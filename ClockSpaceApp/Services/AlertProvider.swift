//
//  AppAlert.swift
//  ClockSpace
//
//  Standardized alert model for the application.
//

import SwiftUI
import Combine

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
    
    init(title: String, message: String, primaryButton: Alert.Button = .default(Text("OK")), secondaryButton: Alert.Button? = nil) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

@MainActor
final class AlertProvider: ObservableObject {
    static let shared = AlertProvider()
    
    @Published var currentAlert: AppAlert?
    
    private init() {}
    
    func showAlert(title: String, message: String) {
        currentAlert = AppAlert(title: title, message: message)
    }
    
    func showError(_ error: Error) {
        currentAlert = AppAlert(title: "Error", message: error.localizedDescription)
    }
}
