//
//  EntryDetailView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI

struct EntryDetailView: View {
    let entry: TableEntryModel
    let table: TableModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IgnitionSpacing.lg) {
                // Header
                headerView
                
                // Content
                if !entry.content.isEmpty {
                    contentView
                }
                
                // Photo
                if let photoData = entry.photoData,
                   let uiImage = UIImage(data: photoData) {
                    photoView(uiImage)
                }
                
                // Details
                detailsView
                
                // Tags
                if !entry.tags.isEmpty {
                    tagsView
                }
                
                // Custom Data
                if !entry.customData.isEmpty {
                    customDataView
                }
            }
            .padding(IgnitionSpacing.md)
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: entry.type.icon)
                .font(.title)
                .foregroundColor(typeColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(typeColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type.displayName)
                    .font(IgnitionFonts.body)
                    .foregroundColor(typeColor)
                    .fontWeight(.medium)
                
                Text(entry.createdAt, style: .date)
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
                
                if entry.isImportant {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Important")
                            .font(IgnitionFonts.caption2)
                    }
                    .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            if let mood = entry.mood {
                VStack {
                    Image(systemName: "face.smiling.fill")
                        .font(.title2)
                        .foregroundColor(moodColor(mood))
                    
                    Text(moodText(mood))
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(moodColor(mood))
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Description")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            Text(entry.content)
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.primaryText)
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
    }
    
    private func photoView(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Photo")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: IgnitionCornerRadius.md))
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Details")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.sm) {
                if let duration = entry.duration, duration > 0 {
                    DetailRow(
                        title: "Duration",
                        value: formatDuration(duration),
                        icon: "clock"
                    )
                }
                
                if let value = entry.value, value > 0 {
                    DetailRow(
                        title: "Value",
                        value: String(format: "%.1f", value),
                        icon: "number"
                    )
                }
                
                DetailRow(
                    title: "Created",
                    value: entry.createdAt.formatted(date: .abbreviated, time: .shortened),
                    icon: "calendar"
                )
                
                if entry.updatedAt != entry.createdAt {
                    DetailRow(
                        title: "Updated",
                        value: entry.updatedAt.formatted(date: .abbreviated, time: .shortened),
                        icon: "clock.arrow.circlepath"
                    )
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
    }
    
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Tags")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            FlowLayout(spacing: IgnitionSpacing.xs) {
                ForEach(entry.tags, id: \.self) { tag in
                    Text(tag)
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(IgnitionColors.primaryText)
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                .fill(IgnitionColors.ignitionOrange.opacity(0.1))
                        )
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
    }
    
    private var customDataView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Custom Fields")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.sm) {
                ForEach(Array(entry.customData.keys.sorted()), id: \.self) { key in
                    if let value = entry.customData[key], !value.isEmpty {
                        DetailRow(
                            title: key,
                            value: value,
                            icon: "textformat"
                        )
                    }
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                .fill(IgnitionColors.cardBackground)
        )
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
    
    private func moodText(_ mood: Int) -> String {
        switch mood {
        case 1: return "Terrible"
        case 2: return "Bad"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return ""
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

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(IgnitionColors.ignitionOrange)
                .frame(width: 20)
            
            Text(title)
                .font(IgnitionFonts.body)
                .fontWeight(.medium)
                .foregroundColor(IgnitionColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
        }
    }
}

#Preview {
    EntryDetailView(
        entry: TableEntryModel(
            tableId: UUID(),
            title: "Great Session",
            content: "Had an amazing poker session today. Played tight-aggressive and managed to win big.",
            type: .session,
            duration: 7200, // 2 hours
            value: 150.0,
            tags: ["poker", "tournament", "win"],
            customData: ["Buy-in": "$50", "Cash-out": "$200", "Venue": "Local Casino"],
            isImportant: true,
            mood: 5
        ),
        table: TableModel(
            title: "Poker Sessions",
            category: .poker
        )
    )
    .environmentObject(ThemeManager.shared)
}
