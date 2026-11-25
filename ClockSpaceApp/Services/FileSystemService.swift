//
//  FileSystemService.swift
//  ClockSpace
//
//  File operations on ~/Library/Screen Savers. No UI state.
//

import Foundation

nonisolated struct FileSystemService: Sendable {

    static let shared = FileSystemService()

    /// ~/Library/Screen Savers
    var screenSaversDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Screen Savers", directoryHint: .isDirectory)
    }

    func url(forSaverNamed fileName: String) -> URL {
        screenSaversDirectory.appending(path: fileName, directoryHint: .isDirectory)
    }

    func saverExists(named fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: url(forSaverNamed: fileName).path)
    }

    /// Copies `bundle` into ~/Library/Screen Savers as `fileName`, replacing any
    /// bundle of that name. The copy is made under a temporary name first, so a
    /// failure never leaves a half-copied saver or loses the existing one.
    @discardableResult
    func install(bundle: URL, as fileName: String) throws -> URL {
        let fm = FileManager.default
        let dir = screenSaversDirectory
        let destination = url(forSaverNamed: fileName)
        let staging = dir.appending(path: ".clockspace-\(UUID().uuidString).saver", directoryHint: .isDirectory)
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try fm.copyItem(at: bundle, to: staging)
            if fm.fileExists(atPath: destination.path) {
                _ = try fm.replaceItemAt(destination, withItemAt: staging)
            } else {
                try fm.moveItem(at: staging, to: destination)
            }
        } catch {
            try? fm.removeItem(at: staging)
            throw InstallError.cannotWrite
        }
        return destination
    }

    /// Removes a saver by file name. Missing files are not an error.
    func remove(saverNamed fileName: String) throws {
        let target = url(forSaverNamed: fileName)
        guard FileManager.default.fileExists(atPath: target.path) else { return }
        do {
            try FileManager.default.removeItem(at: target)
        } catch {
            throw InstallError.cannotWrite
        }
    }
}
