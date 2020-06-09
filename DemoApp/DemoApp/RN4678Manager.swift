//
//  LetsBLEManager.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import CoreBluetooth


public class RN4678Manager {
    public static var shared = RN4678Manager()
    
    private var rawPayload:         String                 = ""
    private var currentCommand:     RN4678Command          = RN4678Command()
    private var currentResponse:    RN4678Response         = RN4678Response()
    private var connectionObserver: NSKeyValueObservation? = nil
    private var streamCallback:     ((String)->Void)?      = nil
    

    func registerConnectionObserver(_ callback: @escaping ((Bool)->Void) ) {
        connectionObserver = BluetoothManager.shared.registerConnnectionObserver { (prev, actual) in
            callback(actual)
        }
    }
    
    func scanning(_ prefixes: [String] = [String](), _ callback: @escaping ((PeripheralDevice)->Void) ) {
        BluetoothManager.shared.scanForPeripheral(prefixes) { (devices) in
            callback(devices[0])
        }
    }
    
    func searchAndConnect(_ callback: @escaping ((PeripheralDevice)->Void) ) {
        BluetoothManager.shared.scanAndConnect(to: "RN4678-850D") { (device) in
            callback(device)
        }
    }

    
    func sendWithSteamResponse(command: RN4678Command, _ callback: @escaping ((RN4678Response)->Void)) {
        self.currentResponse = RN4678Response()
        self.currentCommand  = command
        
        BluetoothManager.shared.subscribe(to: RN4678Characteristic.characteristic3.rawValue) { (device, response, success) in
            guard response.isZeroFilled == false else {
                print("Received empty response")
                return
            }
            
            self.currentResponse.append(data: response)
            
            if self.currentResponse.isComplete {
                DispatchQueue.main.async {
                    callback(RN4678Response.clone(with: self.currentResponse))
                    
                    //Invio ancora il comando per creare lo stream
                    self.currentResponse = RN4678Response()
                    self.write(command: command, to: .characteristic3)
                }
                
            }
        }
        
        //Invio il comando
        self.write(command: command, to: .characteristic3)
    }
    
    func sendWithResponse(command: RN4678Command, _ callback: @escaping ((RN4678Response)->Void)) {
        self.currentResponse = RN4678Response()
        self.currentCommand  = command
        
        BluetoothManager.shared.subscribe(to: RN4678Characteristic.characteristic3.rawValue) { (device, response, success) in
            guard response.isZeroFilled == false else {
                print("Received empty response")
                return
            }
            
            self.currentResponse.append(data: response)
            
            if self.currentResponse.isComplete {
                DispatchQueue.main.async {
                    callback(self.currentResponse)
                    self.currentResponse = RN4678Response()
                }
            }
        }
        
        //Invio il comando
        self.write(command: command, to: .characteristic3)
    }
    
    private func write(command: ABLECommand?, to characteristic: RN4678Characteristic = .characteristic3, modality: CBCharacteristicWriteType = .withResponse) {
        
        guard let ableCommand = command else {
            return
        }
        
        Thread.detachNewThread {
            BluetoothManager.shared.write(command: ableCommand, to: characteristic.rawValue, modality: modality) { (_, success) in
                guard success == true else {
                    print("Send failed")
                    return
                }
                
                print("Send success")
            }
        }
    }
}


extension Data {
    var isZeroFilled: Bool {
        get {
            var res = true
            self.hexString.forEach { (element) in
                if String(element) != "0" {
                    res = false
                }
            }
            return res
        }
    }
}
