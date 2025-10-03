//
//  SparkManager.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import CoreData
import Combine

// MARK: - Spark Manager
@MainActor
class SparkManager: ObservableObject {
    static let shared = SparkManager()
    
    @Published var sparks: [SparkModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSparks()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for Core Data changes to reload sparks
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                // Only reload if CDSpark entities were changed
                if let userInfo = notification.userInfo,
                   let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                   let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                   let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                    
                    let hasSparkChanges = inserted.contains { $0 is CDSpark } ||
                                         updated.contains { $0 is CDSpark } ||
                                         deleted.contains { $0 is CDSpark }
                    
                    if hasSparkChanges {
                        Task { @MainActor in
                            self?.loadSparks()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    func loadSparks() {
        isLoading = true
        error = nil
        
        Task {
            await MainActor.run {
                // Load from Core Data
                self.sparks = persistenceController.fetchSparks()
                self.isLoading = false
                print("📊 Loaded \(self.sparks.count) sparks from Core Data")
            }
        }
    }
    
    func addSpark(_ spark: SparkModel) {
        // Save to Core Data
        let savedSpark = persistenceController.createSpark(
            title: spark.title,
            category: spark.category,
            intensity: spark.intensity,
            notes: spark.notes,
            tags: spark.tags.joined(separator: ", "),
            location: nil
        )
        
        // Update in-memory array immediately for UI responsiveness
        self.sparks.insert(savedSpark, at: 0)
        
        print("✨ Spark added: \(savedSpark.title) - Total sparks: \(self.sparks.count)")
        
        // Notify other managers
        NotificationCenter.default.post(name: .sparkAdded, object: savedSpark)
        
        // Play feedback
        AudioHapticsManager.shared.sparkAdded()
    }
    
    func updateSpark(_ spark: SparkModel) {
        // Update in Core Data
        persistenceController.updateSpark(spark)
        
        // Update in-memory array
        var updatedSpark = spark
        updatedSpark.updatedAt = Date()
        
        if let index = self.sparks.firstIndex(where: { $0.id == spark.id }) {
            self.sparks[index] = updatedSpark
        }
        
        print("✅ Spark updated: \(spark.title)")
        NotificationCenter.default.post(name: .sparkUpdated, object: updatedSpark)
    }
    
    func deleteSpark(_ spark: SparkModel) {
        // Delete from Core Data
        persistenceController.deleteSpark(spark)
        
        // Remove from in-memory array
        self.sparks.removeAll { $0.id == spark.id }
        
        print("🗑️ Spark deleted: \(spark.title)")
        NotificationCenter.default.post(name: .sparkDeleted, object: spark)
    }
    
    // MARK: - Filtering & Search
    func sparks(for category: SparkCategory) -> [SparkModel] {
        return sparks.filter { $0.category == category }
    }
    
    func sparks(withTag tag: String) -> [SparkModel] {
        return sparks.filter { $0.tags.contains(tag) }
    }
    
    func sparks(from startDate: Date, to endDate: Date) -> [SparkModel] {
        return sparks.filter { spark in
            spark.createdAt >= startDate && spark.createdAt <= endDate
        }
    }
    
    func searchSparks(_ query: String) -> [SparkModel] {
        guard !query.isEmpty else { return sparks }
        
        return sparks.filter { spark in
            spark.title.localizedCaseInsensitiveContains(query) ||
            spark.notes?.localizedCaseInsensitiveContains(query) == true ||
            spark.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Statistics
    func totalPoints() -> Int {
        return sparks.reduce(0) { $0 + $1.points }
    }
    
    func sparkCount(for category: SparkCategory) -> Int {
        return sparks(for: category).count
    }
    
    func averageIntensity() -> Double {
        guard !sparks.isEmpty else { return 0 }
        
        let totalIntensity = sparks.reduce(0) { $0 + Int($1.intensity.rawValue) }
        return Double(totalIntensity) / Double(sparks.count)
    }
    
    func currentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasSparksOnDay = sparks.contains { spark in
                spark.createdAt >= dayStart && spark.createdAt < dayEnd
            }
            
            if hasSparksOnDay {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Core Data Conversion Helpers
    // TODO: Add these methods when Core Data model is properly set up
    
}

// MARK: - Notification Names
extension Notification.Name {
    static let sparkAdded = Notification.Name("sparkAdded")
    static let sparkUpdated = Notification.Name("sparkUpdated")
    static let sparkDeleted = Notification.Name("sparkDeleted")
    static let overloadTriggered = Notification.Name("overloadTriggered")
}
