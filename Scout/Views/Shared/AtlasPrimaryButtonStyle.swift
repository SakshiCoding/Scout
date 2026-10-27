import SwiftUI

struct AtlasPrimaryButtonStyle: ButtonStyle {
    var fill: Color = Atlas.burnt
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Atlas.Font.sans(14.5, weight: .semibold))
            .foregroundStyle(Atlas.paper)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fill, in: Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
    }
}
