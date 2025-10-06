//
//  LibraryModels.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import Foundation
import SwiftUI

// MARK: - Table Category
enum TableCategory: String, CaseIterable, Codable {
    case poker = "poker"
    case school = "school"
    case gym = "gym"
    case work = "work"
    case personal = "personal"
    case health = "health"
    case finance = "finance"
    case hobby = "hobby"
    
    var displayName: String {
        switch self {
        case .poker: return "Poker"
        case .school: return "School"
        case .gym: return "Gym"
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .finance: return "Finance"
        case .hobby: return "Hobby"
        }
    }
    
    var icon: String {
        switch self {
        case .poker: return "suit.club.fill"
        case .school: return "graduationcap.fill"
        case .gym: return "dumbbell.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .hobby: return "paintbrush.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .poker: return .red
        case .school: return .blue
        case .gym: return .orange
        case .work: return .purple
        case .personal: return .green
        case .health: return .pink
        case .finance: return .yellow
        case .hobby: return .indigo
        }
    }
}

// MARK: - Table Model
struct TableModel: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var category: TableCategory
    var isActive: Bool
    var totalEntries: Int
    var totalHours: Double
    var bestStreak: Int
    var currentStreak: Int
    var lastEntryDate: Date?
    let createdAt: Date
    var updatedAt: Date
    var customFields: [String: String] // For custom tracking fields
    var targetGoal: String?
    var targetValue: Double?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: TableCategory,
        isActive: Bool = true,
        totalEntries: Int = 0,
        totalHours: Double = 0,
        bestStreak: Int = 0,
        currentStreak: Int = 0,
        lastEntryDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        customFields: [String: String] = [:],
        targetGoal: String? = nil,
        targetValue: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isActive = isActive
        self.totalEntries = totalEntries
        self.totalHours = totalHours
        self.bestStreak = bestStreak
        self.currentStreak = currentStreak
        self.lastEntryDate = lastEntryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customFields = customFields
        self.targetGoal = targetGoal
        self.targetValue = targetValue
    }
}

// MARK: - Entry Type
enum EntryType: String, CaseIterable, Codable {
    case session = "session"
    case milestone = "milestone"
    case note = "note"
    case photo = "photo"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .session: return "Session"
        case .milestone: return "Milestone"
        case .note: return "Note"
        case .photo: return "Photo"
        case .achievement: return "Achievement"
        }
    }
    
    var icon: String {
        switch self {
        case .session: return "clock.fill"
        case .milestone: return "flag.fill"
        case .note: return "note.text"
        case .photo: return "camera.fill"
        case .achievement: return "trophy.fill"
        }
    }
}

// MARK: - Table Entry Model
struct TableEntryModel: Identifiable, Codable {
    let id: UUID
    let tableId: UUID
    var title: String
    var content: String
    var type: EntryType
    var duration: TimeInterval? // For sessions
    var value: Double? // For numeric tracking
    var photoData: Data? // For photo entries
    var tags: [String]
    var customData: [String: String]
    let createdAt: Date
    var updatedAt: Date
    var isImportant: Bool
    var mood: Int? // 1-5 scale
    
    init(
        id: UUID = UUID(),
        tableId: UUID,
        title: String,
        content: String = "",
        type: EntryType = .session,
        duration: TimeInterval? = nil,
        value: Double? = nil,
        photoData: Data? = nil,
        tags: [String] = [],
        customData: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isImportant: Bool = false,
        mood: Int? = nil
    ) {
        self.id = id
        self.tableId = tableId
        self.title = title
        self.content = content
        self.type = type
        self.duration = duration
        self.value = value
        self.photoData = photoData
        self.tags = tags
        self.customData = customData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isImportant = isImportant
        self.mood = mood
    }
}

// MARK: - Library Statistics
struct LibraryStats {
    let totalTables: Int
    let activeTables: Int
    let totalEntries: Int
    let totalHours: Double
    let longestStreak: Int
    let mostActiveCategory: TableCategory?
    let weeklyProgress: Double
    let monthlyProgress: Double
}

// MARK: - Table Template
struct TableTemplate {
    let category: TableCategory
    let title: String
    let description: String
    let suggestedFields: [String]
    let defaultGoal: String?
    
    static let templates: [TableTemplate] = [
        TableTemplate(
            category: .poker,
            title: "Poker Sessions",
            description: "Track your poker games: record buy-ins, results, and notes to analyze your performance over time.",
            suggestedFields: ["Buy-in", "Cash-out", "Duration", "Venue", "Game Type"],
            defaultGoal: "Improve win rate and bankroll management"
        ),
        TableTemplate(
            category: .school,
            title: "Study Sessions",
            description: "Log your learning activities: subjects studied, time spent, and progress made towards your educational goals.",
            suggestedFields: ["Subject", "Hours Studied", "Grade", "Topics Covered"],
            defaultGoal: "Maintain consistent study schedule and improve grades"
        ),
        TableTemplate(
            category: .gym,
            title: "Workout Log",
            description: "Record your fitness activities: exercises, sets, reps, and weights to track your strength progress.",
            suggestedFields: ["Exercise", "Sets", "Reps", "Weight", "Duration"],
            defaultGoal: "Build strength and maintain workout consistency"
        ),
        TableTemplate(
            category: .work,
            title: "Work Projects",
            description: "Monitor your professional tasks: track time spent, skills developed, and project milestones achieved.",
            suggestedFields: ["Project", "Hours", "Tasks Completed", "Skills Used"],
            defaultGoal: "Enhance productivity and skill development"
        ),
        TableTemplate(
            category: .personal,
            title: "Personal Growth",
            description: "Document your self-improvement journey: activities, reflections, and insights for personal development.",
            suggestedFields: ["Activity", "Reflection", "Mood", "Insights"],
            defaultGoal: "Continuous self-improvement and mindfulness"
        ),
        TableTemplate(
            category: .health,
            title: "Health Tracking",
            description: "Monitor your wellness journey: track vital signs, symptoms, medications, and health-related activities.",
            suggestedFields: ["Weight", "Blood Pressure", "Exercise", "Sleep Hours"],
            defaultGoal: "Maintain optimal health and wellness"
        ),
        TableTemplate(
            category: .finance,
            title: "Financial Goals",
            description: "Track your money management: record income, expenses, savings, and investment progress over time.",
            suggestedFields: ["Income", "Expenses", "Savings", "Investments"],
            defaultGoal: "Achieve financial independence and smart money habits"
        ),
        TableTemplate(
            category: .hobby,
            title: "Creative Projects",
            description: "Document your artistic pursuits: track time spent, techniques learned, and creative projects completed.",
            suggestedFields: ["Project", "Medium", "Time Spent", "Techniques Used"],
            defaultGoal: "Develop artistic skills and complete meaningful projects"
        )
    ]
}
