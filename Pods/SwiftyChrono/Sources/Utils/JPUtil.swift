//
//  JPUtil.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

// source: https://gist.github.com/sgr-ksmt/2dcf11a64cdb22d44517
extension String {
    private func convertFullWidthToHalfWidth(reverse: Bool) -> String {
        let str = NSMutableString(string: self) as CFMutableString
        CFStringTransform(str, nil, kCFStringTransformFullwidthHalfwidth, reverse)
        return str as String
    }
    
    var hankaku: String {
        return convertFullWidthToHalfWidth(reverse: false)
    }
    
    var zenkaku: String {
        return convertFullWidthToHalfWidth(reverse: true)
    }
    
    var hankakuOnlyNumber: String {
        return convertFullWidthToHalfWidthOnlyNumber(fullWidth: false)
    }
    
    var zenkakuOnlyNumber: String {
        return convertFullWidthToHalfWidthOnlyNumber(fullWidth: true)
    }
    
    private func convertFullWidthToHalfWidthOnlyNumber(fullWidth: Bool) -> String {
        var str = self
        let pattern = fullWidth ? "[0-9]+" : "[０-９]+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let results = regex.matches(in: str, options: [], range: NSMakeRange(0, str.count))
        
        results.reversed().forEach {
            let subStr = (str as NSString).substring(with: $0.range)
            str = str.replacingOccurrences(of: subStr, with: (fullWidth ? subStr.zenkaku : subStr.hankaku))
        }
        return str
    }
}
