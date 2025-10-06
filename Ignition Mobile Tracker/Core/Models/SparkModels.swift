//
//  SparkModels.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Spark Category
enum SparkCategory: String, CaseIterable, Codable {
    case decision = "decision"
    case energy = "energy"
    case idea = "idea"
    case experiment = "experiment"
    case challenge = "challenge"
    
    var displayName: String {
        switch self {
        case .decision: return "Decision"
        case .energy: return "Energy"
        case .idea: return "Idea"
        case .experiment: return "Experiment"
        case .challenge: return "Challenge"
        }
    }
    
    var iconName: String {
        return AssetNames.SparkCategories(rawValue: "\(self.rawValue)-icon")?.systemName ?? "circle.fill"
    }
    
    var color: Color {
        switch self {
        case .decision: return .orange
        case .energy: return .yellow
        case .idea: return .blue
        case .experiment: return .purple
        case .challenge: return .red
        }
    }
    
    var points: Int {
        switch self {
        case .decision: return 10
        case .energy: return 15
        case .idea: return 8
        case .experiment: return 20
        case .challenge: return 25
        }
    }
}

// MARK: - Spark Intensity
enum SparkIntensity: Int16, CaseIterable, Codable {
    case low = 1
    case medium = 2
    case high = 3
    case extreme = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    var multiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 1.5
        case .high: return 2.0
        case .extreme: return 2.5
        }
    }
}

// MARK: - Spark Model (Core Data Entity will be generated)
struct SparkModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var notes: String?
    var category: SparkCategory
    var intensity: SparkIntensity
    var tags: [String]
    var estimatedTime: Int? // minutes
    var actualTime: Int? // minutes
    var createdAt: Date
    var updatedAt: Date?
    
    var points: Int {
        return Int(Double(category.points) * intensity.multiplier)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        category: SparkCategory,
        intensity: SparkIntensity = .medium,
        tags: [String] = [],
        estimatedTime: Int? = nil,
        actualTime: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.intensity = intensity
        self.tags = tags
        self.estimatedTime = estimatedTime
        self.actualTime = actualTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mission Models
enum MissionType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case special = "special"
    case selfImposed = "self_imposed"
    case adaptive = "adaptive"
    case streak = "streak"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .special: return "Special"
        case .selfImposed: return "Self-Imposed"
        case .adaptive: return "Adaptive"
        case .streak: return "Streak"
        case .achievement: return "Achievement"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .special: return "star.fill"
        case .selfImposed: return "target"
        case .adaptive: return "brain.head.profile"
        case .streak: return "flame.fill"
        case .achievement: return "trophy.fill"
        }
    }
}

enum MissionStatus: String, CaseIterable, Codable {
    case available = "available"
    case inProgress = "in_progress"
    case completed = "completed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .expired: return "Expired"
        }
    }
}

struct MissionModel: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: MissionType
    let category: SparkCategory?
    let targetCount: Int
    var currentProgress: Int
    let rewardPoints: Int
    var status: MissionStatus
    let createdAt: Date
    let expiresAt: Date?
    var completedAt: Date?
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetCount), 1.0)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: MissionType,
        category: SparkCategory? = nil,
        targetCount: Int,
        currentProgress: Int = 0,
        rewardPoints: Int,
        status: MissionStatus = .available,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.category = category
        self.targetCount = targetCount
        self.currentProgress = currentProgress
        self.rewardPoints = rewardPoints
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.completedAt = completedAt
    }
}

// MARK: - Achievement Models
enum AchievementType: String, CaseIterable, Codable {
    case sparkCount = "spark_count"
    case categoryMaster = "category_master"
    case streak = "streak"
    case points = "points"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .sparkCount: return "Spark Counter"
        case .categoryMaster: return "Category Master"
        case .streak: return "Streak"
        case .points: return "Points"
        case .special: return "Special"
        }
    }
}

struct AchievementModel: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: AchievementType
    let category: SparkCategory?
    let targetValue: Int
    let currentProgress: Int
    let rewardPoints: Int
    let iconName: String
    let isUnlocked: Bool
    let unlockedAt: Date?
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: AchievementType,
        category: SparkCategory? = nil,
        targetValue: Int,
        currentProgress: Int = 0,
        rewardPoints: Int,
        iconName: String,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.category = category
        self.targetValue = targetValue
        self.currentProgress = currentProgress
        self.rewardPoints = rewardPoints
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Mission Model
struct IgnitionMissionModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var type: MissionType
    var currentProgress: Int
    var targetValue: Int
    var rewardPoints: Int
    var status: MissionStatus
    var createdAt: Date
    var completedAt: Date?
    var expiresAt: Date?
    var category: SparkCategory?
    var difficulty: MissionDifficulty
    var isFavorite: Bool
    var customIcon: String? // Custom icon for each mission
    
    var progress: Double {
        return Double(currentProgress) / Double(targetValue)
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: MissionType,
        currentProgress: Int = 0,
        targetValue: Int? = nil,
        targetCount: Int? = nil,
        rewardPoints: Int,
        status: MissionStatus = .available,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        expiresAt: Date? = nil,
        category: SparkCategory? = nil,
        difficulty: MissionDifficulty = .medium,
        isFavorite: Bool = false,
        customIcon: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.currentProgress = currentProgress
        self.targetValue = targetValue ?? targetCount ?? 1
        self.rewardPoints = rewardPoints
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.expiresAt = expiresAt
        self.category = category
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.customIcon = customIcon
    }
}

// MARK: - Mission Difficulty
enum MissionDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var colorHex: String {
        switch self {
        case .easy: return "#00FF00"
        case .medium: return "#FFFF00"
        case .hard: return "#FF8800"
        case .expert: return "#FF0000"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
    
    var points: Int {
        switch self {
        case .easy: return 50
        case .medium: return 100
        case .hard: return 200
        case .expert: return 500
        }
    }
}

// MARK: - User Profile Model (matches Core Data UserProfile entity)
struct UserProfileModel: Identifiable, Codable {
    let id: UUID
    var displayName: String
    var selectedAvatarIcon: String
    var selectedCardBack: String
    var totalSparks: Int
    var totalSparkPoints: Int
    var currentFuelLevel: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalOverloads: Int
    var lastOverloadAt: Date?
    let createdAt: Date
    
    // Additional properties for SparkManagerExpanded compatibility
    var totalPoints: Int {
        get { return totalSparkPoints }
        set { totalSparkPoints = newValue }
    }
    var lastSparkDate: Date?
    var ideaSparks: Int
    var decisionSparks: Int
    var experimentSparks: Int
    var challengeSparks: Int
    var energySparks: Int
    
    var level: Int {
        return max(1, totalSparkPoints / 100) // 100 points per level
    }
    
    var nextLevelPoints: Int {
        return (level + 1) * 100
    }
    
    var currentLevelProgress: Double {
        let currentLevelBase = level * 100
        let pointsInCurrentLevel = totalSparkPoints - currentLevelBase
        return Double(pointsInCurrentLevel) / 100.0
    }
    
    var fuelGaugePercentage: Double {
        return min(Double(currentFuelLevel) / 1000.0, 1.0) // Max 1000 for overload
    }
    
    var isOverloadMode: Bool {
        return currentFuelLevel >= 1000
    }
    
    init(
        id: UUID = UUID(),
        displayName: String = "Igniter",
        selectedAvatarIcon: String = "flame",
        selectedCardBack: String = "default",
        totalSparks: Int = 0,
        totalSparkPoints: Int = 0,
        currentFuelLevel: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalOverloads: Int = 0,
        lastOverloadAt: Date? = nil,
        createdAt: Date = Date(),
        lastSparkDate: Date? = nil,
        ideaSparks: Int = 0,
        decisionSparks: Int = 0,
        experimentSparks: Int = 0,
        challengeSparks: Int = 0,
        energySparks: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.selectedAvatarIcon = selectedAvatarIcon
        self.selectedCardBack = selectedCardBack
        self.totalSparks = totalSparks
        self.totalSparkPoints = totalSparkPoints
        self.currentFuelLevel = currentFuelLevel
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalOverloads = totalOverloads
        self.lastOverloadAt = lastOverloadAt
        self.createdAt = createdAt
        self.lastSparkDate = lastSparkDate
        self.ideaSparks = ideaSparks
        self.decisionSparks = decisionSparks
        self.experimentSparks = experimentSparks
        self.challengeSparks = challengeSparks
        self.energySparks = energySparks
    }
}

// MARK: - Spark Card Models

enum CardRarity: String, CaseIterable, Codable, Comparable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return Color.gray
        case .rare: return Color.blue
        case .epic: return Color.purple
        case .legendary: return Color(red: 1.0, green: 0.72, blue: 0.0) // Gold
        }
    }
    
    var glowColor: Color {
        switch self {
        case .common: return Color.gray.opacity(0.5)
        case .rare: return Color.blue.opacity(0.7)
        case .epic: return Color.purple.opacity(0.8)
        case .legendary: return Color(red: 1.0, green: 0.72, blue: 0.0).opacity(0.9)
        }
    }
    
    // Drop rate percentages
    var dropRate: Double {
        switch self {
        case .common: return 0.60 // 60%
        case .rare: return 0.30 // 30%
        case .epic: return 0.08 // 8%
        case .legendary: return 0.02 // 2%
        }
    }
    
    // Bonus points when obtaining a duplicate
    var duplicatePoints: Int {
        switch self {
        case .common: return 10
        case .rare: return 25
        case .epic: return 50
        case .legendary: return 100
        }
    }
    
    // Comparable conformance for sorting by rarity
    static func < (lhs: CardRarity, rhs: CardRarity) -> Bool {
        let order: [CardRarity] = [.common, .rare, .epic, .legendary]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

struct SparkCardModel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String // e.g., "flame", "bolt", "lightbulb"
    let category: SparkCategory
    let rarity: CardRarity
    var isOwned: Bool
    var ownedCount: Int // How many times the user obtained this card
    let obtainedAt: Date? // First time obtained
    
    // Asset name derived from properties
    var assetName: String {
        return "spark-card-\(category.rawValue)-\(name)-\(rarity.rawValue)"
    }
    
    var displayTitle: String {
        return name.capitalized
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        category: SparkCategory,
        rarity: CardRarity,
        isOwned: Bool = false,
        ownedCount: Int = 0,
        obtainedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.rarity = rarity
        self.isOwned = isOwned
        self.ownedCount = ownedCount
        self.obtainedAt = obtainedAt
    }
}

