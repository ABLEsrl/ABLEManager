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
    
    private var rawPayload:         String                 = ""
    private var currentCommand:     ProteusCommand          = ProteusCommand()
    private var currentResponse:    ProteusResponse         = ProteusResponse()
    private var connectionObserver: NSKeyValueObservation? = nil
    private var streamCallback:     ((String)->Void)?      = nil
    

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

    func subscribe(characteristic: ProteusCharacteristic = .characteristic1, _ callback: @escaping ((String)->Void)) {
        self.currentResponse = ProteusResponse()
        
        BluetoothManager.shared.subscribe(to: characteristic.rawValue) { (device, response, success) in
            guard response.isZeroFilled == false else {
                print("Received empty response")
                return
            }
        
            self.currentResponse.append(data: response)
            let (residuo, list)  = self.splitParts(from: self.currentResponse.rawString)
            self.currentResponse = ProteusResponse()
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
    
    func read(characteristic: ProteusCharacteristic = .characteristic2) -> ProteusResponse {
        let char = BluetoothManager.shared.connectedDevice?.characteristics.first(where: { $0.uuid.uuidString.uppercased() == characteristic.rawValue.uppercased() })
        let res = ProteusResponse(with: char?.value?.asciiString ?? "")
        return res
    }
    
    func send(command: ProteusCommand) {
        self.currentResponse = ProteusResponse()
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
            self.write(command: command, to: .characteristic2)
        //}
    }
    
    private func write(command: ABLECommand?, to characteristic: ProteusCharacteristic = .characteristic2, modality: CBCharacteristicWriteType = .withResponse) {
        
        guard let ableCommand = command else {
            return
        }
        
        DispatchQueue.global().async {
            BluetoothManager.shared.write(command: ableCommand, to: characteristic.rawValue, modality: modality) { (_, success) in
                guard success == true else {
                    print("Send failed")
                    return
                }
                
                print("Send success")
            }
        }
    }
}



extension ProteusManager {
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
    
    private func splitParts(from rawPayload: String) -> (String, [ProteusResponse]) {
        let lista: [ProteusResponse] = self.matches(for: "(\\[).*(\\])", in: rawPayload).compactMap {
            let resp = ProteusResponse()
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


extension String {
    public func indexOf(char: Character) -> Int? {
        if let idx = firstIndex(of: char) {
            return distance(from: startIndex, to: idx)
        }
        
        return nil
    }
    
    public func getFragment(from: Character, to: Character) -> (Int, Int, String)? {
        if count < 1 {
            return nil
        }
        
        if let startIdx = self.indexOf(char: from),
           let stopIdx = self.indexOf(char: to),
           startIdx < stopIdx {
              return (startIdx, stopIdx+1, subString(from: startIdx, len: stopIdx-startIdx+1))
        }
        
        return nil
    }
}


extension NSRegularExpression {
    
    func split(_ str: String) -> [String] {
        let range = NSRange(location: 0, length: str.count)
        
        //get locations of matches
        var matchingRanges: [NSRange] = []
        let matches: [NSTextCheckingResult] = self.matches(in: str, options: [], range: range)
        for match: NSTextCheckingResult in matches {
            matchingRanges.append(match.range)
        }
        
        //invert ranges - get ranges of non-matched pieces
        var pieceRanges: [NSRange] = []
        
        //add first range
        pieceRanges.append(NSRange(location: 0, length: (matchingRanges.count == 0 ? str.count : matchingRanges[0].location)))
        
        //add between splits ranges and last range
        for i in 0..<matchingRanges.count {
            let isLast = i + 1 == matchingRanges.count
            
            let location = matchingRanges[i].location
            let length = matchingRanges[i].length
            
            let startLoc = location + length
            let endLoc = isLast ? str.count : matchingRanges[i + 1].location
            pieceRanges.append(NSRange(location: startLoc, length: endLoc - startLoc))
        }
        
        var pieces: [String] = []
        for range: NSRange in pieceRanges {
            let piece = (str as NSString).substring(with: range)
            pieces.append(piece)
        }
        
        return pieces
    }
  
}
