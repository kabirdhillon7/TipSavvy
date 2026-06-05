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
        if canConfigureFirebase {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        }
        return true
    }

    private var canConfigureFirebase: Bool {
        guard
            let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
            let config = NSDictionary(contentsOf: url) as? [String: Any],
            let apiKey = config["API_KEY"] as? String,
            let googleAppID = config["GOOGLE_APP_ID"] as? String
        else {
            return false
        }

        return !apiKey.hasPrefix("REPLACE_WITH") && !googleAppID.hasPrefix("REPLACE_WITH")
    }
}

@main
struct TipSavvyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager: DataManager
    @StateObject private var settings: TipSavvySettings
    @StateObject private var calculationViewModel: CalculationViewModel
    @State private var selectedTab: TipSavvyTab

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
        let calculatorViewModel = CalculationViewModel(defaults: defaults, settings: appSettings)
        if Self.appStoreScreenshotMode(in: arguments) == "calculator" {
            calculatorViewModel.billAmount = 86.40
            calculatorViewModel.tipPercentage = 20
            calculatorViewModel.numberOfPeople = 3
            calculatorViewModel.roundingMode = .roundPerPersonUp
        }

        _manager = StateObject(wrappedValue: dataManager)
        _settings = StateObject(wrappedValue: appSettings)
        _calculationViewModel = StateObject(wrappedValue: calculatorViewModel)
        _selectedTab = State(initialValue: Self.initialTab(for: arguments))
    }
    
    var body: some Scene {
        WindowGroup {
            if Self.appStoreScreenshotMode(in: ProcessInfo.processInfo.arguments) == "detail",
               let tip = manager.savedTips.first {
                SavedDetailView(tip: tip)
                    .environmentObject(settings)
            } else {
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

    private static func appStoreScreenshotMode(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "-app-store-screenshot"),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func initialTab(for arguments: [String]) -> TipSavvyTab {
        switch appStoreScreenshotMode(in: arguments) {
        case "saved", "detail":
            return .saved
        case "settings":
            return .settings
        default:
            return .calculate
        }
    }
}

private enum TipSavvyTab {
    case calculate
    case saved
    case settings
}
