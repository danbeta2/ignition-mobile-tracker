//
//  AchievementsView.swift
//  Ignition Mobile Tracker
//
//  Extracted from HomeViewExpanded.swift
//

import SwiftUI

struct AchievementsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Obiettivi e Traguardi")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati tutti gli obiettivi")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Obiettivi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AchievementsView()
}
