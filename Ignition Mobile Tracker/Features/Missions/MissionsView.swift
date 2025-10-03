//
//  MissionsView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct MissionsView: View {
    @StateObject private var missionManager = MissionManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var selectedFilter: MissionFilter = .all
    @State private var showingError = false
    @State private var showingStats = false
    @State private var showingSettings = false
    
    enum MissionFilter: String, CaseIterable {
        case all = "All"
        case daily = "Daily"
        case weekly = "Weekly"
        case completed = "Completed"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (Fixed at top)
            CustomAppHeader(showingStats: $showingStats, showingSettings: $showingSettings)
                .zIndex(10)
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: IgnitionSpacing.lg) {
                        // Filter Section
                        filterSection
                            .padding(.top, IgnitionSpacing.md)
                    
                    // Missions List
                    if missionManager.isLoading {
                        loadingView
                    } else if filteredMissions.isEmpty {
                        emptyStateView
                    } else {
                        missionsListSection
                    }
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
                .background(themeManager.backgroundColor)
                .navigationBarHidden(true)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(missionManager.error ?? "An unexpected error occurred")
            }
                .onChange(of: missionManager.error) { _, error in
                    showingError = error != nil
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsViewExpanded()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: IgnitionSpacing.sm) {
                ForEach(MissionFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    private func filterChip(_ filter: MissionFilter) -> some View {
        Button(action: {
            audioHapticsManager.playSelectionHaptic()
            selectedFilter = filter
        }) {
            Text(filter.rawValue)
                .font(IgnitionFonts.callout)
                .foregroundColor(selectedFilter == filter ? IgnitionColors.ignitionWhite : themeManager.textColor)
                .padding(.horizontal, IgnitionSpacing.md)
                .padding(.vertical, IgnitionSpacing.sm)
                .background(selectedFilter == filter ? themeManager.primaryColor : themeManager.cardColor)
                .cornerRadius(IgnitionRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.primaryColor)
            
            Text("Loading missions...")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(IgnitionSpacing.xl)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(IgnitionColors.mediumGray)
            
            VStack(spacing: IgnitionSpacing.sm) {
                Text("No Missions")
                    .font(IgnitionFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("New missions will be generated automatically")
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(IgnitionSpacing.xl)
    }
    
    // MARK: - Missions List Section
    private var missionsListSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("\(selectedFilter.rawValue) Missions")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: IgnitionSpacing.sm) {
                ForEach(filteredMissions, id: \.id) { mission in
                    MissionCardView(
                        mission: mission,
                        onTap: {
                            // Handle mission tap
                        },
                        onComplete: {
                            if mission.status == MissionStatus.inProgress {
                                missionManager.completeMission(mission)
                                audioHapticsManager.missionCompleted()
                            }
                        },
                        onToggleFavorite: {
                            // Handle favorite toggle
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredMissions: [IgnitionMissionModel] {
        switch selectedFilter {
        case .all:
            return missionManager.missions
        case .daily:
            return missionManager.missions.filter { $0.type == .daily }
        case .weekly:
            return missionManager.missions.filter { $0.type == .weekly }
        case .completed:
            return missionManager.completedMissions()
        }
    }
    
    private func missionCard(
        title: String,
        description: String,
        progress: Int,
        target: Int,
        reward: Int,
        type: MissionType
    ) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(title)
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(description)
                        .font(IgnitionFonts.callout)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                    Text("+\(reward)")
                        .font(IgnitionFonts.callout)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text(type.displayName)
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(typeColor(type))
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(typeColor(type).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text("Progress")
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(IgnitionColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(progress)/\(target)")
                        .font(IgnitionFonts.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                }
                
                ProgressView(value: Double(progress), total: Double(target))
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.primaryColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.md)
    }
    
    private func typeColor(_ type: MissionType) -> Color {
        switch type {
        case .daily: return .orange
        case .weekly: return .blue
        case .special: return .purple
        case .selfImposed: return .green
        case .adaptive: return .cyan
        case .streak: return .red
        case .achievement: return .yellow
        }
    }
}

// MARK: - Mission Card View
// MissionCardView moved to MissionsViewExpanded.swift to avoid duplication

/*
struct MissionCardView: View {
    let mission: IgnitionMissionModel
    @StateObject private var missionManager = MissionManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(mission.title)
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(mission.description)
                        .font(IgnitionFonts.callout)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                    Text("+\(mission.rewardPoints)")
                        .font(IgnitionFonts.callout)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text(mission.type.displayName)
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(typeColor(mission.type))
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(typeColor(mission.type).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                HStack {
                    Text("Progress")
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(IgnitionColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(mission.currentProgress)/\(mission.targetCount)")
                        .font(IgnitionFonts.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                }
                
                ProgressView(value: mission.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: mission.isCompleted ? IgnitionColors.success : themeManager.primaryColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            // Action Button (if completed but not claimed)
            if mission.isCompleted && mission.status != .completed {
                Button(action: {
                    audioHapticsManager.missionCompleted()
                    missionManager.completeMission(mission)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Riscuoti Ricompensa")
                    }
                    .font(IgnitionFonts.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(IgnitionColors.ignitionWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, IgnitionSpacing.sm)
                    .background(IgnitionColors.success)
                    .cornerRadius(IgnitionRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Completion Status
            if mission.status == .completed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(IgnitionColors.success)
                    
                    Text("Completata")
                        .font(IgnitionFonts.callout)
                        .fontWeight(.medium)
                        .foregroundColor(IgnitionColors.success)
                    
                    Spacer()
                    
                    if let completedAt = mission.completedAt {
                        Text(completedAt, style: .date)
                            .font(IgnitionFonts.caption1)
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: IgnitionRadius.md)
                .stroke(mission.isCompleted ? IgnitionColors.success : Color.clear, lineWidth: 2)
        )
    }
    
    private func typeColor(_ type: MissionType) -> Color {
        switch type {
        case .daily: return .orange
        case .weekly: return .blue
        case .special: return .purple
        case .selfImposed: return .green
        case .adaptive: return .cyan
        case .streak: return .red
        case .achievement: return .yellow
        }
    }
}
*/

// MARK: - Preview
#Preview {
    MissionsView()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
