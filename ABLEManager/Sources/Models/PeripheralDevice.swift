//
//  PeripheralDevice.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation


open class PeripheralDevice: Equatable, Comparable, Hashable {
    public var peripheral: CBPeripheral
    public var services: [CBService]
    public var characteristics: [CBCharacteristic]
    
    init(with peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.services = peripheral.services ?? [CBService]()
        self.characteristics = [CBCharacteristic]()
    }
    
    public var peripheralName: String {
        get {
            return peripheral.name ?? ""
        }
    }
    
    public static func ==(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
    
    public static func <(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        let lhsName = lhs.peripheral.name ?? "NoName"
        let rhsName = rhs.peripheral.name ?? "NoName"
        
        switch lhsName.compare(rhsName) {
        case .orderedDescending:
            return false
        case .orderedAscending:
            return true
        case .orderedSame:
            return lhs.peripheral.identifier.uuidString > rhs.peripheral.identifier.uuidString
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier.uuidString)
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
            if let deviceIdx = index(of: device) {
                remove(at: deviceIdx)
                append(device)
                return true
            }            
        }
        
        return false
    }
}
