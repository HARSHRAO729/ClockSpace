#!/usr/bin/env python3
"""
Generate dist/r2-bucket/catalog.json + gallery thumbnails for the working saver set.
Thumbnails are real screenshots from dist/screenshots/<key>.png or .jpg (1280x800, made with
scripts/capture_saver.swift); a saver without one gets a generated name card
(640x400, needs Pillow). URLs use the CATALOG_BASE environment variable (the __R2_BASE__ placeholder if unset):
    CATALOG_BASE=https://pub-xxxx.r2.dev python3 scripts/build_catalog.py
"""
import hashlib, json, os, shutil, uuid, glob

BUCKET = "dist/r2-bucket"
SCREENSHOTS = "dist/screenshots"
# Public base URL of the bucket, e.g. CATALOG_BASE=https://pub-xxxx.r2.dev python3 scripts/build_catalog.py
BASE = os.environ.get("CATALOG_BASE", "__R2_BASE__").rstrip("/")
NS = uuid.UUID("c10c5eac-0000-4000-8000-000000000000")  # fixed namespace for stable ids
FONT_BOLD = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_REG = "/System/Library/Fonts/SFNS.ttf"

# key, name, author, category, template, accent(hex), tags
SAVERS = [
    ("WordClock",      "Word Clock",       "ClockSpace",          "clocks",     "words",   "#6ea8ff", ["words", "qlocktwo", "typography", "time"]),
    ("FlipClock",      None, None, None, None, None, None),  # skipped (no bundle)
    ("ColorClockSaver","Color Clock",       "Edward Loveall",      "clocks",     None,      "#7ee0c0", ["color", "minimal", "time"]),
    ("MinimalClock",   "Minimal Clock",     "Mattia Rossini",      "minimalist", "minimal", "#d0d0d0", ["minimal", "clean", "time"]),
    ("GridClock",      "Grid Clock",        "Christopher Newton",  "clocks",     None,      "#9b8cff", ["grid", "minimal", "time"]),
    ("EpochFlipClock", "Epoch Flip Clock",  "Christopher Newton",  "developer",  "flip",    "#ffb86b", ["epoch", "unix", "flip", "developer"]),
    ("Countdown",      "Countdown",         "Sam Soffes",          "minimalist", None,      "#ff7a90", ["countdown", "timer", "minimal"]),
    ("FractalClock",   "Fractal Clock",     "phreakocious",        "abstract",   None,      "#f0a0ff", ["fractal", "generative", "hands"]),
    ("October30",      "October 30",        "Julius Lekevicius",   "minimalist", None,      "#c0c8d0", ["date", "minimal"]),
    ("Octoscreen",     "Octoscreen",        "Steve Smith",         "developer",  None,      "#8affc1", ["github", "octocat", "developer"]),
    ("ScreenMazer",    "ScreenMazer",       "Alex Beals",          "abstract",   None,      "#7ec8ff", ["maze", "generative"]),
    ("WhatColourIsIt", "What Colour Is It", "Jon Combe",           "abstract",   None,      "#ffd36e", ["color", "hex", "time"]),
    # --- already-native keepers (arm64) + re-signed, staged from r2-upload ---
    ("Fliqlo",         "Fliqlo",            "Yuji Adachi",         "clocks",     "flip",    "#e6e6e6", ["flip", "clock", "classic"]),
    ("Matrix",         "Matrix",            "Monroe Williams",           "sciFi",      None,      "#57ff8f", ["matrix", "code", "rain"]),
    ("MultiClock",     "MultiClock",        "Brad Root",           "clocks",     None,      "#8ecbff", ["clock", "world", "multi"]),
    ("Today",          "Today",             "Matt Sephton",           "minimalist", None,      "#ffd36e", ["date", "today", "minimal"]),
    ("Ealain",         "Ealain",            "Brad Root",           "abstract",   None,      "#b0a0ff", ["art", "generative", "landscape"]),
    ("EmojiSaver",     "Emoji Saver",       "Klaas Hermanns",           "graphics",   None,      "#ffca6b", ["emoji", "fun", "colour"]),
    ("EmojiSaverLite", None, None, None, None, None, None),  # dropped 2026-11-24: crashes on start (its emoji-font code) on current macOS
    ("StartNow",       "Start Now",         "Polytime",           "minimalist", None,      "#7ee0c0", ["motivation", "minimal", "text"]),
    ("ForeverStars",   "Forever",           "Sami Eljabali",  "minimalist", None,      "#9b8cff", ["stars", "clock", "minimal"]),
    ("Fruit",          "Fruit",             "Corkscrews",           "nature",     None,      "#7ee0c0", ["fruit", "fun", "colour"]),
    ("OneClock",       "OneClock",          "xDEHANG",           "clocks",     None,      "#8affc1", ["clock", "minimal", "modern"]),
]

# Where each saver comes from and under which licence. "No licence stated" means the
# upstream repository has no licence file (all rights reserved by default).
GH = "https://github.com/"
SOURCES = {
    "WordClock":       (GH + "HARSHRAO729/ClockSpace",                       "PolyForm Noncommercial 1.0.0"),
    "ColorClockSaver": (GH + "edwardloveall/ColorClockSaver",                "MIT"),
    "MinimalClock":    (GH + "mattiarossini/MinimalClock",                   "MIT"),
    "GridClock":       (GH + "chrstphrknwtn/grid-clock-screensaver",         "No licence stated"),
    "EpochFlipClock":  (GH + "chrstphrknwtn/epoch-flip-clock-screensaver",   "No licence stated"),
    "Countdown":       (GH + "soffes/Countdown",                             "MIT"),
    "FractalClock":    (GH + "phreakocious/FractalClock",                    "No licence stated"),
    "October30":       (GH + "lekevicius/october30",                         "MIT"),
    "Octoscreen":      (GH + "orderedlist/octoscreen",                       "No licence stated"),
    "ScreenMazer":     (GH + "dado3212/ScreenMazer",                         "No licence stated"),
    "WhatColourIsIt":  (GH + "Jonic/WhatColourIsIt-ScreenSaver",             "No licence stated"),
    "Fliqlo":          ("https://fliqlo.com",                                "Freeware, closed source"),
    "Matrix":          (GH + "monroewilliams/MatrixDownload",                "No licence stated"),
    "MultiClock":      (GH + "amiantos/multiclock",                          "MPL-2.0"),
    "Today":           (GH + "gingerbeardman/today",                         "MIT"),
    "Ealain":          (GH + "amiantos/ealain",                              "MPL-2.0"),
    "EmojiSaver":      ("https://emojisaver.eu",                             "Freeware, closed source"),
    "EmojiSaverLite":  ("https://emojisaver.eu",                             "Freeware, closed source"),
    "StartNow":        (None,                                                "Closed source"),
    "ForeverStars":    (GH + "sami-eljabali/forever-stars-macos-screensaver", "MIT"),
    "Fruit":           (GH + "Corkscrews/fruit",                             "MIT"),
    "OneClock":        (None,                                                "Closed source"),
}

# How each bundle in the bucket was produced, for THIRD_PARTY.md.
BUILT_FROM_SOURCE = {"ColorClockSaver", "MinimalClock", "GridClock", "EpochFlipClock", "Countdown",
                     "FractalClock", "October30", "Octoscreen", "ScreenMazer", "WhatColourIsIt", "Fruit"}
RESIGNED_AD_HOC = {"ForeverStars", "OneClock"}  # original binary, signature replaced
PART_OF_CLOCKSPACE = {"WordClock"}

# Bundles with no Intel code (no source available to rebuild them universal).
# The app hides these on Intel Macs.
APPLE_SILICON_ONLY = {"OneClock", "StartNow"}

DESCR = {
    "WordClock": "Tells the time in words on a glowing letter grid.",
    "ColorClockSaver": "The screen becomes the time, rendered as a colour.",
    "MinimalClock": "An ultra-light clock stripped to the essentials.",
    "GridClock": "A precise, minimal grid-aligned clock.",
    "EpochFlipClock": "A flip clock counting Unix epoch seconds.",
    "Countdown": "A clean countdown to any date.",
    "FractalClock": "Recursive fractal clock hands blooming over time.",
    "October30": "A quiet, minimal date display.",
    "Octoscreen": "The GitHub Octocat, for your idle screen.",
    "ScreenMazer": "Endlessly generated mazes.",
    "WhatColourIsIt": "The current time as a live hex colour.",
    "Fliqlo": "The classic minimalist flip clock.",
    "Matrix": "Cascading green code, straight from the screen.",
    "MultiClock": "Several clocks at a glance.",
    "Today": "Today's date, kept beautifully simple.",
    "Ealain": "Slowly shifting generative landscapes.",
    "EmojiSaver": "A playful cascade of emoji.",
    "EmojiSaverLite": "A lighter take on the emoji saver.",
    "StartNow": "A gentle nudge to just begin.",
    "ForeverStars": "A modern, minimal star clock.",
    "Fruit": "Fresh, colourful fruit while you're away.",
    "OneClock": "A clean, modern single clock.",
}


def hexrgb(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def card(key, name, author, accent, W=640, H=400):
    from PIL import Image, ImageDraw, ImageFont  # only needed when there's no screenshot
    img = Image.new("RGB", (W, H), (13, 13, 15))
    d = ImageDraw.Draw(img)
    # subtle vertical gradient
    for y in range(H):
        v = 13 + int(10 * (y / H))
        d.line([(0, y), (W, y)], fill=(v, v, v + 2))
    ac = hexrgb(accent)
    d.rounded_rectangle([40, 40, W - 40, H - 40], radius=22, outline=(ac[0], ac[1], ac[2]), width=2)
    fn = ImageFont.truetype(FONT_BOLD, 58)
    fa = ImageFont.truetype(FONT_REG, 26)
    # wrap name to 2 lines if long
    d.text((W / 2, H / 2 - 24), name, font=fn, fill=(240, 240, 245), anchor="mm")
    d.text((W / 2, H / 2 + 40), author, font=fa, fill=(ac[0], ac[1], ac[2]), anchor="mm")
    d.rectangle([W / 2 - 26, H / 2 + 14, W / 2 + 26, H / 2 + 16], fill=(ac[0], ac[1], ac[2]))
    img.save(f"{BUCKET}/thumbnails/{key}.png")


def zip_size(key):
    p = f"{BUCKET}/savers/{key}.saver.zip"
    if not os.path.exists(p): return None
    mb = os.path.getsize(p) / 1_000_000
    return f"{mb:.1f} MB" if mb >= 1 else f"{os.path.getsize(p)//1024} KB"


def zip_sha256(key):
    p = f"{BUCKET}/savers/{key}.saver.zip"
    with open(p, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def write_third_party(savers):
    """Write THIRD_PARTY.md (repo root) from the same data as the catalog."""
    def how(key):
        if key in PART_OF_CLOCKSPACE: return "Part of ClockSpace"
        if key in BUILT_FROM_SOURCE: return "Built from the upstream source"
        if key in RESIGNED_AD_HOC: return "Original binary, re-signed ad hoc"
        return "Original binary, unchanged"
    lines = [
        "# Third-party screensavers",
        "",
        "ClockSpace downloads these screensavers from its CDN. Each one belongs to its author;",
        "ClockSpace only collects them in one place. Licence files are included in each download",
        "where the upstream project has one.",
        "",
        "\"No licence stated\" means the upstream repository has no licence file. Authors who",
        "would like their screensaver removed or credited differently can open an issue.",
        "",
        "This file is generated by `scripts/build_catalog.py`.",
        "",
        "| Screensaver | Author | Source | Licence | Build |",
        "|---|---|---|---|---|",
    ]
    for key, name, author in sorted(savers, key=lambda s: s[1].lower()):
        url, lic = SOURCES.get(key, (None, "Unknown"))
        src = f"[{url.split('//', 1)[1]}]({url})" if url else "Not public"
        lines.append(f"| {name} | {author} | {src} | {lic} | {how(key)} |")
    open("THIRD_PARTY.md", "w").write("\n".join(lines) + "\n")
    print(f"wrote THIRD_PARTY.md ({len(savers)} entries)")


def main():
    os.makedirs(f"{BUCKET}/thumbnails", exist_ok=True)
    catalog, rank = [], 0
    for key, name, author, cat, tmpl, accent, tags in SAVERS:
        if name is None or not os.path.exists(f"{BUCKET}/savers/{key}.saver.zip"):
            continue
        # Real screenshot if there is one (.png for flat graphics, .jpg for photo-like ones),
        # otherwise a generated name card.
        shot = next((p for p in (f"{SCREENSHOTS}/{key}.png", f"{SCREENSHOTS}/{key}.jpg") if os.path.exists(p)), None)
        thumb = f"{key}{os.path.splitext(shot)[1]}" if shot else f"{key}.png"
        if shot:
            shutil.copyfile(shot, f"{BUCKET}/thumbnails/{thumb}")
        elif not os.path.exists(f"{BUCKET}/thumbnails/{thumb}"):
            card(key, name, author, accent)  # name cards never change, so an existing one is kept
        rank += 1
        catalog.append({
            "id": str(uuid.uuid5(NS, key)),
            "name": name,
            "description": DESCR.get(key, ""),
            "category": cat,
            "thumbnailURL": f"{BASE}/thumbnails/{thumb}",
            "downloadURL": f"{BASE}/savers/{key}.saver.zip",
            "isPremium": False,
            "price": None,
            "author": author,
            "downloadCount": 0,
            "tags": tags,
            "createdAt": "2026-08-09T00:00:00Z",
            "rank": rank if rank <= 3 else None,
            "resolution": "Vector",
            "fileSize": zip_size(key),
            "sha256": zip_sha256(key),
            "sourceURL": SOURCES.get(key, (None, None))[0],
            "license": SOURCES.get(key, (None, None))[1],
            "appleSiliconOnly": key in APPLE_SILICON_ONLY,
            "isNew": True,
            "template": tmpl,
        })
    json.dump(catalog, open(f"{BUCKET}/catalog.json", "w"), indent=2, ensure_ascii=False)
    write_third_party([(k, n, a) for k, n, a, *_ in SAVERS if n and os.path.exists(f"{BUCKET}/savers/{k}.saver.zip")])
    print(f"wrote {BUCKET}/catalog.json with {len(catalog)} savers + {len(catalog)} thumbnails")
    for c in catalog:
        print(f"  {c['name']:<20} {c['category']:<12} {c['fileSize']}")


if __name__ == "__main__":
    main()
