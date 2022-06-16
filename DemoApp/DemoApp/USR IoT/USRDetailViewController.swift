//
//  USRDetailViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class USRDetailViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var device: PeripheralDevice?
    var messages: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        self.device = BluetoothManager.shared.connectedDevice
        if self.device == nil {
            self.navigationController?.popViewController(animated: true)
        }
        
        USRManager.shared.registerConnectionObserver { isConnected in
            if isConnected == false {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        USRManager.shared.subscribe() { [weak self] newData in
            self?.handle(data: newData)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        USRManager.shared.unsubscribe()
        USRManager.shared.disconnect()
    }
}


extension USRDetailViewController {
                     
    @IBAction func sendCommandPressed(_ sender: UIButton?) {
        USRManager.shared.send(command: USRCommand.authCommand)
        
        self.messages.append("Sending: \(USRCommand.authCommand.rawString)")
        self.tableView.reloadSections([0], with: .fade)
    }
    
    func handle(data: String) {
        print("USRData: \"\(data)\"")
        
        self.messages.append("Received: \(data)")
        self.tableView.reloadSections([0], with: .fade)
    }
}


extension USRDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = self.messages[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

