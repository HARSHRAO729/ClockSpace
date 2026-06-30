//
//  FirebaseService.swift
//  ClockSpace
//
//  Centralized service for Firebase Firestore and Storage operations.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class FirebaseService {
    
    static let shared = FirebaseService()
    
    private var isConfigured: Bool {
        FirebaseApp.app() != nil
    }
    
    private lazy var db: Firestore? = {
        guard isConfigured else { return nil }
        return Firestore.firestore()
    }()
    
    private lazy var storage: Storage? = {
        guard isConfigured else { return nil }
        return Storage.storage()
    }()
    
    private init() {}
    
    // MARK: - Firestore: Screensavers
    
    /// Fetches all screensavers from the "screensavers" collection.
    func fetchScreensavers() async throws -> [Screensaver] {
        guard isConfigured, let db = db else {
            print("⚠️ Firebase not configured. Skipping cloud fetch.")
            return []
        }
        
        let snapshot = try await db.collection("savers")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Screensaver.self)
            } catch {
                print("❌ Decoding error for document \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    /// Fetches screensavers by category.
    func fetchScreensavers(for category: Category) async throws -> [Screensaver] {
        guard isConfigured, let db = db else {
            return []
        }
        
        let snapshot = try await db.collection("savers")
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Screensaver.self)
            } catch {
                print("❌ Decoding error for document \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    /// Uploads/Updates a screensaver document.
    func uploadScreensaver(_ screensaver: Screensaver) async throws {
        guard isConfigured, let db = db else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        try db.collection("savers").document(screensaver.id.uuidString).setData(from: screensaver)
    }
    
    // MARK: - Storage: Assets
    
    /// Gets a download URL for a specific path in Firebase Storage.
    func getDownloadURL(for path: String) async throws -> URL {
        guard isConfigured, let storage = storage else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        let ref = storage.reference(withPath: path)
        return try await ref.downloadURL()
    }
}
