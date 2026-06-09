import AppKit
import Carbon
import Foundation

@MainActor
final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
    }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard hotKeyID.id == 1 else {
                    return noErr
                }

                let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    controller.onToggle()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType("DTNK".fourCharCode), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        utf8.reduce(0) { result, character in
            (result << 8) + FourCharCode(character)
        }
    }
}
