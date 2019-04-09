//
//  ABLEDispatchGroup.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 09/04/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation

open class ABLEDispatchGroup {
    private var semaphore: DispatchGroup
    private var needLeave: Bool
    
    
    init() {
        semaphore = DispatchGroup()
        needLeave = false
    }
    
    public func enter() {
        semaphore.enter()
    }
    
    public func leave() {
        if needLeave == true {
            semaphore.leave()
        }
    }
    
    public func wait() {
        needLeave = true
        semaphore.wait()
    }
    
    public func wait(timeout: DispatchTime) -> DispatchTimeoutResult {
        needLeave = true
        return semaphore.wait(timeout: timeout)
    }
}
