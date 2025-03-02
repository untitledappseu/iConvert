//
//  ViewController.swift
//  iConvert
//
//  @JuditKaramazov, 2023.
//

import SwiftUI

class ViewController: NSHostingController<WelcomeView> {
    
    @IBAction func juditKaramazovClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://untitledapps.at")!)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: WelcomeView())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.window?.isMovableByWindowBackground = true
        view.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        view.window?.standardWindowButton(.zoomButton)?.isHidden = true
        view.window?.center()
    }
}
