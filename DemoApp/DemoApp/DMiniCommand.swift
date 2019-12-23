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
 
 *** Write Tag ***
 $2220010Cxxxxxxxxxxxxxxxxxxxxxxxx\r\n
 
 22 is the command
 20 is the frame length in hex (20=32 characters)
 01 indicates that the writing has to be performed in RAM memory and save only if not present
 0c is tag length in byte (0c=12 byte, so 24 characters)
 xxxxxxxxxxxxxxxxxxxxxxxx EPC of tag

 */



public enum CMD: String {
    case TAG_COUNT   = "27"
    case READ_TAG    = "29"
    case WRITE_TAG   = "22"
    case CLEAR       = "2B"
    case SCANN_MODE  = "0E"
    case CHANGE_MODE = "3D"
}

public enum MODALITA: String {
    case RAM = "01"
}

public enum SCANNING_MODE: String {
    case ON  = "01"
    case OFF = "00"
}

public enum DEVICE_MODE: String {
    case INVENTORY = "01"
    case FIND      = "02"
    case SCANNING  = "03"
}


public class DMiniCommand: ABLECommand {
    var SOF:     String = "$"
    var CMD:     String = ""
    var LEN:     String = ""
    var PAYLOAD: String = ""
    var EOF:     String = "\r\n"
    
    
    public init(with command: CMD, payload: String = "") {
        let len        = command.rawValue.count + 2 + payload.count // il 2 è la len dell'hex len (al massimo due byte)
        let hexLen     = Utils.intToHex(len) ?? "00"
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
        let readFromRAM    = MODALITA.RAM.rawValue
        let tagIndexString = String(index).leftPadding(toLength: 4, withPad: "0")
        let command        = DMiniCommand(with: .READ_TAG, payload: readFromRAM + tagIndexString)
        return command
    }

    static func writeTagCommand(value: String) -> DMiniCommand {
        let readFromRAM = MODALITA.RAM.rawValue
        let tagHexLen   = Utils.intToHex(value.count/2) ?? "00"
        let payload     = readFromRAM + tagHexLen + value
        let command     = DMiniCommand(with: .WRITE_TAG, payload: payload)
        print("Write Payload: \(command.rawString)")
        return command
    }
 
    static func clearDeviceCommand() -> DMiniCommand {
        let payload = "01"
        let command = DMiniCommand(with: .CLEAR, payload: payload)
        print("Clear Payload: \(command.rawString)")
        return command
    }
    
    static func setScanningModeCommand(_ mode: SCANNING_MODE) -> DMiniCommand {
        let payload = "01" + mode.rawValue
        let command = DMiniCommand(with: .SCANN_MODE, payload: payload)
        print("Scanning Mode Payload: \(command.rawString)")
        return command
    }
    
    static func switchToModeCommand(_ mode: DEVICE_MODE) -> DMiniCommand {
        let payload = "01" + mode.rawValue
        let command = DMiniCommand(with: .CHANGE_MODE, payload: payload)
        print("Switch Mode Payload: \(command.rawString)")
        return command
    }
}
