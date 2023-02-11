//
//  DEMergeDateTimeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/17/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class DEMergeDateTimeRefiner: MergeDateTimeRefiner {
    override var PATTERN: String { return "^\\s*(T|vor|nach|um|,|-)?\\s*$" }
    override var TAGS: TagUnit { return .deMergeDateAndTimeRefiner }
}
