//
//  VigenereViewController.swift
//  Security
//
//  Created by Артём Абрамов on 24.12.2020.
//

import UIKit

class VigenereViewController: UIViewController {

    @IBOutlet var keyTextField: UITextField!
    
    @IBOutlet var inputTextView: UITextView!
    @IBOutlet var outputTextView: UITextView!
    
    @IBOutlet var cryptButton: UIButton!
    @IBOutlet var encryptButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cryptButton.layer.cornerRadius = 5.0
        encryptButton.layer.cornerRadius = 5.0
        inputTextView.layer.cornerRadius = 5.0
        outputTextView.layer.cornerRadius = 5.0
    }
    

    @IBAction func cryptButtonAction(_ sender: Any) {
        outputTextView.text = vigenere(keyTextField.text ?? "", text: inputTextView.text, crypt: true)
    }

    @IBAction func encryptButtonAction(_ sender: Any) {
        outputTextView.text = vigenere(keyTextField.text ?? "", text: inputTextView.text, crypt: false)
    }
    
    // Функция, шифрующая и разшифровывающая текст с помощью указанного ключа
    func vigenere(_ key: String, text: String, crypt: Bool) -> String {
        // Алфавит
        let alphabet = ["А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"]
        
        // Преобразование ключа и текста в заглавные буквы
        let key = key.uppercased()
        let text = text.uppercased()
        
        var result = ""
        
        var index = 0
        
        // Перебор символов в тексте
        for character in text {
            // Получение номера символа из текста в алфавите
            if let characterIndex = alphabet.firstIndex(of: String(character)) {
                let keyIndex = key.index(key.startIndex, offsetBy: index % key.count)
                let keyCharacter = key[keyIndex]
                
                // Получение номера символа из ключа в алфавите
                if let keyCharacterIndex = alphabet.firstIndex(of: String(keyCharacter)) {
                    if crypt {
                        // Шифрование суммированием по модулю
                        let newCharacterIndex = (characterIndex + keyCharacterIndex) % alphabet.count
                        result.append(alphabet[newCharacterIndex])
                    } else {
                        // Разшифровывание вычитанием по модулю
                        var newCharacterIndex = (characterIndex - keyCharacterIndex)
                        
                        if newCharacterIndex < 0 {
                            newCharacterIndex += alphabet.count
                        }
                        
                        result.append(alphabet[newCharacterIndex])
                    }
                } else {
                    result.append(character)
                }
            } else {
                result.append(character)
            }
            
            index += 1
        }
        
        return result
    }
    
}
