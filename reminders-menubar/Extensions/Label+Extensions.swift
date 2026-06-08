import SwiftUI

extension Label where Title == Text, Icon == Image {
    init(_ title: String, rmbSymbol: RmbSymbol) {
        self.init(title, systemImage: rmbSymbol.name)
    }
}
