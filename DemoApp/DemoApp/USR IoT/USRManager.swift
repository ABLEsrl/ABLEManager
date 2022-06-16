//
//  USRManager.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import CoreBluetooth


public class USRManager {
    public static var shared = USRManager()
    
    private var startSend:          Date                   = Date()
    private var rawPayload:         String                 = ""
    private var currentCommand:     USRCommand             = USRCommand()
    private var currentResponse:    USRResponse            = USRResponse()
    private var connectionObserver: NSKeyValueObservation? = nil
    private var streamCallback:     ((String)->Void)?      = nil
    
    private var serialQueue = DispatchQueue(label: "serial.queue.com.able")
    
    
    init() {
    
    }
    
    func registerConnectionObserver(_ callback: @escaping ((Bool)->Void) ) {
        connectionObserver = BluetoothManager.shared.registerConnnectionObserver { (prev, actual) in
            callback(actual)
        }
    }
    
    func scanning(_ prefixes: [String] = [String](), _ callback: @escaping (([PeripheralDevice])->Void) ) {
        BluetoothManager.shared.scanForPeripheral(prefixes) { (devices) in
            callback(devices)
        }
    }
    
    public func stopScan() {
        BluetoothManager.shared.stopScan()
    }
    
    func connect(to device: PeripheralDevice, timeout: TimeInterval=10, _ callback: @escaping ((PeripheralDevice?)->Void)) {
        DispatchQueue.global().async {
            BluetoothManager.shared.connect(to: device, timeout: timeout)
            
            DispatchQueue.main.async {
                callback(BluetoothManager.shared.connectedDevice)
            }
        }
    }
    
    func searchAndConnect(name: String="Proteus", timeout: TimeInterval=10, _ callback: @escaping ((PeripheralDevice)->Void) ) {
        BluetoothManager.shared.scanAndConnect(to: name, timeout: timeout) { device in
            guard let device = device else { return }
            
            callback(device)
        }
    }

    func subscribe(characteristic: USRCharacteristics = .characteristic1, _ callback: @escaping ((String)->Void)) {
        self.currentResponse = USRResponse()
        
        BluetoothManager.shared.subscribe(to: characteristic.rawValue) { (device, response, success) in
            guard response.isZeroFilled == false else {
                print("Received empty response")
                return
            }
        
            self.currentResponse.append(data: response)
            let (residuo, list)  = self.splitParts(from: self.currentResponse.rawString)
            self.currentResponse = USRResponse()
            self.currentResponse.append(string: residuo)
            
            list.forEach { response in
                if response.isComplete {
                    var data = response.rawString
                    data = data.replacingOccurrences(of: "<", with: "")
                    data = data.replacingOccurrences(of: ">", with: "")
                    
                    DispatchQueue.main.async { callback(data) }
                }
            }
        }
    }
    
    func unsubscribe(characteristic: ProteusCharacteristic = .characteristic1) {
        BluetoothManager.shared.unsubscribe(to: characteristic.rawValue)
    }
    
    func disconnect() {
        BluetoothManager.shared.disconnect()
    }
    
    func read(characteristic: USRCharacteristics = .characteristic2) -> USRResponse {
        let char = BluetoothManager.shared.connectedDevice?.characteristics.first(where: { $0.uuid.uuidString.uppercased() == characteristic.rawValue.uppercased() })
        let res = USRResponse(with: char?.value?.asciiString ?? "")
        return res
    }
    
    func send(command: USRCommand) {
        
        self.serialQueue.async {
            self.currentResponse = USRResponse()
            self.currentCommand  = command
            
            /*
            BluetoothManager.shared.subscribe(to: ProteusCharacteristic.characteristic1.rawValue) { (device, response, success) in
                guard response.isZeroFilled == false else {
                    print("Received empty response")
                    return
                }
                
                self.currentResponse.append(data: response)
                
                if self.currentResponse.isComplete {
                    DispatchQueue.main.async {
                        callback(self.currentResponse)
                        self.currentResponse = ProteusResponse()
                    }
                }
            }
            */
            
            //DispatchQueue.global().async {
            //    usleep(useconds_t(100 * 1000))
                print("Sending: \(command.rawString)")
                self.write(command: command, to: .characteristic2)
            //}
        }
    }
    
    private func write(command: ABLECommand?, to characteristic: ProteusCharacteristic = .characteristic2, modality: CBCharacteristicWriteType = .withResponse) {
        guard let ableCommand = command else { return }
        
        let semaphore = ABLEDispatchGroup()
        semaphore.enter()
        
        self.startSend = Date()
        BluetoothManager.shared.write(command: ableCommand, to: characteristic.rawValue, modality: modality) { (_, success) in
            guard success == true else {
                print("Send failed")
                return
            }
            
            print("Response time: \(Date().timeIntervalSince(self.startSend)*1000)")
            //print("Send success")
            semaphore.leave()
        }
        
        semaphore.wait()
    }
}



extension USRManager {
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex    = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results  = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    private func splitParts(from rawPayload: String) -> (String, [USRResponse]) {
        let lista: [USRResponse] = self.matches(for: "(\\[).*(\\])", in: rawPayload).compactMap {
            let resp = USRResponse()
            resp.append(string: String($0))
            print($0)
            return resp
        }
        
        if lista.count > 0 {
            let count = lista.reduce(0) {$0 + $1.rawString.count}
            let newPayload = rawPayload.subString(from: count, len: rawPayload.count)
            return (newPayload, lista)
        }
        
        return (rawPayload, lista)
    }
}
