//
//  LetsResponse.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

class USRResponse: ABLEResponse {
    var start:        String = "" // 9 byte di Start
    var heartRate:    String = "" // 1 byte di frequenza cardiaca
    var breathRate:   String = "" // 1 byte di frequenza respiratoria
    var sampleCount:  String = "" // 4 byte di conteggio pacchetti inviati
    var ecgSamples:   String = "" // 64 campioni per il segnale ecg (composti da 3 byte)
    var breathSample: String = "" // 32 campioni per il segnale respiratorio (composti da 3 byte)
    var stop:         String = "" // 9 byte di stop.
    
    
    var parsedString: String {
        return String(data: self.rawData, encoding: .ascii) ?? "Non ci sono riuscito"
    }
    
    public override init(with rawString: String = "") {
        super.init(with: rawString)
    }
    
    public static func clone(with data: USRResponse = USRResponse()) -> USRResponse {
        let newResponse          = USRResponse()
        newResponse.start        = data.start
        newResponse.heartRate    = data.heartRate
        newResponse.breathRate   = data.breathRate
        newResponse.sampleCount  = data.sampleCount
        newResponse.ecgSamples   = data.ecgSamples
        newResponse.breathSample = data.breathSample
        newResponse.stop         = data.stop
        
        return newResponse
    }
    
    public func append(data: Data) {
        let userData = data.subdata(in: 1..<data.count)
        
        rawData   += userData
        rawString  = String(data: self.rawData, encoding: .ascii) ?? ""
    }
    
    public func append(string: String) {
        rawString += string
        rawData    = self.rawString.data(using: .ascii) ?? Data()
    }
    
    public var isComplete: Bool {
        return rawString.contains("[") && rawString.contains("]")
    }
    
    var heartRateValue: Int {
        return Utils.hexToInt(heartRate) ?? -1
    }
    var breathRateValue: Int {
        return Utils.hexToInt(breathRate) ?? -1
    }
    var sampleCountValue: Int {
        return Utils.hexToInt(sampleCount) ?? -1
    }
    var ecgSamplesValues: [Int] {
        return ecgSamples.split(byLen: 3).compactMap { Utils.hexToInt($0) ?? nil }
    }
    var breathSampleValues: [Int] {
        return breathSample.split(byLen: 3).compactMap { Utils.hexToInt($0) ?? nil }
    }
}
