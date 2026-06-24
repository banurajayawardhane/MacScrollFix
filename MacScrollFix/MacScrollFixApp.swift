// MacScrollFixApp.swift
import SwiftUI

@main
struct MacScrollFixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
