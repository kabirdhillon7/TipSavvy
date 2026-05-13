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
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var showingPrivacyPolicy = false

    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    private let appStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6449447909?action=write-review")
    private let contactURL = URL(string: "mailto:kabirdhillon.dev@gmail.com?subject=TipSavvy%20Support")
    private let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/e/2PACX-1vT5uoP653Dd3_hKw-ozR0c0YxUhKPlGNglEByGnuWDC4M7rzMwI4gIdw-mFvU94Ma3gxW5JV-XNj_KW/pub")
    private let appReadinessInfo = AppReadinessInfo()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    defaultsCard
                    experienceCard
                    privacyReliabilityCard
                    appStoreCard
                    aboutCard
                    resetButton
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Settings"))
            .sheet(isPresented: $showingPrivacyPolicy) {
                privacyPolicySheet
            }
        }
    }

    private var defaultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(String(localized: "Calculation Defaults"), systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "Default Tip"))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(settings.defaultTipPercentage, specifier: "%.0f")%")
                        .font(.headline.monospacedDigit())
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
                        .font(.headline.monospacedDigit())
                        .animatedTextChange(value: settings.defaultNumberOfPeople)
                }
            }
            .accessibilityLabel(String(localized: "Default Split"))
            .accessibilityValue("\(settings.defaultNumberOfPeople)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22, highContrast: colorSchemeContrast == .increased)
    }

    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(String(localized: "Experience"), systemImage: "iphone.gen3")
                .font(.headline)
                .foregroundStyle(.secondary)

            Toggle(isOn: $settings.hapticsEnabled) {
                Text(String(localized: "Haptic Feedback"))
            }
            .onChange(of: settings.hapticsEnabled) { isEnabled in
                HapticFeedbackPerformer.softImpact(isEnabled: isEnabled)
            }

            themePicker

            InfoRow(title: String(localized: "Currency"), value: localCurrency)
            Text(String(localized: "TipSavvy formats totals with your device locale and currency settings."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Theme"))
                .font(.subheadline.weight(.medium))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
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
    }

    private var privacyReliabilityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Privacy & Reliability"), systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(.secondary)

            Label(String(localized: "Crash reports help improve reliability."), systemImage: "waveform.path.ecg")
            Label(String(localized: "TipSavvy does not require an account."), systemImage: "person.crop.circle.badge.xmark")
            Label(String(localized: "Saved calculations stay on this device."), systemImage: "iphone")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
    }

    private var appStoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Support TipSavvy"), systemImage: "heart")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(String(localized: "Enjoying the app? Ratings are optional, private, and help other people find TipSavvy."))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                requestNativeReview()
            } label: {
                Label(String(localized: "Rate TipSavvy"), systemImage: "star")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("Request App Review")

            if let appStoreReviewURL {
                Link(destination: appStoreReviewURL) {
                    Label(String(localized: "Open App Store Review"), systemImage: "star.bubble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("Rate on the App Store")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "About TipSavvy"), systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(.secondary)

            InfoRow(title: String(localized: "Version"), value: appReadinessInfo.displayVersion)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    privacyPolicyButton
                    contactButton
                }

                VStack(spacing: 10) {
                    privacyPolicyButton
                    contactButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityIdentifier("About TipSavvy")
    }

    private var privacyPolicyButton: some View {
        Button {
            showingPrivacyPolicy = true
        } label: {
            Label(String(localized: "Privacy Policy"), systemImage: "hand.raised")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("Privacy Policy")
    }

    @ViewBuilder
    private var contactButton: some View {
        if let contactURL {
            Link(destination: contactURL) {
                Label(String(localized: "Contact"), systemImage: "envelope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("Contact Support")
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            settings.resetPreferences()
        } label: {
            Label(String(localized: "Reset Preferences"), systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Reset Preferences"))
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
                    Text(String(localized: "TipSavvy uses Firebase Crashlytics for crash reporting and diagnostics. Crash reports help improve reliability and are not used to personally identify users."))
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
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary.opacity(colorSchemeContrast == .increased ? 0.6 : 0.2), lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
                        }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityHidden(true)

                Text(theme.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? theme.accentColor.opacity(colorSchemeContrast == .increased ? 0.22 : 0.12) : Color.primary.opacity(colorSchemeContrast == .increased ? 0.08 : 0.04))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? theme.accentColor : Color.primary.opacity(colorSchemeContrast == .increased ? 0.28 : 0.08), lineWidth: isSelected || colorSchemeContrast == .increased ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.displayName)
        .accessibilityHint(String(localized: "Sets the app theme"))
        .modifier(SelectedAccessibilityTraitModifier(isSelected: isSelected))
    }
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SettingsPreview") ?? .standard))
}
