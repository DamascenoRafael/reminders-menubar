//
//  FRMergeDateRangeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class FRMergeDateRangeRefiner: MergeDateRangeRefiner {
    override var PATTERN: String { return "^\\s*(à|a|\\-)\\s*$" }
    override var TAGS: TagUnit { return .frMergeDateRangeRefiner }
}
