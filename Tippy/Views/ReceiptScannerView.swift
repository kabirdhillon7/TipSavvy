//
//  ReceiptScannerView.swift
//  Tippy
//

import AVFoundation
import SwiftUI
import UIKit
import VisionKit

/// A live receipt scanner. Reports the detected bill total via `onAmount`.
/// Presentation/dismissal is owned by the parent — this view never dismisses itself.
struct ReceiptScannerView: View {
    let onAmount: (Double) -> Void

    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) != .denied
        && AVCaptureDevice.authorizationStatus(for: .video) != .restricted

    var body: some View {
        Group {
            if cameraAuthorized {
                DataScannerRepresentable(onAmount: onAmount)
                    .overlay(alignment: .bottom) {
                        hintLabel
                    }
            } else {
                permissionDeniedView
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: requestAccessIfNeeded)
    }

    private var hintLabel: some View {
        Text(String(localized: "Aim at the receipt total"))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.5), in: Capsule())
            .padding(.bottom, 32)
            .accessibilityHidden(true)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(String(localized: "Camera Access Is Off"))
                .font(.headline)
            Text(String(localized: "Enable camera access in Settings to scan receipts."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(String(localized: "Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func requestAccessIfNeeded() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else { return }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { cameraAuthorized = granted }
        }
    }
}

/// UIKit bridge to `DataScannerViewController` with a stabilization gate.
private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onAmount: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAmount: onAmount)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onAmount: (Double) -> Void
        private var didMatch = false
        private var lastCandidate: Double?
        private var stableCount = 0

        // Require the same value across this many consecutive callbacks before accepting.
        private let requiredStableCount = 3

        init(onAmount: @escaping (Double) -> Void) {
            self.onAmount = onAmount
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            evaluate(allItems, in: dataScanner)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            evaluate(allItems, in: dataScanner)
        }

        private func evaluate(_ allItems: [RecognizedItem], in dataScanner: DataScannerViewController) {
            guard !didMatch else { return }
            guard let candidate = ReceiptParser.extractBillAmount(from: allItems), candidate > 0 else { return }

            if candidate == lastCandidate {
                stableCount += 1
            } else {
                lastCandidate = candidate
                stableCount = 1
            }

            guard stableCount >= requiredStableCount else { return }

            didMatch = true
            dataScanner.stopScanning()
            onAmount(candidate)
        }
    }
}
