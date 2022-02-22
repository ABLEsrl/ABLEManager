//
//  TimeoutTimer.swift
//  ABLEManager
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


open class TimeoutTimer {
    
    public static func detachTimer(relative deadline: Double, interval: TimeInterval = 2, callback: @escaping ()->()) -> Timer {
        let timer = Timer(fire: Date(timeInterval: deadline, since: Date()), interval: interval, repeats: false) { (timer) in
            DispatchQueue.main.async {
                callback()
            }
        }
        
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        return timer
    }
    
    public static func invalidate(timer: Timer?) {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
