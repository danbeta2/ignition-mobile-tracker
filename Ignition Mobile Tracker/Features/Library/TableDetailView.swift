//
//  TableDetailView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI

struct TableDetailView: View {
    let table: TableModel
    @StateObject private var libraryManager = LibraryManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var audioHapticsManager: AudioHapticsManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var showingAddEntry = false
    @State private var selectedEntry: TableEntryModel?
    @State private var searchText = ""
    @State private var selectedFilter: EntryFilter = .all
    @State private var sortOption: SortOption = .newest
    
    enum EntryFilter: String, CaseIterable {
        case all = "all"
        case sessions = "sessions"
        case milestones = "milestones"
        case notes = "notes"
        case photos = "photos"
        case important = "important"
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .sessions: return "Sessions"
            case .milestones: return "Milestones"
            case .notes: return "Notes"
            case .photos: return "Photos"
            case .important: return "Important"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "newest"
        case oldest = "oldest"
        case title = "title"
        case type = "type"
        
        var displayName: String {
            switch self {
            case .newest: return "Newest"
            case .oldest: return "Oldest"
            case .title: return "Title"
            case .type: return "Type"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: IgnitionSpacing.lg) {
                // MARK: - Header Stats
                headerStatsView
                
                // MARK: - Controls
                controlsView
                
                // MARK: - Entries List
                entriesListView
            }
            .padding(IgnitionSpacing.md)
        }
        .navigationTitle(table.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddEntry = true
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(IgnitionColors.ignitionOrange)
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView(table: table)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry, table: table)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
        }
        .onAppear {
            libraryManager.loadEntries(for: table.id)
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStatsView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Table info
            HStack {
                Image(systemName: table.category.icon)
                    .font(.title)
                    .foregroundColor(table.category.color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(table.category.color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.title)
                        .font(IgnitionFonts.title2)
                        .fontWeight(.bold)
                    
                    if !table.description.isEmpty {
                        Text(table.description)
                            .font(IgnitionFonts.body)
                            .foregroundColor(IgnitionColors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    if let goal = table.targetGoal {
                        Text("Goal: \(goal)")
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.ignitionOrange)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // Stats grid
            HStack(spacing: IgnitionSpacing.md) {
                StatCard(
                    title: "Entries",
                    value: "\(table.totalEntries)",
                    icon: "doc.text",
                    color: .blue
                )
                
                StatCard(
                    title: "Hours",
                    value: String(format: "%.1f", table.totalHours),
                    icon: "clock",
                    color: .green
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(table.currentStreak)",
                    icon: "flame",
                    color: .orange
                )
                
                StatCard(
                    title: "Best",
                    value: "\(table.bestStreak)",
                    icon: "trophy",
                    color: .yellow
                )
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
                .shadow(color: IgnitionColors.lightGray.opacity(0.2), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(IgnitionColors.secondaryText)
                
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        audioHapticsManager.uiTapped()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.vertical, IgnitionSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                    .fill(IgnitionColors.cardBackground)
            )
            
            // Filters and Sort
            HStack {
                // Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IgnitionSpacing.xs) {
                        ForEach(EntryFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter,
                                action: {
                                    selectedFilter = filter
                                    audioHapticsManager.uiTapped()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
                
                Spacer()
                
                // Sort
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                            audioHapticsManager.uiTapped()
                        }) {
                            HStack {
                                Text(option.displayName)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.displayName)
                    }
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.ignitionOrange)
                    .padding(.horizontal, IgnitionSpacing.sm)
                    .padding(.vertical, IgnitionSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                            .fill(IgnitionColors.ignitionOrange.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Entries List
    
    private var entriesListView: some View {
        LazyVStack(spacing: IgnitionSpacing.md) {
            let entries = filteredAndSortedEntries
            
            if entries.isEmpty {
                emptyStateView
            } else {
                ForEach(entries, id: \.id) { entry in
                    EntryRowView(entry: entry) {
                        selectedEntry = entry
                        audioHapticsManager.uiTapped()
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: selectedFilter == .all ? "doc.text" : getFilterIcon())
                .font(.system(size: 50))
                .foregroundColor(IgnitionColors.secondaryText)
            
            VStack(spacing: IgnitionSpacing.sm) {
                Text(selectedFilter == .all ? "No Entries Yet" : "No \(selectedFilter.displayName)")
                    .font(IgnitionFonts.title3)
                    .fontWeight(.semibold)
                
                Text(selectedFilter == .all ? 
                     "Start tracking your progress by adding your first entry." :
                     "No entries match the current filter.")
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if selectedFilter == .all {
                Button(action: {
                    showingAddEntry = true
                    audioHapticsManager.uiTapped()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add First Entry")
                    }
                    .font(IgnitionFonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, IgnitionSpacing.lg)
                    .padding(.vertical, IgnitionSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                            .fill(IgnitionColors.ignitionOrange)
                    )
                }
            }
        }
        .padding(IgnitionSpacing.xl)
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedEntries: [TableEntryModel] {
        var entries = libraryManager.getEntries(for: table.id)
        
        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .sessions:
            entries = entries.filter { $0.type == .session }
        case .milestones:
            entries = entries.filter { $0.type == .milestone }
        case .notes:
            entries = entries.filter { $0.type == .note }
        case .photos:
            entries = entries.filter { $0.photoData != nil }
        case .important:
            entries = entries.filter { $0.isImportant }
        }
        
        // Apply sort
        switch sortOption {
        case .newest:
            entries = entries.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            entries = entries.sorted { $0.createdAt < $1.createdAt }
        case .title:
            entries = entries.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .type:
            entries = entries.sorted { $0.type.displayName.localizedCaseInsensitiveCompare($1.type.displayName) == .orderedAscending }
        }
        
        return entries
    }
    
    // MARK: - Helper Methods
    
    private func getFilterIcon() -> String {
        switch selectedFilter {
        case .all: return "doc.text"
        case .sessions: return "clock"
        case .milestones: return "flag"
        case .notes: return "note.text"
        case .photos: return "camera"
        case .important: return "star"
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(IgnitionFonts.caption2)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : IgnitionColors.primaryText)
                .padding(.horizontal, IgnitionSpacing.sm)
                .padding(.vertical, IgnitionSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                        .fill(isSelected ? IgnitionColors.ignitionOrange : IgnitionColors.cardBackground)
                )
        }
    }
}

struct EntryRowView: View {
    let entry: TableEntryModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IgnitionSpacing.md) {
                // Type icon
                VStack {
                    Image(systemName: entry.type.icon)
                        .font(.title2)
                        .foregroundColor(typeColor)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(typeColor.opacity(0.1))
                        )
                    
                    if entry.isImportant {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.title)
                            .font(IgnitionFonts.body)
                            .fontWeight(.semibold)
                            .foregroundColor(IgnitionColors.primaryText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let mood = entry.mood {
                            HStack(spacing: 2) {
                                Image(systemName: "face.smiling.fill")
                                    .font(.caption2)
                                Text("\(mood)")
                                    .font(IgnitionFonts.caption2)
                            }
                            .foregroundColor(moodColor(mood))
                        }
                    }
                    
                    if !entry.content.isEmpty {
                        Text(entry.content)
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        // Type and duration/value
                        HStack(spacing: IgnitionSpacing.xs) {
                            Text(entry.type.displayName)
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(IgnitionColors.secondaryText)
                            
                            if let duration = entry.duration, duration > 0 {
                                Text("•")
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                                
                                Text(formatDuration(duration))
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                            }
                            
                            if let value = entry.value, value > 0 {
                                Text("•")
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                                
                                Text(String(format: "%.1f", value))
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Tags and photo indicator
                        HStack(spacing: IgnitionSpacing.xs) {
                            if !entry.tags.isEmpty {
                                Image(systemName: "tag")
                                    .font(.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                            }
                            
                            if entry.photoData != nil {
                                Image(systemName: "camera.fill")
                                    .font(.caption2)
                                    .foregroundColor(IgnitionColors.ignitionOrange)
                            }
                            
                            Text(entry.createdAt, style: .relative)
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            .padding(IgnitionSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                    .fill(IgnitionColors.cardBackground)
                    .shadow(color: IgnitionColors.lightGray.opacity(0.1), radius: 1, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var typeColor: Color {
        switch entry.type {
        case .session: return .blue
        case .milestone: return .green
        case .note: return .purple
        case .photo: return .orange
        case .achievement: return .yellow
        }
    }
    
    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return IgnitionColors.secondaryText
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    NavigationStack {
        TableDetailView(table: TableModel(
            title: "Poker Sessions",
            description: "Track your poker games and progress",
            category: .poker,
            totalEntries: 15,
            totalHours: 45.5,
            bestStreak: 7,
            currentStreak: 3,
            targetGoal: "Improve win rate and bankroll management"
        ))
    }
    .environmentObject(ThemeManager.shared)
    .environmentObject(AudioHapticsManager.shared)
}
