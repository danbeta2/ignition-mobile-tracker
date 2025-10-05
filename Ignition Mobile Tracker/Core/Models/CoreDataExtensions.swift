//
//  CoreDataExtensions.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import Foundation
import CoreData

// MARK: - CDSpark Extensions
extension CDSpark {
    
    var sparkCategory: SparkCategory {
        get {
            return SparkCategory(rawValue: category ?? "idea") ?? .idea
        }
        set {
            category = newValue.rawValue
        }
    }
    
    var sparkIntensity: SparkIntensity {
        get {
            return SparkIntensity(rawValue: intensity) ?? .low
        }
        set {
            intensity = newValue.rawValue
        }
    }
    
    var points: Int {
        // Calculate points based on intensity
        switch sparkIntensity {
        case .low: return 10
        case .medium: return 25
        case .high: return 50
        case .extreme: return 100
        }
    }
    
    var tagsArray: [String] {
        guard let tags = tags, !tags.isEmpty else { return [] }
        return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    func setTags(_ tagArray: [String]) {
        tags = tagArray.joined(separator: ", ")
    }
    
    // Convert to SparkModel for compatibility
    func toSparkModel() -> SparkModel {
        return SparkModel(
            id: id ?? UUID(),
            title: title ?? "",
            notes: notes,
            category: sparkCategory,
            intensity: sparkIntensity,
            tags: tagsArray,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt
        )
    }
}

// MARK: - CDMission Extensions
extension CDMission {
    
    var missionType: MissionType {
        get {
            return MissionType(rawValue: type ?? "daily") ?? .daily
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var missionStatus: MissionStatus {
        get {
            return MissionStatus(rawValue: status ?? "inProgress") ?? .inProgress
        }
        set {
            status = newValue.rawValue
        }
    }
    
    var missionCategory: SparkCategory? {
        get {
            guard let category = category else { return nil }
            return SparkCategory(rawValue: category)
        }
        set {
            category = newValue?.rawValue
        }
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0.0 }
        return Double(currentProgress) / Double(targetValue)
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var isCompleted: Bool {
        return missionStatus == .completed
    }
    
    var canComplete: Bool {
        return currentProgress >= targetValue && !isCompleted && !isExpired
    }
    
    // Convert to IgnitionMissionModel for compatibility
    func toMissionModel() -> IgnitionMissionModel {
        return IgnitionMissionModel(
            id: id ?? UUID(),
            title: title ?? "",
            description: desc ?? "",
            type: missionType,
            currentProgress: Int(currentProgress),
            targetValue: Int(targetValue),
            targetCount: Int(targetValue),
            rewardPoints: Int(rewardPoints),
            status: missionStatus,
            createdAt: createdAt ?? Date(),
            completedAt: completedAt,
            expiresAt: expiresAt,
            category: missionCategory
        )
    }
}

// MARK: - CDUserProfile Extensions
extension CDUserProfile {
    
    var totalPoints: Int32 {
        get {
            return totalSparkPoints
        }
        set {
            totalSparkPoints = newValue
        }
    }
    
    var sparksArray: [CDSpark] {
        return (sparks?.allObjects as? [CDSpark]) ?? []
    }
    
    var missionsArray: [CDMission] {
        return (missions?.allObjects as? [CDMission]) ?? []
    }
    
    var activeMissions: [CDMission] {
        return missionsArray.filter { $0.missionStatus == .inProgress && !$0.isExpired }
    }
    
    var completedMissions: [CDMission] {
        return missionsArray.filter { $0.missionStatus == .completed }
    }
    
    func incrementCategorySpark(_ category: SparkCategory) {
        switch category {
        case .idea:
            ideaSparks += 1
        case .decision:
            decisionSparks += 1
        case .experiment:
            experimentSparks += 1
        case .challenge:
            challengeSparks += 1
        case .energy:
            energySparks += 1
        }
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastSparkDate = lastSparkDate {
            let lastSparkDay = calendar.startOfDay(for: lastSparkDate)
            let daysBetween = calendar.dateComponents([.day], from: lastSparkDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if daysBetween > 1 {
                // Streak broken - reset
                currentStreak = 1
            }
            // If daysBetween == 0, it's the same day, don't change streak
        } else {
            // First spark ever
            currentStreak = 1
            longestStreak = 1
        }
        
        self.lastSparkDate = Date()
    }
    
    // Convert to UserProfileModel for compatibility
    func toUserProfileModel() -> UserProfileModel {
        return UserProfileModel(
            id: id ?? UUID(),
            displayName: displayName ?? username ?? "User",
            selectedAvatarIcon: selectedAvatarIcon ?? "flame",
            selectedCardBack: selectedCardBack ?? "default",
            totalSparks: Int(totalSparks),
            totalSparkPoints: Int(totalSparkPoints),
            currentFuelLevel: 0,
            currentStreak: Int(currentStreak),
            longestStreak: Int(longestStreak),
            totalOverloads: Int(totalOverloads),
            lastOverloadAt: nil,
            createdAt: createdAt ?? Date(),
            lastSparkDate: lastSparkDate,
            ideaSparks: Int(ideaSparks),
            decisionSparks: Int(decisionSparks),
            experimentSparks: Int(experimentSparks),
            challengeSparks: Int(challengeSparks),
            energySparks: Int(energySparks)
        )
    }
}

// MARK: - CDTable Extensions
extension CDTable {
    
    var tableCategory: TableCategory {
        get {
            return TableCategory(rawValue: category ?? "personal") ?? .personal
        }
        set {
            category = newValue.rawValue
        }
    }
    
    var entriesArray: [CDEntry] {
        return (entries?.allObjects as? [CDEntry]) ?? []
    }
    
    var customFieldsDict: [String: String] {
        get {
            guard let customFields = customFields,
                  let data = customFields.data(using: .utf8) else {
                return [:]
            }
            return (try? JSONSerialization.jsonObject(with: data) as? [String: String]) ?? [:]
        }
        set {
            if let data = try? JSONSerialization.data(withJSONObject: newValue),
               let string = String(data: data, encoding: .utf8) {
                customFields = string
            }
        }
    }
    
    func toTableModel() -> TableModel {
        return TableModel(
            id: id ?? UUID(),
            title: title ?? "",
            description: desc ?? "",
            category: tableCategory,
            isActive: isActive,
            totalEntries: Int(totalEntries),
            totalHours: totalHours,
            bestStreak: Int(bestStreak),
            currentStreak: Int(currentStreak),
            lastEntryDate: lastEntryDate,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            customFields: customFieldsDict,
            targetGoal: targetGoal,
            targetValue: targetValue == 0 ? nil : targetValue
        )
    }
}

// MARK: - CDEntry Extensions
extension CDEntry {
    
    var entryType: EntryType {
        get {
            return EntryType(rawValue: type ?? "session") ?? .session
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var tagsArray: [String] {
        get {
            guard let tags = tags, !tags.isEmpty else { return [] }
            return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tags = newValue.joined(separator: ",")
        }
    }
    
    var customDataDict: [String: String] {
        get {
            guard let customData = customData,
                  let data = customData.data(using: .utf8) else {
                return [:]
            }
            return (try? JSONSerialization.jsonObject(with: data) as? [String: String]) ?? [:]
        }
        set {
            if let data = try? JSONSerialization.data(withJSONObject: newValue),
               let string = String(data: data, encoding: .utf8) {
                customData = string
            }
        }
    }
    
    func toTableEntryModel() -> TableEntryModel {
        return TableEntryModel(
            id: id ?? UUID(),
            tableId: table?.id ?? UUID(),
            title: title ?? "",
            content: content ?? "",
            type: entryType,
            duration: duration == 0 ? nil : duration,
            value: value == 0 ? nil : value,
            photoData: photoData,
            tags: tagsArray,
            customData: customDataDict,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            isImportant: isImportant,
            mood: mood == 0 ? nil : Int(mood)
        )
    }
}

// MARK: - CDSparkCard Extensions
extension CDSparkCard {
    
    var cardCategory: SparkCategory {
        get {
            return SparkCategory(rawValue: category ?? "energy") ?? .energy
        }
        set {
            category = newValue.rawValue
        }
    }
    
    var cardRarity: CardRarity {
        get {
            return CardRarity(rawValue: rarity ?? "common") ?? .common
        }
        set {
            rarity = newValue.rawValue
        }
    }
    
    func toSparkCardModel() -> SparkCardModel {
        return SparkCardModel(
            id: id ?? UUID(),
            name: name ?? "",
            category: cardCategory,
            rarity: cardRarity,
            isOwned: isOwned,
            ownedCount: Int(ownedCount),
            obtainedAt: obtainedAt
        )
    }
}

// MARK: - SparkModel Extensions

extension SparkModel {
    /// Placeholder property for favorite functionality
    /// TODO: Implement proper favorite tracking in Core Data when needed
    var isFavorite: Bool {
        get { return false } // Placeholder - not yet implemented
        set { } // Placeholder - not yet implemented
    }
}
