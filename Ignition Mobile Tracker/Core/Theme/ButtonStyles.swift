//
//  ButtonStyles.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 02/10/25.
//

import SwiftUI

// MARK: - Fire Gradient Button Style
struct FireGradientButtonStyle: ButtonStyle {
    var isCompact: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 16, weight: .semibold) : .system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, isCompact ? 20 : 32)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                IgnitionGradients.fireGradient
            )
            .cornerRadius(isCompact ? 12 : 16)
            .shadow(color: IgnitionColors.ignitionOrange.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Gold Button Style
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(IgnitionColors.ignitionBlack)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(IgnitionColors.goldAccent)
            .cornerRadius(12)
            .shadow(color: IgnitionColors.goldAccent.opacity(0.5), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(IgnitionColors.ignitionOrange)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(IgnitionColors.ignitionOrange, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func fireGradientButton(isCompact: Bool = false) -> some View {
        self.buttonStyle(FireGradientButtonStyle(isCompact: isCompact))
    }
    
    func goldButton() -> some View {
        self.buttonStyle(GoldButtonStyle())
    }
    
    func ghostButton() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }
}

