//
//  Pause.swift
//  Voyage01
//
//  Created by j.lingo on 10/11/16.
//  Copyright © 2016 j.lingo. All rights reserved.
//

import Foundation

public class Pause: Operation {
    
    // MARK: - Properties
    
    fileprivate var timerIncomplete = true
    
    fileprivate let duration: TimeInterval
    
    // MARK: - Functions
    
    // MARK: - Functions: Operation
    
    public override func main() {
        if isCancelled { return }
        
        var _ = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
            self.timerIncomplete = false
        }
        
        if isCancelled { return }
        
        print("pausing")

        CFRunLoopRun()
        
        while timerIncomplete {             // <-- !! Not triggering?
            /* waiting */
            print(".", separator: "", terminator: "")
            
            if isCancelled { timerIncomplete = false }
        }
    }
    
    // MARK: - Functions: Initializers
    
    fileprivate override init() { duration = -1 }
    
    init(seconds: TimeInterval) {
        duration = seconds
        super.init()
    }
}
