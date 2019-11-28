//
//  DMiniClearRespose.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 28/11/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

/*
 $2c0300\r\n
 */

public enum ClearResponseCode: String {
    case ClearCorrectly   = "00"

    case UnknownCodeError = ""
}

public class DMiniClearResponse: ABLEResponse {
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
    
    public var responseCode: ClearResponseCode {
        return ClearResponseCode(rawValue: CODE) ?? ClearResponseCode.UnknownCodeError
    }
}
