//
//  DEUtil.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/7/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

let DE_WEEKDAY_OFFSET = [
    "sonntag": 0,
    "so": 0,
    "montag": 1,
    "mo": 1,
    "dienstag": 2,
    "di":2,
    "mittwoch": 3,
    "mi": 3,
    "donnerstag": 4,
    "do": 4,
    "freitag": 5,
    "fr": 5,
    "samstag": 6,
    "sa": 6
]
let DE_WEEKDAY_WORDS_PATTERN = "(?:" + DE_WEEKDAY_OFFSET.keys.joined(separator: "|") + ")"

let DE_MONTH_OFFSET = [
    "januar": 1,
    "jan": 1,
    "jan.": 1,
    "februar": 2,
    "feb": 2,
    "feb.": 2,
    "märz": 3,
    "mär": 3,
    "mär.": 3,
    "april": 4,
    "apr": 4,
    "apr.": 4,
    "mai": 5,
    "juni": 6,
    "jun": 6,
    "jun.": 6,
    "juli": 7,
    "jul": 7,
    "jul.": 7,
    "august": 8,
    "aug": 8,
    "aug.": 8,
    "september": 9,
    "sep": 9,
    "sep.": 9,
    "sept": 9,
    "sept.": 9,
    "oktober": 10,
    "okt": 10,
    "okt.": 10,
    "november": 11,
    "nov": 11,
    "nov.": 11,
    "dezember": 12,
    "dez": 12,
    "dez.": 12
]
let DE_MONTH_OFFSET_PATTERN = "(?:" + DE_MONTH_OFFSET.keys.joined(separator: "|") + ")"

let DE_INTEGER1_WORDS = [
    "einen": 1,
    "eine": 1,
    "einer": 1,
    "ein": 1,
    "eines": 1,
    "einem": 1,
]
let DE_INTEGER1_WORDS_PATTERN = "(?:" + DE_INTEGER1_WORDS.keys.joined(separator: "|") + ")"

let DE_INTEGER_WORDS = DE_INTEGER1_WORDS.merged(with: [
    "zwei": 2,
    "drei": 3,
    "vier": 4,
    "fünf": 5,
    "sechs": 6,
    "sieben": 7,
    "acht": 8,
    "neun": 9,
    "zehn": 10,
    "elf": 11,
    "zwölf": 12
])
let DE_INTEGER_WORDS_PATTERN = "(?:" + DE_INTEGER_WORDS.keys.joined(separator: "|") + ")"

// all need /n/r/m/s
private let DE_ORDINAL_WORDS_BASIC = [
    "erste": 1,
    "zweite": 2,
    "dritte": 3,
    "vierte": 4,
    "fünfte": 5,
    "sechste": 6,
    "siebte": 7,
    "achte": 8,
    "neunte": 9,
    "zehnte": 10,
    "elfte": 11,
    "zwölfte": 12,
    "dreizehnte": 13,
    "vierzehnte": 14,
    "fünfzehnte": 15,
    "sechzehnte": 16,
    "siebzehnte": 17,
    "achtzehnte": 18,
    "neunzehnte": 19,
    "zwanzigste": 20,
    "einundzwanzigste": 21,
    "zweiundzwanzigste": 22,
    "dreiundzwanzigste": 23,
    "vierundzwanzigste": 24,
    "fünfundzwanzigste": 25,
    "sechsundzwanzigste": 26,
    "siebenundzwanzigste": 27,
    "achtundzwanzigste": 28,
    "neunundzwanzigste": 29,
    "dreißigste": 30,
    "einunddreißigste": 31
]

let DE_ORDINAL_WORDS = DE_ORDINAL_WORDS_BASIC.reduce([String: Int]()) { (result, keyValue) -> [String: Int] in
    var result = result
    result[keyValue.key + "n"] = keyValue.value
    result[keyValue.key + "r"] = keyValue.value
    result[keyValue.key + "m"] = keyValue.value
    result[keyValue.key + "s"] = keyValue.value
    return result
}

let DE_ORDINAL_WORDS_PATTERN = "(?:\(DE_ORDINAL_WORDS_BASIC.keys.map{ $0 + "[nrms]?" }.joined(separator: "|").replacingOccurrences(of: " ", with: "[ -]")))";
