import Cocoa
import SwiftyChrono

import Cocoa
import SwiftyChrono

let chrono = Chrono()
Chrono.preferredLanguage = .english
let refDate = Date()
let parsed = chrono.parse(text: "Autolettura at 9pm", refDate: refDate)
print(parsed)


