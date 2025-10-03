//
//  CardManager.swift
//  Ignition Mobile Tracker
//
//  Manages the Spark Cards collection system
//

import Foundation
import SwiftUI
import Combine

class CardManager: ObservableObject {
    static let shared = CardManager()
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Published Properties
    @Published var allCards: [SparkCardModel] = []
    @Published var ownedCards: [SparkCardModel] = []
    @Published var isLoading: Bool = false
    @Published var lastObtainedCard: SparkCardModel?
    @Published var showCardReveal: Bool = false
    
    // MARK: - Computed Properties
    var totalCardsCount: Int {
        return 50 // Fixed: 10 cards per 5 categories
    }
    
    var ownedCardsCount: Int {
        return ownedCards.count
    }
    
    var completionPercentage: Double {
        return Double(ownedCardsCount) / Double(totalCardsCount)
    }
    
    var rarestOwnedCards: [SparkCardModel] {
        return ownedCards
            .sorted { $0.rarity > $1.rarity }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Initialization
    private init() {
        loadAllCards()
    }
    
    // MARK: - Card Initialization
    
    /// Initializes all 50 spark cards in Core Data (only on first launch)
    func initializeCardCollection() {
        // Check if cards already exist
        let existingCards = persistenceController.fetchAllSparkCards()
        
        if !existingCards.isEmpty {
            print("📦 Spark cards already initialized (\(existingCards.count) cards)")
            return
        }
        
        print("📦 Initializing 50 Spark Cards...")
        
        // Define all 50 cards (10 per category)
        let cardDefinitions: [(name: String, category: SparkCategory, rarity: CardRarity)] = [
            // DECISION (10 cards: 5 common, 3 rare, 1 epic, 1 legendary)
            ("balance", .decision, .common),
            ("choice", .decision, .common),
            ("compass", .decision, .common),
            ("crossroads", .decision, .common),
            ("pathfinder", .decision, .common),
            ("chessmaster", .decision, .rare),
            ("oracle", .decision, .rare),
            ("timeline", .decision, .rare),
            ("mindpalace", .decision, .epic),
            ("destinyweaver", .decision, .legendary),
            
            // ENERGY (10 cards: 5 common, 3 rare, 1 epic, 1 legendary)
            ("bolt", .energy, .common),
            ("flame", .energy, .common),
            ("pulse", .energy, .common),
            ("spark", .energy, .common),
            ("surge", .energy, .common),
            ("blaze", .energy, .rare),
            ("inferno", .energy, .rare),
            ("thunder", .energy, .rare),
            ("phoenix", .energy, .epic),
            ("supernova", .energy, .legendary),
            
            // IDEA (10 cards: 5 common, 3 rare, 1 epic, 1 legendary)
            ("blueprint", .idea, .common),
            ("brain", .idea, .common),
            ("gear", .idea, .common),
            ("lightbulb", .idea, .common),
            ("sketch", .idea, .common),
            ("eureka", .idea, .rare),
            ("innovation", .idea, .rare),
            ("vision", .idea, .rare),
            ("architect", .idea, .epic),
            ("prometheus", .idea, .legendary),
            
            // EXPERIMENT (10 cards: 5 common, 3 rare, 1 epic, 1 legendary)
            ("beaker", .experiment, .common),
            ("flask", .experiment, .common),
            ("labcoat", .experiment, .common),
            ("microscope", .experiment, .common),
            ("testtube", .experiment, .common),
            ("catalyst", .experiment, .rare),
            ("formula", .experiment, .rare),
            ("mutation", .experiment, .rare),
            ("alchemist", .experiment, .epic),
            ("madscientist", .experiment, .legendary),
            
            // CHALLENGE (10 cards: 5 common, 3 rare, 1 epic, 1 legendary)
            ("gauntlet", .challenge, .common),
            ("mountain", .challenge, .common),
            ("shield", .challenge, .common),
            ("sword", .challenge, .common),
            ("target", .challenge, .common),
            ("arena", .challenge, .rare),
            ("champion", .challenge, .rare),
            ("dragon", .challenge, .rare),
            ("titan", .challenge, .epic),
            ("immortal", .challenge, .legendary)
        ]
        
        // Create all cards in Core Data
        for card in cardDefinitions {
            _ = persistenceController.createSparkCard(
                name: card.name,
                category: card.category,
                rarity: card.rarity
            )
        }
        
        print("✅ Initialized 50 Spark Cards successfully!")
        
        // Reload cards
        loadAllCards()
    }
    
    // MARK: - Card Loading
    
    func loadAllCards() {
        isLoading = true
        
        allCards = persistenceController.fetchAllSparkCards()
        ownedCards = allCards.filter { $0.isOwned }
        
        isLoading = false
        
        print("📦 Loaded \(allCards.count) total cards, \(ownedCards.count) owned")
    }
    
    // MARK: - Card Drop Logic
    
    /// Triggers a card drop for a specific spark category
    /// Returns the obtained card (if any) and bonus points for duplicates
    func triggerCardDrop(for category: SparkCategory) -> (card: SparkCardModel?, bonusPoints: Int, isNew: Bool) {
        // Get all cards for this category
        let categoryCards = allCards.filter { $0.category == category }
        
        guard !categoryCards.isEmpty else {
            print("⚠️ No cards found for category: \(category.rawValue)")
            return (nil, 0, false)
        }
        
        // Determine rarity based on drop rates
        let selectedRarity = determineCardRarity()
        
        // Filter cards by rarity
        let eligibleCards = categoryCards.filter { $0.rarity == selectedRarity }
        
        guard !eligibleCards.isEmpty else {
            print("⚠️ No cards found for rarity: \(selectedRarity.rawValue)")
            return (nil, 0, false)
        }
        
        // Randomly select a card from eligible cards
        guard let selectedCard = eligibleCards.randomElement() else {
            return (nil, 0, false)
        }
        
        // Obtain the card (handles both new and duplicate)
        let result = persistenceController.obtainSparkCard(cardId: selectedCard.id)
        
        // Reload cards
        loadAllCards()
        
        // Get the updated card
        if let updatedCard = allCards.first(where: { $0.id == selectedCard.id }) {
            lastObtainedCard = updatedCard
            
            print("🎴 Card obtained: \(updatedCard.displayTitle) (\(updatedCard.rarity.displayName))")
            if !result.isNew {
                print("   Duplicate! +\(result.duplicatePoints) bonus points")
            }
            
            return (updatedCard, result.duplicatePoints, result.isNew)
        }
        
        return (nil, 0, false)
    }
    
    /// Determines the rarity of the card to drop based on weighted probabilities
    private func determineCardRarity() -> CardRarity {
        let roll = Double.random(in: 0...1)
        
        // Cumulative probability distribution
        // Common: 0.00 - 0.60 (60%)
        // Rare:   0.60 - 0.90 (30%)
        // Epic:   0.90 - 0.98 (8%)
        // Legendary: 0.98 - 1.00 (2%)
        
        if roll < 0.60 {
            return .common
        } else if roll < 0.90 {
            return .rare
        } else if roll < 0.98 {
            return .epic
        } else {
            return .legendary
        }
    }
    
    // MARK: - Card Filtering
    
    func getCards(byCategory category: SparkCategory) -> [SparkCardModel] {
        return allCards.filter { $0.category == category }
    }
    
    func getCards(byRarity rarity: CardRarity) -> [SparkCardModel] {
        return allCards.filter { $0.rarity == rarity }
    }
    
    func getOwnedCards(byCategory category: SparkCategory) -> [SparkCardModel] {
        return ownedCards.filter { $0.category == category }
    }
    
    func getOwnedCards(byRarity rarity: CardRarity) -> [SparkCardModel] {
        return ownedCards.filter { $0.rarity == rarity }
    }
    
    // MARK: - Collection Stats
    
    func getCategoryCompletion(_ category: SparkCategory) -> (owned: Int, total: Int) {
        let categoryCards = allCards.filter { $0.category == category }
        let ownedCategoryCards = categoryCards.filter { $0.isOwned }
        return (ownedCategoryCards.count, categoryCards.count)
    }
    
    func getRarityCompletion(_ rarity: CardRarity) -> (owned: Int, total: Int) {
        let rarityCards = allCards.filter { $0.rarity == rarity }
        let ownedRarityCards = rarityCards.filter { $0.isOwned }
        return (ownedRarityCards.count, rarityCards.count)
    }
    
    func isCollectionComplete() -> Bool {
        return ownedCardsCount == totalCardsCount
    }
    
    func isCategoryComplete(_ category: SparkCategory) -> Bool {
        let completion = getCategoryCompletion(category)
        return completion.owned == completion.total
    }
    
    func isRarityComplete(_ rarity: CardRarity) -> Bool {
        let completion = getRarityCompletion(rarity)
        return completion.owned == completion.total
    }
    
    // MARK: - Achievement Checks
    
    func checkAchievements() -> [String] {
        var unlockedAchievements: [String] = []
        
        // Check category completions
        for category in SparkCategory.allCases {
            if isCategoryComplete(category) {
                unlockedAchievements.append("Master of \(category.displayName)")
            }
        }
        
        // Check rarity completions
        if isRarityComplete(.legendary) {
            unlockedAchievements.append("Legendary Collector")
        }
        
        // Check full collection
        if isCollectionComplete() {
            unlockedAchievements.append("Completionist")
        }
        
        return unlockedAchievements
    }
}

