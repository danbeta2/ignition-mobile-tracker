//
//  TrackerView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct TrackerView: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var showingAddSpark = false
    @State private var searchText = ""
    @State private var selectedCategory: SparkCategory?
    @State private var sortOption: SortOption = .newest
    @State private var showingError = false
    
    enum SortOption: String, CaseIterable {
        case newest = "Più Recenti"
        case oldest = "Più Vecchi"
        case points = "Punti"
        case category = "Categoria"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterSection
                
                // Content
                if sparkManager.isLoading {
                    loadingView
                } else if filteredSparks.isEmpty {
                    emptyStateView
                } else {
                    sparkListView
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addSparkButton
                }
            }
            .sheet(isPresented: $showingAddSpark) {
                AddSparkView()
            }
            .alert("Errore", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(sparkManager.error ?? "Si è verificato un errore imprevisto")
            }
            .onChange(of: sparkManager.error) { _, error in
                showingError = error != nil
            }
            .onAppear {
                // Check if we need to show AddSpark from QuickActions
                if tabRouter.shouldShowAddSpark {
                    showingAddSpark = true
                    tabRouter.shouldShowAddSpark = false
                }
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(IgnitionColors.mediumGray)
                
                TextField("Cerca spark...", text: $searchText)
                    .font(IgnitionFonts.body)
                    .foregroundColor(themeManager.textColor)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(IgnitionColors.mediumGray)
                    }
                }
            }
            .padding(IgnitionSpacing.sm)
            .background(themeManager.cardColor)
            .cornerRadius(IgnitionRadius.sm)
            
            // Filter Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    // All Categories Button
                    filterChip(
                        title: "Tutti",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    // Category Filters
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        filterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            audioHapticsManager.playSelectionHaptic()
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                    
                    // Sort Button
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                audioHapticsManager.playSelectionHaptic()
                                sortOption = option
                            }
                        }
                    } label: {
                        HStack(spacing: IgnitionSpacing.xs) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.rawValue)
                        }
                        .font(IgnitionFonts.callout)
                        .foregroundColor(themeManager.primaryColor)
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(themeManager.primaryColor.opacity(0.1))
                        .cornerRadius(IgnitionRadius.sm)
                    }
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
        .background(themeManager.backgroundColor)
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(IgnitionFonts.callout)
                .foregroundColor(isSelected ? IgnitionColors.ignitionWhite : themeManager.textColor)
                .padding(.horizontal, IgnitionSpacing.sm)
                .padding(.vertical, IgnitionSpacing.xs)
                .background(isSelected ? themeManager.primaryColor : themeManager.cardColor)
                .cornerRadius(IgnitionRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Add Spark Button
    private var addSparkButton: some View {
        Button(action: {
            audioHapticsManager.uiTapped()
            showingAddSpark = true
        }) {
            Image(systemName: AssetNames.SystemIcons.addButton.systemName)
                .font(.title2)
                .foregroundColor(themeManager.primaryColor)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.primaryColor)
            
            Text("Caricamento spark...")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(IgnitionColors.mediumGray)
            
            VStack(spacing: IgnitionSpacing.sm) {
                Text(emptyStateTitle)
                    .font(IgnitionFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(emptyStateMessage)
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Aggiungi il tuo primo Spark") {
                showingAddSpark = true
            }
            .font(IgnitionFonts.body)
            .fontWeight(.semibold)
            .foregroundColor(IgnitionColors.ignitionWhite)
            .padding(.horizontal, IgnitionSpacing.lg)
            .padding(.vertical, IgnitionSpacing.md)
            .background(themeManager.primaryColor)
            .cornerRadius(IgnitionRadius.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(IgnitionSpacing.lg)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "Nessun risultato"
        } else if selectedCategory != nil {
            return "Nessun spark in questa categoria"
        } else {
            return "Inizia il tuo viaggio"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Prova a modificare i termini di ricerca o i filtri"
        } else if selectedCategory != nil {
            return "Non hai ancora creato spark in questa categoria"
        } else {
            return "Crea il tuo primo spark e inizia a tracciare la tua energia!"
        }
    }
    
    // MARK: - Spark List View
    private var sparkListView: some View {
        List {
            ForEach(filteredSparks, id: \.id) { spark in
                SparkRowView(
                    spark: spark,
                    isSelected: false,
                    isSelectionMode: false,
                    onTap: {
                        // Handle spark tap
                    },
                    onLongPress: {
                        // Handle long press
                    },
                    onToggleSelection: {
                        // Handle selection toggle
                    },
                    onDelete: {
                        // Handle delete
                    }
                )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: IgnitionSpacing.xs,
                        leading: IgnitionSpacing.md,
                        bottom: IgnitionSpacing.xs,
                        trailing: IgnitionSpacing.md
                    ))
            }
            .onDelete(perform: deleteSparks)
        }
        .listStyle(PlainListStyle())
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - Computed Properties
    private var filteredSparks: [SparkModel] {
        var sparks = sparkManager.sparks
        
        // Apply search filter
        if !searchText.isEmpty {
            sparks = sparkManager.searchSparks(searchText)
        }
        
        // Apply category filter
        if let category = selectedCategory {
            sparks = sparks.filter { $0.category == category }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            sparks = sparks.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            sparks = sparks.sorted { $0.createdAt < $1.createdAt }
        case .points:
            sparks = sparks.sorted { $0.points > $1.points }
        case .category:
            sparks = sparks.sorted { $0.category.rawValue < $1.category.rawValue }
        }
        
        return sparks
    }
    
    // MARK: - Actions
    private func deleteSparks(offsets: IndexSet) {
        for index in offsets {
            let spark = filteredSparks[index]
            sparkManager.deleteSpark(spark)
        }
    }
}

// MARK: - Spark Row View
// SparkRowView moved to TrackerViewExpanded.swift to avoid duplication

/*
struct SparkRowView: View {
    let spark: SparkModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    var body: some View {
        Button(action: {
            // Navigate to spark detail
            tabRouter.navigate(to: .sparkDetail, with: spark)
        }) {
            HStack(spacing: IgnitionSpacing.md) {
                // Category Icon
                Image(systemName: spark.category.iconName)
                    .font(.title2)
                    .foregroundColor(themeManager.primaryColor)
                    .frame(width: 40, height: 40)
                    .background(themeManager.primaryColor.opacity(0.1))
                    .cornerRadius(IgnitionRadius.sm)
                
                // Content
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(spark.title)
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(2)
                    
                    HStack {
                        Text(spark.category.displayName)
                            .font(IgnitionFonts.caption1)
                            .foregroundColor(themeManager.primaryColor)
                        
                        Text("•")
                            .font(IgnitionFonts.caption1)
                            .foregroundColor(IgnitionColors.mediumGray)
                        
                        Text(spark.intensity.displayName)
                            .font(IgnitionFonts.caption1)
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        Spacer()
                        
                        Text(timeAgo(from: spark.createdAt))
                            .font(IgnitionFonts.caption1)
                            .foregroundColor(IgnitionColors.mediumGray)
                    }
                    
                    if !spark.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: IgnitionSpacing.xs) {
                                ForEach(spark.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(IgnitionFonts.caption2)
                                        .foregroundColor(IgnitionColors.mediumGray)
                                        .padding(.horizontal, IgnitionSpacing.xs)
                                        .padding(.vertical, 2)
                                        .background(IgnitionColors.mediumGray.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                
                // Points
                VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                    Text("+\(spark.points)")
                        .font(IgnitionFonts.callout)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryColor)
                    
                    intensityIndicator(spark.intensity)
                }
            }
            .padding(IgnitionSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(IgnitionRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func intensityIndicator(_ intensity: SparkIntensity) -> some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { level in
                Circle()
                    .fill(level <= intensity.rawValue ? themeManager.primaryColor : IgnitionColors.mediumGray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
*/

// MARK: - Preview
#Preview {
    TrackerView()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
