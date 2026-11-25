//
//  InstallerService.swift
//  ClockSpace
//
//  Downloads a screensaver and prepares it for installation, off the main thread:
//  download → check HTTP status → verify checksum → unzip → find the .saver →
//  sanity-check it → fix its signature only if it is broken.
//  Nothing in ~/Library/Screen Savers is touched here.
//

import Foundation
import CryptoKit

// MARK: - Errors

/// Install failures, with messages written for the person using the app.
nonisolated enum InstallError: LocalizedError, Equatable {
    case offline
    case notFound
    case server(Int)
    case damaged
    case wrongProcessor
    case downloadFailed
    case cannotWrite
    case other(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You appear to be offline. Check your internet connection and try again."
        case .notFound:
            return "This screensaver isn't available for download right now. Please try again later."
        case .server(let code):
            return "The download failed (error \(code)). Please try again later."
        case .damaged:
            return "The downloaded screensaver is damaged or incomplete. Please try again."
        case .wrongProcessor:
            return "This screensaver doesn't run on this Mac's processor."
        case .downloadFailed:
            return "The download didn't complete. Check your internet connection and try again."
        case .cannotWrite:
            return "ClockSpace couldn't write to your Screen Savers folder (~/Library/Screen Savers). Check that the folder isn't locked, then try again."
        case .other(let detail):
            return detail
        }
    }

    /// Maps any thrown error to a user-facing install error.
    static func from(_ error: Error) -> InstallError {
        if let e = error as? InstallError { return e }
        if let e = error as? URLError {
            switch e.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
                 .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
                return .offline
            default:
                return .other(e.localizedDescription)
            }
        }
        return .other(error.localizedDescription)
    }
}

// MARK: - Installer

nonisolated enum InstallerService {

    /// A downloaded, checked screensaver bundle waiting in a temporary folder.
    struct Prepared: Sendable {
        let bundle: URL       // the .saver inside the work folder
        let workDir: URL      // delete when done (see `discard`)
        var fileName: String { bundle.lastPathComponent }
    }

    /// Downloads and checks `saver`. On success the caller owns `workDir` and must
    /// call `discard(_:)` when finished. On failure nothing is left behind.
    @concurrent
    static func prepare(_ saver: Screensaver) async throws -> Prepared {
        guard let url = URL(string: saver.downloadURL), url.scheme == "https" else {
            throw InstallError.notFound
        }
        let workDir = FileManager.default.temporaryDirectory
            .appending(path: "ClockSpace-install-\(UUID().uuidString)", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

            // 1–2. Download and require HTTP 200.
            let tempFile: URL, response: URLResponse
            do {
                (tempFile, response) = try await URLSession.shared.download(from: url)
            } catch {
                // Known "no connection" cases get the offline message; any other
                // transfer failure gets a generic one instead of raw system text.
                let mapped = InstallError.from(error)
                throw mapped == .offline ? mapped : InstallError.downloadFailed
            }
            let zip = workDir.appending(path: "download.zip")
            try FileManager.default.moveItem(at: tempFile, to: zip)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200: break
            case 403, 404, 410: throw InstallError.notFound
            default: throw InstallError.server(status)
            }

            // 3. Checksum, when the catalog provides one.
            if let expected = saver.sha256, !expected.isEmpty {
                guard try sha256(of: zip) == expected.lowercased() else { throw InstallError.damaged }
            }

            // 4. Unzip.
            let unzipped = workDir.appending(path: "unzipped", directoryHint: .isDirectory)
            guard try await run("/usr/bin/ditto", ["-x", "-k", zip.path, unzipped.path]) == 0 else {
                throw InstallError.damaged
            }

            // 5–6. Find the bundle and check it can load on this Mac.
            guard let bundle = findSaver(in: unzipped) else { throw InstallError.damaged }
            try validate(bundle)

            // 7. Leave valid signatures alone; repair broken ones with an ad-hoc signature.
            if try await run("/usr/bin/codesign", ["--verify", "--deep", "--strict", bundle.path]) != 0 {
                guard try await run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", bundle.path]) == 0 else {
                    throw InstallError.damaged
                }
            }
            return Prepared(bundle: bundle, workDir: workDir)
        } catch {
            try? FileManager.default.removeItem(at: workDir)
            throw InstallError.from(error)
        }
    }

    static func discard(_ prepared: Prepared) {
        try? FileManager.default.removeItem(at: prepared.workDir)
    }

    // MARK: Checks

    /// First `.saver` bundle in an unzipped folder, ignoring macOS zip metadata.
    static func findSaver(in folder: URL) -> URL? {
        guard let items = FileManager.default.enumerator(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return nil }
        for case let item as URL in items {
            if item.lastPathComponent == "__MACOSX" { items.skipDescendants(); continue }
            if item.pathExtension.lowercased() == "saver" { return item }
        }
        return nil
    }

    /// Throws unless `bundle` has an Info.plist, its executable, and code for this Mac's CPU.
    static func validate(_ bundle: URL) throws {
        guard let info = Bundle(url: bundle),
              info.infoDictionary?["CFBundleExecutable"] != nil,
              let executable = info.executableURL,
              FileManager.default.fileExists(atPath: executable.path) else {
            throw InstallError.damaged
        }
        let needed = CSConstants.isAppleSilicon ? NSBundleExecutableArchitectureARM64 : NSBundleExecutableArchitectureX86_64
        let archs = info.executableArchitectures?.map(\.intValue) ?? []
        guard archs.contains(needed) else { throw InstallError.wrongProcessor }
    }

    static func sha256(of file: URL) throws -> String {
        let digest = SHA256.hash(data: try Data(contentsOf: file))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Running tools

    /// Runs a command-line tool with an argument list (no shell) and returns its exit code.
    @concurrent
    static func run(_ tool: String, _ arguments: [String]) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: tool)
            process.arguments = arguments
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
