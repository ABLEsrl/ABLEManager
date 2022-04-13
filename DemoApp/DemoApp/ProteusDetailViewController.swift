//
//  ProteusDetailViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class ProteusDetailViewController: UIViewController {
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
        
        ProteusManager.shared.registerConnectionObserver { isConnected in
            if isConnected == false {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        ProteusManager.shared.subscribe() { [weak self] newData in
            self?.handle(data: newData)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ProteusManager.shared.unsubscribe()
        ProteusManager.shared.disconnect()
    }
}


extension ProteusDetailViewController {
                     
    @IBAction func sendCommandPressed(_ sender: UIButton?) {
        ProteusManager.shared.send(command: ProteusCommand.authCommand)
        
        self.messages.append("Sending: \(ProteusCommand.authCommand.rawString)")
        self.tableView.reloadSections([0], with: .fade)
    }
    
    func handle(data: String) {
        print("ProteusData: \"\(data)\"")
        
        self.messages.append("Received: \(data)")
        self.tableView.reloadSections([0], with: .fade)
    }
}


extension ProteusDetailViewController: UITableViewDelegate, UITableViewDataSource {
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


extension UIColor {

    func to(color: UIColor, percentage: CGFloat) -> UIColor {
        let percentage = max(min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return self
        case 1: return color
        default:
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
            guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }

            return UIColor(red: CGFloat(r1 + (r2 - r1) * percentage),
                           green: CGFloat(g1 + (g2 - g1) * percentage),
                           blue: CGFloat(b1 + (b2 - b1) * percentage),
                           alpha: CGFloat(a1 + (a2 - a1) * percentage))
        }
    }
}







extension Dictionary {
    
    func jsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self)
            let string = String(data: jsonData, encoding: .utf8) ?? ""
            return string
        }
        catch {
            print(error.localizedDescription)
        }
        
        return ""
    }
}

extension Array {
    
    func jsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self)
            let string = String(data: jsonData, encoding: .utf8) ?? ""
            return string
        }
        catch {
            print(error.localizedDescription)
        }
        
        return ""
    }
}
