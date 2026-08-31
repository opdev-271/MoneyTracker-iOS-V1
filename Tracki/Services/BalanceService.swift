//
//  BalanceService.swift
//  Tracki
//

import Foundation

/// Computes account/profile balances the same way the Android SQL did (A2.7):
/// a running balance is never stored, it's `initialBalance + Σ signed
/// transaction amounts`, and envelopes hold a *subset* of a savings
/// account's balance rather than affecting it directly.
enum BalanceService {
    static func balance(for account: Account) -> Double {
        let transactionSum = (account.transactions ?? []).reduce(0.0) { $0 + $1.signedAmount }
        return account.initialBalance + transactionSum
    }

    static func envelopedTotal(for account: Account) -> Double {
        (account.envelopes ?? []).reduce(0.0) { $0 + $1.currentAmount }
    }

    static func unallocated(for account: Account) -> Double {
        balance(for: account) - envelopedTotal(for: account)
    }

    /// Home balance card total (A5): a single selected account shows in its
    /// own currency, unconverted; two or more are each converted to
    /// `preferredCurrency` before summing.
    static func totalBalance(
        accounts: [Account],
        preferredCurrency: String,
        rates: ExchangeRateService
    ) -> Double {
        if accounts.count == 1, let only = accounts.first {
            return balance(for: only)
        }
        return accounts.reduce(0.0) { partial, account in
            let converted = CurrencyConverter.convert(
                balance(for: account),
                from: account.currencyCode,
                to: preferredCurrency,
                rates: rates
            )
            return partial + converted
        }
    }
}
