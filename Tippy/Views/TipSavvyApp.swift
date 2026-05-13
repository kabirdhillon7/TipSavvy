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
    @StateObject private var calculationViewModel: CalculationViewModel
    @State private var selectedTab: TipSavvyTab = .calculate

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

        let appSettings = TipSavvySettings(defaults: defaults)
        _manager = StateObject(wrappedValue: dataManager)
        _settings = StateObject(wrappedValue: appSettings)
        _calculationViewModel = StateObject(wrappedValue: CalculationViewModel(defaults: defaults, settings: appSettings))
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                CalculationView(viewModel: calculationViewModel)
                    .tabItem {
                        Label(String(localized: "Calculate"), systemImage: "percent")
                            .accessibilityLabel(String(localized: "Calculate"))
                            .accessibilityHint(String(localized: "Calculate tip amounts"))
                    }
                    .tag(TipSavvyTab.calculate)
                    .environmentObject(manager)
                    .environmentObject(settings)
                
                SavedView { tip in
                    calculationViewModel.applySavedTip(tip)
                    selectedTab = .calculate
                }
                    .tabItem {
                        Label(String(localized: "Saved"), systemImage: "bookmark")
                            .accessibilityLabel(String(localized: "Saved"))
                            .accessibilityHint(String(localized: "View and manage saved tip calculations"))
                    }
                    .tag(TipSavvyTab.saved)
                    .environmentObject(manager)

                SettingsView()
                    .tabItem {
                        Label(String(localized: "Settings"), systemImage: "gearshape")
                            .accessibilityLabel(String(localized: "Settings"))
                            .accessibilityHint(String(localized: "Manage TipSavvy preferences"))
                    }
                    .tag(TipSavvyTab.settings)
                    .environmentObject(settings)
            }
            .tint(settings.selectedTheme.accentColor)
        }
    }
}

private enum TipSavvyTab {
    case calculate
    case saved
    case settings
}
