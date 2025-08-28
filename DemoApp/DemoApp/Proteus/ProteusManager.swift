//
//  LetsBLEManager.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import CoreBluetooth


public class ProteusManager {
    public static var shared = ProteusManager()
    
    private var startSend:          Date                   = Date()
    private var rawPayload:         String                 = ""
    private var currentCommand:     ProteusCommand         = ProteusCommand()
    private var currentResponse:    ProteusResponse        = ProteusResponse()
    private var connectionObserver: NSKeyValueObservation? = nil
    private var streamCallback:     ((String)->Void)?      = nil
    private var messagesQueue:      [ProteusCommand]       = []
    private var serialQueue:        DispatchQueue          = DispatchQueue(label: "com.able.message.serial.queue")
    private var inFlight:           Bool                   = false
    
    var handleNewMessage: ((ProteusResponse)->Void)?
    
    
    init() {
    
    }
    
    func registerMessagesCallback(_ callback: ((ProteusResponse)->Void)? ) {
        self.handleNewMessage = callback
    }
    
    func removeMessagesCallback() {
        self.handleNewMessage = nil
    }
    
    func registerConnectionObserver(_ callback: @escaping ((Bool)->Void) ) {
        self.connectionObserver = BluetoothManager.shared.registerConnnectionObserver { (prev, actual) in
            callback(actual)
        }
    }
    
    func scanning(_ prefixes: [String] = [String](), _ callback: @escaping (([PeripheralDevice])->Void) ) {
        BluetoothManager.shared.scanForPeripheral(prefixes, completion: callback)
    }
    
    public func stopScan() {
        BluetoothManager.shared.stopScan()
    }
    
    func connect(to device: PeripheralDevice, timeout: TimeInterval=5, _ callback: @escaping ((PeripheralDevice?)->Void) ) {
        self.serialQueue.async {
            BluetoothManager.shared.connect(to: device, timeout: timeout)
            
            DispatchQueue.main.async {
                callback(BluetoothManager.shared.connectedDevice)
            }
            
            self.subscribe { response in
                self.handleNewMessage?(response)
            }
        }
    }
    
    func searchAndConnect(name: String="Proteus", timeout: TimeInterval=5, _ callback: @escaping ((PeripheralDevice?)->Void) ) {
        BluetoothManager.shared.scanAndConnect(to: name, timeout: timeout, callback: callback)
    }

    private func subscribe(characteristic: ProteusCharacteristic = .characteristic1, _ callback: @escaping ((ProteusResponse)->Void)) {
        self.currentResponse = ProteusResponse()
        
        BluetoothManager.shared.subscribe(to: characteristic.rawValue) { (device, response, success) in
            guard success == true, response.isZeroFilled == false else { return }
        
            self.currentResponse.append(data: response)
            let (residuo, list)  = self.splitParts(from: self.currentResponse.rawString)
            self.currentResponse = ProteusResponse()
            self.currentResponse.append(string: residuo)
            
            list.forEach { response in
                if response.isComplete {
                    DispatchQueue.main.async { callback(response) }
                }
            }
            
            print("Response after: \(Date().timeIntervalSince(self.startSend)*1000)")
            self.inFlight = false
            self.writeIfPossible()
        }
    }
    
    func unsubscribe(characteristic: ProteusCharacteristic = .characteristic1) {
        DispatchQueue.global().async {
            BluetoothManager.shared.unsubscribe(to: characteristic.rawValue)
        }
    }
    
    func disconnect() {
        DispatchQueue.global().async {
            self.unsubscribe(characteristic: .characteristic1)
            self.unsubscribe(characteristic: .characteristic2)
            
            BluetoothManager.shared.disconnect()
            self.messagesQueue = []
            self.inFlight      = false
        }
    }
    
    func send(command: ProteusCommand) {
        self.serialQueue.async {
            self.currentResponse = ProteusResponse()
            self.currentCommand  = command
            
            if self.messagesQueue.count == 0 {
                self.messagesQueue.append(command)
            } else {
                self.messagesQueue.removeLast()
                self.messagesQueue.append(command)
            }
            
            self.writeIfPossible()
        }
    }
    
    private func writeIfPossible() {
        let epased = Date().timeIntervalSince(self.startSend)*1000
        if epased > 100 {
            self.inFlight = false
        }
        
        guard self.inFlight == false, self.messagesQueue.count > 0 else {
            return
        }
        
        self.inFlight = true
        let sendingCommand = self.messagesQueue.removeFirst()
        self.write(command: sendingCommand, to: .characteristic2, modality: .withResponse)
    }
    
    private func write(command: ABLECommand, to characteristic: ProteusCharacteristic = .characteristic2, modality: CBCharacteristicWriteType = .withResponse) {
        print("Sending: \(command.rawString)...")
        
        self.startSend = Date()
        BluetoothManager.shared.write(command: command, to: characteristic.rawValue, modality: modality) { (_, success) in
            guard success == true else {
                print("Send failed")
                return
            }
            
            print("Sent after: \(Date().timeIntervalSince(self.startSend)*1000)")
        }
    }
}


extension ProteusManager {
    
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex    = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results  = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            let list     = results.map { nsString.substring(with: $0.range)}
            return list
        } catch let error {
            print("[Cosmolink] Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    private func splitParts(from rawPayload: String) -> (String, [ProteusResponse]) {
        let matched = self.matches(for: "(\\[).*(\\])", in: rawPayload)
        let lista   = matched.compactMap { ProteusResponse(with: $0) }
        
        if matched.count > 0 {
            let count   = matched.reduce(0) {$0 + $1.count}
            var payload = rawPayload.subString(from: count, len: rawPayload.count)
            payload     = payload.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
            return (payload, lista)
        }
        
        return (rawPayload, lista)
    }
}
