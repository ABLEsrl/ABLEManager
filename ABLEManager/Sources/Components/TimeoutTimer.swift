//
//  TimeoutTimer.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 19/02/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


class TimeoutTimer {
    
    static func detachTimer(relative deadline: Double, callback: @escaping ()->()) -> Timer {
        let timer = Timer(fire: Date(timeInterval: deadline, since: Date()), interval: 2, repeats: false) { (timer) in
            DispatchQueue.main.async {
                callback()
            }
        }
        
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        return timer
    }
    
    static func invalidate(timer: Timer?) {
        if let timeout = timer {
            timeout.invalidate()
        }
    }
}
