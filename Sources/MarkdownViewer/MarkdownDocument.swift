import SwiftUI
import UniformTypeIdentifiers

/// Read-only document backing the viewer.
///
/// Kept intentionally tiny: decoding a text file is cheap, so the whole file is
/// read synchronously during `init(configuration:)`. This keeps the very first
/// frame ready the instant the window appears — the key to a Preview-fast cold
/// start. Anything heavier (file watching, network) is deferred until after the
/// document view has painted.
struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .text]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        if let daring = UTType("net.daringfireball.markdown") { types.append(daring) }
        return types
    }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(decoding: data, as: UTF8.self)
        } else {
            self.text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // The app is a viewer; this exists only to satisfy FileDocument.
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
