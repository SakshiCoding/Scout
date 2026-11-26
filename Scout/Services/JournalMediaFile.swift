import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Check the file on disk before reading bytes; PhotosPicker's temporary URL is valid only here.
struct JournalMediaFile: Transferable {
    let data: Data
    let fileExtension: String

    nonisolated static func read(from url: URL) throws -> JournalMediaFile {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        try ScoutMediaUploadPolicy.validateSize(size, isVideo: true)
        let data = try Data(contentsOf: url)
        try ScoutMediaUploadPolicy.validateSize(data.count, isVideo: true)
        return JournalMediaFile(data: data, fileExtension: url.pathExtension.lowercased())
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .data) { received in
            try read(from: received.file)
        }
    }
}
