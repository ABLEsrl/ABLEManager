//
//  CommandResponse.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 24/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


open class ABLEResponse: Hashable {
    open var rawString: String = ""
    open var rawData:   Data   = Data()
    
    public init(with payload: String) {
        self.rawString = payload
        self.rawData   = payload.data(using: .ascii) ?? Data()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawString)
    }
    
    public static func ==(lhs: ABLEResponse, rhs: ABLEResponse) -> Bool {
        return lhs.rawString == rhs.rawString
    }
    
    public var description: String {
        return rawString
    }
}
