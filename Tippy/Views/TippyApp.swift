//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TippyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
