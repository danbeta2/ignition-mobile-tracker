//
//  LevelSystem.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 02/10/25.
//

import SwiftUI

// MARK: - Level System
enum IgnitionLevel: Int, CaseIterable {
    case novice = 1
    case apprentice = 2
    case practitioner = 3
    case adept = 4
    case expert = 5
    case master = 6
    case grandMaster = 7
    case legend = 8
    case titan = 9
    case mythical = 10
    
    var title: String {
        switch self {
        case .novice: return "Novice Igniter"
        case .apprentice: return "Apprentice Igniter"
        case .practitioner: return "Practitioner Igniter"
        case .adept: return "Adept Igniter"
        case .expert: return "Expert Igniter"
        case .master: return "Master Igniter"
        case .grandMaster: return "Grand Master"
        case .legend: return "Legendary Igniter"
        case .titan: return "Titan of Ignition"
        case .mythical: return "Mythical Flame"
        }
    }
    
    var description: String {
        switch self {
        case .novice: return "Just starting your journey"
        case .apprentice: return "Learning the ways of Ignition"
        case .practitioner: return "Building momentum"
        case .adept: return "Mastering the fundamentals"
        case .expert: return "A force to be reckoned with"
        case .master: return "True mastery achieved"
        case .grandMaster: return "Among the elite"
        case .legend: return "Your name is legendary"
        case .titan: return "Unstoppable force of nature"
        case .mythical: return "You've transcended all limits"
        }
    }
    
    var requiredPoints: Int {
        // Exponential progression for longevity
        // Uses formula: basePoints * (multiplier ^ (level - 1))
        // Base: 500, Multiplier: ~1.8
        
        switch self {
        case .novice: return 0 // Starting point
        case .apprentice: return 500 // 500 total
        case .practitioner: return 1400 // ~900 more (500 * 1.8)
        case .adept: return 2900 // ~1,500 more (900 * 1.8)
        case .expert: return 5600 // ~2,700 more
        case .master: return 10500 // ~4,900 more
        case .grandMaster: return 19300 // ~8,800 more
        case .legend: return 35100 // ~15,800 more
        case .titan: return 63500 // ~28,400 more
        case .mythical: return 114800 // ~51,300 more (ultimate achievement)
        }
    }
    
    var color: Color {
        switch self {
        case .novice: return .gray
        case .apprentice: return Color(red: 0.7, green: 0.7, blue: 0.7) // Light gray
        case .practitioner: return Color(red: 0.8, green: 0.6, blue: 0.4) // Bronze
        case .adept: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case .expert: return IgnitionColors.goldAccent // Gold
        case .master: return IgnitionColors.ignitionOrange // Orange
        case .grandMaster: return Color(red: 1.0, green: 0.2, blue: 0.2) // Red
        case .legend: return Color(red: 0.6, green: 0.2, blue: 0.8) // Purple
        case .titan: return Color(red: 0.0, green: 0.8, blue: 1.0) // Cyan
        case .mythical: return IgnitionColors.fireRed // Fire Red
        }
    }
    
    var iconName: String {
        switch self {
        case .novice: return "flame"
        case .apprentice: return "flame.fill"
        case .practitioner: return "sparkles"
        case .adept: return "bolt.fill"
        case .expert: return "star.fill"
        case .master: return "crown.fill"
        case .grandMaster: return "crown"
        case .legend: return "trophy.fill"
        case .titan: return "shield.fill"
        case .mythical: return "flame.circle.fill"
        }
    }
    
    static func level(for points: Int) -> IgnitionLevel {
        // Find the highest level the user has achieved based on total points
        for level in IgnitionLevel.allCases.reversed() {
            if points >= level.requiredPoints {
                return level
            }
        }
        return .novice
    }
    
    static func progress(for points: Int) -> (currentLevel: IgnitionLevel, nextLevel: IgnitionLevel?, progressToNext: Double, pointsNeeded: Int) {
        let current = level(for: points)
        let next = IgnitionLevel(rawValue: current.rawValue + 1)
        
        let currentLevelBase = current.requiredPoints
        let nextLevelRequired = next?.requiredPoints ?? (current.requiredPoints + 100000) // Arbitrary high number for max level
        
        let pointsInCurrentLevel = points - currentLevelBase
        let pointsNeededForNextLevel = nextLevelRequired - currentLevelBase
        
        let progressToNext: Double
        if next == nil {
            // Max level reached
            progressToNext = 1.0
        } else if pointsNeededForNextLevel <= 0 {
            // Edge case: should never happen, but prevent division by zero
            progressToNext = 0.0
        } else {
            progressToNext = min(1.0, Double(pointsInCurrentLevel) / Double(pointsNeededForNextLevel))
        }
        
        let pointsNeeded = max(0, nextLevelRequired - points)
        
        return (current, next, progressToNext, pointsNeeded)
    }
    
    /// Returns the estimated number of sparks needed to reach the next level
    /// Assumes average spark value of 30 points (medium intensity, average category)
    static func sparksToNextLevel(currentPoints: Int) -> Int {
        let (_, nextLevel, _, pointsNeeded) = progress(for: currentPoints)
        guard nextLevel != nil else { return 0 }
        
        let averageSparkValue = 30
        return Int(ceil(Double(pointsNeeded) / Double(averageSparkValue)))
    }
}

