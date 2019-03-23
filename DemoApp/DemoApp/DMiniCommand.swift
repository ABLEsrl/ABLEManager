//
//  DMiniCommand.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 23/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

/*
 SOF    CMD    LEN   PAYLOAD    EOF
 
 //SOF:      Inizio del comando
 //CMD:      Il comando (2 caratteri che rappresentano un numero esadecimale)
 //LEN:      La lunghezza del frame eccetto SOF e EOF
 //PAYLOAD:  Il campo che contiene le informazioni aggiuntive del comando
 //EOF:      End Of Frame CR LF (\r\n)
 
 *** Read number of tags ***
 $270600\r\n
 
 *** Read Tag ***
 $290a010001\r\n
 */

public enum CMD: String {
    case TAG_COUNT = "27"
    case READ_TAG  = "29"
}

public class DMiniCommand: ABLECommand {
    var SOF:     String = "$"
    var CMD:     String = ""
    var LEN:     String = ""
    var PAYLOAD: String = ""
    var EOF:     String = "\r\n"
    
    
    public init(with command: CMD, payload: String = "") {
        let len = command.rawValue.count+2+payload.count // il 2 è la len dell'hex len (al massimo due byte)
        let hexLen = Utils.intToHex(len) ?? ""
        let rawCommand = SOF + command.rawValue + hexLen + payload + EOF
        
        super.init(with: rawCommand)
    }
    
    static func tagCountCommand() -> DMiniCommand {
        let command = DMiniCommand(with: .TAG_COUNT, payload: "00")
        return command
    }
    
    static func readTagCommand() -> DMiniCommand {
        return readTagCommand(index: 1)
    }
    static func readTagCommand(index: Int) -> DMiniCommand {
        let readFromRAM = "01"
        let tagIndexString = String(index).leftPadding(toLength: 4, withPad: "0")
        let command = DMiniCommand(with: .READ_TAG, payload: readFromRAM + tagIndexString)
        return command
    }
}
