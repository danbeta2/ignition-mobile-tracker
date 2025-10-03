//
//  LibraryStatsView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct LibraryStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libraryManager = LibraryManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Overall Stats
                    overallStatsView
                    
                    // Category Breakdown
                    categoryBreakdownView
                    
                    // Recent Activity
                    recentActivityView
                }
                .padding(IgnitionSpacing.md)
            }
            .navigationTitle("Library Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Overall Stats
    
    private var overallStatsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Overview")
                .font(IgnitionFonts.title2)
                .fontWeight(.bold)
            
            let stats = libraryManager.getLibraryStats()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: IgnitionSpacing.md) {
                StatsCard(
                    title: "Total Tables",
                    value: "\(stats.totalTables)",
                    subtitle: "\(stats.activeTables) active",
                    color: .blue
                )
                
                StatsCard(
                    title: "Total Entries",
                    value: "\(stats.totalEntries)",
                    subtitle: "All time",
                    color: .green
                )
                
                StatsCard(
                    title: "Hours Logged",
                    value: String(format: "%.1f", stats.totalHours),
                    subtitle: "Total time",
                    color: .orange
                )
                
                StatsCard(
                    title: "Best Streak",
                    value: "\(stats.longestStreak)",
                    subtitle: "Days",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Categories")
                .font(IgnitionFonts.title2)
                .fontWeight(.bold)
            
            let categoryStats = getCategoryStats()
            
            ForEach(categoryStats, id: \.category) { stat in
                CategoryRow(
                    category: stat.category,
                    count: stat.count,
                    percentage: stat.percentage
                )
            }
        }
    }
    
    // MARK: - Recent Activity
    
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Recent Activity")
                .font(IgnitionFonts.title2)
                .fontWeight(.bold)
            
            let recentEntries = libraryManager.getRecentEntries(limit: 5)
            
            if recentEntries.isEmpty {
                Text("No recent activity")
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, IgnitionSpacing.lg)
            } else {
                ForEach(recentEntries, id: \.id) { entry in
                    RecentEntryRow(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCategoryStats() -> [(category: TableCategory, count: Int, percentage: Double)] {
        let tables = libraryManager.tables
        let totalTables = tables.count
        
        guard totalTables > 0 else { return [] }
        
        let categoryCount = Dictionary(grouping: tables, by: { $0.category })
            .mapValues { $0.count }
        
        return TableCategory.allCases.compactMap { category in
            let count = categoryCount[category] ?? 0
            guard count > 0 else { return nil }
            
            let percentage = Double(count) / Double(totalTables) * 100
            return (category: category, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }
}

// MARK: - Supporting Views

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(IgnitionFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(IgnitionColors.primaryText)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(IgnitionFonts.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            .multilineTextAlignment(.center)
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
                .shadow(color: IgnitionColors.lightGray.opacity(0.2), radius: 2, x: 0, y: 1)
        )
    }
}

struct CategoryRow: View {
    let category: TableCategory
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(IgnitionFonts.body)
                    .fontWeight(.medium)
                
                Text("\(count) tables")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", percentage))
                    .font(IgnitionFonts.body)
                    .fontWeight(.semibold)
                
                // Progress bar
                ProgressView(value: percentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: category.color))
                    .frame(width: 60)
            }
        }
        .padding(.vertical, IgnitionSpacing.xs)
    }
}

struct RecentEntryRow: View {
    let entry: TableEntryModel
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.md) {
            Image(systemName: entry.type.icon)
                .font(.title3)
                .foregroundColor(IgnitionColors.ignitionOrange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(IgnitionFonts.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(entry.type.displayName)
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            Spacer()
            
            Text(entry.createdAt, style: .relative)
                .font(IgnitionFonts.caption2)
                .foregroundColor(IgnitionColors.secondaryText)
        }
        .padding(.vertical, IgnitionSpacing.xs)
    }
}

#Preview {
    LibraryStatsView()
        .environmentObject(ThemeManager.shared)
}
