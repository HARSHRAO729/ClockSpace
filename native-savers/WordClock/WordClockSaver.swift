//
//  WordClockSaver.swift
//  ClockSpace — native Swift screensaver (flagship rebuild of the broken "Word Clock")
//
//  Self-contained: a ScreenSaverView subclass (the principal class macOS loads)
//  hosting a SwiftUI word-clock that lights the words for the current time.
//  Universal (arm64 + x86_64), no external assets. Build via scripts/build_saver.sh.
//

import ScreenSaver
import SwiftUI

// MARK: - Principal class (loaded by macOS via NSPrincipalClass)

final class WordClockView: ScreenSaverView {
    private var hosting: NSHostingView<WordClockContent>?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 5.0 // SwiftUI drives its own updates; keep light
        let view = NSHostingView(rootView: WordClockContent())
        view.frame = bounds
        view.autoresizingMask = [.width, .height]
        addSubview(view)
        hosting = view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill(); rect.fill()
        super.draw(rect)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        hosting?.frame = bounds
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}

// MARK: - The 11×10 QLOCKTWO-style letter grid

private enum WordGrid {
    static let rows: [String] = [
        "ITLISASAMPM",
        "ACQUARTERDC",
        "TWENTYFIVEX",
        "HALFSTENFTO",
        "PASTERUNINE",
        "ONESIXTHREE",
        "FOURFIVETWO",
        "EIGHTELEVEN",
        "SEVENTWELVE",
        "TENSEOCLOCK",
    ]
    // A word = (row, startColumn, length)
    typealias Word = (r: Int, c: Int, len: Int)
    static let IT: Word = (0, 0, 2); static let IS: Word = (0, 3, 2)
    static let PAST: Word = (4, 0, 4); static let TO: Word = (3, 9, 2)
    static let OCLOCK: Word = (9, 5, 6)
    // minutes
    static let M_FIVE: Word = (2, 6, 4); static let M_TEN: Word = (3, 5, 3)
    static let M_QUARTER: Word = (1, 2, 7); static let M_TWENTY: Word = (2, 0, 6)
    static let M_HALF: Word = (3, 0, 4)
    // hours 1...12
    static let hours: [Word] = [
        (5, 0, 3),  // ONE
        (6, 8, 3),  // TWO
        (5, 6, 5),  // THREE
        (6, 0, 4),  // FOUR
        (6, 4, 4),  // FIVE
        (5, 3, 3),  // SIX
        (8, 0, 5),  // SEVEN
        (7, 0, 5),  // EIGHT
        (4, 7, 4),  // NINE
        (9, 0, 3),  // TEN
        (7, 5, 6),  // ELEVEN
        (8, 5, 6),  // TWELVE
    ]

    /// Returns the set of lit (row,col) coordinates for a given hour/minute.
    static func lit(hour24: Int, minute: Int) -> Set<[Int]> {
        var words: [Word] = [IT, IS]
        let m = (minute / 5) * 5              // round down to nearest 5
        var hour = hour24 % 12
        switch m {
        case 0: words += [OCLOCK]
        case 5: words += [M_FIVE, PAST]
        case 10: words += [M_TEN, PAST]
        case 15: words += [M_QUARTER, PAST]
        case 20: words += [M_TWENTY, PAST]
        case 25: words += [M_TWENTY, M_FIVE, PAST]
        case 30: words += [M_HALF, PAST]
        case 35: words += [M_TWENTY, M_FIVE, TO]; hour += 1
        case 40: words += [M_TWENTY, TO]; hour += 1
        case 45: words += [M_QUARTER, TO]; hour += 1
        case 50: words += [M_TEN, TO]; hour += 1
        case 55: words += [M_FIVE, TO]; hour += 1
        default: break
        }
        let idx = ((hour + 11) % 12)          // 0->12 o'clock uses index 11
        words.append(hours[idx])
        var set = Set<[Int]>()
        for w in words { for k in 0..<w.len { set.insert([w.r, w.c + k]) } }
        return set
    }
}

// MARK: - SwiftUI content

struct WordClockContent: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: context.date)
            let lit = WordGrid.lit(hour24: comps.hour ?? 0, minute: comps.minute ?? 0)
            GeometryReader { geo in
                // Per-display: GeometryReader reports THIS screen's bounds, so the grid
                // sizes independently on every monitor and in the Settings preview.
                let cols: CGFloat = 11, rowsN: CGFloat = 10
                let hGap: CGFloat = 0.30, vGap: CGFloat = 0.32   // fractions of a cell
                let fit: CGFloat = 0.88                          // grid never exceeds 88% of either axis
                // Largest cell that fits BOTH axes; whichever axis binds wins.
                let cellW = geo.size.width  * fit / (cols  + (cols  - 1) * hGap)
                let cellH = geo.size.height * fit / (rowsN + (rowsN - 1) * vGap)
                let cell = min(cellW, cellH)
                let font = Font.system(size: cell * 0.60, weight: .semibold, design: .monospaced)
                VStack(spacing: cell * vGap) {
                    ForEach(0..<Int(rowsN), id: \.self) { r in
                        HStack(spacing: cell * hGap) {
                            ForEach(0..<Int(cols), id: \.self) { c in
                                let on = lit.contains([r, c])
                                Text(String(Array(WordGrid.rows[r])[c]))
                                    .font(font)
                                    .foregroundStyle(on ? Color.white : Color.white.opacity(0.10))
                                    .shadow(color: on ? .white.opacity(0.55) : .clear,
                                            radius: on ? cell * 0.10 : 0)
                                    .frame(width: cell, height: cell)
                                    .animation(.easeInOut(duration: 0.6), value: on)
                            }
                        }
                    }
                }
                // Center the grid within the full display bounds — margins stay black.
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
}
