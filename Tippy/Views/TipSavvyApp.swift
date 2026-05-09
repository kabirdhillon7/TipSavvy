//
//  TippyApp.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        return true
    }
}

@main
struct TipSavvyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager: DataManager
    @StateObject private var settings: TipSavvySettings

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let usesEphemeralStore = arguments.contains("-ui-testing") || arguments.contains("-demo-data")
        let dataManager = DataManager(inMemory: usesEphemeralStore)
        if arguments.contains("-demo-data") {
            dataManager.seedDemoTips()
        }

        let defaults = arguments.contains("-ui-testing")
        ? UserDefaults(suiteName: "TipSavvyUITests") ?? .standard
        : .standard
        if arguments.contains("-ui-testing") {
            defaults.removePersistentDomain(forName: "TipSavvyUITests")
        }

        _manager = StateObject(wrappedValue: dataManager)
        _settings = StateObject(wrappedValue: TipSavvySettings(defaults: defaults))
    }
    
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
                    .environmentObject(settings)
                
                SavedView()
                    .tabItem {
                        Label(String(localized: "Saved"), systemImage: "bookmark")
                            .accessibilityLabel(String(localized: "Saved"))
                            .accessibilityHint(String(localized: "View and manage saved tip calculations"))
                    }
                    .environmentObject(manager)

                SettingsView()
                    .tabItem {
                        Label(String(localized: "Settings"), systemImage: "gearshape")
                            .accessibilityLabel(String(localized: "Settings"))
                            .accessibilityHint(String(localized: "Manage TipSavvy preferences"))
                    }
                    .environmentObject(settings)
            }
        }
    }
}
