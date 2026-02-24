//
//  APIResponse.swift
//  reminders-menubar
//
//  API Response Models for REST API
//

import Foundation
import CoreGraphics

extension CGColor {
    var hexString: String? {
        guard let components = components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
