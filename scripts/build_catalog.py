#!/usr/bin/env python3
"""
Generate dist/r2-bucket/catalog.json + uniform gallery thumbnails for the working
saver set. Thumbnails are clean name-cards (640x400) so the in-app gallery reads as
one system. URLs use the BASE placeholder — rewrite it once the R2 URL is known:
    sed -i '' 's#__R2_BASE__#https://pub-xxxx.r2.dev#g' dist/r2-bucket/catalog.json
"""
import json, os, uuid, glob
from PIL import Image, ImageDraw, ImageFont

BUCKET = "dist/r2-bucket"
BASE = "__R2_BASE__"
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
    ("Octoscreen",     "Octoscreen",        "orderedlist",         "developer",  None,      "#8affc1", ["github", "octocat", "developer"]),
    ("ScreenMazer",    "ScreenMazer",       "Alex Beals",          "abstract",   None,      "#7ec8ff", ["maze", "generative"]),
    ("WhatColourIsIt", "What Colour Is It", "Jon Combe",           "abstract",   None,      "#ffd36e", ["color", "hex", "time"]),
    # --- already-native keepers (arm64) + re-signed, staged from r2-upload ---
    ("Fliqlo",         "Fliqlo",            "Yuji Adachi",         "clocks",     "flip",    "#e6e6e6", ["flip", "clock", "classic"]),
    ("Matrix",         "Matrix",            "Community",           "sciFi",      None,      "#57ff8f", ["matrix", "code", "rain"]),
    ("MultiClock",     "MultiClock",        "Community",           "clocks",     None,      "#8ecbff", ["clock", "world", "multi"]),
    ("Today",          "Today",             "Community",           "minimalist", None,      "#ffd36e", ["date", "today", "minimal"]),
    ("Ealain",         "Ealain",            "Community",           "abstract",   None,      "#b0a0ff", ["art", "generative", "landscape"]),
    ("EmojiSaver",     "Emoji Saver",       "Community",           "graphics",   None,      "#ffca6b", ["emoji", "fun", "colour"]),
    ("EmojiSaverLite", "Emoji Saver Lite",  "Community",           "graphics",   None,      "#ffb86b", ["emoji", "fun", "minimal"]),
    ("StartNow",       "Start Now",         "Community",           "minimalist", None,      "#7ee0c0", ["motivation", "minimal", "text"]),
    ("ForeverStars",   "Forever",           "Forever Stars Team",  "minimalist", None,      "#9b8cff", ["stars", "clock", "minimal"]),
    ("Fruit",          "Fruit",             "Community",           "nature",     None,      "#7ee0c0", ["fruit", "fun", "colour"]),
    ("OneClock",       "OneClock",          "Community",           "clocks",     None,      "#8affc1", ["clock", "minimal", "modern"]),
]

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


def main():
    os.makedirs(f"{BUCKET}/thumbnails", exist_ok=True)
    catalog, rank = [], 0
    for key, name, author, cat, tmpl, accent, tags in SAVERS:
        if name is None or not os.path.exists(f"{BUCKET}/savers/{key}.saver.zip"):
            continue
        card(key, name, author, accent)
        rank += 1
        catalog.append({
            "id": str(uuid.uuid5(NS, key)),
            "name": name,
            "description": DESCR.get(key, ""),
            "category": cat,
            "thumbnailURL": f"{BASE}/thumbnails/{key}.png",
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
            "isNew": True,
            "template": tmpl,
        })
    json.dump(catalog, open(f"{BUCKET}/catalog.json", "w"), indent=2, ensure_ascii=False)
    print(f"wrote {BUCKET}/catalog.json with {len(catalog)} savers + {len(catalog)} thumbnails")
    for c in catalog:
        print(f"  {c['name']:<20} {c['category']:<12} {c['fileSize']}")


if __name__ == "__main__":
    main()
