//
//  ArchiverViewController.swift
//  Security
//
//  Created by Артём Абрамов on 24.12.2020.
//

import UIKit
import UniformTypeIdentifiers


class ArchiverViewController: UIViewController {

    @IBOutlet var filePathLabel: UILabel!
    
    @IBOutlet var keyTextField: UITextField!
    
    @IBOutlet var archiveButton: UIButton!
    
    var url: URL? {
        didSet {
            if url != nil {
                filePathLabel.text = url?.path
                
                if url!.pathExtension == "x" {
                    archiveButton.setTitle("Разархивировать", for: .normal)
                } else {
                    archiveButton.setTitle("Архивировать", for: .normal)
                }
                
            } else {
                filePathLabel.text = "Выберите файл или директорию"
            }
            
            if url != nil {
                archiveButton.alpha = 1.0
                archiveButton.isEnabled = true
            } else {
                archiveButton.alpha = 0.5
                archiveButton.isEnabled = false
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        archiveButton.layer.cornerRadius = 5.0
        
        url = nil
    }
    
    @IBAction func browseButtonAction(_ sender: Any) {
        let types = UTType.types(tag: "public.data", tagClass: .filenameExtension, conformingTo: nil)
        
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)

        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = false
        
        present(documentPickerController, animated: true, completion: nil)
    }

    // Метод, вызываемый по нажатию кнопки архивации/разархивации
    @IBAction func archiveButtonAction(_ sender: Any) {
        guard let url = url else {
            return
        }
        
        // Если расширение файла .x, то разархивировать
        if url.pathExtension == "x" {
            if var data = try? Data(contentsOf: url) {
                // Расшифрока файла
                data = vegenere(keyTextField.text ?? " ", data: data, crypt: false)
                
                // Обработка байтов по очереди
                while data.count > 0 {
                    // Считывание первых 252 байтов для получения пути к файлу
                    var pathBuffer = [UInt8](repeating: 0, count: 252)
                    data.copyBytes(to: &pathBuffer, count: 252)
                    data = data.dropFirst(252)
                              
                    // Считывание 4х байт размера файла
                    var fileSizeBuffer = [UInt8](repeating: 0, count: 4)
                    data.copyBytes(to: &fileSizeBuffer, count: 4)
                    data = data.dropFirst(4)
                    
                    var fileSize: Int = Int(fileSizeBuffer[3])
                    
                    fileSize = (fileSize << 8) | Int(fileSizeBuffer[2])
                    fileSize = (fileSize << 8) | Int(fileSizeBuffer[1])
                    fileSize = (fileSize << 8) | Int(fileSizeBuffer[0])
                    
                    // Считывание файла
                    var fileBuffer = [UInt8](repeating: 0, count: fileSize)
                    data.copyBytes(to: &fileBuffer, count: fileSize)
                    data = data.dropFirst(fileSize)
                    
                    var fileData = Data()
                    
                    for byte in fileBuffer {
                        fileData.append(byte)
                    }
                    
                    // Получение относительного пути к файлу
                    if var path = String(bytes: pathBuffer, encoding: .ascii) {
                        path = url.deletingPathExtension().path + path
                        path = path.replacingOccurrences(of: "*", with: "")
                                        
                        // Получение пути к директории, содержащей файл
                        let folderURL = URL(fileURLWithPath: path).deletingLastPathComponent()
                        
                        // Попыка создать директорию и все промежуточные директории
                        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                        
                        // Создание файла
                        FileManager.default.createFile(atPath: path, contents: fileData, attributes: nil)
                    }
                }
                
                // Удаление архива
                try? FileManager.default.removeItem(at: url)
            }
        } else {
            // Получение списка всех файлов
            let allFiles = getAllFiles(atPath: url.deletingLastPathComponent().path + "/")
            
            var archive = Data()
            
            // Перебор по файлам
            for file in allFiles {
                // Попытка открытия файла
                if let fileData = try? Data(contentsOf: URL(fileURLWithPath: file)) {
                    // Создание заголовка с путем к файлу
                    var header = "\(file.replacingOccurrences(of: url.deletingLastPathComponent().path, with: ""))"
                    
                    // Дополнение пути до длины в 252 байта
                    while header.count < 252 {
                        header.append("*")
                    }
                    
                    if var headerData = header.data(using: .ascii) {
                        // Получение размера файла
                        var fileSize = UInt32(fileData.count)
                        
                        for _ in 0 ..< 4 {
                            let lowerByte = UInt8(fileSize & 0xFF)
                            headerData.append(lowerByte)
                            
                            fileSize = fileSize >> 8
                        }
                        
                        // Добавление заголовка и данных в архив
                        archive.append(headerData)
                        archive.append(fileData)
                    }
                }
            }
            
            // Удаление файлов и папок
            for file in allFiles {
                try? FileManager.default.removeItem(atPath: file)
                
                let folderURL = URL(fileURLWithPath: file).deletingLastPathComponent()
                
                if folderURL != url.deletingLastPathComponent() {
                    try? FileManager.default.removeItem(at: folderURL)
                }
            }
            
            let archivePath = url.deletingLastPathComponent().path + "/archive.x"
            
            // Шифрование архива
            archive = vegenere(keyTextField.text ?? " ", data: archive, crypt: true)
            
            // Сохранение архива
            try? archive.write(to: URL(fileURLWithPath: archivePath))
        }
    }
 
    // Получение массива байтов
    func getBytes(fromPath: String) -> [UInt8]? {
        if let data = NSData(contentsOfFile: fromPath) {
            var buffer = [UInt8](repeating: 0, count: data.length)
            data.getBytes(&buffer, length: data.length)
            
            return buffer
        } else {
            return nil
        }
    }

    // Получение всех файлов и поддиректорий в директории (более подробно описано в задании 1)
    func getFolderContent(atPath: String) -> [[String]]? {
        do {
            let fileManager = FileManager.default
            let items = try fileManager.contentsOfDirectory(atPath: atPath)
            
            var files: [String] = []
            var folders: [String] = []
            
            for item in items {
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: atPath + item, isDirectory:&isDirectory) {
                    if isDirectory.boolValue {
                        folders.append(item)
                    } else {
                        files.append(item)
                    }
                }
            }
            
            return [files, folders]
        } catch let error as NSError {
            print(error)
        }
        
        return nil
    }
    
    // Получение всех файлов в директории (более подробно описано в задании 1)
    func getAllFiles(atPath: String) -> [String] {
        guard let content = getFolderContent(atPath: atPath) else {
            return []
        }
        
        var result: [String] = []
        
        let files = content[0]
        let folders = content[1]
                
        for file in files {
            let path = atPath + file
            result.append(path)
        }
        
        for folder in folders {
            result.append(contentsOf: getAllFiles(atPath: atPath + folder + "/"))
        }
        
        return result
    }
    
    // Шифрование методом Виджинера. В качетсве алфавита используется таблица символов ASCII
    // (более подробно описано в задании 5)
    func vegenere(_ key: String, data: Data, crypt: Bool) -> Data {
        var result = Data()
        
        var dataBytes = [UInt8](repeating: 0, count: data.count)
        NSData(data: data).getBytes(&dataBytes, length: dataBytes.count)
        
        let keyData = NSData(data: key.data(using: .ascii)!)
        var keyBytes = [UInt8](repeating: 0, count: keyData.length)
        keyData.getBytes(&keyBytes, length: keyData.length)
        
        for byteIndex in 0 ..< dataBytes.count {
            if crypt {
                let newByte: UInt8 = UInt8((Int(dataBytes[byteIndex]) + Int(keyBytes[byteIndex % keyBytes.count])) % 255)
                result.append(newByte)
            } else {
                let new = Int(255 + Int(dataBytes[byteIndex]) - Int(keyBytes[byteIndex % keyBytes.count])) % 255
                let newByte: UInt8 = UInt8(new)
                result.append(newByte)
            }
        }
        
        return result
    }
    
}

extension ArchiverViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        url = urls[0]
    }
    
}
