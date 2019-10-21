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
        guard let number = UInt(exactly: num) else {
            return nil
        }
        
        return String(number, radix: 16, uppercase: true).leftPadding(toLength: 2, withPad: "0")
    }
    
    public static func hexToInt(_ val: String) -> Int? {
        guard let number = UInt(val, radix: 16) else {
            return nil
        }
        
        return Int(number)
    }
}

public extension Character {
    
    var asciiValue: Int {
        let s = String(self).unicodeScalars
        return Int(s[s.startIndex].value)
    }
    
    var asciiHexValue: String? {
        return Utils.intToHex(asciiValue)
    }
}
