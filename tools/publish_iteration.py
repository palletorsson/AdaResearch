#!/usr/bin/env python3
"""Publish a capture set to the encyclopedia as one dated ITERATION.

The spatial pipeline has produced diagrams, numbers, gates and captures for a
whole pass, and none of it was ever visible in one place while it changed. This
makes each run a row you can look at: N images, what they were of, what the
numbers said that day, and what changed since the run before.

An iteration is a DIRECTORY, never an overwrite. The point is the sequence — a
gallery that only shows the newest frame cannot answer "did that get better",
which is the question the pictures exist to settle.

Captures land in Godot's user dir (Roaming, not Local):
    %APPDATA%/Godot/app_userdata/Ada Research Zero One/

    python tools/publish_iteration.py --label="plan wired" --from=user://em
    python tools/publish_iteration.py --label="wave 2" --from=multi_shots/uffizi
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ENCY = Path("C:/Users/palle/Documents/GitHub/ada_encyclopedia")
GALLERY = ENCY / "public" / "spatial-iterations"
MANIFEST = GALLERY / "index.json"
USERDIR = Path("C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One")

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}


def _resolve(src: str) -> Path:
    """`user://x`, an absolute path, or a path relative to the Godot user dir."""
    if src.startswith("user://"):
        return USERDIR / src[7:]
    p = Path(src)
    return p if p.is_absolute() else (USERDIR / src)


def _facts() -> dict:
    """Numbers worth stamping on the iteration, read fresh, never guessed.

    Read from files rather than passed on the command line: a number typed into
    a caption is a claim about a run, and this whole pass has been a lesson in
    what happens when the caption and the run drift apart.
    """
    out: dict = {}
    plan = REPO / "ada_run" / "em_plan.json"
    if plan.exists():
        try:
            d = json.loads(plan.read_text(encoding="utf-8"))
            ms = d.get("museums", {})
            arts = [a for m in ms.values() for a in m.get("artifacts", [])]
            out["museums_planned"] = len(ms)
            out["placements"] = len(arts)
            out["interior"] = sum(1 for a in arts if a.get("venue") == "interior")
            out["rejected"] = sum(len(m.get("rejected", [])) for m in ms.values())
        except Exception as exc:
            out["plan_error"] = str(exc)
    rooms = REPO / "commons" / "artifacts" / "dressing_rooms"
    if rooms.is_dir():
        files = list(rooms.glob("*.json"))
        gen = 0
        for f in files:
            try:
                if "_generated" in json.loads(f.read_text(encoding="utf-8")):
                    gen += 1
            except Exception:
                pass
        out["dressing_rooms"] = len(files)
        out["generated_rooms"] = gen
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--label", required=True, help="what this iteration tried")
    ap.add_argument("--from", dest="src", required=True,
                    help="user://dir, an image, or a dir under the Godot user dir")
    ap.add_argument("--note", default="", help="what to look for in these frames")
    ap.add_argument("--slug", default="", help="defaults to a timestamp")
    args = ap.parse_args()

    src = _resolve(args.src)
    if not src.exists():
        print(f"nothing at {src}", file=sys.stderr)
        return 2
    images = ([src] if src.is_file()
              else sorted(p for p in src.rglob("*") if p.suffix.lower() in IMAGE_SUFFIXES))
    if not images:
        print(f"no images under {src}", file=sys.stderr)
        return 2

    stamp = datetime.now()
    slug = args.slug or stamp.strftime("%Y%m%d-%H%M%S")
    dest = GALLERY / slug
    dest.mkdir(parents=True, exist_ok=True)

    shots = []
    for img in images:
        name = img.name
        # flatten, but keep the parent when it disambiguates (angle dirs)
        if img.parent != src and not img.is_file() or img.parent != src:
            name = f"{img.parent.name}__{img.name}"
        shutil.copy2(img, dest / name)
        shots.append({"file": name, "bytes": img.stat().st_size,
                      "source": str(img.relative_to(USERDIR))
                      if USERDIR in img.parents else str(img)})

    entry = {
        "slug": slug,
        "label": args.label,
        "note": args.note,
        "at": stamp.isoformat(timespec="seconds"),
        "shots": shots,
        "facts": _facts(),
    }

    index = {"schema": "adaresearch.spatial_iterations.v1", "iterations": []}
    if MANIFEST.exists():
        try:
            index = json.loads(MANIFEST.read_text(encoding="utf-8"))
        except Exception:
            pass
    # newest first, and a re-publish of the same slug REPLACES rather than
    # duplicates, so re-running a capture does not fork the history.
    index["iterations"] = ([entry] +
                           [i for i in index.get("iterations", []) if i.get("slug") != slug])
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")

    print(f"iteration {slug}: {len(shots)} image(s) -> {dest}")
    for k, v in entry["facts"].items():
        print(f"   {k:20s} {v}")
    print(f"\n   http://localhost:3003/spatial-iterations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
