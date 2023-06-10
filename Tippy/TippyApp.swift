//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

@main
struct TippyApp: App {
    @StateObject var savedTipsEnvironment = SavedTipsEnvironment()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Calculate", systemImage: "percent")
                    }
                    .environmentObject(savedTipsEnvironment)
                
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }
                    .environmentObject(savedTipsEnvironment) 
            }
        }
    }
}
