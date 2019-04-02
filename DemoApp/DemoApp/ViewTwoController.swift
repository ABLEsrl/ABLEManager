//
//  ViewTwoController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 02/04/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import UIKit

class ViewTwoController: UIViewController {
    @IBOutlet var progressIndicator: UIProgressView!
    @IBOutlet var activityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IdroManager.shared.registerConnectionObserver { (isConnected) in
            print("Idro is connected? \(isConnected)")
        }
    }
    
    @IBAction func tagsCountOnReader(_ sender: UIButton?) {
        IdroManager.shared.sendCommand_O(gateway: "6E02008F", bar: progressIndicator, label: activityLabel) { [weak self] (response, code) in
            if code == .ack {
                self?.activityLabel.text = "Gateway attivo."
            }
        }
    }
    
    @IBAction func connetti(_ sender: UIButton?) {
        IdroManager.shared.scanning(with: "-E18") { (list) in
            IdroManager.shared.stopScan()
            
            DispatchQueue(label: "idro.controller").async {
                IdroManager.shared.connect(with: list[0])
            }
        }
    }
}
