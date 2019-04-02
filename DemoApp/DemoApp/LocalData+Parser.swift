//
//  Data+Parser.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

extension Data {
    var isZeroFilled: Bool {
        get {
            var res = true
            self.hexString.forEach { (element) in
                if String(element) != "0" {
                    res = false
                }
            }
            return res
        }
    }
    
    var commandCode: CommandCode {
        get {
            let prefix = self.hexString.subString(from: 0, len: 2)
            if let value = Utils.hexToInt(prefix), let unicode = UnicodeScalar(value) {
                let string = String(Character(unicode))
                return CommandCode(rawValue: string) ?? .UNDEF
            }
            
            return .UNDEF
        }
    }
    
    var gateway: String {
        get {
            let hexString = self.hexString
            if hexString.count >= 10 {
                let gateway = hexString.subString(from: 2, len: 8)
                return gateway
            }
            
            return ""
        }
    }
    
    func ack(_ location: Int) -> String {
        let hexString = self.hexString
        if hexString.count >= 12 {
            let ack = hexString.subString(from: location, len: 2)
            return ack
        }
        
        return ""
    }
    
    
    var taget: String {
        get {
            let hexString = self.hexString
            if hexString.count > 10 {
                let taget = hexString.subString(from: 10, len: 18)
                return taget
            }
            
            return ""
        }
    }
    
    var reply: String {
        get {
            let hexString = self.hexString
            let len = hexString.count - 18
            if hexString.count > 18, len > 0 {
                let reply = hexString.subString(from: 18, len: len)
                return reply
            }
            
            return ""
        }
    }
    
    var nodes: String {
        get {
            let hexString = self.hexString
            let len = hexString.count - 20 - 4 
            if hexString.count > 20, len > 0 {
                let reply = hexString.subString(from: 20, len: len)
                return reply
            }
            
            return ""
        }
    }
    
    var sensorValues: [Int] {
        get {
            let nodes = self.nodes.split(by: 2)
            let values = nodes.map { Utils.hexToInt($0) ?? 0 }
            let valuesBit = [ ((values[0] & 0b11111111) << 2) + (values[1] >> 6 & 0b00000011),
                              ((values[1] & 0b00111111) << 4) + (values[2] >> 4 & 0b00001111),
                              ((values[2] & 0b00001111) << 6) + (values[3] >> 2 & 0b00111111),
                              ((values[3] & 0b00000011) << 8) + (values[4] >> 0 & 0b11111111) ]

            return valuesBit
        }
    }
    
    var networkErrorNodes: [String] {
        get {
            let hexString = self.hexString
            let hexLen = hexString.count
            let maxLen = (1+4+1+3+7+2)*2
            if hexLen != maxLen { //Len del pacchetto in #hexbyte*2 = #bytes
                return [String]()
            }
            
            let nodeCountString = hexString.subString(from: 10, len: 2)//String(hexString.substring(with: NSRange(location: 10, length: 2)))
            let nodeCount = Utils.hexToInt(nodeCountString) ?? 0
            
            let networkPrefixString = hexString.subString(from: 12, len: 6)//String(hexString.substring(with: NSRange(location: 12, length: 6)))
            
            let networkAddressNodesString = hexString.subString(from: 18, len: 2*nodeCount)//String(hexString.substring(with: NSRange(location: 18, length: 2*nodeCount)))
            let networkNodes = networkAddressNodesString.split(by: 2)
            
            let result = networkNodes.compactMap { networkPrefixString + $0 }
            return result
        }
    }
    
    var networkNodes: [String] {
        get {
            let hexString = self.hexString
            let hexLen = hexString.count
            let maxLen = (1+4+1+3+7+2)*2
            if hexLen != maxLen { //Len del pacchetto in #hexbyte*2 = #bytes
                return [String]()
            }
            
            //let nodeCountString = String(hexString.substring(with: NSRange(location: 10, length: 2)))
            //let nodeCountInt = Int(nodeCountString) ?? 0
            let networkIPMask = hexString.subString(from: 12, len: 6)//String(hexString.substring(with: NSRange(location: 12, length: 6)))
            
            let nodesMask = hexString.subString(from: 18, len: 14)//tring(hexString.substring(with: NSRange(location: 18, length: 14)))
            let bitString = nodesMask.split(by: 2).map {
                let values = Utils.hexToInt($0) ?? 0
                var stringVal = String(values, radix: 2)
                for _ in 1...(8-stringVal.count) {
                    stringVal = "0"+stringVal
                }
                return stringVal
            }.joined(separator: "")
            
            let reversedBitString = String(bitString.reversed())
            
            let nodesAddress: [String] = reversedBitString.split(by: 1).enumerated().compactMap { (arg0) -> String? in
                let (index, value) = arg0
                
                if
                    Int(value) == 1,
                    index > 0,
                    let hexValue = Utils.intToHex(index) {
                        return "\(networkIPMask)\(hexValue)"
                }
                
                return nil
            }
            
            return nodesAddress
        }
    }
    
    var needOptionW: Bool {
        get {
            let hexString = self.hexString
            let hexLen = hexString.count
            let maxLen = (1+4+1+3+7+2)*2
            if hexLen != maxLen { //Len del pacchetto in #hexbyte*2 = #bytes
                return false
            }
            
            let nodesMask = hexString.subString(from: 18, len: 14)//String(hexString.substring(with: NSRange(location: 18, length: 14)))
            let bitString = nodesMask.split(by: 2).map {
                let values = Utils.hexToInt($0) ?? 0
                var stringVal = String(values, radix: 2)
                for _ in 1...(8-stringVal.count) {
                    stringVal = "0"+stringVal
                }
                return stringVal
            }.joined(separator: "")
            
            let reversedBitString = String(bitString.reversed()).split(by: 1)
            if reversedBitString.count == 0 {
                return false
            }
            
            if Int(reversedBitString[0]) == 1 {
                return true
            }
            
            return false
        }
    }
    
    var nodeType: String {
        get {
            let hexString = self.hexString
    
            let type = hexString.subString(from: 20, len: 2)//String(hexString.substring(with: NSRange(location: 20, length: 2)))
            if type == "52" {
                return "REPEATER"
            }
            if type == "53" {
                return "SENSOR"
            }
            
            return ""
        }
    }
    
    var rssiValue: Int {
        get {
            let hexString = self.hexString
            
            let hexValue = hexString.subString(from: 20, len: 4)//String(hexString.substring(with: NSRange(location: 20, length: 4)))
            return Utils.hexToInt(hexValue) ?? Int.max
        }
    }
    
    var batteryValue: Int {
        get {
            if self.sensorValues.count == 4 {
                return self.sensorValues[3]
            }
            
            return Int.max
        }
    }
    
    var networks: [String] {
        get {
            let hexString = self.hexString
            
            let numberStr = hexString.subString(from: 10, len: 2)//String(hexString.substring(with: NSRange(location: 10, length: 2)))
            let n = Int(numberStr) ?? 0
            
            let networksString = hexString.subString(from: 12, len: n*6)//String(hexString.substring(with: NSRange(location: 12, length: n*6)))
            let networks = networksString.split(by: 6)
            return networks
        }
    }
}



extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        
        return results.map { String($0) }
    }
}
