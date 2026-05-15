import SwiftUI

enum TabItem: String, CaseIterable {
    case list, map, pick, journal
}

struct CustomTabBar: View {
    @Binding var selected: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarButton(tab: tab, isActive: selected == tab) {
                    selected = tab
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: Atlas.tabBarHeight)
        .background(Atlas.paper)
        .clipShape(Capsule())
        .tabBarShadow()
        .padding(.horizontal, 16)
    }
}

private struct TabBarButton: View {
    let tab: TabItem
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                TabIcon(tab: tab, color: isActive ? Atlas.burnt : Atlas.ink3)
                    .frame(width: 22, height: 22)

                if isActive {
                    Circle()
                        .fill(Atlas.burnt)
                        .frame(width: 4, height: 4)
                        .padding(.top, 4)
                } else {
                    Spacer().frame(height: 8)
                }
            }
            .frame(width: 46, height: 44)
            .background(isActive ? Atlas.burnt.opacity(0.10) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selected: .constant(.list))
            .padding(.bottom, Atlas.tabBarBottomOffset)
    }
    .background(Atlas.paper)
}
