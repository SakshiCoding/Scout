#!/usr/bin/env swift
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Native vector geometry derived from the Atlas ScoutCompass in designs/.../data.jsx.
// Run from the repository root. No network, fonts, API keys, or third-party tools.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Scout/Assets.xcassets")
let brand = root.appendingPathComponent("Branding")
let markSet = assets.appendingPathComponent("ScoutCompass.imageset")
for directory in [brand, markSet] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
}

enum Segment {
    case move(CGFloat, CGFloat), line(CGFloat, CGFloat), quad(CGFloat, CGFloat, CGFloat, CGFloat), close
    var svg: String {
        switch self {
        case let .move(x,y): "M\(x) \(y)"
        case let .line(x,y): "L\(x) \(y)"
        case let .quad(cx,cy,x,y): "Q\(cx) \(cy) \(x) \(y)"
        case .close: "Z"
        }
    }
}
let lines: [([Segment], CGFloat)] = [
    // Three fork tines and bowl form the north compass needle.
    ([.move(13.7,4.4), .line(13.7,7.7), .quad(13.7,10,16,10),
      .quad(18.3,10,18.3,7.7), .line(18.3,4.4), .move(16,4.4), .line(16,11)], 1.4),
    ([.move(3,16), .line(10,16), .move(22,16), .line(29,16), .move(16,23), .line(16,29)], 1.4),
    ([.move(16,11), .line(20,16), .line(16,23), .line(12,16), .close], 1.1)
]
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
let paper = CGColor(colorSpace:sRGB,components:[247/255,241/255,230/255,1])!
let burnt = CGColor(colorSpace:sRGB,components:[204/255,85/255,0,1])!

func drawMark(_ context: CGContext, color: CGColor) {
    context.setStrokeColor(color)
    context.setFillColor(color)
    context.setLineWidth(1.25)
    context.strokeEllipse(in: CGRect(x: 2, y: 2, width: 28, height: 28))
    context.setLineCap(.round)
    context.setLineJoin(.round)
    for (segments, width) in lines {
        context.beginPath()
        for segment in segments {
            switch segment {
            case let .move(x,y): context.move(to: CGPoint(x:x,y:y))
            case let .line(x,y): context.addLine(to: CGPoint(x:x,y:y))
            case let .quad(cx,cy,x,y): context.addQuadCurve(to: CGPoint(x:x,y:y), control: CGPoint(x:cx,y:cy))
            case .close: context.closePath()
            }
        }
        context.setLineWidth(width)
        context.strokePath()
    }
    context.fillEllipse(in: CGRect(x:14.7,y:14.7,width:2.6,height:2.6))
}

func writePNG(_ url: URL, background: CGColor?, foreground: CGColor, grayscale: Bool = false) throws {
    let size = 1024
    let space = grayscale ? CGColorSpaceCreateDeviceGray() : CGColorSpace(name: CGColorSpace.sRGB)!
    let alpha: CGImageAlphaInfo = grayscale ? .none : (background == nil ? .premultipliedLast : .noneSkipLast)
    let context = CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:0,
                            space:space,bitmapInfo:alpha.rawValue)!
    if let background {
        context.setFillColor(background)
        context.fill(CGRect(x:0,y:0,width:size,height:size))
    }
    // The OS applies the icon mask. Keep the source square, with generous glyph clearance.
    context.translateBy(x:96,y:928)
    context.scaleBy(x:26,y:-26)
    drawMark(context,color:foreground)
    let destination = CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(destination,context.makeImage()!,nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

let iconSet = assets.appendingPathComponent("AppIcon.appiconset")
try writePNG(iconSet.appendingPathComponent("Scout-Light.png"),background:paper,foreground:burnt)
try writePNG(iconSet.appendingPathComponent("Scout-Dark.png"),background:nil,foreground:paper)
try writePNG(iconSet.appendingPathComponent("Scout-Tinted.png"),background:CGColor(gray:0,alpha:1),
             foreground:CGColor(gray:1,alpha:1),grayscale:true)

var manifest = try JSONSerialization.jsonObject(with: Data(contentsOf:iconSet.appendingPathComponent("Contents.json"))) as! [String:Any]
var images = manifest["images"] as! [[String:Any]]
for index in images.indices where images[index]["platform"] as? String == "ios" {
    let appearances = images[index]["appearances"] as? [[String:String]]
    let style = appearances?.first?["value"]
    images[index]["filename"] = style == "dark" ? "Scout-Dark.png" : style == "tinted" ? "Scout-Tinted.png" : "Scout-Light.png"
}
manifest["images"] = images
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:iconSet.appendingPathComponent("Contents.json"))

let paths = lines.map { segments,width in
    "<path d=\"\(segments.map(\.svg).joined(separator:" "))\" stroke-width=\"\(width)\"/>"
}.joined(separator:"\n  ")
let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 32 32" fill="none" color="#CC5500">
  <title>Scout Atlas compass with a fork pointing north</title>
  <g stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="16" cy="16" r="14" stroke-width="1.25"/>
    \(paths)
  </g>
  <circle cx="16" cy="16" r="1.3" fill="currentColor"/>
</svg>

"""
try svg.write(to:brand.appendingPathComponent("ScoutCompass.svg"),atomically:true,encoding:.utf8)

// A vector PDF keeps the same mark crisp at any SwiftUI display size.
var box = CGRect(x:0,y:0,width:32,height:32)
let pdf = CGContext(markSet.appendingPathComponent("ScoutCompass.pdf") as CFURL,mediaBox:&box,
                    [kCGPDFContextCreator:"Scout brand asset generator"] as CFDictionary)!
pdf.beginPDFPage(nil)
pdf.translateBy(x:0,y:32)
pdf.scaleBy(x:1,y:-1)
drawMark(pdf,color:burnt)
pdf.endPDFPage()
pdf.closePDF()
let markManifest: [String:Any] = ["images":[["filename":"ScoutCompass.pdf","idiom":"universal"]],
    "info":["author":"xcode","version":1],"properties":["preserves-vector-representation":true,"template-rendering-intent":"template"]]
try JSONSerialization.data(withJSONObject:markManifest,options:[.prettyPrinted,.sortedKeys]).write(to:markSet.appendingPathComponent("Contents.json"))

let accent: [String:Any] = ["colors":[["idiom":"universal","color":["color-space":"srgb",
    "components":["red":"0.800","green":"0.3333333333","blue":"0.000","alpha":"1.000"]]]],
    "info":["author":"xcode","version":1]]
try JSONSerialization.data(withJSONObject:accent,options:[.prettyPrinted,.sortedKeys]).write(to:assets.appendingPathComponent("AccentColor.colorset/Contents.json"))
print("Generated three iOS icons, vector compass PDF/SVG, and Atlas accent color.")

// Contact sheet for visual review; rounded masks here are previews, not source icon masks.
let space=CGColorSpace(name:CGColorSpace.sRGB)!
let ctx=CGContext(data:nil,width:1200,height:480,bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(colorSpace:space,components:[0.94,0.92,0.88,1])!);ctx.fill(CGRect(x:0,y:0,width:1200,height:480))
for (index,style) in ["Light","Dark","Tinted"].enumerated() {
 let rect=CGRect(x:CGFloat(70+index*390),y:110,width:280,height:280)
 ctx.saveGState();ctx.addPath(CGPath(roundedRect:rect,cornerWidth:64,cornerHeight:64,transform:nil));ctx.clip()
 ctx.setFillColor(CGColor(colorSpace:space,components:[0.106,0.086,0.071,1])!);ctx.fill(rect)
 let url=URL(fileURLWithPath:"Scout/Assets.xcassets/AppIcon.appiconset/Scout-\(style).png")
 let img=CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
 ctx.draw(img,in:rect);ctx.restoreGState()
 let attributes:[NSAttributedString.Key:Any]=[NSAttributedString.Key(kCTFontAttributeName as String):CTFontCreateWithName("Helvetica" as CFString,22,nil),NSAttributedString.Key(kCTForegroundColorAttributeName as String):CGColor(gray:0.15,alpha:1)]
 let line=CTLineCreateWithAttributedString(NSAttributedString(string:style,attributes:attributes))
 let width=CTLineGetTypographicBounds(line,nil,nil,nil)
 ctx.textPosition=CGPoint(x:rect.midX-width/2,y:62);CTLineDraw(line,ctx)
}
let output=URL(fileURLWithPath:"Branding/Preview.png")
let dest=CGImageDestinationCreateWithURL(output as CFURL,UTType.png.identifier as CFString,1,nil)!
CGImageDestinationAddImage(dest,ctx.makeImage()!,nil);CGImageDestinationFinalize(dest)

print("Generated Branding/Preview.png for visual review.")
