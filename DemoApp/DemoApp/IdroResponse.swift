//
//  IdroResponse.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

enum IdroResponseCode: String {
    case ack     = "30"
    case nack_31 = "31"
    case nack_32 = "32"
    case nack_33 = "33"
    case nack_34 = "34"
    case nack_35 = "35"
    case nack_36 = "36"
    case nack_37 = "37"
    case nack_38 = "38"
    
    case nack = "100"
}


class IdroResponse: ABLEResponse {
    var code: CommandCode = .UNDEF
    var gateway: String = ""
    var ack: String = ""
    var nack: String = ""
    var target: String = ""
    var reply: String = ""
    
    
    init() {
        super.init(with: "")
    }
    
    init(data: Data, code: CommandCode = .UNDEF) {
        self.code = data.commandCode
        self.gateway = data.gateway
        self.target = data.taget
        self.reply = data.reply
        
        super.init(with: data.asciiString)
        
        self.rawData = data
        
        let commandAck = isCommandAck() ? data.ack(10) : data.ack(18)
        if commandAck == "30" {
            self.ack = commandAck
        } else {
            self.nack = commandAck
        }
    }
    
    func evaluateResponse() -> (IdroResponseCode, String) {
        if self.ack == "30" {
            return (.ack, "")
        }
        
        switch nack {
        case "31":
            return (.nack_31, "Impossibile eseguire il comando in quanto la modalità installazione è disabilitata")
        case "32":
            return (.nack_32, "Impossibile eseguire il comando in quanto non valido")
        case "33":
            return (.nack_33, "Il Gateway è impegnato nella routine GSM")
        case "34":
            return (.nack_34, "Il Gateway non è riuscito a recuperare la propria configurazione")
        case "35":
            return (.nack_35, "Impossibile eseguire il comando in quanto l’opzione specificata non valida")
        case "36":
            return (.nack_36, "Impossibile eseguire il comando in quanto l’opzione specificata non valida")
        case "37":
            return (.nack_37, "")
        case "38":
            return (.nack_38, "")
            
        default:
            return (.ack, "")
        }
    }
    
    func isCommandAck() -> Bool {
        let len = rawData.hexString.count
        let partial = rawData.hexString.subString(from: 12, len: len - 12 - 4)
        var isAck = true
        
        partial.split(by: 2).forEach { (hexPart) in
            if hexPart != "03" {
                isAck = false
            }
        }
        
        return isAck
    }
    
    func getSensorsValues() -> [Int] {
        if isCommandAck() {
            return [Int]()
        }
        
        return rawData.sensorValues
    }
    
    func getBatteryValues() -> Int {
        if isCommandAck() {
            return Int()
        }
        
        return rawData.batteryValue
    }
    
    func getRSSIValues() -> Int {
        if isCommandAck() {
            return Int()
        }
        
        return rawData.rssiValue
    }
    
    func getDiscoveryNodes() -> [String] {
        let res = rawData.networkNodes
        return res
    }
    
    func getDiscoveryErrorNodes() -> [String] {
        let res = rawData.networkErrorNodes
        return res
    }
    
    
//    func getNodeType() -> TipoNodo? {
//        let type = rawData.nodeType
//        if type.count > 0 {
//            return TipoNodo(rawValue: type)
//        }
//        
//        return nil
//    }
    
    func getNetworkList() -> [String] {
        let networks = rawData.networks
        return networks
    }
    
    func needCommandDOptionW() -> Bool {
        if rawData.needOptionW {
            return true
        }
        
        return false
    }
}
