#!/usr/bin/env python3
"""
Audit every .saver.zip in ./r2-upload/savers/ for macOS 26 (Apple Silicon)
compatibility. The dominant breakage on modern macOS is a screensaver bundle
that has no arm64 slice (x86_64/i386 only) — it runs, if at all, under Rosetta's
flaky legacyScreenSaver host. Secondary signals: missing/adhoc code signature.

Classification:
  BROKEN  - no arm64 slice (won't run natively on Apple Silicon)
  RISKY   - arm64 present but unsigned / adhoc-signed (Gatekeeper friction)
  OK      - arm64 present and Developer-ID / valid signature

Outputs a table to stdout and a machine-readable r2-upload/_saver_audit.json.
"""
import glob, json, os, plistlib, subprocess, tempfile, zipfile

SAVERS = "r2-upload/savers"


def sh(cmd: list[str]) -> tuple[int, str]:
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr)


def find_bundle(root: str) -> str | None:
    for dirpath, dirs, _ in os.walk(root):
        for d in dirs:
            if d.endswith(".saver"):
                return os.path.join(dirpath, d)
    return None


def audit_one(zip_path: str) -> dict:
    name = os.path.basename(zip_path)
    rec = {"zip": name, "status": "BROKEN", "archs": "", "signed": "", "minOS": "",
           "principal": "", "version": "", "note": ""}
    with tempfile.TemporaryDirectory() as tmp:
        try:
            with zipfile.ZipFile(zip_path) as z:
                z.extractall(tmp)
        except Exception as e:  # noqa: BLE001
            rec["note"] = f"unzip failed: {e}"
            return rec
        bundle = find_bundle(tmp)
        if not bundle:
            rec["note"] = "no .saver bundle inside"
            return rec
        info_path = os.path.join(bundle, "Contents", "Info.plist")
        exe = None
        try:
            info = plistlib.load(open(info_path, "rb"))
            exe = info.get("CFBundleExecutable")
            rec["principal"] = info.get("NSPrincipalClass", "")
            rec["minOS"] = str(info.get("LSMinimumSystemVersion", ""))
            rec["version"] = str(info.get("CFBundleShortVersionString", ""))
        except Exception as e:  # noqa: BLE001
            rec["note"] = f"no Info.plist ({e}); "
        binpath = os.path.join(bundle, "Contents", "MacOS", exe) if exe else None
        if not binpath or not os.path.exists(binpath):
            # fall back to whatever single file is in MacOS/
            macos = os.path.join(bundle, "Contents", "MacOS")
            files = os.listdir(macos) if os.path.isdir(macos) else []
            binpath = os.path.join(macos, files[0]) if files else None
        if not binpath or not os.path.exists(binpath):
            rec["note"] += "no executable found"
            return rec
        _, archs = sh(["lipo", "-archs", binpath])
        rec["archs"] = archs.strip()
        code, cs = sh(["codesign", "-dvv", binpath])
        line = next((l for l in cs.splitlines() if l.startswith("Authority=")), "")
        if "not signed" in cs or code != 0 and "code object is not signed" in cs:
            rec["signed"] = "unsigned"
        elif "adhoc" in cs.lower():
            rec["signed"] = "adhoc"
        elif line:
            rec["signed"] = line.replace("Authority=", "")[:40]
        else:
            rec["signed"] = "unknown"

        has_arm = "arm64" in rec["archs"]
        signed_ok = rec["signed"] not in ("unsigned", "adhoc", "unknown", "")
        if not has_arm:
            rec["status"] = "BROKEN"
            rec["note"] += "no arm64 slice"
        elif not signed_ok:
            rec["status"] = "RISKY"
            rec["note"] += "arm64 ok but signature weak"
        else:
            rec["status"] = "OK"
    return rec


def main() -> int:
    zips = sorted(glob.glob(os.path.join(SAVERS, "*.saver.zip")))
    if not zips:
        print(f"no .saver.zip in {SAVERS}")
        return 1
    results = [audit_one(z) for z in zips]
    order = {"BROKEN": 0, "RISKY": 1, "OK": 2}
    results.sort(key=lambda r: (order.get(r["status"], 3), r["zip"].lower()))
    w = max(len(r["zip"]) for r in results)
    print(f"\n{'STATUS':7} {'ARCHS':16} {'SIGNED':10} {'zip'.ljust(w)}  note")
    print("-" * (7 + 16 + 10 + w + 12))
    for r in results:
        print(f"{r['status']:7} {r['archs'][:15]:16} {r['signed'][:9]:10} "
              f"{r['zip'].ljust(w)}  {r['note']}")
    counts = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print("\nSUMMARY:", counts)
    json.dump(results, open(os.path.join("r2-upload", "_saver_audit.json"), "w"), indent=2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
