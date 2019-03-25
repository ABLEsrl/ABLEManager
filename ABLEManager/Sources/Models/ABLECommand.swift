//
//  Command.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


open class ABLECommand: Hashable {
    var rawString: String = ""
    var rawData:   Data   = Data()
    
    public init(with payload: String) {
        self.rawString = payload
        self.rawData   = payload.data(using: .ascii) ?? Data()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawString)
    }
    
    public static func ==(lhs: ABLECommand, rhs: ABLECommand) -> Bool {
        return lhs.rawString == rhs.rawString
    }
    
    public var description: String {
        return rawString
    }
}
