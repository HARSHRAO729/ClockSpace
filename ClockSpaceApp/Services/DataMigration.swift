//
//  DataMigration.swift
//  ClockSpace
//
//  One-time utility to sync local mock data to Firebase Firestore.
//

import Foundation
import FirebaseFirestore

@MainActor
struct DataMigration {
    
    /// Pushes all mock screensavers from APIManager to Firestore.
    static func syncToCloud() async {
        print("🚀 Starting Cloud Sync...")
        
        // Get the mock data from APIManager
        let localSavers = APIManager.mockScreensavers
        let firebase = FirebaseService.shared
        
        var successCount = 0
        var failCount = 0
        
        for saver in localSavers {
            do {
                try await firebase.uploadScreensaver(saver)
                print("✅ Synced: \(saver.name)")
                successCount += 1
            } catch {
                print("❌ Failed: \(saver.name) - \(error.localizedDescription)")
                failCount += 1
            }
        }
        
        print("--- Sync Finished ---")
        print("Successfully synced: \(successCount)")
        print("Failed: \(failCount)")
    }
}
