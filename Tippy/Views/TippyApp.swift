//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

@main
struct TippyApp: App {
    @StateObject private var manager: DataManager = DataManager()
        
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Calculate", systemImage: "percent")
                            .accessibilityLabel("Calculate")
                            .accessibilityHint("Calculate tip amounts")
                    }
                    .environmentObject(manager)
                
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                            .accessibilityLabel("Saved")
                            .accessibilityHint("View and manage saved tip calculations")
                    }
                    .environmentObject(manager)
            }
        }
    }
}
