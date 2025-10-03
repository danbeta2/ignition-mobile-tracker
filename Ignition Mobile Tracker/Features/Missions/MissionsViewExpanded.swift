//
//  MissionsViewExpanded.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import Charts

struct MissionsViewExpanded: View {
    @StateObject private var missionManager = MissionManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    // MARK: - State Variables
    @State private var selectedFilter: MissionFilter = .all
    @State private var selectedDifficulty: MissionDifficultyFilter = .all
    @State private var selectedTimeframe: MissionTimeframe = .all
    @State private var showingError = false
    @State private var showingMissionCreator = false
    @State private var showingMissionDetails = false
    @State private var showingLeaderboard = false
    @State private var showingAchievements = false
    @State private var showingMissionHistory = false
    @State private var showingCustomMissions = false
    @State private var showingMissionTemplates = false
    @State private var showingProgressAnalytics = false
    
    // Mission Management
    @State private var selectedMissionForDetails: IgnitionMissionModel?
    @State private var missionToComplete: IgnitionMissionModel?
    @State private var showingCompletionAnimation = false
    @State private var completedMissionReward = 0
    @State private var completedMissionTitle = ""
    @State private var showingCompletionOverlay = false
    
    // UI States
    @State private var animateMissions = false
    @State private var refreshing = false
    @State private var showingFilters = true
    @State private var viewMode: MissionViewMode = .cards
    @State private var sortOption: MissionSortOption = .priority
    
    // Search & Discovery
    @State private var searchText = ""
    @State private var showingMissionSuggestions = false
    @State private var discoveryMode = false
    
    // Gamification
    @State private var showingStreakBonus = false
    @State private var currentStreak = 0
    @State private var showingLevelUp = false
    @State private var missionPoints = 0
    
    // MARK: - Enums
    enum MissionFilter: String, CaseIterable {
        case all = "All"
        case available = "Available"
        case inProgress = "In Progress"
        case completed = "Completed"
        case expired = "Expired"
        case favorites = "Favorites"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .available: return "play.circle"
            case .inProgress: return "clock"
            case .completed: return "checkmark.circle"
            case .expired: return "xmark.circle"
            case .favorites: return "heart.fill"
            }
        }
    }
    
    enum MissionDifficultyFilter: String, CaseIterable {
        case all = "All"
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        
        var icon: String {
            switch self {
            case .all: return "star"
            case .easy: return "star.fill"
            case .medium: return "star.leadinghalf.filled"
            case .hard: return "flame"
            case .expert: return "flame.fill"
            }
        }
        
        func matches(_ difficulty: MissionDifficulty) -> Bool {
            switch self {
            case .all: return true
            case .easy: return difficulty == .easy
            case .medium: return difficulty == .medium
            case .hard: return difficulty == .hard
            case .expert: return difficulty == .expert
            }
        }
    }
    
    enum MissionTimeframe: String, CaseIterable {
        case all = "All"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case seasonal = "Seasonal"
        case special = "Special"
        
        var icon: String {
            switch self {
            case .all: return "calendar"
            case .daily: return "sun.max"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.circle"
            case .seasonal: return "leaf"
            case .special: return "star.circle"
            }
        }
    }
    
    enum MissionViewMode: String, CaseIterable {
        case cards = "Cards"
        case list = "List"
        case timeline = "Timeline"
        case board = "Board"
        
        var icon: String {
            switch self {
            case .cards: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            case .timeline: return "timeline.selection"
            case .board: return "kanban"
            }
        }
    }
    
    enum MissionSortOption: String, CaseIterable {
        case priority = "Priority"
        case deadline = "Deadline"
        case points = "Points"
        case difficulty = "Difficulty"
        case progress = "Progress"
        case alphabetical = "Alphabetical"
        
        var icon: String {
            switch self {
            case .priority: return "exclamationmark.triangle"
            case .deadline: return "clock"
            case .points: return "star"
            case .difficulty: return "flame"
            case .progress: return "chart.bar"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredMissions: [IgnitionMissionModel] {
        var missions = missionManager.missions
        
        // Text search
        if !searchText.isEmpty {
            missions = missions.filter { mission in
                mission.title.localizedCaseInsensitiveContains(searchText) ||
                mission.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Status filter
        switch selectedFilter {
        case .all:
            break
        case .available:
            missions = missions.filter { $0.status == .available }
        case .inProgress:
            missions = missions.filter { $0.status == .inProgress }
        case .completed:
            missions = missions.filter { $0.status == .completed }
        case .expired:
            missions = missions.filter { $0.status == .expired }
        case .favorites:
            missions = missions.filter { $0.isFavorite }
        }
        
        // Difficulty filter
        if selectedDifficulty != .all {
            missions = missions.filter { selectedDifficulty.matches($0.difficulty) }
        }
        
        // Timeframe filter
        if selectedTimeframe != .all {
            switch selectedTimeframe {
            case .all:
                break
            case .daily:
                missions = missions.filter { $0.type == .daily }
            case .weekly:
                missions = missions.filter { $0.type == .weekly }
            case .monthly:
                missions = missions.filter { $0.type == .achievement }
            case .seasonal, .special:
                missions = missions.filter { $0.type == .achievement }
            }
        }
        
        // Sort
        switch sortOption {
        case .priority:
            missions.sort { mission1, mission2 in
                let priority1 = missionPriority(mission1)
                let priority2 = missionPriority(mission2)
                return priority1 > priority2
            }
        case .deadline:
            missions.sort { ($0.expiresAt ?? Date.distantFuture) < ($1.expiresAt ?? Date.distantFuture) }
        case .points:
            missions.sort { $0.rewardPoints > $1.rewardPoints }
        case .difficulty:
            missions.sort { $0.difficulty.points > $1.difficulty.points }
        case .progress:
            missions.sort { missionProgress($0) > missionProgress($1) }
        case .alphabetical:
            missions.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return missions
    }
    
    private var missionStats: (total: Int, completed: Int, available: Int, inProgress: Int) {
        let total = missionManager.missions.count
        let completed = missionManager.missions.filter { $0.status == .completed }.count
        let available = missionManager.missions.filter { $0.status == .available }.count
        let inProgress = missionManager.missions.filter { $0.status == .inProgress }.count
        
        return (total, completed, available, inProgress)
    }
    
    private var completionRate: Double {
        let stats = missionStats
        return stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0
    }
    
    private var todaysMissions: [IgnitionMissionModel] {
        let calendar = Calendar.current
        return missionManager.missions.filter { mission in
            if let expiresAt = mission.expiresAt {
                return calendar.isDate(expiresAt, inSameDayAs: Date())
            }
            return mission.type == .daily
        }
    }
    
    private var urgentMissions: [IgnitionMissionModel] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        return missionManager.missions.filter { mission in
            guard let expiresAt = mission.expiresAt else { return false }
            return expiresAt <= tomorrow && mission.status == .available
        }
    }
    
    private var missionCategories: [(category: SparkCategory?, count: Int)] {
        let grouped = Dictionary(grouping: filteredMissions) { $0.category }
        return grouped.map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mission Dashboard Header
                missionDashboardHeader
                
                // Search and Filters
                searchAndFiltersSection
                
                // Quick Filters
                if showingFilters {
                    quickFiltersSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content Area
                contentArea
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(navigationTitle)
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
            .searchable(text: $searchText, prompt: "Search missions...")
            .sheet(isPresented: $showingMissionCreator) {
                MissionCreatorView()
            }
            .sheet(isPresented: $showingLeaderboard) {
                MissionLeaderboardView()
            }
            .sheet(isPresented: $showingAchievements) {
                MissionAchievementsView()
            }
            .overlay {
                if showingCompletionOverlay {
                    missionCompletionOverlay
                }
            }
            .sheet(isPresented: $showingMissionHistory) {
                MissionHistoryView()
            }
            .sheet(isPresented: $showingCustomMissions) {
                CustomMissionsView()
            }
            .sheet(isPresented: $showingMissionTemplates) {
                MissionTemplatesView()
            }
            .sheet(isPresented: $showingProgressAnalytics) {
                MissionProgressAnalyticsView()
            }
            .sheet(item: $selectedMissionForDetails) { mission in
                MissionDetailView(mission: mission)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(missionManager.error ?? "An unknown error occurred")
            }
            .overlay(
                missionCompletionOverlay
                    .opacity(showingCompletionAnimation ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showingCompletionAnimation)
            )
            .animation(.easeInOut(duration: 0.3), value: showingFilters)
        }
    }
    
    // MARK: - Mission Dashboard Header
    private var missionDashboardHeader: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Progress Overview
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Mission Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("\(missionStats.completed)/\(missionStats.total) completed")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(themeManager.secondaryColor.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: completionRate)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: completionRate)
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
            }
            
            // Quick Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: IgnitionSpacing.sm) {
                missionStatCard(
                    title: "Available",
                    value: "\(missionStats.available)",
                    icon: "play.circle.fill",
                    color: .green
                )
                
                missionStatCard(
                    title: "In Progress",
                    value: "\(missionStats.inProgress)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                missionStatCard(
                    title: "Urgent",
                    value: "\(urgentMissions.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                missionStatCard(
                    title: "Today",
                    value: "\(todaysMissions.count)",
                    icon: "calendar.circle.fill",
                    color: .blue
                )
            }
            
            // Mission Streak & Level
            HStack(spacing: IgnitionSpacing.md) {
                // Current Streak
                VStack(spacing: IgnitionSpacing.xs) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Text("\(currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, IgnitionSpacing.sm)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
                
                // Mission Level
                VStack(spacing: IgnitionSpacing.xs) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Level")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Text("\(missionLevel)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, IgnitionSpacing.sm)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
                
                // Total Points
                VStack(spacing: IgnitionSpacing.xs) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.purple)
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Text("\(missionPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, IgnitionSpacing.sm)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(IgnitionCornerRadius.sm)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 4, x: 0, y: 2)
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    // MARK: - Search and Filters Section
    private var searchAndFiltersSection: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            HStack(spacing: IgnitionSpacing.sm) {
                // Search Field
                HStack {
                    Image(systemName: AssetNames.SystemIcons.searchIcon.systemName)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search missions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
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
                    ForEach(MissionViewMode.allCases, id: \.self) { mode in
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
                    ForEach(MissionSortOption.allCases, id: \.self) { option in
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
                
                // Filters Toggle
                Button(action: {
                    withAnimation {
                        showingFilters.toggle()
                    }
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: AssetNames.SystemIcons.filterIcon.systemName)
                        .foregroundColor(hasActiveFilters ? .orange : themeManager.primaryColor)
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Quick Filters Section
    private var quickFiltersSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Status Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    ForEach(MissionFilter.allCases, id: \.self) { filter in
                        filterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            count: missionCountForFilter(filter),
                            action: {
                                selectedFilter = filter
                                audioHapticsManager.playSelectionHaptic()
                            }
                        )
                    }
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
            
            // Difficulty & Timeframe Filters
            HStack(spacing: IgnitionSpacing.md) {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Difficulty")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Menu {
                        ForEach(MissionDifficultyFilter.allCases, id: \.self) { difficulty in
                            Button(action: {
                                selectedDifficulty = difficulty
                                audioHapticsManager.playSelectionHaptic()
                            }) {
                                Label(difficulty.rawValue, systemImage: difficulty.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedDifficulty.icon)
                                .font(.caption)
                            
                            Text(selectedDifficulty.rawValue)
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
                
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Type")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Menu {
                        ForEach(MissionTimeframe.allCases, id: \.self) { timeframe in
                            Button(action: {
                                selectedTimeframe = timeframe
                                audioHapticsManager.playSelectionHaptic()
                            }) {
                                Label(timeframe.rawValue, systemImage: timeframe.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedTimeframe.icon)
                                .font(.caption)
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text(selectedTimeframe.rawValue)
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
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if missionManager.isLoading {
                loadingView
            } else if filteredMissions.isEmpty {
                emptyStateView
            } else {
                missionContentView
            }
        }
    }
    
    // MARK: - Mission Content View
    private var missionContentView: some View {
        Group {
            switch viewMode {
            case .cards:
                missionCardsView
            case .list:
                missionListView
            case .timeline:
                missionTimelineView
            case .board:
                missionBoardView
            }
        }
    }
    
    // MARK: - Mission Cards View
    private var missionCardsView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: IgnitionSpacing.md) {
                ForEach(Array(filteredMissions.enumerated()), id: \.element.id) { index, mission in
                    MissionCardView(
                        mission: mission,
                        onTap: {
                            selectedMissionForDetails = mission
                            audioHapticsManager.uiTapped()
                        },
                        onComplete: {
                            completeMission(mission)
                        },
                        onToggleFavorite: {
                            toggleMissionFavorite(mission)
                        }
                    )
                    .opacity(animateMissions ? 1 : 0)
                    .scaleEffect(animateMissions ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateMissions)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Mission List View
    private var missionListView: some View {
        ScrollView {
            LazyVStack(spacing: IgnitionSpacing.sm) {
                ForEach(Array(filteredMissions.enumerated()), id: \.element.id) { index, mission in
                    MissionRowView(
                        mission: mission,
                        onTap: {
                            selectedMissionForDetails = mission
                            audioHapticsManager.uiTapped()
                        },
                        onComplete: {
                            completeMission(mission)
                        },
                        onToggleFavorite: {
                            toggleMissionFavorite(mission)
                        }
                    )
                    .opacity(animateMissions ? 1 : 0)
                    .offset(x: animateMissions ? 0 : 50)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05), value: animateMissions)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Mission Timeline View
    private var missionTimelineView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: IgnitionSpacing.lg) {
                ForEach(groupedMissionsByDeadline, id: \.key) { dateGroup in
                    VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
                        // Date Header
                        HStack {
                            Text(formatDateForTimeline(dateGroup.key))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Spacer()
                            
                            Text("\(dateGroup.value.count) missions")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.horizontal, IgnitionSpacing.md)
                        
                        // Missions for this date
                        ForEach(dateGroup.value, id: \.id) { mission in
                            MissionTimelineItemView(
                                mission: mission,
                                onTap: {
                                    selectedMissionForDetails = mission
                                    audioHapticsManager.uiTapped()
                                },
                                onComplete: {
                                    completeMission(mission)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Mission Board View (Kanban Style)
    private var missionBoardView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: IgnitionSpacing.md) {
                ForEach(MissionStatus.allCases, id: \.self) { status in
                    MissionBoardColumnView(
                        status: status,
                        missions: filteredMissions.filter { $0.status == status },
                        onMissionTap: { mission in
                            selectedMissionForDetails = mission
                            audioHapticsManager.uiTapped()
                        },
                        onMissionComplete: { mission in
                            completeMission(mission)
                        }
                    )
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Helper Views
    private func missionStatCard(title: String, value: String, icon: String, color: Color) -> some View {
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
    
    private func filterChip(title: String, icon: String, isSelected: Bool, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.3) : themeManager.primaryColor.opacity(0.3))
                        .cornerRadius(8)
                }
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
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Loading & Empty States
    private var loadingView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.primaryColor)
            
            Text("Loading missions...")
                .font(.headline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: hasActiveFilters ? "magnifyingglass" : "target")
                .font(.system(size: 60))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text(hasActiveFilters ? "No Missions Found" : "No Missions Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(hasActiveFilters ? "Try adjusting your search filters" : "New missions will be generated automatically")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearAllFilters()
                    audioHapticsManager.uiTapped()
                }
                .buttonStyle(.bordered)
                .tint(themeManager.primaryColor)
            } else {
                Button("Create Custom Mission") {
                    showingMissionCreator = true
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
        HStack {
            Button(action: {
                showingProgressAnalytics = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: AssetNames.ChartIcons.analytics.systemName)
                    .foregroundColor(themeManager.primaryColor)
            }
            
            Button(action: {
                showingLeaderboard = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: "trophy")
                    .foregroundColor(themeManager.primaryColor)
            }
        }
    }
    
    private var trailingToolbarItems: some View {
        HStack {
            Menu {
                Button("History", systemImage: "clock.arrow.circlepath") {
                    showingMissionHistory = true
                }
                
                Button("Achievements", systemImage: "rosette") {
                    showingAchievements = true
                }
                
                Button("Custom Missions", systemImage: "person.crop.circle.badge.plus") {
                    showingCustomMissions = true
                }
                
                Button("Templates", systemImage: "doc.on.doc") {
                    showingMissionTemplates = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(themeManager.primaryColor)
            }
            
            Button(action: {
                showingMissionCreator = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: AssetNames.SystemIcons.addButton.systemName)
                    .foregroundColor(themeManager.primaryColor)
                    .font(.title3)
            }
        }
    }
    
    // MARK: - Mission Completion Overlay
    private var missionCompletionOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .ignoresSafeArea()
            
            VStack(spacing: IgnitionSpacing.lg) {
                // Celebration Animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(showingCompletionAnimation ? 1.2 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showingCompletionAnimation)
                
                VStack(spacing: IgnitionSpacing.sm) {
                    Text("Mission Completed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You earned \(completedMissionReward) points!")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Button("Awesome!") {
                    showingCompletionAnimation = false
                    audioHapticsManager.missionCompleted()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(IgnitionSpacing.xl)
        }
    }
    
    // MARK: - Computed Properties for Data Processing
    private var hasActiveFilters: Bool {
        selectedFilter != .all ||
        selectedDifficulty != .all ||
        selectedTimeframe != .all ||
        !searchText.isEmpty
    }
    
    private var navigationTitle: String {
        if hasActiveFilters {
            return "\(filteredMissions.count) Missions"
        } else {
            return "Missions"
        }
    }
    
    private var missionLevel: Int {
        missionPoints / 1000 + 1
    }
    
    private var groupedMissionsByDeadline: [(key: Date, value: [IgnitionMissionModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMissions.filter { $0.expiresAt != nil }) { mission in
            calendar.startOfDay(for: mission.expiresAt!)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - Helper Methods
    private func setupView() {
        loadMissionData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateMissions = true
        }
        
        // Listen for mission completion
        NotificationCenter.default.addObserver(
            forName: .missionCompleted,
            object: nil,
            queue: .main
        ) { notification in
            if let mission = notification.object as? IgnitionMissionModel {
                showMissionCompletionAnimation(mission: mission)
            }
        }
    }
    
    private func showMissionCompletionAnimation(mission: IgnitionMissionModel) {
        completedMissionTitle = mission.title
        completedMissionReward = mission.rewardPoints
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showingCompletionOverlay = true
        }
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingCompletionOverlay = false
            }
        }
    }
    
    private func loadMissionData() {
        currentStreak = calculateMissionStreak()
        missionPoints = calculateTotalMissionPoints()
    }
    
    private func refreshData() async {
        refreshing = true
        
        await MainActor.run {
            missionManager.loadMissions()
            loadMissionData()
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        refreshing = false
    }
    
    private func missionPriority(_ mission: IgnitionMissionModel) -> Int {
        var priority = 0
        
        // Deadline urgency
        if let expiresAt = mission.expiresAt {
            let timeUntilExpiry = expiresAt.timeIntervalSinceNow
            if timeUntilExpiry < 86400 { // Less than 1 day
                priority += 100
            } else if timeUntilExpiry < 259200 { // Less than 3 days
                priority += 50
            }
        }
        
        // Difficulty points
        priority += mission.difficulty.points / 10
        
        // Progress bonus
        let progress = missionProgress(mission)
        if progress > 0.5 {
            priority += 25
        }
        
        return priority
    }
    
    private func missionProgress(_ mission: IgnitionMissionModel) -> Double {
        return Double(mission.currentProgress) / Double(mission.targetValue)
    }
    
    private func missionCountForFilter(_ filter: MissionFilter) -> Int {
        switch filter {
        case .all:
            return missionManager.missions.count
        case .available:
            return missionManager.missions.filter { $0.status == .available }.count
        case .inProgress:
            return missionManager.missions.filter { $0.status == .inProgress }.count
        case .completed:
            return missionManager.missions.filter { $0.status == .completed }.count
        case .expired:
            return missionManager.missions.filter { $0.status == .expired }.count
        case .favorites:
            return missionManager.missions.filter { $0.isFavorite }.count
        }
    }
    
    private func completeMission(_ mission: IgnitionMissionModel) {
        missionToComplete = mission
        completedMissionReward = mission.rewardPoints
        
        missionManager.completeMission(mission)
        
        showingCompletionAnimation = true
        audioHapticsManager.missionCompleted()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showingCompletionAnimation = false
        }
    }
    
    private func toggleMissionFavorite(_ mission: IgnitionMissionModel) {
        var updatedMission = mission
        updatedMission.isFavorite.toggle()
        missionManager.updateMission(updatedMission)
        audioHapticsManager.uiTapped()
    }
    
    private func clearAllFilters() {
        selectedFilter = .all
        selectedDifficulty = .all
        selectedTimeframe = .all
        searchText = ""
    }
    
    private func calculateMissionStreak() -> Int {
        // Calculate consecutive days with completed missions
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let dayMissions = missionManager.missions.filter { mission in
                guard let completedAt = mission.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: currentDate)
            }
            
            if dayMissions.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func calculateTotalMissionPoints() -> Int {
        return missionManager.missions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.rewardPoints }
    }
    
    private func formatDateForTimeline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
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

struct MissionCardView: View {
    let mission: IgnitionMissionModel
    let onTap: () -> Void
    let onComplete: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            // Header
            HStack {
                // Difficulty Indicator
                Circle()
                    .fill(mission.difficulty.color)
                    .frame(width: 8, height: 8)
                
                Spacer()
                
                // Spark Reward Pill (like in image)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text("\(mission.rewardPoints)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(IgnitionColors.ignitionOrange)
                )
            }
            
            // Mission Icon (use custom icon if available, otherwise type icon)
            Image(systemName: mission.customIcon ?? mission.type.icon)
                .foregroundColor(themeManager.primaryColor)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Title & Description
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(mission.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(2)
                
                Text(mission.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(3)
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Text("\(mission.currentProgress)/\(mission.targetValue)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.secondaryColor.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(themeManager.primaryColor)
                            .frame(width: geometry.size.width * missionProgress, height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 0.5), value: missionProgress)
                    }
                }
                .frame(height: 4)
            }
            
            // Footer
            HStack {
                Spacer()
                
                // Action Button or Time Until Expiry
                if mission.status == .available && missionProgress >= 1.0 {
                    Button("Complete") {
                        onComplete()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, IgnitionSpacing.md)
                    .padding(.vertical, 6)
                    .background(IgnitionColors.ignitionOrange)
                    .foregroundColor(.white)
                    .cornerRadius(IgnitionCornerRadius.sm)
                } else if let expiresAt = mission.expiresAt {
                    Text(timeUntilExpiry(expiresAt))
                        .font(.caption2)
                        .foregroundColor(isUrgent(expiresAt) ? .red : themeManager.secondaryTextColor)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var missionProgress: Double {
        return Double(mission.currentProgress) / Double(mission.targetValue)
    }
    
    private func timeUntilExpiry(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func isUrgent(_ date: Date) -> Bool {
        return date.timeIntervalSinceNow < 86400 // Less than 24 hours
    }
}

struct MissionRowView: View {
    let mission: IgnitionMissionModel
    let onTap: () -> Void
    let onComplete: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Mission Icon & Difficulty
            VStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: mission.type.icon)
                    .foregroundColor(themeManager.primaryColor)
                    .font(.title2)
                
                Circle()
                    .fill(mission.difficulty.color)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text(mission.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if mission.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(mission.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                // Progress & Points
                HStack {
                    // Progress
                    Text("\(mission.currentProgress)/\(mission.targetValue)")
                        .font(.caption2)
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(themeManager.primaryColor.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(themeManager.primaryColor)
                    
                    // Points
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text("\(mission.rewardPoints)")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Expiry
                    if let expiresAt = mission.expiresAt {
                        Text(timeUntilExpiry(expiresAt))
                            .font(.caption2)
                            .foregroundColor(isUrgent(expiresAt) ? .red : themeManager.secondaryTextColor)
                    }
                }
            }
            
            // Action Button
            if mission.status == .available && missionProgress >= 1.0 {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button("Dettagli", systemImage: "info.circle") {
                onTap()
            }
            
            Button(mission.isFavorite ? "Rimuovi dai Preferiti" : "Aggiungi ai Preferiti", 
                   systemImage: mission.isFavorite ? "heart.slash" : "heart") {
                onToggleFavorite()
            }
            
            if mission.status == .available && missionProgress >= 1.0 {
                Button("Completa", systemImage: "checkmark.circle") {
                    onComplete()
                }
            }
        }
    }
    
    private var missionProgress: Double {
        return Double(mission.currentProgress) / Double(mission.targetValue)
    }
    
    private func timeUntilExpiry(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func isUrgent(_ date: Date) -> Bool {
        return date.timeIntervalSinceNow < 86400
    }
}

struct MissionTimelineItemView: View {
    let mission: IgnitionMissionModel
    let onTap: () -> Void
    let onComplete: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(mission.difficulty.color)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(mission.difficulty.color.opacity(0.3))
                    .frame(width: 2, height: 30)
            }
            
            // Content
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text(mission.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    if mission.status == .available && missionProgress >= 1.0 {
                        Button("Completa") {
                            onComplete()
                        }
                        .font(.caption2)
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(themeManager.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                }
                
                Text(mission.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                HStack {
                    Text("\(mission.currentProgress)/\(mission.targetValue)")
                        .font(.caption2)
                        .foregroundColor(themeManager.primaryColor)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text("\(mission.rewardPoints)")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding(.vertical, IgnitionSpacing.sm)
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var missionProgress: Double {
        return Double(mission.currentProgress) / Double(mission.targetValue)
    }
}

struct MissionBoardColumnView: View {
    let status: MissionStatus
    let missions: [IgnitionMissionModel]
    let onMissionTap: (IgnitionMissionModel) -> Void
    let onMissionComplete: (IgnitionMissionModel) -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            // Column Header
            HStack {
                Text(status.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Text("\(missions.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, IgnitionSpacing.xs)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(status.color)
            }
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.vertical, IgnitionSpacing.sm)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(IgnitionCornerRadius.md)
            
            // Missions
            ScrollView {
                LazyVStack(spacing: IgnitionSpacing.sm) {
                    ForEach(missions, id: \.id) { mission in
                        MissionBoardCardView(
                            mission: mission,
                            onTap: {
                                onMissionTap(mission)
                            },
                            onComplete: {
                                onMissionComplete(mission)
                            }
                        )
                    }
                }
                .padding(.horizontal, IgnitionSpacing.sm)
            }
        }
        .frame(width: 280)
        .background(status.color.opacity(0.05))
        .cornerRadius(IgnitionCornerRadius.lg)
    }
}

struct MissionBoardCardView: View {
    let mission: IgnitionMissionModel
    let onTap: () -> Void
    let onComplete: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            // Header
            HStack {
                Circle()
                    .fill(mission.difficulty.color)
                    .frame(width: 6, height: 6)
                
                Text(mission.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // Description
            Text(mission.description)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(3)
            
            // Progress
            HStack {
                Text("\(mission.currentProgress)/\(mission.targetValue)")
                    .font(.caption2)
                    .foregroundColor(themeManager.primaryColor)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text("\(mission.rewardPoints)")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Action
            if mission.status == .available && missionProgress >= 1.0 {
                Button("Completa") {
                    onComplete()
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(themeManager.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(IgnitionCornerRadius.sm)
            }
        }
        .padding(IgnitionSpacing.sm)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var missionProgress: Double {
        return Double(mission.currentProgress) / Double(mission.targetValue)
    }
}

// MARK: - Extensions

extension MissionStatus {
    var color: Color {
        switch self {
        case .available: return .green
        case .inProgress: return .orange
        case .completed: return .blue
        case .expired: return .red
        }
    }
}

extension IgnitionMissionModel {
    mutating func toggleFavorite() {
        isFavorite.toggle()
        // Save to persistence if needed
    }
}

// MARK: - Placeholder Views for Sheets

struct MissionCreatorView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Creatore Missioni")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verrà implementato il creatore di missioni personalizzate")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Nuova Missione")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionLeaderboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Classifica Missioni")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verrà mostrata la classifica globale")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Classifica")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionAchievementsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Obiettivi Missioni")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati tutti gli obiettivi")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Obiettivi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionHistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Cronologia Missioni")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verrà mostrata la cronologia completa")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Cronologia")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CustomMissionsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Missioni Personalizzate")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno gestite le missioni create dall'utente")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Personalizzate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionTemplatesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Template Missioni")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati i template disponibili")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Template")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionProgressAnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Analisi Progressi")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrate le analisi dettagliate dei progressi")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Analisi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MissionDetailView: View {
    let mission: IgnitionMissionModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Dettagli Missione")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati i dettagli della missione")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle(mission.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MissionsViewExpanded()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
