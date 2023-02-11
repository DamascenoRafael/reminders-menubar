//
//  MergeDataRangeRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/16/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

class MergeDateRangeRefiner: Refiner {
    var PATTERN: String { return "" }
    var TAGS: TagUnit { return .none }
    
    override public func refine(text: String, results: [ParsedResult], opt: [OptionType: Int]) -> [ParsedResult] {
        var results = results
        let resultsLength = results.count
        if resultsLength < 2 { return results }
        
        var mergedResults = [ParsedResult]()
        var currentResult: ParsedResult?
        var previousResult: ParsedResult
        
        var i = 1
        while i < resultsLength {
            currentResult = results[i]
            previousResult = results[i-1]
            
            if previousResult.end == nil && currentResult!.end == nil &&
                isAbleToMerge(text: text, result1: previousResult, result2: currentResult!) {
                
                results[i] = mergeResult(refText: text, fromResult: previousResult, toResult: currentResult!)
                currentResult = results[i]
                
                i += 1
                continue
            }
            
            mergedResults.append(previousResult)
            i += 1
        }
        
        if let currentResult = currentResult {
            mergedResults.append(currentResult)
        }
        
        return mergedResults
    }
    
    private func isAbleToMerge(text: String, result1: ParsedResult, result2: ParsedResult) -> Bool {
        let (startIndex, endIndex) = sortTwoNumbers(result1.index + result1.text.count, result2.index)
        let textBetween = text.substring(from: startIndex, to: endIndex)
        
        return NSRegularExpression.isMatch(forPattern: PATTERN, in: textBetween)
    }
    
    private func isWeekdayResult(result: ParsedResult) -> Bool {
        return result.start.isCertain(component: .weekday) && !result.start.isCertain(component: .day)
    }
    
    private func mergeResult(refText text: String, fromResult: ParsedResult, toResult: ParsedResult) -> ParsedResult {
        var fromResult = fromResult
        var toResult = toResult
        
        if !isWeekdayResult(result: fromResult) && !isWeekdayResult(result: toResult) {
            for key in toResult.start.knownValues {
                if !fromResult.start.isCertain(component: key.key) {
                    fromResult.start.assign(key.key, value: key.value)
                }
            }
            
            for key in fromResult.start.knownValues {
                if !toResult.start.isCertain(component: key.key) {
                    toResult.start.assign(key.key, value: key.value)
                }
            }
        }
        
        if fromResult.start.date.timeIntervalSince1970 > toResult.start.date.timeIntervalSince1970 {
            let tmp = toResult
            toResult = fromResult
            fromResult = tmp
        }
        
        fromResult.end = toResult.start
        
        for tag in toResult.tags.keys {
            fromResult.tags[tag] = true
        }
        
        let startIndex = min(fromResult.index, toResult.index)
        let endIndex = max(
            fromResult.index + fromResult.text.count,
            toResult.index + toResult.text.count)
        
        fromResult.index = startIndex
        fromResult.text = text.substring(from: startIndex, to: endIndex)
        fromResult.tags[TAGS] = true
        
        return fromResult
    }
}












