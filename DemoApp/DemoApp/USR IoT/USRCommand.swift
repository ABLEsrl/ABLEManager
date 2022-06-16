//
//  USRCommand.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager


class USRCommand: ABLECommand {

    init() {
        super.init(with: "")
    }
    
    init(payload: String) {
        super.init(with: "")
 
        self.rawData    = payload.data(using: .ascii) ?? Data()
        self.rawString  = String(data: self.rawData, encoding: .ascii) ?? ""
    }

    override func getData() -> Data {
        var frameData = Data(bytes:[0x01], count: 1)
        frameData.append(contentsOf: self.rawData)
        return frameData
    }
    
    
    static var authCommand: USRCommand {
        return USRCommand(payload: "[1234I]")
    }
    
    static func programCommand(value: Int) -> USRCommand {
        return USRCommand(payload: "[1234P]")
    }
}
