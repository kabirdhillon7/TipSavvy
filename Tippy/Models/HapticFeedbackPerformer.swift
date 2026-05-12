//
//  HapticFeedbackPerformer.swift
//  Tippy
//
//  Created by Codex on 5/12/26.
//

import UIKit

enum HapticFeedbackPerformer {
    static func selection(isEnabled: Bool) {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func lightImpact(isEnabled: Bool) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func softImpact(isEnabled: Bool) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success(isEnabled: Bool) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(isEnabled: Bool) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
