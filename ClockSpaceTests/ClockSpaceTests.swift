//
//  ClockSpaceTests.swift
//  ClockSpaceTests
//
//  Unit tests for the parts of ClockSpace that do not need a network or a UI:
//  catalog decoding, the Intel filter, version comparison and the installer's checks.
//

import Foundation
import Testing
@testable import ClockSpace

// MARK: - Catalog

@Suite struct CatalogTests {

    /// One catalog entry as JSON, with only the required fields unless more are given.
    static func entry(_ extra: String = "", id: UUID = UUID()) -> String {
        #"{"id":"\#(id)","name":"Test","downloadURL":"https://example.com/t.zip"\#(extra)}"#
    }

    static func decode(_ entries: String...) throws -> [Screensaver] {
        try Screensaver.decodeCatalog(from: Data("[\(entries.joined(separator: ","))]".utf8))
    }

    @Test func bundledCatalogIsComplete() throws {
        let url = try #require(Bundle.main.url(forResource: "catalog", withExtension: "json"))
        let savers = try Screensaver.decodeCatalog(from: Data(contentsOf: url))

        #expect(savers.count == 19)
        #expect(Set(savers.map(\.id)).count == savers.count, "ids must be unique")
        for s in savers {
            #expect(s.downloadURL.hasPrefix("https://"), "\(s.name): download must be https")
            #expect(s.thumbnailURL.hasPrefix("https://"), "\(s.name): thumbnail must be https")
            #expect(s.sha256?.count == 64, "\(s.name): needs a sha256")
            #expect(s.sourceURL?.isEmpty == false || s.license == "Closed source", "\(s.name): needs a source link")
            #expect(s.author != "Unknown", "\(s.name): needs an author")
        }
        #expect(Set(savers.filter(\.appleSiliconOnly).map(\.name)) == ["Start Now", "OneClock"])
    }

    @Test func onlyRequiredFieldsGetDefaults() throws {
        let s = try #require(try Self.decode(Self.entry()).first)
        #expect(s.description == "")
        #expect(s.category == .other)
        #expect(s.author == "Unknown")
        #expect(s.tags.isEmpty)
        #expect(s.createdAt == .distantPast)
        #expect(s.sha256 == nil)
        #expect(!s.appleSiliconOnly)
        #expect(!s.isNew)
    }

    @Test func unknownCategoryAndExtraKeysAreTolerated() throws {
        let s = try #require(try Self.decode(Self.entry(#","category":"underwaterBasketWeaving","isPremium":true"#)).first)
        #expect(s.category == .other)
    }

    @Test func wrongTypedOptionalFieldFallsBack() throws {
        let s = try #require(try Self.decode(Self.entry(#","tags":"not-a-list","rank":"first""#)).first)
        #expect(s.tags.isEmpty)
        #expect(s.rank == nil)
    }

    @Test func badEntriesAreSkippedNotFatal() throws {
        let savers = try Self.decode(
            Self.entry(),
            #"{"id":"not-a-uuid","name":"Bad","downloadURL":"https://example.com"}"#,
            #"{"name":"No id"}"#,
            Self.entry()
        )
        #expect(savers.count == 2)
    }

    @Test func nonArrayThrows() {
        #expect(throws: (any Error).self) { try Screensaver.decodeCatalog(from: Data("{}".utf8)) }
    }

    @Test func intelMacsHideAppleSiliconOnlySavers() throws {
        let savers = try Self.decode(Self.entry(), Self.entry(#","appleSiliconOnly":true"#))
        #expect(APIManager.forThisMac(savers, appleSilicon: true).count == 2)
        #expect(APIManager.forThisMac(savers, appleSilicon: false).count == 1)
        #expect(APIManager.forThisMac(savers, appleSilicon: false).allSatisfy { !$0.appleSiliconOnly })
    }
}

// MARK: - Versions

@Suite struct VersionTests {

    @Test(arguments: [("v1.2", "1.2"), ("V1.2.0", "1.2.0"), (" 1.1 ", "1.1"), ("1.0", "1.0")])
    func normalizesTags(tag: String, expected: String) {
        #expect(UpdateChecker.normalized(tag) == expected)
    }

    @Test(arguments: [
        ("1.1.1", "1.1.0", true),
        ("v1.2", "1.1.9", true),
        ("1.10", "1.9", true),      // numeric, not alphabetical
        ("2.0", "1.99.99", true),
        ("1.1", "1.1.0", false),    // missing parts count as 0
        ("1.1.0", "1.1.0", false),
        ("1.0.9", "1.1", false),
        ("1.2-beta", "1.1", true),  // trailing text ignored
    ])
    func comparesVersions(a: String, b: String, newer: Bool) {
        #expect(UpdateChecker.isVersion(a, newerThan: b) == newer)
    }
}

// MARK: - System Settings link

@Suite struct SettingsLinkTests {

    @Test func macOS26OpensScreenSaverInsideWallpaper() {
        let url = ScreensaverManager.screenSaverSettingsURL(isMacOS26OrLater: true).absoluteString
        #expect(url == "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension?ScreenSaver")
    }

    @Test func olderMacOSOpensTheScreenSaverPane() {
        let url = ScreensaverManager.screenSaverSettingsURL(isMacOS26OrLater: false).absoluteString
        #expect(url == "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension")
    }
}

// MARK: - Installer

@Suite struct InstallerTests {

    /// A fresh temporary folder, deleted by the caller.
    static func tempFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "ClockSpaceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A minimal .saver bundle. With `executable`, its binary is a copy of that file.
    static func makeSaver(in folder: URL, named name: String = "Fake", executable: URL? = nil) throws -> URL {
        let bundle = folder.appending(path: "\(name).saver")
        let macOS = bundle.appending(path: "Contents/MacOS")
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
        let info: [String: Any] = ["CFBundleExecutable": name, "CFBundleIdentifier": "test.\(name)", "CFBundlePackageType": "BNDL"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: bundle.appending(path: "Contents/Info.plist"))
        if let executable {
            try FileManager.default.copyItem(at: executable, to: macOS.appending(path: name))
        }
        return bundle
    }

    @Test func sha256MatchesKnownDigest() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "abc.txt")
        try Data("abc".utf8).write(to: file)
        #expect(try InstallerService.sha256(of: file) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func findSaverSkipsZipMetadataAndSearchesSubfolders() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        _ = try Self.makeSaver(in: folder.appending(path: "__MACOSX"), named: "Metadata")
        let real = try Self.makeSaver(in: folder.appending(path: "Release/Nested"), named: "Real")
        #expect(InstallerService.findSaver(in: folder)?.lastPathComponent == real.lastPathComponent)
    }

    @Test func findSaverReturnsNilWhenThereIsNone() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        try Data().write(to: folder.appending(path: "readme.txt"))
        #expect(InstallerService.findSaver(in: folder) == nil)
    }

    @Test func validateRejectsBundleWithoutExecutable() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        let saver = try Self.makeSaver(in: folder)
        #expect(throws: InstallError.damaged) { try InstallerService.validate(saver) }
    }

    @Test func validateRejectsNonExecutableFile() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        let text = folder.appending(path: "not-code")
        try Data("hello".utf8).write(to: text)
        let saver = try Self.makeSaver(in: folder, executable: text)
        #expect(throws: InstallError.wrongProcessor) { try InstallerService.validate(saver) }
    }

    @Test func validateAcceptsCodeForThisMac() throws {
        let folder = try Self.tempFolder(); defer { try? FileManager.default.removeItem(at: folder) }
        // The host app's own binary is always built for the Mac running the tests.
        let saver = try Self.makeSaver(in: folder, executable: Bundle.main.executableURL)
        #expect(throws: Never.self) { try InstallerService.validate(saver) }
    }

    @Test func errorsMapToFriendlyMessages() {
        #expect(InstallError.from(URLError(.notConnectedToInternet)) == .offline)
        #expect(InstallError.from(URLError(.timedOut)) == .offline)
        #expect(InstallError.from(InstallError.notFound) == .notFound)
        if case .other = InstallError.from(URLError(.badServerResponse)) {} else {
            Issue.record("other URL errors should map to .other")
        }
        #expect(InstallError.server(503).errorDescription?.contains("503") == true)
    }

    @Test func prepareRefusesNonHTTPSDownloads() async {
        let json = #"[{"id":"\#(UUID())","name":"Plain","downloadURL":"http://example.com/t.zip"}]"#
        let saver = try! Screensaver.decodeCatalog(from: Data(json.utf8))[0]
        await #expect(throws: InstallError.notFound) { _ = try await InstallerService.prepare(saver) }
    }
}
