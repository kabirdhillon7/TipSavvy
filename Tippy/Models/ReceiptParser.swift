//
//  ReceiptParser.swift
//  Tippy
//

import VisionKit

enum ReceiptParser {
    // Keywords that indicate a line likely contains the final total.
    private static let totalKeywords = ["grand total", "total due", "amount due", "balance due", "total amount", "total"]

    // Substrings that make a bare "total" match a decoy rather than the real bill total.
    private static let totalDecoys = ["subtotal", "sub total", "total savings", "total saved", "total items", "total qty"]

    // Words that signal the scanned text is actually a receipt (and not, say, source code).
    private static let receiptIndicators = ["total", "subtotal", "tax", "amount", "balance", "due", "cash", "change", "card", "visa", "mastercard", "debit", "credit", "tip", "gratuity", "receipt", "server", "check"]

    // A bill above this is almost certainly a misread (ZIP, phone, code constant), not a real total.
    private static let sanityCeiling: Double = 100_000

    /// Extracts the most likely bill total from a set of scanned text items.
    static func extractBillAmount(from items: [RecognizedItem]) -> Double? {
        extractBillAmount(fromLines: lines(from: items))
    }

    /// Pure, testable parsing entry point.
    /// Strategy:
    ///   0. Bail unless the text actually looks like a receipt (≥2 distinct indicator keywords)
    ///   1. Find the first line that contains a total keyword and a value — prefer "grand total" > … > "total"
    ///   2. Otherwise return the largest currency-formatted value on the receipt
    static func extractBillAmount(fromLines lines: [String]) -> Double? {
        guard looksLikeReceipt(lines) else { return nil }

        // Pass 1 — keyword-ranked search (looser matcher: a labeled "TOTAL 48" line is trustworthy)
        for keyword in totalKeywords {
            for line in lines {
                let lower = line.lowercased()
                guard lower.contains(keyword) else { continue }
                // The bare "total" keyword matches decoys like "subtotal"; skip those.
                if keyword == "total", totalDecoys.contains(where: { lower.contains($0) }) {
                    continue
                }
                if let value = largestValue(in: line, requirePriceFormat: false), value > 0, value <= sanityCeiling {
                    return value
                }
            }
        }

        // Pass 2 — largest price-formatted value anywhere (stricter: needs a currency symbol or 2 decimals)
        let allValues = lines.compactMap { largestValue(in: $0, requirePriceFormat: true) }
        return allValues.filter { $0 > 0 && $0 <= sanityCeiling }.max()
    }

    // MARK: - Helpers

    private static func lines(from items: [RecognizedItem]) -> [String] {
        items.compactMap { item -> String? in
            if case .text(let text) = item { return text.transcript }
            return nil
        }
    }

    /// True when the corpus contains at least 2 distinct receipt-indicator keywords.
    private static func looksLikeReceipt(_ lines: [String]) -> Bool {
        let corpus = lines.joined(separator: "\n").lowercased()
        let matched = receiptIndicators.filter { corpus.contains($0) }
        return Set(matched).count >= 2
    }

    /// Returns the largest currency-like value on a line.
    /// When `requirePriceFormat` is true, only values with a currency symbol or exactly two
    /// decimal places qualify — excluding bare integers like line numbers or quantities.
    private static func largestValue(in line: String, requirePriceFormat: Bool) -> Double? {
        // Capture: optional currency symbol, then the number. Two groups so we know if a symbol was present.
        // The integer part is either comma-grouped (1,234) or a plain greedy run (\d+) so long numbers
        // like 999999.99 are matched whole rather than fragmented into 999.99.
        let pattern = #"([\$€£¥])?\s*((?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)

        return regex.matches(in: line, range: range).compactMap { match -> Double? in
            guard let numberRange = Range(match.range(at: 2), in: line) else { return nil }
            let raw = String(line[numberRange])
            let hasSymbol = match.range(at: 1).location != NSNotFound
            let hasTwoDecimals = raw.range(of: #"\.\d{2}$"#, options: .regularExpression) != nil

            if requirePriceFormat && !hasSymbol && !hasTwoDecimals {
                return nil
            }
            return Double(raw.replacingOccurrences(of: ",", with: ""))
        }.max()
    }
}
