import Foundation

struct Screensaver: Codable {
    let id: UUID
    let name: String
    let description: String
    let thumbnailURL: String
    let downloadURL: String
    let isPremium: Bool
    let price: Double?
    let author: String
    let downloadCount: Int
    let tags: [String]
    let createdAt: Date
    let rank: Int
    let resolution: String
    let fileSize: String
    let isNew: Bool
    let template: String
}

let url = URL(fileURLWithPath: "ClockSpaceApp/Resources/catalog.json")
do {
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let catalog = try decoder.decode([Screensaver].self, from: data)
    print("Successfully decoded \(catalog.count) screensavers.")
} catch {
    print("Decoding error: \(error)")
}
