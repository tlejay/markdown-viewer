import Foundation

/// Watches a single file and fires `onChange` when its contents change.
///
/// Built on a `DispatchSource` file-system object so it is essentially free
/// while idle — no polling. It is created lazily (after first paint) so setting
/// up the watch never delays the initial render.
///
/// Editors commonly save atomically (write a temp file, then rename over the
/// original), which delivers `.rename`/`.delete` rather than `.write`. When that
/// happens the old descriptor points at a stale inode, so we tear down and
/// re-open the watch on the same path.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start()
    }

    deinit { stop() }

    private func start() {
        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self, let source = self.source else { return }
            let flags = source.data
            self.onChange()
            if flags.contains(.rename) || flags.contains(.delete) {
                // Atomic save replaced the file — rewatch the path.
                self.restart()
            }
        }

        source.setCancelHandler { [descriptor] in
            if descriptor >= 0 { close(descriptor) }
        }

        self.source = source
        source.resume()
    }

    private func restart() {
        stop()
        // Give the editor a beat to put the new file in place before rewatching.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            self.start()
            self.onChange()
        }
    }

    func stop() {
        source?.cancel()
        source = nil
        descriptor = -1
    }
}
