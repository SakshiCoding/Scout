import SwiftUI
import UIKit

struct CrossPostSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    let media: Media
    let restaurant: Restaurant
    let visit: Visit

    @State private var selectedCircleId: UUID?
    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var activityItems: [Any] = []
    @State private var showActivitySheet = false
    @State private var didCopyLink = false

    private var otherCircles: [ScoutCircle] {
        appState.circles.filter { $0.id != appState.activeCircle?.id }
    }

    private var selectedCircle: ScoutCircle? {
        otherCircles.first { $0.id == selectedCircleId }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SHARE MEMORY")
                        .font(Atlas.Font.sans(11, weight: .medium))
                        .foregroundColor(Atlas.ink3)
                        .kerning(1.6)
                    Text("Pass it along.")
                        .font(Atlas.Font.serif(30))
                        .foregroundColor(Atlas.ink)
                }

                Spacer()
                CloseButton { isPresented = false }
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    previewCard

                    if !otherCircles.isEmpty {
                        circleSection
                    }

                    externalSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Atlas.Font.sans(12.5))
                            .foregroundColor(Atlas.burnt)
                    }

                    if let selectedCircle {
                        Button {
                            Task { await share(to: selectedCircle) }
                        } label: {
                            Group {
                                if isSharing {
                                    ProgressView().tint(Atlas.paper)
                                } else {
                                    Text("Share to \(selectedCircle.name)")
                                }
                            }
                            .font(Atlas.Font.sans(14.5, weight: .semibold))
                            .foregroundColor(Atlas.paper)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Atlas.ink)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isSharing)
                    }
                }
                .padding(.horizontal, Atlas.screenHPad)
                .padding(.bottom, 34)
            }
        }
        .background(Atlas.paper)
        .clipShape(RoundedRectangle(cornerRadius: Atlas.sheetTopRadius, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showActivitySheet) {
            ActivityShareSheet(items: activityItems)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            JournalMediaThumbnail(media: media, size: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(restaurant.name)
                    .font(Atlas.Font.serif(19))
                    .foregroundColor(Atlas.ink)
                    .lineLimit(1)

                Text(visit.visitedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(Atlas.Font.sans(11.5))
                    .foregroundColor(Atlas.ink3)

                if let circle = appState.activeCircle {
                    Text("FROM \(circle.displayShortName.uppercased())")
                        .font(Atlas.Font.sans(9.5, weight: .medium))
                        .foregroundColor(circle.accentSwiftUIColor)
                        .kerning(1.2)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var circleSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("ADD TO ANOTHER CIRCLE")

            VStack(spacing: 4) {
                ForEach(otherCircles) { circle in
                    Button {
                        selectedCircleId = selectedCircleId == circle.id ? nil : circle.id
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(circle.accentSwiftUIColor)
                                .frame(width: 8, height: 8)

                            Text(circle.name)
                                .font(Atlas.Font.serif(17))
                                .foregroundColor(Atlas.ink)

                            Spacer()

                            Image(systemName: selectedCircleId == circle.id ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 21))
                                .foregroundColor(selectedCircleId == circle.id ? circle.accentSwiftUIColor : Atlas.ink3)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(selectedCircleId == circle.id ? Atlas.paper2 : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var externalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("OR SEND SOMEWHERE ELSE")

            HStack(spacing: 10) {
                externalButton("Messages", systemName: "message") {
                    await shareExternally()
                }
                externalButton("Mail", systemName: "envelope") {
                    await shareExternally()
                }
                externalButton(didCopyLink ? "Copied" : "Copy link", systemName: "link") {
                    await copyLink()
                }
                externalButton("More", systemName: "ellipsis") {
                    await shareExternally()
                }
            }
        }
    }

    private func externalButton(
        _ label: String,
        systemName: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Atlas.ink)
                    .frame(width: 38, height: 38)
                    .background(Atlas.paper2)
                    .clipShape(Circle())

                Text(label)
                    .font(Atlas.Font.sans(10.5))
                    .foregroundColor(Atlas.ink2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isSharing)
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label)
            .font(Atlas.Font.sans(10.5, weight: .medium))
            .foregroundColor(Atlas.ink3)
            .kerning(1.4)
    }

    private func share(to circle: ScoutCircle) async {
        isSharing = true
        errorMessage = nil
        defer { isSharing = false }

        do {
            try await appState.crossPostMedia(media, visit: visit, restaurant: restaurant, to: circle)
            isPresented = false
        } catch {
            errorMessage = "Couldn't share this memory: \(error.localizedDescription)"
        }
    }

    private func shareExternally() async {
        isSharing = true
        errorMessage = nil
        defer { isSharing = false }

        do {
            let url = try await appState.mediaService.shareFile(for: media, supabase: appState.supabase)
            activityItems = [url, "\(restaurant.name) · \(visit.visitedAt.formatted(date: .abbreviated, time: .omitted))"]
            showActivitySheet = true
        } catch {
            errorMessage = "Couldn't prepare this memory for sharing: \(error.localizedDescription)"
        }
    }

    private func copyLink() async {
        isSharing = true
        errorMessage = nil
        defer { isSharing = false }

        do {
            let url = try await appState.supabase.signedMediaURL(path: media.storagePath)
            UIPasteboard.general.string = url.absoluteString
            didCopyLink = true
        } catch {
            errorMessage = "Couldn't create a share link: \(error.localizedDescription)"
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
