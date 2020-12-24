//
//  FileSearchViewController.swift
//  Security
//
//  Created by Артём Абрамов on 23.12.2020.
//

import UIKit
import UniformTypeIdentifiers


class FileSearchViewController: UIViewController {

    @IBOutlet var signatureLabel: UILabel!
    @IBOutlet var fileLabel: UILabel!
    @IBOutlet var folderLabel: UILabel!
    
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    let size = 16
    
    var filePath: URL? {
        didSet {
            var signatureHEX = ""
            var signatureASCII = ""
            result = []
            
            if filePath != nil {
                fileLabel.text = filePath?.path
                
                if let data = NSData(contentsOf: filePath!) {
                    if let signature = getBytes(fromData: data, shift: 32) {
                        signatureHEX = ""
                        signatureASCII = String(bytes: signature, encoding: .ascii) ?? ""
                        
                        for byte in signature {
                            signatureHEX += String(format: "%02X ", byte)
                        }
                    }
                }
            } else {
                fileLabel.text = "Файл не выбран"
                
                signatureHEX = ""
                signatureASCII = ""
            }
            
            signatureLabel.text = "Сигнатура HEX: \(signatureHEX)\nСигнатура ASCII: \(signatureASCII)"
            
            searchButton.isEnabled = filePath != nil && folderPath != nil
            searchButton.alpha = searchButton.isEnabled ? 1.0 : 0.5
        }
    }
        
    var folderPath: URL? {
        didSet {
            result = []
            
            if folderPath != nil {
                folderLabel.text = folderPath?.deletingLastPathComponent().path
            } else {
                folderLabel.text = "Директория не выбрана"
            }
            
            searchButton.isEnabled = filePath != nil && folderPath != nil
            searchButton.alpha = searchButton.isEnabled ? 1.0 : 0.5
        }
    }
    
    var result: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchButton.layer.cornerRadius = 5.0
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
                
        filePath = nil
        folderPath = nil
    }
    
    @IBAction func searchButtonAction(_ sender: Any) {
        guard let filePath = filePath, let folderPath = folderPath else {
            return
        }
        
        if let data = NSData(contentsOf: filePath) {
            if let signature = getBytes(fromData: data, shift: 32) {
                var res = ""
                
                for byte in signature {
                    res += String(format:"%02X", byte)
                }
                
                let folder = folderPath.deletingLastPathComponent()
                
                if folder.startAccessingSecurityScopedResource() {
                    result = getAllFiles(atPath: folder.path + "/", equalTo: signature)
                    folder.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    @IBAction func browseButtonAction(_ sender: Any) {
        
        let types = UTType.types(tag: "public.data", tagClass: .filenameExtension, conformingTo: nil)
        
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)

        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.view.tag = 0
        
        present(documentPickerController, animated: true, completion: nil)
    }
    
    @IBAction func browseFolderButtonAction(_ sender: Any) {
        
        let types = UTType.types(tag: "public.data", tagClass: .filenameExtension, conformingTo: nil)
        
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)

        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.view.tag = 1
        
        present(documentPickerController, animated: true, completion: nil)
    }
    
}


extension FileSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")!
        
        cell.textLabel?.lineBreakMode = .byTruncatingHead
        cell.textLabel?.text = result[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Результаты поиска"
    }
    
}


extension FileSearchViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if controller.view.tag == 0 {
            filePath = urls[0]
        } else {
            folderPath = urls[0]
        }
        
    }
    
}


extension FileSearchViewController {
        
    // Функция, возвращающая массив из 16 байтов со сдвигом shift от начала данных
    func getBytes(fromData: NSData, shift: Int) -> [UInt8]? {
        // Инициализация массива байтов
        var buffer = [UInt8](repeating: 0, count: size)
        
        // Если длина данных больше, чем сдвиг + размер сигнатуры, то получить сигнатуру
        if (fromData.length >= shift + size) {
            // Получение сигнатуры длиной size со сдвигом shift от начала
            fromData.getBytes(&buffer, range: NSRange(location: shift, length: size))
            return buffer
        } else {
            return nil
        }
    }

    // Функция, возвращающая содержимое папки. Первый элемент массва - массив файлов, второй - массив папок
    func getFolderContent(atPath: String) -> [[String]]? {
        do {
            let fileManager = FileManager.default
            
            // Получение содержимого директории
            let items = try fileManager.contentsOfDirectory(atPath: atPath)
            
            var files: [String] = []
            var folders: [String] = []
            
            // Перебор всех элементов директории
            for item in items {
                var isDirectory: ObjCBool = false
                
                // Проверка существования файла/директории
                if fileManager.fileExists(atPath: atPath + item, isDirectory: &isDirectory) {
                    // Если директория, то добавить в массив директорий, иначе в массив файлов
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
    
    
    // Функция, возвращающая все файлы в указанной директории
    // и всех её поддиректориях, содержищих указанную сигнатуру
    func getAllFiles(atPath: String, equalTo: [UInt8]) -> [String] {
        // Если директория пустая, то вернуть пустой массив
        guard let content = getFolderContent(atPath: atPath) else {
            return []
        }
                
        var result: [String] = []
        
        let files = content[0]
        let folders = content[1]
                
        // Перебор всех файлов в директории
        for file in files {
            let path = atPath + file
            
            // Получение данных из файла
            let file = NSData(contentsOfFile: path)
            
            // Если файл открыт и его длина больше длины сигнатуры, то проверить его содержимое
            if (file != nil && file!.length >= size) {
                
                // Поиск сигнатуры постепенно увеличивая сдвиг от начала файла
                for shift in 0 ... (file!.length - size) {
                    let bytes = getBytes(fromData: file!, shift: shift)
                    
                    // Если сигнатуры совпали и это не исходный файл, то добавить его к результатам
                    if bytes == equalTo && path != filePath?.relativePath {
                        result.append(path)
                        break
                    }
                }
            }
        }
        
        // Перебор всех директорий с рекурсивным вызовом данной функции для каждой из них
        for folder in folders {
            result.append(contentsOf: getAllFiles(atPath: atPath + folder + "/", equalTo: equalTo))
        }
        
        return result
    }
    
}
