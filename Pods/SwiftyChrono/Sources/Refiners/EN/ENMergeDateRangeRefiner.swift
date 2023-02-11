//
//  ENMergeDateRangeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/20/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class ENMergeDateRangeRefiner: MergeDateRangeRefiner {
    override var PATTERN: String { return "^\\s*(to|\\-)\\s*$" }
    override var TAGS: TagUnit { return .enMergeDateRangeRefiner }
}












