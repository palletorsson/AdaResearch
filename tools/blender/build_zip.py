"""build_zip.py — zip tools/blender/ada_void into an installable Blender add-on.

  python tools/blender/build_zip.py            -> ada_run/ada_void_blender_addon.zip
  python tools/blender/build_zip.py --install  -> also installs + enables it in Blender 4.2
                                                  (blender -b, the user's scripts/addons)

Blender 4.2: Edit › Preferences › Add-ons › (v) › Install from Disk… and pick the zip.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools" / "blender" / "ada_void"
BLENDER = os.environ.get("BLENDER_EXE", r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe")


def build(out: Path) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for p in sorted(SRC.rglob("*")):
            if p.is_dir() or "__pycache__" in p.parts or p.suffix == ".pyc":
                continue
            z.write(p, Path("ada_void") / p.relative_to(SRC))
    return out


def install(zip_path: Path) -> int:
    expr = (
        "import bpy;"
        f"bpy.ops.preferences.addon_install(filepath=r'{zip_path}', overwrite=True);"
        "bpy.ops.preferences.addon_enable(module='ada_void');"
        "bpy.ops.wm.save_userpref();"
        "print('ADA_VOID_INSTALLED', 'ada_void' in bpy.context.preferences.addons, bpy.utils.user_resource('SCRIPTS', path='addons'))"
    )
    r = subprocess.run([BLENDER, "-b", "--python-expr", expr], capture_output=True, text=True, encoding="utf-8", errors="replace")
    for line in r.stdout.splitlines():
        if "ADA_VOID_INSTALLED" in line or "Error" in line or "Traceback" in line:
            print(line)
    return 0 if "ADA_VOID_INSTALLED True" in r.stdout else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "ada_run" / "ada_void_blender_addon.zip"))
    ap.add_argument("--install", action="store_true")
    a = ap.parse_args()
    z = build(Path(a.out))
    print(f"wrote {z} ({z.stat().st_size // 1024} KB)")
    sys.exit(install(z) if a.install else 0)
