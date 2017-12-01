//
//  MCReferable.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/// This key should be used for storing references in a CKRecord, to allow 'MCDownload' by reference to work.
let OWNER_KEY = "Owners"

/**
 * The MCReferable protocol ensures that any conforming instances have what is necessary
 * to be referenced by an owner record in the cloud database. For that relationship
 * to be reflected in the cloud database, conforming instances must also conform to the
 * Recordable protocol and it's 'Recordable.recordFields' dictionary must be amended to
 * store collected CKReferences.
 */
public protocol MCReferable: MCRecordable {
    
    // MARK: - Properties
    
    /**
     * This array stores a conforming instance's CKReferences used as database
     * relationships. Instance is owned by each record that is referenced in the
     * array (supports multiple ownership).
     */
    var references: [CKReference] { get }
    
    // MARK: - Functions
    
    /**
     * This method is used to store new ownership relationship in references array,
     * and to ensure that cloud data model reflects such changes. If necessary, ensures
     * that owned instance has only a single reference in its list of references.
     *
     * - CAUTION: 'OWNER_KEY' must be used for references' field for compatibility with
     *            'MCDownload' operation.
     */
    mutating func attachReference(reference: CKReference)
    
    /**
     * This method is used to store new ownership relationship in references array,
     * and to ensure that cloud data model reflects such changes. If object has no
     * references, it may need to be deleted from database (that should happen here).
     */
    mutating func detachReference(reference: CKReference)
}
