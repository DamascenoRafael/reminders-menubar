//
//  FRUtil.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

let FR_WEEKDAY_OFFSET = [
    "dimanche": 0,
    "dim": 0,
    "lundi": 1,
    "lun": 1,
    "mardi": 2,
    "mar":2,
    "mercredi": 3,
    "mer": 3,
    "jeudi": 4,
    "jeu": 4,
    "vendredi": 5,
    "ven": 5,
    "samedi": 6,
    "sam": 6
]

let FR_MONTH_OFFSET = [
    "janvier": 1,
    "jan": 1,
    "jan.": 1,
    "février": 2,
    "fév": 2,
    "fév.": 2,
    "mars": 3,
    "mar": 3,
    "mar.": 3,
    "avril": 4,
    "avr": 4,
    "avr.": 4,
    "mai": 5,
    "juin": 6,
    "jun": 6,
    "juillet": 7,
    "juil": 7,
    "jul": 7,
    "jul.": 7,
    "août": 8,
    "aout": 8,
    "septembre": 9,
    "sep": 9,
    "sep.": 9,
    "sept": 9,
    "sept.": 9,
    "octobre": 10,
    "oct": 10,
    "oct.": 10,
    "novembre": 11,
    "nov": 11,
    "nov.": 11,
    "décembre": 12,
    "dec": 12,
    "dec.": 12
]

let FR_INTEGER_WORDS_PATTERN = "(?:un|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize)"
let FR_INTEGER_WORDS = [
    "un" : 1,
    "deux" : 2,
    "trois" : 3,
    "quatre" : 4,
    "cinq" : 5,
    "six" : 6,
    "sept" : 7,
    "huit" : 8,
    "neuf" : 9,
    "dix" : 10,
    "onze" : 11,
    "douze" : 12,
    "treize" : 13,
]
