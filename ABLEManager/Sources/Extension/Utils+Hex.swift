//
//  Number+Hex.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import UIKit


open class Utils {
    
    public static func intToHex(_ num: Int) -> String? {
        if let number = UInt(exactly: num) {
            let str = String(number, radix: 16, uppercase: true)
            
            if str.count == 0 {
                return "00"
            } else if str.count == 1 {
                return "0\(str)"
            }
            
            return str
        }
        
        return nil
    }
    
    public static func hexToInt(_ val: String) -> Int? {
        if let number = UInt(val, radix: 16) {
            return Int(number)
        }
        
        return nil
    }
}

public extension Character {
    
    public var asciiValue: Int {
        get {
            let s = String(self).unicodeScalars
            return Int(s[s.startIndex].value)
        }
    }
    
    public var asciiHexValue: String? {
        get {
            return Utils.intToHex(asciiValue)
        }
    }
}
