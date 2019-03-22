//
//  CommandResponse.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 24/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


public class Response: Hashable {
    var rawData: Data = Data()

    public init(with data: Data = Data()) {
        self.rawData = data
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawData)
    }
    
    public static func ==(lhs: Response, rhs: Response) -> Bool {
        return lhs.rawData == rhs.rawData
    }
    
    var description: String {
        return rawData.asciiString
    }
}
