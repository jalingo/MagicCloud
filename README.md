# MagicCloud

**Magic Cloud** is a **Swift (iOS) Framework** that makes using **CloudKit** simple and easy.

Just conform any data types that need to be saved as database records to the **MCRecordable** prototype. Then the generic **MCReceiver** classes can maintain a local array of that type, and mirror it to **CloudKit's** databases in the background.

Default setup covers _error handling, subscriptions, account changes and more_. Can be configured / customized for optimized performance, or just use as is. Check out the **Quick Start Guide** to get started with less than 15 lines of code!

## Requirements

## Getting Started

#### Preparing App for CloudKit

#### CocoaPods or Clone

#### Quick Start Guide

## Examples

#### MCRecordable

#### MCReceiver

#### MCUserRecord

## Considerations

#### Concurrency, Grand Central Dispatch & the Main Thread

If this project is your first attempt at working asynchronous operations, there are a lot of great resources out there that will ultimately save you a lot of time and trouble...

```
Apple's Concurrency Programming Guide
Apple's Grand Central Dispatch ...
```

Thanks to Grand Central Dispatch, Apple has done most of the heavy lifting for us, but you will still have to understand the order your processes will execute and that varying amounts of time will be needed for cloud interactions to occur. Dispatch Groups (and XCTExpectations for unit testing) can be very helpful, in this regard.

Do **NOT** lock up the main thread with synchronous activity; every app needs to separate waiting for data and updating views.

#### Error Notifications & Authentication

## Reporting Bugs

If you've had any issues, first please review the existing documentation. After being certain that you're dealing with a replicable bug the best way to submit the issue is through GitHub.

```
 
```

You can also email `dev@escapechaos.com`, or for a more immediate response check out Stack Overflow.
