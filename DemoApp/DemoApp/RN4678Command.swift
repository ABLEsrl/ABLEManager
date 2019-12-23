//
//  LetsCommand.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager


class RN4678Command: ABLECommand {
    var hexMessage:  String  = ""
    var args:        String  = ""
    
    init() {
        super.init(with: "")
    }
    
    init(payload: String) {
        self.args        = payload
        self.hexMessage  = args
        
        super.init(with: hexMessage)
        
        self.rawData = hexMessage.hexDecodedData()
    }

    override func getData() -> Data {
        return hexMessage.hexDecodedData()
    }
    
    
    static var startCommand: RN4678Command {
        return RN4678Command(payload: "7DFF")
    }
}
