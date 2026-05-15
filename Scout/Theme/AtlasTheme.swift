import SwiftUI

enum Atlas {
    // MARK: - Colors
    static let paper  = Color(hex: "#F7F1E6")
    static let paper2 = Color(hex: "#EFE6D4")
    static let ink    = Color(hex: "#1B1612")
    static let ink2   = Color(hex: "#1B1612").opacity(0.62)
    static let ink3   = Color(hex: "#1B1612").opacity(0.42)
    static let rule   = Color(hex: "#1B1612").opacity(0.10)
    static let burnt  = Color(hex: "#CC5500")
    static let orange = Color(hex: "#E5651C")
    static let statusOpen       = Color(hex: "#1E7A3A")
    static let statusClosesSoon = Color(hex: "#CC5500")

    // MARK: - Circle accent presets
    static let accentBurnt = Color(hex: "#CC5500")
    static let accentSage  = Color(hex: "#7A8B3C")
    static let accentSlate = Color(hex: "#3D5A80")

    // MARK: - Layout
    static let tabBarHeight: CGFloat       = 60
    static let tabBarBottomOffset: CGFloat = 22
    static let tabBarRadius: CGFloat       = 30
    static let pillHeight: CGFloat         = 36
    static let screenHPad: CGFloat         = 24
    static let listBottomPad: CGFloat      = 110   // clears floating tab bar
    static let sheetTopRadius: CGFloat     = 24

    // MARK: - Typography
    enum Font {
        static func serif(_ size: CGFloat, italic: Bool = false) -> SwiftUI.Font {
            italic
                ? .custom("DMSerifDisplay-Italic", size: size)
                : .custom("DMSerifDisplay-Regular", size: size)
        }

        static func sans(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            switch weight {
            case .medium:     return .custom("DMSans-Medium",     size: size)
            case .semibold:   return .custom("DMSans-SemiBold",   size: size)
            case .bold:       return .custom("DMSans-Bold",       size: size)
            default:          return .custom("DMSans-Regular",    size: size)
            }
        }
    }
}

// MARK: - Color hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shadow modifiers
extension View {
    func tabBarShadow() -> some View {
        self
            .shadow(
                color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.18),
                radius: 15, x: 0, y: 10
            )
            .overlay(Capsule().stroke(Atlas.ink.opacity(0.08), lineWidth: 1))
    }

    func cardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1
        )
        .shadow(
            color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4
        )
    }

    func pillShadow(glass: Bool = false) -> some View {
        self.shadow(
            color: Color(red: 50/255, green: 30/255, blue: 10/255)
                .opacity(glass ? 0.15 : 0.06),
            radius: glass ? 6 : 4, x: 0, y: glass ? 4 : 2
        )
        .overlay(Capsule().stroke(Atlas.ink.opacity(0.06), lineWidth: 1))
    }

    func sheetShadow() -> some View {
        self.shadow(
            color: Color(red: 15/255, green: 10/255, blue: 5/255).opacity(0.25),
            radius: 15, x: 0, y: -8
        )
    }
}
