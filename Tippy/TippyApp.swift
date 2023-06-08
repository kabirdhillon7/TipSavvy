//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

@main
struct TippyApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Calculate", systemImage: "percent")
                    }
                
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }
            }
        }
    }
}
