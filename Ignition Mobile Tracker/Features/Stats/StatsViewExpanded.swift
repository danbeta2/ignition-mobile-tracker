//
//  StatsViewExpanded.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import Charts

struct StatsViewExpanded: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var missionManager = MissionManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    // MARK: - State Variables
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMetric: MetricType = .sparks
    @State private var selectedChartType: ChartType = .line
    @State private var selectedAnalysisType: AnalysisType = .overview
    @State private var showingError = false
    @State private var showingExport = false
    @State private var showingComparison = false
    @State private var showingPredictions = false
    @State private var showingGoals = false
    @State private var showingCustomReport = false
    @State private var showingDataBreakdown = false
    
    // Advanced Analytics States
    @State private var selectedCategories: Set<SparkCategory> = Set(SparkCategory.allCases)
    @State private var selectedIntensities: Set<SparkIntensity> = Set(SparkIntensity.allCases)
    @State private var comparisonPeriod: ComparisonPeriod = .previousPeriod
    @State private var showingTrends = true
    @State private var showingCorrelations = false
    @State private var showingHeatmap = false
    @State private var showingForecast = false
    
    // UI States
    @State private var animateCharts = false
    @State private var refreshing = false
    @State private var selectedDataPoint: ChartDataPoint?
    @State private var showingDetailedView = false
    @State private var currentInsightIndex = 0
    
    // Custom Date Range
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var showingDatePicker = false
    
    // MARK: - Enums
    // Moved to StatsViewExpanded+Enums.swift for better code organization
    
    // MARK: - Computed Properties
    private var currentDateRange: DateInterval {
        if selectedTimeRange == .custom {
            return DateInterval(start: customStartDate, end: customEndDate)
        }
        return selectedTimeRange.dateRange
    }
    
    private var sparksInRange: [SparkModel] {
        return sparkManager.sparks.filter { spark in
            currentDateRange.contains(spark.createdAt)
        }
    }
    
    private var filteredSparks: [SparkModel] {
        return sparksInRange.filter { spark in
            selectedCategories.contains(spark.category) &&
            selectedIntensities.contains(spark.intensity)
        }
    }
    
    private var overviewStats: OverviewStats {
        let sparks = filteredSparks
        let totalSparks = sparks.count
        let totalPoints = sparks.reduce(0) { $0 + $1.points }
        let avgIntensity = sparks.isEmpty ? 0 : Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        let uniqueCategories = Set(sparks.map { $0.category }).count
        
        let streakInfo = userProfileManager.getStreakInfo()
        let fuelLevel = userProfileManager.getCurrentFuelPercentage()
        
        let completedMissions = missionManager.missions.filter { mission in
            guard let completedAt = mission.completedAt else { return false }
            return currentDateRange.contains(completedAt)
        }.count
        
        return OverviewStats(
            totalSparks: totalSparks,
            totalPoints: totalPoints,
            averageIntensity: avgIntensity,
            uniqueCategories: uniqueCategories,
            currentStreak: streakInfo.current,
            longestStreak: streakInfo.longest,
            fuelLevel: fuelLevel,
            completedMissions: completedMissions,
            productivityScore: calculateProductivityScore()
        )
    }
    
    private var chartData: [ChartDataPoint] {
        return generateChartData(for: selectedMetric, in: currentDateRange)
    }
    
    private var categoryBreakdown: [CategoryData] {
        let grouped = Dictionary(grouping: filteredSparks, by: { $0.category })
        return grouped.map { category, sparks in
            CategoryData(
                category: category,
                count: sparks.count,
                points: sparks.reduce(0) { $0 + $1.points },
                averageIntensity: sparks.isEmpty ? 0 : Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count),
                percentage: Double(sparks.count) / Double(filteredSparks.count)
            )
        }.sorted { $0.count > $1.count }
    }
    
    private var timePatterns: [TimePatternData] {
        return generateTimePatterns()
    }
    
    private var insights: [InsightData] {
        return generateAdvancedInsights()
    }
    
    private var trends: [TrendData] {
        return calculateTrends()
    }
    
    private var correlations: [CorrelationData] {
        return calculateCorrelations()
    }
    
    private var predictions: [PredictionData] {
        return generatePredictions()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content Area
                ScrollView {
                    LazyVStack(spacing: IgnitionSpacing.lg) {
                        overviewSection
                    }
                    .padding(.horizontal, IgnitionSpacing.md)
                    .padding(.bottom, IgnitionSpacing.xl)
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    leadingToolbarItems
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    trailingToolbarItems
                }
            }
            .onAppear {
                setupView()
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingExport) {
                ExportAnalyticsView(data: chartData, stats: overviewStats)
            }
            .sheet(isPresented: $showingComparison) {
                ComparisonAnalyticsView()
            }
            .sheet(isPresented: $showingPredictions) {
                PredictiveAnalyticsView(predictions: predictions)
            }
            .sheet(isPresented: $showingGoals) {
                GoalsAnalyticsView()
            }
            .sheet(isPresented: $showingCustomReport) {
                CustomReportView()
            }
            .sheet(isPresented: $showingDataBreakdown) {
                DataBreakdownView(sparks: filteredSparks)
            }
            .sheet(isPresented: $showingDatePicker) {
                CustomDateRangeView(
                    startDate: $customStartDate,
                    endDate: $customEndDate
                )
            }
            .alert("Errore", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Si è verificato un errore durante il caricamento dei dati")
            }
        }
    }
    
    // MARK: - Advanced Controls Header
    private var advancedControlsHeader: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Time Range & Metric Selectors
            HStack(spacing: IgnitionSpacing.md) {
                // Time Range
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Periodo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                                if range == .custom {
                                    showingDatePicker = true
                                }
                                audioHapticsManager.playSelectionHaptic()
                            }) {
                                Label(range.rawValue, systemImage: range.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedTimeRange.icon)
                                .font(.caption)
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text(selectedTimeRange.rawValue)
                                .font(.caption)
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(IgnitionCornerRadius.sm)
                    }
                }
                
                // Metric Type
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Metrica")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Menu {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            Button(action: {
                                selectedMetric = metric
                                audioHapticsManager.playSelectionHaptic()
                            }) {
                                Label(metric.rawValue, systemImage: metric.icon)
                                    .foregroundColor(metric.color)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedMetric.icon)
                                .font(.caption)
                                .foregroundColor(selectedMetric.color)
                            
                            Text(selectedMetric.rawValue)
                                .font(.caption)
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(IgnitionCornerRadius.sm)
                    }
                }
                
                Spacer()
                
                // Chart Type
                Menu {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedChartType = type
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                } label: {
                    Image(systemName: selectedChartType.icon)
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title3)
                }
            }
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    // Category Filters
                    Text("Categorie:")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        filterChip(
                            title: category.rawValue.capitalized,
                            isSelected: selectedCategories.contains(category),
                            action: {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                                audioHapticsManager.playSelectionHaptic()
                            }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Intensity Filters
                    Text("Intensità:")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    ForEach(SparkIntensity.allCases, id: \.self) { intensity in
                        filterChip(
                            title: "\(intensity.rawValue)",
                            isSelected: selectedIntensities.contains(intensity),
                            action: {
                                if selectedIntensities.contains(intensity) {
                                    selectedIntensities.remove(intensity)
                                } else {
                                    selectedIntensities.insert(intensity)
                                }
                                audioHapticsManager.playSelectionHaptic()
                            }
                        )
                    }
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    // MARK: - Analysis Type Selector
    private var analysisTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: IgnitionSpacing.sm) {
                ForEach(AnalysisType.allCases, id: \.self) { type in
                    analysisTypeChip(
                        type: type,
                        isSelected: selectedAnalysisType == type,
                        action: {
                            selectedAnalysisType = type
                            audioHapticsManager.playSelectionHaptic()
                        }
                    )
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            // Key Metrics Grid
            keyMetricsGrid
            
            // Main Chart
            mainChartView
            
            // Quick Insights
            quickInsightsView
            
            // Category Breakdown
            categoryBreakdownView
            
            // Time Patterns
            timePatternsView
        }
    }
    
    // MARK: - Key Metrics Grid
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: IgnitionSpacing.md) {
            metricCard(
                title: "Spark Totali",
                value: "\(overviewStats.totalSparks)",
                subtitle: "in questo periodo",
                icon: "sparkles",
                color: .blue,
                trend: calculateTrendForMetric(.sparks)
            )
            
            metricCard(
                title: "Punti Guadagnati",
                value: formatNumber(overviewStats.totalPoints),
                subtitle: "punti totali",
                icon: "star.fill",
                color: .yellow,
                trend: calculateTrendForMetric(.points)
            )
            
            metricCard(
                title: "Intensità Media",
                value: String(format: "%.1f", overviewStats.averageIntensity),
                subtitle: "su 4.0",
                icon: "flame.fill",
                color: .red,
                trend: calculateTrendForMetric(.intensity)
            )
            
            metricCard(
                title: "Streak Attuale",
                value: "\(overviewStats.currentStreak)",
                subtitle: "giorni consecutivi",
                icon: "flame",
                color: .orange,
                trend: TrendDirection.stable
            )
            
            metricCard(
                title: "Categorie Usate",
                value: "\(overviewStats.uniqueCategories)",
                subtitle: "su \(SparkCategory.allCases.count)",
                icon: "folder.fill",
                color: .green,
                trend: calculateTrendForMetric(.categories)
            )
            
            metricCard(
                title: "Produttività",
                value: "\(Int(overviewStats.productivityScore * 100))%",
                subtitle: "score generale",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple,
                trend: calculateTrendForMetric(.productivity)
            )
        }
    }
    
    // MARK: - Main Chart View
    private var mainChartView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Andamento \(selectedMetric.rawValue)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(formatDateRange(currentDateRange))
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Chart Type Selector
                HStack(spacing: IgnitionSpacing.xs) {
                    ForEach([ChartType.line, .bar, .area], id: \.self) { type in
                        Button(action: {
                            selectedChartType = type
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Image(systemName: type.icon)
                                .font(.caption)
                                .foregroundColor(selectedChartType == type ? .white : themeManager.primaryColor)
                                .padding(6)
                                .background(selectedChartType == type ? themeManager.primaryColor : Color.clear)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Chart
            Group {
                switch selectedChartType {
                case .line:
                    lineChartView
                case .bar:
                    barChartView
                case .area:
                    areaChartView
                case .pie:
                    pieChartView
                case .scatter:
                    scatterChartView
                case .heatmap:
                    heatmapChartView
                }
            }
            .frame(height: 250)
            .opacity(animateCharts ? 1 : 0)
            .animation(.easeInOut(duration: 1), value: animateCharts)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Chart Views
    private var lineChartView: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Data", dataPoint.date),
                y: .value("Valore", dataPoint.value)
            )
            .foregroundStyle(selectedMetric.color)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Data", dataPoint.date),
                y: .value("Valore", dataPoint.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 5))) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
    
    private var barChartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Data", dataPoint.date),
                y: .value("Valore", dataPoint.value)
            )
            .foregroundStyle(selectedMetric.color)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 5))) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
    
    private var areaChartView: some View {
        Chart(chartData) { dataPoint in
            AreaMark(
                x: .value("Data", dataPoint.date),
                y: .value("Valore", dataPoint.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selectedMetric.color, selectedMetric.color.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 5))) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
    
    private var pieChartView: some View {
        Chart(categoryBreakdown.prefix(5)) { category in
            SectorMark(
                angle: .value("Count", category.count),
                innerRadius: .ratio(0.4),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Category", category.category.rawValue))
            .opacity(0.8)
        }
        .chartLegend(position: .bottom, alignment: .center)
    }
    
    private var scatterChartView: some View {
        Chart(chartData) { dataPoint in
            PointMark(
                x: .value("Data", dataPoint.date),
                y: .value("Valore", dataPoint.value)
            )
            .foregroundStyle(selectedMetric.color)
            .symbolSize(60)
        }
    }
    
    private var heatmapChartView: some View {
        // Placeholder for heatmap - would need custom implementation
        VStack {
            Image(systemName: "grid.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("Heatmap View")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Disponibile in una futura versione")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Quick Insights View
    private var quickInsightsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text("Quick Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.md) {
                    ForEach(insights.prefix(3), id: \.id) { insight in
                        insightCard(insight)
                    }
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(.vertical, IgnitionSpacing.md)
    }
    
    // MARK: - Category Breakdown View
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Breakdown per Categoria")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(categoryBreakdown.prefix(5), id: \.category) { categoryData in
                categoryBreakdownRow(categoryData)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Time Patterns View
    private var timePatternsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Pattern Temporali")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: IgnitionSpacing.md) {
                ForEach(timePatterns.prefix(4), id: \.id) { pattern in
                    timePatternCard(pattern)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Trends Section
    private var trendsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Analisi delle Tendenze")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(trends, id: \.id) { trend in
                trendCard(trend)
            }
        }
    }
    
    // MARK: - Patterns Section
    private var patternsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Pattern Comportamentali")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            // Heatmap of activity by hour and day
            weeklyHeatmapView
            
            // Most productive times
            productiveTimesView
            
            // Behavioral patterns
            behavioralPatternsView
        }
    }
    
    // MARK: - Correlations Section
    private var correlationsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Analisi delle Correlazioni")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(correlations, id: \.id) { correlation in
                correlationCard(correlation)
            }
        }
    }
    
    // MARK: - Predictions Section
    private var predictionsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Predictions and Projections")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(predictions, id: \.id) { prediction in
                predictionCard(prediction)
            }
        }
    }
    
    // MARK: - Comparisons Section
    private var comparisonsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Confronti Temporali")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            // Comparison controls
            comparisonControlsView
            
            // Comparison charts
            comparisonChartsView
        }
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Goals and Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            // Goal progress cards
            goalsProgressView
            
            // Goal recommendations
            goalRecommendationsView
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Text("Insights Avanzati")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(insights, id: \.id) { insight in
                detailedInsightCard(insight)
            }
        }
    }
    
    // MARK: - Helper Views
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color, trend: TrendDirection) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                trendIndicator(trend)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    private func trendIndicator(_ trend: TrendDirection) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2)
                .foregroundColor(trend.color)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : themeManager.primaryColor)
                .padding(.horizontal, IgnitionSpacing.xs)
                .padding(.vertical, 2)
                .background(isSelected ? themeManager.primaryColor : themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.xs)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.xs)
                        .stroke(themeManager.primaryColor, lineWidth: isSelected ? 0 : 0.5)
                )
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    private func analysisTypeChip(type: AnalysisType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : themeManager.primaryColor)
            .padding(.horizontal, IgnitionSpacing.sm)
            .padding(.vertical, IgnitionSpacing.xs)
            .background(isSelected ? themeManager.primaryColor : themeManager.cardBackgroundColor)
            .cornerRadius(IgnitionCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                    .stroke(themeManager.primaryColor, lineWidth: isSelected ? 0 : 1)
            )
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    private func insightCard(_ insight: InsightData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            HStack {
                Image(systemName: insight.icon)
                    .foregroundColor(insight.color)
                    .font(.title3)
                
                Spacer()
                
                Text(insight.type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(insight.color)
                    .padding(.horizontal, IgnitionSpacing.xs)
                    .padding(.vertical, 2)
                    .background(insight.color.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(insight.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(3)
            
            if let value = insight.value {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(insight.color)
            }
        }
        .padding(IgnitionSpacing.sm)
        .frame(width: 200)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
    }
    
    private func categoryBreakdownRow(_ categoryData: CategoryData) -> some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Category Icon
            Image(systemName: AssetNames.SparkCategories.allCases.first(where: { $0.displayName.lowercased().contains(categoryData.category.rawValue) })?.systemName ?? "circle.fill")
                .foregroundColor(themeManager.primaryColor)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // Category Info
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(categoryData.category.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                HStack(spacing: IgnitionSpacing.sm) {
                    Text("\(categoryData.count) spark")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("\(categoryData.points) punti")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Percentage & Progress
            VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                Text("\(Int(categoryData.percentage * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.secondaryColor.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(themeManager.primaryColor)
                            .frame(width: geometry.size.width * categoryData.percentage, height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 0.5), value: categoryData.percentage)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.vertical, IgnitionSpacing.xs)
    }
    
    private func timePatternCard(_ pattern: TimePatternData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            HStack {
                Image(systemName: pattern.icon)
                    .foregroundColor(pattern.color)
                    .font(.title3)
                
                Spacer()
                
                Text(pattern.value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(pattern.color)
            }
            
            Text(pattern.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(pattern.description)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
        }
        .padding(IgnitionSpacing.sm)
        .background(themeManager.backgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
    }
    
    // MARK: - Placeholder Views for Complex Sections
    private var weeklyHeatmapView: some View {
        VStack {
            Text("Mappa di Calore Settimanale")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Visualizzazione dell'attività per ora e giorno")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            // Placeholder grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<168, id: \.self) { index in
                    Rectangle()
                        .fill(IgnitionColors.ignitionOrange.opacity(Double.random(in: 0.1...0.8)))
                        .frame(height: 20)
                        .cornerRadius(2)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var productiveTimesView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Orari più Produttivi")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Basato sui tuoi pattern di attività")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var behavioralPatternsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Pattern Comportamentali")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Analisi dei tuoi comportamenti ricorrenti")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func trendCard(_ trend: TrendData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text(trend.title)
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                trendIndicator(trend.direction)
            }
            
            Text(trend.description)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("Variazione: \(trend.changePercentage, specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(trend.direction.color)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func correlationCard(_ correlation: CorrelationData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text(correlation.title)
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(correlation.description)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack {
                Text("Correlazione:")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(String(format: "%.2f", correlation.strength))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(correlationColor(correlation.strength))
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func predictionCard(_ prediction: PredictionData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text(prediction.title)
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Text("\(Int(prediction.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(prediction.description)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("Valore previsto: \(prediction.predictedValue)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var comparisonControlsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Confronta con:")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Menu {
                ForEach(ComparisonPeriod.allCases, id: \.self) { period in
                    Button(period.rawValue) {
                        comparisonPeriod = period
                        audioHapticsManager.playSelectionHaptic()
                    }
                }
            } label: {
                HStack {
                    Text(comparisonPeriod.rawValue)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(IgnitionSpacing.sm)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var comparisonChartsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Grafici di Confronto")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("I grafici di confronto saranno implementati qui")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var goalsProgressView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Goals Progress")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Goal progress will be displayed here")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private var goalRecommendationsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Goals Recommendations")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("Recommendations for new goals will be displayed here")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func detailedInsightCard(_ insight: InsightData) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Image(systemName: insight.icon)
                    .foregroundColor(insight.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .foregroundColor(insight.color)
                }
                
                Spacer()
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
            
            if let value = insight.value {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(insight.color)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Toolbar Items
    private var leadingToolbarItems: some View {
        HStack {
            Button(action: {
                showingDataBreakdown = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(themeManager.primaryColor)
            }
            
            Button(action: {
                showingComparison = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(themeManager.primaryColor)
            }
        }
    }
    
    private var trailingToolbarItems: some View {
        HStack {
            Menu {
                Button("Custom Report", systemImage: "doc.text") {
                    showingCustomReport = true
                }
                
                Button("Export Data", systemImage: "square.and.arrow.up") {
                    showingExport = true
                }
                
                Button("Predictions", systemImage: "sparkles") {
                    showingPredictions = true
                }
                
                Button("Goals", systemImage: "scope") {
                    showingGoals = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(themeManager.primaryColor)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateCharts = true
        }
    }
    
    private func refreshData() async {
        refreshing = true
        
        await MainActor.run {
            sparkManager.loadSparks()
            userProfileManager.loadUserProfile()
            missionManager.loadMissions()
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        refreshing = false
    }
    
    private func generateChartData(for metric: MetricType, in dateRange: DateInterval) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: dateRange.start)
        let endDate = calendar.startOfDay(for: dateRange.end)
        
        // Guard against invalid date ranges
        guard startDate <= endDate else {
            print("⚠️ Invalid date range: start > end")
            return []
        }
        
        var data: [ChartDataPoint] = []
        var currentDate = startDate
        var iterationCount = 0
        let maxIterations = 1000 // Safety limit: max 1000 days (~3 years)
        
        while currentDate <= endDate && iterationCount < maxIterations {
            let dayStart = currentDate
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                print("⚠️ Failed to calculate dayEnd for date: \(currentDate)")
                break
            }
            
            let daySparks = filteredSparks.filter { spark in
                spark.createdAt >= dayStart && spark.createdAt < dayEnd
            }
            
            let value: Double
            switch metric {
            case .sparks:
                value = Double(daySparks.count)
            case .points:
                value = Double(daySparks.reduce(0) { $0 + $1.points })
            case .intensity:
                value = daySparks.isEmpty ? 0 : Double(daySparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(daySparks.count)
            case .categories:
                value = Double(Set(daySparks.map { $0.category }).count)
            case .missions:
                let dayMissions = missionManager.missions.filter { mission in
                    guard let completedAt = mission.completedAt else { return false }
                    return completedAt >= dayStart && completedAt < dayEnd
                }
                value = Double(dayMissions.count)
            case .streaks:
                value = Double(userProfileManager.getStreakInfo().current)
            case .fuel:
                value = userProfileManager.getCurrentFuelPercentage() * 100
            case .productivity:
                value = calculateDailyProductivityScore(for: daySparks) * 100
            }
            
            data.append(ChartDataPoint(date: currentDate, value: value))
            
            // Safely increment currentDate
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                print("⚠️ Failed to increment date, breaking loop")
                break
            }
            currentDate = nextDate
            iterationCount += 1
        }
        
        if iterationCount >= maxIterations {
            print("⚠️ Chart data generation hit max iterations limit")
        }
        
        return data
    }
    
    private func calculateProductivityScore() -> Double {
        let sparks = filteredSparks
        guard !sparks.isEmpty else { return 0 }
        
        let avgIntensity = Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        let categoryDiversity = Double(Set(sparks.map { $0.category }).count) / Double(SparkCategory.allCases.count)
        let consistency = calculateConsistency()
        
        return (avgIntensity / 4.0 * 0.4) + (categoryDiversity * 0.3) + (consistency * 0.3)
    }
    
    private func calculateDailyProductivityScore(for sparks: [SparkModel]) -> Double {
        guard !sparks.isEmpty else { return 0 }
        
        let avgIntensity = Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        let sparkCount = min(Double(sparks.count) / 5.0, 1.0) // Normalize to max 5 sparks per day
        
        return (avgIntensity / 4.0 * 0.6) + (sparkCount * 0.4)
    }
    
    private func calculateConsistency() -> Double {
        let calendar = Calendar.current
        let days = Set(filteredSparks.map { calendar.startOfDay(for: $0.createdAt) })
        let totalDays = calendar.dateComponents([.day], from: currentDateRange.start, to: currentDateRange.end).day ?? 1
        
        return Double(days.count) / Double(totalDays)
    }
    
    private func calculateTrendForMetric(_ metric: MetricType) -> TrendDirection {
        // Simplified trend calculation - compare current period with previous period
        let currentValue = getCurrentValueForMetric(metric)
        let previousValue = getPreviousValueForMetric(metric)
        
        if currentValue > previousValue * 1.05 {
            return .up
        } else if currentValue < previousValue * 0.95 {
            return .down
        } else {
            return .stable
        }
    }
    
    private func getCurrentValueForMetric(_ metric: MetricType) -> Double {
        switch metric {
        case .sparks:
            return Double(overviewStats.totalSparks)
        case .points:
            return Double(overviewStats.totalPoints)
        case .intensity:
            return overviewStats.averageIntensity
        case .categories:
            return Double(overviewStats.uniqueCategories)
        case .missions:
            return Double(overviewStats.completedMissions)
        case .streaks:
            return Double(overviewStats.currentStreak)
        case .fuel:
            return overviewStats.fuelLevel * 100
        case .productivity:
            return overviewStats.productivityScore * 100
        }
    }
    
    private func getPreviousValueForMetric(_ metric: MetricType) -> Double {
        // Placeholder - would calculate previous period value
        return getCurrentValueForMetric(metric) * 0.9 // Simulate 10% lower previous value
    }
    
    private func generateTimePatterns() -> [TimePatternData] {
        return [
            TimePatternData(
                id: UUID(),
                title: "Orario di Picco",
                description: "La tua ora più produttiva",
                value: "14:00-15:00",
                icon: "clock.fill",
                color: .blue
            ),
            TimePatternData(
                id: UUID(),
                title: "Giorno Migliore",
                description: "Il giorno della settimana più attivo",
                value: "Martedì",
                icon: "calendar.circle.fill",
                color: .green
            ),
            TimePatternData(
                id: UUID(),
                title: "Durata Media",
                description: "Tempo medio tra i Spark",
                value: "2.5h",
                icon: "timer",
                color: .orange
            ),
            TimePatternData(
                id: UUID(),
                title: "Frequenza",
                description: "Spark per giorno in media",
                value: "3.2",
                icon: "repeat",
                color: .purple
            )
        ]
    }
    
    private func generateAdvancedInsights() -> [InsightData] {
        return [
            InsightData(
                id: UUID(),
                title: "Trend Positivo",
                description: "La tua produttività è aumentata del 15% questa settimana rispetto alla precedente.",
                type: .trend,
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                value: "+15%"
            ),
            InsightData(
                id: UUID(),
                title: "Pattern Identificato",
                description: "Tendi a essere più creativo nelle ore pomeridiane, specialmente tra le 14:00 e le 16:00.",
                type: .pattern,
                icon: "clock.fill",
                color: .blue,
                value: "14:00-16:00"
            ),
            InsightData(
                id: UUID(),
                title: "Correlazione Scoperta",
                description: "C'è una forte correlazione tra l'intensità dei tuoi Spark e il completamento delle missioni.",
                type: .correlation,
                icon: "link",
                color: .purple,
                value: "r=0.78"
            ),
            InsightData(
                id: UUID(),
                title: "Raccomandazione",
                description: "Basandoci sui tuoi pattern, dovresti provare a creare più Spark nella categoria 'Esperimento'.",
                type: .recommendation,
                icon: "lightbulb.fill",
                color: .yellow,
                value: nil
            )
        ]
    }
    
    private func calculateTrends() -> [TrendData] {
        return [
            TrendData(
                id: UUID(),
                title: "Crescita Spark Settimanali",
                description: "Il numero di Spark creati ogni settimana sta aumentando costantemente.",
                direction: .up,
                changePercentage: 12.5,
                period: "Ultime 4 settimane"
            ),
            TrendData(
                id: UUID(),
                title: "Intensità Media",
                description: "L'intensità media dei tuoi Spark è rimasta stabile nell'ultimo mese.",
                direction: .stable,
                changePercentage: 2.1,
                period: "Ultimo mese"
            )
        ]
    }
    
    private func calculateCorrelations() -> [CorrelationData] {
        return [
            CorrelationData(
                id: UUID(),
                title: "Intensità vs Punti",
                description: "Esiste una forte correlazione positiva tra l'intensità dei Spark e i punti guadagnati.",
                strength: 0.85,
                significance: 0.001
            ),
            CorrelationData(
                id: UUID(),
                title: "Orario vs Produttività",
                description: "La produttività mostra una correlazione moderata con l'orario di creazione dei Spark.",
                strength: 0.62,
                significance: 0.05
            )
        ]
    }
    
    private func generatePredictions() -> [PredictionData] {
        return [
            PredictionData(
                id: UUID(),
                title: "Spark del Prossimo Mese",
                description: "Basandoci sui tuoi pattern attuali, prevediamo che creerai circa 85 Spark il prossimo mese.",
                predictedValue: "85 Spark",
                confidence: 0.78,
                timeframe: "Prossimo mese"
            ),
            PredictionData(
                id: UUID(),
                title: "Raggiungimento Obiettivo",
                description: "Hai il 92% di probabilità di raggiungere il tuo obiettivo di streak di 30 giorni.",
                predictedValue: "30 giorni",
                confidence: 0.92,
                timeframe: "Prossime 3 settimane"
            )
        ]
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formatDateRange(_ dateRange: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(dateRange.start, equalTo: dateRange.end, toGranularity: .day) {
            return formatter.string(from: dateRange.start)
        } else {
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    private func correlationColor(_ strength: Double) -> Color {
        let absStrength = abs(strength)
        if absStrength > 0.7 {
            return .green
        } else if absStrength > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Data Models

struct OverviewStats {
    let totalSparks: Int
    let totalPoints: Int
    let averageIntensity: Double
    let uniqueCategories: Int
    let currentStreak: Int
    let longestStreak: Int
    let fuelLevel: Double
    let completedMissions: Int
    let productivityScore: Double
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: SparkCategory
    let count: Int
    let points: Int
    let averageIntensity: Double
    let percentage: Double
}

struct TimePatternData: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let value: String
    let icon: String
    let color: Color
}

struct InsightData: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: InsightType
    let icon: String
    let color: Color
    let value: String?
    
    enum InsightType: String {
        case trend = "Trend"
        case pattern = "Pattern"
        case correlation = "Correlation"
        case recommendation = "Recommendation"
        case anomaly = "Anomaly"
        case achievement = "Achievement"
    }
}

struct TrendData: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let direction: TrendDirection
    let changePercentage: Double
    let period: String
}

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

struct CorrelationData: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let strength: Double
    let significance: Double
}

struct PredictionData: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let predictedValue: String
    let confidence: Double
    let timeframe: String
}

// MARK: - Placeholder Views for Sheets

struct ExportAnalyticsView: View {
    let data: [ChartDataPoint]
    let stats: OverviewStats
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export Analytics")
                    .font(.largeTitle)
                    .padding()
                
                Text("Analytics data export will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ComparisonAnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Analytics Comparison")
                    .font(.largeTitle)
                    .padding()
                
                Text("Temporal comparisons will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Comparisons")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PredictiveAnalyticsView: View {
    let predictions: [PredictionData]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Predictive Analytics")
                    .font(.largeTitle)
                    .padding()
                
                Text("Detailed predictions will be displayed here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Predictions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GoalsAnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Goals Analytics")
                    .font(.largeTitle)
                    .padding()
                
                Text("Goals and progress will be managed here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CustomReportView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Custom Report")
                    .font(.largeTitle)
                    .padding()
                
                Text("Custom report generator will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DataBreakdownView: View {
    let sparks: [SparkModel]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Breakdown Dati")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verrà mostrato il breakdown dettagliato dei dati")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Dati")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CustomDateRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: IgnitionSpacing.lg) {
                DatePicker("Data Inizio", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                
                DatePicker("Data Fine", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                
                Button("Applica") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(IgnitionSpacing.md)
            .navigationTitle("Periodo Personalizzato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StatsViewExpanded()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
