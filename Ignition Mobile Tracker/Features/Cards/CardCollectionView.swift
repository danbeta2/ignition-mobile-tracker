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
    @State private var selectedRarity: CardRarity? = nil
    @State private var showOnlyOwned = false
    @State private var selectedCard: SparkCardModel? = nil
    @State private var sortOption: CardSortOption = .rarity
    @State private var searchText = ""
    @State private var viewMode: CollectionViewMode = .grid
    @State private var showingAchievements = false
    @State private var showingStats = false
    
    // MARK: - Computed Properties
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: IgnitionSpacing.sm),
        GridItem(.flexible(), spacing: IgnitionSpacing.sm),
        GridItem(.flexible(), spacing: IgnitionSpacing.sm)
    ]
    
    private let listColumns = [
        GridItem(.flexible(), spacing: IgnitionSpacing.md)
    ]
    
    var filteredAndSortedCards: [SparkCardModel] {
        var cards = cardManager.allCards
        
        // Apply filters
        if showOnlyOwned {
            cards = cards.filter { $0.isOwned }
        }
        
        if let category = selectedCategory {
            cards = cards.filter { $0.category == category }
        }
        
        if let rarity = selectedRarity {
            cards = cards.filter { $0.rarity == rarity }
        }
        
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                card.category.displayName.localizedCaseInsensitiveContains(searchText) ||
                card.rarity.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .rarity:
            cards.sort { (card1, card2) in
                if card1.rarity == card2.rarity {
                    return card1.name < card2.name
                }
                return card1.rarity > card2.rarity
            }
        case .name:
            cards.sort { $0.displayTitle < $1.displayTitle }
        case .category:
            cards.sort { (card1, card2) in
                if card1.category == card2.category {
                    return card1.rarity > card2.rarity
                }
                return card1.category.displayName < card2.category.displayName
            }
        case .obtained:
            cards.sort { (card1, card2) in
                // Owned cards first, then by obtain date (most recent first)
                if card1.isOwned == card2.isOwned {
                    if let date1 = card1.obtainedAt, let date2 = card2.obtainedAt {
                        return date1 > date2
                    }
                    return card1.isOwned
                }
                return card1.isOwned && !card2.isOwned
            }
        case .duplicates:
            cards.sort { $0.ownedCount > $1.ownedCount }
        }
        
        return cards
    }
    
    var achievementsUnlocked: [String] {
        return cardManager.checkAchievements()
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
                        
                        // Filters and controls
                        filtersSection
                        
                        // Achievements banner (if any unlocked)
                        if !achievementsUnlocked.isEmpty {
                            achievementsBanner
                        }
                        
                        // Cards display
                        if filteredAndSortedCards.isEmpty {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingStats = true
                        audioHapticsManager.uiTapped()
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(IgnitionColors.ignitionOrange)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: IgnitionSpacing.sm) {
                        Button(action: {
                            showingAchievements = true
                            audioHapticsManager.uiTapped()
                        }) {
                            ZStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(IgnitionColors.goldAccent)
                                
                                if !achievementsUnlocked.isEmpty {
                                    Circle()
                                        .fill(IgnitionColors.fireRed)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
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
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
            .sheet(isPresented: $showingAchievements) {
                CardAchievementsView(achievements: achievementsUnlocked)
            }
            .sheet(isPresented: $showingStats) {
                CollectionStatsView()
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
            
            // Rarity breakdown
            HStack(spacing: IgnitionSpacing.md) {
                ForEach(CardRarity.allCases, id: \.self) { rarity in
                    let (owned, total) = cardManager.getRarityCompletion(rarity)
                    
                    Button(action: {
                        if selectedRarity == rarity {
                            selectedRarity = nil
                        } else {
                            selectedRarity = rarity
                        }
                        audioHapticsManager.playSelectionHaptic()
                    }) {
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
                                .foregroundColor(selectedRarity == rarity ? rarity.color : .white)
                            
                            Text(rarity.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(IgnitionColors.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Category breakdown (compact)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.sm) {
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        let (owned, total) = cardManager.getCategoryCompletion(category)
                        
                        categoryProgressChip(category: category, owned: owned, total: total)
                    }
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
    
    private func categoryProgressChip(category: SparkCategory, owned: Int, total: Int) -> some View {
        Button(action: {
            if selectedCategory == category {
                selectedCategory = nil
            } else {
                selectedCategory = category
            }
            audioHapticsManager.playSelectionHaptic()
        }) {
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(category.color)
                
                Text("\(owned)/\(total)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                if cardManager.isCategoryComplete(category) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(IgnitionColors.goldAccent)
                }
            }
            .padding(.horizontal, IgnitionSpacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedCategory == category ? category.color.opacity(0.3) : IgnitionColors.darkGray)
                    .overlay(
                        Capsule()
                            .stroke(selectedCategory == category ? category.color : .clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Top row: View mode, Sort, Owned toggle
            HStack(spacing: IgnitionSpacing.sm) {
                // View mode toggle
                Picker("View Mode", selection: $viewMode) {
                    Image(systemName: "square.grid.3x3.fill").tag(CollectionViewMode.grid)
                    Image(systemName: "list.bullet").tag(CollectionViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                
                Spacer()
                
                // Sort menu
                Menu {
                    ForEach(CardSortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                            audioHapticsManager.playSelectionHaptic()
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
                    HStack(spacing: IgnitionSpacing.xs) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.displayName)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, IgnitionSpacing.md)
                    .padding(.vertical, IgnitionSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: IgnitionRadius.md)
                            .fill(themeManager.cardColor)
                    )
                }
                
                // Owned toggle
                Toggle(isOn: $showOnlyOwned) {
                    Text("Owned")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: IgnitionColors.ignitionOrange))
                .fixedSize()
            }
            .padding(.horizontal, IgnitionSpacing.md)
            
            // Active filters display
            if selectedCategory != nil || selectedRarity != nil || showOnlyOwned {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: IgnitionSpacing.xs) {
                        Text("Filters:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(IgnitionColors.secondaryText)
                        
                        if let category = selectedCategory {
                            filterTag(text: category.displayName, color: category.color) {
                                selectedCategory = nil
                            }
                        }
                        
                        if let rarity = selectedRarity {
                            filterTag(text: rarity.displayName, color: rarity.color) {
                                selectedRarity = nil
                            }
                        }
                        
                        if showOnlyOwned {
                            filterTag(text: "Owned Only", color: IgnitionColors.ignitionOrange) {
                                showOnlyOwned = false
                            }
                        }
                        
                        Button(action: {
                            selectedCategory = nil
                            selectedRarity = nil
                            showOnlyOwned = false
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Text("Clear All")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(IgnitionColors.fireRed)
                                .padding(.horizontal, IgnitionSpacing.xs)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, IgnitionSpacing.md)
                }
            }
        }
    }
    
    private func filterTag(text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            
            Button(action: {
                onRemove()
                audioHapticsManager.playSelectionHaptic()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, IgnitionSpacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(color, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Achievements Banner
    
    private var achievementsBanner: some View {
        Button(action: {
            showingAchievements = true
            audioHapticsManager.uiTapped()
        }) {
            HStack(spacing: IgnitionSpacing.sm) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundColor(IgnitionColors.goldAccent)
                    .goldGlow(radius: 8)
                
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("🎉 Achievement Unlocked!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(achievementsUnlocked.count) new achievement\(achievementsUnlocked.count > 1 ? "s" : "")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(IgnitionColors.goldAccent)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(IgnitionColors.mediumGray)
            }
            .padding(IgnitionSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [IgnitionColors.goldAccent.opacity(0.2), IgnitionColors.ignitionOrange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                            .stroke(IgnitionColors.goldAccent.opacity(0.5), lineWidth: 2)
                    )
            )
            .padding(.horizontal, IgnitionSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Cards Section
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
            // Result count
            HStack {
                Text("\(filteredAndSortedCards.count) card\(filteredAndSortedCards.count != 1 ? "s" : "")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IgnitionColors.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, IgnitionSpacing.md)
            
            // Cards grid/list
            LazyVGrid(columns: viewMode == .grid ? gridColumns : listColumns, spacing: IgnitionSpacing.md) {
                ForEach(filteredAndSortedCards, id: \.id) { card in
                    if viewMode == .grid {
                        cardGridItem(card)
                    } else {
                        cardListItem(card)
                    }
                }
            }
            .padding(.horizontal, IgnitionSpacing.md)
            .animation(.easeInOut(duration: 0.3), value: viewMode)
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
    
    // MARK: - Card List Item
    
    private func cardListItem(_ card: SparkCardModel) -> some View {
        Button(action: {
            if card.isOwned {
                selectedCard = card
                audioHapticsManager.uiTapped()
            }
        }) {
            HStack(spacing: IgnitionSpacing.md) {
                // Card thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                        .fill(card.isOwned ? IgnitionColors.ignitionBlack : IgnitionColors.darkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                                .stroke(card.isOwned ? card.rarity.color : IgnitionColors.mediumGray.opacity(0.3), lineWidth: card.isOwned ? 2 : 1)
                        )
                    
                    if card.isOwned {
                        if let _ = UIImage(named: card.assetName) {
                            Image(card.assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 84)
                                .clipped()
                                .cornerRadius(IgnitionRadius.sm)
                        } else {
                            Image(systemName: card.category.iconName)
                                .font(.system(size: 30))
                                .foregroundColor(card.category.color)
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(IgnitionColors.mediumGray.opacity(0.5))
                    }
                }
                .frame(width: 60, height: 84)
                .shadow(color: card.isOwned ? card.rarity.glowColor.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                
                // Card info
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(card.isOwned ? card.displayTitle : "???")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: IgnitionSpacing.xs) {
                        // Rarity badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(card.rarity.color)
                                .frame(width: 8, height: 8)
                            
                            Text(card.rarity.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(card.rarity.color)
                        }
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(card.rarity.color.opacity(0.2))
                        )
                        
                        // Category
                        HStack(spacing: 4) {
                            Image(systemName: card.category.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(card.category.color)
                            
                            Text(card.category.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                    
                    if card.isOwned {
                        HStack(spacing: IgnitionSpacing.sm) {
                            if card.ownedCount > 1 {
                                Text("×\(card.ownedCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(IgnitionColors.goldAccent)
                            }
                            
                            if let obtainedAt = card.obtainedAt {
                                Text("Obtained \(obtainedAt, style: .relative)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(IgnitionColors.secondaryText)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if card.isOwned {
                    Image(systemName: "chevron.right")
                        .foregroundColor(IgnitionColors.mediumGray)
                }
            }
            .padding(IgnitionSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.md)
                    .fill(themeManager.cardColor)
            )
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
            
            if selectedCategory != nil || selectedRarity != nil || showOnlyOwned {
                Button(action: {
                    selectedCategory = nil
                    selectedRarity = nil
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

// MARK: - Supporting Types

enum CollectionViewMode {
    case grid
    case list
}

enum CardSortOption: CaseIterable {
    case rarity
    case name
    case category
    case obtained
    case duplicates
    
    var displayName: String {
        switch self {
        case .rarity: return "Rarity"
        case .name: return "Name"
        case .category: return "Category"
        case .obtained: return "Obtained"
        case .duplicates: return "Duplicates"
        }
    }
}

// MARK: - Card Achievements View

struct CardAchievementsView: View {
    let achievements: [String]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    ForEach(achievements, id: \.self) { achievement in
                        HStack(spacing: IgnitionSpacing.md) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 40))
                                .foregroundColor(IgnitionColors.goldAccent)
                                .goldGlow(radius: 10)
                            
                            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                                Text(achievement)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Achievement Unlocked!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(IgnitionColors.goldAccent)
                            }
                            
                            Spacer()
                        }
                        .padding(IgnitionSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                                .fill(
                                    LinearGradient(
                                        colors: [IgnitionColors.goldAccent.opacity(0.2), IgnitionColors.ignitionOrange.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                                        .stroke(IgnitionColors.goldAccent.opacity(0.5), lineWidth: 2)
                                )
                        )
                    }
                }
                .padding(IgnitionSpacing.md)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
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
}

// MARK: - Collection Stats View

struct CollectionStatsView: View {
    @StateObject private var cardManager = CardManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Overall stats
                    statsCard(
                        title: "Collection Overview",
                        stats: [
                            ("Total Cards", "50"),
                            ("Owned", "\(cardManager.ownedCardsCount)"),
                            ("Completion", "\(Int(cardManager.completionPercentage * 100))%"),
                            ("Missing", "\(50 - cardManager.ownedCardsCount)")
                        ]
                    )
                    
                    // Rarity stats
                    statsCard(
                        title: "By Rarity",
                        stats: CardRarity.allCases.map { rarity in
                            let (owned, total) = cardManager.getRarityCompletion(rarity)
                            return (rarity.displayName, "\(owned)/\(total)")
                        }
                    )
                    
                    // Category stats
                    statsCard(
                        title: "By Category",
                        stats: SparkCategory.allCases.map { category in
                            let (owned, total) = cardManager.getCategoryCompletion(category)
                            return (category.displayName, "\(owned)/\(total)")
                        }
                    )
                    
                    // Duplicates stats
                    if !cardManager.ownedCards.isEmpty {
                        let totalDuplicates = cardManager.ownedCards.reduce(0) { $0 + ($1.ownedCount - 1) }
                        let mostDuplicates = cardManager.ownedCards.max(by: { $0.ownedCount < $1.ownedCount })
                        
                        statsCard(
                            title: "Duplicates",
                            stats: [
                                ("Total Duplicates", "\(totalDuplicates)"),
                                ("Most Duplicated", mostDuplicates?.displayTitle ?? "N/A"),
                                ("Duplicate Count", "×\(mostDuplicates?.ownedCount ?? 0)")
                            ]
                        )
                    }
                }
                .padding(IgnitionSpacing.md)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Collection Stats")
            .navigationBarTitleDisplayMode(.large)
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
    
    private func statsCard(title: String, stats: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Divider()
                .background(IgnitionColors.mediumGray.opacity(0.3))
            
            ForEach(stats, id: \.0) { stat in
                HStack {
                    Text(stat.0)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(IgnitionColors.secondaryText)
                    
                    Spacer()
                    
                    Text(stat.1)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                .fill(themeManager.cardColor)
        )
    }
}

// MARK: - Card Detail View (Enhanced)

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
