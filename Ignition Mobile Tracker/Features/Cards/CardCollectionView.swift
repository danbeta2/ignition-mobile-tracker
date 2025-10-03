//
//  CardCollectionView.swift
//  Ignition Mobile Tracker
//
//  Complete card collection view with advanced features
//

import SwiftUI

struct CardCollectionView: View {
    @StateObject private var cardManager = CardManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var selectedCategory: SparkCategory? = nil
    @State private var showOnlyOwned = false
    @State private var selectedCard: SparkCardModel? = nil
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: IgnitionSpacing.sm),
        GridItem(.flexible(), spacing: IgnitionSpacing.sm),
        GridItem(.flexible(), spacing: IgnitionSpacing.sm)
    ]
    
    var filteredCards: [SparkCardModel] {
        var cards = cardManager.allCards
        
        // Apply filters
        if showOnlyOwned {
            cards = cards.filter { $0.isOwned }
        }
        
        if let category = selectedCategory {
            cards = cards.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                card.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by rarity (descending) and then by name
        cards.sort { (card1, card2) in
            if card1.rarity == card2.rarity {
                return card1.name < card2.name
            }
            return card1.rarity > card2.rarity
        }
        
        return cards
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: IgnitionSpacing.lg) {
                        // Stats header
                        statsHeader
                        
                        // Search bar
                        searchBar
                        
                        // Category filters
                        categoryFilters
                        
                        // Cards display
                        if filteredCards.isEmpty {
                            emptyStateView
                        } else {
                            cardsSection
                        }
                    }
                    .padding(.vertical, IgnitionSpacing.md)
                }
            }
            .navigationTitle("Card Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                        audioHapticsManager.uiTapped()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(IgnitionColors.mediumGray)
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Main progress
            VStack(spacing: IgnitionSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                        Text("\(cardManager.ownedCardsCount) / 50")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .goldGlow(radius: 6)
                        
                        Text("Cards Collected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(IgnitionColors.darkGray, lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: cardManager.completionPercentage)
                            .stroke(
                                AngularGradient(
                                    colors: [IgnitionColors.ignitionOrange, IgnitionColors.goldAccent, IgnitionColors.ignitionOrange],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: cardManager.completionPercentage)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(cardManager.completionPercentage * 100))")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(IgnitionColors.darkGray)
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [IgnitionColors.ignitionOrange, IgnitionColors.goldAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * cardManager.completionPercentage, height: 12)
                            .animation(.easeInOut(duration: 0.5), value: cardManager.completionPercentage)
                    }
                }
                .frame(height: 12)
            }
            
            Divider()
                .background(IgnitionColors.mediumGray.opacity(0.3))
            
            // Rarity breakdown (display only)
            HStack(spacing: IgnitionSpacing.md) {
                ForEach(CardRarity.allCases, id: \.self) { rarity in
                    let (owned, total) = cardManager.getRarityCompletion(rarity)
                    
                    VStack(spacing: IgnitionSpacing.xs) {
                        ZStack {
                            Circle()
                                .fill(rarity.color.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .fill(rarity.color)
                                .frame(width: 36, height: 36)
                            
                            if cardManager.isRarityComplete(rarity) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("\(owned)/\(total)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(rarity.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(IgnitionColors.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                .fill(themeManager.cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [IgnitionColors.goldAccent.opacity(0.3), IgnitionColors.ignitionOrange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: IgnitionShadow.large, radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: IgnitionSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(IgnitionColors.mediumGray)
            
            TextField("Search cards...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    audioHapticsManager.playSelectionHaptic()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(IgnitionColors.mediumGray)
                }
            }
        }
        .padding(IgnitionSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: IgnitionRadius.md)
                .fill(themeManager.cardColor)
        )
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    // MARK: - Category Filters
    
    private var categoryFilters: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    // All categories button
                    Button(action: {
                        selectedCategory = nil
                        showOnlyOwned = false
                        audioHapticsManager.playSelectionHaptic()
                    }) {
                        HStack(spacing: IgnitionSpacing.xs) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 12))
                                .foregroundColor(selectedCategory == nil ? .white : IgnitionColors.secondaryText)
                            
                            Text("All")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedCategory == nil ? .white : IgnitionColors.secondaryText)
                        }
                        .padding(.horizontal, IgnitionSpacing.md)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == nil ? IgnitionColors.ignitionOrange : IgnitionColors.darkGray)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        let (owned, total) = cardManager.getCategoryCompletion(category)
                        
                        Button(action: {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                            showOnlyOwned = false
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            HStack(spacing: IgnitionSpacing.xs) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedCategory == category ? .white : category.color)
                                
                                Text("\(owned)/\(total)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedCategory == category ? .white : IgnitionColors.secondaryText)
                                
                                if cardManager.isCategoryComplete(category) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(IgnitionColors.goldAccent)
                                }
                            }
                            .padding(.horizontal, IgnitionSpacing.md)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? category.color : IgnitionColors.darkGray)
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedCategory == category ? .clear : category.color.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Owned filter
                    Button(action: {
                        showOnlyOwned.toggle()
                        audioHapticsManager.playSelectionHaptic()
                    }) {
                        HStack(spacing: IgnitionSpacing.xs) {
                            Image(systemName: showOnlyOwned ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(showOnlyOwned ? IgnitionColors.goldAccent : IgnitionColors.secondaryText)
                            
                            Text("Owned Only")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(showOnlyOwned ? .white : IgnitionColors.secondaryText)
                        }
                        .padding(.horizontal, IgnitionSpacing.md)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(showOnlyOwned ? IgnitionColors.goldAccent.opacity(0.3) : IgnitionColors.darkGray)
                                .overlay(
                                    Capsule()
                                        .stroke(showOnlyOwned ? IgnitionColors.goldAccent : .clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
    }
    
    // MARK: - Cards Section
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            // Result count
            HStack {
                Text("\(filteredCards.count) card\(filteredCards.count != 1 ? "s" : "")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IgnitionColors.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, IgnitionSpacing.md)
            
            // Cards grid
            LazyVGrid(columns: gridColumns, spacing: IgnitionSpacing.md) {
                ForEach(filteredCards, id: \.id) { card in
                    cardGridItem(card)
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
        }
    }
    
    // MARK: - Card Grid Item
    
    private func cardGridItem(_ card: SparkCardModel) -> some View {
        Button(action: {
            if card.isOwned {
                selectedCard = card
                audioHapticsManager.uiTapped()
            }
        }) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: IgnitionRadius.md)
                    .fill(card.isOwned ? IgnitionColors.ignitionBlack : IgnitionColors.darkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.md)
                            .stroke(card.isOwned ? card.rarity.color : IgnitionColors.mediumGray.opacity(0.3), lineWidth: card.isOwned ? 2 : 1)
                    )
                
                if card.isOwned {
                    // Card image or icon
                    if let _ = UIImage(named: card.assetName) {
                        Image(card.assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 150)
                            .clipped()
                            .cornerRadius(IgnitionRadius.md)
                    } else {
                        VStack(spacing: IgnitionSpacing.xs) {
                            Image(systemName: card.category.iconName)
                                .font(.system(size: 36))
                                .foregroundColor(card.category.color)
                            
                            Text(card.displayTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    // Rarity indicator (top-right)
                    VStack {
                        HStack {
                            Spacer()
                            
                            Circle()
                                .fill(card.rarity.color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: rarityIcon(card.rarity))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .padding(6)
                        }
                        
                        Spacer()
                    }
                    
                    // Duplicate count (bottom-left)
                    if card.ownedCount > 1 {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Text("×\(card.ownedCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(IgnitionColors.goldAccent.opacity(0.9))
                                    )
                                    .padding(6)
                                
                                Spacer()
                            }
                        }
                    }
                } else {
                    // Locked card
                    VStack(spacing: IgnitionSpacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(IgnitionColors.mediumGray.opacity(0.5))
                        
                        Text("???")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(IgnitionColors.mediumGray.opacity(0.5))
                    }
                }
            }
            .frame(width: 110, height: 150)
            .shadow(color: card.isOwned ? card.rarity.glowColor : .clear, radius: 6, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(IgnitionColors.mediumGray)
            
            Text("No Cards Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Try adjusting your filters or\ncreate more sparks to collect cards!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(IgnitionColors.secondaryText)
                .multilineTextAlignment(.center)
            
            if selectedCategory != nil || showOnlyOwned {
                Button(action: {
                    selectedCategory = nil
                    showOnlyOwned = false
                    audioHapticsManager.uiTapped()
                }) {
                    Text("Clear Filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, IgnitionSpacing.lg)
                        .padding(.vertical, IgnitionSpacing.sm)
                        .background(
                            Capsule()
                                .fill(IgnitionColors.ignitionOrange)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(IgnitionSpacing.xl)
    }
    
    // MARK: - Helper Functions
    
    private func rarityIcon(_ rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "c.circle.fill"
        case .rare: return "r.circle.fill"
        case .epic: return "e.circle.fill"
        case .legendary: return "l.circle.fill"
        }
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: SparkCardModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.xl) {
                    // Large card display
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(IgnitionColors.ignitionBlack)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [card.rarity.color, card.rarity.color.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                        
                        if let _ = UIImage(named: card.assetName) {
                            Image(card.assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 390)
                                .clipped()
                                .cornerRadius(24)
                        } else {
                            VStack(spacing: IgnitionSpacing.md) {
                                Image(systemName: card.category.iconName)
                                    .font(.system(size: 120))
                                    .foregroundColor(card.category.color)
                                
                                Text(card.displayTitle)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Rarity badge (top-right corner)
                        VStack {
                            HStack {
                                Spacer()
                                
                                Circle()
                                    .fill(card.rarity.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: rarityIcon(card.rarity))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .padding(IgnitionSpacing.md)
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(width: 280, height: 390)
                    .shadow(color: card.rarity.glowColor, radius: 30, x: 0, y: 0)
                    
                    // Card info
                    VStack(spacing: IgnitionSpacing.lg) {
                        // Name
                        Text(card.displayTitle)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Rarity badge
                        HStack(spacing: IgnitionSpacing.xs) {
                            Circle()
                                .fill(card.rarity.color)
                                .frame(width: 12, height: 12)
                            
                            Text(card.rarity.displayName.uppercased())
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(card.rarity.color)
                                .tracking(1.5)
                        }
                        .padding(.horizontal, IgnitionSpacing.lg)
                        .padding(.vertical, IgnitionSpacing.sm)
                        .background(
                            Capsule()
                                .fill(card.rarity.color.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(card.rarity.color.opacity(0.6), lineWidth: 2)
                                )
                        )
                        
                        // Category
                        HStack(spacing: IgnitionSpacing.sm) {
                            Image(systemName: card.category.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(card.category.color)
                            
                            Text(card.category.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Divider()
                            .background(IgnitionColors.mediumGray.opacity(0.3))
                            .padding(.vertical, IgnitionSpacing.sm)
                        
                        // Stats
                        VStack(spacing: IgnitionSpacing.md) {
                            statRow(label: "Owned", value: "×\(card.ownedCount)", color: IgnitionColors.goldAccent)
                            
                            if let obtainedAt = card.obtainedAt {
                                statRow(
                                    label: "First Obtained",
                                    value: obtainedAt.formatted(date: .abbreviated, time: .omitted),
                                    color: .white
                                )
                                
                                statRow(
                                    label: "Time Ago",
                                    value: obtainedAt.formatted(.relative(presentation: .named)),
                                    color: IgnitionColors.secondaryText
                                )
                            }
                            
                            if card.ownedCount > 1 {
                                statRow(
                                    label: "Duplicate Value",
                                    value: "+\(card.rarity.duplicatePoints * (card.ownedCount - 1)) pts",
                                    color: IgnitionColors.goldAccent
                                )
                            }
                        }
                    }
                    .padding(.horizontal, IgnitionSpacing.xl)
                }
                .padding(.vertical, IgnitionSpacing.xl)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(IgnitionColors.ignitionOrange)
                }
            }
        }
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(IgnitionColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, IgnitionSpacing.md)
    }
    
    private func rarityIcon(_ rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "c.circle.fill"
        case .rare: return "r.circle.fill"
        case .epic: return "e.circle.fill"
        case .legendary: return "l.circle.fill"
        }
    }
}
