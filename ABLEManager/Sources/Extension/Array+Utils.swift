//
//  Array+Utils.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 21/10/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation

public extension Array {
    
    var representableString: String {
        let result = (compactMap( { (value) -> String in
            if let value = value as? [String: Any] {
                return value.representableString
            }
            if let value = value as? Int {
                return "\(value)"
            }
            if let value = value as? Bool {
                return "\(value)"
            }
            if let value = value as? Float {
                return "\(value)"
            }
            if let value = value as? Double {
                return "\(value)"
            }
            
            return String(describing: value)
        }) as Array<String>).joined(separator: "\n")
        
        return result
    }
}
