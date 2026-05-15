import SwiftUI

struct StatusDot: View {
    enum Status { case open, closesSoon, opensLater }

    let status: Status

    var dotColor: Color {
        switch status {
        case .open:       return Atlas.statusOpen
        case .closesSoon: return Atlas.burnt
        case .opensLater: return Atlas.ink3
        }
    }

    var label: String {
        switch status {
        case .open:       return "Open"
        case .closesSoon: return "Closes soon"
        case .opensLater: return "Opens later"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(Atlas.Font.sans(11))
                .foregroundColor(Atlas.ink2)
                .kerning(0.2)
        }
    }
}

// Vibe tag inline label
struct VibeTagLabel: View {
    let tag: String
    var body: some View {
        Text("· \(tag)")
            .font(Atlas.Font.sans(10.5))
            .foregroundColor(Atlas.ink3)
            .kerning(0.3)
            .textCase(.lowercase)
    }
}

// Filter chip — used in both the inline row and filter sheet
struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Atlas.Font.sans(11.5, weight: .medium))
                .kerning(0.2)
                .foregroundColor(isActive ? Atlas.paper : Atlas.ink2)
                .padding(.horizontal, 11)
                .frame(height: 26)
                .background(isActive ? Atlas.ink : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isActive ? Atlas.ink : Atlas.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            StatusDot(status: .open)
            StatusDot(status: .closesSoon)
            StatusDot(status: .opensLater)
        }
        HStack(spacing: 6) {
            FilterChip(label: "All",   isActive: true,  action: {})
            FilterChip(label: "Patio", isActive: false, action: {})
            FilterChip(label: "$$",    isActive: false, action: {})
        }
    }
    .padding()
    .background(Atlas.paper)
}
