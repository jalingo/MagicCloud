//
//  Pause.swift
//  Voyager
//
//  Created by j.lingo on 10/11/16.
//  Copyright © 2016 j.lingo. All rights reserved.
//

import Foundation

/// This operation class can be used to set delays as a dependency in operation chains.
public class Pause: Operation {
    
    // MARK: - Properties
    
    fileprivate var timerIncomplete = true
    
    fileprivate let duration: TimeInterval
    
    // MARK: - Functions
    
    // MARK: - Functions: Operation
    
    /// If not cancelled, this method override will set a timer for the specified duration and wait.
    public override func main() {
        if isCancelled { return }
        
        var _ = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
            self.timerIncomplete = false
        }
        
        if isCancelled { return }
        
        print("** pause starting")

        CFRunLoopRun()
        
        while timerIncomplete { // waiting
            if isCancelled { timerIncomplete = false }
        }
    }
    
    // MARK: - Functions: Initializers
        
    public init(seconds: TimeInterval) {
        duration = seconds
        super.init()
    }
}
