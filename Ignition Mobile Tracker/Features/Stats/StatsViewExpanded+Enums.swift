//
//  StatsViewExpanded+Enums.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 04/10/25.
//  Refactored from StatsViewExpanded.swift for better code organization
//

import SwiftUI

// MARK: - StatsViewExpanded Enums Extension
extension StatsViewExpanded {
    
    enum TimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .day: return "sun.max"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar.circle"
            case .quarter: return "calendar.badge.exclamationmark"
            case .year: return "calendar"
            case .custom: return "calendar.badge.plus"
            }
        }
        
        var dateRange: DateInterval {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .day:
                return calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, end: now)
            case .month:
                return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, end: now)
            case .quarter:
                let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
                let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter) ?? now
                return DateInterval(start: startOfQuarter, end: endOfQuarter)
            case .year:
                return calendar.dateInterval(of: .year, for: now) ?? DateInterval(start: now, end: now)
            case .custom:
                return DateInterval(start: now, end: now) // Will be overridden
            }
        }
    }
    
    enum MetricType: String, CaseIterable {
        case sparks = "Sparks"
        case points = "Points"
        case intensity = "Intensity"
        case categories = "Categories"
        case missions = "Missions"
        case streaks = "Streaks"
        case fuel = "Fuel"
        case productivity = "Productivity"
        
        var icon: String {
            switch self {
            case .sparks: return "sparkles"
            case .points: return "star.fill"
            case .intensity: return "flame.fill"
            case .categories: return "folder.fill"
            case .missions: return "target"
            case .streaks: return "flame"
            case .fuel: return "gauge"
            case .productivity: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var color: Color {
            switch self {
            case .sparks: return .blue
            case .points: return .yellow
            case .intensity: return .red
            case .categories: return .green
            case .missions: return .purple
            case .streaks: return .orange
            case .fuel: return .cyan
            case .productivity: return .indigo
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case line = "Line"
        case bar = "Bar"
        case area = "Area"
        case pie = "Pie"
        case scatter = "Scatter"
        case heatmap = "Heatmap"
        
        var icon: String {
            switch self {
            case .line: return "chart.line.uptrend.xyaxis"
            case .bar: return "chart.bar.fill"
            case .area: return "chart.xyaxis.line"
            case .pie: return "chart.pie.fill"
            case .scatter: return "chart.dots.scatter"
            case .heatmap: return "grid.circle.fill"
            }
        }
    }
    
    enum AnalysisType: String, CaseIterable {
        case overview = "Overview"
        case trends = "Trends"
        case patterns = "Patterns"
        case correlations = "Correlations"
        case predictions = "Predictions"
        case comparisons = "Comparisons"
        case goals = "Goals"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.doc.horizontal"
            case .trends: return "chart.line.uptrend.xyaxis"
            case .patterns: return "waveform.path"
            case .correlations: return "link"
            case .predictions: return "sparkles"
            case .comparisons: return "arrow.left.arrow.right"
            case .goals: return "scope"
            case .insights: return "lightbulb.fill"
            }
        }
    }
    
    enum ComparisonPeriod: String, CaseIterable {
        case previousPeriod = "Previous Period"
        case sameLastYear = "Same Period Last Year"
        case average = "Historical Average"
        case custom = "Custom"
    }
}

