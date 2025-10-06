//
//  AssetManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import UIKit
import Combine

@MainActor
class AssetManager: ObservableObject {
    static let shared = AssetManager()
    
    private var imageCache: [String: UIImage] = [:]
    
    private init() {
        preloadCriticalAssets()
    }
    
    // MARK: - Asset Loading
    
    func loadImage(named name: String) -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[name] {
            return cachedImage
        }
        
        // Load from bundle
        guard let image = UIImage(named: name) else {
            print("⚠️ Failed to load image: \(name)")
            return nil
        }
        
        // Optimize and cache
        let optimizedImage = optimizeImage(image)
        imageCache[name] = optimizedImage
        
        return optimizedImage
    }
    
    func loadImageAsView(named name: String, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        Group {
            if let image = loadImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
            } else {
                // Fallback to SF Symbol
                Image(systemName: "circle.fill")
                    .font(.system(size: min(size.width, size.height)))
                    .foregroundColor(IgnitionColors.secondaryText)
            }
        }
    }
    
    // MARK: - Category Icons
    
    func categoryIcon(for category: SparkCategory, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        let assetName = categoryAssetName(for: category)
        return loadImageAsView(named: assetName, size: size)
    }
    
    func categoryAssetName(for category: SparkCategory) -> String {
        switch category {
        case .decision: return "decisione-icon"
        case .energy: return "energia-icon"
        case .idea: return "idea-icon"
        case .experiment: return "esperimento-icon"
        case .challenge: return "sfida-icon"
        }
    }
    
    // MARK: - Tab Icons
    
    func tabIcon(for tab: TabRoute, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        let assetName = tabAssetName(for: tab)
        return loadImageAsView(named: assetName, size: size)
    }
    
    func tabAssetName(for tab: TabRoute) -> String {
        switch tab {
        case .home: return "home-tab"
        case .tracker: return "tracker-tab"
        case .library: return "books.vertical.fill" // Use SF Symbol for new tab
        case .missions: return "missions-tab"
        }
    }
    
    // MARK: - Mission Icons
    
    func missionIcon(for type: MissionType, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        let assetName = missionAssetName(for: type)
        return loadImageAsView(named: assetName, size: size)
    }
    
    func missionAssetName(for type: MissionType) -> String {
        switch type {
        case .daily: return "mission-daily"
        case .weekly: return "mission-weekly"
        case .special: return "mission-achievement"
        case .selfImposed: return "mission-achievement"
        case .adaptive: return "mission-achievement"
        case .streak: return "mission-achievement"
        case .achievement: return "mission-achievement"
        }
    }
    
    // MARK: - Intensity Icons
    
    func intensityIcon(for intensity: SparkIntensity, size: CGSize = CGSize(width: 20, height: 20)) -> some View {
        let assetName = intensityAssetName(for: intensity)
        return loadImageAsView(named: assetName, size: size)
    }
    
    func intensityAssetName(for intensity: SparkIntensity) -> String {
        switch intensity {
        case .low: return "intensity-low"
        case .medium: return "intensity-medium"
        case .high: return "intensity-high"
        case .extreme: return "intensity-extreme"
        }
    }
    
    // MARK: - General Icons
    
    func generalIcon(named name: String, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        return loadImageAsView(named: name, size: size)
    }
    
    // MARK: - Image Optimization
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        // Target size for optimization (max 256x256 for UI icons)
        let maxSize: CGFloat = 256
        let size = image.size
        
        // Skip optimization if already small enough
        guard size.width > maxSize || size.height > maxSize else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: size.height * maxSize / size.width)
        } else {
            newSize = CGSize(width: size.width * maxSize / size.height, height: maxSize)
        }
        
        // Create optimized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
    
    // MARK: - Preloading
    
    private func preloadCriticalAssets() {
        Task {
            // Preload tab icons
            for tab in TabRoute.allCases {
                if tab != .library { // Skip library as it uses SF Symbol
                    _ = loadImage(named: tabAssetName(for: tab))
                }
            }
            
            // Preload category icons
            for category in SparkCategory.allCases {
                _ = loadImage(named: categoryAssetName(for: category))
            }
            
            // Preload intensity icons
            for intensity in SparkIntensity.allCases {
                _ = loadImage(named: intensityAssetName(for: intensity))
            }
            
            // Preload mission icons
            for type in MissionType.allCases {
                _ = loadImage(named: missionAssetName(for: type))
            }
            
            print("✅ Critical assets preloaded")
        }
    }
    
    // MARK: - Memory Management
    
    func clearCache() {
        imageCache.removeAll()
        print("🧹 Asset cache cleared")
    }
    
    func getCacheInfo() -> (count: Int, estimatedSize: String) {
        let count = imageCache.count
        let estimatedBytes = imageCache.values.reduce(0) { total, image in
            return total + Int(image.size.width * image.size.height * 4) // RGBA
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        
        return (count: count, estimatedSize: formatter.string(fromByteCount: Int64(estimatedBytes)))
    }
}

// MARK: - SwiftUI Extensions

extension Image {
    static func asset(_ name: String) -> Image {
        if let uiImage = AssetManager.shared.loadImage(named: name) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "circle.fill")
        }
    }
    
    static func categoryIcon(_ category: SparkCategory) -> Image {
        let assetName = AssetManager.shared.categoryAssetName(for: category)
        return Image.asset(assetName)
    }
    
    static func tabIcon(_ tab: TabRoute) -> Image {
        if tab == .library {
            return Image(systemName: "books.vertical.fill")
        } else {
            let assetName = AssetManager.shared.tabAssetName(for: tab)
            return Image.asset(assetName)
        }
    }
    
    static func missionIcon(_ type: MissionType) -> Image {
        let assetName = AssetManager.shared.missionAssetName(for: type)
        return Image.asset(assetName)
    }
    
    static func intensityIcon(_ intensity: SparkIntensity) -> Image {
        let assetName = AssetManager.shared.intensityAssetName(for: intensity)
        return Image.asset(assetName)
    }
}

// MARK: - View Modifiers

struct OptimizedAssetModifier: ViewModifier {
    let assetName: String
    let size: CGSize
    
    func body(content: Content) -> some View {
        content
            .overlay(
                AssetManager.shared.loadImageAsView(named: assetName, size: size)
            )
    }
}

extension View {
    func optimizedAsset(_ name: String, size: CGSize = CGSize(width: 24, height: 24)) -> some View {
        modifier(OptimizedAssetModifier(assetName: name, size: size))
    }
}

// MARK: - Asset Validation

struct AssetValidator {
    static func validateAssets() -> [String] {
        var missingAssets: [String] = []
        
        // Check tab icons
        for tab in TabRoute.allCases {
            if tab != .library {
                let assetName = AssetManager.shared.tabAssetName(for: tab)
                if UIImage(named: assetName) == nil {
                    missingAssets.append(assetName)
                }
            }
        }
        
        // Check category icons
        for category in SparkCategory.allCases {
            let assetName = AssetManager.shared.categoryAssetName(for: category)
            if UIImage(named: assetName) == nil {
                missingAssets.append(assetName)
            }
        }
        
        // Check intensity icons
        for intensity in SparkIntensity.allCases {
            let assetName = AssetManager.shared.intensityAssetName(for: intensity)
            if UIImage(named: assetName) == nil {
                missingAssets.append(assetName)
            }
        }
        
        // Check mission icons
        for type in MissionType.allCases {
            let assetName = AssetManager.shared.missionAssetName(for: type)
            if UIImage(named: assetName) == nil {
                missingAssets.append(assetName)
            }
        }
        
        return missingAssets
    }
}
