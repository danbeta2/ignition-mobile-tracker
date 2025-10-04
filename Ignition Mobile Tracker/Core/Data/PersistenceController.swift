//
//  PersistenceController.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import CoreData
import Foundation

// MARK: - Persistence Controller
class PersistenceController {
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IgnitionTracker")
        
        // Configure store description with migration options
        container.persistentStoreDescriptions.forEach { storeDescription in
            // Enable automatic lightweight migration
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Performance optimizations
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                print("⚠️ Core Data error: \(error), \(error.userInfo)")
                // For now, continue with in-memory store
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Core Data Operations
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Core Data fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Background Context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Preview Context (for SwiftUI Previews)
    static var preview: PersistenceController = {
        let controller = PersistenceController()
        let context = controller.persistentContainer.viewContext
        
        // Add sample data for previews
        let profile = CDUserProfile(context: context)
        profile.id = UUID()
        profile.username = "Preview User"
        profile.totalSparks = 42
        profile.totalSparkPoints = 567
        profile.currentStreak = 7
        profile.longestStreak = 15
        profile.createdAt = Date()
        
        try? context.save()
        
        return controller
    }()
}

// MARK: - User Profile Methods
extension PersistenceController {
    
    func getOrCreateUserProfile() -> UserProfileModel {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(request)
            if let existingProfile = profiles.first {
                print("📊 Loaded existing user profile from Core Data")
                return existingProfile.toUserProfileModel()
            }
        } catch {
            print("⚠️ Error fetching user profile: \(error)")
        }
        
        // Create new profile in Core Data
        let newCDProfile = CDUserProfile(context: context)
        newCDProfile.id = UUID()
        newCDProfile.username = "User"
        newCDProfile.totalSparks = 0
        newCDProfile.totalSparkPoints = 0
        newCDProfile.currentStreak = 0
        newCDProfile.longestStreak = 0
        newCDProfile.totalMissionsCompleted = 0
        newCDProfile.overloadCount = 0
        newCDProfile.totalOverloads = 0
        newCDProfile.createdAt = Date()
        newCDProfile.updatedAt = Date()
        newCDProfile.ideaSparks = 0
        newCDProfile.decisionSparks = 0
        newCDProfile.experimentSparks = 0
        newCDProfile.challengeSparks = 0
        newCDProfile.energySparks = 0
        
        save()
        print("✨ Created new user profile in Core Data")
        
        return newCDProfile.toUserProfileModel()
    }
    
    func updateUserProfile(_ profile: UserProfileModel) {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
        
        do {
            let profiles = try context.fetch(request)
            if let cdProfile = profiles.first {
                // Update all fields
                cdProfile.username = profile.displayName
                cdProfile.totalSparks = Int32(profile.totalSparks)
                cdProfile.totalSparkPoints = Int32(profile.totalSparkPoints)
                cdProfile.currentStreak = Int32(profile.currentStreak)
                cdProfile.longestStreak = Int32(profile.longestStreak)
                cdProfile.totalMissionsCompleted = 0 // Will be updated by mission system
                cdProfile.overloadCount = 0 // Will be updated by overload system
                cdProfile.totalOverloads = Int32(profile.totalOverloads)
                cdProfile.updatedAt = Date()
                cdProfile.displayName = profile.displayName
                cdProfile.selectedAvatarIcon = profile.selectedAvatarIcon
                cdProfile.selectedCardBack = profile.selectedCardBack
                cdProfile.lastSparkDate = profile.lastSparkDate
                cdProfile.ideaSparks = Int32(profile.ideaSparks)
                cdProfile.decisionSparks = Int32(profile.decisionSparks)
                cdProfile.experimentSparks = Int32(profile.experimentSparks)
                cdProfile.challengeSparks = Int32(profile.challengeSparks)
                cdProfile.energySparks = Int32(profile.energySparks)
                
                save()
                print("✅ User profile updated in Core Data")
            }
        } catch {
            print("❌ Error updating user profile: \(error)")
        }
    }
    
    func getCDUserProfile() -> CDUserProfile? {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        return try? context.fetch(request).first
    }
}

// MARK: - Spark Methods
extension PersistenceController {
    
    func createSpark(
        title: String,
        category: SparkCategory,
        intensity: SparkIntensity,
        notes: String? = nil,
        tags: String? = nil,
        location: String? = nil
    ) -> SparkModel {
        let cdSpark = CDSpark(context: context)
        
        cdSpark.id = UUID()
        cdSpark.title = title
        cdSpark.category = category.rawValue
        cdSpark.intensity = Int16(intensity.rawValue)
        cdSpark.notes = notes
        cdSpark.tags = tags
        cdSpark.location = location
        cdSpark.createdAt = Date()
        cdSpark.updatedAt = Date()
        cdSpark.isFavorite = false
        
        // Associate with user profile
        if let userProfile = getCDUserProfile() {
            cdSpark.userProfile = userProfile
            
            // Update user stats
            userProfile.totalSparks += 1
            let points = Int(Double(category.points) * intensity.multiplier)
            userProfile.totalSparkPoints += Int32(points)
            userProfile.incrementCategorySpark(category)
            userProfile.updateStreak()
            userProfile.updatedAt = Date()
        }
        
        save()
        print("✨ Created new spark in Core Data: \(title)")
        
        return cdSpark.toSparkModel()
    }
    
    func fetchSparks() -> [SparkModel] {
        let request: NSFetchRequest<CDSpark> = CDSpark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDSpark.createdAt, ascending: false)]
        
        let cdSparks = fetch(request)
        return cdSparks.map { $0.toSparkModel() }
    }
    
    func deleteSpark(_ sparkModel: SparkModel) {
        let request: NSFetchRequest<CDSpark> = CDSpark.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sparkModel.id as CVarArg)
        
        if let cdSpark = try? context.fetch(request).first {
            // Update user stats
            if let userProfile = getCDUserProfile() {
                userProfile.totalSparks -= 1
                userProfile.totalSparkPoints -= Int32(cdSpark.points)
                userProfile.updatedAt = Date()
            }
            
            delete(cdSpark)
            print("🗑️ Deleted spark from Core Data")
        }
    }
    
    func updateSpark(_ sparkModel: SparkModel) {
        let request: NSFetchRequest<CDSpark> = CDSpark.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sparkModel.id as CVarArg)
        
        if let cdSpark = try? context.fetch(request).first {
            cdSpark.title = sparkModel.title
            cdSpark.category = sparkModel.category.rawValue
            cdSpark.intensity = Int16(sparkModel.intensity.rawValue)
            cdSpark.notes = sparkModel.notes
            cdSpark.tags = sparkModel.tags.joined(separator: ", ")
            cdSpark.updatedAt = Date()
            
            save()
            print("✅ Updated spark in Core Data")
        }
    }
}

// MARK: - Mission Methods
extension PersistenceController {
    
    func createMission(
        title: String,
        description: String,
        type: MissionType,
        targetValue: Int,
        rewardPoints: Int,
        category: SparkCategory? = nil,
        expiresAt: Date? = nil
    ) -> IgnitionMissionModel {
        let cdMission = CDMission(context: context)
        
        cdMission.id = UUID()
        cdMission.title = title
        cdMission.desc = description
        cdMission.type = type.rawValue
        cdMission.currentProgress = 0
        cdMission.targetValue = Int32(targetValue)
        cdMission.rewardPoints = Int32(rewardPoints)
        cdMission.status = MissionStatus.inProgress.rawValue
        cdMission.createdAt = Date()
        cdMission.expiresAt = expiresAt
        cdMission.category = category?.rawValue
        cdMission.isFavorite = false
        
        // Associate with user profile
        if let userProfile = getCDUserProfile() {
            cdMission.userProfile = userProfile
        }
        
        save()
        print("✨ Created new mission in Core Data: \(title)")
        
        return cdMission.toMissionModel()
    }
    
    func fetchMissions() -> [IgnitionMissionModel] {
        let request: NSFetchRequest<CDMission> = CDMission.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMission.createdAt, ascending: false)]
        
        let cdMissions = fetch(request)
        return cdMissions.map { $0.toMissionModel() }
    }
    
    func updateMission(_ missionModel: IgnitionMissionModel) {
        let request: NSFetchRequest<CDMission> = CDMission.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", missionModel.id as CVarArg)
        
        if let cdMission = try? context.fetch(request).first {
            cdMission.title = missionModel.title
            cdMission.desc = missionModel.description
            cdMission.currentProgress = Int32(missionModel.currentProgress)
            cdMission.status = missionModel.status.rawValue
            cdMission.completedAt = missionModel.completedAt
            
            // If mission just completed, award points
            if missionModel.status == .completed && cdMission.missionStatus != .completed {
                if let userProfile = getCDUserProfile() {
                    userProfile.totalMissionsCompleted += 1
                    userProfile.totalSparkPoints += cdMission.rewardPoints
                    userProfile.updatedAt = Date()
                }
            }
            
            save()
            print("✅ Updated mission in Core Data")
        }
    }
    
    func deleteMission(_ missionModel: IgnitionMissionModel) {
        let request: NSFetchRequest<CDMission> = CDMission.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", missionModel.id as CVarArg)
        
        if let cdMission = try? context.fetch(request).first {
            delete(cdMission)
            print("🗑️ Deleted mission from Core Data")
        }
    }
}

// MARK: - Batch Operations
extension PersistenceController {
    
    /// Batch delete operation
    func batchDelete<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            print("✅ Batch delete completed")
        } catch {
            print("❌ Batch delete error: \(error)")
        }
    }
    
    func deleteAllData() {
        batchDelete(CDSpark.self)
        batchDelete(CDMission.self)
        batchDelete(CDTable.self)
        batchDelete(CDEntry.self)
        batchDelete(CDUserProfile.self)
        print("🗑️ All data deleted from Core Data")
    }
}

// MARK: - Table & Entry Methods
extension PersistenceController {
    
    func createTable(
        title: String,
        description: String,
        category: TableCategory,
        targetGoal: String?
    ) -> TableModel {
        let cdTable = CDTable(context: context)
        
        cdTable.id = UUID()
        cdTable.title = title
        cdTable.desc = description
        cdTable.category = category.rawValue
        cdTable.targetGoal = targetGoal
        cdTable.createdAt = Date()
        cdTable.updatedAt = Date()
        cdTable.isActive = true
        cdTable.totalEntries = 0
        cdTable.totalHours = 0.0
        cdTable.currentStreak = 0
        cdTable.bestStreak = 0
        
        // Associate with user profile
        if let userProfile = getCDUserProfile() {
            cdTable.userProfile = userProfile
        }
        
        save()
        print("✨ Created table in Core Data: \(title)")
        
        return cdTable.toTableModel()
    }
    
    func fetchTables() -> [TableModel] {
        let request: NSFetchRequest<CDTable> = CDTable.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTable.updatedAt, ascending: false)]
        
        let cdTables = fetch(request)
        return cdTables.map { $0.toTableModel() }
    }
    
    func updateTable(_ tableModel: TableModel) {
        let request: NSFetchRequest<CDTable> = CDTable.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tableModel.id as CVarArg)
        
        if let cdTable = try? context.fetch(request).first {
            cdTable.title = tableModel.title
            cdTable.desc = tableModel.description
            cdTable.category = tableModel.category.rawValue
            cdTable.targetGoal = tableModel.targetGoal
            cdTable.totalEntries = Int32(tableModel.totalEntries)
            cdTable.totalHours = tableModel.totalHours
            cdTable.currentStreak = Int32(tableModel.currentStreak)
            cdTable.bestStreak = Int32(tableModel.bestStreak)
            cdTable.lastEntryDate = tableModel.lastEntryDate
            cdTable.isActive = tableModel.isActive
            cdTable.updatedAt = Date()
            
            save()
            print("✅ Updated table in Core Data")
        }
    }
    
    func deleteTable(_ tableId: UUID) {
        let request: NSFetchRequest<CDTable> = CDTable.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tableId as CVarArg)
        
        if let cdTable = try? context.fetch(request).first {
            delete(cdTable)
            print("🗑️ Deleted table from Core Data")
        }
    }
    
    // MARK: - Entry Methods
    
    func createEntry(
        tableId: UUID,
        title: String,
        content: String,
        duration: TimeInterval?,
        tags: [String],
        customData: [String: String]?
    ) -> TableEntryModel {
        let cdEntry = CDEntry(context: context)
        
        cdEntry.id = UUID()
        cdEntry.title = title
        cdEntry.content = content
        cdEntry.duration = duration ?? 0
        cdEntry.tags = tags.joined(separator: ", ")
        cdEntry.createdAt = Date()
        cdEntry.updatedAt = Date()
        cdEntry.type = "general"
        cdEntry.isImportant = false
        
        // Convert customData to JSON string
        if let customData = customData,
           let jsonData = try? JSONSerialization.data(withJSONObject: customData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            cdEntry.customData = jsonString
        }
        
        // Associate with table
        let tableRequest: NSFetchRequest<CDTable> = CDTable.fetchRequest()
        tableRequest.predicate = NSPredicate(format: "id == %@", tableId as CVarArg)
        
        if let cdTable = try? context.fetch(tableRequest).first {
            cdEntry.table = cdTable
            
            // Update table stats
            cdTable.totalEntries += 1
            if let duration = duration {
                cdTable.totalHours += duration / 3600.0
            }
            cdTable.lastEntryDate = Date()
            cdTable.updatedAt = Date()
        }
        
        save()
        print("✨ Created entry in Core Data: \(title)")
        
        return cdEntry.toTableEntryModel()
    }
    
    func fetchEntries(for tableId: UUID) -> [TableEntryModel] {
        let request: NSFetchRequest<CDEntry> = CDEntry.fetchRequest()
        request.predicate = NSPredicate(format: "table.id == %@", tableId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEntry.createdAt, ascending: false)]
        
        let cdEntries = fetch(request)
        return cdEntries.map { $0.toTableEntryModel() }
    }
    
    func updateEntry(_ entryModel: TableEntryModel) {
        let request: NSFetchRequest<CDEntry> = CDEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entryModel.id as CVarArg)
        
        if let cdEntry = try? context.fetch(request).first {
            cdEntry.title = entryModel.title
            cdEntry.content = entryModel.content
            cdEntry.duration = entryModel.duration ?? 0
            cdEntry.tags = entryModel.tags.joined(separator: ", ")
            cdEntry.updatedAt = Date()
            
            // Convert customData to JSON string
            let customData = entryModel.customData
            if !customData.isEmpty,
               let jsonData = try? JSONSerialization.data(withJSONObject: customData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                cdEntry.customData = jsonString
            }
            
            save()
            print("✅ Updated entry in Core Data")
        }
    }
    
    func deleteEntry(_ entryId: UUID) {
        let request: NSFetchRequest<CDEntry> = CDEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
        
        if let cdEntry = try? context.fetch(request).first {
            // Update table stats
            if let cdTable = cdEntry.table {
                cdTable.totalEntries = max(0, cdTable.totalEntries - 1)
                if cdEntry.duration > 0 {
                    cdTable.totalHours = max(0, cdTable.totalHours - (cdEntry.duration / 3600.0))
                }
                cdTable.updatedAt = Date()
            }
            
            delete(cdEntry)
            print("🗑️ Deleted entry from Core Data")
        }
    }
    
    // MARK: - Spark Card Operations
    
    func createSparkCard(
        name: String,
        category: SparkCategory,
        rarity: CardRarity
    ) -> SparkCardModel {
        let cdCard = CDSparkCard(context: context)
        
        cdCard.id = UUID()
        cdCard.name = name
        cdCard.category = category.rawValue
        cdCard.rarity = rarity.rawValue
        cdCard.isOwned = false
        cdCard.ownedCount = 0
        cdCard.obtainedAt = nil
        
        // Associate with user profile
        if let userProfile = getCDUserProfile() {
            cdCard.userProfile = userProfile
        }
        
        save()
        print("✨ Created spark card in Core Data: \(name) (\(rarity.rawValue))")
        
        return cdCard.toSparkCardModel()
    }
    
    func fetchAllSparkCards() -> [SparkCardModel] {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "rarity", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let cdCards = fetch(request)
        return cdCards.map { $0.toSparkCardModel() }
    }
    
    func fetchSparkCard(by id: UUID) -> SparkCardModel? {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let cdCard = try? context.fetch(request).first {
            return cdCard.toSparkCardModel()
        }
        return nil
    }
    
    func fetchSparkCards(byCategory category: SparkCategory) -> [SparkCardModel] {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(key: "rarity", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let cdCards = fetch(request)
        return cdCards.map { $0.toSparkCardModel() }
    }
    
    func fetchSparkCards(byRarity rarity: CardRarity) -> [SparkCardModel] {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "rarity == %@", rarity.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let cdCards = fetch(request)
        return cdCards.map { $0.toSparkCardModel() }
    }
    
    func fetchOwnedSparkCards() -> [SparkCardModel] {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "isOwned == YES")
        request.sortDescriptors = [
            NSSortDescriptor(key: "rarity", ascending: false),
            NSSortDescriptor(key: "obtainedAt", ascending: false)
        ]
        
        let cdCards = fetch(request)
        return cdCards.map { $0.toSparkCardModel() }
    }
    
    func updateSparkCard(_ cardModel: SparkCardModel) {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardModel.id as CVarArg)
        
        if let cdCard = try? context.fetch(request).first {
            cdCard.isOwned = cardModel.isOwned
            cdCard.ownedCount = Int32(cardModel.ownedCount)
            cdCard.obtainedAt = cardModel.obtainedAt
            
            save()
            print("✅ Updated spark card in Core Data: \(cardModel.name)")
        }
    }
    
    func obtainSparkCard(cardId: UUID) -> (isNew: Bool, duplicatePoints: Int) {
        let request: NSFetchRequest<CDSparkCard> = CDSparkCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
        
        guard let cdCard = try? context.fetch(request).first else {
            return (false, 0)
        }
        
        let wasNew = !cdCard.isOwned
        
        if wasNew {
            cdCard.isOwned = true
            cdCard.obtainedAt = Date()
        }
        
        cdCard.ownedCount += 1
        
        save()
        
        let rarity = CardRarity(rawValue: cdCard.rarity ?? "common") ?? .common
        let duplicatePoints = wasNew ? 0 : rarity.duplicatePoints
        
        print(wasNew ? "✨ New spark card obtained: \(cdCard.name ?? "")" : "🔄 Duplicate card obtained: +\(duplicatePoints) points")
        
        return (wasNew, duplicatePoints)
    }
    
    func deleteAllSparkCards() {
        let request: NSFetchRequest<NSFetchRequestResult> = CDSparkCard.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(batchDelete)
            try context.save()
            print("🗑️ Deleted all spark cards")
        } catch {
            print("❌ Failed to delete spark cards: \(error)")
        }
    }
}
