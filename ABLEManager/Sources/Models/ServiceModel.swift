//
//  CommandQ.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 03/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//


import Foundation


public enum DeviceOperationType: String {
    case Scanning       = "Scanning"
    case Connect        = "Connect"
    case Read           = "Read"
    case Write          = "Write"
    case Subscribe      = "Subscribe"
    case Service        = "Service"
    case Characteristic = "Characteristic"
    case Stop           = "Stop"
}


public enum Characteristic : String {
    case characteristic1 = "2A29"
    case characteristic2 = "2A24"
    case characteristic3 = "2A23"
    case characteristic4 = "F7BF3564-FB6D-4E53-88A4-5E37E0326063"
    case characteristic5 = "F000C0E1-0451-4000-B000-000000000000"
}
