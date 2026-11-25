//
//  GlassUI.swift
//  Tippy
//
//  Created by Codex on 5/8/26.
//

import SwiftUI
import UIKit

/// Shared corner radii so every container reads as one family.
enum GlassRadius {
    /// Top-level section panels.
    static let panel: CGFloat = 22
    /// Rows and controls inside a panel.
    static let inner: CGFloat = 12
}

/// The content layer: an opaque grouped surface. Liquid Glass is reserved for elements that
/// float above content (bars, toasts, controls), so cards never use it.
struct ContentCardModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let cornerRadius: CGFloat
    let highlight: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(Color(.secondarySystemGroupedBackground), in: shape)
            .overlay {
                if let highlight {
                    shape.strokeBorder(highlight, lineWidth: 1.5)
                } else if colorSchemeContrast == .increased {
                    shape.strokeBorder(.primary.opacity(0.4), lineWidth: 1)
                }
            }
    }
}

/// The functional layer: Liquid Glass on iOS 26, a material on earlier versions.
struct FloatingGlassModifier<S: Shape>: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.regularMaterial, in: shape)
            .overlay {
                shape.stroke(.primary.opacity(colorSchemeContrast == .increased ? 0.45 : 0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
    }
}

private struct GlassButtonStyleModifier: ViewModifier {
    let prominent: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    @ViewBuilder
    private func fallback(_ content: Content) -> some View {
        if prominent {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

/// Dismisses a sheet: the iOS 26 close button, or "Done" on earlier versions.
struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
                .accessibilityIdentifier("Done")
        } else {
            Button(String(localized: "Done"), action: action)
                .accessibilityIdentifier("Done")
        }
#else
        Button(String(localized: "Done"), action: action)
            .accessibilityIdentifier("Done")
#endif
    }
}

extension View {
    /// An opaque card for content. `highlight` draws an accent edge, e.g. for focus.
    func contentCard(cornerRadius: CGFloat = GlassRadius.panel, highlight: Color? = nil) -> some View {
        modifier(ContentCardModifier(cornerRadius: cornerRadius, highlight: highlight))
    }

    /// Liquid Glass for an element that floats above content.
    func floatingGlass<S: Shape>(in shape: S) -> some View {
        modifier(FloatingGlassModifier(shape: shape))
    }

    func glassButtonStyle() -> some View {
        modifier(GlassButtonStyleModifier(prominent: false))
    }

    func glassProminentButtonStyle() -> some View {
        modifier(GlassButtonStyleModifier(prominent: true))
    }

    /// A round glass button, for icon-only controls.
    @ViewBuilder
    func glassCircleButtonStyle() -> some View {
        if #available(iOS 17.0, *) {
            glassButtonStyle().buttonBorderShape(.circle)
        } else {
            glassButtonStyle().buttonBorderShape(.capsule)
        }
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

/// A labeled figure. Drawn without its own container so it can sit inside a panel
/// without nesting boxes; primacy comes from type size and weight.
struct MetricCard: View {
    let title: String
    let value: String
    var prominence: Prominence = .regular
    var accentColor: Color? = nil

    enum Prominence: Equatable {
        case regular
        case primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(prominence == .primary ? .largeTitle.weight(.bold) : .title2.weight(.semibold))
                .foregroundStyle(prominence == .primary ? (accentColor ?? .primary) : .primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .animatedTextChange(value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// A toast that reports a change and offers to reverse it.
struct TipSavvyUndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            toastIcon(systemName: "arrow.uturn.backward", tint: .secondary)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(String(localized: "Undo"), action: onUndo)
                .font(.subheadline.weight(.bold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("Undo")
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .liquidGlassToast()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Undo Banner")
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

private struct LiquidGlassToastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let highContrast: Bool

    func body(content: Content) -> some View {
        let shape = Capsule(style: .continuous)
        content
            .floatingGlass(in: shape)
            .overlay {
                if highContrast || colorSchemeContrast == .increased {
                    shape.strokeBorder(.primary.opacity(0.45), lineWidth: 1.5)
                }
            }
    }
}

private extension View {
    func liquidGlassToast(highContrast: Bool = false) -> some View {
        modifier(LiquidGlassToastModifier(highContrast: highContrast))
    }
}

private func toastIcon(systemName: String, tint: some ShapeStyle) -> some View {
    Image(systemName: systemName)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(tint)
        .frame(width: 30, height: 30)
        .background(.primary.opacity(0.08), in: Circle())
        .accessibilityHidden(true)
}
