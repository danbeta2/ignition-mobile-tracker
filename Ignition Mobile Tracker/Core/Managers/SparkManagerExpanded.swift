//
//  SparkManagerExpanded.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
class SparkManagerExpanded: ObservableObject {
    static let shared = SparkManagerExpanded()
    
    // MARK: - Published Properties
    @Published var sparks: [SparkModel] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var syncStatus: SyncStatus = .idle
    @Published var analytics: SparkAnalytics = SparkAnalytics()
    @Published var suggestions: [SparkSuggestion] = []
    @Published var achievements: [Achievement] = []
    @Published var streakInfo: StreakInfo = StreakInfo()
    
    // MARK: - Advanced Features
    @Published var smartCategories: [SmartCategory] = []
    @Published var patterns: [BehaviorPattern] = []
    @Published var predictions: [Prediction] = []
    @Published var insights: [Insight] = []
    @Published var goals: [Goal] = []
    @Published var reminders: [Reminder] = []
    
    // MARK: - Configuration
    @Published var settings: SparkSettings = SparkSettings()
    @Published var filters: SparkFilters = SparkFilters()
    @Published var preferences: UserPreferences = UserPreferences()
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private let userProfileManager = UserProfileManager.shared
    private let notificationManager = NotificationManager.shared
    private let analyticsEngine = AnalyticsEngine()
    private let mlEngine = MachineLearningEngine()
    private let syncEngine = SyncEngine()
    
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var autoSaveTimer: Timer?
    private var analyticsTimer: Timer?
    
    // MARK: - Cache & Performance
    private var sparkCache: [String: SparkModel] = [:]
    private var categoryCache: [SparkCategory: [SparkModel]] = [:]
    private var dateCache: [Date: [SparkModel]] = [:]
    private var searchCache: [String: [SparkModel]] = [:]
    private let cacheQueue = DispatchQueue(label: "spark.cache", qos: .utility)
    
    // MARK: - Initialization
    private init() {
        setupObservers()
        setupTimers()
        loadSettings()
        loadSparks()
    }
    
    deinit {
        Task { @MainActor in
            stopTimers()
        }
        cancellables.removeAll()
    }
    
    // MARK: - Core CRUD Operations (Enhanced)
    
    func loadSparks() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Load from cache first for immediate UI response
                await loadFromCache()
                
                // Then load from persistence
                let loadedSparks = try await loadFromPersistence()
                
                await MainActor.run {
                    self.sparks = loadedSparks
                    self.updateCaches()
                    self.generateSuggestions()
                    self.detectPatterns()
                    self.updateStreakInfo()
                    self.isLoading = false
                }
                
                // Call async methods separately
                await updateAnalytics()
                await checkAchievements()
                
                // Background sync if enabled
                if settings.autoSync {
                    await syncWithCloud()
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Errore nel caricamento: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func addSpark(_ spark: SparkModel) {
        Task {
            do {
                var newSpark = spark
                newSpark.id = UUID()
                newSpark.createdAt = Date()
                
                // Add to local collection immediately
                await MainActor.run {
                    self.sparks.append(newSpark)
                    self.updateCaches()
                }
                
                // Save to persistence
                try await saveToPersistence(newSpark)
                
                // Update related systems
                await processSparkAdded(newSpark)
                
                // Trigger notifications and achievements
                await checkForNotifications(newSpark)
                await checkAchievements()
                
                // Update analytics
                await updateAnalytics()
                
                // Generate new suggestions
                await generateSuggestions()
                
                // Sync if enabled
                if settings.autoSync {
                    await syncWithCloud()
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Errore nel salvataggio: \(error.localizedDescription)"
                    // Remove from local collection if save failed
                    self.sparks.removeAll { $0.id == spark.id }
                    self.updateCaches()
                }
            }
        }
    }
    
    func updateSpark(_ spark: SparkModel) {
        Task {
            do {
                var updatedSpark = spark
                updatedSpark.updatedAt = Date()
                
                // Update in local collection
                await MainActor.run {
                    if let index = self.sparks.firstIndex(where: { $0.id == spark.id }) {
                        self.sparks[index] = updatedSpark
                        self.updateCaches()
                    }
                }
                
                // Save to persistence
                try await saveToPersistence(updatedSpark)
                
                // Update analytics
                await updateAnalytics()
                
                // Sync if enabled
                if settings.autoSync {
                    await syncWithCloud()
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Errore nell'aggiornamento: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteSpark(_ spark: SparkModel) {
        Task {
            do {
                // Remove from local collection
                await MainActor.run {
                    self.sparks.removeAll { $0.id == spark.id }
                    self.updateCaches()
                }
                
                // Delete from persistence
                try await deleteFromPersistence(spark)
                
                // Update related systems
                await processSparkDeleted(spark)
                
                // Update analytics
                await updateAnalytics()
                
                // Sync if enabled
                if settings.autoSync {
                    await syncWithCloud()
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Errore nell'eliminazione: \(error.localizedDescription)"
                    // Re-add to local collection if delete failed
                    self.sparks.append(spark)
                    self.updateCaches()
                }
            }
        }
    }
    
    // MARK: - Advanced Search & Filtering
    
    func searchSparks(query: String, filters: SparkFilters? = nil) -> [SparkModel] {
        let cacheKey = "\(query)_\(filters?.hashValue ?? 0)"
        
        if let cached = searchCache[cacheKey] {
            return cached
        }
        
        var results = sparks
        
        // Text search
        if !query.isEmpty {
            results = results.filter { spark in
                spark.title.localizedCaseInsensitiveContains(query) ||
                (spark.notes?.localizedCaseInsensitiveContains(query) ?? false) ||
                spark.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
                spark.category.rawValue.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        let filtersToUse = filters ?? (self.filters.isEmpty ? nil : self.filters)
        if let filtersToUse = filtersToUse {
            results = applyFilters(to: results, filters: filtersToUse)
        }
        
        // Cache results
        searchCache[cacheKey] = results
        
        return results
    }
    
    func getSparks(from startDate: Date, to endDate: Date) -> [SparkModel] {
        return sparks.filter { spark in
            spark.createdAt >= startDate && spark.createdAt <= endDate
        }
    }
    
    func getSparksByCategory(_ category: SparkCategory) -> [SparkModel] {
        if let cached = categoryCache[category] {
            return cached
        }
        
        let results = sparks.filter { $0.category == category }
        categoryCache[category] = results
        return results
    }
    
    func getSparksByIntensity(_ intensity: SparkIntensity) -> [SparkModel] {
        return sparks.filter { $0.intensity == intensity }
    }
    
    func getSparksByTags(_ tags: [String]) -> [SparkModel] {
        return sparks.filter { spark in
            !Set(spark.tags).isDisjoint(with: Set(tags))
        }
    }
    
    func getFavoriteSparks() -> [SparkModel] {
        return sparks.filter { $0.isFavorite }
    }
    
    // MARK: - Analytics & Insights
    
    func generateAnalytics() -> SparkAnalytics {
        let totalSparks = sparks.count
        let totalPoints = sparks.reduce(0) { $0 + $1.points }
        let averageIntensity = sparks.isEmpty ? 0 : Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        
        let categoryBreakdown = Dictionary(grouping: sparks, by: { $0.category })
            .mapValues { $0.count }
        
        let intensityBreakdown = Dictionary(grouping: sparks, by: { $0.intensity })
            .mapValues { $0.count }
        
        let timePatterns = analyzeTimePatterns()
        let trends = calculateTrends()
        let correlations = findCorrelations()
        
        return SparkAnalytics(
            totalSparks: totalSparks,
            totalPoints: totalPoints,
            averageIntensity: averageIntensity,
            categoryBreakdown: categoryBreakdown,
            intensityBreakdown: intensityBreakdown,
            timePatterns: timePatterns,
            trends: trends,
            correlations: correlations,
            productivity: calculateProductivityScore(),
            consistency: calculateConsistencyScore(),
            growth: calculateGrowthRate()
        )
    }
    
    func generateInsights() -> [Insight] {
        var insights: [Insight] = []
        
        // Pattern-based insights
        insights.append(contentsOf: generatePatternInsights())
        
        // Trend-based insights
        insights.append(contentsOf: generateTrendInsights())
        
        // Comparative insights
        insights.append(contentsOf: generateComparativeInsights())
        
        // Behavioral insights
        insights.append(contentsOf: generateBehavioralInsights())
        
        // Goal-based insights
        insights.append(contentsOf: generateGoalInsights())
        
        return insights.sorted { $0.priority > $1.priority }
    }
    
    func generatePredictions() -> [Prediction] {
        return mlEngine.generatePredictions(from: sparks)
    }
    
    func detectPatterns() {
        Task {
            let detectedPatterns = await mlEngine.detectPatterns(in: sparks)
            
            await MainActor.run {
                self.patterns = detectedPatterns
            }
        }
    }
    
    // MARK: - Smart Suggestions
    
    func generateSuggestions() {
        Task {
            var suggestions: [SparkSuggestion] = []
            
            // Time-based suggestions
            suggestions.append(contentsOf: generateTimeBasedSuggestions())
            
            // Category-based suggestions
            suggestions.append(contentsOf: generateCategoryBasedSuggestions())
            
            // Pattern-based suggestions
            suggestions.append(contentsOf: generatePatternBasedSuggestions())
            
            // Goal-based suggestions
            suggestions.append(contentsOf: generateGoalBasedSuggestions())
            
            // ML-powered suggestions
            suggestions.append(contentsOf: await mlEngine.generateSuggestions(from: sparks))
            
            await MainActor.run {
                self.suggestions = suggestions.sorted { $0.priority > $1.priority }
            }
        }
    }
    
    // MARK: - Achievement System
    
    func checkAchievements() {
        Task {
            let newAchievements = await achievementEngine.checkAchievements(for: sparks)
            
            await MainActor.run {
                for achievement in newAchievements {
                    if !self.achievements.contains(where: { $0.id == achievement.id }) {
                        self.achievements.append(achievement)
                        self.notifyAchievementUnlocked(achievement)
                    }
                }
            }
        }
    }
    
    // MARK: - Goal Management
    
    func setGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
        generateSuggestions() // Update suggestions based on new goal
    }
    
    func updateGoalProgress() {
        for i in 0..<goals.count {
            goals[i].currentProgress = calculateGoalProgress(goals[i])
            
            if goals[i].currentProgress >= goals[i].targetValue && !goals[i].isCompleted {
                goals[i].isCompleted = true
                goals[i].completedAt = Date()
                notifyGoalCompleted(goals[i])
            }
        }
        saveGoals()
    }
    
    // MARK: - Sync & Backup
    
    func syncWithCloud() async {
        syncStatus = .syncing
        
        do {
            try await syncEngine.sync(sparks: sparks)
            syncStatus = .synced
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    func exportData(format: ExportFormat) async throws -> Data {
        switch format {
        case .json:
            return try JSONEncoder().encode(sparks)
        case .csv:
            return try generateCSV()
        case .pdf:
            return try await generatePDF()
        }
    }
    
    func importData(from data: Data, format: ImportFormat) async throws {
        let importedSparks: [SparkModel]
        
        switch format {
        case .json:
            importedSparks = try JSONDecoder().decode([SparkModel].self, from: data)
        case .csv:
            importedSparks = try parseCSV(data)
        }
        
        for spark in importedSparks {
            await addSpark(spark)
        }
    }
    
    // MARK: - Notifications & Reminders
    
    func scheduleReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        notificationManager.scheduleNotification(for: reminder)
        saveReminders()
    }
    
    func cancelReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        notificationManager.cancelNotification(for: reminder)
        saveReminders()
    }
    
    // MARK: - Batch Operations
    
    func batchAddSparks(_ sparks: [SparkModel]) async {
        for spark in sparks {
            await addSpark(spark)
        }
    }
    
    func batchUpdateSparks(_ sparks: [SparkModel]) async {
        for spark in sparks {
            await updateSpark(spark)
        }
    }
    
    func batchDeleteSparks(_ sparks: [SparkModel]) async {
        for spark in sparks {
            await deleteSpark(spark)
        }
    }
    
    // MARK: - Performance Optimization
    
    func preloadData() async {
        // Preload frequently accessed data
        await loadFromCache()
        updateCaches()
        generateSuggestions()
    }
    
    func clearCache() {
        sparkCache.removeAll()
        categoryCache.removeAll()
        dateCache.removeAll()
        searchCache.removeAll()
    }
    
    func optimizePerformance() {
        // Clean old cache entries
        if searchCache.count > 100 {
            let keysToRemove = Array(searchCache.keys.prefix(50))
            keysToRemove.forEach { searchCache.removeValue(forKey: $0) }
        }
        
        // Compress old data
        compressOldSparks()
    }
    
    // MARK: - Private Helper Methods
    
    private func setupObservers() {
        // Observe app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
        
        // Observe user profile changes
        userProfileManager.$userProfile
            .sink { [weak self] _ in
                Task {
                    await self?.updateAnalytics()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupTimers() {
        // Auto-save timer
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.autoSave()
            }
        }
        
        // Analytics update timer
        analyticsTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.updateAnalytics()
            }
        }
    }
    
    private func stopTimers() {
        autoSaveTimer?.invalidate()
        analyticsTimer?.invalidate()
    }
    
    private func loadSettings() {
        // Load user settings from UserDefaults or persistence
        if let data = UserDefaults.standard.data(forKey: "SparkSettings"),
           let settings = try? JSONDecoder().decode(SparkSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "SparkSettings")
        }
    }
    
    private func loadFromCache() async {
        // Load from local cache for immediate response
        // This would typically load from a fast local database or file system
    }
    
    private func loadFromPersistence() async throws -> [SparkModel] {
        // Load from Core Data or other persistence layer
        // For now, return mock data
        return generateMockSparks()
    }
    
    private func saveToPersistence(_ spark: SparkModel) async throws {
        // Save to Core Data or other persistence layer
        // Update user profile stats
        await updateUserProfileAfterSparkAdded(spark)
    }
    
    private func deleteFromPersistence(_ spark: SparkModel) async throws {
        // Delete from Core Data or other persistence layer
        // Update user profile stats
        await updateUserProfileAfterSparkDeleted(spark)
    }
    
    private func updateCaches() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Update spark cache
            self.sparkCache = Dictionary(uniqueKeysWithValues: self.sparks.map { ($0.id.uuidString, $0) })
            
            // Update category cache
            self.categoryCache = Dictionary(grouping: self.sparks, by: { $0.category })
            
            // Update date cache
            let calendar = Calendar.current
            self.dateCache = Dictionary(grouping: self.sparks) { spark in
                calendar.startOfDay(for: spark.createdAt)
            }
        }
    }
    
    private func updateAnalytics() async {
        let newAnalytics = generateAnalytics()
        
        await MainActor.run {
            self.analytics = newAnalytics
        }
    }
    
    private func processSparkAdded(_ spark: SparkModel) async {
        // Update user profile
        await updateUserProfileAfterSparkAdded(spark)
        
        // Check for streaks
        updateStreakInfo()
        
        // Update goals
        updateGoalProgress()
        
        // Generate insights
        let newInsights = generateInsights()
        await MainActor.run {
            self.insights = newInsights
        }
    }
    
    private func processSparkDeleted(_ spark: SparkModel) async {
        // Update user profile
        await updateUserProfileAfterSparkDeleted(spark)
        
        // Update goals
        updateGoalProgress()
    }
    
    private func updateUserProfileAfterSparkAdded(_ spark: SparkModel) async {
        let userProfile = await persistenceController.getOrCreateUserProfile()
        
        var updatedProfile = userProfile
        updatedProfile.totalSparks += 1
        updatedProfile.totalPoints += calculatePoints(for: spark)
        updatedProfile.lastSparkDate = spark.createdAt
        
        // Update category counts
        switch spark.category {
        case .idea:
            updatedProfile.ideaSparks += 1
        case .decision:
            updatedProfile.decisionSparks += 1
        case .experiment:
            updatedProfile.experimentSparks += 1
        case .challenge:
            updatedProfile.challengeSparks += 1
        case .energy:
            updatedProfile.energySparks += 1
        }
        
        await persistenceController.updateUserProfile(updatedProfile)
    }
    
    private func updateUserProfileAfterSparkDeleted(_ spark: SparkModel) async {
        let userProfile = await persistenceController.getOrCreateUserProfile()
        
        var updatedProfile = userProfile
        updatedProfile.totalSparks = max(0, updatedProfile.totalSparks - 1)
        updatedProfile.totalPoints = max(0, updatedProfile.totalPoints - calculatePoints(for: spark))
        
        // Update category counts
        switch spark.category {
        case .idea:
            updatedProfile.ideaSparks = max(0, updatedProfile.ideaSparks - 1)
        case .decision:
            updatedProfile.decisionSparks = max(0, updatedProfile.decisionSparks - 1)
        case .experiment:
            updatedProfile.experimentSparks = max(0, updatedProfile.experimentSparks - 1)
        case .challenge:
            updatedProfile.challengeSparks = max(0, updatedProfile.challengeSparks - 1)
        case .energy:
            updatedProfile.energySparks = max(0, updatedProfile.energySparks - 1)
        }
        
        await persistenceController.updateUserProfile(updatedProfile)
    }
    
    private func calculatePoints(for spark: SparkModel) -> Int {
        var points = Int(spark.intensity.rawValue) * 10
        
        // Bonus for tags
        points += spark.tags.count * 2
        
        // Bonus for notes
        if let notes = spark.notes, !notes.isEmpty {
            points += 5
        }
        
        // Category multipliers
        switch spark.category {
        case .challenge:
            points = Int(Double(points) * 1.5)
        case .experiment:
            points = Int(Double(points) * 1.3)
        case .decision:
            points = Int(Double(points) * 1.2)
        default:
            break
        }
        
        return points
    }
    
    private func applyFilters(to sparks: [SparkModel], filters: SparkFilters) -> [SparkModel] {
        var results = sparks
        
        if let categories = filters.categories, !categories.isEmpty {
            results = results.filter { categories.contains($0.category) }
        }
        
        if let intensities = filters.intensities, !intensities.isEmpty {
            results = results.filter { intensities.contains($0.intensity) }
        }
        
        if let startDate = filters.startDate {
            results = results.filter { $0.createdAt >= startDate }
        }
        
        if let endDate = filters.endDate {
            results = results.filter { $0.createdAt <= endDate }
        }
        
        if let tags = filters.tags, !tags.isEmpty {
            results = results.filter { spark in
                !Set(spark.tags).isDisjoint(with: Set(tags))
            }
        }
        
        if filters.favoritesOnly {
            results = results.filter { $0.isFavorite }
        }
        
        if filters.withNotesOnly {
            results = results.filter { $0.notes != nil && !$0.notes!.isEmpty }
        }
        
        return results
    }
    
    // MARK: - Analytics Helper Methods
    
    private func analyzeTimePatterns() -> [TimePattern] {
        let calendar = Calendar.current
        var patterns: [TimePattern] = []
        
        // Hour patterns
        let hourGroups = Dictionary(grouping: sparks) { spark in
            calendar.component(.hour, from: spark.createdAt)
        }
        
        let mostActiveHour = hourGroups.max { $0.value.count < $1.value.count }
        if let hour = mostActiveHour {
            patterns.append(TimePattern(
                type: .hourly,
                value: hour.key,
                count: hour.value.count,
                description: "Ora più attiva: \(hour.key):00"
            ))
        }
        
        // Day of week patterns
        let dayGroups = Dictionary(grouping: sparks) { spark in
            calendar.component(.weekday, from: spark.createdAt)
        }
        
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }
        if let day = mostActiveDay {
            let dayName = calendar.weekdaySymbols[day.key - 1]
            patterns.append(TimePattern(
                type: .daily,
                value: day.key,
                count: day.value.count,
                description: "Giorno più attivo: \(dayName)"
            ))
        }
        
        return patterns
    }
    
    private func calculateTrends() -> [Trend] {
        // Calculate various trends
        var trends: [Trend] = []
        
        // Weekly trend
        let weeklyTrend = calculateWeeklyTrend()
        trends.append(weeklyTrend)
        
        // Category trend
        let categoryTrend = calculateCategoryTrend()
        trends.append(categoryTrend)
        
        // Intensity trend
        let intensityTrend = calculateIntensityTrend()
        trends.append(intensityTrend)
        
        return trends
    }
    
    private func calculateWeeklyTrend() -> Trend {
        let calendar = Calendar.current
        let now = Date()
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: now) ?? now
        
        let thisWeekSparks = sparks.filter { $0.createdAt >= lastWeek }
        let lastWeekSparks = sparks.filter { $0.createdAt >= twoWeeksAgo && $0.createdAt < lastWeek }
        
        let thisWeekCount = thisWeekSparks.count
        let lastWeekCount = lastWeekSparks.count
        
        let changePercentage = lastWeekCount > 0 ? Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount) * 100 : 0
        
        return Trend(
            type: .weekly,
            direction: changePercentage > 5 ? .increasing : (changePercentage < -5 ? .decreasing : .stable),
            changePercentage: changePercentage,
            description: "Trend settimanale: \(changePercentage > 0 ? "+" : "")\(String(format: "%.1f", changePercentage))%"
        )
    }
    
    private func calculateCategoryTrend() -> Trend {
        // Analyze which categories are trending up or down
        let recentSparks = sparks.filter { $0.createdAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        let categoryCount = Dictionary(grouping: recentSparks, by: { $0.category }).mapValues { $0.count }
        
        let trendingCategory = categoryCount.max { $0.value < $1.value }?.key ?? .idea
        
        return Trend(
            type: .category,
            direction: .increasing,
            changePercentage: 0,
            description: "Categoria in crescita: \(trendingCategory.rawValue.capitalized)"
        )
    }
    
    private func calculateIntensityTrend() -> Trend {
        let recentSparks = sparks.filter { $0.createdAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        let olderSparks = sparks.filter { 
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            return $0.createdAt >= twoWeeksAgo && $0.createdAt < weekAgo
        }
        
        let recentAvgIntensity = recentSparks.isEmpty ? 0 : Double(recentSparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(recentSparks.count)
        let olderAvgIntensity = olderSparks.isEmpty ? 0 : Double(olderSparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(olderSparks.count)
        
        let changePercentage = olderAvgIntensity > 0 ? (recentAvgIntensity - olderAvgIntensity) / olderAvgIntensity * 100 : 0
        
        return Trend(
            type: .intensity,
            direction: changePercentage > 5 ? .increasing : (changePercentage < -5 ? .decreasing : .stable),
            changePercentage: changePercentage,
            description: "Intensità media: \(changePercentage > 0 ? "+" : "")\(String(format: "%.1f", changePercentage))%"
        )
    }
    
    private func findCorrelations() -> [Correlation] {
        var correlations: [Correlation] = []
        
        // Time vs Intensity correlation
        let timeIntensityCorr = calculateTimeIntensityCorrelation()
        correlations.append(timeIntensityCorr)
        
        // Category vs Points correlation
        let categoryPointsCorr = calculateCategoryPointsCorrelation()
        correlations.append(categoryPointsCorr)
        
        return correlations
    }
    
    private func calculateTimeIntensityCorrelation() -> Correlation {
        // Simplified correlation calculation
        let hourIntensityPairs = sparks.map { spark in
            let hour = Calendar.current.component(.hour, from: spark.createdAt)
            return (Double(hour), Double(spark.intensity.rawValue))
        }
        
        let correlation = calculatePearsonCorrelation(hourIntensityPairs)
        
        return Correlation(
            variables: ("Ora del giorno", "Intensità"),
            coefficient: correlation,
            strength: abs(correlation) > 0.7 ? .strong : (abs(correlation) > 0.3 ? .moderate : .weak),
            description: "Correlazione tra ora del giorno e intensità: \(String(format: "%.2f", correlation))"
        )
    }
    
    private func calculateCategoryPointsCorrelation() -> Correlation {
        // Calculate correlation between category and points earned
        let categoryPoints = Dictionary(grouping: sparks, by: { $0.category })
            .mapValues { sparks in
                Double(sparks.reduce(0) { $0 + $1.points }) / Double(sparks.count)
            }
        
        // Simplified correlation - in reality would need more sophisticated calculation
        let correlation = 0.65 // Placeholder
        
        return Correlation(
            variables: ("Categoria", "Punti medi"),
            coefficient: correlation,
            strength: .moderate,
            description: "Correlazione tra categoria e punti guadagnati: \(String(format: "%.2f", correlation))"
        )
    }
    
    private func calculatePearsonCorrelation(_ pairs: [(Double, Double)]) -> Double {
        guard pairs.count > 1 else { return 0 }
        
        let n = Double(pairs.count)
        let sumX = pairs.reduce(0) { $0 + $1.0 }
        let sumY = pairs.reduce(0) { $0 + $1.1 }
        let sumXY = pairs.reduce(0) { $0 + ($1.0 * $1.1) }
        let sumX2 = pairs.reduce(0) { $0 + ($1.0 * $1.0) }
        let sumY2 = pairs.reduce(0) { $0 + ($1.1 * $1.1) }
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0
    }
    
    private func calculateProductivityScore() -> Double {
        guard !sparks.isEmpty else { return 0 }
        
        let avgIntensity = Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        let categoryDiversity = Double(Set(sparks.map { $0.category }).count) / Double(SparkCategory.allCases.count)
        let consistency = calculateConsistencyScore()
        
        return (avgIntensity / 4.0 * 0.4) + (categoryDiversity * 0.3) + (consistency * 0.3)
    }
    
    private func calculateConsistencyScore() -> Double {
        guard !sparks.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let days = Set(sparks.map { calendar.startOfDay(for: $0.createdAt) })
        let daysSinceFirst = calendar.dateComponents([.day], from: sparks.map { $0.createdAt }.min() ?? Date(), to: Date()).day ?? 1
        
        return Double(days.count) / Double(max(daysSinceFirst, 1))
    }
    
    private func calculateGrowthRate() -> Double {
        guard sparks.count > 1 else { return 0 }
        
        let sortedSparks = sparks.sorted { $0.createdAt < $1.createdAt }
        let firstWeek = sortedSparks.prefix(7)
        let lastWeek = sortedSparks.suffix(7)
        
        let firstWeekAvg = Double(firstWeek.count) / 7.0
        let lastWeekAvg = Double(lastWeek.count) / 7.0
        
        return firstWeekAvg > 0 ? (lastWeekAvg - firstWeekAvg) / firstWeekAvg : 0
    }
    
    // MARK: - Suggestion Generation Methods
    
    private func generateTimeBasedSuggestions() -> [SparkSuggestion] {
        var suggestions: [SparkSuggestion] = []
        
        // Analyze time patterns and suggest optimal times
        let timePatterns = analyzeTimePatterns()
        
        if let mostActiveHour = timePatterns.first(where: { $0.type == .hourly }) {
            suggestions.append(SparkSuggestion(
                id: UUID(),
                type: .timing,
                title: "Orario Ottimale",
                description: "Sei più produttivo intorno alle \(mostActiveHour.value):00. Prova a creare più Spark in questo orario.",
                priority: 0.8,
                category: nil,
                actionType: .schedule
            ))
        }
        
        return suggestions
    }
    
    private func generateCategoryBasedSuggestions() -> [SparkSuggestion] {
        var suggestions: [SparkSuggestion] = []
        
        // Find underused categories
        let categoryCount = Dictionary(grouping: sparks, by: { $0.category }).mapValues { $0.count }
        let totalSparks = sparks.count
        
        for category in SparkCategory.allCases {
            let count = categoryCount[category] ?? 0
            let percentage = totalSparks > 0 ? Double(count) / Double(totalSparks) : 0
            
            if percentage < 0.1 { // Less than 10% usage
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .category,
                    title: "Esplora \(category.rawValue.capitalized)",
                    description: "Non hai creato molti Spark nella categoria \(category.rawValue). Prova a esplorare questa area!",
                    priority: 0.6,
                    category: category,
                    actionType: .create
                ))
            }
        }
        
        return suggestions
    }
    
    private func generatePatternBasedSuggestions() -> [SparkSuggestion] {
        var suggestions: [SparkSuggestion] = []
        
        // Analyze patterns and suggest improvements
        for pattern in patterns {
            switch pattern.type {
            case .productivity:
                if pattern.confidence > 0.7 {
                    suggestions.append(SparkSuggestion(
                        id: UUID(),
                        type: .pattern,
                        title: "Pattern Produttività",
                        description: pattern.description,
                        priority: pattern.confidence,
                        category: nil,
                        actionType: .optimize
                    ))
                }
            case .timing:
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .timing,
                    title: "Ottimizza i Tempi",
                    description: pattern.description,
                    priority: pattern.confidence,
                    category: nil,
                    actionType: .schedule
                ))
            case .category:
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .category,
                    title: "Diversifica le Categorie",
                    description: pattern.description,
                    priority: pattern.confidence,
                    category: nil,
                    actionType: .diversify
                ))
            case .intensity:
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .pattern,
                    title: "Bilancia l'Intensità",
                    description: pattern.description,
                    priority: pattern.confidence,
                    category: nil,
                    actionType: .optimize
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateGoalBasedSuggestions() -> [SparkSuggestion] {
        var suggestions: [SparkSuggestion] = []
        
        for goal in goals where !goal.isCompleted {
            let progress = goal.currentProgress / goal.targetValue
            
            if progress < 0.5 {
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .goal,
                    title: "Obiettivo in Ritardo",
                    description: "Sei al \(Int(progress * 100))% del tuo obiettivo '\(goal.title)'. Accelera il ritmo!",
                    priority: 0.9,
                    category: nil,
                    actionType: .accelerate
                ))
            } else if progress > 0.8 {
                suggestions.append(SparkSuggestion(
                    id: UUID(),
                    type: .goal,
                    title: "Obiettivo Quasi Raggiunto",
                    description: "Sei al \(Int(progress * 100))% del tuo obiettivo '\(goal.title)'. Ancora un piccolo sforzo!",
                    priority: 0.7,
                    category: nil,
                    actionType: .complete
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Insight Generation Methods
    
    private func generatePatternInsights() -> [Insight] {
        var insights: [Insight] = []
        
        // Most productive time insight
        if let mostProductiveHour = findMostProductiveHour() {
            insights.append(Insight(
                id: UUID(),
                type: .pattern,
                title: "Orario di Picco Produttività",
                description: "Sei più produttivo alle \(mostProductiveHour):00. In questo orario crei Spark con intensità media del 20% superiore.",
                priority: 0.8,
                actionable: true,
                action: "Pianifica le attività più importanti in questo orario"
            ))
        }
        
        // Category preference insight
        if let preferredCategory = findPreferredCategory() {
            insights.append(Insight(
                id: UUID(),
                type: .preference,
                title: "Categoria Preferita",
                description: "Il 40% dei tuoi Spark sono nella categoria \(preferredCategory.rawValue). Questo indica una forte inclinazione verso questo tipo di attività.",
                priority: 0.6,
                actionable: true,
                action: "Prova a bilanciare con altre categorie per una crescita più completa"
            ))
        }
        
        return insights
    }
    
    private func generateTrendInsights() -> [Insight] {
        var insights: [Insight] = []
        
        let weeklyTrend = calculateWeeklyTrend()
        
        if weeklyTrend.direction == .increasing && weeklyTrend.changePercentage > 20 {
            insights.append(Insight(
                id: UUID(),
                type: .trend,
                title: "Crescita Accelerata",
                description: "La tua produttività è aumentata del \(String(format: "%.1f", weeklyTrend.changePercentage))% questa settimana. Ottimo lavoro!",
                priority: 0.9,
                actionable: true,
                action: "Mantieni questo ritmo e considera di aumentare i tuoi obiettivi"
            ))
        } else if weeklyTrend.direction == .decreasing && weeklyTrend.changePercentage < -20 {
            insights.append(Insight(
                id: UUID(),
                type: .trend,
                title: "Calo di Produttività",
                description: "La tua attività è diminuita del \(String(format: "%.1f", abs(weeklyTrend.changePercentage)))% questa settimana.",
                priority: 0.8,
                actionable: true,
                action: "Prova a identificare le cause e riprendi gradualmente"
            ))
        }
        
        return insights
    }
    
    private func generateComparativeInsights() -> [Insight] {
        var insights: [Insight] = []
        
        // Compare with previous periods
        let thisMonth = getSparks(from: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), to: Date())
        let lastMonth = getSparks(from: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(), to: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
        
        let thisMonthAvgIntensity = thisMonth.isEmpty ? 0 : Double(thisMonth.map { $0.intensity.rawValue }.reduce(0, +)) / Double(thisMonth.count)
        let lastMonthAvgIntensity = lastMonth.isEmpty ? 0 : Double(lastMonth.map { $0.intensity.rawValue }.reduce(0, +)) / Double(lastMonth.count)
        
        if thisMonthAvgIntensity > lastMonthAvgIntensity * 1.1 {
            insights.append(Insight(
                id: UUID(),
                type: .comparison,
                title: "Intensità in Crescita",
                description: "L'intensità media dei tuoi Spark è aumentata del \(String(format: "%.1f", (thisMonthAvgIntensity - lastMonthAvgIntensity) / lastMonthAvgIntensity * 100))% rispetto al mese scorso.",
                priority: 0.7,
                actionable: false,
                action: nil
            ))
        }
        
        return insights
    }
    
    private func generateBehavioralInsights() -> [Insight] {
        var insights: [Insight] = []
        
        // Analyze consistency
        let consistencyScore = calculateConsistencyScore()
        
        if consistencyScore > 0.8 {
            insights.append(Insight(
                id: UUID(),
                type: .behavioral,
                title: "Eccellente Consistenza",
                description: "Mantieni una routine molto consistente con un punteggio di \(String(format: "%.1f", consistencyScore * 100))%. Questo è un ottimo indicatore di disciplina.",
                priority: 0.6,
                actionable: false,
                action: nil
            ))
        } else if consistencyScore < 0.3 {
            insights.append(Insight(
                id: UUID(),
                type: .behavioral,
                title: "Migliora la Consistenza",
                description: "La tua consistenza è al \(String(format: "%.1f", consistencyScore * 100))%. Prova a creare una routine più regolare.",
                priority: 0.8,
                actionable: true,
                action: "Imposta promemoria giornalieri per creare almeno un Spark"
            ))
        }
        
        return insights
    }
    
    private func generateGoalInsights() -> [Insight] {
        var insights: [Insight] = []
        
        let completedGoals = goals.filter { $0.isCompleted }
        let activeGoals = goals.filter { !$0.isCompleted }
        
        if completedGoals.count > 0 {
            insights.append(Insight(
                id: UUID(),
                type: .achievement,
                title: "Obiettivi Raggiunti",
                description: "Hai completato \(completedGoals.count) obiettivi. Questo dimostra la tua capacità di mantenere la concentrazione sui risultati.",
                priority: 0.5,
                actionable: true,
                action: "Considera di impostare obiettivi più ambiziosi"
            ))
        }
        
        if activeGoals.count > 5 {
            insights.append(Insight(
                id: UUID(),
                type: .warning,
                title: "Troppi Obiettivi Attivi",
                description: "Hai \(activeGoals.count) obiettivi attivi. Potrebbe essere difficile mantenerli tutti.",
                priority: 0.7,
                actionable: true,
                action: "Considera di concentrarti sui 3-5 obiettivi più importanti"
            ))
        }
        
        return insights
    }
    
    // MARK: - Helper Methods for Insights
    
    private func findMostProductiveHour() -> Int? {
        let hourGroups = Dictionary(grouping: sparks) { spark in
            Calendar.current.component(.hour, from: spark.createdAt)
        }
        
        let hourIntensity = hourGroups.mapValues { sparks in
            sparks.isEmpty ? 0 : Double(sparks.map { $0.intensity.rawValue }.reduce(0, +)) / Double(sparks.count)
        }
        
        return hourIntensity.max { $0.value < $1.value }?.key
    }
    
    private func findPreferredCategory() -> SparkCategory? {
        let categoryCount = Dictionary(grouping: sparks, by: { $0.category }).mapValues { $0.count }
        return categoryCount.max { $0.value < $1.value }?.key
    }
    
    // MARK: - Notification Methods
    
    private func checkForNotifications(_ spark: SparkModel) async {
        // Check for streak notifications
        if shouldNotifyForStreak() {
            await notificationManager.sendStreakNotification(streakInfo.current)
        }
        
        // Check for achievement notifications
        await checkAchievements()
        
        // Check for milestone notifications
        if shouldNotifyForMilestone(spark) {
            await notificationManager.sendMilestoneNotification(sparks.count)
        }
    }
    
    private func shouldNotifyForStreak() -> Bool {
        return streakInfo.current > 0 && streakInfo.current % 7 == 0 // Every week
    }
    
    private func shouldNotifyForMilestone(_ spark: SparkModel) -> Bool {
        let milestones = [10, 25, 50, 100, 250, 500, 1000]
        return milestones.contains(sparks.count)
    }
    
    private func notifyAchievementUnlocked(_ achievement: Achievement) {
        Task {
            await notificationManager.sendAchievementNotification(achievement)
        }
    }
    
    private func notifyGoalCompleted(_ goal: Goal) {
        Task {
            await notificationManager.sendGoalCompletedNotification(goal)
        }
    }
    
    // MARK: - Goal Helper Methods
    
    private func calculateGoalProgress(_ goal: Goal) -> Double {
        switch goal.type {
        case .sparkCount:
            return Double(sparks.count)
        case .categoryDiversity:
            return Double(Set(sparks.map { $0.category }).count)
        case .streak:
            return Double(streakInfo.current)
        case .points:
            return Double(sparks.reduce(0) { $0 + $1.points })
        case .consistency:
            return calculateConsistencyScore() * 100
        }
    }
    
    private func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: "SparkGoals")
        }
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: "SparkGoals"),
           let goals = try? JSONDecoder().decode([Goal].self, from: data) {
            self.goals = goals
        }
    }
    
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "SparkReminders")
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "SparkReminders"),
           let reminders = try? JSONDecoder().decode([Reminder].self, from: data) {
            self.reminders = reminders
        }
    }
    
    // MARK: - Export/Import Helper Methods
    
    private func generateCSV() throws -> Data {
        var csv = "ID,Title,Category,Intensity,Points,Created,Updated,Notes,Tags\n"
        
        for spark in sparks {
            let row = [
                spark.id.uuidString,
                spark.title.replacingOccurrences(of: ",", with: ";"),
                spark.category.rawValue,
                String(spark.intensity.rawValue),
                String(spark.points),
                ISO8601DateFormatter().string(from: spark.createdAt),
                spark.updatedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                (spark.notes ?? "").replacingOccurrences(of: ",", with: ";"),
                spark.tags.joined(separator: "|")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv.data(using: .utf8) ?? Data()
    }
    
    private func generatePDF() async throws -> Data {
        // Placeholder for PDF generation
        // Would use PDFKit or similar to generate a formatted PDF report
        return Data()
    }
    
    private func parseCSV(_ data: Data) throws -> [SparkModel] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw SparkError.invalidData
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        var sparks: [SparkModel] = []
        
        for (index, line) in lines.enumerated() {
            guard index > 0, !line.isEmpty else { continue } // Skip header
            
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 9 else { continue }
            
            guard let id = UUID(uuidString: columns[0]),
                  let category = SparkCategory(rawValue: columns[2]),
                  let intensityValue = Int(columns[3]),
                  let intensity = SparkIntensity(rawValue: Int16(intensityValue)),
                  let points = Int(columns[4]),
                  let createdAt = ISO8601DateFormatter().date(from: columns[5]) else {
                continue
            }
            
            let updatedAt = columns[6].isEmpty ? nil : ISO8601DateFormatter().date(from: columns[6])
            let notes = columns[7].isEmpty ? nil : columns[7]
            let tags = columns[8].isEmpty ? [] : columns[8].components(separatedBy: "|")
            
            let spark = SparkModel(
                id: id,
                title: columns[1],
                notes: notes,
                category: category,
                intensity: intensity,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            sparks.append(spark)
        }
        
        return sparks
    }
    
    // MARK: - Background Tasks
    
    private func handleAppDidEnterBackground() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Perform background save
        Task {
            await autoSave()
            endBackgroundTask()
        }
    }
    
    private func handleAppWillEnterForeground() {
        // Refresh data when app becomes active
        loadSparks()
        Task {
            await updateAnalytics()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func autoSave() async {
        // Implement auto-save logic
        // Save current state to persistence
    }
    
    private func compressOldSparks() {
        // Compress sparks older than a certain date to save memory
        let cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        
        // Move old sparks to compressed storage
        let oldSparks = sparks.filter { $0.createdAt < cutoffDate }
        
        if !oldSparks.isEmpty {
            // Archive old sparks
            archiveOldSparks(oldSparks)
            
            // Remove from active collection
            sparks.removeAll { $0.createdAt < cutoffDate }
            updateCaches()
        }
    }
    
    private func archiveOldSparks(_ sparks: [SparkModel]) {
        // Archive old sparks to compressed storage
        // This could be a separate Core Data entity or file-based storage
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockSparks() -> [SparkModel] {
        var mockSparks: [SparkModel] = []
        let calendar = Calendar.current
        
        for i in 0..<50 {
            let daysAgo = Int.random(in: 0...30)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            let spark = SparkModel(
                title: "Spark di Test \(i + 1)",
                notes: i % 3 == 0 ? "Note di esempio per questo spark" : nil,
                category: SparkCategory.allCases.randomElement() ?? .idea,
                intensity: SparkIntensity.allCases.randomElement() ?? .medium,
                tags: i % 2 == 0 ? ["test", "mock"] : [],
                createdAt: date,
                updatedAt: nil
            )
            
            mockSparks.append(spark)
        }
        
        return mockSparks.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func updateStreakInfo() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var currentDate = today
        
        // Calculate current streak
        while true {
            let hasSparksOnDate = sparks.contains { calendar.isDate($0.createdAt, inSameDayAs: currentDate) }
            
            if hasSparksOnDate {
                if currentDate == today || calendar.isDate(currentDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today) ?? today) {
                    currentStreak += 1
                }
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                if currentDate == today {
                    // No sparks today, but check yesterday for current streak
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                    continue
                } else {
                    tempStreak = 0
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            
            // Stop after checking reasonable history
            if calendar.dateComponents([.day], from: currentDate, to: today).day ?? 0 > 365 {
                break
            }
        }
        
        streakInfo = StreakInfo(
            current: currentStreak,
            longest: longestStreak,
            lastSparkDate: sparks.first?.createdAt
        )
    }
}

// MARK: - Supporting Types and Extensions

enum SparkError: Error {
    case invalidData
    case saveFailed
    case loadFailed
    case syncFailed
}

enum SyncStatus {
    case idle
    case syncing
    case synced
    case error(String)
}

enum ExportFormat {
    case json
    case csv
    case pdf
}

enum ImportFormat {
    case json
    case csv
}

// MARK: - Data Models

struct SparkAnalytics: Codable {
    var totalSparks: Int = 0
    var totalPoints: Int = 0
    var averageIntensity: Double = 0
    var categoryBreakdown: [SparkCategory: Int] = [:]
    var intensityBreakdown: [SparkIntensity: Int] = [:]
    var timePatterns: [TimePattern] = []
    var trends: [Trend] = []
    var correlations: [Correlation] = []
    var productivity: Double = 0
    var consistency: Double = 0
    var growth: Double = 0
}

struct SparkSuggestion: Identifiable, Codable {
    let id: UUID
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Double
    let category: SparkCategory?
    let actionType: ActionType
    
    enum SuggestionType: String, Codable {
        case timing, category, pattern, goal, achievement
    }
    
    enum ActionType: String, Codable {
        case create, schedule, optimize, diversify, accelerate, complete
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let points: Int
    let unlockedAt: Date?
    let isUnlocked: Bool
}

struct StreakInfo: Codable {
    var current: Int = 0
    var longest: Int = 0
    var lastSparkDate: Date?
}

struct SmartCategory: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let keywords: [String]
    let suggestedIntensity: SparkIntensity
    let color: String
}

struct BehaviorPattern: Identifiable, Codable {
    let id: UUID
    let type: PatternType
    let description: String
    let confidence: Double
    let detectedAt: Date
    
    enum PatternType: String, Codable {
        case productivity, timing, category, intensity
    }
}

struct Prediction: Identifiable, Codable {
    let id: UUID
    let type: PredictionType
    let title: String
    let description: String
    let predictedValue: Double
    let confidence: Double
    let timeframe: String
    
    enum PredictionType: String, Codable {
        case sparkCount, productivity, streak, categoryUsage
    }
}

struct Insight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let priority: Double
    let actionable: Bool
    let action: String?
    
    enum InsightType: String, Codable {
        case pattern, trend, comparison, behavioral, achievement, warning, preference
    }
}

struct Goal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: GoalType
    let targetValue: Double
    var currentProgress: Double = 0
    let deadline: Date?
    var isCompleted: Bool = false
    var completedAt: Date?
    let createdAt: Date
    
    enum GoalType: String, Codable {
        case sparkCount, categoryDiversity, streak, points, consistency
    }
}

struct Reminder: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let scheduledTime: Date
    let repeatInterval: RepeatInterval?
    let isActive: Bool
    
    enum RepeatInterval: String, Codable {
        case daily, weekly, monthly
    }
}

struct SparkSettings: Codable {
    var autoSync: Bool = true
    var notificationsEnabled: Bool = true
    var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var weeklyGoal: Int = 20
    var streakNotifications: Bool = true
    var achievementNotifications: Bool = true
    var dataRetentionDays: Int = 365
    var autoBackup: Bool = true
}

struct SparkFilters: Codable, Hashable {
    var categories: [SparkCategory]?
    var intensities: [SparkIntensity]?
    var startDate: Date?
    var endDate: Date?
    var tags: [String]?
    var favoritesOnly: Bool = false
    var withNotesOnly: Bool = false
    
    var isEmpty: Bool {
        return categories?.isEmpty != false &&
               intensities?.isEmpty != false &&
               startDate == nil &&
               endDate == nil &&
               tags?.isEmpty != false &&
               !favoritesOnly &&
               !withNotesOnly
    }
}

struct UserPreferences: Codable {
    var defaultCategory: SparkCategory = .idea
    var defaultIntensity: SparkIntensity = .medium
    var autoAddTags: [String] = []
    var quickActions: [String] = []
    var theme: String = "system"
    var language: String = "it"
}

struct TimePattern: Identifiable, Codable {
    let id = UUID()
    let type: PatternType
    let value: Int
    let count: Int
    let description: String
    
    enum PatternType: String, Codable {
        case hourly, daily, weekly, monthly
    }
}

struct Trend: Identifiable, Codable {
    let id = UUID()
    let type: TrendType
    let direction: TrendDirection
    let changePercentage: Double
    let description: String
    
    enum TrendType: String, Codable {
        case weekly, monthly, category, intensity
    }
    
    enum TrendDirection: String, Codable {
        case increasing, decreasing, stable
    }
}

struct Correlation: Identifiable, Codable {
    let id = UUID()
    let variables: (String, String)
    let coefficient: Double
    let strength: CorrelationStrength
    let description: String
    
    enum CorrelationStrength: String, Codable {
        case weak, moderate, strong
    }
    
    // Custom coding for tuple
    private enum CodingKeys: String, CodingKey {
        case id, coefficient, strength, description, variable1, variable2
    }
    
    init(variables: (String, String), coefficient: Double, strength: CorrelationStrength, description: String) {
        self.variables = variables
        self.coefficient = coefficient
        self.strength = strength
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let variable1 = try container.decode(String.self, forKey: .variable1)
        let variable2 = try container.decode(String.self, forKey: .variable2)
        self.variables = (variable1, variable2)
        self.coefficient = try container.decode(Double.self, forKey: .coefficient)
        self.strength = try container.decode(CorrelationStrength.self, forKey: .strength)
        self.description = try container.decode(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(variables.0, forKey: .variable1)
        try container.encode(variables.1, forKey: .variable2)
        try container.encode(coefficient, forKey: .coefficient)
        try container.encode(strength, forKey: .strength)
        try container.encode(description, forKey: .description)
    }
}

// MARK: - Placeholder Classes

class AnalyticsEngine {
    // Placeholder for advanced analytics engine
}

class MachineLearningEngine {
    func generatePredictions(from sparks: [SparkModel]) -> [Prediction] {
        // Placeholder for ML predictions
        return []
    }
    
    func detectPatterns(in sparks: [SparkModel]) async -> [BehaviorPattern] {
        // Placeholder for ML pattern detection
        return []
    }
    
    func generateSuggestions(from sparks: [SparkModel]) async -> [SparkSuggestion] {
        // Placeholder for ML-powered suggestions
        return []
    }
}

class SyncEngine {
    func sync(sparks: [SparkModel]) async throws {
        // Placeholder for cloud sync
    }
}

class NotificationManager {
    static let shared = NotificationManager()
    
    func scheduleNotification(for reminder: Reminder) {
        // Placeholder for notification scheduling
    }
    
    func cancelNotification(for reminder: Reminder) {
        // Placeholder for notification cancellation
    }
    
    func sendStreakNotification(_ streak: Int) async {
        // Placeholder for streak notification
    }
    
    func sendMilestoneNotification(_ count: Int) async {
        // Placeholder for milestone notification
    }
    
    func sendAchievementNotification(_ achievement: Achievement) async {
        // Placeholder for achievement notification
    }
    
    func sendGoalCompletedNotification(_ goal: Goal) async {
        // Placeholder for goal completion notification
    }
}

let achievementEngine = AchievementEngine()

class AchievementEngine {
    func checkAchievements(for sparks: [SparkModel]) async -> [Achievement] {
        // Placeholder for achievement checking
        return []
    }
}

extension SparkModel {
    var isFavorite: Bool {
        get { return false } // Placeholder
        set { } // Placeholder
    }
}

// Preview removed - SparkManagerExpanded is a manager class, not a view
