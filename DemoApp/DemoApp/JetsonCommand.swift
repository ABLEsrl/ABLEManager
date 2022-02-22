//
//  LetsCommand.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager


class JetsonCommand: ABLECommand {
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
        return hexMessage.hexDecodedData()
    }
    
    
    static var startCommand: JetsonCommand {
        return JetsonCommand(payload: "7DFF")
    }
}
