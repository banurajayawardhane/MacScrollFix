// StatusBarController.swift
import AppKit
import SwiftUI

class StatusBarController {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: EventMonitor?

    init() {
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "arrow.up.arrow.down.circle.fill",
                accessibilityDescription: "Mac Scroll Fix"
            )
            button.image?.isTemplate = true
            button.toolTip = "Mac Scroll Fix"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 360)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: SettingsView())
    }

    @objc func togglePopover() {
        popover.isShown ? closePopover() : openPopover()
    }

    func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        eventMonitor?.start()
    }

    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }

    func updateIcon(enabled: Bool) {
        let symbol = enabled
            ? "arrow.up.arrow.down.circle.fill"
            : "arrow.up.arrow.down.circle"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: "Mac Scroll Fix"
        )
        statusItem.button?.image?.isTemplate = true
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let self, self.popover.isShown { self.closePopover() }
        }
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit { stop() }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}
