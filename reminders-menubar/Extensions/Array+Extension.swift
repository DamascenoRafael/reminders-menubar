import Foundation

extension Array {
    func separeted(by condition: (Element) -> Bool) -> (matching: [Element], notMatching: [Element]) {
        var elements = self
        let partition = elements.partition(by: { condition($0) })
        let matching = Array(elements[partition...])
        let notMatching = Array(elements[..<partition])
        return(matching, notMatching)
    }
}
