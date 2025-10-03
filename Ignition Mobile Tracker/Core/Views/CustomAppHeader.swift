//
//  CustomAppHeader.swift
//  Ignition Mobile Tracker
//
//  Created by AI Assistant on 03/10/25.
//

import SwiftUI

struct CustomAppHeader: View {
    @Environment(\.tabRouter) private var tabRouter
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Binding var showingStats: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            // Logo
            if let _ = UIImage(named: "app-logo") {
                Image("app-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 32)
                    .fireGlow(radius: 6, color: IgnitionColors.ignitionOrange)
            } else {
                Text("IGNITION")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .overlay(
                        LinearGradient(
                            colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text("IGNITION")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                        )
                    )
                    .fireGlow(radius: 6)
            }
            
            Spacer()
            
            HStack(spacing: IgnitionSpacing.sm) {
                // Stats Pill Button
                Button(action: {
                    showingStats = true
                    audioHapticsManager.uiTapped()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("STATS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(IgnitionColors.ignitionOrange)
                            .fireGlow(radius: 4, color: IgnitionColors.ignitionOrange)
                    )
                }
                
                // Settings Pill Button
                Button(action: {
                    showingSettings = true
                    audioHapticsManager.uiTapped()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("SETTINGS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(IgnitionColors.ignitionOrange)
                            .fireGlow(radius: 4, color: IgnitionColors.ignitionOrange)
                    )
                }
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
        .background(IgnitionColors.headerGray)
    }
}

