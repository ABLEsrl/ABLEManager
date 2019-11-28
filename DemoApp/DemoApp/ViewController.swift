//
//  ViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 22/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DMiniBLEManager.shared.registerConnectionObserver { (isConnected) in
            print("DMini is connected? \(isConnected)")
        }
        
        DMiniBLEManager.shared.searchAndConnect { (device) in
            print("Connesso con \(device.peripheralName)")
        }
        
        DMiniBLEManager.shared.scanning(["DMini"]) { (device) in
            print("Device Found: \(device.peripheralName)")
        }
    }
}
 

extension ViewController {
    
    @IBAction func tagsCountOnReader(_ sender: UIButton?) {
        DMiniBLEManager.shared.getTagsCountOnReader { (tagsCount, success) in
            print("Tags on reader: \(tagsCount)")
        }
    }
    
    @IBAction func readAllTags(_ sender: UIButton?) {
        DMiniBLEManager.shared.readAllTags { (tags, success) in
            tags.forEach { (tag) in
                print("Tag : \(tag)")
            }
        }
    }
    
    @IBAction func writeTag(_ sender: UIButton?) {
        DMiniBLEManager.shared.writeTag(value: "e2801170200000c03bf709e8") { (reponseCode) in
            switch reponseCode {
            case .SaveCorrecty:
                print("Salvato")
            case .MemoryFull:
                print("Memoria Piena")
            case .DeviceNotReady:
                print("Modalità Dmini non valida! Scarica i tags prima di scrivere")
            case .TagAlreadySaved:
                print("Already Saved")
            case .UnknownCodeError:
                print("Errore")
            }
        }
    }
    
    @IBAction func writeTagList(_ sender: UIButton?) {
        let list = ["e2801170200000c03bf709e8", "e2801180300000c03bf709e8", "e2801180303000c03bf709e8"]
        
        DMiniBLEManager.shared.writeAllTags(values: list) { (responseList) in
            responseList.forEach { (reponseCode) in
                switch reponseCode {
                case .SaveCorrecty: //Risposta valida
                    print("Salvato")
                case .MemoryFull:
                    print("Memoria Piena")
                case .DeviceNotReady:
                    print("Modalità DMini non valida! Scarica i tags prima di scrivere")
                case .TagAlreadySaved: //Risposta valida
                    print("Already Saved")
                case .UnknownCodeError:
                    print("Errore")
                }
            }
        }
    }
}

