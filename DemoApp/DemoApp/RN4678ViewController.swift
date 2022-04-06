//
//  RN4678ViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager


class RN4678ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        RN4678Manager.shared.registerConnectionObserver { (isConnected) in
            print("Lets is connected? \(isConnected)")
        }
        
        RN4678Manager.shared.searchAndConnect { (device) in
            print("Connesso con \(device.peripheralName)")
        }
    }
}


extension RN4678ViewController {
    @IBAction func closePressed(_ sender: UIButton?) {
        self.dismiss(animated: true)
    }
}


extension RN4678ViewController {
    
    @IBAction func startStream(_ sender: UIButton?) {
        var start = Date().timeIntervalSince1970 * 1000
        RN4678Manager.shared.sendWithSteamResponse(command: RN4678Command.startCommand) { (response) in
            print("HeartRate:  " + "\(response.heartRateValue)")
            print("breathRate: " + "\(response.breathRateValue)")
            print("Samples:    " + "\(response.sampleCountValue)")
//            print("ECG:        " + response.ecgSamplesValues.compactMap {"\($0)"}.joined(separator: " "))
//            print("Breath:     " + response.breathSampleValues.compactMap {"\($0)"}.joined(separator: " "))
            
            let elaps = Date().timeIntervalSince1970 * 1000 - start
            print("Elapsed: \(elaps)")
            start = Date().timeIntervalSince1970 * 1000
        }
    }
    
}
