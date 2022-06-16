//
//  USRDetailViewControllerMany.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class USRDetailViewControllerMany: UIViewController {
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
        
        self.messages = []
        self.tableView.reloadData()
        
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


extension USRDetailViewControllerMany {
    @IBAction func clearPressend(_ sender: UIBarButtonItem?) {
        self.messages = []
        self.tableView.reloadData()
    }
    
    @IBAction func sendCommandPressed(_ sender: UISlider?) {
        guard let number = sender?.value else { return }
        
        let value = Int(number)
        navigationItem.title = "\(value)"

        USRManager.shared.send(command: USRCommand.programCommand(value: value))
    }
    
    func handle(data: String) {
        print("USRData: " + data)
        
        self.messages.append(data)
        self.tableView.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .fade)
    }
}


extension USRDetailViewControllerMany: UITableViewDelegate, UITableViewDataSource {
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
