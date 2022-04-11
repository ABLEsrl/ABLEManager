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
    public var peripheral:      CBPeripheral?
    public var advData:         [String: Any]
    public var rssi:            NSNumber
    public var services:        [CBService]
    public var characteristics: [CBCharacteristic]
    
    init(with peripheral: CBPeripheral, advData: [String: Any] = [String: Any](), rssi: NSNumber = NSNumber()) {
        self.peripheral      = peripheral
        self.services        = peripheral.services ?? [CBService]()
        self.characteristics = [CBCharacteristic]()
        self.advData         = advData
        self.rssi            = rssi
    }
    
    public var peripheralName: String {
        if self.name.count > 0 {
            return self.name
        }
        
        if self.advName.count > 0 {
            return self.advName
        }
        
        return ""
    }
    
    public var advName: String {
        if let name = advData["kCBAdvDataLocalName"] as? String {
            return name
        }
        
        return ""
    }
    
    public var name: String {
        guard let device = peripheral else {
            return ""
        }
        
        return device.name ?? ""
    }
    
    public static func ==(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        guard
            let _ = lhs.peripheral,
            let _ = rhs.peripheral else {
                return false
        }
        
        var equals = true
        equals = equals && (lhs.peripheralName.compare(rhs.peripheralName) == .orderedSame)
        equals = equals && (lhs.characteristics.count == rhs.characteristics.count)
       
        return equals
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
            
            return lhsDevice.identifier.uuidString < rhsDevice.identifier.uuidString
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        guard let device = peripheral else {
            return
        }
        
        hasher.combine(device.identifier.uuidString)
    }
    
    public var description: String {
        var res = "DEVICE\n"
        res.append("\tName:    " + (peripheral?.name ?? "") + "\n")
        res.append("\tADVData: " + advData.representableString + "\n")
        res.append("\tRSSI:    " + "\(rssi)" + "\n")
        res.append("\n\n")
        return res
    }
    
    public var debugDescription: String {
        var res = "DEVICE\n"
        res.append("\tName:            " + (peripheral?.name ?? "") + "\n")
        res.append("\tADVData:         " + advData.representableString + "\n")
        res.append("\tRSSI:            " + "\(rssi)" + "\n")
        res.append("\tServices:        " + services.representableString + "\n")
        res.append("\tCharacteristics: " + characteristics.representableString + "\n")
        res.append("\n\n")
        return res
    }
}


public extension Array where Iterator.Element == PeripheralDevice {
    
    @discardableResult
    mutating func appendDistinc(_ device: PeripheralDevice, sorting: Bool=true) -> Bool {
        var valueAppended = false
        
        if contains(device) == false {
            append(device)
            valueAppended = true
        }
        
        if valueAppended && sorting {
            sort()
        }
        
        return valueAppended
    }
    
    @discardableResult
    mutating func updatePeripheral(_ device: PeripheralDevice, sorting: Bool=true) -> Bool {
        var valueUpdated = false
        
        forEach {
            let elementUUID = $0.peripheral?.identifier.uuidString ?? ""
            let deviceUUID = device.peripheral?.identifier.uuidString ?? ""
            
            if elementUUID.compare(deviceUUID) == .orderedSame {
                $0.peripheral = device.peripheral
                valueUpdated = true
            }
        }
        
        if valueUpdated && sorting {
            sort()
        }
        
        return valueUpdated
    }
}
