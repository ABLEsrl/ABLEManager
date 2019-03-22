//
//  ViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 22/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import UIKit
import ABLEManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BluetoothManager.shared.scanAndConnect(to: "D-mini") { (connectedDevice) in
            
        }
        
    }


}

