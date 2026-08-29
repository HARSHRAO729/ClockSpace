#!/usr/bin/env python3
"""
Rescue every screensaver asset + thumbnail out of Firebase Storage into a local
./r2-upload/ folder, preserving the object path so the same keys can be uploaded
straight to Cloudflare R2.

Firebase download URLs look like:
  https://firebasestorage.googleapis.com/v0/b/<bucket>/o/savers%2Ffile.mp4?alt=media&token=...
The object key is the URL-decoded segment between "/o/" and "?".

Run:  python3 scripts/rescue_assets.py
Re-runnable: already-downloaded files of the right size are skipped.
"""
import json, os, subprocess, sys, urllib.parse

CATALOG = "ClockSpaceApp/Resources/catalog.json"
OUTDIR = "r2-upload"


def object_key(url: str) -> str | None:
    """Extract the Storage object path (the future R2 key) from a Firebase URL."""
    if "/o/" not in url:
        return None
    enc = url.split("/o/", 1)[1].split("?", 1)[0]
    return urllib.parse.unquote(enc)


def download(url: str, dest: str) -> str:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        return "skip"
    # curl uses the system trust store (system Python's urllib lacks a CA bundle),
    # follows redirects, fails loudly on HTTP errors, and retries transient ones.
    subprocess.run(
        ["curl", "-fsSL", "--retry", "3", "-o", dest, url],
        check=True,
    )
    return "ok"


def main() -> int:
    savers = json.load(open(CATALOG))
    keys = {}  # url -> key, to also emit a mapping file
    ok = skip = fail = 0
    for i, s in enumerate(savers, 1):
        for field in ("downloadURL", "thumbnailURL"):
            url = s.get(field) or ""
            if not url.startswith("https://firebasestorage"):
                continue
            key = object_key(url)
            if not key:
                print(f"  ⚠️  no key for {s.get('name')} {field}")
                fail += 1
                continue
            keys[url] = key
            dest = os.path.join(OUTDIR, key)
            try:
                r = download(url, dest)
                if r == "ok":
                    ok += 1
                    print(f"[{i}/{len(savers)}] ⬇  {key}")
                else:
                    skip += 1
            except Exception as e:  # noqa: BLE001
                fail += 1
                print(f"  ❌ {key}: {e}")
    json.dump(keys, open(os.path.join(OUTDIR, "_url_to_key.json"), "w"), indent=2)
    print(f"\nDone. downloaded={ok} skipped={skip} failed={fail}")
    print(f"Files in ./{OUTDIR}/ — upload that folder's contents to your R2 bucket root.")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
