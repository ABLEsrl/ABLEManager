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
    
    private var currentTag: DMiniTagResponse
    private var connectionObserver: NSKeyValueObservation?
    
    init() {
        currentTag = DMiniTagResponse()
        
        connectionObserver = nil
    }
    
    func registerConnectionObserver(_ callback: @escaping ((Bool)->Void) ) {
        connectionObserver = BluetoothManager.shared.registerConnnectionObserver { (connected) in
            callback(connected)
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
        currentTag = DMiniTagResponse()
        
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
        getTagsCountOnReader { (tagsCount, success) in
            if tagsCount <= 0 {
                return
            }
            
            DispatchQueue(label: "tags.reader.queue").async {
                var tags = [String]()
                let group = DispatchGroup()
                
                for i in 1...tagsCount {
                    group.enter()
                    
                    self.readTag(index: i) { (tag, success) in
                        tags.append(tag)
                        group.leave()
                    }
                    
                    group.wait()
                }
                
                group.notify(queue: DispatchQueue.main) {
                    callback(tags, true)
                }
            }
        }
    }

}
