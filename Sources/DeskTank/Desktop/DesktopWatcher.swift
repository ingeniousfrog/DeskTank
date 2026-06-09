import Foundation

@MainActor
final class DesktopWatcher {
    private var sources: [DispatchSourceFileSystemObject] = []
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    func start() {
        stop()

        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let dsStoreURL = desktopURL.appendingPathComponent(".DS_Store")
        [desktopURL, dsStoreURL].forEach(watch)
    }

    func stop() {
        sources.forEach { $0.cancel() }
        sources = []
    }

    private func watch(url: URL) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend, .attrib],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.onChange()
            }
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
        sources.append(source)
    }

    deinit {
        sources.forEach { $0.cancel() }
    }
}
