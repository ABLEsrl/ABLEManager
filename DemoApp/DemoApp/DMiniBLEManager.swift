//
//  DMiniBLEManager.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 23/03/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager

public class DMiniBLEManager {
    public static var shared = DMiniBLEManager()
    
    private var readedTag: Int = 0
    
    private var currentTag:         DMiniTagResponse
    private var currentWriteTag:    DMiniWriteTagResponse
    private var connectionObserver: NSKeyValueObservation?
    
    init() {
        currentTag      = DMiniTagResponse()
        currentWriteTag = DMiniWriteTagResponse()
        
        connectionObserver = nil
    }
    
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
        BluetoothManager.shared.scanAndConnect(to: "D-mini") { (device) in
            callback(device)
        }
    }
    
    
    
    func getTagsCountOnReader(_ callback: @escaping ((Int, Bool)->Void) ) {
        // La risposta del palmare è: $2808xxxx\r\n
        BluetoothManager.shared.subscribe(to: DMiniCharacteristic.characteristic5.rawValue) { (device, rawResponse, success) in
            if success {
                let response = DMiniCountResponse(with: rawResponse.asciiString)
                //print("Tags count raw respone: \(rawResponse.asciiString)")
                //print("Tags presenti nel lettore: \(response.tagsCount)\n")
                callback(response.tagsCount, true)
            }
        }
        
        let counter = DMiniCommand.tagCountCommand()
        BluetoothManager.shared.write(command: counter, to: DMiniCharacteristic.characteristic5.rawValue, modality: .withoutResponse)
    }
    
    func readTag(index: Int, callback: @escaping ((String, Bool)->Void) ) {
        self.currentTag = DMiniTagResponse()
        
        BluetoothManager.shared.subscribe(to: DMiniCharacteristic.characteristic5.rawValue) { (device, response, success) in
            if success {
                //print("Ricevo risposta: " + response.asciiString)
                
                self.currentTag.append(string: response.asciiString)
                if self.currentTag.parsedCompletely() {
                    // print("Tag Parsato: " + self.currentTag.tagPayload)
                    callback(self.currentTag.tagPayload, true)
                }
            }
        }
        
        let readTag = DMiniCommand.readTagCommand()
        BluetoothManager.shared.write(command: readTag, to: DMiniCharacteristic.characteristic5.rawValue, modality: .withoutResponse)
    }
    
    func readAllTags(_ callback: @escaping (([String], Bool)->Void) ) {
        print("Read all tags...")
        getTagsCountOnReader { (tagsCount, success) in
            if tagsCount <= 0 {
                print("No tags on reader")
                return
            }
            
            DispatchQueue(label: "tags.reader.queue").async {
                var tags  = [String]()
                let group = DispatchGroup()
                
                for i in 1...tagsCount {
                    group.enter()
                    
                    DispatchQueue(label: "read.tag.reader.queue").sync {
                        self.readTag(index: i) { (tag, success) in
                            print("\tTag: \(tag)")
                            tags.append(tag)
                            group.leave()
                        }
                        
                        group.wait()
                    }
                }
                
                group.notify(queue: DispatchQueue.main) {
                    callback(tags, true)
                }
            }
        }
    }
    
    
    func writeTag(value: String, callback: @escaping ((WriteTagResponseCode)->Void) ) {
        self.currentWriteTag = DMiniWriteTagResponse()
        
        BluetoothManager.shared.subscribe(to: DMiniCharacteristic.characteristic5.rawValue) { (device, response, success) in
            if success {
                print("Ricevo risposta: " + response.asciiString)
                
                self.currentWriteTag.append(string: response.asciiString)
                if self.currentWriteTag.parsedCompletely() {
                    // print("Tag Parsato: " + self.currentTag.tagPayload)
                    callback(self.currentWriteTag.responseCode)
                }
            } else {
                print("Errore nella ricezione della risposta")
            }
        }
        
        let writeTag = DMiniCommand.writeTagCommand(value: value)
        //print("Max write value: \(String(describing: BluetoothManager.shared.connectedDevice?.peripheral?.maximumWriteValueLength(for: .withResponse)))")
        BluetoothManager.shared.write(command: writeTag, to: DMiniCharacteristic.characteristic5.rawValue, modality: .withoutResponse)
    }

    func writeAllTags(values: [String], callback: @escaping (([WriteTagResponseCode])->Void) ) {
        DispatchQueue(label: "tags.writer.queue").async {
            var resCodes = [WriteTagResponseCode]()
            let group    = DispatchGroup()

            values.forEach { (value) in
                group.enter()
                self.writeTag(value: value) { (responseCode) in
                    resCodes.append(responseCode)
                    group.leave()
                }
                group.wait()
            }
            
            group.notify(queue: .main) {
                callback(resCodes)
            }
        }
    }
}
