## SwiftyChrono

A natural language date parser in Swift, designed to extract date information from any given text.
 
When we were [integrating Siri](https://quire.io/blog/p/Quire-Siri-Best-Task-Manager-Friend.html) with our [iOS app](https://itunes.apple.com/us/app/quire-task-manager-for-teams/id1095193897?mt=8), we found that JavascriptCore runtime is running on resource-limited extensions and will crash due to memory limitation. So, we created a Swift version. Thanks to Wanasit Tanakitrungruang's [chrono.js](https://github.com/wanasit/chrono).

SwiftyChrono supports most date and time formats, such as:
* Today, Tomorrow, Yesterday, Last Friday, etc
* 17 August 2013 - 19 August 2013
* This Friday from 13:00 - 16.00
* 5 days ago
* Sat Aug 17 2013 18:40:39 GMT+0900 (JST)
* 2014-11-30T08:15:30-05:30

There are more available patterns. You can simply download it and try.

### Status

This project is currently being used in the [Quire](https://quire.io) iOS app.

### Requirements

Swift 4.2
* Xcode 10
* Swift 4.2

Swift 3
* iOS 9.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 2.0+
* Xcode 8
* Swift 3.0
* 64 bit device (didn't test on 32 bit device)

### Install

CocoaPods

```ruby
use_frameworks!

target 'MyApp' do
	pod 'SwiftyChrono'
end
```

### Usage

#### Initialization

```swift
import SwiftyChrono
let chrono = Chrono()
```
#### Parse

```swift
chrono.parse(text: "Bring a book tomorrow")
// [
// 	SwiftyChrono.ParsedResult(ref: 2017-02-22 08:33:33 +0000,
// 	index: 13,
// 	text: "tomorrow",
// 	tags: [
// 		SwiftyChrono.TagUnit.enCasualDateParser: true
// 	],
// 	start: SwiftyChrono.ParsedComponents(
// 		knownValues: [
// 			SwiftyChrono.ComponentUnit.day: 23,
// 			SwiftyChrono.ComponentUnit.year: 2017,
// 			SwiftyChrono.ComponentUnit.month: 2],
// 		impliedValues: [
// 			SwiftyChrono.ComponentUnit.minute: 0,
// 			SwiftyChrono.ComponentUnit.second: 0,
// 			SwiftyChrono.ComponentUnit.millisecond: 0,
// 			SwiftyChrono.ComponentUnit.hour: 12
// 		]),
// 	end: nil,
// 	isMoveIndexMode: false)
// ]

// refDate (1485921600000) is 2017/2/1 12:00:00.0000
let refDate = Date(timeIntervalSince1970: 1485921600)
// you can add a reference date
chrono.parse(text: "Bring a book tomorrow", refDate: refDate)
```

#### Quick Date Parse

```swift
chrono.parseDate(text: "Bring a book tomorrow", refDate: refDate)
// "Feb 2, 2017, 12:00 PM"
```

#### Other Options

```swift
// options: .forwardDate - the match date is always later than refDate
chrono.parseDate(text: "Bring a book on December 1", refDate: refDate)
// "Dec 1, 2016, 12:00 PM"
chrono.parseDate(text: "Bring a book on December 1", refDate: refDate, opt: [.forwardDate: 1])
// "Dec 1, 2017, 12:00 PM"

// you can assignee which hour in 
// morning, afternoon, evening, noon
chrono.parseDate(text: "Bring a book tomorrow morning", refDate: refDate, opt: [.morning: 10])
// "Feb 2, 2017, 10:00 AM"

/// specify the preferred language will let the answer more acurate
chrono.parse(text: "you can do it tomorrow", refDate: refDate).map{ $0.text }
// ["do", "tomorrow"]
Chrono.preferredLanguage = .english
chrono.parse(text: "you can do it tomorrow", refDate: refDate).map{ $0.text }
// ["tomorrow"]


/// specify sixMinutesFixBefore1900 to true, if the date before 1900 is in your use case
Chrono.sixMinutesFixBefore1900 = true
chrono.parseDate(text: "you can do it 1970/1/1")


/// override defaut hour, minute, second, millisecond
// the default implied hour is 12 pm if the given text doesn't specify
Chrono.defaultImpliedHour = 1
Chrono.defaultImpliedMinute = 1
Chrono.defaultImpliedSecond = 1
Chrono.defaultImpliedMillisecond = 1
chrono.parseDate(text: "you can do it tomorrow", refDate: refDate)?.timeIntervalSince1970
// 1485968461.001, 2017/2/1 01:01:01.001
```

### Demo Video

[![Everything Is AWESOME](https://img.youtube.com/vi/f5PKHumpwsE/0.jpg)](https://www.youtube.com/watch?v=f5PKHumpwsE "Talk to Siri to Add Tasks")
