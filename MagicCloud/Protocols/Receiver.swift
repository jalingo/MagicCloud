//
//  Receiver.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
 * This protocol enables conforming types to give access to an array of Recordable, and
 * to prevent / allow that array's didSet to upload said array's changes to the cloud.
 */
public protocol ReceivesRecordable {
    
    /**
     * This boolean property allows / prevents changes to `recordables` being reflected in
     * the cloud.
     */
    var allowComponentsDidSetToUploadDataModel: Bool { get set }
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables: [Recordable] { get set }
}
