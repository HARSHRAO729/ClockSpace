#!/usr/bin/env python3
"""
Audit every .saver.zip in the bucket folder (default: dist/r2-bucket/savers).

Per bundle it reports CPU architectures, the signer, whether the signature
verifies, and whether a LICENSE file ships in the zip.

Status:
  BROKEN  - no bundle, no arm64 code, or the signature fails `codesign --verify --deep --strict`
  WARN    - works, but Apple Silicon only (no x86_64), or signed with a personal
            "Apple Development" certificate (that embeds the developer's email)
  OK      - everything else

Usage:  python3 scripts/audit_savers.py [folder]
Exit code is 1 if any bundle is BROKEN, so this can run in CI.
"""
import glob, os, plistlib, subprocess, sys, tempfile, zipfile


def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def find_bundle(root):
    for dirpath, dirs, _ in os.walk(root):
        dirs[:] = [d for d in dirs if d != "__MACOSX"]
        for d in dirs:
            if d.endswith(".saver"):
                return os.path.join(dirpath, d)
    return None


def audit(zip_path):
    rec = {"zip": os.path.basename(zip_path), "status": "BROKEN", "archs": "", "signer": "",
           "license": "no", "notes": []}
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["ditto", "-xk", zip_path, tmp], check=False)
        rec["license"] = "yes" if any(n.upper().startswith("LICENSE")
                                      for n in zipfile.ZipFile(zip_path).namelist()) else "no"
        bundle = find_bundle(tmp)
        if not bundle:
            rec["notes"].append("no .saver bundle inside")
            return rec
        try:
            info = plistlib.load(open(os.path.join(bundle, "Contents", "Info.plist"), "rb"))
            exe = os.path.join(bundle, "Contents", "MacOS", info["CFBundleExecutable"])
        except Exception as e:  # noqa: BLE001
            rec["notes"].append(f"bad Info.plist ({e})")
            return rec
        _, archs = run(["lipo", "-archs", exe])
        rec["archs"] = archs.strip()
        _, details = run(["codesign", "-dvv", bundle])
        authority = next((l[len("Authority="):] for l in details.splitlines() if l.startswith("Authority=")), "")
        rec["signer"] = authority.split(" (")[0] if authority else ("ad hoc" if "adhoc" in details else "unsigned")
        verified = run(["codesign", "--verify", "--deep", "--strict", bundle])[0] == 0

        if "arm64" not in rec["archs"]:
            rec["notes"].append("no arm64 code")
        if not verified:
            rec["notes"].append("signature does not verify")
        if rec["notes"]:
            return rec
        rec["status"] = "OK"
        if "x86_64" not in rec["archs"]:
            rec["status"] = "WARN"
            rec["notes"].append("Apple Silicon only")
        if rec["signer"].startswith("Apple Development:"):
            rec["status"] = "WARN"
            rec["notes"].append("personal development certificate (contains an email)")
    return rec


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else "dist/r2-bucket/savers"
    zips = sorted(glob.glob(os.path.join(folder, "*.saver.zip")))
    if not zips:
        print(f"no .saver.zip in {folder}")
        return 1
    results = [audit(z) for z in zips]
    print(f"{'STATUS':7} {'ARCHS':14} {'LIC':4} {'SIGNER':34} ZIP / NOTES")
    for r in results:
        signer = r["signer"].split(":")[0] if r["signer"].startswith("Apple Development:") else r["signer"]
        print(f"{r['status']:7} {r['archs'][:13]:14} {r['license']:4} {signer[:33]:34} {r['zip']}  {'; '.join(r['notes'])}")
    counts = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print("\nSUMMARY:", counts)
    return 1 if counts.get("BROKEN") else 0


if __name__ == "__main__":
    raise SystemExit(main())
