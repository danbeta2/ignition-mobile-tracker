//
//  ErrorManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 04/10/25.
//

import SwiftUI
import Combine

// MARK: - App Error Model
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Error Manager
@MainActor
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var showAlert = false
    
    private init() {}
    
    /// Handle Core Data errors with user-friendly messages
    func handleCoreDataError(_ error: Error, context: String = "saving data") {
        print("❌ Core Data error in \(context): \(error.localizedDescription)")
        
        currentError = AppError(
            title: "Unable to Save",
            message: "There was a problem \(context). Please try again."
        )
        showAlert = true
    }
    
    /// Handle general errors
    func handleError(_ error: Error, title: String = "Error", message: String? = nil) {
        print("❌ Error: \(error.localizedDescription)")
        
        currentError = AppError(
            title: title,
            message: message ?? "Something went wrong. Please try again."
        )
        showAlert = true
    }
}

