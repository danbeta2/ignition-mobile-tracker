//
//  AddEntryView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import PhotosUI

struct AddEntryView: View {
    let table: TableModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libraryManager = LibraryManager.shared
    @StateObject private var photoManager = PhotoManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var audioHapticsManager: AudioHapticsManager
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: EntryType = .session
    @State private var duration: TimeInterval = 0
    @State private var value: Double = 0
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var customData: [String: String] = [:]
    @State private var selectedMood: Int?
    @State private var isImportant = false
    @State private var isCreating = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingDurationPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // MARK: - Basic Info
                    basicInfoView
                    
                    // MARK: - Type-Specific Fields
                    typeSpecificFieldsView
                    
                    // MARK: - Photos
                    photosView
                    
                    // MARK: - Tags
                    tagsView
                    
                    // MARK: - Custom Fields
                    customFieldsView
                }
                .padding(IgnitionSpacing.md)
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        audioHapticsManager.uiTapped()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createEntry()
                    }
                    .disabled(title.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(
                isPresented: $photoManager.isShowingPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            )
            .sheet(isPresented: $photoManager.isShowingCamera) {
                CameraPickerView(isPresented: $photoManager.isShowingCamera) { image in
                    Task {
                        await photoManager.processCameraPhoto(image)
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newValue in
                Task {
                    await photoManager.processSelectedPhotos(newValue)
                    selectedPhotos = []
                }
            }
        }
        .onAppear {
            setupCustomFields()
        }
        .onDisappear {
            photoManager.clearSelectedImages()
        }
    }
    
    // MARK: - Entry Type Selection
    
    private var entryTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Entry Type")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        EntryTypeChip(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                            audioHapticsManager.uiTapped()
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Entry Details")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.md) {
                // Entry Type
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Type")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    Menu {
                        ForEach(EntryType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedType = type
                                audioHapticsManager.uiTapped()
                            }) {
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.displayName)
                                    if selectedType == type {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(IgnitionColors.ignitionOrange)
                            Text(selectedType.displayName)
                                .foregroundColor(IgnitionColors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                .fill(IgnitionColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Title
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Title")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    TextField("Enter entry title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Content
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Description")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    TextField("What happened? How did it go?", text: $content, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...8)
                }
            }
        }
    }
    
    // MARK: - Type-Specific Fields
    
    private var typeSpecificFieldsView: some View {
        Group {
            if selectedType == .session {
                sessionFieldsView
            } else if selectedType == .milestone {
                milestoneFieldsView
            }
        }
    }
    
    private var sessionFieldsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Session Details")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.md) {
                // Duration
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Duration")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        showingDurationPicker = true
                    }) {
                        HStack {
                            Text(formatDuration(duration))
                                .foregroundColor(duration > 0 ? IgnitionColors.primaryText : IgnitionColors.secondaryText)
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundColor(IgnitionColors.ignitionOrange)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                .fill(IgnitionColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Value (optional numeric tracking)
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    HStack {
                        Text("Value")
                            .font(IgnitionFonts.body)
                            .fontWeight(.medium)
                        
                        Text("Optional")
                            .font(IgnitionFonts.caption2)
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        Spacer()
                    }
                    
                    TextField("Score, weight, reps, etc.", value: $value, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
        }
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerView(duration: $duration)
        }
    }
    
    private var milestoneFieldsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Milestone Details")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text("Achievement Value")
                    .font(IgnitionFonts.body)
                    .fontWeight(.medium)
                
                TextField("Points, level, milestone number", value: $value, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    // MARK: - Photos
    
    private var photosView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text("Photos")
                    .font(IgnitionFonts.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            // Photo Actions
            HStack(spacing: IgnitionSpacing.md) {
                Button(action: {
                    photoManager.selectPhotos()
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Gallery")
                    }
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.ignitionOrange)
                    .padding(.horizontal, IgnitionSpacing.md)
                    .padding(.vertical, IgnitionSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                            .fill(IgnitionColors.ignitionOrange.opacity(0.1))
                    )
                }
                
                Button(action: {
                    photoManager.takePhoto()
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Camera")
                    }
                    .font(IgnitionFonts.body)
                    .foregroundColor(IgnitionColors.ignitionOrange)
                    .padding(.horizontal, IgnitionSpacing.md)
                    .padding(.vertical, IgnitionSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                            .fill(IgnitionColors.ignitionOrange.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            
            // Selected Photos
            if !photoManager.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IgnitionSpacing.sm) {
                        ForEach(Array(photoManager.selectedImages.enumerated()), id: \.offset) { index, image in
                            PhotoPreview(image: image) {
                                photoManager.removeImage(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            if photoManager.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing images...")
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Tags
    
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                Text("Tags")
                    .font(IgnitionFonts.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(IgnitionFonts.caption2)
                    .foregroundColor(IgnitionColors.secondaryText)
            }
            
            // Add new tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(IgnitionColors.ignitionOrange)
                }
                .disabled(newTag.isEmpty)
            }
            
            // Current tags
            if !tags.isEmpty {
                FlowLayout(spacing: IgnitionSpacing.xs) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                        TagChip(tag: tag) {
                            removeTag(at: index)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Fields
    
    private var customFieldsView: some View {
        Group {
            if !table.customFields.isEmpty {
                VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
                    Text("Custom Fields")
                        .font(IgnitionFonts.title3)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: IgnitionSpacing.md) {
                        ForEach(Array(table.customFields.keys.sorted()), id: \.self) { fieldName in
                            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                                Text(fieldName)
                                    .font(IgnitionFonts.body)
                                    .fontWeight(.medium)
                                
                                TextField("Enter \(fieldName.lowercased())", text: Binding(
                                    get: { customData[fieldName] ?? "" },
                                    set: { customData[fieldName] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Mood & Priority
    
    private var moodAndPriorityView: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Additional Info")
                .font(IgnitionFonts.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: IgnitionSpacing.md) {
                // Mood
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Mood")
                        .font(IgnitionFonts.body)
                        .fontWeight(.medium)
                    
                    HStack(spacing: IgnitionSpacing.md) {
                        ForEach(1...5, id: \.self) { mood in
                            Button(action: {
                                selectedMood = selectedMood == mood ? nil : mood
                                audioHapticsManager.uiTapped()
                            }) {
                                Image(systemName: selectedMood == mood ? "face.smiling.fill" : "face.smiling")
                                    .font(.title2)
                                    .foregroundColor(selectedMood == mood ? moodColor(mood) : IgnitionColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        if let mood = selectedMood {
                            Text(moodText(mood))
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(moodColor(mood))
                        }
                    }
                }
                
                // Important toggle
                Toggle("Mark as Important", isOn: $isImportant)
                    .font(IgnitionFonts.body)
            }
        }
    }
    
    // MARK: - Actions
    
    private func setupCustomFields() {
        for fieldName in table.customFields.keys {
            customData[fieldName] = ""
        }
    }
    
    private func addTag() {
        guard !newTag.isEmpty, !tags.contains(newTag) else { return }
        tags.append(newTag)
        newTag = ""
        audioHapticsManager.uiTapped()
    }
    
    private func removeTag(at index: Int) {
        tags.remove(at: index)
        audioHapticsManager.uiTapped()
    }
    
    private func createEntry() {
        guard !title.isEmpty else { return }
        
        isCreating = true
        audioHapticsManager.uiTapped()
        
        Task {
            // Process photos
            var photoData: Data?
            if let firstImage = photoManager.selectedImages.first,
               let data = photoManager.imageToData(firstImage) {
                photoData = data
            }
            
            let newEntry = TableEntryModel(
                tableId: table.id,
                title: title,
                content: content,
                type: selectedType,
                duration: duration > 0 ? duration : nil,
                value: value > 0 ? value : nil,
                photoData: photoData,
                tags: tags,
                customData: customData,
                isImportant: isImportant,
                mood: selectedMood
            )
            
            await libraryManager.addEntry(newEntry)
            
            await MainActor.run {
                isCreating = false
                dismiss()
                audioHapticsManager.uiTapped()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "Select duration" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
}

// MARK: - Supporting Views

struct EntryTypeChip: View {
    let type: EntryType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.displayName)
                    .font(IgnitionFonts.caption2)
            }
            .foregroundColor(isSelected ? .white : IgnitionColors.ignitionOrange)
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.vertical, IgnitionSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                    .fill(isSelected ? IgnitionColors.ignitionOrange : IgnitionColors.ignitionOrange.opacity(0.1))
            )
        }
    }
}

struct PhotoPreview: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 8, y: -8)
        }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: IgnitionSpacing.xs) {
            Text(tag)
                .font(IgnitionFonts.caption2)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(IgnitionColors.primaryText)
        .padding(.horizontal, IgnitionSpacing.sm)
        .padding(.vertical, IgnitionSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                .fill(IgnitionColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionCornerRadius.sm)
                        .stroke(IgnitionColors.lightGray, lineWidth: 1)
                )
        )
    }
}

struct DurationPickerView: View {
    @Binding var duration: TimeInterval
    @Environment(\.dismiss) private var dismiss
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: IgnitionSpacing.lg) {
                Text("Select Duration")
                    .font(IgnitionFonts.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: IgnitionSpacing.lg) {
                    VStack {
                        Text("Hours")
                            .font(IgnitionFonts.body)
                            .fontWeight(.medium)
                        
                        Picker("Hours", selection: $hours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                    
                    VStack {
                        Text("Minutes")
                            .font(IgnitionFonts.body)
                            .fontWeight(.medium)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(Array(stride(from: 0, through: 59, by: 5)), id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                }
                
                Spacer()
            }
            .padding(IgnitionSpacing.md)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        duration = TimeInterval(hours * 3600 + minutes * 60)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            hours = Int(duration) / 3600
            minutes = (Int(duration) % 3600) / 60
        }
    }
}

// MARK: - FlowLayout for Tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width + spacing > maxWidth && currentRowWidth > 0 {
                totalHeight += maxRowHeight + spacing
                currentRowWidth = subviewSize.width
                maxRowHeight = subviewSize.height
            } else {
                if currentRowWidth > 0 {
                    currentRowWidth += spacing
                }
                currentRowWidth += subviewSize.width
                maxRowHeight = max(maxRowHeight, subviewSize.height)
            }
        }
        
        totalHeight += maxRowHeight
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        var currentX = bounds.minX
        var currentY = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                currentY += maxRowHeight + spacing
                currentX = bounds.minX
                maxRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            
            currentX += subviewSize.width + spacing
            maxRowHeight = max(maxRowHeight, subviewSize.height)
        }
    }
}

#Preview {
    AddEntryView(table: TableModel(
        title: "Poker Sessions",
        description: "Track poker games",
        category: .poker,
        customFields: ["Buy-in": "", "Cash-out": "", "Venue": ""]
    ))
    .environmentObject(ThemeManager.shared)
    .environmentObject(AudioHapticsManager.shared)
}
