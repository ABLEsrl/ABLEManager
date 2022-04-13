//
//  LetsViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class ProteusViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var deviceList = [PeripheralDevice]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        ProteusManager.shared.registerConnectionObserver { isConnected in
            print("Proteus is connected? \(isConnected)")
        }
        
        /*
         ProteusManager.shared.searchAndConnect { (device) in
            print("Connesso con \(device.peripheralName)")
        }
        */
        
        ProteusManager.shared.scanning(["BP"]) { devices in
            self.deviceList = devices
            self.tableView.reloadData()
        }
    }
}


extension ProteusViewController {
    @IBAction func closePressed(_ sender: UIButton?) {
        self.dismiss(animated: true)
    }
    
    @IBAction func scanningPressed(_ sender: UIButton?) {
        ProteusManager.shared.stopScan()
        
        self.deviceList = [PeripheralDevice]()
        self.tableView.reloadData()
        
        ProteusManager.shared.scanning(["BP"]) { devices in
            self.deviceList = devices
            self.tableView.reloadData()
        }
    }
}


extension ProteusViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text       = self.deviceList[indexPath.row].peripheralName
        cell.detailTextLabel?.text = self.deviceList[indexPath.row].characteristics.representableString
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ProteusManager.shared.stopScan()
        
        tableView.cellForRow(at: indexPath)?.accessoryView = self.createSpinner()
        ProteusManager.shared.connect(to: self.deviceList[indexPath.row], timeout: 10) { device in
            tableView.cellForRow(at: indexPath)?.accessoryView = nil
            
            guard let device = device else {
                print("Unable to connect to selected device")
                return
            }
            
            print("Connected:       \(true)")
            print("Services:        \(device.services)")
            print("Characteristics: \(device.characteristics)")
            
            self.performSegue(withIdentifier: "kShowDetail", sender: self)
        }
    }
    
    
    func createSpinner() -> UIActivityIndicatorView {
        let view             = UIActivityIndicatorView(style: .gray)
        view.backgroundColor = .clear
        view.style           = .gray
        view.tintColor       = .gray
        view.color           = .gray
        view.startAnimating()
        return view
    }
}
