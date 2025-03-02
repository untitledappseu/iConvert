//
//  WelcomeView.swift
//  iConvert
//
//  @JuditKaramazov, 2023.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("AppIcon")
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("Welcome to iConvert")
                .font(.largeTitle)
                .bold()
            
            Text("To use iConvert, go to System Preferences > Login Items & Extensions > File Providers, and make sure the extension is enabled. If it indeed is, just right-click on a file you want to convert and choose \"iConvert\". Missing file formats? Leave a review and we'll add it!")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Link("Made by UNTITLED APPS e.U.", destination: URL(string: "https://untitledapps.at")!)
                .padding(.bottom)
        }
        .frame(width: 500, height: 400)
        .padding()
    }
}

#Preview {
    WelcomeView()
}

