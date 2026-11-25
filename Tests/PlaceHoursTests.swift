import AppKit
import CoreText
import Foundation
import SwiftUI

@MainActor private final class DeferredDetails {
    var ids: [String] = []
    var requests: [CheckedContinuation<PlaceContactDetails?, Never>] = []
    func fetch(_ id: String) async -> PlaceContactDetails? {
        ids.append(id)
        return await withCheckedContinuation { requests.append($0) }
    }
    func finish(_ index: Int, _ details: PlaceContactDetails?) { requests[index].resume(returning: details) }
}

@main private struct PlaceHoursTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10_000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Deferred detail request did not reach expected state")
    }
    @MainActor static func main() async throws {
        let now = Date(timeIntervalSince1970: 1_793_000_000)
        let lines = ["Sunday: Closed", "Monday: 11:00 AM–2:00 PM, 5:00 PM–10:00 PM",
                     "Tuesday: 11:00 AM–2:00 AM", "Wednesday: Open 24 hours", "Thursday: Closed",
                     "Friday: 5:00 PM–2:00 AM", "Saturday: 5:00 PM–2:00 AM"]
        var attribution = AttributedString("Listings by Example Provider")
        attribution.link = URL(string: "https://example.com/provider")!
        let fixture = PlaceContactDetails(websiteURL: URL(string: "https://example.com"),
            phoneNumber: "+1 555 0100", weekdayText: lines + ["", "  "], openStatus: .open,
            checkedAt: now, providerAttribution: attribution)
        precondition(fixture.weekdayText == lines && fixture.hasDirectContact)
        precondition(fixture.checkedAt == now && fixture.providerAttribution?.link == attribution.link)
        let localized = ["月曜日: 11時00分～14時00分、17時00分～翌日2時00分", "الأحد: مغلق"]
        precondition(PlaceContactDetails(weekdayText: localized).weekdayText == localized)
        precondition(!PlaceContactDetails(phoneNumber: "  ").hasDirectContact)
        precondition(PlaceContactDetails(phoneNumber: "123").hasDirectContact)
        precondition(PlaceContactDetails().openStatus == .unknown)
        precondition(PlaceContactDetails.OpenStatus.open.label == "Open at last check")
        precondition(PlaceContactDetails.OpenStatus.closed.label == "Closed at last check")
        precondition(PlaceContactDetails.OpenStatus.temporarilyClosed.label == "Temporarily closed")
        precondition(PlaceContactDetails.OpenStatus.permanentlyClosed.label == "Permanently closed")
        print("PASS localized source order/text, split/overnight/24-hour rows, blank filtering, neutral defaults, checked status, contacts and attribution links")

        let state = PlaceDetailsLoadState()
        await state.load(placeId: nil) { _ in preconditionFailure("Manual place fetched") }
        await state.load(placeId: "  ") { _ in preconditionFailure("Empty ID fetched") }
        precondition(state.details == nil && !state.isLoading && !state.failed)
        let deferred = DeferredDetails()
        let old = Task { await state.load(placeId: "old") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 1 }
        precondition(state.isLoading && state.details == nil)
        let latest = Task { await state.load(placeId: "new") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 2 }
        deferred.finish(0, fixture)
        await old.value
        precondition(state.isLoading && state.details == nil)
        deferred.finish(1, nil)
        await latest.value
        precondition(state.failed && !state.isLoading && state.details == nil)
        await state.load(placeId: "new") { _ in fixture }
        precondition(!state.failed && !state.isLoading && state.details?.weekdayText == lines)

        let revoked = Task { await state.load(placeId: "new") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 3 }
        await state.load(placeId: nil) { _ in preconditionFailure("Inactive/auth-cleared scope fetched") }
        deferred.finish(2, fixture)
        await revoked.value
        precondition(state.details == nil && !state.failed && !state.isLoading)
        let cancelled = Task { await state.load(placeId: "cancel") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 4 }
        cancelled.cancel()
        deferred.finish(3, fixture)
        await cancelled.value
        precondition(state.details == nil && !state.failed && !state.isLoading)
        precondition(deferred.ids == ["old", "new", "new", "cancel"])
        print("PASS production load state: manual fallback, loading, overlapping requests, failure/retry, scope invalidation, canceled late responses")

        for font in ["DMSans-Regular.ttf", "DMSans-Medium.ttf", "DMSans-SemiBold.ttf", "DMSerifDisplay-Regular.ttf"] {
            CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: font) as CFURL, .process, nil)
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let cases: [(String, PlaceContactDetails?, Bool, Bool, Bool)] = [
            ("ready", fixture, false, false, true),
            ("loading", nil, true, false, true),
            ("failed", nil, false, true, true),
            ("manual", nil, false, false, false),
            ("unknown", PlaceContactDetails(checkedAt: now), false, false, true),
            ("closed", PlaceContactDetails(weekdayText: localized, openStatus: .temporarilyClosed,
                                          checkedAt: now), false, false, true),
            ("permanent", PlaceContactDetails(weekdayText: lines, openStatus: .permanentlyClosed,
                                              checkedAt: now), false, false, true)
        ]
        for (name, details, loading, failed, canLoad) in cases {
            let content = RestaurantHoursCard(details: details, isLoading: loading, failed: failed,
                canLoad: canLoad, refresh: {})
                .padding(20).frame(width: 390).background(Atlas.paper)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
                preconditionFailure("Could not render hours card: \(name)")
            }
            try png.write(to: output.appendingPathComponent("hours-\(name).png"))
        }
        print("PASS seven production hours-card renders: ready, loading, failed, manual, unknown, temporary/localized, permanently closed")
    }
}
