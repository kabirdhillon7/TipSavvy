//
//  CurrencyAmountField.swift
//  TipSavvy
//

import SwiftUI

/// Turns what someone types into an amount, and an amount back into editable text.
///
/// A `TextField(value:format: .currency)` reformats while you type, so a quick second
/// keystroke can land on the reformatted text and be lost ("24" became "$2.00"). Keeping
/// the raw text and only parsing it avoids that.
enum CurrencyInput {
    /// Keeps digits and a single decimal separator, with at most two fraction digits.
    static func sanitize(_ text: String, locale: Locale = .current) -> String {
        let separator = Character(locale.decimalSeparator ?? ".")
        var result = ""
        var sawSeparator = false
        var fractionDigits = 0
        for character in text {
            if character.isASCII, character.isNumber {
                if sawSeparator {
                    guard fractionDigits < 2 else { continue }
                    fractionDigits += 1
                }
                result.append(character)
            } else if character == separator, !sawSeparator {
                sawSeparator = true
                result.append(character)
            }
        }
        return result
    }

    static func parse(_ text: String, locale: Locale = .current) -> Double? {
        let separator = locale.decimalSeparator ?? "."
        let normalized = sanitize(text, locale: locale).replacingOccurrences(of: separator, with: ".")
        guard !normalized.isEmpty, normalized != "." else {
            return nil
        }
        return Double(normalized)
    }

    /// Plain text for an amount: "24" or "24.5" while editing, "24.00" at rest.
    static func text(for amount: Double?, padded: Bool, locale: Locale = .current) -> String {
        guard let amount else {
            return ""
        }
        let fraction = padded ? 2...2 : 0...2
        return amount.formatted(.number.precision(.fractionLength(fraction)).grouping(.never).locale(locale))
    }

    /// Whether the locale writes the currency symbol before the number ("$24" vs "24 €").
    static func symbolLeads(currencyCode: String, locale: Locale = .current) -> Bool {
        let sample = (1.0).formatted(.currency(code: currencyCode).locale(locale))
        return sample.first.map { !$0.isNumber } ?? true
    }

    static func symbol(currencyCode: String, locale: Locale = .current) -> String {
        let sample = (0.0).formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(locale))
        return sample.filter { !$0.isNumber && !$0.isWhitespace }
    }
}

/// A money field that never rewrites the text under the cursor. The currency symbol sits
/// outside the editable text, and the amount is padded to cents only once focus leaves.
struct CurrencyAmountField<Field: Hashable>: View {
    let prompt: String
    @Binding var amount: Double?
    let currencyCode: String
    let focus: FocusState<Field?>.Binding
    let field: Field

    @State private var text = ""

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        let symbolLeads = CurrencyInput.symbolLeads(currencyCode: currencyCode)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            if !text.isEmpty, symbolLeads {
                symbol
            }
            TextField(prompt, text: $text)
                .keyboardType(.decimalPad)
                .focused(focus, equals: field)
                .textFieldStyle(.plain)
            if !text.isEmpty, !symbolLeads {
                symbol
            }
        }
        .onAppear {
            text = CurrencyInput.text(for: amount, padded: !isFocused)
        }
        .onChange(of: text) { newText in
            let sanitized = CurrencyInput.sanitize(newText)
            guard sanitized == newText else {
                text = sanitized
                return
            }
            let parsed = CurrencyInput.parse(sanitized)
            if parsed != amount {
                amount = parsed
            }
        }
        .onChange(of: amount) { newAmount in
            // Reset, undo and "Use Again" change the amount from outside; only then rewrite.
            if CurrencyInput.parse(text) != newAmount {
                text = CurrencyInput.text(for: newAmount, padded: !isFocused)
            }
        }
        .onChange(of: isFocused) { focused in
            text = CurrencyInput.text(for: amount, padded: !focused)
        }
    }

    private var symbol: some View {
        Text(CurrencyInput.symbol(currencyCode: currencyCode))
            .accessibilityHidden(true)
    }
}
