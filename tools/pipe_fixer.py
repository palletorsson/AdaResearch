#!/usr/bin/env python
"""
pipe_fixer.py — auto-research loop that fixes empty-ish pipe renders.

Every config in commons/audio/pipe_configs/*.json is rendered by
capture_pipe_system.gd with the default camera + lighting. Many big_pipe
renders come out nearly blank because the default camera framing assumes
glass-rack scale and undershoots for 50x-larger drain pipes, or the
lighting is too dim for the matte pipe material.

This tool iterates: for each config whose current render has fewer than
MIN_COLORS unique colors (thus empty-ish), it tries a fixed set of
camera + lighting variations, keeps the one that produces the most
image content, and writes the winner to the gallery.

Variations are passed to capture_pipe_system.gd as user args:
  --cam_distance_mult=<float>    (default 1.6)
  --cam_elevation=<float>        (default 0.5)
  --cam_azimuth=<float>          (default 0.7)
  --cam_forward=<float>          (default 0.9)
  --key_boost=<float>            (default 1.0)
  --ambient_boost=<float>        (default 1.0)

Output: public/pipes-auto-gallery/<id>.png updated in place.
        tools/pipe_fixer_log.json records best params per token.

Usage::

    python tools/pipe_fixer.py                       # all empty-ish big_pipes
    python tools/pipe_fixer.py --system big_pipe     # only big
    python tools/pipe_fixer.py --token big_straight_5af8a  # one specific
    python tools/pipe_fixer.py --min-colors 600      # stricter threshold
    python tools/pipe_fixer.py --dry-run             # list what would run
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
ENCYC = Path(os.environ.get("ADA_ENCYCLOPEDIA", str(REPO.parent / "ada_encyclopedia")))
GALLERY = ENCYC / "public" / "pipes-auto-gallery"
CONFIGS = REPO / "commons" / "audio" / "pipe_configs"
LOG_FILE = REPO / "tools" / "pipe_fixer_log.json"

GODOT_EXE = os.environ.get("GODOT_EXE",
    r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
CAPTURE_SCRIPT = "res://commons/testing/capture_pipe_system.gd"

# ── Variation search space ───────────────────────────────────────────────
# Ordered by likelihood of helping. The first entry is the default (control).

VARIATIONS = [
    # label, dict of extra args
    ("default",        {}),
    # Pull CLOSER — for thin-tube glass configs, the default distance
    # makes pipes into barely-visible lines. Closer = more pixels per pipe.
    ("close",          {"cam_distance_mult": 1.0}),
    ("closer",         {"cam_distance_mult": 0.7}),
    ("point_blank",    {"cam_distance_mult": 0.5}),
    # Closer + brighter for thin glass
    ("close_bright",   {"cam_distance_mult": 0.8, "key_boost": 2.0, "ambient_boost": 1.8}),
    # Pull BACK — for big_pipe elongated shapes
    ("far",            {"cam_distance_mult": 2.5}),
    ("farther",        {"cam_distance_mult": 4.0}),
    # High 3/4 view
    ("high_34",        {"cam_distance_mult": 1.5, "cam_elevation": 1.0}),
    # Low angle
    ("low_angle",      {"cam_distance_mult": 1.2, "cam_elevation": -0.3}),
    # Isometric
    ("iso",            {"cam_distance_mult": 1.5, "cam_elevation": 0.7, "cam_azimuth": 0.7, "cam_forward": 0.7}),
    # Frontal
    ("front",          {"cam_distance_mult": 1.5, "cam_azimuth": 0.1, "cam_elevation": 0.2, "cam_forward": 1.5}),
    # Bright wash
    ("bright",         {"cam_distance_mult": 1.2, "key_boost": 2.5, "ambient_boost": 2.0}),
]


def image_content_score(png_path: Path) -> int:
    """Percentage of non-background pixels in a 128x128 downsample (0..1000).
    Measures actual pipe coverage, not color complexity. A smooth cylinder
    filling 30% of the frame scores ~300; an empty dark image scores ~0.

    Previous metric used unique-color count, which under-ranked simple
    geometry with lots of uniform shading (a monochrome straight pipe
    might fill 30% of the frame but only show 300 distinct colors, looking
    'empty' to that metric while actually being the most-filled render).
    """
    try:
        from PIL import Image
    except ImportError:
        try:
            return png_path.stat().st_size // 100
        except Exception:
            return 0
    try:
        img = Image.open(png_path).convert("RGB").resize((128, 128))
        pipe_pixels = 0
        for r, g, b in img.getdata():
            # Background is intentionally dark (0.06,0.07,0.09 → ~15,18,23).
            # Threshold 35 on each channel catches the ambient + any edge
            # anti-aliasing, so we count only pixels that clearly belong to
            # geometry (pipes, segment caps, labels if any).
            if r > 35 or g > 35 or b > 35:
                pipe_pixels += 1
        total = 128 * 128
        # Scale to a comparable integer: 0-1000, where 1000 = 100% pipe
        return int(pipe_pixels * 1000 / total)
    except Exception:
        return 0


def render_once(config_rel: str, out_abs: Path, extra_args: dict, timeout: int) -> bool:
    """Run Godot once with the given extra args. Returns True if it wrote a PNG."""
    user_out = f"user://pipes/_fixer_{int(time.time()*1000)}.png"
    user_out_path = _godot_user_path(user_out)

    cmd = [
        GODOT_EXE, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", CAPTURE_SCRIPT, "--no-bridges", "--",
        f"--config=res://{config_rel}",
        f"--out={user_out}",
    ]
    for k, v in extra_args.items():
        cmd.append(f"--{k}={v}")

    try:
        subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                       encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return False

    # Godot wrote to user_out_path; copy it to out_abs if present
    if not user_out_path.exists():
        return False
    try:
        shutil.copy2(user_out_path, out_abs)
        user_out_path.unlink(missing_ok=True)
        return True
    except Exception:
        return False


def _godot_user_path(user_url: str) -> Path:
    """user:// → OS path on Windows / macOS / Linux."""
    names = ["Ada Research Zero One", "Ada_Research_Zero_One",
             "AdaResearch_46", "AdaResearch"]
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData/Roaming"))
        root = base / "Godot" / "app_userdata"
    elif sys.platform == "darwin":
        root = Path.home() / "Library/Application Support/Godot/app_userdata"
    else:
        root = Path.home() / ".local/share/godot/app_userdata"
    for n in names:
        p = root / n
        if p.exists():
            return p / user_url[len("user://"):]
    return root / names[0] / user_url[len("user://"):]


def load_log() -> dict:
    if LOG_FILE.exists():
        try:
            return json.loads(LOG_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"tokens": {}}


def save_log(log: dict) -> None:
    log["last_updated"] = int(time.time())
    LOG_FILE.write_text(json.dumps(log, indent=2, ensure_ascii=False) + "\n",
                        encoding="utf-8")


def fix_one(config_path: Path, min_colors: int, timeout: int, log: dict) -> dict:
    """Iterate variations until one beats min_colors, keep the best.
    Returns a summary dict of what happened for this token."""
    token = config_path.stem
    config_rel = str(config_path.relative_to(REPO)).replace("\\", "/")
    out_abs = GALLERY / f"{token}.png"

    current_score = image_content_score(out_abs) if out_abs.exists() else 0

    print(f"  [{token}] current score = {current_score}  (threshold {min_colors})")
    if current_score >= min_colors:
        return {"token": token, "action": "skip_ok", "score": current_score}

    best_score = current_score
    best_variation = "existing"
    best_args: dict = {}
    tmp_out = GALLERY / f"_fixer_tmp_{token}.png"

    for label, extra in VARIATIONS:
        if label == "default" and current_score > 0:
            continue  # already had this
        print(f"    trying [{label}] {extra}", end=" ... ", flush=True)
        ok = render_once(config_rel, tmp_out, extra, timeout)
        if not ok:
            print("fail")
            continue
        score = image_content_score(tmp_out)
        print(f"score={score}")
        if score > best_score:
            best_score = score
            best_variation = label
            best_args = dict(extra)
            shutil.copy2(tmp_out, out_abs)
        if best_score >= min_colors:
            print(f"    [ok] {label} hit threshold")
            break

    tmp_out.unlink(missing_ok=True)

    return {
        "token": token,
        "action": "fixed" if best_variation != "existing" else "no_improvement",
        "score": best_score,
        "variation": best_variation,
        "args": best_args,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--token", help="only fix this token")
    ap.add_argument("--system", help="glass | big_pipe (filter by prefix)")
    ap.add_argument("--min-colors", type=int, default=50,
                    help="minimum pipe-coverage score (0-1000, default 50 = 5%%). "
                         "Replaces the old unique-colors metric.")
    ap.add_argument("--timeout", type=int, default=60,
                    help="per-render seconds (default 60)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not CONFIGS.exists():
        print(f"[ERR] {CONFIGS} not found")
        return 1

    configs = sorted(CONFIGS.glob("*.json"))
    if args.token:
        configs = [c for c in configs if c.stem == args.token]
    elif args.system:
        prefix = "big_" if args.system.startswith("big") else "glass_"
        configs = [c for c in configs if c.name.startswith(prefix)]

    if not configs:
        print("no configs matched"); return 1

    if args.dry_run:
        print(f"[dry-run] would consider {len(configs)} configs against threshold {args.min_colors}")
        n_ok = 0; n_empty = 0
        for c in configs:
            out = GALLERY / f"{c.stem}.png"
            score = image_content_score(out) if out.exists() else 0
            if score >= args.min_colors:
                n_ok += 1; marker = "ok"
            else:
                n_empty += 1; marker = "EMPTY"
            print(f"  {c.stem:<40s} score={score:<5d} {marker}")
        print(f"\n{n_ok} ok, {n_empty} empty (threshold {args.min_colors})")
        return 0

    log = load_log()
    t0 = time.time()
    results = []
    for c in configs:
        r = fix_one(c, args.min_colors, args.timeout, log)
        results.append(r)
        if r.get("action") == "fixed":
            log["tokens"][r["token"]] = {
                "variation": r["variation"],
                "args": r["args"],
                "score": r["score"],
                "fixed_at": int(time.time()),
            }
            save_log(log)  # checkpoint each fix

    # Summary
    fixed = [r for r in results if r["action"] == "fixed"]
    skipped = [r for r in results if r["action"] == "skip_ok"]
    stuck = [r for r in results if r["action"] == "no_improvement"]
    print(f"\n{'-' * 60}")
    print(f"done in {time.time() - t0:.1f}s: "
          f"{len(fixed)} fixed, {len(skipped)} already ok, {len(stuck)} still stuck")
    if stuck:
        print("still stuck (no variation crossed threshold):")
        for r in stuck:
            print(f"  {r['token']} (best score {r['score']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
