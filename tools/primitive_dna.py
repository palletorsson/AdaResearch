"""primitive_dna.py — DNA-style auto-research for Godot primitives.

Companion to chamber.py. Where chamber improves *named* artifacts one at a
time (proposal-without-applying), primitive_dna explores the *parameter
space* of a primitive class (TorusMesh, SphereMesh, …) and surfaces a
gallery of variants. Approved variants graduate to named artifacts.

Storage convention mirrors chamber-runs/:
    ada_encyclopedia/public/primitive-runs/<PrimitiveName>/
        manifest.json     # genome definition + variant index
        variants/<id>.png # one capture per variant

Usage:
    python tools/primitive_dna.py sweep TorusMesh
        # generates a 2D parameter sweep, captures all variants, writes manifest

    python tools/primitive_dna.py list
        # lists primitive runs that exist on disk

The Godot side (commons/testing/capture_primitive_dna.gd) does the actual
rendering. This script generates the input manifest, invokes Godot once,
and copies the captures into the encyclopedia's public/ directory so the
/primitives-dna page can render them.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
ENCY = REPO.parent / "ada_encyclopedia"
PRIMITIVE_RUNS = ENCY / "public" / "primitive-runs"
GODOT_EXE = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
CAPTURE_SCRIPT = "res://commons/testing/capture_primitive_dna.gd"

# ── Genome definitions ──────────────────────────────────────────────────
#
# Each genome describes a primitive's parameter space and a default 2D
# sweep that covers the interesting range. Values picked to span "barely
# recognizable as X" → "smooth canonical X".

GENOMES: dict[str, dict[str, Any]] = {
    "TorusMesh": {
        "fixed": {
            "inner_radius": 0.18,
            "outer_radius": 0.40,
        },
        "axes": {
            "rings":         [3, 4, 5, 6, 8, 12, 16, 24],
            "ring_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.6},
        "material": {"base_color": [0.62, 0.65, 0.74, 1.0]},
        "image":    {"width": 384, "height": 384},
        "truth":    "a torus is a 2D parameter space; rings × ring_segments names which corner the eye reads as 'donut'",
    },
    "SphereMesh": {
        "fixed": {
            "radius": 0.30,
            "height": 0.60,
        },
        "axes": {
            "rings":           [2, 3, 4, 6, 8, 12, 16, 24],
            "radial_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.5},
        "material": {"base_color": [0.62, 0.65, 0.74, 1.0]},
        "image":    {"width": 384, "height": 384},
        "truth":    "a sphere is what the eye calls a polyhedron once both axes have enough segments",
    },
    "CapsuleMesh": {
        "fixed": {
            "radius": 0.20,
        },
        "axes": {
            "height":          [0.40, 0.50, 0.65, 0.80, 1.00, 1.30, 1.60, 2.00],
            "radial_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 15.0, "pad": 1.5},
        "material": {"base_color": [0.62, 0.65, 0.74, 1.0]},
        "image":    {"width": 384, "height": 512},
        "truth":    "a capsule is a sphere stretched along an axis; height vs segments names which 'pill' you mean",
    },
    "BoxMesh": {
        "fixed": {},
        "axes": {
            "subdivide_width": [0, 1, 2, 4, 8],
            "subdivide_depth": [0, 1, 2, 4, 8],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.6},
        "material": {"base_color": [0.62, 0.65, 0.74, 1.0]},
        "image":    {"width": 384, "height": 384},
        "truth":    "a box subdivided is still a box; its DNA is in what you do with the extra vertices",
    },
}


def _short(p: Path) -> str:
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


def _build_sweep(genome: dict[str, Any]) -> list[dict[str, Any]]:
    """Cartesian product of every axis combined with the fixed params."""
    axes: dict[str, list] = genome["axes"]
    fixed: dict = genome.get("fixed", {})
    axis_names = list(axes.keys())
    if len(axis_names) != 2:
        raise NotImplementedError(
            "Only 2-axis sweeps are supported in this first cut "
            "(got %d axes)" % len(axis_names)
        )
    a, b = axis_names
    variants = []
    for av in axes[a]:
        for bv in axes[b]:
            params = dict(fixed)
            params[a] = av
            params[b] = bv
            # ID like "rings4_segments6" — readable, sortable, filename-safe
            vid = f"{a}{av}_{b}{bv}".replace(".", "p").replace("-", "n")
            variants.append({
                "id": vid,
                "params": params,
                "axes": {a: av, b: bv},
            })
    return variants


def cmd_sweep(args) -> int:
    name = args.primitive
    if name not in GENOMES:
        print(f"  !! unknown primitive '{name}'", file=sys.stderr)
        print(f"     known: {', '.join(sorted(GENOMES.keys()))}", file=sys.stderr)
        return 1

    if not Path(GODOT_EXE).exists():
        print(f"  !! Godot exe not found: {GODOT_EXE}", file=sys.stderr)
        return 1

    if not ENCY.exists():
        print(f"  !! encyclopedia not found at {ENCY}", file=sys.stderr)
        return 1

    genome = GENOMES[name]
    variants = _build_sweep(genome)
    print(f"primitive_dna sweep: {name} ({len(variants)} variants)")
    print(f"  axes: {list(genome['axes'].keys())}")

    # Manifest the Godot side reads.
    manifest_in = {
        "primitive": name,
        "material": genome.get("material", {}),
        "camera":   genome.get("camera", {}),
        "image":    genome.get("image", {}),
        "variants": variants,
    }

    # Write to user:// so Godot can read it. We use a stable filename so a
    # rerun overwrites cleanly.
    user_data = (
        Path(os.environ.get("APPDATA", ""))
        / "Godot/app_userdata/Ada Research Zero One"
    )
    dna_in = user_data / "primitive_dna_in"
    dna_out = user_data / "primitive_dna_out" / name
    dna_in.mkdir(parents=True, exist_ok=True)
    if dna_out.exists():
        shutil.rmtree(dna_out)
    dna_out.mkdir(parents=True, exist_ok=True)

    manifest_path = dna_in / f"{name}.json"
    manifest_path.write_text(json.dumps(manifest_in, indent=2), encoding="utf-8")
    print(f"  manifest: {manifest_path}")

    # Run Godot.
    print(f"  godot:    capturing {len(variants)} variants...")
    cmd = [
        GODOT_EXE,
        "--path", str(REPO),
        "--xr-mode", "off",
        "--no-window",
        "--script", CAPTURE_SCRIPT, "--",
        f"--manifest=user://primitive_dna_in/{name}.json",
        f"--out=user://primitive_dna_out/{name}",
    ]
    try:
        result = subprocess.run(
            cmd, check=False, capture_output=True, text=True, timeout=600
        )
        if result.returncode != 0:
            print(f"    !! godot exited {result.returncode}", file=sys.stderr)
            print(result.stderr[-2000:] if result.stderr else "(no stderr)",
                  file=sys.stderr)
    except subprocess.TimeoutExpired:
        print("    !! godot timed out (10 min)", file=sys.stderr)
        return 1

    # Read the summary Godot wrote.
    summary_path = dna_out / "summary.json"
    if not summary_path.exists():
        print(f"    !! no summary.json — capture probably failed", file=sys.stderr)
        return 1
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    print(f"  saved:    {summary['saved']}/{len(variants)} variants")

    # Copy the captures into the encyclopedia's public folder.
    target_dir = PRIMITIVE_RUNS / name
    target_variants = target_dir / "variants"
    target_variants.mkdir(parents=True, exist_ok=True)

    copied = 0
    for vid in summary["ids"]:
        src = dna_out / f"{vid}.png"
        if src.exists():
            shutil.copy(str(src), str(target_variants / f"{vid}.png"))
            copied += 1

    # Write the public-side manifest (what the page reads).
    public_manifest = {
        "primitive":    name,
        "axes":         genome["axes"],
        "fixed":        genome.get("fixed", {}),
        "image_size":   summary.get("image_size", [384, 384]),
        "truth":        genome.get("truth", ""),
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "variants":     [
            {
                "id":     v["id"],
                "params": v["params"],
                "axes":   v["axes"],
                "captured": v["id"] in summary["ids"],
            }
            for v in variants
        ],
    }
    (target_dir / "manifest.json").write_text(
        json.dumps(public_manifest, indent=2), encoding="utf-8"
    )

    print(f"  public:   {_short(target_dir)} — {copied} PNGs")
    print(f"  view:     http://localhost:3003/primitives-dna/{name}")
    return 0


def cmd_list(args) -> int:
    if not PRIMITIVE_RUNS.exists():
        print(f"  no primitive runs found ({PRIMITIVE_RUNS} doesn't exist)")
        return 0
    rows = []
    for name_dir in sorted(PRIMITIVE_RUNS.iterdir()):
        if not name_dir.is_dir():
            continue
        manifest_path = name_dir / "manifest.json"
        if not manifest_path.exists():
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        n_variants = len(manifest.get("variants", []))
        n_captured = sum(1 for v in manifest.get("variants", []) if v.get("captured"))
        rows.append((name_dir.name, n_captured, n_variants))
    if not rows:
        print("  no primitive runs yet — try: python tools/primitive_dna.py sweep TorusMesh")
        return 0
    print(f"  {'primitive':20s}  {'captured':>10s}")
    for name, captured, total in rows:
        print(f"  {name:20s}  {captured:>4d}/{total:<4d}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="primitive_dna")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_sweep = sub.add_parser(
        "sweep", help="generate a parameter sweep + capture all variants"
    )
    p_sweep.add_argument("primitive", help=f"one of: {', '.join(sorted(GENOMES.keys()))}")
    p_sweep.set_defaults(func=cmd_sweep)

    p_list = sub.add_parser("list", help="list primitive runs on disk")
    p_list.set_defaults(func=cmd_list)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
