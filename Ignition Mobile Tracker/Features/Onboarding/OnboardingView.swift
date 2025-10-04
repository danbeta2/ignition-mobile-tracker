//
//  OnboardingView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 04/10/25.
//

import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "bolt.fill",
            title: "Capture Your Sparks",
            description: "Record moments of inspiration, decisions, and creative ideas. Every spark fuels your journey.",
            color: IgnitionColors.ignitionOrange
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Complete Missions",
            description: "Daily and weekly challenges keep you engaged. Earn points and unlock achievements.",
            color: IgnitionColors.goldAccent
        ),
        OnboardingPage(
            icon: "rectangle.stack.fill",
            title: "Collect Spark Cards",
            description: "Discover rare cards as you create sparks. Build your collection and master each category.",
            color: IgnitionColors.fireRed
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "Monitor your stats, streaks, and level up as you grow. Your journey is uniquely yours.",
            color: IgnitionColors.ignitionOrange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .font(IgnitionFonts.body)
                            .foregroundColor(IgnitionColors.mediumGray)
                            .padding()
                    }
                }
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom buttons
                VStack(spacing: IgnitionSpacing.md) {
                    if currentPage == pages.count - 1 {
                        // Get Started button on last page
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, IgnitionSpacing.md)
                                .background(
                                    LinearGradient(
                                        colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(IgnitionRadius.lg)
                                .shadow(color: IgnitionColors.ignitionOrange.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, IgnitionSpacing.xl)
                    } else {
                        // Next button
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                            audioHapticsManager.playSelectionHaptic()
                        }) {
                            Text("Next")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, IgnitionSpacing.md)
                                .background(
                                    LinearGradient(
                                        colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(IgnitionRadius.lg)
                                .shadow(color: IgnitionColors.ignitionOrange.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, IgnitionSpacing.xl)
                    }
                }
                .padding(.bottom, IgnitionSpacing.xl)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        audioHapticsManager.uiTapped()
        isPresented = false
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: IgnitionSpacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
            }
            .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, IgnitionSpacing.lg)
            
            // Description
            Text(page.description)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(IgnitionColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, IgnitionSpacing.xl)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isPresented: .constant(true))
}

