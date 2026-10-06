//
//  HostInsightsPlaceholderView.swift
//  Encore
//

import SwiftUI
import Charts

// Keep the original name so HostProfileView navigation link doesn't break.
struct HostInsightsPlaceholderView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager

    @State private var rentals: [Rental] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rentals.isEmpty {
                MemphisEmptyView(
                    icon: "chart.bar.fill",
                    circleColor: Color.encoreBlue,
                    accentColor: Color.encoreAccent,
                    secondAccent: Color.encorePrimary,
                    title: language.sp ? "Sin datos todavía" : "No data yet",
                    subtitle: language.sp ? "¡Crea tu primer anuncio para ver tus estadísticas!" : "Create your first listing to see your insights."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCards
                        revenueCard
                        statusCard
                        topInstrumentsCard
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Strings.insights(language.sp))
        .task { await loadRentals() }
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            InsightCard(
                title: language.sp ? "Ingresos totales" : "Total Revenue",
                value: "₡\(formattedTotal)",
                icon: "coloncurrencysign.circle.fill",
                color: .green
            )
            InsightCard(
                title: language.sp ? "Reservas totales" : "Total Bookings",
                value: "\(rentals.count)",
                icon: "calendar.badge.checkmark",
                color: Color.encorePrimary
            )
        }
    }

    private var formattedTotal: String {
        let total = rentals
            .filter { $0.status == .completed }
            .reduce(Decimal(0)) { $0 + $1.totalPrice }
        let n = NSDecimalNumber(decimal: total)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: n) ?? "\(n)"
    }

    // MARK: - Revenue by month

    private var revenueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.sp ? "Ingresos por mes" : "Revenue by Month")
                .font(.headline)
                .foregroundStyle(Color.encoreText)

            let data = revenueByMonth()
            if data.isEmpty {
                Text(language.sp ? "Sin ingresos completados aún." : "No completed revenue yet.")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.label),
                        y: .value("Revenue", item.amount)
                    )
                    .foregroundStyle(Color.encorePrimary)
                    .cornerRadius(4)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Bookings by status

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.sp ? "Reservas por estado" : "Bookings by Status")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.encoreText)

            ForEach(statusCounts(), id: \.status) { item in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(item.color.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                    }
                    Text(item.status.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    Text("\(item.count)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.encoreText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(item.color.opacity(0.2))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(item.color, lineWidth: 1))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.encoreLightPurple)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary, lineWidth: 1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: CGFloat(item.count) / CGFloat(max(rentals.count, 1)) * geo.size.width)
                        }
                    }
                    .frame(width: 80, height: 10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Top instruments

    private var topInstrumentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.sp ? "Instrumentos más alquilados" : "Top Instruments")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.encoreText)

            let top = topInstruments()
            if top.isEmpty {
                Text(language.sp ? "Sin datos aún." : "No data yet.")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
            } else {
                let palette: [Color] = [Color.encoreAccent, Color.encorePrimary, Color.encorePink, Color.encoreTeal, Color.encoreOrange]
                ForEach(Array(top.enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(palette[idx % palette.count])
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                .memphisShadow(x: 1, y: 1)
                            Text("\(idx + 1)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.black)
                        }
                        Text(item.emoji)
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                            .lineLimit(1)
                        Spacer()
                        Text(language.sp ? "\(item.count) alq." : "\(item.count) rentals")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Data helpers

    private struct MonthRevenue: Identifiable {
        let id: String
        let label: String
        let amount: Double
    }

    private func revenueByMonth() -> [MonthRevenue] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let cutoff = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let labelFmt = DateFormatter()
        labelFmt.dateFormat = "MMM"

        var grouped: [String: Double] = [:]
        var order: [String] = []

        for i in (0..<6).reversed() {
            if let month = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let key = labelFmt.string(from: month)
                if grouped[key] == nil {
                    grouped[key] = 0
                    order.append(key)
                }
            }
        }

        for rental in rentals where rental.status == .completed {
            guard let dateStr = rental.createdAt?.prefix(10).description,
                  let date = formatter.date(from: dateStr),
                  date >= cutoff else { continue }
            let key = labelFmt.string(from: date)
            grouped[key, default: 0] += NSDecimalNumber(decimal: rental.totalPrice).doubleValue
        }

        return order.map { MonthRevenue(id: $0, label: $0, amount: grouped[$0] ?? 0) }
    }

    private struct StatusCount {
        let status: String
        let count: Int
        let color: Color
    }

    private func statusCounts() -> [StatusCount] {
        let colorMap: [RentalStatus: Color] = [
            .pending: .orange,
            .confirmed: Color.encorePrimary,
            .active: .green,
            .completed: .gray,
            .cancelled: .red
        ]
        return RentalStatus.allCases.compactMap { s in
            let count = rentals.filter { $0.status == s }.count
            guard count > 0 else { return nil }
            return StatusCount(status: s.rawValue, count: count, color: colorMap[s] ?? .gray)
        }
    }

    private struct InstrumentCount {
        let name: String
        let emoji: String
        let count: Int
    }

    private func topInstruments() -> [InstrumentCount] {
        var counts: [String: (emoji: String, count: Int)] = [:]
        for r in rentals {
            let name = r.instrumentName ?? "Unknown"
            let emoji = r.instrumentEmoji ?? "🎸"
            counts[name] = (emoji, (counts[name]?.count ?? 0) + 1)
        }
        return counts.map { InstrumentCount(name: $0.key, emoji: $0.value.emoji, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Load

    private func loadRentals() async {
        guard let uid = auth.session?.userId else {
            await MainActor.run { isLoading = false }
            return
        }
        do {
            let query = [URLQueryItem(name: "host_id", value: "eq.\(uid.uuidString)")]
            let list: [Rental] = try await SupabaseClient.shared.fetch(table: "rentals", query: query)
            await MainActor.run { rentals = list; isLoading = false }
        } catch {
            print("[HostInsights] load failed: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Insight summary card

private struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(Color.encoreText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.encoreTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
    }
}
