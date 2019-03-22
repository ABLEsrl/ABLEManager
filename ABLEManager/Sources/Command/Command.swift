//
//  Command.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 20/12/2018.
//  Copyright © 2018 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit

class Command: Hashable {
    var rawString: String = ""
    var rawData:   Data   = Data()
    
    init(with payload: String) {
        self.rawString = payload
        self.rawData   = payload.data(using: .ascii) ?? Data()
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawString)
    }
    
    static func ==(lhs: Command, rhs: Command) -> Bool {
        return lhs.rawString == rhs.rawString
    }
    
    var description: String {
        return rawString
    }
}


/*
private enum IdroControllerService: String {
    //case idroControllerE188 = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    case ableE189 = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
}

class Command: BlockOperation {
    var tableView: UITableView?
    var indexPath: IndexPath?
    
    var type: CommandType
    var state: CommandState
    var payload: Data?
    var response: Data?
    
    var serviceModel: NodeServiceModel
    var manager: Manager
    var device: Device
    
    var waitingForWriting: Bool
    var writeSemaphore: DispatchGroup
    
    var waitingForReading: Bool
    var readingSemaphore: DispatchGroup
    
    init(type: CommandType, manager: Manager, device: Device) {
        self.type = type
        self.state = .Begin
        self.payload = nil
        self.response = nil
        
        self.writeSemaphore = DispatchGroup()
        self.readingSemaphore = DispatchGroup()
        self.waitingForWriting = false
        self.waitingForReading = false
        
        self.serviceModel = NodeServiceModel()
        self.manager = manager
        self.device = device
    
        super.init()
        
        self.manager.delegate = self
        
        //self.manager.disconnectFromDevice()
        self.manager.connect(with: self.device)
    }
 
    public func setResponse(raw: Any) {
        switch type {
        case .I:
            response = parseReponse_I(raw: raw)
        case .N:
            response = parseReponse_N(raw: raw)
        case .Q:
            response = parseReponse_Q(raw: raw)
        case .O:
            response = parseReponse_O(raw: raw)
            
        default:
            break
        }
    }
    
    private func parseReponse_I(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_N(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_Q(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_O(raw: Any) -> Data {
        return Data()
    }
    
    
    func write(message: String = "") -> Bool {
        return write(data: message.hexDecodedData())
    }
    func write(data: Data = Data()) -> Bool {
        waitingForWriting = true
        
        writeSemaphore.enter()
        device.peripheral.delegate = self
        let result = writeSemaphore.wait(timeout: .now() + 4)
        
        serviceModel.valueCharacteristic4 = data
        serviceModel.writeValue(withUUID: Characteristic.characteristic4.rawValue, response: true)
        
        if result == .success {
            return true
        }
        
        waitingForWriting = false
        return false
    }

    
    func read(from characteristic: Characteristic) -> Data? {
        waitingForReading = true
        
        readingSemaphore.enter()
        device.peripheral.delegate = self
        serviceModel.setNotify(enabled: true, forUUID: characteristic.rawValue)
        let result = readingSemaphore.wait(timeout: .now() + 4)
        
        if result == .success {
            return serviceModel.valueCharacteristic3
        }
        
        return nil
    }
    
    override func main() {
        super.main()
        
        while device.peripheral.state != .connected {
            print("Device state: \(device.peripheral.state.rawValue)")
            
            manager.disconnectFromDevice()
            usleep(400000)
            manager.connect(with: device)
            usleep(400000)
            print("Connetting...")
        }
        
        if device.peripheral.state == .connected {
            print("Write into 3: 4F 6E 02 00 7E")
            serviceModel.valueCharacteristic4 = "4F6E02007E".hexDecodedData()
            serviceModel.writeValue(withUUID: Characteristic.characteristic4.rawValue, response: true)

            serviceModel.setNotify(enabled: true, forUUID: Characteristic.characteristic3.rawValue)
            let res3 = serviceModel.valueCharacteristic3.reduce("") { "\($0)" + "\(Utils.intToHex(Int($1)) ?? "") " }
            print("Read from 3: \(res3)")
        }
        
        state = CommandState.Begin
        print("Inizio Comando O")
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
        sleep(1)
        
        state = CommandState.Waiting
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
            
        if write(data: "4F6E02007E".hexDecodedData()) == true {
            print("Write effettuata con successo")
        } else {
            print("Write fallita")
        }
        
        state = CommandState.Waiting
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
        
        if let data = read(from: Characteristic.characteristic3) {
            let result = data.reduce("") { "\($0)" + "\(Utils.intToHex(Int($1)) ?? "") " }
            print("Read from 3: \(result)")
        } else {
            print("Read fallita")
        }
        
        state = CommandState.Completed
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
    }
}


extension Command: ManagerDelegate {
    
    func manager(_ manager: Manager, didFindDevice device: Device) {
        
    }
    
    func manager(_ manager: Manager, willConnectToDevice device: Device) {
        device.register(serviceModel: serviceModel)
    }
    
    func manager(_ manager: Manager, connectedToDevice device: Device) {
        device.peripheral.delegate = self
    }
    
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, willRetry retry: Bool) {

    }
}


extension Command: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForReading == true {
            readingSemaphore.leave()
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForReading == true {
            readingSemaphore.leave()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForWriting == true {
            writeSemaphore.leave()
        }
    }
}
*/
