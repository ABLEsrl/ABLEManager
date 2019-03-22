//
//  Number+Hex.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 28/12/2018.
//  Copyright © 2018 ABLE. All rights reserved.
//

import Foundation
import UIKit


public class Utils {
    
    static func intToHex(_ num: Int) -> String? {
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
    
    static func hexToInt(_ val: String) -> Int? {
        if let number = UInt(val, radix: 16) {
            return Int(number)
        }
        
        return nil
    }
}


public extension Character {
    
    var asciiValue: Int {
        get {
            let s = String(self).unicodeScalars
            return Int(s[s.startIndex].value)
        }
    }
    
    var asciiHexValue: String? {
        get {
            return Utils.intToHex(asciiValue)
        }
    }
}


public extension String {
    /// A data representation of the hexadecimal bytes in this string.
    func hexDecodedData() -> Data {
        // Get the UTF8 characters of this string
        let chars = Array(utf8)
        
        // Keep the bytes in an UInt8 array and later convert it to Data
        var bytes = [UInt8]()
        bytes.reserveCapacity(count / 2)
        
        // It is a lot faster to use a lookup map instead of strtoul
        let map: [UInt8] = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
            0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
            0x00, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, // @ABCDEFG
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // HIJKLMNO
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // PQRSTUVW
            0x00, 0x00, 0x00                                // XYZ
        ]
        
        // Grab two characters at a time, map them and turn it into a byte
        for i in stride(from: 0, to: count, by: 2) {
            let index1 = Int(chars[i] & 0x1F ^ 0x10)
            let index2 = Int(chars[i + 1] & 0x1F ^ 0x10)
            bytes.append(map[index1] << 4 | map[index2])
        }
        
        return Data(bytes)
    }
}


extension Data {
    
    func toHexString() -> String {
        return reduce("") { "\($0)" + "\(Utils.intToHex(Int($1)) ?? "")" }//String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
}
