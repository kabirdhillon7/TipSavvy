//
//  SettingsView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/8/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: TipSavvySettings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    private let appStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6449447909?action=write-review")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    defaultsCard
                    experienceCard
                    privacyReliabilityCard
                    appStoreCard
                    resetButton
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Settings"))
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

            InfoRow(title: String(localized: "Currency"), value: localCurrency)
            Text(String(localized: "TipSavvy formats totals with your device locale and currency settings."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
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

            Text(String(localized: "Enjoying the app? A quick rating helps other people find it."))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let appStoreReviewURL {
                Link(destination: appStoreReviewURL) {
                    Label(String(localized: "Rate on the App Store"), systemImage: "star.bubble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("Rate on the App Store")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22)
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
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SettingsPreview") ?? .standard))
}
