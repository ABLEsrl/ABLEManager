//
//  JetsonDetailViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class JetsonDetailViewController: UIViewController {
    @IBOutlet weak var centerLabel:    UILabel!
    @IBOutlet weak var leftStackView:  UIStackView!
    @IBOutlet weak var rightStackView: UIStackView!
    
    
    var device: PeripheralDevice?
    
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
        
        JetsonManager.shared.registerConnectionObserver { isConnected in
            if isConnected == false {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        JetsonManager.shared.subscribe() { [weak self] newData in
            self?.handle(data: newData)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        
        JetsonManager.shared.unsubscribe()
        JetsonManager.shared.disconnect()
    }
}


extension JetsonDetailViewController {
                     
    @IBAction func sendCommandPressed(_ sender: UIButton?) {
        JetsonManager.shared.sendWithoutResponse(command: JetsonCommand.startCommand)
    }
    
    func handle(data: String) {
        guard let jetsonData = JetsonData.from(string: data) else {
            return
        }
        
        self.leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        self.rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let leftCount  = UILabel()
        leftCount.text = "\(jetsonData.detection)"
        leftCount.font = UIFont.boldSystemFont(ofSize: 14)
        self.leftStackView.addArrangedSubview(leftCount)
        
        let rightCount  = UILabel()
        rightCount.text = "\(jetsonData.detection)"
        rightCount.font = UIFont.boldSystemFont(ofSize: 20)
        self.rightStackView.addArrangedSubview(rightCount)
        
        jetsonData.porosity.forEach { porosity in
            let label             = UILabel()
            label.text            = "\(porosity)%"
            label.textColor       = .black
            label.font            = UIFont.boldSystemFont(ofSize: 16)
            label.backgroundColor = UIColor.white.to(color: .green, percentage: CGFloat(porosity))
            self.leftStackView.addArrangedSubview(label)
            self.rightStackView.addArrangedSubview(label)
        }
    }
}


class JetsonData: Codable {
    var porosity: [Int]
    var detection: Int
    
    class func from(string: String) -> JetsonData? {
        if let encoded = string.data(using: .utf8), let decoded = try? JSONDecoder().decode(JetsonData.self, from: encoded) {
            return decoded
        }
        return nil
    }
}

extension String {

    func toDictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            }
            catch {
                print("Dict parser Error: " + error.localizedDescription)
            }
        }

        return nil
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
