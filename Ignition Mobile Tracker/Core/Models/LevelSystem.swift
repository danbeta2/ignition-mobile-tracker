//
//  LevelSystem.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 02/10/25.
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
        return rawValue * 1000 // Level 1 = 1000, Level 2 = 2000, etc.
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
        // Find the highest level the user has achieved
        let levelNumber = min(max(1, points / 1000), 10)
        return IgnitionLevel(rawValue: levelNumber) ?? .novice
    }
    
    static func progress(for points: Int) -> (currentLevel: IgnitionLevel, nextLevel: IgnitionLevel?, progressToNext: Double, pointsNeeded: Int) {
        let current = level(for: points)
        let next = IgnitionLevel(rawValue: current.rawValue + 1)
        
        let currentLevelPoints = (current.rawValue - 1) * 1000
        let pointsInCurrentLevel = points - currentLevelPoints
        let progressToNext = Double(pointsInCurrentLevel) / 1000.0
        let pointsNeeded = (next?.requiredPoints ?? (current.requiredPoints + 1000)) - points
        
        return (current, next, progressToNext, max(0, pointsNeeded))
    }
}

