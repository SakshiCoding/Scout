import SwiftUI

struct AvatarStack: View {
    let members: [CircleMember]
    let accentColor: Color
    var size: CGFloat = 24
    var borderColor: Color = Atlas.paper
    var borderWidth: CGFloat = 1.5
    var overlap: CGFloat = 9

    var body: some View {
        let shown = Array(members.prefix(3))
        HStack(spacing: -overlap) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, member in
                Text(member.initials)
                    .font(Atlas.Font.serif(size * 0.48))
                    .foregroundColor(Atlas.paper)
                    .frame(width: size, height: size)
                    .background(index == 0 ? accentColor : Atlas.ink)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
                    .zIndex(Double(shown.count - index))
            }
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        AvatarStack(members: ScoutCircle.mockMorgan.members,
                    accentColor: ScoutCircle.mockMorgan.accentSwiftUIColor)
        AvatarStack(members: ScoutCircle.mockFamily.members,
                    accentColor: ScoutCircle.mockFamily.accentSwiftUIColor,
                    size: 32, borderWidth: 2)
    }
    .padding()
    .background(Atlas.paper)
}
