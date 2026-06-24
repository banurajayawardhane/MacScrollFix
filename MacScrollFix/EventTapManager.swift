// EventTapManager.swift
import CoreGraphics
import Foundation
import ApplicationServices

class EventTapManager {

    static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isActive = false

    private init() {
        MomentumEngine.shared.onScrollDelta = { deltaY, deltaX, phase in
            EventTapManager.postSynthetic(deltaY: deltaY, deltaX: deltaX, phase: phase)
        }
    }

    func start() {
        guard !isActive else { return }
        guard AXIsProcessTrusted() else {
            print("[EventTapManager] Accessibility not granted.")
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            print("[EventTapManager] Failed to create event tap.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true
        print("[EventTapManager] Started ✓")
    }

    func stop() {
        guard isActive, let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isActive = false
        print("[EventTapManager] Stopped.")
    }

    func reEnable() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    fileprivate func handleEvent(_ event: CGEvent) -> CGEvent? {
        guard SettingsModel.shared.isEnabled else { return event }

        // Only handle discrete mouse scroll — not trackpad (isContinuous == 1)
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        guard isContinuous == 0 else { return event }

        // Trackpad always has a phase set; raw mouse events have phase 0
        let scrollPhase   = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        guard scrollPhase == 0 && momentumPhase == 0 else { return event }

        let rawDeltaY = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
        let rawDeltaX = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)
        guard abs(rawDeltaY) > 0 || abs(rawDeltaX) > 0 else { return nil }

        MomentumEngine.shared.injectScroll(deltaY: rawDeltaY, deltaX: rawDeltaX)

        // Suppress original raw event
        return nil
    }

    static func postSynthetic(deltaY: Double, deltaX: Double, phase: ScrollPhase) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(deltaY.rounded()),
            wheel2: Int32(deltaX.rounded()),
            wheel3: 0
        ) else { return }

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase.rawValue)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: phase == .momentum ? 2 : 0)
        event.post(tap: .cghidEventTap)
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reEnable()
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

    if let result = manager.handleEvent(event) {
        return Unmanaged.passUnretained(result)
    }
    return nil
}
