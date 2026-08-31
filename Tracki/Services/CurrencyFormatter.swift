//
//  CurrencyFormatter.swift
//  Tracki
//

import Foundation

/// Formats amounts as "1,234.56" plus a currency symbol, **independent of
/// device locale** — this is deliberate (A5), not a bug: the app's own
/// formatting must stay predictable regardless of which language the user
/// has picked inside the app.
enum CurrencyFormatter {
    private static let symbols: [String: String] = [
        "CZK": "Kč", "EUR": "€", "USD": "$", "GBP": "£",
    ]

    static let supportedCurrencyCodes = ["CZK", "EUR", "USD", "GBP"]

    static func symbol(for currencyCode: String?) -> String {
        guard let currencyCode else { return "" }
        return symbols[currencyCode] ?? currencyCode
    }

    private static func numberFormatter(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter
    }

    /// e.g. `"$34,567.90"` or `"34,567.90 Kč"`. Sign is always on the far left.
    static func format(_ amount: Double, _ currencyCode: String?) -> String {
        let number = numberFormatter(fractionDigits: 2).string(from: NSNumber(value: abs(amount))) ?? "0.00"
        let symbol = symbol(for: currencyCode)
        let sign = amount < 0 ? "-" : ""
        return symbol == "Kč" ? "\(sign)\(number) \(symbol)" : "\(sign)\(symbol)\(number)"
    }

    /// e.g. `"+$1,923"` or `"-1,532 Kč"` — no decimals, always signed. Used on
    /// transaction rows.
    static func formatSigned(_ signedAmount: Double, _ currencyCode: String?) -> String {
        let number = numberFormatter(fractionDigits: 0).string(from: NSNumber(value: abs(signedAmount))) ?? "0"
        let symbol = symbol(for: currencyCode)
        let sign = signedAmount < 0 ? "-" : "+"
        return symbol == "Kč" ? "\(sign)\(number) \(symbol)" : "\(sign)\(symbol)\(number)"
    }
}
