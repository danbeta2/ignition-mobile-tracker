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
                if let spark = notification.object as? SparkModel {
                    Task { @MainActor in
                        self?.updateMissionProgress(for: spark)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for card obtained events to update card achievement missions
        NotificationCenter.default.publisher(for: .cardObtained)
            .sink { [weak self] notification in
                if let card = notification.object as? SparkCardModel {
                    Task { @MainActor in
                        self?.updateCardMissionProgress(for: card)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mission Operations
    func loadMissions() {
        isLoading = true
        error = nil
        
        // Initialize fixed missions if empty, then check for resets
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.missions.isEmpty {
                self.initializeFixedMissions()
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
            
            // Award points to user
            awardMissionReward(mission)
            
            // Play completion feedback
            AudioHapticsManager.shared.missionCompleted()
            
            NotificationCenter.default.post(name: .missionCompleted, object: mission)
        }
    }
    
    // MARK: - Mission Progress
    private func updateMissionProgress(for spark: SparkModel) {
        let activeMissions = missions.filter { $0.status != .completed && $0.status != .expired }
        
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
                    
                case "Spark Streak", "Weekly Warrior", "Consistent Creator", "Power Week":
                    // Count any spark
                    newProgress += 1
                    shouldUpdate = true
                    
                case "High Intensity", "Intensity Champion":
                    if spark.intensity == .high || spark.intensity == .extreme {
                        newProgress += 1
                        shouldUpdate = true
                    }
                    
                case "Diversity Champion":
                    // For now, just count any spark
                    newProgress += 1
                    shouldUpdate = true
                    
                case "Point Collector":
                    // Track total points earned
                    newProgress += spark.points
                    shouldUpdate = true
                    
                default:
                    break
                }
            }
            
            if shouldUpdate {
                updateMissionProgressValue(mission, newProgress: newProgress)
            }
        }
    }
    
    private func updateMissionProgressValue(_ mission: IgnitionMissionModel, newProgress: Int) {
        if let index = missions.firstIndex(where: { $0.id == mission.id }) {
            var updatedMission = mission
            updatedMission.currentProgress = newProgress
            
            if newProgress >= mission.targetValue {
                updatedMission.status = .completed
                updatedMission.completedAt = Date()
                
                // Award reward
                awardMissionReward(updatedMission)
                
                // Play completion feedback
                AudioHapticsManager.shared.missionCompleted()
                
                NotificationCenter.default.post(name: .missionCompleted, object: updatedMission)
            }
            
            missions[index] = updatedMission
        }
    }
    
    // MARK: - Card Mission Progress
    
    /// Updates progress for card-related achievement missions
    private func updateCardMissionProgress(for card: SparkCardModel) {
        let cardManager = CardManager.shared
        let activeMissions = missions.filter { $0.status != .completed && $0.type == .achievement }
        
        for mission in activeMissions {
            var shouldUpdate = false
            var newProgress = 0
            
            switch mission.title {
            case "First Card":
                // Count total owned cards
                newProgress = cardManager.ownedCardsCount
                shouldUpdate = true
                
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
    
    // MARK: - Deprecated Functions Removed
    // createDailyMissions() - REMOVED
    // createWeeklyMissions() - REMOVED
    // generateSelfImposedMissions() - REMOVED
    // generateAdaptiveMissions() - REMOVED
    // generateStreakMissions() - REMOVED
    // generateAchievementMissions() - REMOVED
    // generateMockMissions() - REMOVED
    
    // All missions are now fixed and permanent in initializeFixedMissions()
    
    // MARK: - Fixed Missions Initialization
    private func initializeFixedMissions() {
        // These missions are PERMANENT and FIXED
        // They don't expire, they just reset their progress daily/weekly
        
        let fixedMissions = [
            // Daily Missions (15 missions) - Reset every day at midnight
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
                title: "Decision Maker",
                description: "Record 2 Decision-type sparks",
                type: .daily,
                targetCount: 2,
                rewardPoints: 75,
                expiresAt: nil,
                category: .decision,
                difficulty: .easy,
                customIcon: "arrow.left.arrow.right.circle.fill"
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
                description: "Complete 3 Energy sparks",
                type: .daily,
                targetCount: 3,
                rewardPoints: 100,
                expiresAt: nil,
                category: .energy,
                difficulty: .medium,
                customIcon: "bolt.circle.fill"
            ),
            IgnitionMissionModel(
                title: "Daily Challenger",
                description: "Take on 1 Challenge",
                type: .daily,
                targetCount: 1,
                rewardPoints: 80,
                expiresAt: nil,
                category: .challenge,
                difficulty: .easy,
                customIcon: "flag.checkered"
            ),
            IgnitionMissionModel(
                title: "Experimenter",
                description: "Try 1 new Experiment",
                type: .daily,
                targetCount: 1,
                rewardPoints: 70,
                expiresAt: nil,
                category: .experiment,
                difficulty: .easy,
                customIcon: "flask.fill"
            ),
            IgnitionMissionModel(
                title: "Spark Streak",
                description: "Create 5 sparks today",
                type: .daily,
                targetCount: 5,
                rewardPoints: 150,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "flame.fill"
            ),
            IgnitionMissionModel(
                title: "High Intensity",
                description: "Create 2 High or Extreme intensity sparks",
                type: .daily,
                targetCount: 2,
                rewardPoints: 90,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "bolt.badge.a.fill"
            ),
            IgnitionMissionModel(
                title: "Quick Fire",
                description: "Create 3 sparks in 1 hour",
                type: .daily,
                targetCount: 3,
                rewardPoints: 120,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "timer"
            ),
            IgnitionMissionModel(
                title: "Reflection Time",
                description: "Create 1 Decision spark",
                type: .daily,
                targetCount: 1,
                rewardPoints: 65,
                expiresAt: nil,
                category: .decision,
                difficulty: .easy,
                customIcon: "brain.head.profile"
            ),
            IgnitionMissionModel(
                title: "Double Decision",
                description: "Make 2 important decisions today",
                type: .daily,
                targetCount: 2,
                rewardPoints: 85,
                expiresAt: nil,
                category: .decision,
                difficulty: .medium,
                customIcon: "checkmark.diamond.fill"
            ),
            IgnitionMissionModel(
                title: "Creative Burst",
                description: "Generate 3 new ideas",
                type: .daily,
                targetCount: 3,
                rewardPoints: 110,
                expiresAt: nil,
                category: .idea,
                difficulty: .medium,
                customIcon: "sparkles"
            ),
            IgnitionMissionModel(
                title: "Energy Master",
                description: "Complete 5 energy-focused activities",
                type: .daily,
                targetCount: 5,
                rewardPoints: 140,
                expiresAt: nil,
                category: .energy,
                difficulty: .hard,
                customIcon: "bolt.batteryblock.fill"
            ),
            IgnitionMissionModel(
                title: "Night Owl",
                description: "Create 1 spark after 8:00 PM",
                type: .daily,
                targetCount: 1,
                rewardPoints: 55,
                expiresAt: nil,
                category: nil,
                difficulty: .easy,
                customIcon: "moon.stars.fill"
            ),
            IgnitionMissionModel(
                title: "Perfectionist",
                description: "Create 1 spark with extreme intensity",
                type: .daily,
                targetCount: 1,
                rewardPoints: 95,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "star.circle.fill"
            ),
            
            // Weekly Missions (15 missions) - Reset every Monday
            IgnitionMissionModel(
                title: "Weekly Warrior",
                description: "Complete 20 sparks this week",
                type: .weekly,
                targetCount: 20,
                rewardPoints: 500,
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
                rewardPoints: 400,
                expiresAt: nil,
                category: .challenge,
                difficulty: .medium,
                customIcon: "trophy.fill"
            ),
            IgnitionMissionModel(
                title: "Idea Factory",
                description: "Generate 10 Idea sparks",
                type: .weekly,
                targetCount: 10,
                rewardPoints: 450,
                expiresAt: nil,
                category: .idea,
                difficulty: .medium,
                customIcon: "atom"
            ),
            IgnitionMissionModel(
                title: "Energy Dynamo",
                description: "Complete 15 Energy sparks",
                type: .weekly,
                targetCount: 15,
                rewardPoints: 550,
                expiresAt: nil,
                category: .energy,
                difficulty: .hard,
                customIcon: "waveform.path.ecg"
            ),
            IgnitionMissionModel(
                title: "Consistent Creator",
                description: "Create at least 1 spark every day",
                type: .weekly,
                targetCount: 7,
                rewardPoints: 600,
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
                rewardPoints: 700,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "star.square.on.square.fill"
            ),
            IgnitionMissionModel(
                title: "Decision Week",
                description: "Make 8 Decision sparks",
                type: .weekly,
                targetCount: 8,
                rewardPoints: 480,
                expiresAt: nil,
                category: .decision,
                difficulty: .medium,
                customIcon: "arrow.triangle.branch"
            ),
            IgnitionMissionModel(
                title: "Experiment Lab",
                description: "Complete 7 Experiment sparks",
                type: .weekly,
                targetCount: 7,
                rewardPoints: 520,
                expiresAt: nil,
                category: .experiment,
                difficulty: .medium,
                customIcon: "testtube.2"
            ),
            IgnitionMissionModel(
                title: "Point Collector",
                description: "Earn 1000 points this week",
                type: .weekly,
                targetCount: 1000,
                rewardPoints: 800,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "sparkles.square.filled.on.square"
            ),
            IgnitionMissionModel(
                title: "Overload Seeker",
                description: "Trigger 1 Overload mode",
                type: .weekly,
                targetCount: 1,
                rewardPoints: 1000,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "burst.fill"
            ),
            IgnitionMissionModel(
                title: "Reflection Master",
                description: "Complete 6 Challenge sparks",
                type: .weekly,
                targetCount: 6,
                rewardPoints: 420,
                expiresAt: nil,
                category: .challenge,
                difficulty: .medium,
                customIcon: "eye.circle.fill"
            ),
            IgnitionMissionModel(
                title: "Power Week",
                description: "Create 30 sparks in one week",
                type: .weekly,
                targetCount: 30,
                rewardPoints: 750,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "wind"
            ),
            IgnitionMissionModel(
                title: "Intensity Champion",
                description: "Create 10 high/extreme intensity sparks",
                type: .weekly,
                targetCount: 10,
                rewardPoints: 650,
                expiresAt: nil,
                category: nil,
                difficulty: .hard,
                customIcon: "bolt.horizontal.fill"
            ),
            IgnitionMissionModel(
                title: "Morning Person",
                description: "Create 5 morning sparks (before noon)",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 380,
                expiresAt: nil,
                category: nil,
                difficulty: .medium,
                customIcon: "sun.and.horizon.fill"
            ),
            IgnitionMissionModel(
                title: "Grand Achiever",
                description: "Complete 5 daily missions this week",
                type: .weekly,
                targetCount: 5,
                rewardPoints: 850,
                expiresAt: nil,
                category: nil,
                difficulty: .expert,
                customIcon: "rosette"
            ),
            
            // Card Collection Achievements (Achievement type missions)
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
            )
        ]
        
        missions.append(contentsOf: fixedMissions)
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let missionCompleted = Notification.Name("missionCompleted")
}
