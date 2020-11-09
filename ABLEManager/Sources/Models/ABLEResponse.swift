//
//  CommandResponse.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


open class ABLEResponse: Hashable, CustomStringConvertible {
    open var rawString: String = ""
    open var rawData:   Data   = Data()
    
    public init(with payload: String) {
        self.rawString = payload
        self.rawData   = payload.data(using: .ascii) ?? Data()
    }
    
    open func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawString)
    }
    
    public static func ==(lhs: ABLEResponse, rhs: ABLEResponse) -> Bool {
        return lhs.rawString == rhs.rawString
    }
    
    open func parseData(_ data: Data) {
        self.rawData = data
    }
    
    open var description: String {
        return self.rawString
    }
    
    open var debugDescription: String {
        return self.rawString
    }
}
