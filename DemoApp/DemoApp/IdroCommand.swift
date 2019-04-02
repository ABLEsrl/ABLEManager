//
//  IdroCommand.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import ABLEManager
import Foundation
import UIKit


public enum CommandCode: String {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
    case E = "E"
    case F = "F"
    case G = "G"
    case H = "H"
    case I = "I"
    case J = "J"
    case K = "K"
    case L = "L"
    case M = "M"
    case N = "N"
    case O = "O"
    case P = "P"
    case Q = "Q"
    case R = "R"
    case S = "S"
    case T = "T"
    case U = "U"
    case V = "V"
    case W = "W"
    case X = "X"
    case Y = "Y"
    case Z = "Z"
    
    case UNDEF = ""
    
    var asiiHexValue: String {
        get {
            return Character(self.rawValue).asciiHexValue ?? ""
        }
    }
    
    func waitForDelay(callback: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            callback()
        }
    }
    
    func waitForResponse(_ message: String = "", showWaitTime: Bool = true, label: UILabel? = nil, callback: @escaping () -> ()) {
        var waitMessage = description
        if message.count > 0 {
            waitMessage = message
        }
        
        label?.text = "\(waitMessage)"
        if showWaitTime == true {
            label?.text = "\(waitMessage)\nAttendi \(responseTime) secondi..."
        }
    
        DispatchQueue.main.asyncAfter(deadline: .now() + responseTime) {
            callback()
        }
    }
    
    var delay: Double {
        get {
            return 2.0
        }
    }
    
    var responseTime: Double {
        get {
            switch self {
            case .A:
                return 20.0
            case .B:
                return 2.0
            case .C:
                return 35.0
            case .D:
                return 8.0
            case .E:
                return 2.0
            case .F:
                return 2.0
            case .G:
                return 2.0
            case .H:
                return 2.0
            case .I:
                return 2.0
            case .J:
                return 2.0
            case .K:
                return 2.0
            case .L:
                return 2.0
            case .M:
                return 90.0
            case .N:
                return 2.0
            case .O:
                return 2.0
            case .P:
                return 2.0
            case .Q:
                return 2.0
            case .R:
                return 2.0
            case .S:
                return 20.0
            case .T:
                return 2.0
            case .U:
                return 2.0
            case .V:
                return 8.0
            case .W:
                return 20.0
            case .X:
                return 2.0
            case .Y:
                return 2.0
            case .Z:
                return 2.0
            case .UNDEF:
                return 0.0
            }
        }
    }
    
    var description: String {
        get {
            switch self {
            case .A:
                return "Modifica dell'indirizzo del nodo"
            case .B:
                return ""
            case .C:
                return "Lettura dei sensori"
            case .D:
                return "Scansione dei nodi in campo"
            case .E:
                return ""
            case .F:
                return ""
            case .G:
                return ""
            case .H:
                return ""
            case .I:
                return "Abilitazione della modalità installazione"
            case .J:
                return ""
            case .K:
                return ""
            case .L:
                return ""
            case .M:
                return "Verifica della connessione di rete"
            case .N:
                return "Disabilitazione della modalità installazione"
            case .O:
                return "Verifica dello stato del gateway"
            case .P:
                return ""
            case .Q:
                return ""
            case .R:
                return "Lettura della risposta"
            case .S:
                return "Misurazione dell'RSSI"
            case .T:
                return ""
            case .U:
                return "Cambiamento dell'APN di rete"
            case .V:
                return "Tipologia di un nodo"
            case .W:
                return "Instazione del wakeup del nodo"
            case .X:
                return ""
            case .Y:
                return ""
            case .Z:
                return ""
                
            case .UNDEF:
                return "Comando sconosciuto"
            }
        }
    }
}


class IdroCommand: ABLECommand {
    var commandCode: CommandCode = .UNDEF
    var hexMessage: String = ""
    var gateway: String = ""
    var target: String = ""
    var args: String = ""
    
    init() {
        super.init(with: "")
    }
    
    init(code: CommandCode, gateway: String, target: String, payload: String) {
        self.commandCode = code
        self.gateway = gateway
        self.target = target
        self.args = payload
        
        self.hexMessage = "\(code.asiiHexValue)\(gateway)\(target)\(args)"
    
        super.init(with: hexMessage)
        
        self.rawData = hexMessage.hexDecodedData()
    }

    override func getData() -> Data {
        return hexMessage.hexDecodedData()
    }
}
