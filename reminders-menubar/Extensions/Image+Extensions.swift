import SwiftUI

extension Image {
    init(rmbSymbol: RmbSymbol) {
        self.init(systemName: rmbSymbol.name)
    }
}
