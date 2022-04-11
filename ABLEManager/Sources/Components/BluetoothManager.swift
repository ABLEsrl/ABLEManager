//
//  BluetoothManager.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit

public typealias ConnectionKVOCallback = ((Bool, Bool)->Void)
public typealias ScanningCallback      = (([PeripheralDevice])->Void)
public typealias ConnectCallback       = ((PeripheralDevice?)->Void)
public typealias WriteCallback         = ((PeripheralDevice, Bool)->Void)
public typealias NotifyCallback        = ((PeripheralDevice, Data, Bool)->Void)

public class BluetoothManager: NSObject {
    
    public static let shared: BluetoothManager = BluetoothManager()
    
    private var connectingSemaphore:     ABLEDispatchGroup
    private var subcribeSemaphore:       ABLEDispatchGroup
    private var serviceSemaphore:        ABLEDispatchGroup
    private var characteristicSemaphore: ABLEDispatchGroup
    private var scanAndConnectSemaphore: ABLEDispatchGroup
    private var reconnectionSemaphore:   ABLEDispatchGroup
    
    private var manager:        CBCentralManager!
    private var eventQueue:     DispatchQueue!
    private var scanningFilter: [String]?
    
    public var peripherals:         [PeripheralDevice]
    public var connectedDevice:     PeripheralDevice?
    public var lastConnectedDevice: PeripheralDevice?
    
    private var connectionStatusCallback: ConnectionKVOCallback?
    private var scanningCallback:         ScanningCallback?
    private var connectCallback:          ConnectCallback?
    private var writeCallbacks:           [String: WriteCallback?]
    private var notifyCallbacks:          [String: NotifyCallback?]
    
    
    @objc dynamic public var isConnected: Bool {
        get {
            guard let device = self.connectedDevice, let peripheral = device.peripheral else {
                return false
            }
            
            return peripheral.state == .connected
        }
        
        set {
            self.connectedDevice = nil
        }
    }
    
    @objc dynamic public var isPoweredOn: Bool {
        guard let manager = self.manager else {
            return false
        }
        
        return manager.state == .poweredOn
    }
    
    private override init() {
        self.scanAndConnectSemaphore = ABLEDispatchGroup()
        self.connectingSemaphore     = ABLEDispatchGroup()
        self.serviceSemaphore        = ABLEDispatchGroup()
        self.characteristicSemaphore = ABLEDispatchGroup()
        self.subcribeSemaphore       = ABLEDispatchGroup()
        self.reconnectionSemaphore   = ABLEDispatchGroup()
        
        self.peripherals = [PeripheralDevice]()
        self.eventQueue  = DispatchQueue(label: "it.able.ble.event.queue")

        self.scanningFilter   = nil
        self.scanningCallback = nil
        self.connectCallback  = nil
        self.writeCallbacks   = [String: WriteCallback?]()
        self.notifyCallbacks  = [String: NotifyCallback?]()
        
        super.init()
        
        let options = [CBCentralManagerOptionShowPowerAlertKey: true,
                  CBCentralManagerScanOptionAllowDuplicatesKey: true] as [String : Any]
        self.manager = CBCentralManager(delegate: self, queue: self.eventQueue, options: options)
    }
    

    public func scanForPeripheral(_ prefixes: [String] = [String](), completion: @escaping ScanningCallback) {
        DispatchQueue.global().async { [weak self] in
            while self?.isPoweredOn == false {
                usleep(100)
            }
            
            self?.manager.delegate = self
            self?.scanningFilter   = prefixes
            self?.scanningCallback = completion
            
            if self?.manager.isScanning == true {
                self?.peripherals = [PeripheralDevice]()
                return
            }
                
            DispatchQueue.main.async { [weak self] in
                self?.peripherals = [PeripheralDevice]()
                self?.manager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    
    @discardableResult
    public func connect(to device: PeripheralDevice, timeout: TimeInterval = 10) -> Bool {
        guard let peripheral = device.peripheral else {
            return false
        }
        
        self.connectingSemaphore.enter()
        self.manager.connect(peripheral, options: nil)
        
        if self.connectingSemaphore.wait(timeout: .now() + timeout) == .timedOut {
            return false
        }
        
        self.connectedDevice = device
        self.lastConnectedDevice = device
        
        return self.discoverServicesForConnectedDevice()
    }
    
    public func scanAndConnect(to name: String, timeout: TimeInterval, callback: @escaping ConnectCallback) {
        Thread.detachNewThread { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.connectCallback = callback
            
            strongSelf.scanAndConnectSemaphore.enter()
            
            strongSelf.scanForPeripheral([name]) { (devices) in
                if let device = devices.first(where: { $0.peripheralName.contains(name) }) {
                    strongSelf.scanAndConnectSemaphore.leave()
                    
                    strongSelf.stopScan()
                    
                    if strongSelf.connect(to: device) {
                        DispatchQueue.main.async { [strongSelf] in strongSelf.connectCallback?(device) }
                    } else {
                        DispatchQueue.main.async { [strongSelf] in strongSelf.connectCallback?(nil) }
                    }
                }
            }
            
            if strongSelf.scanAndConnectSemaphore.wait(timeout: .now() + timeout) == .timedOut {
                DispatchQueue.main.async { [strongSelf] in strongSelf.connectCallback?(nil) }
            }
        }
    }
    
    public func reconnect(timeout: TimeInterval = 10, _ callback: @escaping ((Bool)->Void)) {
        guard let device = self.lastConnectedDevice else {
            DispatchQueue.main.async { callback(false) }
            return
        }
            
        self.scanAndConnect(to: device.peripheralName, timeout: timeout) { (device) in
            if device == nil {
                DispatchQueue.main.async { callback(false) }
            } else {
                DispatchQueue.main.async { callback(true) }
            }
        }
    }
    
    @discardableResult
    private func discoverServicesForConnectedDevice() -> Bool {
        guard
            let device = self.connectedDevice,
            let peripheral = self.connectedDevice?.peripheral else {
                return false
        }
        
        self.serviceSemaphore = ABLEDispatchGroup()
        self.serviceSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        if self.serviceSemaphore.wait(timeout: .now() + 5) == .timedOut {
            return false
        }
        
        //Saving discovered services
        device.services        = peripheral.services ?? [CBService]()
        device.characteristics = [CBCharacteristic]()
        
        device.services.forEach { service in
            if self.discoverCharacteristics(for: service) {
                device.characteristics.append(contentsOf: service.characteristics ?? [CBCharacteristic]())
            }
        }
        
        return true
    }
    
    @discardableResult
    private func discoverCharacteristics(for service: CBService) -> Bool {
        guard let peripheral = self.connectedDevice?.peripheral else {
            return false
        }
        
        self.characteristicSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverCharacteristics(nil, for: service)
        if self.characteristicSemaphore.wait(timeout: .now() + 5) == .timedOut {
            return false
        }
            
        return true
    }
    
    
    public func readData(from characteristic: String, completion: @escaping NotifyCallback) {
        guard
            let device = self.connectedDevice,
            let peripheral = self.connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        self.notifyCallbacks[characteristic] = completion
        peripheral.readValue(for: cbCharacteristic)
    }
    
    public func subscribeRead(to characteristic: String) {
        guard
            let device = self.connectedDevice,
            let peripheral = self.connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }

        if cbCharacteristic.isNotifying {
            peripheral.readValue(for: cbCharacteristic)
            return
        }
        
        DispatchQueue.global().async {
            self.subcribeSemaphore.enter()
            peripheral.setNotifyValue(true, for: cbCharacteristic)
            if self.subcribeSemaphore.wait(timeout: .now() + 5) == .timedOut {
                return
            }
            
            peripheral.readValue(for: cbCharacteristic)
        }
    }
    
    public func subscribe(to characteristic: String, read: Bool=false, completion: @escaping NotifyCallback) {
        guard
            let device = self.connectedDevice,
            let peripheral = self.connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        self.notifyCallbacks[characteristic] = completion
        
        if cbCharacteristic.isNotifying {
            if read {
                peripheral.readValue(for: cbCharacteristic)
            }
            return
        }
        
        DispatchQueue.global().async {
            self.subcribeSemaphore.enter()
            peripheral.setNotifyValue(true, for: cbCharacteristic)
            if self.subcribeSemaphore.wait(timeout: .now() + 5) == .timedOut {
                return
            }
            
            if read {
                peripheral.readValue(for: cbCharacteristic)
            }
        }
     }
    
    public func unsubscribe(to characteristic: String) {
        guard
            let device = self.connectedDevice,
            let peripheral = self.connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        self.notifyCallbacks[characteristic] = nil
        
        if cbCharacteristic.isNotifying == false {
            return
        }
        
        DispatchQueue.global().async {
            self.subcribeSemaphore.enter()
            peripheral.setNotifyValue(false, for: cbCharacteristic)
            if self.subcribeSemaphore.wait(timeout: .now() + 5) == .timedOut {
                return
            }
        }
    }

    public func write(command: ABLECommand, to characteristic: String, modality: CBCharacteristicWriteType = .withResponse, completion: WriteCallback? = nil) {
        guard
            let device = self.connectedDevice,
            let peripheral = device.peripheral else {
                return
        }
        
        self.writeCallbacks[characteristic] = completion
        
        let data = command.getData()
        
        if let cbcharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
            peripheral.writeValue(data, for: cbcharacteristic, type: modality)
        }
    }
    
    public func registerConnnectionObserver(_ callback: @escaping ConnectionKVOCallback) -> NSKeyValueObservation {
        self.connectionStatusCallback = callback
        
        let observer = self.observe(\.isConnected, options: [.old, .new]) { (object, change) in
            let prev   = change.oldValue ?? false
            let actual = change.newValue ?? false
            DispatchQueue.main.async { self.connectionStatusCallback?(prev, actual) }
        }
        
        DispatchQueue.main.async { [weak self] in self?.connectionStatusCallback?(self?.isConnected ?? false, self?.isConnected ?? false) }
        
        return observer
    }
    
    public func disconnect() {
        guard let manager = self.manager else {
            return
        }
        
        guard let peripheral = self.connectedDevice?.peripheral else {
            return
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }

    public func stopScan() {
        guard let manager = self.manager else {
            return
        }
        
        if self.isPoweredOn == false {
            return
        }
        
        if manager.isScanning == true {
            manager.stopScan()
        }
    }
}


extension BluetoothManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")

        case .poweredOff:
            print("PowerOff")
        case .poweredOn:
            print("PowerOn")
            self.manager.delegate = self
            
            if self.scanningCallback != nil {
                let options = [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerScanOptionAllowDuplicatesKey: true]
                self.manager.scanForPeripherals(withServices: nil, options: options)
            }
            
        @unknown default:
            fatalError()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self

        let prefixes = self.scanningFilter ?? [String]()
        let name     = peripheral.name ?? ""
        let advName  = advertisementData["kCBAdvDataLocalName"] as? String ?? ""
        if name.count == 0 && advName.count == 0 && prefixes.count > 0 {
            return
        }
        //print("Name: ", name, " - AdvName: ", advName)
        var match = false
        prefixes.forEach { pref in
            match = match || name.contains(pref) || advName.contains(pref)
        }
        if match == false && prefixes.count > 0 {
            return
        }
        
        let newDevice = PeripheralDevice(with: peripheral, advData: advertisementData, rssi: RSSI)
        let needRefresh = self.peripherals.appendDistinc(newDevice)
        
        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals)
            }
        }
    }
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        let newDevice = PeripheralDevice(with: peripheral)
        let needRefresh = self.peripherals.updatePeripheral(newDevice, sorting: true)

        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.connectedDevice = PeripheralDevice(with: peripheral)
        
        self.connectingSemaphore.leave()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connectedDevice = nil
        self.isConnected = false
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.serviceSemaphore.leave()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.characteristicSemaphore.leave()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            let device = self.connectedDevice,
            let data = characteristic.value else {
                return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let notifyCallback = self?.notifyCallbacks[characteristic.uuid.uuidString] else {
                return
            }
            
            notifyCallback?(device, data, (error == nil))
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let device = self.connectedDevice else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let writeCallback = self?.writeCallbacks[characteristic.uuid.uuidString] else {
                return
            }
            
            writeCallback?(device, (error == nil))
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        self.subcribeSemaphore.leave()
    }
    
}
