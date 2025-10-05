//
//  MissionsViewExpanded+Enums.swift
//  Ignition Mobile Tracker
//
//  Extracted from MissionsViewExpanded.swift
//  Created by Giulio Posa on 01/10/25.
//

import Foundation

// MARK: - Mission Filter Enums

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
    case achievements = "Achievements"
    case seasonal = "Seasonal"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .achievements: return "trophy.fill"
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

