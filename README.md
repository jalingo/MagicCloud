# MagicCloud

**Magic Cloud** is a **Swift (iOS) Framework** that makes using **CloudKit** simple and easy.

Just conform any data types that need to be saved as database records to the **MCRecordable** prototype. Then the generic **MCReceiver** classes can maintain a local array of that type, and mirror it to **CloudKit's** databases in the background.

Default setup covers _error handling, subscriptions, account changes and more_. Can be configured / customized for optimized performance, or just use as is. Check out the **Quick Start Guide** to get started with less than 15 lines of code!

## Requirements

Meet the requirements for **CloudKit**, which includes a _paid developer account_.

An **iOS** project. (Why wouldn't you use Swift for that?)

## Getting Started

In order to use **Magic Cloud**, a project has to be configured for **CloudKit** and the **MagicCloud** framework will need to be linked to its workspace.

### Preparing App for CloudKit

**Magic Cloud** is meant to work on top of **Apple's CloudKit** technology, not replace it. The developer does not maintain any actual databases and is not responsible for _data integrity, security or loss_.

Before installing **Magic Cloud** be sure **CloudKit** and **Push Notification** are [enabled in your project's capabilities](https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitQuickStart/EnablingiCloudandConfiguringCloudKit/EnablingiCloudandConfiguringCloudKit.html).

### Installations

If you're comfortable using **CocoaPods** to [manage your dependencies](https://guides.cocoapods.org/using/getting-started.html) (recommended), add the following line to your target in the podfile. 

```ruby
pod 'MagicCloud', '~> 2.2'
```

Then, from your project's directory...

```bash
pod install
```

Alternatively, clone from [github](github.com/jalingo/MagicCloud), then add the framework to your project manually (not recommended).

### Quick Start Guide

Check out the **Quick Start Guide**, a how-to video at [Escape Chaos](https://www.escapechaos.com/magiccloud), and see a test app get fully configured in less than 15 lines of code.

## Examples

For basic projects, these examples should be all that is necessary.

### MCRecordable

Any data type that needs to have it's model stored as records (and it's properties saved as those records' fields) will need to conform to the `MCRecordable` protocol. 

```swift
extension MockType: MCRecordable {
    
    public var recordType: String { return "MockType" }            // <-- This string will serve as a CKRecordType.Name
    
    public var recordFields: Dictionary<String, CKRecordValue> {   // <-- This is where the properties that should be CKRecord   
        get {                                                      //     fields are updated / recovered. 
            return [Mock.key: created as CKRecordValue] 
        }
        
        set {
            if let date = newValue[Mock.key] as? Date { created = date }
        }
    }
    
    public var recordID: CKRecordID {                              // <-- This ID needs to be unique for each instance.
        get { return _recordID ?? CKRecordID(recordName: "EmptyRecord") }
        set { _recordID = newValue }                               // <-- This value needs to be saved when instances are
    }                                                              //     created from downloaded database records. 
    
    // MARK: - Functions: Recordable
    
    public required init() { }                                     // <-- This empty init is used to generate empty instances
}                                                                  //     that can then be overwritten from database records.
```

### MCReceiver

Once there are recordables to work with, use `MCReceiver`(s) to save and recover these types in the `CloudKit` databases.

```swift
let mocksInPublicDatabase = MCReceiver<MockType>(db: .publicDB)
let mocksInPrivateDatabase = MCReceiver<MockType>(db: .privateDB)
```

Shortly after they're initialized, the receivers should finish downloading and transforming any existing records. These can be accessed from the `recordables` array.

```swift
let publicMocks: [MockType] = mocksInPublicDatabase.recordables
```

Voila! Any changes to records in the cloud database (add / edit / remove) will automatically be reflected in the receiver's recordables array until it deinits.

**Note:**  While multiple local receivers for the same data type reduces stability, it is supported. Any change will be reflected in all receivers, both in the local app and in other users' apps.

### MCUpload

In order to add an `MCRecordable` to the database and other local receivers, the `MCUpload` operation and an associated receiver is required.

```swift
let mock = MockType()
 
let op = MCUpload([mock], from: mocksInPublicDatabase, to: .publicDB)
op.start()
```

**Note:**  While multiple local receivers for the same data type reduces stability, it is supported. Any change will be reflected in all receivers, both in the local app and in other users' apps.

**Caution:**  In the current version, adding elements directly to recordables will not be mirrored in the database (coming in a future release).

### MCDelete

In order to remove an `MCRecordable` from the database and other local receivers, the `MCDelete` operation and an associated receiver is required.

```swift
let mock = MockType()

let op = MCDelete([mock], of: mocksInPublicDatabase, from: .publicDB)
op.start()
```

**Note:**  While multiple local receivers for the same data type reduces stability, it is supported. Any change will be reflected in all receivers, both in the local app and in other users' apps.

**Caution:**  In the current version, removing elements directly from recordables will not be mirrored in the database (coming in a future release).

### MCUserRecord

## Considerations

While the aforementioned code is all that is needed for most projects, there are still a few design considerations and common issues to keep in mind.

### Concurrency, Grand Central Dispatch & the Main Thread

If this project is your first attempt at working with asynchronous operations, **Apple** has a lot of great resources out there that will ultimately save you a lot of time and trouble...

[CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
[CloudKit QuickStart](https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitQuickStart/Introduction/Introduction.html)
[Concurrency Programming Guide](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html)
[CloudKit Design Guide](https://developer.apple.com/library/content/documentation/General/Conceptual/iCloudDesignGuide/DesigningforCloudKit/DesigningforCloudKit.html#//apple_ref/doc/uid/TP40012094-CH9-SW1)

Thanks to **Grand Central Dispatch**, **Apple** has done most of the heavy lifting for us, but you will still have to understand the order your processes will execute and that varying amounts of time will be needed for cloud interactions to occur. **Dispatch Groups** (and **XCTExpectations** for unit testing) can be very helpful, in this regard.

Do ***NOT*** lock up the **main thread** with cloud activity; every app needs to keep waiting for data and updating views on separate threads. If your not sure what that means, then you may want to more closely review the documentation mentioned above.

### Error Notifications

**Error Handling** is a big part of cloud development, but in most cases **Magic Cloud** can deal with them sufficiently. In case developers need to perform additional handling, every time an issue is encountered a **Notification** is posted that includes the original **CKError**.

To listen for these notifications, use `MCErrorNotification`.

```
let name = Notification.Name(MCErrorNotification)
NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { notification in

     // Error notifications from MagicCloud should always include the actual CKError as Notification.object.
     if let error = notification.object as? CKError { print("CKError: \(error.localizedDescription)") }
}
```

**CAUTION:**  In cases where there's a batch issue, a single error may generate multiple notifications.

### CloudKit Dashboard

## Reporting Bugs

If you've had any issues, first please review the existing documentation. After being certain that you're dealing with a replicable bug, the best way to submit the issue is through GitHub.

```
Issues > Create New...
```

You can also email `dev@escapechaos.com`, or for a more immediate response try **Stack Overflow**.
