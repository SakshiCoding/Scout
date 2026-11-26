import SwiftUI

struct WishlistTogetherCard: View {
    let members: [CircleMember]
    let count: Int
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarStack(members: members, accentColor: Atlas.burnt, size: 26, borderColor: Atlas.paper2)
                    .accessibilityHidden(true)
                Text("YOUR CIRCLE").font(Atlas.Font.sans(10.5, weight: .medium))
                    .kerning(1.3).foregroundStyle(Atlas.ink2)
            }
            Text("Where shall we eat?")
                .font(Atlas.Font.serif(27)).foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(
                count == 0
                    ? "Save a place for your next meal together."
                    : members.count < 2
                        ? "Invite someone to find your next place together."
                        : "A shared shortlist. A place everyone says yes to."
            )
            .font(Atlas.Font.sans(12.5)).foregroundStyle(Atlas.ink2)
            .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                HStack {
                    Text(
                        count == 0
                            ? "Add a restaurant" : members.count < 2 ? "Invite your circle" : "Pick together")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(Atlas.Font.sans(13, weight: .semibold))
                .foregroundStyle(Atlas.paper)
                .padding(.horizontal, 18).frame(minHeight: 48)
                .background(Atlas.ink).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Atlas.paper2).clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
