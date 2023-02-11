//
//  JPMergeDateRangeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class JPMergeDateRangeRefiner: ENMergeDateRangeRefiner {
    override var PATTERN: String { return "^\\s*(から|ー)\\s*$" }
}
