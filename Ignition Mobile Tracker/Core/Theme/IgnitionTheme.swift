//
//  IgnitionTheme.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI

// MARK: - Ignition Color Palette
struct IgnitionColors {
    // Primary Colors - Casino Theme
    static let ignitionOrange = Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35 - Main brand
    static let fireRed = Color(red: 1.0, green: 0.27, blue: 0.27) // #FF4444 - Intense accents
    static let goldAccent = Color(red: 1.0, green: 0.72, blue: 0.0) // #FFB800 - Rewards/highlights
    static let ignitionBlack = Color(red: 0.10, green: 0.10, blue: 0.10) // #1A1A1A - Deeper black
    static let ignitionWhite = Color.white
    
    // Secondary Colors
    static let darkGray = Color(red: 0.16, green: 0.16, blue: 0.16) // #2A2A2A - Cards
    static let headerGray = Color(red: 0.23, green: 0.23, blue: 0.23) // #3A3A3A - Header (lighter than black)
    static let mediumGray = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
    static let lightGray = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    
    // Background Colors
    static let primaryBackground = ignitionBlack
    static let secondaryBackground = darkGray
    static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.14) // #242424 - Slightly lighter
    
    // Text Colors
    static let primaryText = ignitionWhite
    static let secondaryText = lightGray
    static let accentText = ignitionOrange
    
    // System Colors
    static let success = Color.green
    static let warning = goldAccent // Changed to gold
    static let error = fireRed // Changed to fire red
    
    // Gradient Colors
    static let gradientStart = ignitionOrange
    static let gradientEnd = fireRed
}

// MARK: - Typography
struct IgnitionFonts {
    // Headlines
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Body Text
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    // Small Text
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Spacing
struct IgnitionSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct IgnitionRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Corner Radius (Alternative naming for compatibility)
struct IgnitionCornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Shadow
struct IgnitionShadow {
    static let small = Color.black.opacity(0.1)
    static let medium = Color.black.opacity(0.2)
    static let large = Color.black.opacity(0.3)
    static let glow = Color.black.opacity(0.5) // For card elevation
}

// MARK: - Gradients
struct IgnitionGradients {
    // Fire Gradient (Orange to Red)
    static let fireGradient = LinearGradient(
        colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Vertical Fire Gradient
    static let fireGradientVertical = LinearGradient(
        colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Gold Shimmer
    static let goldShimmer = LinearGradient(
        colors: [
            IgnitionColors.goldAccent.opacity(0.6),
            IgnitionColors.goldAccent,
            IgnitionColors.goldAccent.opacity(0.6)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Card Overlay
    static let cardOverlay = LinearGradient(
        colors: [
            IgnitionColors.cardBackground,
            IgnitionColors.cardBackground.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Glow Effects
extension View {
    func fireGlow(radius: CGFloat = 8, color: Color = IgnitionColors.ignitionOrange) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 1.5, x: 0, y: 0)
    }
    
    func goldGlow(radius: CGFloat = 6) -> some View {
        self
            .shadow(color: IgnitionColors.goldAccent.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: IgnitionColors.goldAccent.opacity(0.3), radius: radius * 1.5, x: 0, y: 0)
    }
}
