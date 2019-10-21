//
//  Dictionary+String.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 21/10/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    var representableString: String {
        let string = (compactMap({ (key, value) -> String in
            if let dictValue = value as? [String: Any] {
                return "\(key): \(dictValue.representableString)"
            }
            
            if let listValue = value as? [Any] {
                return "\(key): \(listValue.representableString)"
            }
            
            return "\(key): \(String(describing: value))"
        }) as Array).joined(separator:"\n")
        
        return string + "\n"
    }
}
