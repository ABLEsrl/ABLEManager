//
//  DMiniResponse.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 23/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

/*
 $2a220cxxxxyyyyyyyyyyyyyyyyyyyyyyyy\r\n
 dove:
 $ è il SOF
 2a è il comando
 22 è la lunghezza del frame in esadecimale (22=34 caratteri)
 0c è la lunghezza in byte del tag (0c=12 byte, quindi 24 caratteri)
 xxxx è il numero di tag in memoria
 yyyy è il tag
 */

public class DMiniResponse: ABLEResponse {
    var SOF:         String = "$"
    var CMD:         String = ""
    var LEN:         String = ""
    var TAG_LEN:     String = ""
    var TAGS_COUNT:  String = ""
    var TAG:         String = ""
    var EOF:         String = "\r\n"
    
    
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
        
        if rawString.count >= 7, TAG_LEN == "" {
            TAG_LEN = rawString.subString(from: 5, len: 2)
        }
        
        if rawString.count >= 11, TAGS_COUNT == "" {
            TAGS_COUNT = rawString.subString(from: 7, len: 4)
        }
        
        if let len = Utils.hexToInt(TAG_LEN), rawString.count >= 11 + len, TAG == "" {
            TAG = rawString.subString(from: 11, len: len)
        }
        
        if CMD == "" || LEN == "" || TAG_LEN == "" || TAGS_COUNT == "" || TAG == "" {
            return false
        }
        
        return true
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
