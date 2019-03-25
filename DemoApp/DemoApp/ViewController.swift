//
//  ViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 22/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        DMiniBLEManager.shared.searchAndConnect { (device) in
            print ("Connesso")
        }
    }
    
    @IBAction func tagsCountOnReader(_ sender: UIButton?) {
        DMiniBLEManager.shared.getTagsCountOnReader { (tagsCount, success) in
            print ("Tags on reader: \(tagsCount)")
        }
    }
    
    @IBAction func readAllTags(_ sender: UIButton?) {
        DMiniBLEManager.shared.readAllTags { (tags, success) in
            tags.forEach { (tag) in
                print("Tag : \(tag)")
            }
        }
    }
    
}

