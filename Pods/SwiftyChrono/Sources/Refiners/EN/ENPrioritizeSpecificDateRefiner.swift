//
//  ENPrioritizeSpecificDateRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/23/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "^\\s*(at|after|before|on|,|-|\\(|\\))?\\s*$"

private func isMoreSpecific(previousResult: ParsedResult, currentResult: ParsedResult) -> Bool {
    var moreSpecific = false
    
    if previousResult.start.isCertain(component: .year) {
        if !currentResult.start.isCertain(component: .year) {
            moreSpecific = true
        } else {
            if previousResult.start.isCertain(component: .month) {
                if !currentResult.start.isCertain(component: .month) {
                    moreSpecific = true
                } else {
                    if previousResult.start.isCertain(component: .day) && !currentResult.start.isCertain(component: .day) {
                        moreSpecific = true
                    }
                }
            }
        }
    }
    
    return moreSpecific
}

private func isAbleToMerge(text: String, previousResult: ParsedResult, currentResult: ParsedResult) -> Bool {
    let (startIndex, endIndex) = sortTwoNumbers(previousResult.index + previousResult.text.count, currentResult.index)
    let textBetween = text.substring(from: startIndex, to: endIndex)
    
    // Only accepts merge if one of them comes from casual relative date
    let includesRelativeResult = previousResult.tags[.enRelativeDateFormatParser] ?? false || currentResult.tags[.enRelativeDateFormatParser] ?? false
    
    // We assume they refer to the same date if all date fields are implied
    var referToSameDate = !previousResult.start.isCertain(component: .day) && !previousResult.start.isCertain(component: .month) && !previousResult.start.isCertain(component: .year)
    
    // If both years are certain, that determines if they refer to the same date
    // but with one more specific than the other
    if previousResult.start.isCertain(component: .year) && currentResult.start.isCertain(component: .year) {
        referToSameDate = previousResult.start[.year]! == currentResult.start[.year]
    }
    
    // We now test with the next level (month) if they refer to the same date
    if previousResult.start.isCertain(component: .month) && currentResult.start.isCertain(component: .month) {
        referToSameDate = previousResult.start[.month]! == currentResult.start[.month] && referToSameDate
    }
    
    return includesRelativeResult && NSRegularExpression.isMatch(forPattern: PATTERN, in: textBetween) && referToSameDate
}

func mergeResult(text: String, specificResult: ParsedResult, nonSpecificResult: ParsedResult) -> ParsedResult {
    var specificResult = specificResult

    let startIndex = min(specificResult.index, nonSpecificResult.index)
    let endIndex = max(
        specificResult.index + specificResult.text.count,
        nonSpecificResult.index + nonSpecificResult.text.count)
    
    specificResult.index = startIndex
    specificResult.text = text.substring(from: startIndex, to: endIndex)
    
    for tag in nonSpecificResult.tags.keys {
        specificResult.tags[tag] = true
    }
    
    specificResult.tags[.enPrioritizeSpecificDateRefiner] = true
    return specificResult
}

class ENPrioritizeSpecificDateRefiner: Refiner {
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
            
            if isMoreSpecific(previousResult: previousResult, currentResult: currentResult!) &&
                isAbleToMerge(text: text, previousResult: previousResult, currentResult: currentResult!) {
                
                results[i] = mergeResult(text: text, specificResult: previousResult, nonSpecificResult: currentResult!)
                currentResult = results[i]
                
                i += 1
                continue
            } else if isMoreSpecific(previousResult: currentResult!, currentResult: previousResult) &&
                isAbleToMerge(text: text, previousResult: previousResult, currentResult: currentResult!) {
                
                results[i] = mergeResult(text: text, specificResult: currentResult!, nonSpecificResult: previousResult)
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
}












