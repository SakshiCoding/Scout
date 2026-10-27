import SwiftUI

struct RestaurantHoursCard: View {
    let details: PlaceContactDetails?
    let isLoading: Bool
    let failed: Bool
    let canLoad: Bool
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("OPENING HOURS")
                    .font(Atlas.Font.sans(10.5, weight: .semibold))
                    .kerning(1.6)
                    .foregroundStyle(Atlas.ink2)
                Spacer()
                if canLoad {
                    Button(failed ? "Retry" : "Refresh", action: refresh)
                        .font(Atlas.Font.sans(13, weight: .semibold))
                        .foregroundStyle(Atlas.burnt)
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .accessibilityLabel(failed ? "Retry opening hours" : "Refresh opening hours")
                }
            }
            if isLoading {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(Atlas.burnt)
                        .accessibilityHidden(true)
                    Text("Checking hours…")
                        .foregroundStyle(Atlas.ink2)
                }
                .font(Atlas.Font.sans(13))
                .accessibilityElement(children: .combine)
            } else if let details {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Circle().fill(statusColor(details.openStatus)).frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(details.openStatus.label)
                        .font(Atlas.Font.sans(14, weight: .medium))
                        .foregroundStyle(Atlas.ink)
                }
                Text("Checked \(details.checkedAt.formatted(.dateTime.month().day().hour().minute()))")
                    .font(Atlas.Font.sans(11))
                    .foregroundStyle(Atlas.ink2)
                if details.openStatus == .permanentlyClosed {
                    message("This place is reported permanently closed.")
                } else if details.weekdayText.isEmpty {
                    message("Weekly hours aren’t available for this place.")
                } else {
                    Text("REGULAR WEEKLY HOURS")
                        .font(Atlas.Font.sans(10.5, weight: .medium))
                        .foregroundStyle(Atlas.ink3)
                    ForEach(Array(details.weekdayText.enumerated()), id: \.offset) { _, text in
                        Text(text)
                            .font(Atlas.Font.sans(13))
                            .foregroundStyle(Atlas.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    message("Times are local to the restaurant. Hours may vary on holidays.")
                }
                Divider().overlay(Atlas.rule)
                Text("Google Maps")
                    .font(Atlas.Font.sans(14))
                    .foregroundStyle(Color(red: 94/255, green: 94/255, blue: 94/255))
                    .lineLimit(1)
                if let attribution = details.providerAttribution {
                    Text(attribution)
                        .font(Atlas.Font.sans(12))
                        .tint(Atlas.burnt)
                }
            } else {
                message(failed ? "Couldn’t load opening hours. Please try again later."
                        : "Opening hours aren’t available for this place.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func message(_ text: String) -> some View {
        Text(text).font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func statusColor(_ status: PlaceContactDetails.OpenStatus) -> Color {
        switch status {
        case .open: return Atlas.statusOpen
        case .temporarilyClosed, .permanentlyClosed: return Atlas.burnt
        case .closed, .unknown: return Atlas.ink3
        }
    }
}
