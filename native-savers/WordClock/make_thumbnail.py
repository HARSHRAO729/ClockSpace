#!/usr/bin/env python3
"""Render Word Clock's gallery thumbnail (90x58 + @2x 180x116) to match the saver:
black field, dim letter grid, the words for 2:10 ('IT IS TEN PAST TWO') lit white."""
from PIL import Image, ImageDraw, ImageFont

GRID = ["ITLISASAMPM", "ACQUARTERDC", "TWENTYFIVEX", "HALFSTENFTO", "PASTERUNINE",
        "ONESIXTHREE", "FOURFIVETWO", "EIGHTELEVEN", "SEVENTWELVE", "TENSEOCLOCK"]
LIT = {(0, 0), (0, 1), (0, 3), (0, 4),            # IT IS
       (3, 5), (3, 6), (3, 7),                     # TEN
       (4, 0), (4, 1), (4, 2), (4, 3),             # PAST
       (6, 8), (6, 9), (6, 10)}                     # TWO
FONT = "/System/Library/Fonts/Menlo.ttc"
COLS, ROWS, HGAP, VGAP, FIT = 11, 10, 0.30, 0.32, 0.88


def render(W, H, ss=4):
    w, h = W * ss, H * ss
    img = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(img)
    cell = min(w * FIT / (COLS + (COLS - 1) * HGAP), h * FIT / (ROWS + (ROWS - 1) * VGAP))
    font = ImageFont.truetype(FONT, max(6, int(cell * 0.62)))
    gw = COLS * cell + (COLS - 1) * HGAP * cell
    gh = ROWS * cell + (ROWS - 1) * VGAP * cell
    x0, y0 = (w - gw) / 2, (h - gh) / 2
    for r in range(ROWS):
        for c in range(COLS):
            on = (r, c) in LIT
            cx = x0 + c * (cell + HGAP * cell) + cell / 2
            cy = y0 + r * (cell + VGAP * cell) + cell / 2
            d.text((cx, cy), GRID[r][c], font=font,
                   fill=(255, 255, 255) if on else (38, 38, 38), anchor="mm")
    return img.resize((W, H), Image.LANCZOS)


render(90, 58).save("native-savers/WordClock/thumbnail.png")
render(180, 116).save("native-savers/WordClock/thumbnail@2x.png")
print("wrote native-savers/WordClock/thumbnail.png + @2x")
