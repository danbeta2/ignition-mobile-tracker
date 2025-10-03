//
//  CardRevealView.swift
//  Ignition Mobile Tracker
//
//  Card Reveal animation with Flame Burst effect
//

import SwiftUI

struct CardRevealView: View {
    let card: SparkCardModel
    @Binding var isPresented: Bool
    @Environment(\.themeManager) private var themeManager
    
    @State private var showFlames = false
    @State private var showCard = false
    @State private var cardScale: CGFloat = 0.1
    @State private var cardRotation: Double = 180
    @State private var glowIntensity: Double = 0
    @State private var showDetails = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: IgnitionSpacing.xl) {
                Spacer()
                
                // Card reveal area
                ZStack {
                    // Flame burst effect
                    if showFlames {
                        FlamesBurstView()
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Card back (flipping to front)
                    if !showCard {
                        cardBackView
                            .rotation3DEffect(
                                .degrees(cardRotation),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    }
                    
                    // Card front
                    if showCard {
                        cardFrontView
                            .scaleEffect(cardScale)
                            .rotation3DEffect(
                                .degrees(cardRotation),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .shadow(color: card.rarity.glowColor, radius: glowIntensity, x: 0, y: 0)
                    }
                }
                .frame(height: 400)
                
                // Card details (appear after reveal)
                if showDetails {
                    VStack(spacing: IgnitionSpacing.md) {
                        // Rarity badge
                        HStack(spacing: IgnitionSpacing.xs) {
                            Circle()
                                .fill(card.rarity.color)
                                .frame(width: 12, height: 12)
                            
                            Text(card.rarity.displayName.uppercased())
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(card.rarity.color)
                                .tracking(1)
                        }
                        .padding(.horizontal, IgnitionSpacing.md)
                        .padding(.vertical, IgnitionSpacing.sm)
                        .background(
                            Capsule()
                                .fill(card.rarity.color.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(card.rarity.color.opacity(0.5), lineWidth: 2)
                                )
                        )
                        
                        // Card name
                        Text(card.displayTitle)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Category
                        HStack(spacing: IgnitionSpacing.xs) {
                            Image(systemName: card.category.iconName)
                                .foregroundColor(card.category.color)
                            
                            Text(card.category.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        // Collection count
                        if card.ownedCount > 1 {
                            HStack(spacing: IgnitionSpacing.xs) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(IgnitionColors.goldAccent)
                                
                                Text("×\(card.ownedCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(IgnitionColors.goldAccent)
                            }
                            .padding(.horizontal, IgnitionSpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(IgnitionColors.goldAccent.opacity(0.2))
                            )
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Dismiss button
                if showDetails {
                    Button(action: {
                        AudioHapticsManager.shared.uiTapped()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }) {
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, IgnitionSpacing.xl)
                            .padding(.vertical, IgnitionSpacing.md)
                            .background(
                                Capsule()
                                    .fill(IgnitionGradients.fireGradient)
                                    .fireGlow(radius: 8)
                            )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, IgnitionSpacing.xl)
                }
            }
        }
        .onAppear {
            startRevealSequence()
        }
    }
    
    // MARK: - Card Back View
    
    private var cardBackView: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(IgnitionColors.ignitionBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
            
            // Card back image
            if let _ = UIImage(named: "card-back") {
                Image("card-back")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 350)
                    .clipped()
                    .cornerRadius(20)
            } else {
                // Fallback: gradient pattern
                VStack(spacing: IgnitionSpacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundColor(IgnitionColors.ignitionOrange)
                        .fireGlow(radius: 20, color: IgnitionColors.ignitionOrange)
                    
                    Text("IGNITION")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                }
            }
        }
        .frame(width: 250, height: 350)
    }
    
    // MARK: - Card Front View
    
    private var cardFrontView: some View {
        ZStack {
            // Card background with rarity border
            RoundedRectangle(cornerRadius: 20)
                .fill(IgnitionColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [card.rarity.color, card.rarity.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
            
            // Card artwork
            if let _ = UIImage(named: card.assetName) {
                Image(card.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 350)
                    .clipped()
                    .cornerRadius(20)
            } else {
                // Fallback: category icon
                VStack(spacing: IgnitionSpacing.md) {
                    Image(systemName: card.category.iconName)
                        .font(.system(size: 100))
                        .foregroundColor(card.category.color)
                    
                    Text(card.displayTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, IgnitionSpacing.md)
                }
            }
            
            // Rarity indicator (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    
                    Circle()
                        .fill(card.rarity.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: rarityIcon(for: card.rarity))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .padding(IgnitionSpacing.sm)
                }
                
                Spacer()
            }
        }
        .frame(width: 250, height: 350)
    }
    
    // MARK: - Animation Sequence
    
    private func startRevealSequence() {
        // Play sound effect
        AudioHapticsManager.shared.cardRevealed()
        
        // Step 1: Show flames (0.2s)
        withAnimation(.easeOut(duration: 0.3)) {
            showFlames = true
        }
        
        // Step 2: Start card flip (0.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                cardRotation = 90
            }
        }
        
        // Step 3: Switch to card front at 90° (1.1s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showCard = true
            cardRotation = 90
        }
        
        // Step 4: Complete flip and scale up (1.15s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                cardRotation = 0
                cardScale = 1.0
            }
        }
        
        // Step 5: Glow effect (1.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 30
            }
        }
        
        // Step 6: Hide flames and show details (2.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFlames = false
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showDetails = true
            }
        }
    }
    
    private func rarityIcon(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "c.circle.fill"
        case .rare: return "r.circle.fill"
        case .epic: return "e.circle.fill"
        case .legendary: return "l.circle.fill"
        }
    }
}

// MARK: - Flames Burst View

struct FlamesBurstView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<12) { index in
                FlameParticle(index: index)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 3 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animate = true
            }
        }
    }
}

struct FlameParticle: View {
    let index: Int
    
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 40))
            .foregroundColor(index % 2 == 0 ? IgnitionColors.ignitionOrange : IgnitionColors.fireRed)
            .offset(
                x: cos(Double(index) * .pi / 6) * 100,
                y: sin(Double(index) * .pi / 6) * 100
            )
            .blur(radius: 2)
    }
}

