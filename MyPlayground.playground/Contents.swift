import Cocoa
import SwiftyChrono

let parser = Chrono()
Chrono.preferredLanguage = .english
let result = parser.parse(text: "Task 12 aug", refDate: Date())
print(result[0].text)
