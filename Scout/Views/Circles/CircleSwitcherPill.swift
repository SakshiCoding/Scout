import SwiftUI

struct CircleSwitcherPill: View {
    let circle: ScoutCircle
    var glassStyle: Bool = false
    var onTap: () -> Void = {}
    var onOverflow: (() -> Void)?

    private var bg: Color {
        glassStyle ? Atlas.paper.opacity(0.85) : Atlas.paper
    }

    var body: some View {
        HStack(spacing: 0) {
            // Tappable pill
            Button(action: onTap) {
                HStack(spacing: 10) {
                    AvatarStack(
                        members: circle.members,
                        accentColor: circle.accentSwiftUIColor,
                        size: 24,
                        borderColor: glassStyle ? Atlas.paper.opacity(0.9) : Atlas.paper
                    )
                    Text(circle.name)
                        .font(Atlas.Font.serif(15))
                        .foregroundColor(Atlas.ink)
                        .lineLimit(1)
                    ChevronDown(color: Atlas.ink2)
                }
                .padding(.leading, 6)
                .padding(.trailing, 14)
                .frame(height: Atlas.pillHeight)
                .background(
                    glassStyle
                        ? AnyView(bg.background(.ultraThinMaterial).clipShape(Capsule()))
                        : AnyView(bg.clipShape(Capsule()))
                )
                .clipShape(Capsule())
                .pillShadow(glass: glassStyle)
            }
            .buttonStyle(.plain)

            Spacer()

            // Overflow ··· button
            Button(action: { onOverflow?() }) {
                ThreeDotsIcon(color: Atlas.ink)
                    .frame(width: 36, height: 36)
                    .background(
                        glassStyle
                            ? AnyView(bg.background(.ultraThinMaterial).clipShape(Circle()))
                            : AnyView(bg.clipShape(Circle()))
                    )
                    .clipShape(Circle())
                    .pillShadow(glass: glassStyle)
            }
            .buttonStyle(.plain)
            .opacity(onOverflow != nil ? 1 : 0)
        }
        .padding(.horizontal, 16)
    }
}

// Thin accent rule + kicker label below the pill on Wishlist/Journal
struct CircleAccentRule: View {
    let circle: ScoutCircle
    var label: String?

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 99)
                .fill(circle.accentSwiftUIColor)
                .frame(width: 18, height: 2)
            Text((label ?? "\(circle.displayShortName.uppercased())'S ATLAS"))
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CircleSwitcherPill(circle: .mockMorgan, onTap: {}, onOverflow: {})
        CircleSwitcherPill(circle: .mockFamily, glassStyle: true, onTap: {}, onOverflow: {})
    }
    .padding()
    .background(Atlas.paper)
}
