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
                        Label(String(localized: "Calculate"), systemImage: "percent")
                            .accessibilityLabel(String(localized: "Calculate"))
                            .accessibilityHint(String(localized: "Calculate tip amounts"))
                    }
                    .environmentObject(manager)
                
                SavedView()
                    .tabItem {
                        Label(String(localized: "Saved"), systemImage: "bookmark")
                            .accessibilityLabel(String(localized: "Saved"))
                            .accessibilityHint(String(localized: "View and manage saved tip calculations"))
                    }
                    .environmentObject(manager)
            }
        }
    }
}
