#!/usr/bin/env swift
//
// Draws the DMG window background (scripts/assets/dmg_background.tiff) in the
// app's colours: a title, an arrow from the app to Applications, and the
// first-launch hint. The TIFF holds a 1x and a 2x image so it is sharp on Retina.
//
// Usage: swift scripts/make_dmg_background.swift
// The layout constants must match create_dmg.sh (window size and icon positions).

import AppKit

let size = CGSize(width: 640, height: 420)     // Finder window content, in points
let appCenter = CGPoint(x: 170, y: 190)        // icon centres, measured from the top
let appsCenter = CGPoint(x: 470, y: 190)
let labelY: CGFloat = 278                      // centre of Finder's icon labels

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

func draw(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centerY: CGFloat, in ctx: CGContext) {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: para,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let h = str.boundingRect(with: CGSize(width: 560, height: 200), options: [.usesLineFragmentOrigin]).height
    str.draw(with: CGRect(x: 40, y: centerY - h / 2, width: 560, height: h), options: [.usesLineFragmentOrigin])
}

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size  // 72 dpi at 1x, 144 dpi at 2x
    NSGraphicsContext.saveGraphicsState()
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    // Flip so y grows downwards, like Finder's icon positions.
    ctx.translateBy(x: 0, y: size.height)
    ctx.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)

    let space = CGColorSpace(name: CGColorSpace.sRGB)!

    // Background: the app's near-black navy, with an indigo glow behind the icons.
    let base = CGGradient(colorsSpace: space, colors: [hex(0x0A0A14).cgColor, hex(0x14142E).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(base, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
    let glow = CGGradient(colorsSpace: space, colors: [hex(0x4F46E5, 0.35).cgColor, hex(0x4F46E5, 0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 320, y: 200), startRadius: 0,
                           endCenter: CGPoint(x: 320, y: 200), endRadius: 300, options: [])

    // Title and subtitle.
    draw("Install ClockSpace", size: 22, weight: .bold, color: .white, centerY: 46, in: ctx)
    draw("Drag ClockSpace into your Applications folder", size: 13, weight: .regular, color: hex(0x94A3B8), centerY: 76, in: ctx)

    // Arrow from the app icon to Applications, indigo to violet.
    let startX = appCenter.x + 78, endX = appsCenter.x - 78, y = appCenter.y
    let arrow = CGMutablePath()
    arrow.move(to: CGPoint(x: startX, y: y))
    arrow.addLine(to: CGPoint(x: endX - 4, y: y))
    arrow.move(to: CGPoint(x: endX - 16, y: y - 12))
    arrow.addLine(to: CGPoint(x: endX - 2, y: y))
    arrow.addLine(to: CGPoint(x: endX - 16, y: y + 12))
    ctx.saveGState()
    ctx.addPath(arrow.copy(strokingWithWidth: 5, lineCap: .round, lineJoin: .round, miterLimit: 1))
    ctx.clip()
    let stroke = CGGradient(colorsSpace: space, colors: [hex(0x6366F1).cgColor, hex(0x8B5CF6).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(stroke, start: CGPoint(x: startX, y: y), end: CGPoint(x: endX, y: y), options: [])
    ctx.restoreGState()

    // Plates under Finder's labels. Finder draws labels black in Light mode and
    // white in Dark mode; this mid tone keeps both above 4:1 contrast.
    for x in [appCenter.x, appsCenter.x] {
        let plate = CGPath(roundedRect: CGRect(x: x - 62, y: labelY - 12, width: 124, height: 24),
                           cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.addPath(plate)
        ctx.setFillColor(hex(0x6B6E8A).cgColor)
        ctx.fillPath()
    }

    // First-launch hint.
    draw("First launch: if macOS blocks ClockSpace, open System Settings › Privacy & Security\nand click Open Anyway.",
         size: 11, weight: .regular, color: hex(0x94A3B8), centerY: 362, in: ctx)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "scripts/assets/dmg_background.tiff")
let tiff = NSBitmapImageRep.tiffRepresentationOfImageReps(in: [render(scale: 1), render(scale: 2)], using: .lzw, factor: 0)!
try tiff.write(to: out)
print("Wrote \(out.path)")
