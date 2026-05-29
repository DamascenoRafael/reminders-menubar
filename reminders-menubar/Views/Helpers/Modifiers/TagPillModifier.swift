import SwiftUI

struct TagPillModifier: ViewModifier {
    enum Size {
        case compact
        case regular
    }

    let size: Size

    private var fontSize: CGFloat {
        switch size {
        case .compact:
            return 10
        case .regular:
            return 11
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .compact:
            return 5
        case .regular:
            return 6
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .compact:
            return 1
        case .regular:
            return 3
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .compact:
            return 4
        case .regular:
            return 6
        }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize))
            .foregroundColor(Color.rmbColor(.tagHighlight))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Color.rmbColor(.tagHighlight).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
