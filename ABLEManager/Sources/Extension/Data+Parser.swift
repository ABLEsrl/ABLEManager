//
//  Data+Parser.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


public extension Data {
    var isNoneOrZeroFilled: Bool {
        get {
            var res = true
            self.toHexString().forEach { (element) in
                if String(element) != "0" {
                    res = false
                }
            }
            return res
        }
    }
    
    var asciiString: String {
        get {
            return String(bytes: self, encoding: .ascii) ?? ""
        }
    }
}
