// SettingsModel.swift
import Foundation
import Combine

enum ScrollSmoothness: String, CaseIterable {
    case off     = "Off"
    case regular = "Regular"
    case high    = "High"
}

enum ScrollSpeed: String, CaseIterable {
    case slow   = "Slow"
    case medium = "Medium"
    case fast   = "Fast"

    var multiplier: Double {
        switch self {
        case .slow:   return 0.6
        case .medium: return 1.0
        case .fast:   return 1.6
        }
    }
}

class SettingsModel: ObservableObject {

    static let shared = SettingsModel()

    // MARK: - General
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            LaunchAtLoginHelper.setEnabled(launchAtLogin)
        }
    }

    // MARK: - Scrolling
    @Published var smoothness: ScrollSmoothness {
        didSet { UserDefaults.standard.set(smoothness.rawValue, forKey: "smoothness") }
    }

    @Published var reverseDirection: Bool {
        didSet { UserDefaults.standard.set(reverseDirection, forKey: "reverseDirection") }
    }

    @Published var speed: ScrollSpeed {
        didSet { UserDefaults.standard.set(speed.rawValue, forKey: "speed") }
    }

    @Published var precisionScrolling: Bool {
        didSet { UserDefaults.standard.set(precisionScrolling, forKey: "precisionScrolling") }
    }

    // MARK: - Derived values for the engine
    var frictionCoefficient: Double {
        switch smoothness {
        case .off:     return 1.0
        case .regular: return 0.85
        case .high:    return 0.93
        }
    }

    var isMomentumEnabled: Bool {
        smoothness != .off
    }

    // MARK: - Init
    private init() {
        isEnabled          = UserDefaults.standard.object(forKey: "isEnabled")          as? Bool ?? true
        launchAtLogin      = UserDefaults.standard.object(forKey: "launchAtLogin")      as? Bool ?? false
        reverseDirection   = UserDefaults.standard.object(forKey: "reverseDirection")   as? Bool ?? false
        precisionScrolling = UserDefaults.standard.object(forKey: "precisionScrolling") as? Bool ?? false

        let smoothRaw = UserDefaults.standard.string(forKey: "smoothness") ?? ScrollSmoothness.high.rawValue
        smoothness = ScrollSmoothness(rawValue: smoothRaw) ?? .high

        let speedRaw = UserDefaults.standard.string(forKey: "speed") ?? ScrollSpeed.medium.rawValue
        speed = ScrollSpeed(rawValue: speedRaw) ?? .medium
    }
}
