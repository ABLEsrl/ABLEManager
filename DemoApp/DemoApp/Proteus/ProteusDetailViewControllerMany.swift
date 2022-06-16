//
//  ProteusDetailViewControllerMany.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class ProteusDetailViewControllerMany: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var device: PeripheralDevice?
    var messages: [String] = []
    
    var value    = 0
    var sent     = 0
    var received = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        navigationItem.title = "\(self.value) - \(self.sent)/\(self.received)"
        
        self.messages = []
        self.tableView.reloadData()
        
        self.device = BluetoothManager.shared.connectedDevice
        if self.device == nil {
            self.navigationController?.popViewController(animated: true)
        }

        ProteusManager.shared.registerConnectionObserver { isConnected in
            if isConnected == false {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        ProteusManager.shared.handleNewMessage = { [weak self] response in
            self?.handle(data: response.rawString)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ProteusManager.shared.unsubscribe()
        ProteusManager.shared.disconnect()
    }
}


extension ProteusDetailViewControllerMany {
    @IBAction func clearPressend(_ sender: UIBarButtonItem?) {
        self.messages = []
        self.tableView.reloadData()
    }
    
    @IBAction func sendCommandPressed(_ sender: UISlider?) {
        guard let number = sender?.value else { return }
        guard self.value != Int(number) else { return }
        
        self.sent += 1
        self.value = Int(number)
        navigationItem.title = "\(self.value) - \(self.sent)/\(self.received)"

        ProteusManager.shared.send(command: ProteusCommand.programCommand(value: value))
    }
    
    func handle(data: String) {
        self.received += 1
        
        navigationItem.title = "\(self.value) - \(self.sent)/\(self.received)"
        
        self.messages.append(data)
        self.tableView.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .fade)
        self.tableView.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .bottom, animated: true)
    }
}


extension ProteusDetailViewControllerMany: UITableViewDelegate, UITableViewDataSource {
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
