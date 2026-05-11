//
//  FirebaseService.swift
//  ClockSpace
//
//  Centralized service for Firebase Firestore and Storage operations.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class FirebaseService {
    
    static let shared = FirebaseService()
    private lazy var db = Firestore.firestore()
    private lazy var storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Firestore: Screensavers
    
    /// Fetches all screensavers from the "screensavers" collection.
    func fetchScreensavers() async throws -> [Screensaver] {
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
        try db.collection("savers").document(screensaver.id.uuidString).setData(from: screensaver)
    }
    
    // MARK: - Storage: Assets
    
    /// Gets a download URL for a specific path in Firebase Storage.
    func getDownloadURL(for path: String) async throws -> URL {
        let ref = storage.reference(withPath: path)
        return try await ref.downloadURL()
    }
}
