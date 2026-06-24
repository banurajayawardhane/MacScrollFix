// AccessibilityChecker.swift
import AppKit
import ApplicationServices

class AccessibilityChecker {

    static func isGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    static func waitForPermission(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            while !AXIsProcessTrusted() {
                Thread.sleep(forTimeInterval: 0.5)
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
