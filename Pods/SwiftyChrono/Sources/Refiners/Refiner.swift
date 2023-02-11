//
//  Refiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class Refiner {
    public func refine(text: String, results: [ParsedResult], opt: [OptionType: Int]) -> [ParsedResult] {
        return results
    }
}

class Filter: Refiner {
    public func isValid(text: String, result: ParsedResult, opt: [OptionType: Int]) -> Bool {
        return true
    }
    
    public override func refine(text: String, results: [ParsedResult], opt: [OptionType: Int]) -> [ParsedResult] {
        var filteredResults = [ParsedResult]()
        
        for r in results {
            if isValid(text: text, result: r, opt: opt) {
                filteredResults.append(r)
            }
        }
        
        return filteredResults
    }
}
