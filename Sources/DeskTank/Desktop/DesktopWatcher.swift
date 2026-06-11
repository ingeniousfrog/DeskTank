import Foundation

@MainActor
final class DesktopWatcher {
    private let pollInterval: TimeInterval
    private var sources: [DispatchSourceFileSystemObject] = []
    private var pollTimer: Timer?
    private var pendingChange: DispatchWorkItem?
    private let onChange: @MainActor () -> Void

    init(pollInterval: TimeInterval = 4.0, onChange: @escaping @MainActor () -> Void) {
        self.pollInterval = pollInterval
        self.onChange = onChange
    }

    func start() {
        stop()

        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let dsStoreURL = desktopURL.appendingPathComponent(".DS_Store")
        [desktopURL, dsStoreURL].forEach(watch)
        startPolling()
    }

    func stop() {
        pendingChange?.cancel()
        pendingChange = nil
        pollTimer?.invalidate()
        pollTimer = nil
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
                self?.scheduleChange()
            }
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
        sources.append(source)
    }

    private func startPolling() {
        guard pollInterval > 0 else {
            return
        }

        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onChange()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func scheduleChange() {
        pendingChange?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        pendingChange = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}
