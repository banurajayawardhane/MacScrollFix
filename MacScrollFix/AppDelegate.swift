// AppDelegate.swift
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController()

        SettingsModel.shared.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.statusBarController.updateIcon(enabled: enabled)
                if enabled {
                    self?.startIfPermitted()
                } else {
                    EventTapManager.shared.stop()
                }
            }
            .store(in: &cancellables)

        // This call registers the app in Accessibility list
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options)

        if AXIsProcessTrusted() {
            startIfPermitted()
        } else {
            AccessibilityChecker.waitForPermission { [weak self] in
                self?.startIfPermitted()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
    }

    private func startIfPermitted() {
        guard SettingsModel.shared.isEnabled else { return }
        guard AXIsProcessTrusted() else { return }
        EventTapManager.shared.start()
    }
}
