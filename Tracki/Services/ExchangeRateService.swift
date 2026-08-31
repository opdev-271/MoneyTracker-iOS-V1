//
//  ExchangeRateService.swift
//  Tracki
//

import Foundation
import Observation

/// Cached currency exchange rates (units per 1 EUR), refreshed in the
/// background on app start from the ECB daily feed. Seeded with rough
/// fallback rates so conversion is never wildly wrong even before the first
/// successful fetch (A5).
@Observable
final class ExchangeRateService {
    private(set) var rates: [String: Double]
    private(set) var lastUpdated: Date?

    private let defaults: UserDefaults
    private static let feedURL = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")!
    private static let fallbackRates: [String: Double] = ["EUR": 1, "USD": 1.08, "GBP": 0.85, "CZK": 25]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded = Self.fallbackRates
        for code in loaded.keys {
            let stored = defaults.double(forKey: "rate_\(code)")
            if stored > 0 { loaded[code] = stored }
        }
        self.rates = loaded
        let millis = defaults.double(forKey: "last_updated_millis")
        self.lastUpdated = millis > 0 ? Date(timeIntervalSince1970: millis) : nil
    }

    func rateRelativeToEUR(_ currencyCode: String) -> Double {
        if currencyCode == "EUR" { return 1 }
        return rates[currencyCode] ?? Self.fallbackRates[currencyCode] ?? 1
    }

    /// Fetches fresh ECB rates. Fails silently on any error, leaving the
    /// cached/fallback rates in place — offline use must never break (A5).
    func refresh() async {
        var request = URLRequest(url: Self.feedURL)
        request.timeoutInterval = 8
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }

        let parsed = Self.parseECBRates(xml: data)
        guard !parsed.isEmpty else { return }

        var updated = parsed
        updated["EUR"] = 1
        rates = updated
        let now = Date.now
        lastUpdated = now
        persist(updated, at: now)
    }

    private func persist(_ rates: [String: Double], at date: Date) {
        for (code, rate) in rates {
            defaults.set(rate, forKey: "rate_\(code)")
        }
        defaults.set(date.timeIntervalSince1970, forKey: "last_updated_millis")
    }

    private static func parseECBRates(xml data: Data) -> [String: Double] {
        let delegate = ECBRateParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        // Foundation's XMLParser does not resolve external entities/DTDs by
        // default, so no extra XXE hardening is needed here.
        parser.parse()
        return delegate.rates
    }
}

private final class ECBRateParserDelegate: NSObject, XMLParserDelegate {
    var rates: [String: Double] = [:]

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        guard elementName == "Cube",
              let currency = attributeDict["currency"],
              let rateString = attributeDict["rate"],
              let rate = Double(rateString) else { return }
        rates[currency] = rate
    }
}
