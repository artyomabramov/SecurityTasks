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
    
    func vigenere(_ key: String, text: String, crypt: Bool) -> String {
        let alphabet = ["А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"]
        
        let key = key.uppercased()
        let text = text.uppercased()
        
        var result = ""
        
        var index = 0
        
        for character in text {
            if let characterIndex = alphabet.firstIndex(of: String(character)) {
                let keyIndex = key.index(key.startIndex, offsetBy: index % key.count)
                let keyCharacter = key[keyIndex]
                
                if let keyCharacterIndex = alphabet.firstIndex(of: String(keyCharacter)) {
                    if crypt {
                        let newCharacterIndex = (characterIndex + keyCharacterIndex) % alphabet.count
                        result.append(alphabet[newCharacterIndex])
                    } else {
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
