//
//  LetsResponse.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

class JetsonResponse: ABLEResponse {
    var start:        String = "" // 9 byte di Start
    var heartRate:    String = "" // 1 byte di frequenza cardiaca
    var breathRate:   String = "" // 1 byte di frequenza respiratoria
    var sampleCount:  String = "" // 4 byte di conteggio pacchetti inviati
    var ecgSamples:   String = "" // 64 campioni per il segnale ecg (composti da 3 byte)
    var breathSample: String = "" // 32 campioni per il segnale respiratorio (composti da 3 byte)
    var stop:         String = "" // 9 byte di stop.
    
    
    var parsedString: String {
        return String(data: self.rawData, encoding: .utf8) ?? "Non ci sono riuscito"
    }
    
    public override init(with rawString: String = "") {
        super.init(with: rawString)
    }
    
    public static func clone(with data: JetsonResponse = JetsonResponse()) -> JetsonResponse {
        let newResponse          = JetsonResponse()
        
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
        rawData   += data
        rawString  = String(data: self.rawData, encoding: .utf8) ?? ""
    }
    
    public func append(string: String) {
        rawString += string
        rawData    = Data(self.rawString.utf8)
    }
    
    public var isComplete: Bool {
        return rawString.contains("[") && rawString.contains("]")
        /*
        guard rawString.hasPrefix("7E7E7E7E7E7E7E7E7E") == true else {
            return false
        }
        
        guard rawString.hasSuffix("7F7F7F7F7F7F7F7F7F") == true else {
            return false
        }
        
        if rawString.count >= 20 { // La prima parte del pacchetto
            heartRate = rawString.subString(from: 18, len: 2)
        }

        if rawString.count >= 22 { // La prima parte del pacchetto
            breathRate = rawString.subString(from: 20, len: 2)
        }
        
        if rawString.count >= 26 { // La prima parte del pacchetto
            sampleCount = rawString.subString(from: 22, len: 4)
        }
        
        if rawString.count >= 218 { // La prima parte del pacchetto
            ecgSamples = rawString.subString(from: 26, len: 64*6)
        }
        
        if rawString.count >= 314 { // La prima parte del pacchetto
            breathSample = rawString.subString(from: 218, len: 32*6)
        }
        
        if heartRate == "" || breathRate == "" || sampleCount == "" || ecgSamples == "" || breathSample == "" {
            return false
        }
        return true
         */
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
