import SwiftUI

struct CirclePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var showNewCircle = false

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SWITCH CIRCLE")
                        .font(Atlas.Font.sans(11, weight: .medium))
                        .foregroundColor(Atlas.ink3)
                        .kerning(1.6)
                    Text("Whose atlas?")
                        .font(Atlas.Font.serif(30))
                        .foregroundColor(Atlas.ink)
                }
                Spacer()
                CloseButton { isPresented = false }
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.bottom, 18)

            // Circles
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(appState.circles) { circle in
                        CirclePickerRow(
                            circle: circle,
                            isActive: circle.id == appState.activeCircle?.id
                        ) {
                            appState.switchCircle(to: circle)
                            isPresented = false
                        }
                    }

                    NewCircleRow { showNewCircle = true }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 36)
            }
        }
        .background(Atlas.paper)
        .clipShape(RoundedRectangle(cornerRadius: Atlas.sheetTopRadius, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showNewCircle) {
            NewCircleSheet(isPresented: $showNewCircle)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
    }
}

// MARK: - Circle row

private struct CirclePickerRow: View {
    let circle: ScoutCircle
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Left accent stripe
                RoundedRectangle(cornerRadius: 99)
                    .fill(circle.accentSwiftUIColor.opacity(isActive ? 1 : 0.4))
                    .frame(width: 3)
                    .padding(.vertical, 6)

                AvatarStack(
                    members: circle.members,
                    accentColor: circle.accentSwiftUIColor,
                    size: 32,
                    borderColor: isActive ? Atlas.paper2 : Atlas.paper,
                    borderWidth: 2,
                    overlap: 12
                )
                .padding(.leading, 8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(circle.name)
                            .font(Atlas.Font.serif(19))
                            .foregroundColor(Atlas.ink)
                        Circle()
                            .fill(circle.accentSwiftUIColor)
                            .frame(width: 5, height: 5)
                    }
                    HStack(spacing: 0) {
                        Group {
                            Text("\(circle.restaurantCount)")
                                .font(Atlas.Font.serif(13))
                                .foregroundColor(Atlas.ink2)
                            Text(" places · ")
                            Text("\(circle.visitedCount)")
                                .font(Atlas.Font.serif(13))
                                .foregroundColor(Atlas.ink2)
                            Text(" visited · ")
                            Text("\(circle.photoCount)")
                                .font(Atlas.Font.serif(13))
                                .foregroundColor(Atlas.ink2)
                            Text(" photos")
                        }
                        .font(Atlas.Font.sans(11.5))
                        .foregroundColor(Atlas.ink3)
                        .kerning(0.3)
                    }
                }

                Spacer()

                if isActive {
                    Circle()
                        .fill(circle.accentSwiftUIColor)
                        .frame(width: 24, height: 24)
                        .overlay(CheckmarkIcon())
                } else {
                    ChevronRight()
                }
            }
            .padding(14)
            .background(isActive ? Atlas.paper2 : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - New circle row

private struct NewCircleRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text("+")
                    .font(Atlas.Font.serif(22))
                    .foregroundColor(Atlas.burnt)
                    .frame(width: 36, height: 36)
                    .background(Atlas.paper2)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Start a new circle")
                        .font(Atlas.Font.serif(17))
                        .foregroundColor(Atlas.ink)
                    Text("Coworkers, a travel group, a city crew…")
                        .font(Atlas.Font.sans(11.5))
                        .foregroundColor(Atlas.ink3)
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundColor(Atlas.rule)
            )
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Color.black.opacity(0.55)
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            CirclePickerSheet(isPresented: .constant(true))
        }
        .environment(AppState.preview)
}
