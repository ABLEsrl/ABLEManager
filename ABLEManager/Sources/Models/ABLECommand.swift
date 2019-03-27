//
//  Command.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


open class ABLECommand: Hashable {
    open var rawString: String = ""
    open var rawData:   Data   = Data()
    
    public init(with payload: String) {
        self.rawString = payload
        self.rawData   = payload.data(using: .ascii) ?? Data()
    }
    
    open func hash(into hasher: inout Hasher) {
        hasher.combine(rawString)
    }
    
    public static func ==(lhs: ABLECommand, rhs: ABLECommand) -> Bool {
        return lhs.rawString == rhs.rawString
    }
    
    open func getData() -> Data {
        return rawData
    }
    
    open var description: String {
        return rawString
    }
}
