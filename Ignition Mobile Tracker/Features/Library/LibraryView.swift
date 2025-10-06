//
//  LibraryView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var libraryManager = LibraryManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var audioHapticsManager: AudioHapticsManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var showingAddTable = false
    @State private var selectedViewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var selectedCategory: TableCategory?
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedTable: TableModel?
    
    enum ViewMode: String, CaseIterable {
        case grid = "grid"
        case list = "list"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (Fixed at top)
            CustomAppHeader(showingStats: $showingStats, showingSettings: $showingSettings)
                .zIndex(10)
            
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    // MARK: - Controls
                    controlsView
                        .padding(.top, IgnitionSpacing.md)
                
                    // MARK: - Content
                    if libraryManager.isLoading {
                        loadingView
                    } else if filteredTables.isEmpty {
                        emptyStateView
                    } else {
                        tablesContentView
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                // Floating Add Button
                Button(action: {
                    showingAddTable = true
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(IgnitionColors.ignitionOrange)
                        .background(
                            Circle()
                                .fill(Color.black)
                                .frame(width: 50, height: 50)
                        )
                        .shadow(color: IgnitionColors.ignitionOrange.opacity(0.5), radius: 8, x: 0, y: 0)
                        .shadow(color: IgnitionColors.ignitionOrange.opacity(0.3), radius: 12, x: 0, y: 0)
                }
                .padding(.trailing, IgnitionSpacing.lg)
                .padding(.bottom, IgnitionSpacing.xl)
            }
                .navigationBarHidden(true)
            .navigationDestination(for: TableModel.self) { table in
                TableDetailView(table: table)
                    .environmentObject(themeManager)
                    .environmentObject(audioHapticsManager)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTable = true
                        audioHapticsManager.uiTapped()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(IgnitionColors.ignitionOrange)
                    }
                }
            }
            .sheet(isPresented: $showingAddTable) {
                AddTableView()
                    .environmentObject(themeManager)
                    .environmentObject(audioHapticsManager)
            }
                .sheet(isPresented: $showingStats) {
                    LibraryStatsView()
                        .environmentObject(themeManager)
                        .environmentObject(audioHapticsManager)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
            }
        }
        .onAppear {
            libraryManager.loadTables()
        }
    }
    
    
    // MARK: - Controls
    
    private var controlsView: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(IgnitionColors.secondaryText)
                
                TextField("Search tables...", text: $searchText)
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
            
            // Category Filter & View Mode
            HStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IgnitionSpacing.sm) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                                audioHapticsManager.uiTapped()
                            }
                        )
                        
                        ForEach(TableCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                    audioHapticsManager.uiTapped()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, IgnitionSpacing.md)
                }
                
                Spacer()
                
                // View Mode Toggle
                Button(action: {
                    selectedViewMode = selectedViewMode == .grid ? .list : .grid
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: selectedViewMode.icon)
                        .font(.title3)
                        .foregroundColor(IgnitionColors.ignitionOrange)
                }
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your tables...")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(IgnitionColors.secondaryText)
            
            VStack(spacing: IgnitionSpacing.sm) {
                Text("Welcome to Library")
                    .font(IgnitionFonts.title2)
                    .fontWeight(.bold)
                
                Text("Create specialized tracking tables for different areas of your life. Each table can track specific activities with custom fields, photos, and notes.")
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Text("Examples: Poker sessions, Study time, Workouts, Projects, Personal goals, Health metrics, and more.")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, IgnitionSpacing.xs)
            }
            
            Button(action: {
                showingAddTable = true
                audioHapticsManager.uiTapped()
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First Table")
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
        .padding(IgnitionSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var tablesContentView: some View {
        ScrollView {
            LazyVStack(spacing: IgnitionSpacing.md) {
                if selectedViewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.bottom, IgnitionSpacing.xl)
        }
    }
    
    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: IgnitionSpacing.md),
            GridItem(.flexible(), spacing: IgnitionSpacing.md)
        ], spacing: IgnitionSpacing.md) {
            ForEach(filteredTables) { table in
                TableGridCard(table: table) {
                    navigateToTable(table)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        deleteTable(table)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private var listView: some View {
        LazyVStack(spacing: IgnitionSpacing.sm) {
            ForEach(filteredTables) { table in
                TableListRow(table: table) {
                    navigateToTable(table)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTable(table)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTables: [TableModel] {
        var tables = libraryManager.tables
        
        // Filter by search text
        if !searchText.isEmpty {
            tables = tables.filter { table in
                table.title.localizedCaseInsensitiveContains(searchText) ||
                table.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            tables = tables.filter { $0.category == selectedCategory }
        }
        
        // Sort by last entry date (most recent first)
        return tables.sorted { table1, table2 in
            let date1 = table1.lastEntryDate ?? table1.createdAt
            let date2 = table2.lastEntryDate ?? table2.createdAt
            return date1 > date2
        }
    }
    
    // MARK: - Actions
    
    private func navigateToTable(_ table: TableModel) {
        navigationPath.append(table)
        audioHapticsManager.uiTapped()
    }
    
    private func deleteTable(_ table: TableModel) {
        Task {
            await libraryManager.deleteTable(table.id)
            audioHapticsManager.uiTapped()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(IgnitionFonts.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(IgnitionFonts.caption2)
                .foregroundColor(IgnitionColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, IgnitionSpacing.sm)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(IgnitionFonts.caption2)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : IgnitionColors.primaryText)
                .padding(.horizontal, IgnitionSpacing.md)
                .padding(.vertical, IgnitionSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                        .fill(isSelected ? IgnitionColors.ignitionOrange : IgnitionColors.cardBackground)
                )
        }
    }
}

struct TableGridCard: View {
    let table: TableModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: table.category.icon)
                        .font(.title2)
                        .foregroundColor(table.category.color)
                    
                    Spacer()
                    
                    if !table.isActive {
                        Image(systemName: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                }
                
                // Title
                Text(table.title)
                    .font(IgnitionFonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(IgnitionColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Stats
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("\(table.totalEntries)")
                            .font(IgnitionFonts.caption2)
                            .fontWeight(.semibold)
                        Text("entries")
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                    
                    if table.currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("\(table.currentStreak) day streak")
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(IgnitionSpacing.md)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                    .fill(IgnitionColors.cardBackground)
                    .shadow(color: IgnitionColors.lightGray.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TableListRow: View {
    let table: TableModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IgnitionSpacing.md) {
                // Icon
                Image(systemName: table.category.icon)
                    .font(.title2)
                    .foregroundColor(table.category.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(table.category.color.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(table.title)
                            .font(IgnitionFonts.body)
                            .fontWeight(.semibold)
                            .foregroundColor(IgnitionColors.primaryText)
                        
                        Spacer()
                        
                        if !table.isActive {
                            Image(systemName: "pause.circle.fill")
                                .font(.caption)
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                    
                    Text(table.description.isEmpty ? "No description" : table.description)
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(IgnitionColors.secondaryText)
                        .lineLimit(1)
                    
                    HStack {
                        Text("\(table.totalEntries) entries")
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        if table.currentStreak > 0 {
                            Text("•")
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(IgnitionColors.secondaryText)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("\(table.currentStreak)")
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        if let lastEntry = table.lastEntryDate {
                            Text(lastEntry, style: .relative)
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
                    .shadow(color: IgnitionColors.lightGray.opacity(0.2), radius: 1, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LibraryView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AudioHapticsManager.shared)
}
