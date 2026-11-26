// Synthetic ImageIO/AVFoundation fixtures only; no user media or credentials.
import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

@main struct Fixtures {
  static func video(at url: URL, type: AVFileType) async throws -> Data {
    let writer = try AVAssetWriter(outputURL: url, fileType: type)
    let input = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1280, AVVideoHeightKey: 720,
      ])
    input.transform = CGAffineTransform(rotationAngle: .pi / 2)
    let adapter = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: 1280, kCVPixelBufferHeightKey as String: 720,
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      ])
    writer.add(input)
    precondition(writer.startWriting())
    writer.startSession(atSourceTime: .zero)
    var buffer: CVPixelBuffer?
    precondition(
      CVPixelBufferCreate(
        kCFAllocatorDefault, 1280, 720,
        kCVPixelFormatType_32ARGB, nil, &buffer) == kCVReturnSuccess)
    CVPixelBufferLockBaseAddress(buffer!, [])
    memset(CVPixelBufferGetBaseAddress(buffer!), 0x88, CVPixelBufferGetDataSize(buffer!))
    CVPixelBufferUnlockBaseAddress(buffer!, [])
    for index in 0..<3 {
      while !input.isReadyForMoreMediaData { await Task.yield() }
      precondition(
        adapter.append(buffer!, withPresentationTime: CMTime(value: Int64(index), timescale: 2)))
    }
    input.markAsFinished()
    await writer.finishWriting()
    precondition(
      writer.status == .completed, "Video fixture failed: \(String(describing: writer.error))")
    return try Data(contentsOf: url)
  }

  static func main() async throws {
    let dir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let context = CGContext(
      data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 256,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(CGColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
    for (ext, type) in [
      ("jpg", UTType.jpeg), ("png", UTType.png), ("heic", UTType.heic), ("heif", UTType.heic),
    ] {
      let data = NSMutableData()
      let dest = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
      CGImageDestinationAddImage(dest, context.makeImage()!, nil)
      precondition(CGImageDestinationFinalize(dest))
      try (data as Data).write(to: dir.appendingPathComponent("fixture." + ext))
    }
    for (ext, type) in [("mov", AVFileType.mov), ("mp4", AVFileType.mp4), ("m4v", AVFileType.m4v)] {
      _ = try await video(at: dir.appendingPathComponent("fixture." + ext), type: type)
    }
    print("Generated real ImageIO JPEG/PNG/HEIC/HEIF and AVFoundation MOV/MP4/M4V fixtures")
  }
}
