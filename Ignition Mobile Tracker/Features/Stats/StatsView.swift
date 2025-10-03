//
//  StatsView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct StatsView: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingError = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Settimana"
        case month = "Mese"
        case year = "Anno"
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Overview Cards
                    overviewSection
                    
                    // Charts Section
                    chartsSection
                    
                    // Category Breakdown
                    categoryBreakdownSection
                    
                    // Insights Section
                    insightsSection
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(.horizontal, IgnitionSpacing.md)
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Statistiche")
        .navigationBarTitleDisplayMode(.large)
        .alert("Errore", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(sparkManager.error ?? "Si è verificato un errore imprevisto")
        }
        .onChange(of: sparkManager.error) { _, error in
            showingError = error != nil
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        Picker("Periodo", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.sm)
        .onChange(of: selectedTimeRange) { _, _ in
            audioHapticsManager.playSelectionHaptic()
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: IgnitionSpacing.md) {
            let filteredSparks = sparksForTimeRange()
            let (totalSparks, totalPoints, totalOverloads) = userProfileManager.getTotalStats()
            let (currentStreak, longestStreak) = userProfileManager.getStreakInfo()
            
            overviewCard(
                title: "Spark \(selectedTimeRange.rawValue)",
                value: "\(filteredSparks.count)",
                icon: "sparkles",
                color: themeManager.primaryColor
            )
            
            overviewCard(
                title: "Punti Totali",
                value: formatNumber(totalPoints),
                icon: "star.fill",
                color: .yellow
            )
            
            overviewCard(
                title: "Streak Attuale",
                value: "\(currentStreak)",
                icon: "flame.fill",
                color: .red
            )
            
            overviewCard(
                title: "Overload",
                value: "\(totalOverloads)",
                icon: "bolt.fill",
                color: IgnitionColors.warning
            )
        }
    }
    
    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: IgnitionSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(IgnitionFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(title)
                .font(IgnitionFonts.caption1)
                .foregroundColor(IgnitionColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.md)
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Andamento Spark")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            // Simple chart placeholder
            chartPlaceholder
        }
    }
    
    private var chartPlaceholder: some View {
        VStack(spacing: IgnitionSpacing.md) {
            let chartData = generateChartData()
            let maxValue = chartData.map(\.value).max() ?? 1
            
            // Real chart data visualization
            HStack(alignment: .bottom, spacing: IgnitionSpacing.xs) {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
                    VStack(spacing: IgnitionSpacing.xs) {
                        Rectangle()
                            .fill(themeManager.primaryColor)
                            .frame(width: 30, height: max(10, CGFloat(dataPoint.value) / CGFloat(maxValue) * 80))
                            .cornerRadius(4)
                        
                        Text(dataPoint.label)
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(IgnitionSpacing.lg)
            .background(themeManager.cardColor)
            .cornerRadius(IgnitionRadius.md)
            
            // Chart legend
            HStack {
                Text("Spark per giorno")
                    .font(IgnitionFonts.caption1)
                    .foregroundColor(IgnitionColors.secondaryText)
                
                Spacer()
                
                Text("Max: \(maxValue)")
                    .font(IgnitionFonts.caption1)
                    .foregroundColor(themeManager.primaryColor)
            }
        }
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Breakdown per Categoria")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: IgnitionSpacing.sm) {
                ForEach(SparkCategory.allCases, id: \.self) { category in
                    categoryRow(category)
                }
            }
        }
    }
    
    private func categoryRow(_ category: SparkCategory) -> some View {
        let filteredSparks = sparksForTimeRange()
        let count = filteredSparks.filter { $0.category == category }.count
        let total = filteredSparks.count
        let percentage = total > 0 ? Double(count) / Double(total) : 0.0
        
        return HStack(spacing: IgnitionSpacing.md) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text(category.displayName)
                        .font(IgnitionFonts.body)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                }
                
                ProgressView(value: percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.primaryColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.sm)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Insights")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: IgnitionSpacing.sm) {
                ForEach(generateInsights(), id: \.title) { insight in
                    insightCard(
                        icon: insight.icon,
                        title: insight.title,
                        description: insight.description,
                        color: insight.color
                    )
                }
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: IgnitionSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(title)
                    .font(IgnitionFonts.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(IgnitionFonts.caption1)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.sm)
    }
    
    // MARK: - Helper Methods
    private func sparksForTimeRange() -> [SparkModel] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return sparkManager.sparks(from: startDate, to: now)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func generateChartData() -> [StatsChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let filteredSparks = sparksForTimeRange()
        
        var dataPoints: [StatsChartDataPoint] = []
        
        switch selectedTimeRange {
        case .week:
            // Last 7 days
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
                
                let count = filteredSparks.filter { spark in
                    spark.createdAt >= dayStart && spark.createdAt < dayEnd
                }.count
                
                let formatter = DateFormatter()
                formatter.dateFormat = "E"
                let label = formatter.string(from: date)
                
                dataPoints.append(StatsChartDataPoint(value: Double(count), label: label, color: themeManager.primaryColor))
            }
            dataPoints.reverse()
            
        case .month:
            // Last 4 weeks
            for i in 0..<4 {
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) ?? now
                let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
                
                let count = filteredSparks.filter { spark in
                    spark.createdAt >= weekStart && spark.createdAt < weekEnd
                }.count
                
                dataPoints.append(StatsChartDataPoint(value: Double(count), label: "S\(4-i)", color: themeManager.primaryColor))
            }
            dataPoints.reverse()
            
        case .year:
            // Last 12 months
            for i in 0..<12 {
                let monthStart = calendar.date(byAdding: .month, value: -i, to: now) ?? now
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                
                let count = filteredSparks.filter { spark in
                    spark.createdAt >= monthStart && spark.createdAt < monthEnd
                }.count
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let label = formatter.string(from: monthStart)
                
                dataPoints.append(StatsChartDataPoint(value: Double(count), label: label, color: themeManager.primaryColor))
            }
            dataPoints.reverse()
        }
        
        return dataPoints
    }
    
    private func generateInsights() -> [StatsInsightData] {
        let filteredSparks = sparksForTimeRange()
        var insights: [StatsInsightData] = []
        
        // Peak hour insight
        if !filteredSparks.isEmpty {
            let hourCounts = Dictionary(grouping: filteredSparks) { spark in
                Calendar.current.component(.hour, from: spark.createdAt)
            }.mapValues { $0.count }
            
            if let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key {
                insights.append(StatsInsightData(
                    icon: "clock.fill",
                    title: "Orario di Picco",
                    description: "Sei più produttivo alle \(peakHour):00",
                    color: .blue
                ))
            }
        }
        
        // Favorite category insight
        if !filteredSparks.isEmpty {
            let categoryCounts = Dictionary(grouping: filteredSparks) { $0.category }
                .mapValues { $0.count }
            
            if let favoriteCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
                insights.append(StatsInsightData(
                    icon: "trophy.fill",
                    title: "Categoria Preferita",
                    description: "Hai creato più spark nella categoria \(favoriteCategory.displayName)",
                    color: .yellow
                ))
            }
        }
        
        // Streak insight
        let (currentStreak, longestStreak) = userProfileManager.getStreakInfo()
        if currentStreak > 0 {
            insights.append(StatsInsightData(
                icon: "flame.fill",
                title: "Streak Attiva",
                description: currentStreak == longestStreak ? 
                    "Hai raggiunto il tuo record di \(currentStreak) giorni!" :
                    "Continua così! Record da battere: \(longestStreak) giorni",
                color: currentStreak == longestStreak ? .green : .orange
            ))
        }
        
        // Fuel gauge insight
        let fuelPercentage = userProfileManager.getCurrentFuelPercentage()
        if fuelPercentage > 0.8 {
            insights.append(StatsInsightData(
                icon: "bolt.fill",
                title: "Energia Alta",
                description: "Il tuo Fuel Gauge è all'\(Int(fuelPercentage * 100))%! Overload imminente!",
                color: IgnitionColors.warning
            ))
        }
        
        // If no specific insights, add a motivational one
        if insights.isEmpty {
            insights.append(StatsInsightData(
                icon: "sparkles",
                title: "Inizia il Viaggio",
                description: "Crea il tuo primo spark per vedere insights personalizzati",
                color: themeManager.primaryColor
            ))
        }
        
        return insights
    }
}

// MARK: - Data Models
struct StatsChartDataPoint {
    let value: Double
    let label: String
    let color: Color
}

struct StatsInsightData {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview
#Preview {
    StatsView()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
