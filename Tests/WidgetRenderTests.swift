import AppKit
import CoreText
import SwiftUI
import WidgetKit

@main
private struct WidgetRenderTests {
    @MainActor static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for file in ["DMSans-Regular.ttf", "DMSans-Medium.ttf", "DMSans-SemiBold.ttf", "DMSerifDisplay-Regular.ttf", "DMSerifDisplay-Italic.ttf"] {
            CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: file) as CFURL, .process, nil)
        }
        let circle = UUID()
        let now = Date()
        let places = [
            Restaurant(circleId: circle, name: "The very long neighborhood restaurant name", cuisine: "Mediterranean", priceTier: .three, createdAt: now.addingTimeInterval(1)),
            Restaurant(circleId: circle, name: "Kismet", cuisine: "Italian", priceTier: .two),
            Restaurant(circleId: circle, name: "Cafe", priceTier: .one)
        ]
        let ready = ScoutWidgetSnapshot(isSignedIn: true, circleId: circle, circleName: "Our very long circle name", restaurants: places)
        let cases: [(String, ScoutWidgetEntry)] = [
            ("ready", ScoutWidgetEntry(date: now, snapshot: ready)),
            ("signed-out", ScoutWidgetEntry(date: now, snapshot: .signedOut)),
            ("no-circle", ScoutWidgetEntry(date: now, snapshot: ScoutWidgetSnapshot(isSignedIn: true, circleId: nil, circleName: nil, restaurants: []))),
            ("empty", ScoutWidgetEntry(date: now, snapshot: ScoutWidgetSnapshot(isSignedIn: true, circleId: circle, circleName: "Friends", restaurants: []))),
            ("stale", ScoutWidgetEntry(date: now.addingTimeInterval(86_400), snapshot: ready))
        ]
        for (family, width, label) in [(WidgetFamily.systemSmall, 170.0, "small"), (.systemMedium, 364.0, "medium")] {
            for (state, entry) in cases {
                let content = ScoutWidgetContent(entry: entry, family: family)
                    .padding(16)
                    .frame(width: width, height: 170)
                    .background(Atlas.paper)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                guard let image = renderer.nsImage,
                      let tiff = image.tiffRepresentation,
                      let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
                    fatalError("Failed to render \(label)-\(state)")
                }
                try png.write(to: output.appendingPathComponent("\(label)-\(state).png"))
            }
        }
        print("PASS: rendered production widget view in both sizes across all five states to \(output.path)")
    }
}
