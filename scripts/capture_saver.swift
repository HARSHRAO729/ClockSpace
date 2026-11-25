// Capture a screenshot of a .saver bundle running, for the gallery thumbnail.
//
// Usage:
//   xcrun swiftc -O scripts/capture_saver.swift -o /tmp/capture_saver
//   /tmp/capture_saver <Name.saver> <out.png> [seconds=4] [--onscreen]
//
// Loads the saver's principal class (a ScreenSaverView), runs it at 1280×800
// for a few seconds, then renders the view into a PNG.
// --onscreen shows the window and captures it with `screencapture -l`, which
// also sees GPU-drawn (Metal/OpenGL) savers. It needs Screen Recording
// permission for the app that runs this tool (macOS asks the first time).
// Exit codes: 0 ok, 2 usage, 3 not a loadable saver, 4 view init failed, 5 write failed.
// Run one saver per process: two savers can define the same class names.

import AppKit
import ScreenSaver

let args = CommandLine.arguments.filter { $0 != "--onscreen" }
let onscreen = CommandLine.arguments.contains("--onscreen")
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: capture_saver <Name.saver> <out.png> [seconds] [--onscreen]\n".data(using: .utf8)!)
    exit(2)
}
let saverURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
let seconds = args.count > 3 ? (Double(args[3]) ?? 4) : 4
let size = NSSize(width: 1280, height: 800)

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, never takes focus

guard let bundle = Bundle(url: saverURL), bundle.load(),
      let saverClass = bundle.principalClass as? ScreenSaverView.Type else {
    FileHandle.standardError.write("not a loadable screensaver: \(saverURL.path)\n".data(using: .utf8)!)
    exit(3)
}
guard let view = saverClass.init(frame: NSRect(origin: .zero, size: size), isPreview: false) else {
    FileHandle.standardError.write("screensaver view failed to initialise\n".data(using: .utf8)!)
    exit(4)
}

// Off screen by default so nothing flashes on the user's display.
let origin = onscreen ? NSPoint(x: 80, y: 80) : NSPoint(x: -20000, y: -20000)
let window = NSWindow(contentRect: NSRect(origin: origin, size: size),
                      styleMask: [.borderless], backing: .buffered, defer: false)
window.isReleasedWhenClosed = false
window.backgroundColor = .black
window.contentView = view
window.level = onscreen ? .floating : .normal
window.orderFrontRegardless()
view.startAnimation()

DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
    if onscreen {
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), outURL.path]
        try? capture.run()
        capture.waitUntilExit()
        view.stopAnimation()
        exit(capture.terminationStatus == 0 ? 0 : 5)
    }
    view.display()
    guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { exit(5) }
    view.cacheDisplay(in: view.bounds, to: rep)
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(5) }
    do {
        try png.write(to: outURL)
    } catch {
        exit(5)
    }
    view.stopAnimation()
    exit(0)
}
app.run()
