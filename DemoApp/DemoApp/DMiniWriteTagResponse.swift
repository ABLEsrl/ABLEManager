//
//  DMiniWriteTagResponse.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 28/11/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

/*
 $2306xx\r\n
 dove:
 $ è il SOF
 23 è il comando
 06 è la lunghezza del frame in esadecimale (22=34 caratteri)
 xx è la il codice risposta:
    XX=00 Saved correctly
    XX=01 Memory full
    XX=02 Tags in memory (inventory mode active)
    XX=03 Tag already saved
 */

public enum WriteTagResponseCode: String {
    case SaveCorrecty    = "00"
    case MemoryFull      = "01"
    case DeviceNotReady  = "02"
    case TagAlreadySaved = "03"
    
    case UnknownCodeError = ""
}

public class DMiniWriteTagResponse: ABLEResponse {
    var SOF:  String = "$"
    var CMD:  String = ""
    var LEN:  String = ""
    var CODE: String = ""
    var EOF:  String = "\r\n"
    
    
    public override init(with rawString: String = "") {
        super.init(with: rawString)
    }
    
    public func append(data: Data) {
        rawData += data
    }
    
    public func append(string: String) {
        rawString += string
    }
    
    public func parsedCompletely() -> Bool {
        guard rawString.starts(with: SOF) else {
            return false
        }
        
        if rawString.count >= 3, CMD == "" { // La prima parte del pacchetto
            CMD = rawString.subString(from: 1, len: 2)
        }
        
        if rawString.count >= 5, LEN == "" {
            LEN = rawString.subString(from: 3, len: 2)
        }
        
        if rawString.count >= 7, CODE == "" {
            CODE = rawString.subString(from: 5, len: 2)
        }
        
        
        if CMD == "" || LEN == "" || CODE == "" {
            return false
        }
        
        return true
    }
    
    public var responseCode: WriteTagResponseCode {
        return WriteTagResponseCode(rawValue: CODE) ?? WriteTagResponseCode.UnknownCodeError
    }
}
