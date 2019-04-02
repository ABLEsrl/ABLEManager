//
//  IdroManager.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import ABLEManager
import Foundation
import UIKit


class IdroManager {
    public static var shared = IdroManager()
    
    private var currentCommand:     IdroCommand
    private var currentResponse:    IdroResponse
    private var connectionObserver: NSKeyValueObservation?
    
    private var currentBar: UIProgressView?
    private var currentLabel: UILabel?
    private var progressTimer: Timer?
    
    private var MAX_RETRY: Int
    private var needRetry: Bool
    private var retryCount: Int
    
    var connectedDevice: PeripheralDevice? {
        get {
            return BluetoothManager.shared.connectedDevice
        }
    }
    
    
    init() {
        currentCommand = IdroCommand()
        currentResponse = IdroResponse()
        
        connectionObserver = nil
        progressTimer = nil
        
        needRetry = false
        retryCount = 0
        MAX_RETRY = 0
    }
    
    func registerConnectionObserver(_ callback: @escaping ((Bool)->Void) ) {
        connectionObserver = BluetoothManager.shared.registerConnnectionObserver { (connected) in
            callback(connected)
        }
    }
    
    func searchAndConnect(_ callback: @escaping ((PeripheralDevice)->Void) ) {
        BluetoothManager.shared.scanAndConnect(to: "-E18") { (device) in
            callback(device)
        }
    }
    
    func scanning(with name: String, _ callback: @escaping (([PeripheralDevice])->Void) ) {
        BluetoothManager.shared.scanForPeripheral(name) { (device) in
            callback(device)
        }
    }
    
    @discardableResult
    func connect(with device: PeripheralDevice) -> Bool {
        return BluetoothManager.shared.connect(to: device)
    }
    
    @discardableResult
    func reconnect() -> Bool {
        return BluetoothManager.shared.reconnect()
    }
    
    func unsubscribe(from characteristic: CharacteristicsModel) {
        BluetoothManager.shared.unsubscribe(to: characteristic.rawValue)
    }
    
//    func readAllTags(_ callback: @escaping (([String], Bool)->Void) ) {
//        getTagsCountOnReader { (tagsCount, success) in
//            if tagsCount <= 0 {
//                return
//            }
//
//            DispatchQueue(label: "tags.reader.queue").async {
//                var tags = [String]()
//                let group = DispatchGroup()
//
//                for i in 1...tagsCount {
//                    group.enter()
//
//                    self.readTag(index: i) { (tag, success) in
//                        tags.append(tag)
//                        group.leave()
//                    }
//
//                    group.wait()
//                }
//
//                group.notify(queue: DispatchQueue.main) {
//                    callback(tags, true)
//                }
//            }
//        }
//    }

    func stopScan() {
        BluetoothManager.shared.stopScan()
    }
    
    func disconnect() {
        BluetoothManager.shared.disconnect()
    }
}

extension IdroManager {
    
    func sendCommand_O(gateway: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .O, gateway: gateway, target: "", payload: "", bar: bar, label: label, needWaitForResponse: false, callback)
    }
    
    func sendCommand_I(gateway: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .I, gateway: gateway, target: "", payload: "", bar: bar, label: label, needWaitForResponse: false, callback)
    }
    
    func sendCommand_U(gateway: String, apn: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        BluetoothManager.shared.subscribeRead(to: CharacteristicsModel.characteristic3.rawValue) { [weak self] (device, response, success) in
            guard response.isZeroFilled == false else {
                return
            }
            
            let idroResponse = IdroResponse(data: response)
            let (responseCode, errorMessage) = idroResponse.evaluateResponse()
            if responseCode != .ack {
                //NavigationController.shared?.showPopup(title: "IdroController", message: errorMessage)
                self?.stopTimerUpdate()
                return
            }
            
            self?.stopTimerUpdate()
            callback(idroResponse, responseCode)
        }
        
        updateTimerAndDescription(for: .U, bar: bar, label: label, waitForResponse: false)
        currentCommand = IdroCommand(code: .U, gateway: gateway, target: "", payload: apn)
        BluetoothManager.shared.write(command: currentCommand, to: CharacteristicsModel.characteristic4.rawValue, modality: .withResponse)
    }
    
    func sendCommand_M(gateway: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .M, gateway: gateway, target: "", payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_C(gateway: String, target: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .C, gateway: gateway, target: target, payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_ScanningReti(gateway: String, payload: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .D, gateway: gateway, target: "", payload: payload, bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_DetectTipoNodo(gateway: String, target: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .V, gateway: gateway, target: target, payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_A(gateway: String, target: String, payload: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .V, gateway: gateway, target: target, payload: payload, bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_TestRSSI(gateway: String, target: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .S, gateway: gateway, target: target, payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_ValoriSensori(gateway: String, target: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .C, gateway: gateway, target: target, payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
    
    func sendCommand_WakeUp(gateway: String, target: String, bar: UIProgressView, label: UILabel, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void) ) {
        sendCommand(code: .W, gateway: gateway, target: target, payload: "", bar: bar, label: label, needWaitForResponse: true, callback)
    }
}


extension IdroManager {
    public func stopTimerUpdate() {
        guard let timer = progressTimer else {
            return
        }
        
        TimeoutTimer.invalidate(timer: timer)
        currentBar?.setProgress(0, animated: false)
    }
    
    public func updateTimerAndDescription(for commandCode: CommandCode, bar: UIProgressView, label: UILabel, waitForResponse: Bool = false) {
        currentBar = bar
        currentLabel = label
        
        DispatchQueue.main.async {
            self.stopTimerUpdate()
            
            label.text = "\(commandCode.description) in corso..."
            
            let wait: Double = waitForResponse == false ? commandCode.delay : commandCode.responseTime
            let interval: TimeInterval = 0.1/(wait + 0.5)
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                let nextProgress = bar.progress + Float(interval)
                bar.setProgress(nextProgress, animated: true)
            })
        }
    }
}



//Generic function for sending command
extension IdroManager {
    private func sendCommand(code: CommandCode, gateway: String = "", target: String = "", payload: String = "", bar: UIProgressView, label: UILabel,  needWaitForResponse: Bool = false, _ callback: @escaping ((IdroResponse, IdroResponseCode)->Void)) {
        
        BluetoothManager.shared.subscribeRead(to: CharacteristicsModel.characteristic3.rawValue) { [weak self] (device, response, success) in
            guard
                let strongSelf = self,
                response.isZeroFilled == false else {
                return
            }
            
            //Ho ricetuo la risposta quindi blocco il sistema dei retry
            strongSelf.needRetry = false
            strongSelf.retryCount = strongSelf.MAX_RETRY
            
            let idroResponse = IdroResponse(data: response)
            let (responseCode, _) = idroResponse.evaluateResponse()
            
            if needWaitForResponse == false || strongSelf.currentCommand.commandCode == .R {
                strongSelf.stopTimerUpdate()
                callback(idroResponse, responseCode)
                return
            }
            
            if needWaitForResponse == true && responseCode == .ack && strongSelf.currentCommand.commandCode != .R {
                strongSelf.updateTimerAndDescription(for: strongSelf.currentCommand.commandCode, bar: bar, label: label, waitForResponse: true)
                strongSelf.currentCommand.commandCode.waitForResponse(label: strongSelf.currentLabel) {
                    strongSelf.currentCommand = IdroCommand(code: .R, gateway: gateway, target: "", payload: "")
                    strongSelf.write(command: strongSelf.currentCommand)
                }
                return
            }
            
            strongSelf.stopTimerUpdate()
            callback(idroResponse, responseCode)
        }
        
        self.updateTimerAndDescription(for: code, bar: bar, label: label, waitForResponse: false)
        self.currentCommand = IdroCommand(code: code, gateway: gateway, target: target, payload: payload)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.write(command: self.currentCommand)
        }
    }
    
    private func write(command: IdroCommand, to characteristic: CharacteristicsModel = .characteristic4, retry: Int = 5, modality: CBCharacteristicWriteType = .withResponse) {
        self.MAX_RETRY  = retry
        self.needRetry  = true
        self.retryCount = 0
        
        Thread.detachNewThread {
            while self.needRetry == true && self.retryCount < self.MAX_RETRY {
                BluetoothManager.shared.write(command: self.currentCommand, to: characteristic.rawValue, modality: .withResponse)
                print("\(command.commandCode) Tentativo: \(self.retryCount)")
                self.retryCount += 1
                sleep(2)
            }
        }
    }
}
