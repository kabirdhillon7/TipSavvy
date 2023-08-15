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
                CalculationView()
                    .tabItem {
                        let calculateLocalizedString = NSLocalizedString("calculate_tab", comment: "Calculate Tab Name")
                        Label(calculateLocalizedString, systemImage: "percent")
                            .accessibilityLabel("Calculate")
                            .accessibilityHint("Calculate tip amounts")
                    }
                    .environmentObject(manager)
                
                SavedView()
                    .tabItem {
                        let savedLocalizaedString = NSLocalizedString("saved_tab", comment: "Saved Tab Name")
                        Label(savedLocalizaedString, systemImage: "bookmark")
                            .accessibilityLabel("Saved")
                            .accessibilityHint("View and manage saved tip calculations")
                    }
                    .environmentObject(manager)
            }
        }
    }
}
