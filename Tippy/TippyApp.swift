//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

@main
struct TippyApp: App {
//    @StateObject var savedTipsEnvironment = SavedTipsEnvironment()
    @StateObject private var manager: DataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Calculate", systemImage: "percent")
                    }
                    .environmentObject(manager)
                
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }
                    .environmentObject(manager) 
            }
        }
    }
}

//class SavedTipsEnvironment: ObservableObject {
//    @Published var savedTips: [SavedTip] = []
//
//    func addSavedTip(_ savedTip: SavedTip) {
//        savedTips.append(savedTip)
//    }
//}
