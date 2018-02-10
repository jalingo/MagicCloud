# MagicCloud

**Magic Cloud** is a **Swift (iOS) Framework** that makes using **CloudKit** simple and easy.

Just conform any data types that need to be saved as database records to the **MCRecordable** prototype. Then the generic **MCReceiver** classes can maintain a local array of that type, and mirror it to **CloudKit's** databases in the background.

Default setup covers _error handling, subscriptions, account changes and more_. Can be configured / customized for optimized performance, or just use as is. Check out the **Quick Start Guide** to get started with less than 15 lines of code!

## Requirements

Meet the requirements for **CloudKit**, which includes a _paid developer account_.

An **iOS** project. (Why wouldn't you use Swift for that?)

## Getting Started

In order to use **Magic Cloud**, a project has to be configured for **CloudKit** and the **MagicCloud** framework will need to be linked to its workspace.

#### Preparing App for CloudKit

**Magic Cloud** is meant to work on top of **Apple's CloudKit** technology, not replace it. The developer does not maintain any actual databases and is not responsible for data integrity, security or loss.

Before installing **Magic Cloud** be sure **CloudKit** and **Push Notification** are [enabled in your project's capabilities](https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitQuickStart/EnablingiCloudandConfiguringCloudKit/EnablingiCloudandConfiguringCloudKit.html).

#### CocoaPods or Clone

If you're comfortable using **CocoaPods** to manage your dependencies (recommended), add the following line to your podfile. 

```
  pod 'MagicCloud', '~> 2.2'
```

Alternatively, you could clone from github.com/jalingo/MagicCloud.git (not recommended). Then add the framework to your project manually.

#### Quick Start Guide

A how-to video at escapeChaos.com/MagicCloud, check out the **Quick Start Guide** and see a test app get fully configured in less than 15 lines of code.

## Examples

For basic projects, these examples should be all that is necessary.

#### MCRecordable

Any data type that needs to have it's model stored as records will need to conform to the `MCRecordable` protocol. 

```swift
extension MockType: MCRecordable {
    
    public var recordType: String { return "MockType" }            // <-- This string will serve as a CKRecordType.Name
    
    public var recordFields: Dictionary<String, CKRecordValue> {   // <-- This is where the properties that need to be saved   
        get {                                                      //     are set / recovered from CKRecord fields. 
            return [Mock.key: created as CKRecordValue] 
        }
        
        set {
            if let date = newValue[Mock.key] as? Date { created = date }
        }
    }
    
    public var recordID: CKRecordID {
        get { return _recordID ?? CKRecordID(recordName: "EmptyRecord") }
        set { _recordID = newValue }
    }
    
    // MARK: - Functions: Recordable
    
    public required init() { }
}
```

#### MCReceiver

#### MCUserRecord

## Considerations

While the aforementioned code is all that needed for most projects, there are still a few design considerations and common issues to keep in mind.

#### Concurrency, Grand Central Dispatch & the Main Thread

If this project is your first attempt at working with asynchronous operations, there are a lot of great resources out there that will ultimately save you a lot of time and trouble...

[CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
Apple's Concurrency Programming Guide
Apple's CloudKit Design Guide
Apple's Grand Central Dispatch ...

Thanks to **Grand Central Dispatch**, **Apple** has done most of the heavy lifting for us, but you will still have to understand the order your processes will execute and that varying amounts of time will be needed for cloud interactions to occur. **Dispatch Groups** (and **XCTExpectations** for unit testing) can be very helpful, in this regard.

Do ***NOT*** lock up the **main thread** with cloud activity; every app needs to keep waiting for data and updating views on separate threads. If your not sure what that means, then you may want to more closely review the documentation mentioned above.

#### Error Notifications

**Error Handling** is a big part of cloud development, but in most cases **Magic Cloud** can deal with them sufficiently. In case developers need to perform additional handling, every time an issue is encountered a **Notification** is posted that includes the original **CKError**.

To listen for these notifications, use `MCErrorNotification`.

```
let name = Notification.Name(MCErrorNotification)
NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { notification in

     // Error notifications from MagicCloud should always include the actual CKError as Notification.object.
     if let error = notification.object as? CKError { print("CKError: \(error.localizedDescription)") }
}
```

***CAUTION:***  In cases where there's a batch issue, a single error may generate multiple notifications.

#### CloudKit Dashboard

## Reporting Bugs

If you've had any issues, first please review the existing documentation. After being certain that you're dealing with a replicable bug, the best way to submit the issue is through GitHub.

```
Issues > Create New...
```

You can also email `dev@escapechaos.com`, or for a more immediate response try **Stack Overflow**.
