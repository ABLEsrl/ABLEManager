//
//  DMiniCountResponse.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 25/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

/*
 $2808xxxx\r\n
 dove:
 $ è il SOF
 28 è il comando
 08 è la lunghezza del frame in esadecimale (22=34 caratteri)
 xxxx è il numero di tag in memoria
 */

public class DMiniCountResponse: ABLEResponse {
    var SOF:         String = "$"
    var CMD:         String = ""
    var LEN:         String = ""
    var TAGS_COUNT:  String = ""
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
        
        if rawString.count >= 10, TAGS_COUNT == "" {
            TAGS_COUNT = rawString.subString(from: 5, len: 4)
        }
        
        if CMD == "" || LEN == "" || TAGS_COUNT == "" {
            return false
        }
        
        return true
    }
    
    public var tagsCount: Int {
        get {
            if parsedCompletely() {
                return Utils.hexToInt(TAGS_COUNT) ?? -1
            } else {
                return -1
            }
        }
    }
}
