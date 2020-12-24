//
//  RootViewController.swift
//  Security
//
//  Created by Артём Абрамов on 23.12.2020.
//

import UIKit

class RootViewController: UIViewController, MenuViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
    }

    func didSelectItem(_ item: MenuItem) {
        navigationController?.popToRootViewController(animated: false)
        performSegue(withIdentifier: item.segue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SteganographySegue" {
            (segue.destination as? SteganographyViewController)?.mode = 0
        }
        
        if segue.identifier == "SteganographySegue2" {
            (segue.destination as? SteganographyViewController)?.mode = 1
        }
        
        if segue.identifier == "SteganographySegue3" {
            (segue.destination as? SteganographyViewController)?.mode = 2
        }
    }
}
