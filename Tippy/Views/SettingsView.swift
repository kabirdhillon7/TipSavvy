//
//  SettingsView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/8/26.
//

import StoreKit
import SafariServices
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var settings: TipSavvySettings

    @State private var showingPrivacyPolicy = false
    @State private var showingResetConfirmation = false

    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    private let appStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6449447909?action=write-review")
    private let contactURL = URL(string: "mailto:kabirdhillon.dev@gmail.com?subject=TipSavvy%20Support")
    private let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/e/2PACX-1vT5uoP653Dd3_hKw-ozR0c0YxUhKPlGNglEByGnuWDC4M7rzMwI4gIdw-mFvU94Ma3gxW5JV-XNj_KW/pub")
    private let appReadinessInfo = AppReadinessInfo()

    /// A standard inset-grouped Form: it matches people's model of Settings and picks up
    /// the system's Liquid Glass treatment on its own.
    var body: some View {
        NavigationStack {
            Form {
                defaultsSection
                appearanceSection
                privacySection
                supportSection
                aboutSection

                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Text(String(localized: "Reset Preferences"))
                    }
                    .accessibilityIdentifier("Reset Preferences")
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .sheet(isPresented: $showingPrivacyPolicy) {
                privacyPolicySheet
            }
            .confirmationDialog(String(localized: "Reset Preferences"), isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button(String(localized: "Reset Preferences"), role: .destructive) {
                    settings.resetPreferences()
                }

                Button(String(localized: "Cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "This restores your default tip, split count, haptics, and app theme."))
            }
        }
    }

    private var defaultsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(localized: "Default Tip"))
                    Spacer()
                    Text("\(settings.defaultTipPercentage, specifier: "%.0f")%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .animatedTextChange(value: settings.defaultTipPercentage)
                }

                Slider(value: $settings.defaultTipPercentage, in: 0...30, step: 1)
                    .accessibilityLabel(String(localized: "Default Tip"))
                    .accessibilityValue("\(settings.defaultTipPercentage, specifier: "%.0f")%")
            }

            Stepper(value: $settings.defaultNumberOfPeople, in: 1...99) {
                HStack {
                    Text(String(localized: "Default Split"))
                    Spacer()
                    Text("\(settings.defaultNumberOfPeople)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .animatedTextChange(value: settings.defaultNumberOfPeople)
                }
            }
            .accessibilityLabel(String(localized: "Default Split"))
            .accessibilityValue("\(settings.defaultNumberOfPeople)")
        } header: {
            Text(String(localized: "Calculation Defaults"))
        }
    }

    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Text(String(localized: "Haptic Feedback"))
            }
            .onChange(of: settings.hapticsEnabled) { isEnabled in
                HapticFeedbackPerformer.softImpact(isEnabled: isEnabled)
            }

            themePicker
        } header: {
            Text(String(localized: "Experience"))
        }
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Theme"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 8)], spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionButton(
                        theme: theme,
                        isSelected: settings.selectedTheme == theme
                    ) {
                        settings.selectedTheme = theme
                        HapticFeedbackPerformer.softImpact(isEnabled: settings.hapticsEnabled)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Theme Picker")
    }

    private var privacySection: some View {
        Section {
            Button {
                showingPrivacyPolicy = true
            } label: {
                Text(String(localized: "Privacy Policy"))
            }
            .accessibilityIdentifier("Privacy Policy")
        } header: {
            Text(String(localized: "Privacy"))
        } footer: {
            Text(String(localized: "No account, no analytics, no crash data. Saved calculations stay on this device."))
        }
    }

    private var supportSection: some View {
        Section {
            // The App Store link always opens visibly, whereas the system review prompt is
            // rate-limited and can silently do nothing.
            if let appStoreReviewURL {
                Link(destination: appStoreReviewURL) {
                    Text(String(localized: "Rate TipSavvy"))
                }
                .accessibilityIdentifier("Rate on the App Store")
            } else {
                Button {
                    requestNativeReview()
                } label: {
                    Text(String(localized: "Rate TipSavvy"))
                }
                .accessibilityIdentifier("Request App Review")
            }

            if let contactURL {
                Link(destination: contactURL) {
                    Text(String(localized: "Contact Support"))
                }
                .accessibilityIdentifier("Contact Support")
            }
        } header: {
            Text(String(localized: "Support"))
        } footer: {
            Text(String(localized: "Ratings are optional and help other people find TipSavvy."))
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent(String(localized: "Version"), value: appReadinessInfo.displayVersion)
                .accessibilityIdentifier("About TipSavvy")
            LabeledContent(String(localized: "Currency"), value: localCurrency)
        } header: {
            Text(String(localized: "About"))
        } footer: {
            Text(String(localized: "Totals use your device's region and currency."))
        }
    }

    @ViewBuilder
    private var privacyPolicySheet: some View {
        if let privacyPolicyURL {
            SafariView(url: privacyPolicyURL)
                .ignoresSafeArea()
        } else {
            fallbackPrivacyPolicyView
        }
    }

    private var fallbackPrivacyPolicyView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(String(localized: "TipSavvy does not require an account and does not ask for your name, email address, phone number, payment information, contacts, or location."))
                    Text(String(localized: "Saved bill amounts, tip percentages, split counts, and app settings stay on your device unless you delete them or uninstall the app."))
                    Text(String(localized: "TipSavvy does not include third-party analytics or crash reporting. If you choose to share analytics with app developers in iOS Settings, Apple may provide anonymous crash reports."))
                    Text(String(localized: "TipSavvy is suitable for a general audience and does not knowingly collect personal information from children."))
                }
                .font(.body)
                .foregroundStyle(.primary)
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Privacy Policy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) {
                        showingPrivacyPolicy = false
                    }
                }
            }
        }
    }

    private func requestNativeReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

private struct ThemeOptionButton: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary.opacity(colorSchemeContrast == .increased ? 0.6 : 0.2), lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
                        }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 44, height: 44)

                Text(theme.displayName)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.displayName)
        .accessibilityHint(String(localized: "Sets the app theme"))
        .accessibilityIdentifier("Theme Option \(theme.displayName)")
        .modifier(SelectedAccessibilityTraitModifier(isSelected: isSelected))
    }
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SettingsPreview") ?? .standard))
}
