// SettingsView.swift
import SwiftUI

// MARK: - Tab enum
enum SettingsTab: String, CaseIterable {
    case general   = "General"
    case scrolling = "Scrolling"
    case about     = "About"

    var icon: String {
        switch self {
        case .general:   return "gearshape"
        case .scrolling: return "arrow.up.arrow.down"
        case .about:     return "info.circle"
        }
    }
}

// MARK: - Root Settings View
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.top, 12)
                .padding(.bottom, 4)

            Divider()

            Group {
                switch selectedTab {
                case .general:   GeneralTabView()
                case .scrolling: ScrollingTabView()
                case .about:     AboutTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 380, height: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.horizontal, 16)
    }

    private func tabButton(tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isSelected ? .accentColor : Color(NSColor.secondaryLabelColor))
                Text(tab.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .accentColor : Color(NSColor.secondaryLabelColor))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab
struct GeneralTabView: View {
    @ObservedObject private var settings = SettingsModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SettingsRow(
                title: "Enable Mac Scroll Fix",
                subtitle: "Stays enabled after you close this window",
                showDivider: true
            ) {
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            CheckboxRow(
                isOn: $settings.launchAtLogin,
                title: "Launch at Login",
                subtitle: "Start automatically when you log in",
                showDivider: true
            )

            // Quit button
            HStack {
                Spacer()
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 11, weight: .medium))
                        Text("Quit Mac Scroll Fix")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Scrolling Tab
struct ScrollingTabView: View {
    @ObservedObject private var settings = SettingsModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SettingsRow(title: "Smoothness", subtitle: nil, showDivider: true) {
                Picker("", selection: $settings.smoothness) {
                    ForEach(ScrollSmoothness.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)
            }

            SettingsRow(title: "Speed", subtitle: nil, showDivider: true) {
                Picker("", selection: $settings.speed) {
                    ForEach(ScrollSpeed.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)
            }

            CheckboxRow(
                isOn: $settings.reverseDirection,
                title: "Reverse Direction",
                subtitle: "Scroll in the opposite direction to your mouse wheel",
                showDivider: true
            )

            CheckboxRow(
                isOn: $settings.precisionScrolling,
                title: "Precision",
                subtitle: "Moving the scroll wheel slowly scrolls precisely, line by line",
                showDivider: false
            )

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - About Tab
struct AboutTabView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentColor)
                    .frame(width: 72, height: 72)
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("Mac Scroll Fix")
                    .font(.system(size: 18, weight: .semibold))
                Text("Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
            }

            Text("Smooth, natural scrolling for your mouse :)")
                .font(.system(size: 12))
                .foregroundColor(Color(NSColor.secondaryLabelColor))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Divider()
                .padding(.horizontal, 60)

            VStack(spacing: 4) {
                Text("Created by Banura")
                    .font(.system(size: 12, weight: .medium))
                Link("banura.me", destination: URL(string: "https://banura.me")!)
                    .font(.system(size: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Shared Row Components

struct SettingsRow<Control: View>: View {
    let title: String
    let subtitle: String?
    let showDivider: Bool
    @ViewBuilder let control: () -> Control

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                    }
                }
                Spacer()
                control()
            }
            .padding(.vertical, 13)

            if showDivider { Divider() }
        }
    }
}

struct CheckboxRow: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String
    let showDivider: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Toggle("", isOn: $isOn)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 13)

            if showDivider { Divider() }
        }
    }
}

#Preview {
    SettingsView()
}
