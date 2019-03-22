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
            // Leggere i dati dal device
            BluetoothManager.shared.subscribe(to: .characteristic5) { (device, response, success) in
                if success {
                    print("Ricevo risposta: " + response.asciiString)
                }
            }
            
            // $2a0a000000
            let command = Command(with: "$290a010001\r\n")
            print("Scrivo il messaggio: \(command.description)")
            BluetoothManager.shared.write(command: command, to: .characteristic5, modality: .withoutResponse)
        }
        
    }


}

