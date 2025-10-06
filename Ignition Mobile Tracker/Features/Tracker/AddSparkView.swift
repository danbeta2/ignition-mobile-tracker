//
//  AddSparkView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI

struct AddSparkView: View {
    let sparkToEdit: SparkModel? // Added for edit mode
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedCategory: SparkCategory = .idea
    @State private var selectedIntensity: SparkIntensity = .medium
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var estimatedTime: Int?
    @State private var showingTimePicker = false
    
    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var tagFocused: Bool
    
    init(sparkToEdit: SparkModel? = nil) {
        self.sparkToEdit = sparkToEdit
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Category Selection
                    categorySelectionSection
                    
                    // Title Input
                    titleInputSection
                    
                    // Notes Input
                    notesInputSection
                    
                    // Intensity Selection
                    intensitySelectionSection
                    
                    // Time Estimation
                    timeEstimationSection
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(IgnitionSpacing.md)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(sparkToEdit == nil ? "New Spark" : "Edit Spark")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSparkData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(IgnitionColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSpark()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? themeManager.primaryColor : IgnitionColors.mediumGray)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    // MARK: - Category Selection Section
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Category")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: IgnitionSpacing.sm) {
                ForEach(SparkCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }
    
    private func categoryCard(_ category: SparkCategory) -> some View {
        Button(action: {
            selectedCategory = category
            audioHapticsManager.uiTapped()
        }) {
            VStack(spacing: IgnitionSpacing.sm) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(selectedCategory == category ? IgnitionColors.ignitionWhite : themeManager.primaryColor)
                
                Text(category.displayName)
                    .font(IgnitionFonts.callout)
                    .fontWeight(.medium)
                    .foregroundColor(selectedCategory == category ? IgnitionColors.ignitionWhite : themeManager.textColor)
                
                Text("+\(category.points) pts")
                    .font(IgnitionFonts.caption1)
                    .foregroundColor(selectedCategory == category ? IgnitionColors.ignitionWhite.opacity(0.8) : IgnitionColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selectedCategory == category ? themeManager.primaryColor : themeManager.cardColor)
            .cornerRadius(IgnitionRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: IgnitionRadius.md)
                    .stroke(selectedCategory == category ? themeManager.primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Title Input Section
    private var titleInputSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Title")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            TextField("Describe your spark...", text: $title)
                .font(IgnitionFonts.body)
                .foregroundColor(themeManager.textColor)
                .padding(IgnitionSpacing.md)
                .background(themeManager.cardColor)
                .cornerRadius(IgnitionRadius.sm)
                .focused($titleFocused)
        }
    }
    
    // MARK: - Notes Input Section
    private var notesInputSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Notes (optional)")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            TextField("Add details...", text: $notes, axis: .vertical)
                .font(IgnitionFonts.body)
                .foregroundColor(themeManager.textColor)
                .padding(IgnitionSpacing.md)
                .background(themeManager.cardColor)
                .cornerRadius(IgnitionRadius.sm)
                .lineLimit(3...6)
                .focused($notesFocused)
        }
    }
    
    // MARK: - Intensity Selection Section
    private var intensitySelectionSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Intensity")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: IgnitionSpacing.sm) {
                ForEach(SparkIntensity.allCases, id: \.self) { intensity in
                    intensityRow(intensity)
                }
            }
        }
    }
    
    private func intensityRow(_ intensity: SparkIntensity) -> some View {
        Button(action: {
            selectedIntensity = intensity
            audioHapticsManager.uiTapped()
        }) {
            HStack(spacing: IgnitionSpacing.md) {
                // Intensity Indicator
                HStack(spacing: 2) {
                    ForEach(1...4, id: \.self) { level in
                        Circle()
                            .fill(level <= intensity.rawValue ? themeManager.primaryColor : IgnitionColors.mediumGray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(intensity.displayName)
                    .font(IgnitionFonts.body)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("×\(String(format: "%.1f", intensity.multiplier))")
                    .font(IgnitionFonts.callout)
                    .foregroundColor(IgnitionColors.secondaryText)
                
                Image(systemName: selectedIntensity == intensity ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedIntensity == intensity ? themeManager.primaryColor : IgnitionColors.mediumGray)
            }
            .padding(IgnitionSpacing.md)
            .background(selectedIntensity == intensity ? themeManager.primaryColor.opacity(0.1) : themeManager.cardColor)
            .cornerRadius(IgnitionRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Tag")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            // Tag Input
            HStack {
                TextField("Aggiungi tag...", text: $newTag)
                    .font(IgnitionFonts.body)
                    .foregroundColor(themeManager.textColor)
                    .focused($tagFocused)
                    .onSubmit {
                        addTag()
                    }
                
                Button("Aggiungi") {
                    addTag()
                }
                .font(IgnitionFonts.callout)
                .foregroundColor(newTag.isEmpty ? IgnitionColors.mediumGray : themeManager.primaryColor)
                .disabled(newTag.isEmpty)
            }
            .padding(IgnitionSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(IgnitionRadius.sm)
            
            // Tags Display
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IgnitionSpacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            tagChip(tag)
                        }
                    }
                    .padding(.horizontal, IgnitionSpacing.xs)
                }
            }
        }
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: IgnitionSpacing.xs) {
            Text("#\(tag)")
                .font(IgnitionFonts.caption1)
                .foregroundColor(themeManager.textColor)
            
            Button(action: {
                removeTag(tag)
            }) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(IgnitionColors.mediumGray)
            }
        }
        .padding(.horizontal, IgnitionSpacing.sm)
        .padding(.vertical, IgnitionSpacing.xs)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.sm)
    }
    
    // MARK: - Time Estimation Section
    private var timeEstimationSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            Text("Estimated Time (optional)")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            Button(action: {
                showingTimePicker = true
            }) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text(estimatedTime != nil ? "\(estimatedTime!) minutes" : "Select time")
                        .font(IgnitionFonts.body)
                        .foregroundColor(estimatedTime != nil ? themeManager.textColor : IgnitionColors.secondaryText)
                    
                    Spacer()
                    
                    if estimatedTime != nil {
                        Button(action: {
                            estimatedTime = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(IgnitionColors.mediumGray)
                        }
                    }
                }
                .padding(IgnitionSpacing.md)
                .background(themeManager.cardColor)
                .cornerRadius(IgnitionRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: $estimatedTime)
        }
    }
    
    // MARK: - Computed Properties
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
            audioHapticsManager.uiTapped()
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        AudioHapticsManager.shared.uiTapped()
    }
    
    private func loadSparkData() {
        guard let spark = sparkToEdit else { return }
        
        title = spark.title
        notes = spark.notes ?? ""
        selectedCategory = spark.category
        selectedIntensity = spark.intensity
        tags = spark.tags
        estimatedTime = spark.estimatedTime
    }
    
    private func saveSpark() {
        if let sparkToEdit = sparkToEdit {
            // Edit mode - update existing spark
            var updatedSpark = sparkToEdit
            updatedSpark.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedSpark.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedSpark.category = selectedCategory
            updatedSpark.intensity = selectedIntensity
            updatedSpark.tags = tags
            updatedSpark.estimatedTime = estimatedTime
            updatedSpark.updatedAt = Date()
            
            sparkManager.updateSpark(updatedSpark)
        } else {
            // Add mode - create new spark
            let spark = SparkModel(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                intensity: selectedIntensity,
                tags: tags,
                estimatedTime: estimatedTime
            )
            
            sparkManager.addSpark(spark)
        }
        
        dismiss()
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Binding var selectedTime: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    @State private var hours = 0
    @State private var minutes = 15
    
    var body: some View {
        NavigationView {
            VStack(spacing: IgnitionSpacing.lg) {
                Text("Select Estimated Time")
                    .font(IgnitionFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                HStack(spacing: IgnitionSpacing.lg) {
                    // Hours Picker
                    VStack {
                        Text("Ore")
                            .font(IgnitionFonts.callout)
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        Picker("Ore", selection: $hours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                    }
                    
                    // Minutes Picker
                    VStack {
                        Text("Minuti")
                            .font(IgnitionFonts.callout)
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        Picker("Minuti", selection: $minutes) {
                            ForEach([5, 10, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                    }
                }
                
                Text("Totale: \(totalMinutes) minuti")
                    .font(IgnitionFonts.body)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
            }
            .padding(IgnitionSpacing.lg)
            .background(themeManager.backgroundColor)
            .navigationTitle("Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(IgnitionColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        selectedTime = totalMinutes
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
    }
    
    private var totalMinutes: Int {
        return hours * 60 + minutes
    }
}

// MARK: - Preview
#Preview {
    AddSparkView()
        .environment(\.themeManager, ThemeManager.shared)
}
