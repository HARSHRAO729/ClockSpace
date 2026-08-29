#!/usr/bin/env python3
"""
Re-point catalog.json asset URLs from Firebase Storage to the Cloudflare R2
public base. Reuses the existing object key (the path after /o/), so keys line
up 1:1 with what rescue/gsutil put in ./r2-upload/.

Usage:
    python3 scripts/repoint_catalog.py https://pub-xxxx.r2.dev

Result: rewrites ClockSpaceApp/Resources/catalog.json in place. Upload the same
file to R2 as catalog.json so the app's remote fetch and bundled fallback match.
Re-runnable and idempotent (already-R2 URLs with the given base are left as-is).
"""
import json, os, re, sys, urllib.parse

CATALOG = "ClockSpaceApp/Resources/catalog.json"
ASSETS = "r2-upload"  # local mirror of what will be uploaded to R2


def key_from_firebase(url: str) -> str | None:
    if "/o/" not in url:
        return None
    return urllib.parse.unquote(url.split("/o/", 1)[1].split("?", 1)[0])


def have_local(key: str | None) -> bool:
    """True if the asset for this key actually exists in ./r2-upload/."""
    if not key:
        return False
    p = os.path.join(ASSETS, key)
    return os.path.exists(p) and os.path.getsize(p) > 0


def repoint(url: str, base: str) -> str:
    if not url or url.startswith(base):
        return url
    key = key_from_firebase(url)
    if key is None:
        return url  # local:// or already-migrated; leave untouched
    return f"{base}/{urllib.parse.quote(key)}"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: repoint_catalog.py <R2_PUBLIC_BASE_URL>")
        return 2
    base = sys.argv[1].rstrip("/")
    if not re.match(r"^https://", base):
        print("base must be an https:// URL")
        return 2

    savers = json.load(open(CATALOG))

    # Prune entries whose saver file doesn't exist locally (== won't exist on R2).
    # These were already dead on Firebase (404). A missing thumbnail alone is kept.
    kept, dropped = [], []
    for s in savers:
        if have_local(key_from_firebase(s.get("downloadURL", ""))):
            kept.append(s)
        else:
            dropped.append(s["name"])

    changed = 0
    for s in kept:
        for field in ("downloadURL", "thumbnailURL"):
            new = repoint(s.get(field, ""), base)
            if new != s.get(field):
                s[field] = new
                changed += 1

    json.dump(kept, open(CATALOG, "w"), indent=2, ensure_ascii=False)
    print(f"Kept {len(kept)} savers, dropped {len(dropped)} dead entries: {dropped}")
    print(f"Rewrote {changed} URLs -> {base}")
    print(f"Now upload {CATALOG} to R2 as 'catalog.json', and set catalogURL in APIManager.swift.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
