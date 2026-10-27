#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

let root = URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Scout/Assets.xcassets")
let iconSet = assets.appendingPathComponent("AppIcon.appiconset")
func json(_ url: URL) throws -> [String:Any] {
    try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [String:Any]
}
let images = try json(iconSet.appendingPathComponent("Contents.json"))["images"] as! [[String:Any]]
let ios = images.filter { $0["platform"] as? String == "ios" }
precondition(ios.count == 3)
var styles = Set<String>()
for slot in ios {
    let style = (slot["appearances"] as? [[String:String]])?.first?["value"] ?? "light"
    styles.insert(style)
    let url = iconSet.appendingPathComponent(slot["filename"] as! String)
    let source = CGImageSourceCreateWithURL(url as CFURL,nil)!
    let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil)! as NSDictionary
    precondition(properties[kCGImagePropertyPixelWidth] as? Int == 1024)
    precondition(properties[kCGImagePropertyPixelHeight] as? Int == 1024)
    precondition((properties[kCGImagePropertyHasAlpha] as? Bool ?? false) == (style == "dark"))
    let image = CGImageSourceCreateImageAtIndex(source,0,nil)!
    let bytes = image.dataProvider!.data! as Data
    let stride = image.bitsPerPixel / 8
    let center = 512 * image.bytesPerRow + 512 * stride
    if style == "light" {
        precondition(Array(bytes[0..<3]) == [247,241,230],"Light icon must use exact sRGB Atlas paper")
        precondition(Array(bytes[center..<center+3]) == [204,85,0],"Light icon must use exact sRGB Atlas burnt orange")
    } else if style == "dark" {
        precondition(stride == 4 && bytes[3] == 0 && bytes[center+3] == 255,"Dark icon must have transparent background and visible glyph")
    } else {
        precondition(image.colorSpace?.model == .monochrome,"Tinted icon must be grayscale")
        precondition(bytes[0] == 0 && bytes[center] == 255,"Tinted silhouette must have full contrast")
    }
}
precondition(styles == ["light","dark","tinted"])
let markSet = assets.appendingPathComponent("ScoutCompass.imageset")
let markManifest = try json(markSet.appendingPathComponent("Contents.json"))
let properties = markManifest["properties"] as! [String:Any]
precondition(properties["preserves-vector-representation"] as? Bool == true)
precondition(properties["template-rendering-intent"] as? String == "template")
let pdf = CGPDFDocument(markSet.appendingPathComponent("ScoutCompass.pdf") as CFURL)!
precondition(pdf.numberOfPages == 1 && pdf.page(at:1)!.getBoxRect(.mediaBox).size == CGSize(width:32,height:32))
let svg = try String(contentsOf:root.appendingPathComponent("Branding/ScoutCompass.svg"),encoding:.utf8)
precondition(svg.contains("viewBox=\"0 0 32 32\"") && !svg.contains("<text") && !svg.contains("<image"))
print("PASS icon slots, 1024px dimensions, light/dark alpha rules, exact Atlas sRGB palette, grayscale tint, and reusable vector assets")

if CommandLine.arguments.count > 1 {
    let app = URL(fileURLWithPath:CommandLine.arguments[1])
    let info = try PropertyListSerialization.propertyList(from:Data(contentsOf:app.appendingPathComponent("Info.plist")),format:nil) as! [String:Any]
    let icons = info["CFBundleIcons"] as! [String:Any]
    let primary = icons["CFBundlePrimaryIcon"] as! [String:Any]
    precondition(primary["CFBundleIconName"] as? String == "AppIcon")
    let files = try FileManager.default.contentsOfDirectory(atPath:app.path)
    precondition(files.contains("Assets.car") && files.contains { $0.hasPrefix("AppIcon") && $0.hasSuffix(".png") })
    print("PASS built app declares AppIcon and contains compiled icon renditions and asset catalog")
}
