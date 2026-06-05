//
//  GlassUI.swift
//  Tippy
//
//  Created by Codex on 5/8/26.
//

import SwiftUI
import UIKit

struct GlassPanelModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let cornerRadius: CGFloat
    let interactive: Bool
    let highContrast: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let useHighContrast = highContrast || colorSchemeContrast == .increased

#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(interactive), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.primary.opacity(useHighContrast ? 0.45 : 0.18), lineWidth: useHighContrast ? 1.5 : 1)
                }
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.primary.opacity(useHighContrast ? 0.5 : 0.18), lineWidth: useHighContrast ? 1.5 : 1)
                }
                .shadow(color: .primary.opacity(useHighContrast ? 0.05 : 0.08), radius: 12, y: 6)
        }
#else
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(useHighContrast ? 0.5 : 0.18), lineWidth: useHighContrast ? 1.5 : 1)
            }
            .shadow(color: .primary.opacity(useHighContrast ? 0.05 : 0.08), radius: 12, y: 6)
#endif
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 18, interactive: Bool = false, highContrast: Bool = false) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, interactive: interactive, highContrast: highContrast))
    }

    func toastOverlay<Toast: View>(isPresented: Bool, @ViewBuilder content: () -> Toast) -> some View {
        modifier(ToastOverlayModifier(isPresented: isPresented, toast: content()))
    }

    func animatedTextChange<Value: Equatable>(value: Value) -> some View {
        modifier(AnimatedTextChangeModifier(value: value))
    }
}

private struct ToastOverlayModifier<Toast: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPresented: Bool
    let toast: Toast

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    toast
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(toastTransition)
                        .zIndex(1)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86), value: isPresented)
    }

    private var toastTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .opacity.combined(with: .move(edge: .top))
    }
}

private struct AnimatedTextChangeModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Value

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else if #available(iOS 17.0, *) {
            content
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.22), value: value)
        } else {
            content
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.18), value: value)
        }
    }
}

struct TipPresetButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let isSelected: Bool
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        let highContrast = colorSchemeContrast == .increased
        let shape = Capsule(style: .continuous)

        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? accentColor : Color.primary)
            .padding(.vertical, 9)
            .background {
                shape
                    .fill(isSelected ? accentColor.opacity(highContrast ? 0.24 : 0.14) : Color.primary.opacity(highContrast ? 0.08 : 0.04))
            }
            .overlay {
                shape
                    .strokeBorder(isSelected ? accentColor : Color.primary.opacity(highContrast ? 0.35 : 0.14), lineWidth: isSelected || highContrast ? 1.5 : 1)
            }
            .contentShape(shape)
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var prominence: Prominence = .regular

    enum Prominence: Equatable {
        case regular
        case primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(prominence == .primary ? .title2.weight(.bold) : .headline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.85)
                .animatedTextChange(value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassPanel(cornerRadius: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                titleView
                Spacer(minLength: 12)
                valueView
            }

            VStack(alignment: .leading, spacing: 3) {
                titleView
                valueView
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var titleView: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var valueView: some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .animatedTextChange(value: value)
    }
}

struct SelectedAccessibilityTraitModifier: ViewModifier {
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content.accessibilityAddTraits(.isSelected)
        } else {
            content
        }
    }
}

struct TipSavvyErrorBanner: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            toastIcon(systemName: "exclamationmark.triangle.fill", tint: .orange)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.primary.opacity(colorSchemeContrast == .increased ? 0.12 : 0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Dismiss Error"))
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .liquidGlassToast(highContrast: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Error"))
        .accessibilityValue(message)
        .accessibilityIdentifier("Error Banner")
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

struct TipSavvySuccessBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            toastIcon(systemName: "checkmark", tint: .green)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassToast()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Success"))
        .accessibilityValue(message)
        .accessibilityIdentifier("Success Banner")
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

private struct LiquidGlassToastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let highContrast: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let useHighContrast = highContrast || colorSchemeContrast == .increased
        let shape = Capsule(style: .continuous)

#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .background {
                    shape
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: shape)
                }
                .overlay {
                    shape
                        .strokeBorder(.primary.opacity(useHighContrast ? 0.45 : 0.2), lineWidth: useHighContrast ? 1.5 : 1)
                }
                .shadow(color: .black.opacity(useHighContrast ? 0.18 : 0.22), radius: 18, y: 10)
        } else {
            fallbackToast(content: content, shape: shape, useHighContrast: useHighContrast)
        }
#else
        fallbackToast(content: content, shape: shape, useHighContrast: useHighContrast)
#endif
    }

    private func fallbackToast(content: Content, shape: Capsule, useHighContrast: Bool) -> some View {
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape
                    .strokeBorder(.primary.opacity(useHighContrast ? 0.5 : 0.22), lineWidth: useHighContrast ? 1.5 : 1)
            }
            .shadow(color: .black.opacity(useHighContrast ? 0.16 : 0.2), radius: 18, y: 10)
    }
}

private extension View {
    func liquidGlassToast(highContrast: Bool = false) -> some View {
        modifier(LiquidGlassToastModifier(highContrast: highContrast))
    }
}

private func toastIcon(systemName: String, tint: Color) -> some View {
    Image(systemName: systemName)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(tint)
        .frame(width: 30, height: 30)
        .background(.primary.opacity(0.08), in: Circle())
        .accessibilityHidden(true)
}
