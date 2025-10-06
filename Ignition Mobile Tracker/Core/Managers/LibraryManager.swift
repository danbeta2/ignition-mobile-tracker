//
//  LibraryManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var tables: [TableModel] = []
    @Published var entries: [UUID: [TableEntryModel]] = [:] // tableId -> entries
    @Published var isLoading = false
    @Published var error: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTables()
        setupNotificationObservers()
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .tableAdded)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadTables()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .entryAdded)
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let tableId = notification.object as? UUID {
                        self?.loadEntries(for: tableId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Table Operations
    
    func loadTables() {
        isLoading = true
        error = nil
        
        Task {
            await MainActor.run {
                // Load from Core Data
                self.tables = persistenceController.fetchTables()
                self.isLoading = false
                print("📊 Loaded \(self.tables.count) tables from Core Data")
            }
        }
    }
    
    func createTable(_ table: TableModel) async {
        // Save to Core Data and get the saved model
        let savedTable = persistenceController.createTable(
            title: table.title,
            description: table.description,
            category: table.category,
            targetGoal: table.targetGoal
        )
        
        await MainActor.run {
            tables.append(savedTable)
            
            // Initialize empty entries array for this table
            entries[savedTable.id] = []
        }
        
        NotificationCenter.default.post(name: .tableAdded, object: savedTable.id)
        
        print("✨ Created table: \(savedTable.title)")
    }
    
    func updateTable(_ table: TableModel) async {
        // Update in Core Data
        persistenceController.updateTable(table)
        
        if let index = tables.firstIndex(where: { $0.id == table.id }) {
            var updatedTable = table
            updatedTable.updatedAt = Date()
            tables[index] = updatedTable
            print("✅ Updated table: \(table.title)")
        }
    }
    
    func deleteTable(_ tableId: UUID) async {
        // Delete from Core Data
        persistenceController.deleteTable(tableId)
        
        tables.removeAll { $0.id == tableId }
        entries.removeValue(forKey: tableId)
        
        print("🗑️ Deleted table: \(tableId)")
    }
    
    func getTable(by id: UUID) -> TableModel? {
        return tables.first { $0.id == id }
    }
    
    func getActiveTablesCount() -> Int {
        return tables.filter { $0.isActive }.count
    }
    
    // MARK: - Entry Operations
    
    func loadEntries(for tableId: UUID) {
        Task {
            await MainActor.run {
                // Load from Core Data
                let loadedEntries = persistenceController.fetchEntries(for: tableId)
                self.entries[tableId] = loadedEntries
                print("📊 Loaded \(loadedEntries.count) entries from Core Data for table \(tableId)")
            }
        }
    }
    
    func addEntry(_ entry: TableEntryModel) async {
        // Save to Core Data
        let savedEntry = persistenceController.createEntry(
            tableId: entry.tableId,
            title: entry.title,
            content: entry.content,
            duration: entry.duration,
            tags: entry.tags,
            customData: entry.customData
        )
        
        // Add to entries array
        await MainActor.run {
            if entries[entry.tableId] == nil {
                entries[entry.tableId] = []
            }
            entries[entry.tableId]?.append(savedEntry)
        }
        
        // Update table statistics
        await updateTableStats(for: entry.tableId, with: savedEntry)
        
        NotificationCenter.default.post(name: .entryAdded, object: entry.tableId)
        
        print("✨ Added entry to table: \(entry.tableId)")
    }
    
    func updateEntry(_ entry: TableEntryModel) async {
        // Update in Core Data
        persistenceController.updateEntry(entry)
        
        guard var tableEntries = entries[entry.tableId],
              let index = tableEntries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }
        
        var updatedEntry = entry
        updatedEntry.updatedAt = Date()
        tableEntries[index] = updatedEntry
        entries[entry.tableId] = tableEntries
        
        print("✅ Updated entry: \(entry.id)")
    }
    
    func deleteEntry(_ entryId: UUID, from tableId: UUID) async {
        // Delete from Core Data
        persistenceController.deleteEntry(entryId)
        
        entries[tableId]?.removeAll { $0.id == entryId }
        
        // Update table statistics
        await recalculateTableStats(for: tableId)
        
        print("🗑️ Deleted entry: \(entryId)")
    }
    
    func getEntries(for tableId: UUID) -> [TableEntryModel] {
        return entries[tableId]?.sorted { $0.createdAt > $1.createdAt } ?? []
    }
    
    func getRecentEntries(limit: Int = 10) -> [TableEntryModel] {
        let allEntries = entries.values.flatMap { $0 }
        return Array(allEntries.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    // MARK: - Statistics
    
    func getLibraryStats() -> LibraryStats {
        let totalTables = tables.count
        let activeTables = tables.filter { $0.isActive }.count
        let totalEntries = entries.values.reduce(0) { $0 + $1.count }
        let totalHours = tables.reduce(0) { $0 + $1.totalHours }
        let longestStreak = tables.map { $0.bestStreak }.max() ?? 0
        
        // Find most active category
        let categoryCount = Dictionary(grouping: tables, by: { $0.category })
            .mapValues { $0.count }
        let mostActiveCategory = categoryCount.max { $0.value < $1.value }?.key
        
        // Calculate weekly/monthly progress (placeholder)
        let weeklyProgress = 0.75 // 75% of weekly goal
        let monthlyProgress = 0.60 // 60% of monthly goal
        
        return LibraryStats(
            totalTables: totalTables,
            activeTables: activeTables,
            totalEntries: totalEntries,
            totalHours: totalHours,
            longestStreak: longestStreak,
            mostActiveCategory: mostActiveCategory,
            weeklyProgress: weeklyProgress,
            monthlyProgress: monthlyProgress
        )
    }
    
    // MARK: - Private Methods
    
    
    private func updateTableStats(for tableId: UUID, with entry: TableEntryModel) async {
        guard let tableIndex = tables.firstIndex(where: { $0.id == tableId }) else { return }
        
        var table = tables[tableIndex]
        table.totalEntries += 1
        table.lastEntryDate = entry.createdAt
        
        if let duration = entry.duration {
            table.totalHours += duration / 3600 // Convert seconds to hours
        }
        
        // Update streak
        updateStreak(for: &table)
        
        table.updatedAt = Date()
        tables[tableIndex] = table
        
        // Update in Core Data
        persistenceController.updateTable(table)
    }
    
    private func recalculateTableStats(for tableId: UUID) async {
        guard let tableIndex = tables.firstIndex(where: { $0.id == tableId }) else { return }
        
        var table = tables[tableIndex]
        let tableEntries = entries[tableId] ?? []
        
        table.totalEntries = tableEntries.count
        table.totalHours = tableEntries.compactMap { $0.duration }.reduce(0, +) / 3600
        table.lastEntryDate = tableEntries.max { $0.createdAt < $1.createdAt }?.createdAt
        
        updateStreak(for: &table)
        
        table.updatedAt = Date()
        tables[tableIndex] = table
        
        // Update in Core Data
        persistenceController.updateTable(table)
    }
    
    private func updateStreak(for table: inout TableModel) {
        let tableEntries = entries[table.id] ?? []
        
        // Calculate current streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var checkDate = today
        
        for _ in 0..<30 { // Check last 30 days
            let dayEntries = tableEntries.filter {
                calendar.isDate($0.createdAt, inSameDayAs: checkDate)
            }
            
            if dayEntries.isEmpty {
                break
            } else {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        table.currentStreak = currentStreak
        if currentStreak > table.bestStreak {
            table.bestStreak = currentStreak
        }
    }
    
}

// MARK: - Notification Names
extension Notification.Name {
    static let tableAdded = Notification.Name("tableAdded")
    static let entryAdded = Notification.Name("entryAdded")
}
