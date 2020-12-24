//
//  SteganographyViewController.swift
//  Security
//
//  Created by Артём Абрамов on 23.12.2020.
//

import UIKit
import UniformTypeIdentifiers


class SteganographyViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var selectFileLabel: UILabel!
    
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var decodeButton: UIButton!
    
    @IBOutlet var textView: UITextView!
    
    @IBOutlet var textField: UITextField!
    
    var mode = 0
    
    var filePath: URL? {
        didSet {
            if filePath != nil {
                selectFileLabel.isHidden = true
                textView.text = try? String(contentsOf: filePath!)
            } else {
                selectFileLabel.isHidden = false
                textView.text = ""
            }
            
            nextButton.isEnabled = filePath != nil
            nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
            
            decodeButton.isEnabled = nextButton.isEnabled
            decodeButton.alpha = nextButton.alpha
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.layer.cornerRadius = 5.0
        decodeButton.layer.cornerRadius = 5.0
        
        filePath = nil
        
        textField.delegate = self
    }
    
    @IBAction func browseButtonAction(_ sender: Any) {
        let types = UTType.types(tag: "public.data", tagClass: .filenameExtension, conformingTo: nil)
        
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
        
        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = false
        
        present(documentPickerController, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        let coded = hide(textField.text ?? "", in: textView.text)
        
        print(get(phraseFrom: coded))
        
        if let filePath = filePath {
            let pathExtension = filePath.pathExtension
            let savePath = filePath.deletingPathExtension().path + "_CODED." + pathExtension
            
            try? coded.write(toFile: savePath, atomically:  false, encoding: .utf8)
            
            let alert = UIAlertController(title: "Готово", message: "Файл сохранен", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "Ок", style: .default, handler: nil)
            
            alert.addAction(ok)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func decodeButtonAction(_ sender: Any) {
        let result = get(phraseFrom: textView.text)
        
        let alert  = UIAlertController(title: "Готово", message: "Результат: \(result)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ок", style: .default, handler: nil)
        
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return false
    }
    
    // Функция, возвращающая текст с закодированной в нём фразой
    func hide(_ phrase: String, in text: String) -> String {
        switch mode {
        case 0:
            // Очистка исходного текста от пробелов в конце строки
            let text = text.replacingOccurrences(of: " \n", with: "\n")
            
            // Получение массива строк текста
            var lines = text.components(separatedBy: "\n")
            
            // Преобразование фразы в массив байтов. Кодировка UTF-8
            let data = NSData(data: phrase.data(using: .utf8)!)
            var bytes = [UInt8](repeating: 0, count: data.length)
            
            data.getBytes(&bytes, length: data.length)
            
            // В начало массива байтов вставляется длина фразы
            // в байтах для оптимизаци чтения
            bytes.insert(UInt8(bytes.count), at: 0)
            
            // Перебор по строкам текста
            for index in 0 ..< lines.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                if byteIndex >= bytes.count {
                    break
                }
                
                // Получение бита с номером index
                let mask: UInt8 = 1 << bitIndex
                let bit = (bytes[byteIndex] & mask) != 0
                
                // Если бит равен 1, то добавить пробел в конец строки
                lines[index].append(bit ? " " : "")
            }
            
            // Сборка итогового текста из строк
            let result = lines.joined(separator: "\n")
            return result
            
        case 1:
            // Очистка исходного текста от двойных пробелов
            let text = text.replacingOccurrences(of: "  ", with: " ")
            
            // Разбиение текста по пробелам
            var parts = text.components(separatedBy: " ")
            
            // Преобразование фразы в массив байтов. Кодировка UTF-8
            let data = NSData(data: phrase.data(using: .utf8)!)
            var bytes = [UInt8](repeating: 0, count: data.length)
            
            data.getBytes(&bytes, length: data.length)
            
            // В начало массива байтов вставляется длина фразы
            // в байтах для оптимизаци чтения
            bytes.insert(UInt8(bytes.count), at: 0)
            
            // Перебор по элементам текста
            for index in 0 ..< parts.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                if byteIndex >= bytes.count {
                    break
                }
                
                // Получение бита с номером index
                let mask: UInt8 = 1 << bitIndex
                let bit = (bytes[byteIndex] & mask) != 0
                
                // Если бит равен 1, то добавить второй пробел
                parts[index].append(bit ? " " : "")
            }
            
            // Сборка итогового текста из частей
            let result = parts.joined(separator: " ")
            return result
            
        case 2:
            // Словарь символов кириллицы с их аналогами в латинице
            let charactersMap = [
                "А" : "A",
                "В" : "B",
                "С" : "C",
                "Е" : "E",
                "Н" : "H",
                "К" : "K",
                "М" : "M",
                "О" : "O",
                "Р" : "P",
                "Т" : "T",
                "Х" : "Х",
                "а" : "a",
                "с" : "c",
                "е" : "e",
                "м" : "m",
                "о" : "o",
                "р" : "p",
                "у" : "y",
                "х" : "x"
            ]
            
            var text = text
            
            // Очистка текста от латинских букв, аналагичных символам кириллицы
            for key in charactersMap.keys {
                text = text.replacingOccurrences(of: charactersMap[key]!, with: key)
            }
            
            // Преобразование фразы в массив байтов. Кодировка UTF-8
            let data = NSData(data: phrase.data(using: .utf8)!)
            var bytes = [UInt8](repeating: 0, count: data.length)
            
            data.getBytes(&bytes, length: data.length)
            
            // В начало массива байтов вставляется длина фразы
            // в байтах для оптимизаци чтения
            bytes.insert(UInt8(bytes.count), at: 0)
            
            var index = 0
            
            // Перебор по элементам текста
            for character in 0 ..< text.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                if byteIndex >= bytes.count {
                    break
                }
                
                // Получение бита с номером index
                let mask: UInt8 = 1 << bitIndex
                let bit = (bytes[byteIndex] & mask) != 0
                
                let characterIndex = text.index(text.startIndex, offsetBy: character)
                let symbol = String(text[characterIndex])
                
                // Если бит равен 1 и символ содержится в словаре, то заменить его
                if let alternativeSymbol = charactersMap[symbol] {
                    if bit {
                        text.replaceSubrange(characterIndex ... characterIndex, with: alternativeSymbol)
                    }
                    
                    index += 1
                }
            }
            
            return text
            
        default:
            return ""
        }
    }
    
    // Функция для получения фразы из текста
    func get(phraseFrom text: String) -> String {
        switch mode {
        case 0:
            // Разбиение текста на строки
            let lines = text.components(separatedBy: "\n")
            
            var bytes: [UInt8] = []
            
            // Перебор по строкам
            for index in 0 ..< lines.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                // Увеличение массива байтов, если чтение еще не окончено
                if byteIndex >= bytes.count {
                    // Если размер массива равен длины фразы, то не добавлять новый байт
                    if bytes.count > 1 && bytes[0] <= (bytes.count - 1) {
                        break
                    }
                    
                    bytes.append(0)
                }
                
                let mask: UInt8 = 1 << bitIndex
                
                // Если в конце строки стоит пробел, сделать бит под номером index единицей
                if lines[index].last == " " {
                    bytes[byteIndex] = bytes[byteIndex] | mask
                }
            }
            
            // Удаление байта длины из массива
            bytes.removeFirst()
            
            // Преобразование массива байтов в фразу с кодировкой UTF-8
            return String(bytes: bytes, encoding: .utf8) ?? ""
            
        case 1:
            var bytes: [UInt8] = []
            
            var index = 0
            
            // Перебор символов текста
            for character in 0 ..< text.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                // Увеличение массива байтов, если чтение еще не окончено
                if byteIndex >= bytes.count {
                    // Если размер массива равен длины фразы, то не добавлять новый байт
                    if bytes.count > 1 && bytes[0] <= (bytes.count - 1) {
                        break
                    }
                    
                    bytes.append(0)
                }
                
                // Получение символа с индексом character из текста
                let characterIndex = text.index(text.startIndex, offsetBy: character)
                let symbol = String(text[characterIndex])
                
                // Если символ равен пробелу, то проверить, не является ли следующий символ пробелом
                if symbol == " " {
                    let nextCharacterIndex = text.index(text.startIndex, offsetBy: character + 1)
                    let nextSymbol = String(text[nextCharacterIndex])
                    
                    if nextSymbol == " " {
                        let mask: UInt8 = 1 << bitIndex
                        bytes[byteIndex] = bytes[byteIndex] | mask
                    } else {
                        index += 1
                    }
                }
            }
            
            // Удаление байта длины из массива
            bytes.removeFirst()
            
            // Преобразование массива байтов в фразу с кодировкой UTF-8
            return String(bytes: bytes, encoding: .utf8) ?? ""
            
        case 2:
            // Словарь символов кириллицы с их аналогами в латинице
            let charactersMap = [
                "А" : "A",
                "В" : "B",
                "С" : "C",
                "Е" : "E",
                "Н" : "H",
                "К" : "K",
                "М" : "M",
                "О" : "O",
                "Р" : "P",
                "Т" : "T",
                "Х" : "Х",
                "а" : "a",
                "с" : "c",
                "е" : "e",
                "м" : "m",
                "о" : "o",
                "р" : "p",
                "у" : "y",
                "х" : "x"
            ]
            
            var bytes: [UInt8] = []
            
            var index = 0
            
            // Перебор по символам текста
            for character in 0 ..< text.count {
                let byteIndex = index / 8
                let bitIndex = index % 8
                
                // Увеличение массива байтов, если чтение еще не окончено
                if byteIndex >= bytes.count {
                    // Если размер массива равен длины фразы, то не добавлять новый байт
                    if bytes.count > 1 && bytes[0] <= (bytes.count - 1) {
                        break
                    }
                    
                    bytes.append(0)
                }
                
                // Получение символа с индексом character из текста
                let characterIndex = text.index(text.startIndex, offsetBy: character)
                let symbol = String(text[characterIndex])
                
                // Если символ содержится в словаре и является элементом латинского алфавита,
                // то установить бит с номером index в 1
                if charactersMap.keys.contains(symbol) {
                    index += 1
                } else if charactersMap.values.contains(symbol) {
                    let mask: UInt8 = 1 << bitIndex
                    bytes[byteIndex] = bytes[byteIndex] | mask
                    
                    index += 1
                }
            }
            
            // Удаление байта длины из массива
            bytes.removeFirst()
            
            // Преобразование массива байтов в фразу с кодировкой UTF-8
            return String(bytes: bytes, encoding: .utf8) ?? ""
            
        default:
            return ""
        }
    }
    
}


extension SteganographyViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        filePath = urls[0]
    }
    
}
