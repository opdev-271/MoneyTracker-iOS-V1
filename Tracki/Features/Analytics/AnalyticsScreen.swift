//
//  AnalyticsScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData
import Charts

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case day, week, month, year
    var id: String { rawValue }
    var label: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}

private struct CashFlowPoint: Identifiable {
    let id = UUID()
    let bucketStart: Date
    let income: Double
    let expense: Double
}

private struct CategorySlice: Identifiable {
    let id: UUID
    let name: String
    let color: Color
    let total: Double
}

/// A6.6. Deliberately fixes the Android build's known bug (A11.1) — amounts
/// here are converted to `preferredCurrency` before summing/charting instead
/// of being added up raw across mixed currencies.
struct AnalyticsScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(ExchangeRateService.self) private var exchangeRates
    @Query(sort: \Profile.sortOrder) private var profiles: [Profile]
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]

    @State private var period: AnalyticsPeriod = .month
    @State private var selectedAccountIDs: Set<UUID> = []

    private var currentProfile: Profile? {
        profiles.first { $0.id == appSettings.activeProfileID } ?? profiles.first
    }

    private var profileAccounts: [Account] {
        guard let pid = currentProfile?.id else { return [] }
        return allAccounts.filter { $0.profile?.id == pid }
    }

    private var filterAccounts: [Account] {
        selectedAccountIDs.isEmpty ? profileAccounts : profileAccounts.filter { selectedAccountIDs.contains($0.id) }
    }

    private var calendar: Calendar { .current }

    private var currentRange: (start: Date, end: Date) { range(for: period, endingAt: .now) }

    private var previousRange: (start: Date, end: Date) {
        let length = currentRange.end.timeIntervalSince(currentRange.start)
        return (currentRange.start.addingTimeInterval(-length), currentRange.start)
    }

    private var periodTransactions: [Transaction] {
        let ids = Set(filterAccounts.map(\.id))
        return allTransactions.filter { tx in
            guard let aid = tx.account?.id, ids.contains(aid) else { return false }
            return tx.date >= currentRange.start && tx.date < currentRange.end
        }
    }

    private var previousPeriodExpense: Double {
        let ids = Set(filterAccounts.map(\.id))
        let txs = allTransactions.filter { tx in
            guard let aid = tx.account?.id, ids.contains(aid), tx.type == .expense else { return false }
            return tx.date >= previousRange.start && tx.date < previousRange.end
        }
        return sum(txs)
    }

    private var totalIncome: Double { sum(periodTransactions.filter { $0.type == .income }) }
    private var totalExpense: Double { sum(periodTransactions.filter { $0.type == .expense }) }

    private var trendPercent: Double? {
        guard previousPeriodExpense > 0 else { return nil }
        return ((totalExpense - previousPeriodExpense) / previousPeriodExpense) * 100
    }

    private var periodLabel: String {
        switch period {
        case .day:
            return currentRange.start.formatted(date: .long, time: .omitted)
        case .week:
            let end = calendar.date(byAdding: .day, value: -1, to: currentRange.end) ?? currentRange.end
            return "\(currentRange.start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month().year()))"
        case .month:
            return currentRange.start.formatted(.dateTime.month(.wide).year())
        case .year:
            return currentRange.start.formatted(.dateTime.year())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.l) {
                        GlassSegmentedPicker(
                            options: AnalyticsPeriod.allCases.map { ($0, $0.label) },
                            selection: $period
                        )

                        Text(periodLabel.capitalized(with: nil))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Tokens.textSecondary)

                        if profileAccounts.count > 1 {
                            accountChips
                        }

                        statsCard

                        if let trendPercent {
                            trendBanner(trendPercent)
                        }

                        ContentCard {
                            VStack(alignment: .leading, spacing: Space.s) {
                                Text("Cash flow").font(.headline).foregroundStyle(Tokens.textPrimary)
                                if periodTransactions.isEmpty {
                                    EmptyState(systemImage: "chart.line.uptrend.xyaxis", text: "No activity in this period")
                                } else {
                                    cashFlowChart
                                }
                            }
                        }

                        ContentCard {
                            VStack(alignment: .leading, spacing: Space.s) {
                                Text("Expenses by category").font(.headline).foregroundStyle(Tokens.textPrimary)
                                if categorySlices.isEmpty {
                                    EmptyState(systemImage: "chart.pie", text: "No expenses in this period")
                                } else {
                                    pieChart
                                    legend
                                }
                            }
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: Sections

    private var accountChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s) {
                AccountChip(label: "All", color: nil, isSelected: selectedAccountIDs.isEmpty) {
                    selectedAccountIDs = []
                }
                ForEach(profileAccounts) { account in
                    AccountChip(
                        label: DisplayNameResolver.resolve(account.name, language: appSettings.language),
                        color: Color(hex: account.colorHex),
                        isSelected: selectedAccountIDs.contains(account.id)
                    ) {
                        toggle(account.id)
                    }
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedAccountIDs.contains(id) {
            selectedAccountIDs.remove(id)
        } else {
            selectedAccountIDs.insert(id)
        }
    }

    private var statsCard: some View {
        ContentCard {
            HStack {
                statColumn(title: "Income", value: totalIncome, color: Tokens.income)
                Divider().frame(height: 40).overlay(Tokens.hairline)
                statColumn(title: "Expenses", value: totalExpense, color: Tokens.expense)
            }
        }
    }

    private func statColumn(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Tokens.textSecondary)
            Text(CurrencyFormatter.format(value, appSettings.preferredCurrency))
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func trendBanner(_ percent: Double) -> some View {
        let higher = percent >= 0
        return HStack(spacing: Space.s) {
            Image(systemName: higher ? "arrow.up.right" : "arrow.down.right")
                .foregroundStyle(higher ? Tokens.expense : Tokens.income)
            Text("Expenses \(abs(percent).formatted(.number.precision(.fractionLength(0))))% \(higher ? "higher" : "lower") than last period")
                .font(.footnote)
                .foregroundStyle(Tokens.textSecondary)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.s)
        .background {
            Capsule().fill(Tokens.surfaceSunken)
        }
    }

    // MARK: Line chart

    private var cashFlowPoints: [CashFlowPoint] {
        buckets(period: period, range: currentRange, transactions: periodTransactions)
    }

    private var cashFlowChart: some View {
        Chart {
            ForEach(cashFlowPoints) { point in
                LineMark(x: .value("Time", point.bucketStart), y: .value("Income", point.income), series: .value("Series", "Income"))
                    .foregroundStyle(Tokens.income)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Time", point.bucketStart), y: .value("Income", point.income), series: .value("Series", "Income"))
                    .foregroundStyle(LinearGradient(colors: [Tokens.income.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(cashFlowPoints) { point in
                LineMark(x: .value("Time", point.bucketStart), y: .value("Expense", point.expense), series: .value("Series", "Expense"))
                    .foregroundStyle(Tokens.expense)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Time", point.bucketStart), y: .value("Expense", point.expense), series: .value("Series", "Expense"))
                    .foregroundStyle(LinearGradient(colors: [Tokens.expense.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartLegend(.hidden)
        .chartYAxis { AxisMarks(position: .leading) }
        .frame(height: 200)
        .animation(Motion.smooth, value: period)
    }

    // MARK: Pie chart

    private var categorySlices: [CategorySlice] {
        let expenses = periodTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category?.id }
        return grouped.compactMap { _, txs -> CategorySlice? in
            guard let category = txs.first?.category else { return nil }
            return CategorySlice(
                id: category.id,
                name: DisplayNameResolver.resolve(category.name, language: appSettings.language),
                color: Color(hex: category.colorHex),
                total: sum(txs)
            )
        }
        .sorted { $0.total > $1.total }
    }

    private var pieChart: some View {
        Chart(categorySlices) { slice in
            SectorMark(angle: .value("Total", slice.total), innerRadius: .ratio(0.58), angularInset: 2)
                .foregroundStyle(slice.color)
                .cornerRadius(4)
        }
        .frame(height: 220)
        .animation(Motion.smooth, value: period)
    }

    private var legend: some View {
        FlowLayoutStub(slices: categorySlices, preferredCurrency: appSettings.preferredCurrency)
    }

    // MARK: Helpers

    private func convertedAmount(_ tx: Transaction) -> Double {
        CurrencyConverter.convert(
            tx.amount,
            from: tx.account?.currencyCode ?? appSettings.preferredCurrency,
            to: appSettings.preferredCurrency,
            rates: exchangeRates
        )
    }

    private func sum(_ txs: [Transaction]) -> Double {
        txs.reduce(0) { $0 + convertedAmount($1) }
    }

    private func range(for period: AnalyticsPeriod, endingAt now: Date) -> (start: Date, end: Date) {
        switch period {
        case .day:
            let start = calendar.startOfDay(for: now)
            return (start, calendar.date(byAdding: .day, value: 1, to: start) ?? start)
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, calendar.date(byAdding: .day, value: 7, to: start) ?? start)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return (start, calendar.date(byAdding: .month, value: 1, to: start) ?? start)
        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            return (start, calendar.date(byAdding: .year, value: 1, to: start) ?? start)
        }
    }

    private func buckets(period: AnalyticsPeriod, range: (start: Date, end: Date), transactions: [Transaction]) -> [CashFlowPoint] {
        func point(_ bucketStart: Date, _ bucketEnd: Date) -> CashFlowPoint {
            let inRange = transactions.filter { $0.date >= bucketStart && $0.date < bucketEnd }
            return CashFlowPoint(
                bucketStart: bucketStart,
                income: sum(inRange.filter { $0.type == .income }),
                expense: sum(inRange.filter { $0.type == .expense })
            )
        }

        switch period {
        case .day:
            return (0..<24).compactMap { hour in
                guard let start = calendar.date(byAdding: .hour, value: hour, to: range.start),
                      let end = calendar.date(byAdding: .hour, value: 1, to: start) else { return nil }
                return point(start, end)
            }
        case .week:
            return (0..<7).compactMap { day in
                guard let start = calendar.date(byAdding: .day, value: day, to: range.start),
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
                return point(start, end)
            }
        case .month:
            let days = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 30
            return (0..<max(days, 1)).compactMap { day in
                guard let start = calendar.date(byAdding: .day, value: day, to: range.start),
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
                return point(start, end)
            }
        case .year:
            return (0..<12).compactMap { month in
                guard let start = calendar.date(byAdding: .month, value: month, to: range.start),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
                return point(start, end)
            }
        }
    }
}

/// Simple horizontal-wrap legend for the pie chart.
private struct FlowLayoutStub: View {
    let slices: [CategorySlice]
    let preferredCurrency: String

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Space.xs) {
            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    Circle().fill(slice.color).frame(width: 8, height: 8)
                    Text(slice.name)
                        .font(.caption2)
                        .foregroundStyle(Tokens.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
