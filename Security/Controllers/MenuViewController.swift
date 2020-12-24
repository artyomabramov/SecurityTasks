//
//  ViewController.swift
//  Security
//
//  Created by Артём Абрамов on 23.12.2020.
//

import UIKit

protocol MenuViewControllerDelegate {
    
    func didSelectItem(_ item: MenuItem)
    
}

struct MenuItem {
    var displayName: String
    var segue: String
}

class MenuViewController: UITableViewController {

    var delegate: MenuViewControllerDelegate?
    
    let content: [MenuItem] = [
        MenuItem(displayName: "Поиск по сигнатуре", segue: "SignatureSegue"),
        MenuItem(displayName: "Стеганография 1", segue: "SteganographySegue"),
        MenuItem(displayName: "Стеганография 2", segue: "SteganographySegue2"),
        MenuItem(displayName: "Стеганография 3", segue: "SteganographySegue3"),
        MenuItem(displayName: "Шифр Вижинера", segue: "VigenereSegue"),
        MenuItem(displayName: "Шифрование каталога", segue: "ArchiverSegue"),
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
        
        delegate = ((splitViewController?.viewControllers[1] as? UINavigationController)?.viewControllers[0] as? RootViewController)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")!
        
        cell.textLabel?.text = content[indexPath.row].displayName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectItem(content[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
}

