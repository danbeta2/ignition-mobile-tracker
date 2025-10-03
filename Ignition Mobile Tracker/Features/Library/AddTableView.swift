//
//  AddTableView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct AddTableView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libraryManager = LibraryManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var audioHapticsManager: AudioHapticsManager
    
    @State private var selectedTemplate: TableTemplate?
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TableCategory = .personal
    @State private var targetGoal = ""
    @State private var customFields: [String] = []
    @State private var newFieldName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // MARK: - Template Selection
                    templateSelectionView
                    
                    // MARK: - Basic Info
                    basicInfoView
                    
                    // MARK: - Custom Fields
                    customFieldsView
                    
                    // MARK: - Goal Setting
                    goalSettingView
                }
                .padding(IgnitionSpacing.md)
            }
            .navigationTitle("Create Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        audioHapticsManager.uiTapped()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTable()
                    }
                    .disabled(title.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Template Selection
    
    private var templateSelectionView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Choose a Template")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            Text("Select a pre-made template or create a custom table")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: IgnitionSpacing.sm),
                GridItem(.flexible(), spacing: IgnitionSpacing.sm)
            ], spacing: IgnitionSpacing.sm) {
                ForEach(TableTemplate.templates, id: \.category) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate?.category == template.category
                    ) {
                        selectTemplate(template)
                    }
                }
                
                // Custom template option
                CustomTemplateCard(
                    isSelected: selectedTemplate == nil
                ) {
                    selectedTemplate = nil
                    title = ""
                    description = ""
                    selectedCategory = .personal
                    targetGoal = ""
                    customFields = []
                    audioHapticsManager.uiTapped()
                }
            }
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Table Details")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.md) {
                // Title
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Title")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    TextField("Enter table name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Description")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    TextField("What will you track in this table?", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Category
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Category")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: IgnitionSpacing.sm) {
                            ForEach(TableCategory.allCases, id: \.self) { category in
                                CategorySelectionChip(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                    audioHapticsManager.uiTapped()
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Fields
    
    private var customFieldsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text("Custom Fields")
                    .font(IgnitionFonts.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            Text("Add custom fields to track specific data for each entry")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
            
            // Add new field
            HStack {
                TextField("Field name (e.g., Weight, Score, Duration)", text: $newFieldName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addCustomField) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(IgnitionColors.ignitionOrange)
                }
                .disabled(newFieldName.isEmpty)
            }
            
            // Existing fields
            if !customFields.isEmpty {
                VStack(spacing: IgnitionSpacing.xs) {
                    ForEach(Array(customFields.enumerated()), id: \.offset) { index, field in
                        HStack {
                            Text(field)
                                .font(IgnitionFonts.body)
                            
                            Spacer()
                            
                            Button(action: {
                                removeCustomField(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, IgnitionSpacing.sm)
                        .padding(.vertical, IgnitionSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                .fill(IgnitionColors.cardBackground)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Goal Setting
    
    private var goalSettingView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text("Goal")
                    .font(IgnitionFonts.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            Text("Set a goal or intention for this table")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
            
            TextField("What do you want to achieve?", text: $targetGoal, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(2...4)
        }
    }
    
    // MARK: - Actions
    
    private func selectTemplate(_ template: TableTemplate) {
        selectedTemplate = template
        title = template.title
        description = template.description
        selectedCategory = template.category
        targetGoal = template.defaultGoal ?? ""
        customFields = template.suggestedFields
        audioHapticsManager.uiTapped()
    }
    
    private func addCustomField() {
        guard !newFieldName.isEmpty else { return }
        
        customFields.append(newFieldName)
        newFieldName = ""
        audioHapticsManager.uiTapped()
    }
    
    private func removeCustomField(at index: Int) {
        customFields.remove(at: index)
        audioHapticsManager.uiTapped()
    }
    
    private func createTable() {
        guard !title.isEmpty else { return }
        
        isCreating = true
        audioHapticsManager.uiTapped()
        
        Task {
            let customFieldsDict = Dictionary(uniqueKeysWithValues: customFields.map { ($0, "") })
            
            let newTable = TableModel(
                title: title,
                description: description,
                category: selectedCategory,
                customFields: customFieldsDict,
                targetGoal: targetGoal.isEmpty ? nil : targetGoal
            )
            
            await libraryManager.createTable(newTable)
            
            await MainActor.run {
                isCreating = false
                dismiss()
                audioHapticsManager.uiTapped()
            }
        }
    }
}

// MARK: - Supporting Views

struct TemplateCard: View {
    let template: TableTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
                HStack {
                    Image(systemName: template.category.icon)
                        .font(.title2)
                        .foregroundColor(template.category.color)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(IgnitionColors.ignitionOrange)
                    }
                }
                
                Text(template.title)
                    .font(IgnitionFonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(IgnitionColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(template.description)
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(IgnitionSpacing.md)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                    .fill(IgnitionColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                            .stroke(
                                isSelected ? IgnitionColors.ignitionOrange : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: IgnitionColors.lightGray.opacity(0.2), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomTemplateCard: View {
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: IgnitionSpacing.md) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 40))
                    .foregroundColor(IgnitionColors.ignitionOrange)
                
                VStack(spacing: IgnitionSpacing.xs) {
                    Text("Custom Table")
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(IgnitionColors.primaryText)
                    
                    Text("Create from scratch")
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(IgnitionColors.ignitionOrange)
                } else {
                    Spacer()
                }
            }
            .padding(IgnitionSpacing.md)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                    .fill(IgnitionColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.md)
                            .stroke(
                                isSelected ? IgnitionColors.ignitionOrange : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: IgnitionColors.lightGray.opacity(0.2), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySelectionChip: View {
    let category: TableCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(IgnitionFonts.caption2)
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.vertical, IgnitionSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
        }
    }
}

#Preview {
    AddTableView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AudioHapticsManager.shared)
}
