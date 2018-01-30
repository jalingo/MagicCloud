//
//  DatabaseTransfer.swift
//  MagicCloud
//
//  Created by James Lingo on 1/29/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation
import CloudKit

public protocol MCDatabaseTransferer {
    
    associatedtype T: MCRecordable
    
    /// This computed property saves and recovers recordables to be transfered between production and development database.
//    var recordsToTransfer: [T]? { get set }
    
    /// This method prepares local storage by touching file and
//    func setupLocalStorage()
    
    func saveToDefaults(records: [T])
    func recoverFromDefaults() -> [T]?
}

//extension AdvisorViewController: MCDatabaseTransferer {
//    typealias T = Tip
//
//    func saveTips() {
//        self.saveToDefaults(records: tips.recordables)
//    }
//
//    func recoverTips() {
//        let recoveredTips = self.recoverFromDefaults()
//        print("                             count: #\(String(describing: recoveredTips?.count))")
//        let op = MCUpload(recoveredTips, from: tips, to: .publicDB)
//        OperationQueue().addOperation(op)
//    }
//
//    func saveToDefaults(records: [Tip]) {
//        var coded = [EncodedMCRecordable]()
//        for record in records { coded.append(EncodedMCRecordable(record)) }
//
//        let data = NSKeyedArchiver.archivedData(withRootObject: coded)
//        UserDefaults().setValue(data, forKey: "MCData")
//    }
//
//    func recoverFromDefaults() -> [Tip]? {
//        if let data = UserDefaults().data(forKey: "MCData") { return convert(data: data) }
//        return nil
//    }
//
//    func convert(data: Data) -> [Tip]? {
//        let results = NSKeyedUnarchiver.unarchiveObject(with: data) as? [EncodedMCRecordable]
//        return results?.map { $0.data }
//    }
//}
//
//@objc(SBTipLocalStorage)class EncodedMCRecordable: NSObject, NSCoding {
//
//    let data: Tip
//
//    func encode(with aCoder: NSCoder) {
//        let keys = data.recordFields.keys
//        for key in keys { aCoder.encode(data.recordFields[key], forKey: key) }
//    }
//
//    init(_ tip: Tip) { data = tip }
//
//    required init?(coder aDecoder: NSCoder) {
//        var tip = Tip()
//
//        let keys = tip.recordFields.keys
//        for key in keys { tip.recordFields[key] = aDecoder.decodeObject(forKey: key) as? CKRecordValue }
//
//        data = tip
//    }
//}

//                                      ^^^^^    Did     ^^^^^
//                                      |||||    work    |||||  - Specific
//                                            ----------
//                                      |||||   Didn't   |||||  - Generic
//                                      vvvvv    work    vvvvv

//extension MCDatabaseTransferer {
//    
//    func recoverFromDefaults() -> [T]? {
//        if let data = UserDefaults().data(forKey: "MCData") { return convert(data: data) }
//        return nil
//    }
//    
//    func saveToDefaults(records: [T]) {
//        var coded = [CodedRecordable<T>]()
//        for record in records { coded.append(CodedRecordable<T>(rec: record)) }
//            
//        let data = NSKeyedArchiver.archivedData(withRootObject: coded)
//        UserDefaults().setValue(data, forKey: "MCData")
//    }
//    
//    func convert(data: Data) -> [T]? {
//        let result = NSKeyedUnarchiver.unarchiveObject(with: data) as? [CodedRecordable<T>]
//        return result?.map { $0.recordable }
//    }
//}
//
//class CodedRecordable<T: MCRecordable>: NSObject, NSCoding {
//
//    var recordable: T
//    
//    func encode(with aCoder: NSCoder) {
//        let keys = recordable.recordFields.keys
//        for key in keys { aCoder.encode(recordable.recordFields[key], forKey: key) }
//    }
//    
//    init(rec: T) { recordable = rec }
//    
//    required init?(coder aDecoder: NSCoder) {
//        var new = T()
//        let keys = new.recordFields.keys
//        
//        for key in keys { new.recordFields[key] = aDecoder.decodeObject(forKey: key) as? CKRecordValue }
//
//        recordable = new
//    }
//}

