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
    
    private var connectingSemaphore: DispatchGroup
    private var subcribeSemaphore: DispatchGroup
    private var serviceSemaphore: DispatchGroup
    private var characteristicSemaphore: DispatchGroup
    
    private var needLeaveConnecting: Bool
    private var needLeaveSubcribe: Bool
    private var needLeaveService: Bool
    private var needLeaveCharacteristic: Bool
    
    private var manager: CBCentralManager!
    private var eventQueue: DispatchQueue!
    private var parameterMap: [DeviceOperationType: Any]!
    
    public var peripherals: [PeripheralDevice]!
    public var connectedDevice: PeripheralDevice?
    private var lastConnectedDevice: PeripheralDevice?
    
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
                connectedDevice = nil
            }
        }
    }
    
    @objc dynamic public var isPoweredOn: Bool {
        get {
            if let manager = manager {
                return manager.state == .poweredOn
            }
            
            return false
        }
    }
    
    private override init() {
        connectingSemaphore = DispatchGroup()
        serviceSemaphore = DispatchGroup()
        characteristicSemaphore = DispatchGroup()
        subcribeSemaphore = DispatchGroup()
        
        needLeaveConnecting = false
        needLeaveService = false
        needLeaveCharacteristic = false
        needLeaveSubcribe = false
        
        parameterMap = [DeviceOperationType: Any]()
        
        peripherals = [PeripheralDevice]()
        eventQueue = DispatchQueue(label: "it.able.ble.event.queue")

        scanningCallback = nil
        connectCallback = nil
        writeCallback = nil
        notifyCallback = nil
        
        super.init()
        manager = CBCentralManager(delegate: self, queue: eventQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    public func scanAndConnect(to name: String, callback: @escaping ConnectCallback) {
        while isPoweredOn == false {
            sleep(1)
        }
        
        connectCallback = callback
        
        scanForPeripheral(name) { (devices) in
            if devices.count == 1, devices[0].peripheral.name == name {
                self.stopScan()
                
                self.connect(to: devices[0])
                
                self.connectCallback?(devices[0])
            }
        }
    }

    public func scanForPeripheral(_ prefix: String? = nil, completion: @escaping ScanningCallback) {
        parameterMap[.Scanning] = prefix
        scanningCallback = completion
        peripherals = [PeripheralDevice]()
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    @discardableResult
    public func connect(to device: PeripheralDevice) -> Bool {
        parameterMap[.Connect] = device.peripheral.name
        
        if device.peripheral.state != .connected {
            connectingSemaphore.enter()
            needLeaveConnecting = true
            manager.connect(device.peripheral, options: nil)

            if connectingSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
        }
        
        connectedDevice = device
        lastConnectedDevice = connectedDevice
        
        return discoverServicesForConnectedDevice()
    }

    @discardableResult
    public func reconnect() -> Bool {
        if let device = lastConnectedDevice {
            isConnected = connect(to: device)
        } else {
            isConnected = false
        }
        
        return isConnected
    }
    
    @discardableResult
    private func discoverServicesForConnectedDevice() -> Bool {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Service] = peripheral.name
            
            serviceSemaphore.enter()
            needLeaveService = true
            
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            if serviceSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
            
            //Saving discovered services
            connectedDevice?.services = peripheral.services ?? [CBService]()
            
            var result: Bool = true
            peripheral.services?.forEach{ (service) in
                let res = discoverCharacteristicsForConnectedDevice(for: service)
                if res == true {
                    //Saving discovered characteristics
                    if connectedDevice?.characteristics == nil {
                        connectedDevice?.characteristics = [CBCharacteristic]()
                    }
                    
                    connectedDevice?.characteristics.append(contentsOf: service.characteristics ?? [CBCharacteristic]())
                }
                
                result = result && res
            }
            
            return result
        }
        
        return false
    }
    
    @discardableResult
    private func discoverCharacteristicsForConnectedDevice(for service: CBService) -> Bool {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Characteristic] = peripheral.name
            
            characteristicSemaphore.enter()
            needLeaveCharacteristic = true
            peripheral.delegate = self
            peripheral.discoverCharacteristics(nil, for: service)
            if characteristicSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    
    public func readData(from characteristic: String, completion: @escaping NotifyCallback) {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Read] = peripheral.name
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
                notifyCallback = completion
                peripheral.readValue(for: cbcharacteristic)
            }
        }
    }
    
    public func subscribeRead(to characteristic: String, completion: @escaping NotifyCallback) {
        if let peripheral = connectedDevice?.peripheral {
            unsubscribe(to: characteristic)
            
            parameterMap[.Subscribe] = peripheral.name
            
            notifyCallback = completion
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
                if cbcharacteristic.isNotifying {
                    peripheral.readValue(for: cbcharacteristic)
                    return
                }
                
                subcribeSemaphore.enter()
                needLeaveSubcribe = true
                peripheral.setNotifyValue(true, for: cbcharacteristic)
                subcribeSemaphore.wait()
                
                peripheral.readValue(for: cbcharacteristic)
            }
        } else {
            //completion(PeripheralDevice(), Data(), false)
        }
    }
    
    public func subscribe(to characteristic: String, completion: @escaping NotifyCallback) {
        if let peripheral = connectedDevice?.peripheral {
            unsubscribe(to: characteristic)
            
            parameterMap[.Subscribe] = peripheral.name
            
            notifyCallback = completion
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
                if cbcharacteristic.isNotifying {
                    return
                }
                
                subcribeSemaphore.enter()
                needLeaveSubcribe = true
                peripheral.setNotifyValue(true, for: cbcharacteristic)
                subcribeSemaphore.wait()
            }
        } else {
            //completion(PeripheralDevice(), Data(), false)
        }
    }
    
    public func unsubscribe(to characteristic: String) {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Subscribe] = peripheral.name
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
                if cbcharacteristic.isNotifying {
                    return
                }
                
                subcribeSemaphore.enter()
                needLeaveSubcribe = true
                peripheral.setNotifyValue(false, for: cbcharacteristic)
                subcribeSemaphore.wait()
            }
        }
    }

    public func write(command: ABLECommand, to characteristic: String, modality: CBCharacteristicWriteType = .withResponse, completion: ( (PeripheralDevice, Bool)->Void)? = nil) {
        
        if let device = connectedDevice {
            parameterMap[.Write] = device.peripheral.name
            
            let data = command.rawData
            
            if let cbcharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic}) {
                if modality == .withResponse {
                    //print("Writing \(command.rawString) to characteristic: \(cbcharacteristic.uuid.uuidString)...")
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
    }
    
    public func registerConnnectionObserver(_ callback: @escaping ((Bool) -> ())) -> NSKeyValueObservation {
        let observer = self.observe(\.isConnected, options: [.old, .new]) { (object, change) in
            DispatchQueue.main.async {
                callback(self.isConnected)
            }
        }
        
        callback(self.isConnected)
        return observer
    }
    
    public func disconnect() {
        if let peripheral = connectedDevice?.peripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    public func stopScan() {
        manager.stopScan()
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
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Found Peripheral: \(peripheral.name ?? "No Nome")")
        
        let prefix = parameterMap[.Scanning] as? String ?? ""
        let name = peripheral.name ?? ""
        if name.count == 0 || prefix.count > 0 {
            if name.contains(prefix) == false && name.contains("IdroCtrl") == false {
                return
            }
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
            isConnected = true
            
            if needLeaveConnecting == true {
                needLeaveConnecting = false
                connectingSemaphore.leave()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let name = parameterMap[.Service] as? String, name == peripheral.name {
            if needLeaveService == true {
                needLeaveService = false
                serviceSemaphore.leave()
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let name = parameterMap[.Characteristic] as? String, name == peripheral.name {
            if needLeaveCharacteristic == true {
                needLeaveCharacteristic = false
                characteristicSemaphore.leave()
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("Received: \(characteristic.value?.toHexString() ?? "")")
            
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
        //print("Notification enabled: \(characteristic.isNotifying)")
        
        if needLeaveSubcribe == true {
            needLeaveSubcribe = false
            subcribeSemaphore.leave()
        }
    }
    
}
