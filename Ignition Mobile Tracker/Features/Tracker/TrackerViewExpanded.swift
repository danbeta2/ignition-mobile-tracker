//
//  TrackerViewExpanded.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import Charts

struct TrackerViewExpanded: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    // MARK: - State Variables
    @State private var showingAddSpark = false
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    @State private var showingBulkActions = false
    @State private var showingSparkDetails = false
    @State private var showingQuickStats = false
    @State private var showingSearchSuggestions = false
    @State private var showingStats = false
    @State private var showingSettings = false
    
    // Search & Filter States
    @State private var searchText = ""
    @State private var selectedCategory: SparkCategory?
    @State private var selectedIntensity: SparkIntensity?
    @State private var selectedDateRange: DateRange = .all
    @State private var selectedTags: Set<String> = []
    @State private var sortOption: SortOption = .newest
    @State private var viewMode: ViewMode = .list
    @State private var showOnlyFavorites = false
    @State private var showOnlyWithNotes = false
    
    // Selection & Bulk Actions
    @State private var selectedSparks: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var sparkToDelete: SparkModel?
    @State private var selectedSparkForDetails: SparkModel?
    @State private var showingSparkDetail = false
    
    // Animation & UI States
    @State private var animateCards = false
    @State private var refreshing = false
    @State private var showingQuickFilters = true
    @State private var searchFieldFocused = false
    
    // Analytics States
    @State private var showingTrendChart = false
    @State private var selectedAnalyticsPeriod: AnalyticsPeriod = .week
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case points = "Points"
        case category = "Category"
        case intensity = "Intensity"
        case alphabetical = "Alphabetical"
        
        var icon: String {
            switch self {
            case .newest: return "arrow.down"
            case .oldest: return "arrow.up"
            case .points: return "star.fill"
            case .category: return "folder.fill"
            case .intensity: return "flame.fill"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case list = "Lista"
        case grid = "Griglia"
        case timeline = "Timeline"
        case map = "Mappa"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            case .timeline: return "timeline.selection"
            case .map: return "map"
            }
        }
    }
    
    enum DateRange: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom"
        
        var dateInterval: DateInterval? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all, .custom:
                return nil
            case .today:
                return calendar.dateInterval(of: .day, for: now)
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
                return calendar.dateInterval(of: .day, for: yesterday)
            case .thisWeek:
                return calendar.dateInterval(of: .weekOfYear, for: now)
            case .lastWeek:
                let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
                return calendar.dateInterval(of: .weekOfYear, for: lastWeek)
            case .thisMonth:
                return calendar.dateInterval(of: .month, for: now)
            case .lastMonth:
                let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
                return calendar.dateInterval(of: .month, for: lastMonth)
            }
        }
    }
    
    enum AnalyticsPeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // MARK: - Computed Properties
    private var filteredSparks: [SparkModel] {
        var sparks = sparkManager.sparks
        
        // Text search
        if !searchText.isEmpty {
            sparks = sparks.filter { spark in
                spark.title.localizedCaseInsensitiveContains(searchText) ||
                (spark.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                spark.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Category filter
        if let category = selectedCategory {
            sparks = sparks.filter { $0.category == category }
        }
        
        // Intensity filter
        if let intensity = selectedIntensity {
            sparks = sparks.filter { $0.intensity == intensity }
        }
        
        // Date range filter
        if let dateInterval = selectedDateRange.dateInterval {
            sparks = sparks.filter { dateInterval.contains($0.createdAt) }
        }
        
        // Tags filter
        if !selectedTags.isEmpty {
            sparks = sparks.filter { spark in
                !Set(spark.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Notes filter
        if showOnlyWithNotes {
            sparks = sparks.filter { $0.notes != nil && !$0.notes!.isEmpty }
        }
        
        // Sort
        switch sortOption {
        case .newest:
            sparks.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            sparks.sort { $0.createdAt < $1.createdAt }
        case .points:
            sparks.sort { $0.points > $1.points }
        case .category:
            sparks.sort { $0.category.rawValue < $1.category.rawValue }
        case .intensity:
            sparks.sort { $0.intensity.rawValue > $1.intensity.rawValue }
        case .alphabetical:
            sparks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return sparks
    }
    
    private var availableTags: [String] {
        Array(Set(sparkManager.sparks.flatMap { $0.tags })).sorted()
    }
    
    private var searchSuggestions: [String] {
        let allWords = sparkManager.sparks.flatMap { spark in
            spark.title.components(separatedBy: .whitespacesAndNewlines) +
            (spark.notes?.components(separatedBy: .whitespacesAndNewlines) ?? []) +
            spark.tags
        }
        
        let filtered = allWords.filter { word in
            word.count > 2 && word.localizedCaseInsensitiveContains(searchText)
        }
        
        return Array(Set(filtered)).sorted().prefix(5).map { String($0) }
    }
    
    private var quickStats: (total: Int, todayCount: Int, weekCount: Int, avgIntensity: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today) ?? today
        
        let todayCount = sparkManager.sparks.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: Date()) }.count
        let weekCount = sparkManager.sparks.filter { $0.createdAt >= weekAgo }.count
        let avgIntensity = sparkManager.sparks.isEmpty ? 0 : Double(sparkManager.sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparkManager.sparks.count)
        
        return (sparkManager.sparks.count, todayCount, weekCount, avgIntensity)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (Fixed at top)
            CustomAppHeader(showingStats: $showingStats, showingSettings: $showingSettings)
                .zIndex(10)
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Enhanced Header with Quick Stats
                    if showingQuickStats {
                        quickStatsHeader
                            .padding(.top, IgnitionSpacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Advanced Search Bar
                    advancedSearchSection
                        .padding(.top, IgnitionSpacing.md)
                    
                    // Quick Filters (Collapsible)
                    if showingQuickFilters {
                        quickFiltersSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Content Area
                    contentArea
                }
            .overlay(alignment: .bottomTrailing) {
                // Floating Add Button
                if !isSelectionMode {
                    Button(action: {
                        showingAddSpark = true
                        audioHapticsManager.uiTapped()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(IgnitionColors.ignitionOrange)
                            .background(
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 50, height: 50)
                            )
                            .fireGlow(radius: 8, color: IgnitionColors.ignitionOrange)
                    }
                    .padding(.trailing, IgnitionSpacing.lg)
                    .padding(.bottom, IgnitionSpacing.xl)
                }
            }
            .background(themeManager.backgroundColor)
            .navigationBarHidden(true)
            .onAppear {
                setupView()
                // Check if we need to show AddSpark
                if tabRouter.shouldShowAddSpark {
                    showingAddSpark = true
                    tabRouter.shouldShowAddSpark = false
                }
            }
            .refreshable {
                await refreshData()
            }
            .searchable(text: $searchText, prompt: "Search Sparks...")
            .searchSuggestions {
                if !searchText.isEmpty && showingSearchSuggestions {
                    ForEach(searchSuggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            searchText = suggestion
                            audioHapticsManager.uiTapped()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSpark) {
                AddSparkView()
            }
            .sheet(isPresented: $showingSparkDetail) {
                    if let spark = selectedSparkForDetails {
                        SparkDetailView(spark: spark)
                    }
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsViewExpanded()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(sparkManager.error ?? "An unknown error occurred")
            }
            .alert("Delete Spark", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let spark = sparkToDelete {
                        deleteSpark(spark)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this Spark? This action cannot be undone.")
            }
            .animation(.easeInOut(duration: 0.3), value: showingQuickStats)
            .animation(.easeInOut(duration: 0.3), value: showingQuickFilters)
            .animation(.easeInOut(duration: 0.3), value: isSelectionMode)
        }
    }
    
    // MARK: - Quick Stats Header
    private var quickStatsHeader: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            HStack {
                Text("Panoramica")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingQuickStats.toggle()
                    }
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: showingQuickStats ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.primaryColor)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: IgnitionSpacing.sm) {
                quickStatCard(
                    title: "Totale",
                    value: "\(quickStats.total)",
                    icon: "sparkles",
                    color: .blue
                )
                
                quickStatCard(
                    title: "Today",
                    value: "\(quickStats.todayCount)",
                    icon: "calendar",
                    color: .green
                )
                
                quickStatCard(
                    title: "Week",
                    value: "\(quickStats.weekCount)",
                    icon: "calendar.badge.clock",
                    color: .orange
                )
                
                quickStatCard(
                    title: "Intensity",
                    value: String(format: "%.1f", quickStats.avgIntensity),
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    // MARK: - Advanced Search Section
    private var advancedSearchSection: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            HStack(spacing: IgnitionSpacing.sm) {
                // Search Field
                HStack {
                    Image(systemName: AssetNames.SystemIcons.searchIcon.systemName)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search by title, notes or tags...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onTapGesture {
                            searchFieldFocused = true
                            showingSearchSuggestions = true
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            audioHapticsManager.uiTapped()
                        }) {
                            Image(systemName: AssetNames.SystemIcons.closeIcon.systemName)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, IgnitionSpacing.sm)
                .padding(.vertical, IgnitionSpacing.xs)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
                
                // View Mode Toggle
                Menu {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Button(action: {
                            viewMode = mode
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Label(mode.rawValue, systemImage: mode.icon)
                        }
                    }
                } label: {
                    Image(systemName: viewMode.icon)
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title3)
                }
                
                // Sort Menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    Image(systemName: AssetNames.SystemIcons.sortIcon.systemName)
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title3)
                }
            }
            
            // Active Filters Summary
            if hasActiveFilters {
                activeFiltersView
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Quick Filters Section
    private var quickFiltersSection: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    // Category Filters
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        quickFilterChip(
                            title: category.rawValue.capitalized,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                                audioHapticsManager.playSelectionHaptic()
                            }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Date Range Filters
                    ForEach([DateRange.today, .thisWeek, .thisMonth], id: \.self) { range in
                        quickFilterChip(
                            title: range.rawValue,
                            isSelected: selectedDateRange == range,
                            action: {
                                selectedDateRange = selectedDateRange == range ? .all : range
                                audioHapticsManager.playSelectionHaptic()
                            }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Special Filters
                    quickFilterChip(
                        title: "Favorites",
                        isSelected: showOnlyFavorites,
                        action: {
                            showOnlyFavorites.toggle()
                            audioHapticsManager.playSelectionHaptic()
                        }
                    )
                    
                    quickFilterChip(
                        title: "With Notes",
                        isSelected: showOnlyWithNotes,
                        action: {
                            showOnlyWithNotes.toggle()
                            audioHapticsManager.playSelectionHaptic()
                        }
                    )
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if sparkManager.isLoading {
                loadingView
            } else if filteredSparks.isEmpty {
                emptyStateView
            } else {
                sparkContentView
            }
        }
    }
    
    // MARK: - Spark Content View
    private var sparkContentView: some View {
        Group {
            switch viewMode {
            case .list:
                sparkListView
            case .grid:
                sparkGridView
            case .timeline:
                sparkTimelineView
            case .map:
                sparkMapView
            }
        }
    }
    
    // MARK: - List View
    private var sparkListView: some View {
        ScrollView {
            LazyVStack(spacing: IgnitionSpacing.sm) {
                ForEach(Array(filteredSparks.enumerated()), id: \.element.id) { index, spark in
                    SparkRowView(
                        spark: spark,
                        isSelected: selectedSparks.contains(spark.id),
                        isSelectionMode: isSelectionMode,
                        onTap: {
                            handleSparkTap(spark)
                        },
                        onLongPress: {
                            handleSparkLongPress(spark)
                        },
                        onToggleSelection: {
                            toggleSparkSelection(spark)
                        },
                        onDelete: {
                            confirmDeleteSpark(spark)
                        }
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(x: animateCards ? 0 : 50)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05), value: animateCards)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Grid View
    private var sparkGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: IgnitionSpacing.md) {
                ForEach(Array(filteredSparks.enumerated()), id: \.element.id) { index, spark in
                    SparkCardView(
                        spark: spark,
                        isSelected: selectedSparks.contains(spark.id),
                        isSelectionMode: isSelectionMode,
                        onTap: {
                            handleSparkTap(spark)
                        },
                        onLongPress: {
                            handleSparkLongPress(spark)
                        },
                        onToggleSelection: {
                            toggleSparkSelection(spark)
                        }
                    )
                    .opacity(animateCards ? 1 : 0)
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateCards)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Timeline View
    private var sparkTimelineView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: IgnitionSpacing.lg) {
                ForEach(groupedSparksByDate, id: \.key) { dateGroup in
                    VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
                        // Date Header
                        HStack {
                            Text(formatDateForTimeline(dateGroup.key))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Spacer()
                            
                            Text("\(dateGroup.value.count) Spark")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.horizontal, IgnitionSpacing.md)
                        
                        // Sparks for this date
                        ForEach(dateGroup.value, id: \.id) { spark in
                            SparkTimelineItemView(
                                spark: spark,
                                isSelected: selectedSparks.contains(spark.id),
                                isSelectionMode: isSelectionMode,
                                onTap: {
                                    handleSparkTap(spark)
                                },
                                onLongPress: {
                                    handleSparkLongPress(spark)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Map View (Placeholder)
    private var sparkMapView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("Vista Mappa")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("La vista mappa sarà disponibile in una futura versione")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button("Torna alla Lista") {
                viewMode = .list
                audioHapticsManager.uiTapped()
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.primaryColor)
        }
        .padding(IgnitionSpacing.xl)
    }
    
    // MARK: - Helper Views
    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: IgnitionSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, IgnitionSpacing.sm)
        .background(themeManager.backgroundColor)
        .cornerRadius(IgnitionCornerRadius.sm)
    }
    
    private func quickFilterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : themeManager.primaryColor)
                .padding(.horizontal, IgnitionSpacing.sm)
                .padding(.vertical, IgnitionSpacing.xs)
                .background(isSelected ? themeManager.primaryColor : themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                        .stroke(themeManager.primaryColor, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: IgnitionSpacing.xs) {
                if let category = selectedCategory {
                    activeFilterChip(title: category.rawValue.capitalized) {
                        selectedCategory = nil
                    }
                }
                
                if let intensity = selectedIntensity {
                    activeFilterChip(title: "Intensity \(intensity.rawValue)") {
                        selectedIntensity = nil
                    }
                }
                
                if selectedDateRange != .all {
                    activeFilterChip(title: selectedDateRange.rawValue) {
                        selectedDateRange = .all
                    }
                }
                
                if showOnlyFavorites {
                    activeFilterChip(title: "Favorites") {
                        showOnlyFavorites = false
                    }
                }
                
                if showOnlyWithNotes {
                    activeFilterChip(title: "With Notes") {
                        showOnlyWithNotes = false
                    }
                }
                
                if hasActiveFilters {
                    Button("Clear All") {
                        clearAllFilters()
                        audioHapticsManager.uiTapped()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, IgnitionSpacing.sm)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    private func activeFilterChip(title: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: IgnitionSpacing.xs) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white)
            
            Button(action: {
                onRemove()
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: AssetNames.SystemIcons.closeIcon.systemName)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, IgnitionSpacing.xs)
        .padding(.vertical, 2)
        .background(themeManager.primaryColor)
        .cornerRadius(IgnitionCornerRadius.xs)
    }
    
    // MARK: - Loading & Empty States
    private var loadingView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.primaryColor)
            
            Text("Caricamento Spark...")
                .font(.headline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: hasActiveFilters ? "magnifyingglass" : "sparkles")
                .font(.system(size: 60))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text(hasActiveFilters ? "No Results" : "No Sparks Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(hasActiveFilters ? "Try adjusting your search filters" : "Start by creating your first Spark!")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button("Cancella Filtri") {
                    clearAllFilters()
                    audioHapticsManager.uiTapped()
                }
                .buttonStyle(.bordered)
                .tint(themeManager.primaryColor)
            } else {
                Button("Create Spark") {
                    showingAddSpark = true
                    audioHapticsManager.uiTapped()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.primaryColor)
            }
        }
        .padding(IgnitionSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar Items
    private var leadingToolbarItems: some View {
        EmptyView()
    }
    
    private var trailingToolbarItems: some View {
        HStack(spacing: IgnitionSpacing.sm) {
            if !isSelectionMode {
                // Add Spark Button - Always Visible
                Button(action: {
                    showingAddSpark = true
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title2)
                }
            }
        }
    }
    
    private var bulkActionsToolbar: some View {
        HStack {
            Button("Cancel") {
                isSelectionMode = false
                selectedSparks.removeAll()
                audioHapticsManager.uiTapped()
            }
            .foregroundColor(themeManager.primaryColor)
            
            Spacer()
            
            Text("\(selectedSparks.count) selected")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Spacer()
            
            if !selectedSparks.isEmpty {
                Button(action: {
                    bulkDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Computed Properties for Data Processing
    private var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedIntensity != nil ||
        selectedDateRange != .all ||
        !selectedTags.isEmpty ||
        showOnlyFavorites ||
        showOnlyWithNotes ||
        !searchText.isEmpty
    }
    
    private var navigationTitle: String {
        if isSelectionMode && !selectedSparks.isEmpty {
            return "\(selectedSparks.count) selected"
        } else if hasActiveFilters {
            return "\(filteredSparks.count) Sparks"
        } else {
            return "Tracker"
        }
    }
    
    private var groupedSparksByDate: [(key: Date, value: [SparkModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSparks) { spark in
            calendar.startOfDay(for: spark.createdAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Action Methods
    private func setupView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateCards = true
        }
    }
    
    private func refreshData() async {
        refreshing = true
        
        await MainActor.run {
            sparkManager.loadSparks()
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        refreshing = false
    }
    
    private func handleSparkTap(_ spark: SparkModel) {
        if isSelectionMode {
            toggleSparkSelection(spark)
        } else {
            selectedSparkForDetails = spark
            showingSparkDetail = true
            audioHapticsManager.uiTapped()
        }
    }
    
    private func handleSparkLongPress(_ spark: SparkModel) {
        if !isSelectionMode {
            isSelectionMode = true
            selectedSparks.insert(spark.id)
            audioHapticsManager.playSelectionHaptic()
        }
    }
    
    private func toggleSparkSelection(_ spark: SparkModel) {
        if selectedSparks.contains(spark.id) {
            selectedSparks.remove(spark.id)
        } else {
            selectedSparks.insert(spark.id)
        }
        audioHapticsManager.playSelectionHaptic()
    }
    
    private func confirmDeleteSpark(_ spark: SparkModel) {
        sparkToDelete = spark
        showingDeleteConfirmation = true
    }
    
    private func deleteSpark(_ spark: SparkModel) {
        sparkManager.deleteSpark(spark)
        audioHapticsManager.uiTapped()
    }
    
    private func clearAllFilters() {
        selectedCategory = nil
        selectedIntensity = nil
        selectedDateRange = .all
        selectedTags.removeAll()
        showOnlyFavorites = false
        showOnlyWithNotes = false
        searchText = ""
    }
    
    private func bulkDelete() {
        let selectedSparkModels = sparkManager.sparks.filter { selectedSparks.contains($0.id) }
        for spark in selectedSparkModels {
            sparkManager.deleteSpark(spark)
        }
        isSelectionMode = false
        selectedSparks.removeAll()
        audioHapticsManager.uiTapped()
    }
    
    private func formatDateForTimeline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting Views

struct SparkRowView: View {
    let spark: SparkModel
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Selection Indicator
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.secondaryTextColor)
                        .font(.title3)
                }
            }
            
            // Category Icon
            Image(systemName: AssetNames.SparkCategories.allCases.first(where: { $0.displayName.lowercased().contains(spark.category.rawValue) })?.systemName ?? "circle.fill")
                .foregroundColor(themeManager.primaryColor)
                .font(.title2)
                .frame(width: 30, height: 30)
            
            // Content
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(spark.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                
                HStack(spacing: IgnitionSpacing.sm) {
                    // Category
                    Text(spark.category.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(themeManager.primaryColor.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(themeManager.primaryColor)
                    
                    // Intensity
                    HStack(spacing: 2) {
                        ForEach(0..<spark.intensity.rawValue, id: \.self) { _ in
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    // Time
                    Text(timeAgoString(from: spark.createdAt))
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Points
            if !isSelectionMode {
                VStack(spacing: IgnitionSpacing.xs) {
                    Text("+\(spark.points)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .stroke(isSelected ? themeManager.primaryColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .contextMenu {
            Button("Details", systemImage: "info.circle") {
                onTap()
            }
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SparkCardView: View {
    let spark: SparkModel
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onToggleSelection: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            // Header
            HStack {
                if isSelectionMode {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if spark.isFavorite {
                    Image(systemName: AssetNames.SystemIcons.favoriteIcon.systemName)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Category Icon
            Image(systemName: AssetNames.SparkCategories.allCases.first(where: { $0.displayName.lowercased().contains(spark.category.rawValue) })?.systemName ?? "circle.fill")
                .foregroundColor(themeManager.primaryColor)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Title
            Text(spark.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Category & Intensity
            HStack {
                Text(spark.category.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(themeManager.primaryColor)
                
                Spacer()
                
                HStack(spacing: 1) {
                    ForEach(0..<spark.intensity.rawValue, id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Points
            Text("+\(spark.points)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.lg)
                .stroke(isSelected ? themeManager.primaryColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

struct SparkTimelineItemView: View {
    let spark: SparkModel
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(themeManager.primaryColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(themeManager.primaryColor.opacity(0.3))
                    .frame(width: 2, height: 30)
            }
            
            // Content
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text(timeString(from: spark.createdAt))
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.secondaryTextColor)
                    }
                }
                
                Text(spark.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                HStack {
                    Text(spark.category.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(themeManager.primaryColor.opacity(0.2))
                        .cornerRadius(3)
                        .foregroundColor(themeManager.primaryColor)
                    
                    Spacer()
                    
                    Text("+\(spark.points)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, IgnitionSpacing.sm)
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Spark Detail View

struct SparkDetailView: View {
    let spark: SparkModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    
    @State private var showingEditView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Header Section
                    headerSection
                    
                    // Content Section
                    contentSection
                    
                    // Metadata Section
                    metadataSection
                    
                    // Notes Section
                    if let notes = spark.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                    
                    // Stats Section
                    statsSection
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(IgnitionSpacing.md)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Spark Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                        audioHapticsManager.uiTapped()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                        audioHapticsManager.uiTapped()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            AddSparkView(sparkToEdit: spark)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Category Icon
            Image(systemName: spark.category.iconName)
                .font(.system(size: 60))
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 100, height: 100)
                .background(themeManager.primaryColor.opacity(0.1))
                .cornerRadius(IgnitionCornerRadius.xl)
            
            // Title
            Text(spark.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)
            
            // Category Badge
            HStack {
                Text(spark.category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, IgnitionSpacing.sm)
                    .padding(.vertical, IgnitionSpacing.xs)
                    .background(Color.orange)
                    .cornerRadius(IgnitionCornerRadius.sm)
                
                // Intensity Indicator
                HStack(spacing: 2) {
                    ForEach(0..<spark.intensity.rawValue, id: \.self) { _ in
                        Circle()
                            .fill(spark.intensity.color)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Content")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(spark.notes ?? "No description provided")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            Text("Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: IgnitionSpacing.md) {
                metadataItem(title: "Created", value: DateFormatter.sparkDate.string(from: spark.createdAt))
                metadataItem(title: "Points", value: "+\(spark.points)")
                metadataItem(title: "Intensity", value: spark.intensity.displayName)
                metadataItem(title: "Category", value: spark.category.displayName)
                
                if let duration = spark.estimatedTime {
                    metadataItem(title: "Estimated Time", value: "\(duration) min")
                }
                
                if let actualDuration = spark.actualTime {
                    metadataItem(title: "Actual Time", value: "\(actualDuration) min")
                }
            }
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func metadataItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(IgnitionSpacing.sm)
        .background(themeManager.backgroundColor.opacity(0.5))
        .cornerRadius(IgnitionCornerRadius.sm)
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Tag")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: IgnitionSpacing.sm) {
                ForEach(spark.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(themeManager.primaryColor)
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(themeManager.primaryColor.opacity(0.1))
                        .cornerRadius(IgnitionCornerRadius.sm)
                }
            }
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Notes Section
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(notes)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: IgnitionSpacing.md) {
                statItem(title: "Points Earned", value: "+\(spark.points)", color: .green)
                
                if spark.actualTime != nil {
                    statItem(title: "Completed", value: "✓", color: themeManager.primaryColor)
                }
            }
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: IgnitionSpacing.xs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(IgnitionSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(IgnitionCornerRadius.md)
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let sparkDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}

#Preview {
    TrackerViewExpanded()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
