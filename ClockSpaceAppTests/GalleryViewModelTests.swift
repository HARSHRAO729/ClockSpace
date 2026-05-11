import XCTest
import Combine
@testable import ClockSpace

@MainActor
final class GalleryViewModelTests: XCTestCase {
    
    var viewModel: GalleryViewModel!
    var apiManager: APIManager!
    
    override func setUp() {
        super.setUp()
        apiManager = APIManager.shared
        // Clear existing data for a clean test
        apiManager.screensavers = []
        viewModel = GalleryViewModel(api: apiManager)
    }
    
    func testFilteringBySearchText() {
        // Given
        let saver1 = Screensaver(id: UUID(), name: "Sunset", author: "Alice", category: .nature, description: "", previewURL: "", thumbnailURL: "", downloadURL: "", isNew: false, rating: 5.0, downloadCount: 100)
        let saver2 = Screensaver(id: UUID(), name: "Forest", author: "Bob", category: .nature, description: "", previewURL: "", thumbnailURL: "", downloadURL: "", isNew: false, rating: 4.5, downloadCount: 50)
        apiManager.screensavers = [saver1, saver2]
        
        // When
        viewModel.searchText = "Sun"
        
        // Then
        XCTAssertEqual(viewModel.filteredScreensavers.count, 1)
        XCTAssertEqual(viewModel.filteredScreensavers.first?.name, "Sunset")
    }
    
    func testFilteringByCategory() {
        // Given
        let saver1 = Screensaver(id: UUID(), name: "Sunset", author: "Alice", category: .nature, description: "", previewURL: "", thumbnailURL: "", downloadURL: "", isNew: false, rating: 5.0, downloadCount: 100)
        let saver2 = Screensaver(id: UUID(), name: "Logic", author: "Charlie", category: .abstract, description: "", previewURL: "", thumbnailURL: "", downloadURL: "", isNew: false, rating: 4.0, downloadCount: 20)
        apiManager.screensavers = [saver1, saver2]
        
        // When
        viewModel.selectedCategory = .abstract
        
        // Then
        XCTAssertEqual(viewModel.filteredScreensavers.count, 1)
        XCTAssertEqual(viewModel.filteredScreensavers.first?.category, .abstract)
    }
}
