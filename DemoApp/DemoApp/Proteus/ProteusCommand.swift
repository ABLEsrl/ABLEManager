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
    
    
    static var authCommand: ProteusCommand {
        return ProteusCommand(payload: "[P000000020000000000ff00ff470af00046016764001000000000000]")
    }
    
    static func programCommand(value: Int) -> ProteusCommand {
        let dimming = String(value, radix: 16).leftPadding(toLength: 2, withPad: "0")
        return ProteusCommand(payload: "[P000000020000000000ff00ff"+dimming+"0af00046016764001000000000000]")
    }
}
