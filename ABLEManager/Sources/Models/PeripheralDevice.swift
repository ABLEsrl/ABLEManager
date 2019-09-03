//
//  PeripheralDevice.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation


open class PeripheralDevice: Equatable, Comparable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public var peripheral: CBPeripheral?
    public var advData: [String: Any]
    public var rssi: NSNumber
    public var services: [CBService]
    public var characteristics: [CBCharacteristic]
    
    init(with peripheral: CBPeripheral, advData: [String: Any] = [String: Any](), rssi: NSNumber = NSNumber()) {
        self.peripheral = peripheral
        self.services = peripheral.services ?? [CBService]()
        self.characteristics = [CBCharacteristic]()
        self.advData = advData
        self.rssi = rssi
    }
    
    public var peripheralName: String {
        get {
            guard let device = peripheral else {
                return ""
            }
            
            if let name = advData["kCBAdvDataLocalName"] as? String {
                return name
            }
            
            return device.name ?? ""
        }
    }
    
    public static func ==(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        guard
            let lhsDevice = lhs.peripheral,
            let rhsDevice = rhs.peripheral else {
                return false
        }
        
        return lhsDevice.identifier == rhsDevice.identifier
    }
    
    public static func <(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        let lhsName = lhs.peripheralName
        let rhsName = rhs.peripheralName
        
        switch lhsName.compare(rhsName) {
        case .orderedDescending:
            return false
        case .orderedAscending:
            return true
        case .orderedSame:
            guard
                let lhsDevice = lhs.peripheral,
                let rhsDevice = rhs.peripheral else {
                    return false
            }
            
            return lhsDevice.identifier.uuidString > rhsDevice.identifier.uuidString
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        guard let device = peripheral else {
            return
        }
        
        hasher.combine(device.identifier.uuidString)
    }
    
    public var description: String {
        get {
            var res = "DEVICE\n"
            res.append("Name:     " + (peripheral?.name ?? "") + "\n")
            res.append("ADVData:  " + advData.representableString + "\n")
            res.append("RSSI:     " + "\(rssi)" + "\n")
            res.append("\n\n")
            return res
        }
    }
    
    public var debugDescription: String {
        get {
            var res = "DEVICE\n"
            res.append("Name:     " + (peripheral?.name ?? "") + "\n")
            res.append("ADVData:  " + advData.representableString + "\n")
            res.append("RSSI:     " + "\(rssi)" + "\n")
            res.append("Services: " + services.representableString + "\n")
            res.append("Characteristics: " + characteristics.representableString + "\n")
            res.append("\n\n")
            return res
        }
    }
}

public extension Array where Iterator.Element: PeripheralDevice {
    
    @discardableResult
    mutating func appendDistinc(_ device: Iterator.Element ) -> Bool {
        if contains(device) == false {
            append(device)
            return true
        }
        
        return false
    }
    
    @discardableResult
    mutating func updatePeripheral(_ device: Iterator.Element ) -> Bool {
        if contains(device) == false {
            if let deviceIdx = firstIndex(of: device) {
                remove(at: deviceIdx)
                append(device)
                return true
            }            
        }
        
        return false
    }
}

public extension Dictionary {
    var representableString: String {
        get {
            let string = (compactMap({ (key, value) -> String in
                if let dictValue = value as? [String: Any] {
                    return "\(key): \(dictValue.representableString)"
                }
                
                if let listValue = value as? [Any] {
                    return "\(key): \(listValue.representableString)"
                }
                
                return "\(key): \(String(describing: value))"
            }) as Array).joined(separator:"\n")
            
            return string + "\n"
        }
    }
}

public extension Array {
    var representableString: String {
        get {
            let result = (compactMap( { (value) -> String in
                if let value = value as? [String: Any] {
                    return value.representableString
                }
                if let value = value as? Int {
                    return "\(value)"
                }
                if let value = value as? Bool {
                    return "\(value)"
                }
                if let value = value as? Float {
                    return "\(value)"
                }
                if let value = value as? Double {
                    return "\(value)"
                }
                
                return String(describing: value)
            }) as Array<String>).joined(separator: "\n")
            
            return result
        }
    }
}
