//
//  CurrencyConverter.swift
//  Tracki
//

import Foundation

/// Converts between currencies via EUR as a pivot, using cached exchange rates.
enum CurrencyConverter {
    static func convert(_ amount: Double, from: String, to: String, rates: ExchangeRateService) -> Double {
        guard from != to else { return amount }
        let fromRate = rates.rateRelativeToEUR(from)
        let toRate = rates.rateRelativeToEUR(to)
        guard fromRate > 0 else { return amount }
        let amountInEUR = amount / fromRate
        return amountInEUR * toRate
    }
}
