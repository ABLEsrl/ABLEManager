//
//  ABLEOperationType.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


public enum ABLEOperationType: String {
    case Scanning       = "Scanning"
    case Connect        = "Connect"
    case Read           = "Read"
    case Write          = "Write"
    case Subscribe      = "Subscribe"
    case Service        = "Service"
    case Characteristic = "Characteristic"
    case Stop           = "Stop"
}

