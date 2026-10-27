import SwiftUI

/// Decorative brand mark; the adjacent Scout heading provides its accessible name.
struct ScoutBrandMark: View {
    var size: CGFloat = 72

    var body: some View {
        Image("ScoutCompass")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Atlas.burnt)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
