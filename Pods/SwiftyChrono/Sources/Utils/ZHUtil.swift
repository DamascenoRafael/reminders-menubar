//
//  ZHUtil.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

let ZH_NUMBER = [
    "零": 0,
    "一": 1,
    "二": 2,
    "兩": 2,
    "两": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
    "十": 10,
    "廿": 20,
    "卅": 30,
]

let ZH_NUMBER_PATTERN = "[" + ZH_NUMBER.keys.joined(separator: "") + "]"

let ZH_WEEKDAY_OFFSET = [
    "天": 0,
    "日": 0,
    "一": 1,
    "二": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
]

let ZH_WEEKDAY_OFFSET_PATTERN = "[" + ZH_WEEKDAY_OFFSET.keys.joined(separator: "") + "]"

func ZHStringToNumber(text: String) -> Int {
    var number = 0;
    
    for char in text.map({ String($0) }) {
        let n = ZH_NUMBER[char]!
        if char == "十" {
            number = number == 0 ? n : number * n
        } else {
            number += n
        }
    }
    
    return number
}

func ZHStringToYear(text: String) -> Int {
    var string = ""
    
    for char in text.map({ String($0) }) {
        string += "\(ZH_NUMBER[char]!)"
    }
    
    return Int(string)!
}


