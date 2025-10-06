//
//  HeroBanner.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 02/10/25.
//

import SwiftUI

struct HeroBanner: View {
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    
    var onAction: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image (asset che creerai)
            if let _ = UIImage(named: "hero-banner") {
                Image("hero-banner")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else {
                // Fallback gradient se l'immagine non c'è ancora
                Rectangle()
                    .fill(IgnitionGradients.fireGradientVertical)
                    .frame(height: 200)
            }
            
            // Dark overlay for text readability
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: 200)
            
            // Content
            VStack(spacing: IgnitionSpacing.md) {
                // Points Display
                VStack(spacing: IgnitionSpacing.xs) {
                    Text("\(userProfileManager.userProfile?.totalSparkPoints ?? 0)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .goldGlow(radius: 8)
                    
                    Text("Total Points")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(IgnitionColors.goldAccent)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                
                // CTA Button
                Button(action: {
                    audioHapticsManager.uiTapped()
                    onAction()
                }) {
                    HStack(spacing: IgnitionSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add Spark")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .fireGradientButton(isCompact: true)
            }
            .padding(IgnitionSpacing.md)
        }
        .frame(height: 200)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: IgnitionShadow.glow, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Preview
#Preview {
    HeroBanner(onAction: {
        print("Hero action tapped")
    })
    .padding()
    .background(IgnitionColors.primaryBackground)
}

