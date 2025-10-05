//
//  MissionManager.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import CoreData
import Combine

// MARK: - Mission Manager
@MainActor
class MissionManager: ObservableObject {
    static let shared = MissionManager()
    
    @Published var missions: [IgnitionMissionModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Add references to other managers
    private let userProfileManager = UserProfileManager.shared
    private let sparkManager = SparkManager.shared
    
    private init() {
        loadMissions()
        setupNotificationObservers()
        setupMissionResetTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupMissionResetTimer() {
        // Check for resets when app enters foreground (battery-efficient)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Also check on first launch
        checkAndResetMissions()
    }
    
    @objc private func handleAppWillEnterForeground() {
        Task { @MainActor in
            checkAndResetMissions()
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for spark events to update mission progress
        NotificationCenter.default.publisher(for: .sparkAdded)
            .sink { [weak self] notification in
                print("🔔 MissionManager received .sparkAdded notification")
                if let spark = notification.object as? SparkModel {
                    print("📢 Processing spark for mission progress: \(spark.title) (\(spark.category.displayName))")
                    Task { @MainActor in
                        self?.updateMissionProgress(for: spark)
                    }
                } else {
                    print("⚠️ .sparkAdded notification received but no spark object found")
                }
            }
            .store(in: &cancellables)
        
        // Listen for card obtained events to update card achievement missions
        NotificationCenter.default.publisher(for: .cardObtained)
            .sink { [weak self] notification in
                print("🔔 MissionManager received .cardObtained notification")
                if let card = notification.object as? SparkCardModel {
                    print("📢 Processing card for mission progress: \(card.displayTitle)")
                    Task { @MainActor in
                        self?.updateCardMissionProgress(for: card)
                    }
                } else {
                    print("⚠️ .cardObtained notification received but no card object found")
                }
            }
            .store(in: &cancellables)
        
        // Listen for overload triggered events
        NotificationCenter.default.publisher(for: .overloadTriggered)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateOverloadMissions()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mission Operations
    func loadMissions() {
        isLoading = true
        error = nil
        
        // Load missions from Core Data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let savedMissions = self.persistenceController.fetchMissions()
            
            if savedMissions.isEmpty {
                // First launch - initialize fixed missions in Core Data
                print("📋 No missions in Core Data, initializing...")
                self.initializeFixedMissions()
            } else {
                // Load from Core Data
                print("📋 Loaded \(savedMissions.count) missions from Core Data")
                self.missions = savedMissions
            }
            
            // Check if we need to reset daily/weekly missions
            self.checkAndResetMissions()
            
            self.isLoading = false
        }
    }
    
    private func checkAndResetMissions() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check for daily reset (at midnight)
        let lastResetDate = UserDefaults.standard.object(forKey: "lastDailyReset") as? Date ?? Date.distantPast
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            resetDailyMissions()
            UserDefaults.standard.set(now, forKey: "lastDailyReset")
            print("🔄 Daily missions reset")
        }
        
        // Check for weekly reset (every Monday)
        let lastWeeklyReset = UserDefaults.standard.object(forKey: "lastWeeklyReset") as? Date ?? Date.distantPast
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        if lastWeeklyReset < startOfWeek {
            resetWeeklyMissions()
            UserDefaults.standard.set(now, forKey: "lastWeeklyReset")
            print("🔄 Weekly missions reset")
        }
    }
    
    private func resetDailyMissions() {
        for index in missions.indices {
            if missions[index].type == .daily {
                missions[index].currentProgress = 0
                missions[index].status = .available
                missions[index].completedAt = nil
            }
        }
    }
    
    private func resetWeeklyMissions() {
        for index in missions.indices {
            if missions[index].type == .weekly {
                missions[index].currentProgress = 0
                missions[index].status = .available
                missions[index].completedAt = nil
            }
        }
    }
    
    func completeMission(_ mission: IgnitionMissionModel) {
        if let index = missions.firstIndex(where: { $0.id == mission.id }) {
            var updatedMission = mission
            updatedMission.status = .completed
            updatedMission.completedAt = Date()
            missions[index] = updatedMission
            
            // Save to Core Data
            persistenceController.updateMission(updatedMission)
            print("💾 Mission completed and saved to Core Data: \(mission.title)")
            
            // Award points to user
            awardMissionReward(mission)
            
            // Play completion feedback
            AudioHapticsManager.shared.missionCompleted()
            
            NotificationCenter.default.post(name: .missionCompleted, object: mission)
        }
    }
    
    // MARK: - Mission Progress
    private func updateMissionProgress(for spark: SparkModel) {
        print("🎯 updateMissionProgress called for spark: \(spark.title)")
        let activeMissions = missions.filter { $0.status != .completed && $0.status != .expired }
        print("📊 Found \(activeMissions.count) active missions to check")
        
        for mission in activeMissions {
            var shouldUpdate = false
            var newProgress = mission.currentProgress
            
            // Category-based missions
            if let missionCategory = mission.category {
                if spark.category == missionCategory {
                    newProgress += 1
                    shouldUpdate = true
                }
            } else {
                // Special missions without category
                switch mission.title {
                case "Morning Spark":
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: spark.createdAt)
                    if hour < 12 {
                        newProgress += 1
                        shouldUpdate = true
                    }
                    
                case "Spark Streak", "Weekly Warrior":
                    // Count any spark
                    newProgress += 1
                    shouldUpdate = true
                    
                case "High Intensity":
                    if spark.intensity == .high || spark.intensity == .extreme {
                        newProgress += 1
                        shouldUpdate = true
                    }
                    
                case "Intensity Champion":
                    if spark.intensity == .high || spark.intensity == .extreme {
                        newProgress += 1
                        shouldUpdate = true
                    }
                    
                case "Diversity Champion":
                    // For now, just count any spark
                    newProgress += 1
                    shouldUpdate = true
                    
                case "Point Collector":
                    // Track total points earned this week
                    newProgress += spark.points
                    shouldUpdate = true
                    
                case "Consistent Creator":
                    // Track days with sparks (handled separately)
                    break
                    
                case "Grand Achiever":
                    // Track daily mission completions (handled separately)
                    break
                    
                // Achievement missions - Total spark count
                case "First Steps", "Rising Star", "Spark Veteran", "Spark Master", "Spark Legend":
                    // Track total sparks count
                    let totalSparks = sparkManager.sparks.count
                    newProgress = totalSparks
                    shouldUpdate = true
                    
                // Achievement missions - Total points
                case "Point Starter", "Point Earner", "Point Master":
                    // Track total points from user profile
                    let userProfile = persistenceController.getOrCreateUserProfile()
                    newProgress = userProfile.totalSparkPoints
                    shouldUpdate = true
                    
                // Achievement missions - Streak
                case "Week Warrior", "Month Champion", "Unstoppable":
                    // Track current streak from user profile
                    let (currentStreak, _) = userProfileManager.getStreakInfo()
                    newProgress = currentStreak
                    shouldUpdate = true
                    
                default:
                    break
                }
            }
            
            if shouldUpdate {
                print("   ✅ Updating mission: \(mission.title) - Progress: \(mission.currentProgress) → \(newProgress)")
                updateMissionProgressValue(mission, newProgress: newProgress)
            }
        }
        print("🏁 Finished checking all missions for spark update")
    }
    
    private func updateMissionProgressValue(_ mission: IgnitionMissionModel, newProgress: Int) {
        if let index = missions.firstIndex(where: { $0.id == mission.id }) {
            var updatedMission = mission
            
            // Guard: Don't update if already completed
            guard updatedMission.status != .completed else {
                print("⚠️ Mission already completed, skipping update: \(mission.title)")
                return
            }
            
            // Cap progress at target value to prevent overflow (2/1 issue)
            updatedMission.currentProgress = min(newProgress, mission.targetValue)
            
            // Auto-complete when progress reaches 100%
            if updatedMission.currentProgress >= mission.targetValue {
                updatedMission.status = .completed
                updatedMission.completedAt = Date()
                
                // Award reward
                awardMissionReward(updatedMission)
                
                // Play completion feedback
                AudioHapticsManager.shared.missionCompleted()
                
                NotificationCenter.default.post(name: .missionCompleted, object: updatedMission)
                
                print("🎉 Mission auto-completed: \(mission.title)")
            }
            
            missions[index] = updatedMission
            
            // Save to Core Data
            persistenceController.updateMission(updatedMission)
        }
    }
    
    // MARK: - Card Mission Progress
    
    /// Updates progress for card-related achievement missions
    private func updateCardMissionProgress(for card: SparkCardModel) {
        print("🎯 updateCardMissionProgress called for card: \(card.displayTitle)")
        let cardManager = CardManager.shared
        let activeMissions = missions.filter { $0.status != .completed && $0.type == .achievement }
        print("📊 Found \(activeMissions.count) active achievement missions")
        
        for mission in activeMissions {
            var shouldUpdate = false
            var newProgress = 0
            
            switch mission.title {
            case "First Card":
                // Count total owned cards
                newProgress = cardManager.ownedCardsCount
                shouldUpdate = true
                print("🎴 First Card mission - Current cards: \(newProgress), Target: \(mission.targetValue)")
                
            case "Rare Collector":
                // Count rare cards
                newProgress = cardManager.ownedCards.filter { $0.rarity == .rare }.count
                shouldUpdate = true
                
            case "Epic Hunter":
                // Count epic cards
                newProgress = cardManager.ownedCards.filter { $0.rarity == .epic }.count
                shouldUpdate = true
                
            case "Legendary Status":
                // Count legendary cards
                newProgress = cardManager.ownedCards.filter { $0.rarity == .legendary }.count
                shouldUpdate = true
                
            case "Master of Decision":
                // Count Decision category cards
                if let category = mission.category {
                    newProgress = cardManager.ownedCards.filter { $0.category == category }.count
                    shouldUpdate = true
                }
                
            case "Master of Energy":
                // Count Energy category cards
                if let category = mission.category {
                    newProgress = cardManager.ownedCards.filter { $0.category == category }.count
                    shouldUpdate = true
                }
                
            case "Master of Ideas":
                // Count Idea category cards
                if let category = mission.category {
                    newProgress = cardManager.ownedCards.filter { $0.category == category }.count
                    shouldUpdate = true
                }
                
            case "Master of Experiments":
                // Count Experiment category cards
                if let category = mission.category {
                    newProgress = cardManager.ownedCards.filter { $0.category == category }.count
                    shouldUpdate = true
                }
                
            case "Master of Challenges":
                // Count Challenge category cards
                if let category = mission.category {
                    newProgress = cardManager.ownedCards.filter { $0.category == category }.count
                    shouldUpdate = true
                }
                
            case "Legendary Collector":
                // Count all legendary cards
                newProgress = cardManager.ownedCards.filter { $0.rarity == .legendary }.count
                shouldUpdate = true
                
            case "Completionist":
                // Count all owned cards
                newProgress = cardManager.ownedCardsCount
                shouldUpdate = true
                
            default:
                break
            }
            
            if shouldUpdate {
                updateMissionProgressValue(mission, newProgress: newProgress)
            }
        }
    }
    
    private func awardMissionReward(_ mission: IgnitionMissionModel) {
        var userProfile = persistenceController.getOrCreateUserProfile()
        userProfile.totalSparkPoints += mission.rewardPoints
        userProfile.currentFuelLevel += mission.rewardPoints
        
        // Check for overload
        if userProfile.currentFuelLevel >= 1000 {
            userProfile.totalOverloads += 1
            userProfile.lastOverloadAt = Date()
            userProfile.currentFuelLevel = 0
            
            NotificationCenter.default.post(name: .overloadTriggered, object: nil)
        }
        
        persistenceController.updateUserProfile(userProfile)
    }
    
    // MARK: - Overload Mission Progress
    private func updateOverloadMissions() {
        let activeMissions = missions.filter { $0.status != .completed && $0.type == .achievement }
        let userProfile = persistenceController.getOrCreateUserProfile()
        let totalOverloads = userProfile.totalOverloads
        
        for mission in activeMissions {
            switch mission.title {
            case "First Overload", "Overload Addict", "Overload Master":
                updateMissionProgressValue(mission, newProgress: totalOverloads)
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    func activeMissions() -> [IgnitionMissionModel] {
        return missions.filter { $0.status == .available || $0.status == .inProgress }
    }
    
    func completedMissions() -> [IgnitionMissionModel] {
        return missions.filter { $0.status == .completed }
    }
    
    func updateMission(_ mission: IgnitionMissionModel) {
        if let index = missions.firstIndex(where: { $0.id == mission.id }) {
            missions[index] = mission
        }
    }
    
    // MARK: - Fixed Missions Initialization
    private func initializeFixedMissions() {
        // These missions are PERMANENT and FIXED
        // They don't expire, they just reset their progress daily/weekly
        
        let fixedMissions = [
            // Daily Missions (5 missions) - Reset every day at midnight
            IgnitionMissionModel(
                title: "Morning Spark",
                description: "Create 1 spark before 12:00 PM",
                type: .daily,
                targetCount: 1,
                rewardPoints: 50,
                expiresAt: nil,
                category: nil,
                difficulty: .easy,
                customIcon: "sunrise.fill"
            ),
            IgnitionMissionModel(
                title: "Spark Streak",
                description: "Create 3 sparks today",
                type: .daily,
                targetCount: 3,
                rewardPoints: 100,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "flame.fill"
            ),
            IgnitionMissionModel(
                title: "Idea Generator",
                description: "Create 1 Idea spark",
                type: .daily,
                targetCount: 1,
                rewardPoints: 60,
                expiresAt: nil,
                category: .idea,
                difficulty: .easy,
                customIcon: "lightbulb.fill"
            ),
            IgnitionMissionModel(
                title: "Energy Boost",
                description: "Complete 2 Energy sparks",
                type: .daily,
                targetCount: 2,
                rewardPoints: 75,
                expiresAt: nil,
                category: .energy,
                difficulty: .easy,
                customIcon: "bolt.circle.fill"
            ),
            IgnitionMissionModel(
                title: "High Intensity",
                description: "Create 1 High or Extreme intensity spark",
                type: .daily,
                targetCount: 1,
                rewardPoints: 80,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "bolt.badge.a.fill"
            ),
            
            // Weekly Missions (10 missions) - Reset every Monday
            IgnitionMissionModel(
                title: "Weekly Warrior",
                description: "Complete 15 sparks this week",
                type: .weekly,
                targetCount: 15,
                rewardPoints: 400,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "shield.fill"
            ),
            IgnitionMissionModel(
                title: "Challenge Master",
                description: "Complete 5 Challenge sparks",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 350,
                expiresAt: nil,
                category: .challenge,
                difficulty: .medium,
                customIcon: "trophy.fill"
            ),
            IgnitionMissionModel(
                title: "Idea Factory",
                description: "Generate 7 Idea sparks",
                type: .weekly,
                targetCount: 7,
                rewardPoints: 350,
                expiresAt: nil,
                category: .idea,
                difficulty: .medium,
                customIcon: "atom"
            ),
            IgnitionMissionModel(
                title: "Energy Dynamo",
                description: "Complete 10 Energy sparks",
                type: .weekly,
                targetCount: 10,
                rewardPoints: 400,
                expiresAt: nil,
                category: .energy,
                difficulty: .medium,
                customIcon: "waveform.path.ecg"
            ),
            IgnitionMissionModel(
                title: "Consistent Creator",
                description: "Create at least 1 spark every day",
                type: .weekly,
                targetCount: 7,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "calendar.badge.checkmark"
            ),
            IgnitionMissionModel(
                title: "Diversity Champion",
                description: "Use all 5 spark categories",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 600,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "star.square.on.square.fill"
            ),
            IgnitionMissionModel(
                title: "Decision Week",
                description: "Make 5 Decision sparks",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 300,
                expiresAt: nil,
                category: .decision,
                difficulty: .easy,
                customIcon: "arrow.triangle.branch"
            ),
            IgnitionMissionModel(
                title: "Point Collector",
                description: "Earn 800 points this week",
                type: .weekly,
                targetCount: 800,
                rewardPoints: 600,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "sparkles.square.filled.on.square"
            ),
            IgnitionMissionModel(
                title: "Intensity Champion",
                description: "Create 5 high/extreme intensity sparks",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 450,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "bolt.horizontal.fill"
            ),
            IgnitionMissionModel(
                title: "Grand Achiever",
                description: "Complete 3 daily missions this week",
                type: .weekly,
                targetCount: 3,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "rosette"
            ),
            
            // Achievement Missions (Permanent - Never reset)
            
            // Card Collection Achievements
            IgnitionMissionModel(
                title: "First Card",
                description: "Collect your first Spark Card",
                type: .achievement,
                targetCount: 1,
                rewardPoints: 100,
                expiresAt: nil,
                category: nil,
                difficulty: .easy,
                customIcon: "rectangle.portrait.fill"
            ),
            IgnitionMissionModel(
                title: "Rare Collector",
                description: "Collect 5 Rare cards",
                type: .achievement,
                targetCount: 5,
                rewardPoints: 300,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "square.stack.fill"
            ),
            IgnitionMissionModel(
                title: "Epic Hunter",
                description: "Obtain 1 Epic card",
                type: .achievement,
                targetCount: 1,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "sparkle"
            ),
            IgnitionMissionModel(
                title: "Legendary Status",
                description: "Obtain your first Legendary card",
                type: .achievement,
                targetCount: 1,
                rewardPoints: 1000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "crown.fill"
            ),
            IgnitionMissionModel(
                title: "Card Collector",
                description: "Collect 25 Spark Cards",
                type: .achievement,
                targetCount: 25,
                rewardPoints: 1500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "square.grid.3x3.fill"
            ),
            IgnitionMissionModel(
                title: "Master of Decision",
                description: "Complete the Decision category (10 cards)",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 750,
                expiresAt: nil,
                category: .decision,
                difficulty: .hard,
                customIcon: "checkmark.seal.fill"
            ),
            IgnitionMissionModel(
                title: "Master of Energy",
                description: "Complete the Energy category (10 cards)",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 750,
                expiresAt: nil,
                category: .energy,
                difficulty: .hard,
                customIcon: "bolt.fill"
            ),
            IgnitionMissionModel(
                title: "Master of Ideas",
                description: "Complete the Idea category (10 cards)",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 750,
                expiresAt: nil,
                category: .idea,
                difficulty: .hard,
                customIcon: "lightbulb.fill"
            ),
            IgnitionMissionModel(
                title: "Master of Experiments",
                description: "Complete the Experiment category (10 cards)",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 750,
                expiresAt: nil,
                category: .experiment,
                difficulty: .hard,
                customIcon: "flask.fill"
            ),
            IgnitionMissionModel(
                title: "Master of Challenges",
                description: "Complete the Challenge category (10 cards)",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 750,
                expiresAt: nil,
                category: .challenge,
                difficulty: .hard,
                customIcon: "flag.fill"
            ),
            IgnitionMissionModel(
                title: "Legendary Collector",
                description: "Collect all 3 Legendary cards",
                type: .achievement,
                targetCount: 3,
                rewardPoints: 2000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "star.circle.fill"
            ),
            IgnitionMissionModel(
                title: "Completionist",
                description: "Collect all 50 Spark Cards",
                type: .achievement,
                targetCount: 50,
                rewardPoints: 5000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "trophy.fill"
            ),
            
            // Spark Total Achievements
            IgnitionMissionModel(
                title: "First Steps",
                description: "Create 10 total sparks",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 200,
                expiresAt: nil,
                category: nil,
                difficulty: .easy,
                customIcon: "star.fill"
            ),
            IgnitionMissionModel(
                title: "Rising Star",
                description: "Create 50 total sparks",
                type: .achievement,
                targetCount: 50,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "star.leadinghalf.filled"
            ),
            IgnitionMissionModel(
                title: "Spark Veteran",
                description: "Create 100 total sparks",
                type: .achievement,
                targetCount: 100,
                rewardPoints: 1000,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "sparkles"
            ),
            IgnitionMissionModel(
                title: "Spark Master",
                description: "Create 500 total sparks",
                type: .achievement,
                targetCount: 500,
                rewardPoints: 3000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "flame.fill"
            ),
            IgnitionMissionModel(
                title: "Spark Legend",
                description: "Create 1000 total sparks",
                type: .achievement,
                targetCount: 1000,
                rewardPoints: 10000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "crown.fill"
            ),
            
            // Points Achievements
            IgnitionMissionModel(
                title: "Point Starter",
                description: "Earn 1,000 total points",
                type: .achievement,
                targetCount: 1000,
                rewardPoints: 200,
                expiresAt: nil,
                category: nil,
                difficulty: .easy,
                customIcon: "bolt.fill"
            ),
            IgnitionMissionModel(
                title: "Point Earner",
                description: "Earn 5,000 total points",
                type: .achievement,
                targetCount: 5000,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "bolt.circle.fill"
            ),
            IgnitionMissionModel(
                title: "Point Collector",
                description: "Earn 10,000 total points",
                type: .achievement,
                targetCount: 10000,
                rewardPoints: 1500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "bolt.badge.a.fill"
            ),
            IgnitionMissionModel(
                title: "Point Master",
                description: "Earn 50,000 total points",
                type: .achievement,
                targetCount: 50000,
                rewardPoints: 5000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "bolt.square.fill"
            ),
            
            // Streak Achievements
            IgnitionMissionModel(
                title: "Week Warrior",
                description: "Achieve a 7-day streak",
                type: .achievement,
                targetCount: 7,
                rewardPoints: 300,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "flame.fill"
            ),
            IgnitionMissionModel(
                title: "Month Champion",
                description: "Achieve a 30-day streak",
                type: .achievement,
                targetCount: 30,
                rewardPoints: 1000,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "calendar.badge.checkmark"
            ),
            IgnitionMissionModel(
                title: "Unstoppable",
                description: "Achieve a 100-day streak",
                type: .achievement,
                targetCount: 100,
                rewardPoints: 5000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "infinity.circle.fill"
            ),
            
            // Overload Achievements
            IgnitionMissionModel(
                title: "First Overload",
                description: "Trigger your first Overload",
                type: .achievement,
                targetCount: 1,
                rewardPoints: 500,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "bolt.trianglebadge.exclamationmark.fill"
            ),
            IgnitionMissionModel(
                title: "Overload Addict",
                description: "Trigger 5 Overloads",
                type: .achievement,
                targetCount: 5,
                rewardPoints: 1500,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "burst.fill"
            ),
            IgnitionMissionModel(
                title: "Overload Master",
                description: "Trigger 10 Overloads",
                type: .achievement,
                targetCount: 10,
                rewardPoints: 3000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "externaldrive.fill.badge.exclamationmark"
            )
        ]
        
        // Save all missions to Core Data
        print("📋 Saving \(fixedMissions.count) fixed missions to Core Data...")
        for mission in fixedMissions {
            let _ = persistenceController.createMission(
                title: mission.title,
                description: mission.description,
                type: mission.type,
                targetValue: mission.targetValue,
                rewardPoints: mission.rewardPoints,
                category: mission.category,
                expiresAt: mission.expiresAt
            )
        }
        
        // Load missions from Core Data (which now includes the newly created ones)
        missions = persistenceController.fetchMissions()
        print("✅ Initialized and loaded \(missions.count) missions from Core Data")
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let missionCompleted = Notification.Name("missionCompleted")
}
