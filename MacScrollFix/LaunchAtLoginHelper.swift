// LaunchAtLoginHelper.swift
import Foundation
import ServiceManagement

class LaunchAtLoginHelper {
    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[LaunchAtLogin] Failed: \(error)")
            }
        }
    }
}
