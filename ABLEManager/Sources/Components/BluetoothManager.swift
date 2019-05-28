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

public typealias TimeoutCallback = (()->())
public typealias ScanningCallback = (([PeripheralDevice])->Void)
public typealias ConnectCallback = ((PeripheralDevice)->Void)
public typealias WriteCallback = ((PeripheralDevice, Bool)->Void)
public typealias NotifyCallback = ((PeripheralDevice, Data, Bool)->Void)

public class BluetoothManager: NSObject {
    
    public static var shared: BluetoothManager = BluetoothManager()
    
    private var connectingSemaphore: ABLEDispatchGroup
    private var subcribeSemaphore: ABLEDispatchGroup
    private var serviceSemaphore: ABLEDispatchGroup
    private var characteristicSemaphore: ABLEDispatchGroup
    private var reconnectionSemaphore: ABLEDispatchGroup
    
    private var manager: CBCentralManager!
    private var eventQueue: DispatchQueue!
    private var parameterMap: [DeviceOperationType: Any]!
    
    public var peripherals: [PeripheralDevice]!
    public var connectedDevice: PeripheralDevice?
    public var lastConnectedDevice: PeripheralDevice?
    
    private var scanningCallback: ScanningCallback?
    private var connectCallback: ConnectCallback?
    private var writeCallback: WriteCallback?
    private var notifyCallback: NotifyCallback?
    
    @objc dynamic public var isConnected: Bool {
        get {
            if let device = connectedDevice {
                return device.peripheral.state == .connected
            }
            
            return false
        }
        set (newValue) {
            if newValue == false {
                self.connectedDevice = nil
            }
        }
    }
    
    @objc dynamic public var isPoweredOn: Bool {
        get {
            if let manager = self.manager {
                return manager.state == .poweredOn
            }
            
            return false
        }
    }
    
    private override init() {
        connectingSemaphore = ABLEDispatchGroup()
        serviceSemaphore = ABLEDispatchGroup()
        characteristicSemaphore = ABLEDispatchGroup()
        subcribeSemaphore = ABLEDispatchGroup()
        reconnectionSemaphore = ABLEDispatchGroup()
        
        parameterMap = [DeviceOperationType: Any]()
        
        peripherals = [PeripheralDevice]()
        eventQueue = DispatchQueue(label: "it.able.ble.event.queue")

        scanningCallback = nil
        connectCallback = nil
        writeCallback = nil
        notifyCallback = nil
        
        manager = CBCentralManager(delegate: nil, queue: eventQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        
        super.init()
    }
    
    public func scanAndConnect(to name: String, callback: @escaping ConnectCallback) {
        Thread.detachNewThread {
            while self.isPoweredOn == false {
                sleep(1)
            }
            
            self.connectCallback = callback
            
            self.scanForPeripheral([name]) { (devices) in
                if devices.count == 1, devices[0].peripheral.name == name {
                    self.stopScan()
                    
                    self.connect(to: devices[0])
                    
                    DispatchQueue.main.async {
                        self.connectCallback?(devices[0])
                    }
                }
            }
        }
    }

    public func scanForPeripheral(_ prefixes: [String] = [String](), completion: @escaping ScanningCallback) {
        self.parameterMap[.Scanning] = prefixes
        self.scanningCallback = completion
        self.peripherals = [PeripheralDevice]()
        
        self.manager.delegate = self
        self.manager.scanForPeripherals(withServices: nil, options: nil)
    }

    
    @discardableResult
    public func connect(to device: PeripheralDevice) -> Bool {
        parameterMap[.Connect] = device.peripheralName
        
        connectingSemaphore.enter()
        manager.connect(device.peripheral, options: nil)

        if connectingSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
            return false
        }
        
        connectedDevice = device
        lastConnectedDevice = device
        
        return discoverServicesForConnectedDevice()
    }

    public func reconnect( _ callback: @escaping ((Bool)->Void)) {
        Thread.detachNewThread { [weak self] in
            if let device = self?.lastConnectedDevice {
                self?.reconnectionSemaphore = ABLEDispatchGroup()
                self?.reconnectionSemaphore.enter()
                self?.scanAndConnect(to: device.peripheralName) { (device) in
                    self?.reconnectionSemaphore.leave()
                    callback(true)
                }
                
                if self?.reconnectionSemaphore.wait(timeout: .now() + 10) == .timedOut {
                    callback(false)
                }
            } else {
                callback(false)
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
        
        parameterMap[.Service] = peripheral.name
        
        serviceSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        if serviceSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
            return false
        }
        
        //Saving discovered services
        device.services = peripheral.services ?? [CBService]()
        device.characteristics = [CBCharacteristic]()
        
        device.services.forEach{ (service) in
            if discoverCharacteristicsForConnectedDevice(for: service) {
                device.characteristics.append(contentsOf: service.characteristics ?? [CBCharacteristic]())
            }
        }
        
        return true
    }
    
    @discardableResult
    private func discoverCharacteristicsForConnectedDevice(for service: CBService) -> Bool {
        guard
            let device = connectedDevice,
            let peripheral = connectedDevice?.peripheral else {
                return false
        }
        
        parameterMap[.Characteristic] = device.peripheralName
        
        characteristicSemaphore.enter()
        
        peripheral.delegate = self
        peripheral.discoverCharacteristics(nil, for: service)
        if characteristicSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
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
        
        parameterMap[.Read] = device.peripheralName
        
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
        
        parameterMap[.Subscribe] = device.peripheralName

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
    
        parameterMap[.Subscribe] = peripheral.name
        
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
        
        parameterMap[.Subscribe] = device.peripheralName
        
        notifyCallback = completion
        
        if cbCharacteristic.isNotifying {
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
    
        parameterMap[.Subscribe] = device.peripheralName
        if cbCharacteristic.isNotifying {
            return
        }
            
        subcribeSemaphore.enter()
        peripheral.setNotifyValue(false, for: cbCharacteristic)
        subcribeSemaphore.wait()
    }

    public func write(command: ABLECommand, to characteristic: String, modality: CBCharacteristicWriteType = .withResponse, completion: ( (PeripheralDevice, Bool)->Void)? = nil) {
        
        guard let device = connectedDevice else {
            return
        }
        
        parameterMap[.Write] = device.peripheralName
        
        let data = command.getData()
        
        if let cbcharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
            if modality == .withResponse {
                if let callback = completion {
                    writeCallback = callback
                }
                
                device.peripheral.writeValue(data, for: cbcharacteristic, type: .withResponse)
            }
            else {
                device.peripheral.writeValue(data, for: cbcharacteristic, type: .withoutResponse)
            }
        }
    }
    
    public func registerConnnectionObserver(_ callback: @escaping ((Bool) -> ())) -> NSKeyValueObservation {
        let observer = self.observe(\.isConnected, options: [.old, .new]) { (object, change) in
            DispatchQueue.main.async {
                callback(self.isConnected)
            }
        }
        
        DispatchQueue.main.async {
            callback(self.isConnected)
        }
        
        return observer
    }
    
    public func disconnect() {
        guard
            let manager = manager,
            let peripheral = connectedDevice?.peripheral else {
                return
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }

    public func stopScan() {
        if isPoweredOn == false {
            return
        }
        
        if let manager = manager {
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
                self.manager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Found Peripheral: \(peripheral.name ?? "No Nome")")
        
        let prefixes = parameterMap[.Scanning] as? [String] ?? [String]()
        let name = peripheral.name ?? ""
        if name.count == 0 {
            return
        }
        
        var match = false
        prefixes.forEach { (prefix) in
            match = match || name.contains(prefix)
        }
        if match == false && prefixes.count > 0 {
            return
        }
        
        let needRefresh = peripherals.appendDistinc(PeripheralDevice(with: peripheral))
        peripherals = peripherals.sorted()
        
        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let name = parameterMap[.Connect] as? String, name == peripheral.name {
            connectedDevice = PeripheralDevice(with: peripheral)
            isConnected = true
            
            connectingSemaphore.leave()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedDevice = nil
        isConnected = false
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let name = parameterMap[.Service] as? String, name == peripheral.name {
            serviceSemaphore.leave()
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let name = parameterMap[.Characteristic] as? String, name == peripheral.name {
            characteristicSemaphore.leave()
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let connectedDev = connectedDevice, let data = characteristic.value {
            DispatchQueue.main.async {
                self.notifyCallback?(connectedDev, data, (error == nil))
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let connectedDev = connectedDevice {
            DispatchQueue.main.async {
                self.writeCallback?(connectedDev, (error == nil))
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        subcribeSemaphore.leave()
    }
    
}
