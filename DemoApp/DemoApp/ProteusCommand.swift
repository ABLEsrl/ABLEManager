//
//  LetsCommand.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager


class ProteusCommand: ABLECommand {
    var hexMessage:  String  = ""
    
    init() {
        super.init(with: "")
    }
    
    init(payload: String) {
        super.init(with: "")
        
        self.hexMessage = payload
        self.rawData    = hexMessage.hexDecodedData()
        self.rawString  = String(data: self.rawData, encoding: .ascii) ?? ""
    }

    override func getData() -> Data {
        var frameData = Data(bytes:[0x01], count: 1)
        frameData.append(contentsOf: self.rawData)
        return frameData
    }
    
    
    static var startCommand: ProteusCommand {
        return ProteusCommand(payload: "7DFF")
    }
}
