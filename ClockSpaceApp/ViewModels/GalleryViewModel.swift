//
//  GalleryViewModel.swift
//  ClockSpace
//
//  ViewModel for the screensaver gallery. 
//  Coordinates between APIManager (data) and ScreensaverManager (actions).
//

import SwiftUI
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var filteredScreensavers: [Screensaver] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let api: APIManager
    private let manager: ScreensaverManager
    private var cancellables = Set<AnyCancellable>()
    
    init(api: APIManager = .shared, manager: ScreensaverManager = .shared) {
        self.api = api
        self.manager = manager
        setupBindings()
    }
    
    private func setupBindings() {
        // Automatically refilter when data or search text changes
        Publishers.CombineLatest3(api.$screensavers, $searchText, $selectedCategory)
            .map { screensavers, search, category in
                screensavers.filter { saver in
                    let matchesSearch = search.isEmpty || 
                                       saver.name.localizedCaseInsensitiveContains(search) ||
                                       saver.author.localizedCaseInsensitiveContains(search)
                    let matchesCategory = category == nil || saver.category == category
                    return matchesSearch && matchesCategory
                }
            }
            .assign(to: &$filteredScreensavers)
            
        // Sync loading state
        api.$isLoading.assign(to: &$isLoading)
        api.$errorMessage.assign(to: &$errorMessage)
    }
    
    // MARK: - Actions
    
    func refresh() async {
        do {
            _ = try await api.fetchScreensavers(category: selectedCategory)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func selectCategory(_ category: Category?) {
        selectedCategory = category
    }
    
    func install(_ screensaver: Screensaver) async {
        await manager.installFromMarketplace(screensaver)
    }
    
    func isInstalled(_ screensaver: Screensaver) -> Bool {
        manager.isInstalled(screensaver)
    }
    
    func isInstalling(_ screensaver: Screensaver) -> Bool {
        manager.isInstalling(screensaver)
    }
}
