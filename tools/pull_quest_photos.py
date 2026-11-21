#!/usr/bin/env python3
"""Pull Quest 3 photographs (user://quest_photos and user://opera_journal) to ada_run/quest-photos via ADB."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADB = Path.home() / "AppData/Local/Android/Sdk/platform-tools/adb.exe"
PKG = "com.example.adaresearchzeroone"
OUT = ROOT / "ada_run" / "quest-photos"


def adb_run(serial: str, *args: str, binary: bool = False):
    p = subprocess.run([str(ADB), "-s", serial, *args], capture_output=True, timeout=60)
    if p.returncode != 0:
        return None
    return p.stdout if binary else p.stdout.decode("utf-8", errors="replace")


def find_serial() -> str | None:
    p = subprocess.run([str(ADB), "devices"], capture_output=True, text=True, timeout=15)
    found = [ln.split()[0] for ln in p.stdout.splitlines()[1:] if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    if "2G0YC5ZG4M0569" in found:
        return "2G0YC5ZG4M0569"
    return found[0] if found else None


def main() -> int:
    serial = find_serial()
    if not serial:
        print("No Quest device attached over ADB.", file=sys.stderr)
        return 2
    OUT.mkdir(parents=True, exist_ok=True)
    pulled = []
    for remote_root, img_name, meta_name in [
        ("files/quest_photos", "photo.jpg", "meta.json"),
        ("files/opera_journal", "view.jpg", "entry.json"),
    ]:
        listing = adb_run(serial, "shell", "run-as", PKG, "ls", remote_root)
        if not listing:
            continue
        for entry in [x.strip() for x in listing.splitlines() if x.strip() and not x.startswith("ls:")]:
            dest_dir = OUT / entry
            dest_img = dest_dir / img_name
            if dest_img.exists() and dest_img.stat().st_size > 1000:
                continue
            raw = adb_run(serial, "exec-out", "run-as", PKG, "cat", f"{remote_root}/{entry}/{img_name}", binary=True)
            if not raw or len(raw) < 1000:
                continue
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest_img.write_bytes(raw)
            meta = adb_run(serial, "shell", "run-as", PKG, "cat", f"{remote_root}/{entry}/{meta_name}")
            if meta:
                (dest_dir / meta_name).write_text(meta, encoding="utf-8")
            pulled.append(str(dest_img))
    print(json.dumps({"serial": serial, "pulled_count": len(pulled), "pulled": pulled}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
