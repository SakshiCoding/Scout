import SwiftUI

struct MatchView: View {
    let restaurant: Restaurant
    let circle: ScoutCircle
    var onConfirm: () -> Void
    var onPickAgain: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                closeRow
                Spacer()
                matchHeading
                restaurantCard
                    .padding(.top, 28)
                    .padding(.horizontal, Atlas.screenHPad)
                    .offset(y: appeared ? 0 : 36)
                    .opacity(appeared ? 1 : 0)
                Spacer()
                ctaStack
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.bottom, 52)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.12)) {
                appeared = true
            }
        }
    }

    // MARK: - Close Row

    private var closeRow: some View {
        HStack {
            Spacer()
            CloseButton { onDismiss() }
                .padding(.trailing, 20)
        }
        .padding(.top, 60)
    }

    // MARK: - Match Heading

    private var matchHeading: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(circle.accentSwiftUIColor)
                    .frame(width: 7, height: 7)
                Text("IT'S A MATCH")
                    .font(Atlas.Font.sans(10.5, weight: .semibold))
                    .foregroundColor(Atlas.ink3)
                    .kerning(2)
            }

            (Text("You're going to ")
                .font(Atlas.Font.serif(32))
                .foregroundColor(Atlas.ink)
            + Text(restaurant.name)
                .font(Atlas.Font.serif(32, italic: true))
                .foregroundColor(Atlas.burnt)
            + Text(".")
                .font(Atlas.Font.serif(32))
                .foregroundColor(Atlas.ink))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Atlas.screenHPad)
                .padding(.top, 4)

            memberAvatars
                .padding(.top, 8)
        }
        .scaleEffect(appeared ? 1.0 : 0.88)
        .opacity(appeared ? 1 : 0)
    }

    private var memberAvatars: some View {
        HStack(spacing: -8) {
            ForEach(Array(circle.members.prefix(3).enumerated()), id: \.offset) { idx, member in
                ZStack {
                    Circle()
                        .fill(idx == 0 ? circle.accentSwiftUIColor : Atlas.ink)
                        .frame(width: 32, height: 32)
                    Text(member.initials)
                        .font(Atlas.Font.serif(13))
                        .foregroundColor(Atlas.paper)
                }
                .overlay(Circle().stroke(Atlas.paper, lineWidth: 2))
                .zIndex(Double(3 - idx))
            }
        }
    }

    // MARK: - Restaurant Card

    private var restaurantCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Atlas.paper2)
                    .frame(width: 72, height: 72)
                Text(String(restaurant.name.prefix(1)))
                    .font(Atlas.Font.serif(32))
                    .foregroundColor(Atlas.ink.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(Atlas.Font.serif(20))
                    .foregroundColor(Atlas.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    if let c = restaurant.cuisine {
                        Text(c)
                    }
                    if let p = restaurant.priceTier {
                        Text("·").foregroundColor(Atlas.ink3)
                        Text(p.rawValue)
                    }
                    if let d = restaurant.formattedDistance {
                        Text("·").foregroundColor(Atlas.ink3)
                        Text("\(d) mi")
                    }
                }
                .font(Atlas.Font.sans(12.5))
                .foregroundColor(Atlas.ink2)
                .lineLimit(1)

                if !restaurant.vibeTags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(restaurant.vibeTags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(Atlas.Font.sans(10.5))
                                .foregroundColor(Atlas.ink3)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Atlas.paper)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "heart.fill")
                .font(.system(size: 18))
                .foregroundColor(Atlas.burnt)
        }
        .padding(18)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .cardShadow()
    }

    // MARK: - CTA Stack

    private var ctaStack: some View {
        VStack(spacing: 12) {
            Button { onConfirm() } label: {
                Text("Great, let's go!")
                    .font(Atlas.Font.sans(14.5, weight: .semibold))
                    .foregroundColor(Atlas.paper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Atlas.ink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button { onPickAgain() } label: {
                Text("Pick again")
                    .font(Atlas.Font.sans(14, weight: .medium))
                    .foregroundColor(Atlas.ink2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MatchView(
        restaurant: Restaurant.mockList[0],
        circle: .mockMorgan,
        onConfirm: {},
        onPickAgain: {}
    )
}
