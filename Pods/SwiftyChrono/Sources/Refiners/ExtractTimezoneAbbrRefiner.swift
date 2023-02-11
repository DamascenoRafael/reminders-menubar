//
//  ExtractTimezoneAbbrRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/24/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "^\\s*\\(?([A-Z]{2,4})\\)?(?=\\W|$)"

class ExtractTimezoneAbbrRefiner: Refiner {
    override public func refine(text: String, results: [ParsedResult], opt: [OptionType: Int]) -> [ParsedResult] {
        let resultsLength = results.count
        let availableTagUnits: Set<TagUnit> = [.enTimeExpressionParser, .frTimeExpressionParser, .zhHantTimeExpressionParser]
        var newResults = [ParsedResult]()
        
        var i = 0
        while i < resultsLength {
            var result = results[i]
            let keys = Set(result.tags.keys)
            
            if keys.intersection(availableTagUnits).isEmpty {
                i += 1
                newResults.append(result)
                continue
            }
            
            let substring = text.substring(from: result.index + result.text.count)
            
            if
                let regex = (try? NSRegularExpression(pattern: PATTERN, options: .caseInsensitive)),
                let match = regex.firstMatch(in: substring, range: NSRange(location: 0, length: substring.count))
            {
                let timezoneAbbr = (match.isNotEmpty(atRangeIndex: 1) ? match.string(from: substring, atRangeIndex: 1) : "").uppercased()
                guard let timezoneOffset = timezoneAbbrs[timezoneAbbr] else {
                    i += 1
                    newResults.append(result)
                    continue
                }
                
                if !result.start.isCertain(component: .timeZoneOffset) {
                    result.start.assign(.timeZoneOffset, value: timezoneOffset)
                }
                
                if let end = result.end, end.isCertain(component: .timeZoneOffset) {
                    result.end!.assign(.timeZoneOffset, value: timezoneOffset)
                }
                
                result.text += match.string(from: substring, atRangeIndex: 0)
                result.tags[.extractTimezoneAbbrRefiner] = true
            }
            
            i += 1
            newResults.append(result)
        }
        
        return newResults
    }
}

// TODO: Move this to some configuration
private let timezoneAbbrs = ["ACDT":630,"ACST":570,"ADT":-180,"AEDT":660,"AEST":600,"AFT":270,"AKDT":-480,"AKST":-540,"ALMT":360,"AMST":-180,"AMT":-240,"ANAST":720,"ANAT":720,"AQTT":300,"ART":-180,"AST":-240,"AWDT":540,"AWST":480,"AZOST":0,"AZOT":-60,"AZST":300,"AZT":240,"BNT":480,"BOT":-240,"BRST":-120,"BRT":-180,"BST":60,"BTT":360,"CAST":480,"CAT":120,"CCT":390,"CDT":-300,"CEST":120,"CET":60,"CHADT":825,"CHAST":765,"CKT":-600,"CLST":-180,"CLT":-240,"COT":-300,"CST":-360,"CVT":-60,"CXT":420,"ChST":600,"DAVT":420,"EASST":-300,"EAST":-360,"EAT":180,"ECT":-300,"EDT":-240,"EEST":180,"EET":120,"EGST":0,"EGT":-60,"EST":-300,"ET":-300,"FJST":780,"FJT":720,"FKST":-180,"FKT":-240,"FNT":-120,"GALT":-360,"GAMT":-540,"GET":240,"GFT":-180,"GILT":720,"GMT":0,"GST":240,"GYT":-240,"HAA":-180,"HAC":-300,"HADT":-540,"HAE":-240,"HAP":-420,"HAR":-360,"HAST":-600,"HAT":-90,"HAY":-480,"HKT":480,"HLV":-210,"HNA":-240,"HNC":-360,"HNE":-300,"HNP":-480,"HNR":-420,"HNT":-150,"HNY":-540,"HOVT":420,"ICT":420,"IDT":180,"IOT":360,"IRDT":270,"IRKST":540,"IRKT":540,"IRST":210,"IST":60,"JST":540,"KGT":360,"KRAST":480,"KRAT":480,"KST":540,"KUYT":240,"LHDT":660,"LHST":630,"LINT":840,"MAGST":720,"MAGT":720,"MART":-510,"MAWT":300,"MDT":-360,"MESZ":120,"MEZ":60,"MHT":720,"MMT":390,"MSD":240,"MSK":240,"MST":-420,"MUT":240,"MVT":300,"MYT":480,"NCT":660,"NDT":-90,"NFT":690,"NOVST":420,"NOVT":360,"NPT":345,"NST":-150,"NUT":-660,"NZDT":780,"NZST":720,"OMSST":420,"OMST":420,"PDT":-420,"PET":-300,"PETST":720,"PETT":720,"PGT":600,"PHOT":780,"PHT":480,"PKT":300,"PMDT":-120,"PMST":-180,"PONT":660,"PST":-480,"PT":-480,"PWT":540,"PYST":-180,"PYT":-240,"RET":240,"SAMT":240,"SAST":120,"SBT":660,"SCT":240,"SGT":480,"SRT":-180,"SST":-660,"TAHT":-600,"TFT":300,"TJT":300,"TKT":780,"TLT":540,"TMT":300,"TVT":720,"ULAT":480,"UTC":0,"UYST":-120,"UYT":-180,"UZT":300,"VET":-210,"VLAST":660,"VLAT":660,"VUT":660,"WAST":120,"WAT":60,"WEST":60,"WESZ":60,"WET":0,"WEZ":0,"WFT":720,"WGST":-120,"WGT":-180,"WIB":420,"WIT":540,"WITA":480,"WST":780,"WT":0,"YAKST":600,"YAKT":600,"YAPT":600,"YEKST":360,"YEKT":360]











