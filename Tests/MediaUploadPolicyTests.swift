import Foundation

@main struct MediaUploadPolicyTests {
    static func main() throws {
        func rejects(_ expected: ScoutMediaUploadPolicy.Failure, _ action: () throws -> Void) {
            do { try action(); fatalError("Expected rejection") }
            catch let error as ScoutMediaUploadPolicy.Failure {
                precondition(String(describing: error) == String(describing: expected))
                precondition(!(error.localizedDescription).isEmpty)
            } catch { fatalError("Wrong error: \(error)") }
        }
        for (ext, mime, video) in [("jpg","image/jpeg",false),("png","image/png",false),
                                 ("heic","image/heic",false),("heif","image/heif",false),
                                 ("mp4","video/mp4",true),("mov","video/quicktime",true),("m4v","video/x-m4v",true)] {
            try ScoutMediaUploadPolicy.validate(VisitMediaUpload(data: Data([1]), mediaType: video ? .video : .photo,
                                                               fileExtension: ext, contentType: mime))
        }
        rejects(.empty) { try ScoutMediaUploadPolicy.validate(.photo(Data())) }
        rejects(.unsupported) { try ScoutMediaUploadPolicy.validate(.video(Data([1]), fileExtension: "../mov", contentType: "video/quicktime")) }
        rejects(.unsupported) { try ScoutMediaUploadPolicy.validate(.video(Data([1]), fileExtension: "mp4", contentType: "image/jpeg")) }
        try ScoutMediaUploadPolicy.validateSize(ScoutMediaUploadPolicy.videoLimit, isVideo: true)
        try ScoutMediaUploadPolicy.validateSize(ScoutMediaUploadPolicy.photoLimit, isVideo: false)
        rejects(.videoTooLarge) { try ScoutMediaUploadPolicy.validateSize(ScoutMediaUploadPolicy.videoLimit + 1, isVideo: true) }
        rejects(.photoTooLarge) { try ScoutMediaUploadPolicy.validateSize(ScoutMediaUploadPolicy.photoLimit + 1, isVideo: false) }
        let video = VisitMediaUpload.video(Data(repeating: 0, count: ScoutMediaUploadPolicy.videoLimit))
        try ScoutMediaUploadPolicy.validate([video, video])
        rejects(.entryTooLarge) { try ScoutMediaUploadPolicy.validate([video, video, .photo(Data([1]))]) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let validFile = directory.appendingPathComponent("fixture.MOV")
        try Data([1,2,3]).write(to: validFile)
        let imported = try JournalMediaFile.read(from: validFile)
        precondition(imported.fileExtension == "mov" && imported.data == Data([1,2,3]))
        let largeFile = directory.appendingPathComponent("too-large.mov")
        FileManager.default.createFile(atPath: largeFile.path, contents: nil)
        let handle = try FileHandle(forWritingTo: largeFile)
        try handle.truncate(atOffset: UInt64(ScoutMediaUploadPolicy.videoLimit + 1))
        try handle.close()
        rejects(.videoTooLarge) { _ = try JournalMediaFile.read(from: largeFile) }
        let emptyFile = directory.appendingPathComponent("empty.mov")
        try Data().write(to: emptyFile)
        rejects(.empty) { _ = try JournalMediaFile.read(from: emptyFile) }
        print("PASS production file import: real file bytes and normalized extension; empty and oversized on-disk files rejected")
        print("PASS upload types, extension/MIME mismatch and path rejection, empty files, exact per-file/entry boundaries and actionable errors")
    }
}
