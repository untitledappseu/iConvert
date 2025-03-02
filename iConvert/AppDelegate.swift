//
//  AppDelegate.swift
//  iConvert
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import SwiftUI

// Remove @main since we're using main.swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let welcomeView = WelcomeView()

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(rootView: welcomeView)
        window.center()
        window.title = "iConvert"
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        // Store window and make it key and visible
        self.window = window
        window.makeKeyAndOrderFront(nil)
        
        // Ensure the app is active
        NSApp.activate(ignoringOtherApps: true)
    }

    // Rest of the file remains the same
}
