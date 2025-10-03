//
//  AssetNames.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import Foundation

// MARK: - Asset Names Enum
enum AssetNames {
    
    // MARK: - Tab Icons
    enum TabIcons: String, CaseIterable {
        case home = "home-tab"
        case tracker = "tracker-tab" 
        case missions = "missions-tab"
        case stats = "stats-tab"
        
        var systemName: String {
            switch self {
            case .home: return "house.fill"
            case .tracker: return "book.fill"
            case .missions: return "target"
            case .stats: return "chart.bar.fill"
            }
        }
    }
    
    // MARK: - System Icons
    enum SystemIcons: String, CaseIterable {
        // Custom Assets (with background)
        case sparkIcon = "spark-icon"
        case fuelGauge = "fuel-gauge"
        case addButton = "add-button"
        case overloadIcon = "overload-icon"
        case streakIcon = "streak-icon"
        case pointsIcon = "points-icon"
        case profileIcon = "profile-icon"
        case calendarIcon = "calendar-icon"
        case tagIcon = "tag-icon"
        
        // SF Symbols (no custom assets needed)
        case filterIcon = "line.3.horizontal.decrease.circle"
        case sortIcon = "arrow.up.arrow.down"
        case searchIcon = "magnifyingglass"
        case settingsIcon = "gearshape.fill"
        case notificationIcon = "bell.fill"
        case exportIcon = "square.and.arrow.up"
        case clockIcon = "clock.fill"
        case locationIcon = "location.fill"
        case noteIcon = "note.text"
        case editIcon = "pencil"
        case deleteIcon = "trash.fill"
        case shareIcon = "square.and.arrow.up.fill"
        case favoriteIcon = "heart.fill"
        case bookmarkIcon = "bookmark.fill"
        case refreshIcon = "arrow.clockwise"
        case closeIcon = "xmark"
        case checkIcon = "checkmark"
        case warningIcon = "exclamationmark.triangle.fill"
        case infoIcon = "info.circle.fill"
        case successIcon = "checkmark.circle.fill"
        case errorIcon = "xmark.circle.fill"
        
        var systemName: String {
            switch self {
            // Custom Assets - return fallback SF Symbol for compatibility
            case .sparkIcon: return "sparkles"
            case .fuelGauge: return "gauge"
            case .addButton: return "plus.circle.fill"
            case .overloadIcon: return "bolt.fill"
            case .streakIcon: return "flame"
            case .pointsIcon: return "star.fill"
            case .profileIcon: return "person.circle.fill"
            case .calendarIcon: return "calendar"
            case .tagIcon: return "tag.fill"
            
            // SF Symbols - return the symbol name directly
            case .filterIcon, .sortIcon, .searchIcon, .settingsIcon, .notificationIcon, 
                 .exportIcon, .clockIcon, .locationIcon, .noteIcon, .editIcon, 
                 .deleteIcon, .shareIcon, .favoriteIcon, .bookmarkIcon, .refreshIcon, 
                 .closeIcon, .checkIcon, .warningIcon, .infoIcon, .successIcon, .errorIcon:
                return self.rawValue
            }
        }
        
        var isCustomAsset: Bool {
            switch self {
            case .sparkIcon, .fuelGauge, .addButton, .overloadIcon, .streakIcon, 
                 .pointsIcon, .profileIcon, .calendarIcon, .tagIcon:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Backgrounds
    enum Backgrounds: String, CaseIterable {
        case mainGradient = "main-gradient"
        
        var systemName: String {
            return "rectangle.fill"
        }
    }
    
    // MARK: - Audio
    enum Audio: String, CaseIterable {
        case sparkAdd = "spark-add"
        case uiTap = "ui-tap"
        case overloadTrigger = "overload-trigger"
    }
    
    // MARK: - Spark Categories
    enum SparkCategories: String, CaseIterable {
        case decision = "decisione-icon"  // Keep existing asset name
        case energy = "energia-icon"      // Keep existing asset name
        case idea = "idea-icon"
        case experiment = "esperimento-icon" // Keep existing asset name
        case challenge = "sfida-icon"     // Keep existing asset name
        case reflection = "riflessione-icon"
        
        var systemName: String {
            switch self {
            case .decision: return "checkmark.circle.fill"
            case .energy: return "bolt.fill"
            case .idea: return "lightbulb.fill"
            case .experiment: return "flask.fill"
            case .challenge: return "target"
            case .reflection: return "brain.head.profile"
            }
        }
        
        var displayName: String {
            switch self {
            case .decision: return "Decision"
            case .energy: return "Energy"
            case .idea: return "Idea"
            case .experiment: return "Experiment"
            case .challenge: return "Challenge"
            case .reflection: return "Reflection"
            }
        }
        
        var assetName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Intensity Levels
    enum IntensityIcons: String, CaseIterable {
        case low = "intensity-low"
        case medium = "intensity-medium"
        case high = "intensity-high"
        case extreme = "intensity-extreme"
        
        var systemName: String {
            switch self {
            case .low: return "circle"
            case .medium: return "circle.lefthalf.filled"
            case .high: return "circle.fill"
            case .extreme: return "flame.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .low: return "Bassa"
            case .medium: return "Media"
            case .high: return "Alta"
            case .extreme: return "Estrema"
            }
        }
    }
    
    // MARK: - Mission Types
    enum MissionIcons: String, CaseIterable {
        case daily = "mission-daily"
        case weekly = "mission-weekly"
        case achievement = "mission-achievement"
        
        var systemName: String {
            switch self {
            case .daily: return "sun.max.fill"
            case .weekly: return "calendar.badge.clock"
            case .achievement: return "trophy.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .daily: return "Giornaliera"
            case .weekly: return "Settimanale"
            case .achievement: return "Obiettivo"
            }
        }
    }
    
    // MARK: - Charts & Analytics (All SF Symbols)
    enum ChartIcons: String, CaseIterable {
        case lineChart = "chart.line.uptrend.xyaxis"
        case barChart = "chart.bar.fill"
        case pieChart = "chart.pie.fill"
        case trendUp = "arrow.up.right"
        case trendDown = "arrow.down.right"
        case analytics = "chart.xyaxis.line"
        
        var systemName: String {
            return self.rawValue
        }
    }
}

// MARK: - Asset Helper Extension
extension AssetNames {
    static func image(_ name: String) -> String {
        return name
    }
    
    static func sound(_ name: String) -> String {
        return name
    }
}

// MARK: - SwiftUI Image Helper
import SwiftUI

extension Image {
    init(assetIcon: AssetNames.SystemIcons) {
        if assetIcon.isCustomAsset {
            // Use custom asset from bundle
            self.init(assetIcon.rawValue)
        } else {
            // Use SF Symbol
            self.init(systemName: assetIcon.systemName)
        }
    }
    
    init(tabIcon: AssetNames.TabIcons) {
        // Tab icons are always custom assets
        self.init(tabIcon.rawValue)
    }
    
    init(sparkCategory: AssetNames.SparkCategories) {
        // Spark categories are always custom assets
        self.init(sparkCategory.rawValue)
    }
    
    init(intensityIcon: AssetNames.IntensityIcons) {
        // Intensity icons are always custom assets
        self.init(intensityIcon.rawValue)
    }
    
    init(missionIcon: AssetNames.MissionIcons) {
        // Mission icons are always custom assets
        self.init(missionIcon.rawValue)
    }
    
    init(chartIcon: AssetNames.ChartIcons) {
        // Chart icons are always SF Symbols
        self.init(systemName: chartIcon.systemName)
    }
}
