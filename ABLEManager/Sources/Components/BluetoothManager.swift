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

public typealias TimeoutCallback  = (()->())
public typealias ScanningCallback = (([PeripheralDevice])->Void)
public typealias ConnectCallback  = ((PeripheralDevice?)->Void)
public typealias WriteCallback    = ((PeripheralDevice, Bool)->Void)
public typealias NotifyCallback   = ((PeripheralDevice, Data, Bool)->Void)

public class BluetoothManager: NSObject {
    
    public static let shared: BluetoothManager = BluetoothManager()
    
    private var connectingSemaphore:     ABLEDispatchGroup
    private var subcribeSemaphore:       ABLEDispatchGroup
    private var serviceSemaphore:        ABLEDispatchGroup
    private var characteristicSemaphore: ABLEDispatchGroup
    private var reconnectionSemaphore:   ABLEDispatchGroup
    
    private var manager:        CBCentralManager!
    private var eventQueue:     DispatchQueue!
    private var scanningFilter: [String]?
    
    public var peripherals:         [PeripheralDevice]?
    public var connectedDevice:     PeripheralDevice?
    public var lastConnectedDevice: PeripheralDevice?
    
    private var scanningCallback: ScanningCallback?
    private var connectCallback:  ConnectCallback?
    private var writeCallback:    WriteCallback?
    private var notifyCallback:   NotifyCallback?
    
    
    @objc dynamic public var isConnected: Bool {
        get {
            guard
                let device = connectedDevice,
                let peripheral = device.peripheral else {
                    return false
            }
            
            return peripheral.state == .connected
        }
        
        set(newValue) {
            if newValue == false {
                self.connectedDevice = nil
            }
        }
    }
    
    @objc dynamic public var isPoweredOn: Bool {
        guard let manager = self.manager else {
            return false
        }
        
        return manager.state == .poweredOn
    }
    
    private override init() {
        connectingSemaphore     = ABLEDispatchGroup()
        serviceSemaphore        = ABLEDispatchGroup()
        characteristicSemaphore = ABLEDispatchGroup()
        subcribeSemaphore       = ABLEDispatchGroup()
        reconnectionSemaphore   = ABLEDispatchGroup()
        
        peripherals = [PeripheralDevice]()
        eventQueue  = DispatchQueue(label: "it.able.ble.event.queue")

        scanningFilter   = nil
        scanningCallback = nil
        connectCallback  = nil
        writeCallback    = nil
        notifyCallback   = nil
        
        manager = CBCentralManager(delegate: nil, queue: eventQueue, options: [CBCentralManagerOptionShowPowerAlertKey:      true,
                                                                               CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
        super.init()
    }
    

    public func scanForPeripheral(_ prefixes: [String] = [String](), completion: @escaping ScanningCallback) {
        self.scanningFilter   = prefixes
        self.scanningCallback = completion
        self.peripherals      = [PeripheralDevice]()
        
        self.manager.delegate = self
        
        if self.isPoweredOn {
            self.manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    
    @discardableResult
    public func connect(to device: PeripheralDevice) -> Bool {
        guard let peripheral = device.peripheral else {
            return false
        }
        
        connectingSemaphore.enter()
        manager.connect(peripheral, options: nil)
        
        if connectingSemaphore.wait(timeout: .now() + 4) == .timedOut {
            return false
        }
        
        connectedDevice = device
        lastConnectedDevice = device
        
        return discoverServicesForConnectedDevice()
    }
    
    public func scanAndConnect(to name: String, callback: @escaping ConnectCallback) {
        Thread.detachNewThread { [weak self] in
            guard let strongSelf = self else {
                DispatchQueue.main.async { callback(nil); }
                return
            }
                
            while strongSelf.isPoweredOn == false {
                usleep(2000) // 2 millesec
            }
            
            strongSelf.connectCallback = callback
            
            strongSelf.scanForPeripheral([name]) { (devices) in
                if let device = devices.first(where: { $0.peripheralName.contains(name) }) {
                    strongSelf.stopScan()
                    
                    if strongSelf.connect(to: device) {
                        DispatchQueue.main.async { strongSelf.connectCallback?(device) }
                    } else {
                        DispatchQueue.main.async { strongSelf.connectCallback?(nil) }
                    }
                }
            }
        }
    }
    
    public func reconnect( _ callback: @escaping ((Bool)->Void)) {
        Thread.detachNewThread { [weak self] in
            guard
                let strongSelf = self,
                let device = strongSelf.lastConnectedDevice else {
                    DispatchQueue.main.async { callback(false) }
                    return
            }
            
            strongSelf.reconnectionSemaphore.enter()
            strongSelf.scanAndConnect(to: device.peripheralName) { (device) in
                strongSelf.reconnectionSemaphore.leave()
                DispatchQueue.main.async { callback(true) }
            }
            
            if strongSelf.reconnectionSemaphore.wait(timeout: .now() + 10) == .timedOut {
                DispatchQueue.main.async { callback(false) }
            }
        }
    }
    
    @discardableResult
    private func discoverServicesForConnectedDevice() -> Bool {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral else {
                return false
        }
        
        serviceSemaphore = ABLEDispatchGroup()
        serviceSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        if serviceSemaphore.wait(timeout: .now() + 4) == .timedOut {
            return false
        }
        
        //Saving discovered services
        device.services        = peripheral.services ?? [CBService]()
        device.characteristics = [CBCharacteristic]()
        
        device.services.forEach { service in
            if discoverCharacteristics(for: service) {
                device.characteristics.append(contentsOf: service.characteristics ?? [CBCharacteristic]())
            }
        }
        
        return true
    }
    
    @discardableResult
    private func discoverCharacteristics(for service: CBService) -> Bool {
        guard let peripheral = connectedDevice?.peripheral else {
            return false
        }
        
        characteristicSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverCharacteristics(nil, for: service)
        if characteristicSemaphore.wait(timeout: .now() + 4) == .timedOut {
            return false
        }
            
        return true
    }
    
    
    public func readData(from characteristic: String, completion: @escaping NotifyCallback) {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        notifyCallback = completion
        peripheral.readValue(for: cbCharacteristic)
    }
    
    public func subscribeRead(to characteristic: String) {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }

        if cbCharacteristic.isNotifying {
            peripheral.readValue(for: cbCharacteristic)
            return
        }
        
        subcribeSemaphore.enter()
        peripheral.setNotifyValue(true, for: cbCharacteristic)
        subcribeSemaphore.wait()
        
        peripheral.readValue(for: cbCharacteristic)
    }
    public func subscribeRead(to characteristic: String, completion: @escaping NotifyCallback) {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
    
        notifyCallback = completion
        
        if cbCharacteristic.isNotifying {
            peripheral.readValue(for: cbCharacteristic)
            return
        }
            
        subcribeSemaphore.enter()
        peripheral.setNotifyValue(true, for: cbCharacteristic)
        subcribeSemaphore.wait()
        
        peripheral.readValue(for: cbCharacteristic)
    }
    
    public func subscribe(to characteristic: String, completion: @escaping NotifyCallback) {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        notifyCallback = completion
        
        if cbCharacteristic.isNotifying == true {
            return
        }
        
        subcribeSemaphore.enter()
        peripheral.setNotifyValue(true, for: cbCharacteristic)
        subcribeSemaphore.wait()
    }
    
    public func unsubscribe(to characteristic: String) {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral,
            let cbCharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) else {
                return
        }
        
        if cbCharacteristic.isNotifying == false {
            return
        }
        
        subcribeSemaphore.enter()
        peripheral.setNotifyValue(false, for: cbCharacteristic)
        subcribeSemaphore.wait()
    }

    public func write(command: ABLECommand, to characteristic: String, modality: CBCharacteristicWriteType = .withResponse, completion: WriteCallback? = nil) {
        guard
            let device = connectedDevice,
            let peripheral = device.peripheral else {
            return
        }
        
        writeCallback = completion
        
        let data = command.getData()
        
        if let cbcharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
            peripheral.writeValue(data, for: cbcharacteristic, type: modality)
        }
    }
    
    public func registerConnnectionObserver(_ callback: @escaping ((Bool, Bool) -> ())) -> NSKeyValueObservation {
        let observer = self.observe(\.isConnected, options: [.old, .new]) { (object, change) in
            let prev   = change.oldValue ?? false
            let actual = change.newValue ?? false
            DispatchQueue.main.async { callback(prev, actual) }
        }
        
        DispatchQueue.main.async { callback(self.isConnected, self.isConnected) }
        
        return observer
    }
    
    public func disconnect() {
        guard
            let manager    = manager,
            let peripheral = connectedDevice?.peripheral else {
                return
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }

    public func stopScan() {
        guard let manager = manager else {
            return
        }
        
        if isPoweredOn == false {
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
            manager.delegate = self
            
            if self.scanningCallback != nil {
                self.manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerOptionShowPowerAlertKey:      true,
                                                                             CBCentralManagerScanOptionAllowDuplicatesKey: true])
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
        if name.count == 0 && prefixes.count > 0 {
            return
        }
        
        var match = false
        prefixes.forEach { prefix in
            match = match || name.contains(prefix)
        }
        if match == false && prefixes.count > 0 {
            return
        }
        
        let newDevice   = PeripheralDevice(with: peripheral, advData: advertisementData, rssi: RSSI)
        let needRefresh = peripherals?.appendDistinc(newDevice, sorting: true) ?? false
        
        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals ?? [PeripheralDevice]())
            }
        }
    }
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        let newDevice   = PeripheralDevice(with: peripheral)
        let needRefresh = peripherals?.updatePeripheral(newDevice, sorting: true) ?? false

        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals ?? [PeripheralDevice]())
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //connectedDevice = PeripheralDevice(with: peripheral)
        isConnected = true
        
        connectingSemaphore.leave()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //connectedDevice = nil
        isConnected = false
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        serviceSemaphore.leave()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        characteristicSemaphore.leave()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            let device = connectedDevice,
            let data = characteristic.value else {
                return
        }
        
        DispatchQueue.main.async {
            self.notifyCallback?(device, data, (error == nil))
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let device = connectedDevice else {
            return
        }
        
        DispatchQueue.main.async {
            self.writeCallback?(device, (error == nil))
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        subcribeSemaphore.leave()
    }
    
}
