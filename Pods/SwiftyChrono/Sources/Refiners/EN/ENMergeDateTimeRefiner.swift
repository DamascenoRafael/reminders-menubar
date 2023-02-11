//
//  ENMergeDateTimeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/19/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class ENMergeDateTimeRefiner: MergeDateTimeRefiner {
    override var PATTERN: String { return "^\\s*(T|at|after|before|on|of|,|-)?\\s*$" }
    override var TAGS: TagUnit { return .enMergeDateAndTimeRefiner }
}












