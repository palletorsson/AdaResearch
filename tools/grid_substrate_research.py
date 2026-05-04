#!/usr/bin/env python3
"""
grid_substrate_research.py
===========================

Auto-research orchestrator for GridSubstrateRunner.

This script is deliberately thin: it mirrors the existing pipeline
established by `capture_spine_research.py`. The only thing it adds is
the **prebuild** step — for each (host_shell, expression) config in
`commons/grid/mutators/research_configs.json`, write a temporary
"research host" map at `commons/maps/research_substrate_<id>/` with
grid_substrate_runner placed at one walkable cell and its parameters
filtered to the single expression we want to render.

Capture itself is delegated to the canonical Godot pipeline:
    - `_find_godot` from measure_artifact_aabbs.py (env override + fallback)
    - runtime_flags.json (biome_enabled / artifacts_enabled / _capture_active)
    - commons/testing/capture_multi_angle.gd (the established render script)

After Godot writes the four-angle PNGs, we copy `front.png` into
`ada_encyclopedia/public/grid-substrate-gallery/<id>.png` so the gallery
shows real in-game screenshots, identical in shape to every other DNA
research vein.

Run:
    python tools/grid_substrate_research.py            # prebuild + render all
    python tools/grid_substrate_research.py --prebuild # write hosts only
    python tools/grid_substrate_research.py --dry      # plan only
    python tools/grid_substrate_research.py --force    # re-render
"""

from __future__ import annotations
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

# Reuse what's already there.
from measure_artifact_aabbs import _find_godot  # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
CONFIGS_PATH = REPO / "commons" / "grid" / "mutators" / "research_configs.json"
GALLERY_DIR  = ENC / "public" / "grid-substrate-gallery"
HOST_DIR     = REPO / "commons" / "maps"
RESEARCH_PREFIX = "research_substrate_"

CAPTURE_OUT  = REPO / "ada_run" / "captures" / "grid_substrate"
CAPTURE_GD   = "res://commons/testing/capture_multi_angle.gd"
RUNTIME_FLAGS = REPO / "ada_run" / "runtime_flags.json"
PREFERRED_ANGLE = "front"


# ── Runtime-flags handling (mirrors capture_spine_research.py) ──

def _set_capture_flags() -> dict:
    prior: dict = {}
    if RUNTIME_FLAGS.exists():
        try:
            prior = json.loads(RUNTIME_FLAGS.read_text(encoding="utf-8"))
        except Exception:
            prior = {}
    flags = dict(prior)
    flags["biome_enabled"] = False
    flags["_capture_active"] = True
    # Keep artifacts ENABLED — we WANT the runner to run. (Spine research
    # disables them; we don't.)
    flags["artifacts_enabled"] = True
    RUNTIME_FLAGS.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME_FLAGS.write_text(json.dumps(flags, indent=2) + "\n", encoding="utf-8")
    return prior


def _restore_flags(prior: dict) -> None:
    prior.pop("_capture_active", None)
    if not prior:
        prior = {"biome_enabled": True,
                 "_doc": "restored after grid_substrate research"}
    RUNTIME_FLAGS.write_text(json.dumps(prior, indent=2) + "\n", encoding="utf-8")


# ── Prebuild research host maps ─────────────────────────────────

def _load_configs() -> list[dict]:
    return json.loads(CONFIGS_PATH.read_text(encoding="utf-8")).get("configs", [])


def _load_shell(shell_id: str) -> dict:
    return json.loads((HOST_DIR / shell_id / "map_data.json").read_text(encoding="utf-8"))


def _parse_h(v) -> int:
    if isinstance(v, int): return v
    try: return int(str(v).strip() or 0)
    except (ValueError, TypeError): return 0


# ── Static-fill layouts: pure structure modifications, no mutators ──
#
# Each function takes the shell's height grid and returns a list of
# (row, col) cells to "fill" — meaning raise them in the structure
# layer so the cube becomes visible. We add height delta=1 (so a
# floor cell at h=1 becomes h=2). Plinths (h>=2) stay as-is.
#
# This is the user's request distilled: a grid + fill the holes,
# nothing else. No mutator, no animation, no auto-cycle, no shader
# tricks. Just static structure.

def layout_atop_plinths(H: list[list[int]]) -> list[tuple[int, int]]:
    """Fill cells that ARE plinths — visualizes them as taller (h=3 → h=4)."""
    return [(r, c) for r, row in enumerate(H)
                   for c, h in enumerate(row) if h >= 2]


# ── Plinth selection — different DISTRIBUTIONS over the plinth array ──
# These are the "indexing as visualization" layouts. Take the same set of
# plinths in row-major order, select different subsets. Same array,
# different array slice — the array_tutorial sequence's central idea.

def _plinths(H: list[list[int]]) -> list[tuple[int, int]]:
    """All plinth cells in row-major iteration order — the canonical index."""
    return [(r, c) for r, row in enumerate(H)
                   for c, h in enumerate(row) if h >= 2]


def layout_plinths_first(H):
    """Just index [0] — one plinth lit. The array's first element."""
    p = _plinths(H)
    return p[:1]


def layout_plinths_every_2nd(H):
    """Indices 0, 2, 4, … — alternating. The simplest rhythm."""
    return _plinths(H)[::2]


def layout_plinths_every_3rd(H):
    """Indices 0, 3, 6, … — slower disco beat."""
    return _plinths(H)[::3]


def layout_plinths_odd_indices(H):
    """Indices 1, 3, 5, … — the offbeat. Pairs with every_2nd as complement."""
    return _plinths(H)[1::2]


def layout_plinths_powers_of_2(H):
    """Indices 1, 2, 4, 8, 16, … — computational thinking made visible."""
    p = _plinths(H)
    out = []
    i = 1
    while i < len(p):
        out.append(p[i])
        i *= 2
    return out


def layout_plinths_primes(H):
    """Indices that are prime (2, 3, 5, 7, 11, …). Number theory rendered."""
    p = _plinths(H)
    def is_prime(n: int) -> bool:
        if n < 2: return False
        if n < 4: return True
        if n % 2 == 0: return False
        for k in range(3, int(n ** 0.5) + 1, 2):
            if n % k == 0: return False
        return True
    return [p[i] for i in range(len(p)) if is_prime(i)]


def layout_plinths_disco(H):
    """Disco-style: light up plinths where (r + c) % 4 == 0 — diagonal phase
    bands. The 'now-playing' beat across the array."""
    return [(r, c) for r, c in _plinths(H) if (r + c) % 4 == 0]


def layout_plinths_disco_offbeat(H):
    """Complement of disco: (r + c) % 4 == 2. Together with disco, two
    interleaved phases tile every plinth — the array as a clock with
    multiple hands."""
    return [(r, c) for r, c in _plinths(H) if (r + c) % 4 == 2]


def layout_walkable_floor(H: list[list[int]]) -> list[tuple[int, int]]:
    """Fill every walkable floor cell — the plaza inverted into a forest."""
    return [(r, c) for r, row in enumerate(H)
                   for c, h in enumerate(row) if h == 1]


def layout_array_stride(H: list[list[int]]) -> list[tuple[int, int]]:
    """Every 3rd walkable cell on both axes — Buren spacing."""
    return [(r, c) for r, row in enumerate(H)
                   for c, h in enumerate(row)
                   if h == 1 and r % 3 == 1 and c % 3 == 1]


def layout_perimeter_of_mass(H: list[list[int]]) -> list[tuple[int, int]]:
    """Floor cells adjacent to a plinth — the skirt around dense mass."""
    rows = len(H); cols = len(H[0]) if rows else 0
    out = []
    for r in range(rows):
        for c in range(cols):
            if H[r][c] != 1: continue
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    if dr == 0 and dc == 0: continue
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < rows and 0 <= nc < cols and H[nr][nc] >= 2:
                        out.append((r, c)); break
                else:
                    continue
                break
    return out


def layout_array_filled(H: list[list[int]]) -> list[tuple[int, int]]:
    """Every walkable cell. Densest fill — sets up contrast against stride."""
    return [(r, c) for r, row in enumerate(H)
                   for c, h in enumerate(row) if h == 1]


LAYOUTS = {
    "atop_plinths":           layout_atop_plinths,
    "walkable_floor":         layout_walkable_floor,
    "array_stride":           layout_array_stride,
    "perimeter_of_mass":      layout_perimeter_of_mass,
    "array_filled":           layout_array_filled,
    # Distribution layouts — same plinth array, different indexing rules.
    "plinths_first":          layout_plinths_first,
    "plinths_every_2nd":      layout_plinths_every_2nd,
    "plinths_every_3rd":      layout_plinths_every_3rd,
    "plinths_odd_indices":    layout_plinths_odd_indices,
    "plinths_powers_of_2":    layout_plinths_powers_of_2,
    "plinths_primes":         layout_plinths_primes,
    "plinths_disco":          layout_plinths_disco,
    "plinths_disco_offbeat":  layout_plinths_disco_offbeat,
}

FILL_HEIGHT = 2   # each filled cell becomes this tall (cube above floor)


def write_research_host(config: dict) -> str:
    """Static-fill render. Take the shell's structure, raise the fill cells
    by the layout, save as a new map. Plain map_data.json — Godot renders
    it like any other map. No mutator, no runner, no animation."""
    shell = _load_shell(config["host_shell"])
    expr = config["expression"]
    if expr not in LAYOUTS:
        raise ValueError(f"Unknown layout '{expr}'. Known: {list(LAYOUTS)}")
    map_name = f"{RESEARCH_PREFIX}{config['id']}"

    src_struct = shell["layers"]["structure"]
    H = [[_parse_h(c) for c in row] for row in src_struct]

    fill_cells = LAYOUTS[expr](H)
    # Layouts whose semantics are "highlight selected plinths" need to LIFT
    # those plinths above the rest of the plinth field so the selection
    # reads visually. Otherwise max(h, 2) on an h=3 plinth is a no-op.
    is_plinth_layout = expr.startswith("plinths_") or expr == "atop_plinths"
    for (r, c) in fill_cells:
        orig = _parse_h(shell["layers"]["structure"][r][c])
        if is_plinth_layout:
            # Lift each selected plinth by +2 above the shell's plinth height
            # (from h=3 to h=5) so the chosen subset rises clearly above the
            # unselected plinths still at h=3.
            H[r][c] = max(H[r][c], orig + 2)
        else:
            # Floor-fill layouts: raise floor cells (h=1) up to FILL_HEIGHT.
            H[r][c] = max(H[r][c], FILL_HEIGHT)

    new_struct = [[str(h) for h in row] for row in H]
    rows = len(new_struct); cols = len(new_struct[0]) if rows else 0

    # Use shell's utilities + interactables verbatim. (Keeps spawn/teleport.)
    utilities = [list(row) for row in shell["layers"]["utilities"]]
    interactables = [list(row) for row in shell["layers"]["interactables"]]

    info = dict(shell.get("map_info", {}))
    info["name"] = map_name
    info["lookup_name"] = map_name
    info["description"] = (
        f"Static fill: shell={config['host_shell']}, layout={expr}. "
        f"{len(fill_cells)} cells lifted from the shell structure. "
        f"No mutator, no animation — pure structure."
    )
    if "dimensions" in info:
        info["dimensions"] = dict(info["dimensions"])
        info["dimensions"]["max_height"] = max(
            info["dimensions"].get("max_height", 0),
            max((max(r) for r in H), default=1)
        )

    md = {
        "map_info": info,
        "layers": {
            "structure": new_struct,
            "utilities": utilities,
            "interactables": interactables,
        },
        "settings": shell.get("settings", {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.07, 0.08, 0.12]},
            "grid_animation": {"enabled": False},
        }),
        "utility_definitions": shell.get("utility_definitions", {
            "sp": {"type": "spawn"}, "t": {"type": "teleporter"},
        }),
    }

    out_dir = HOST_DIR / map_name
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "map_data.json").write_text(
        json.dumps(md, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    return map_name


# ── Capture (delegate to existing pipeline) ─────────────────────

def capture_one(godot: str, map_name: str, timeout: int = 120) -> bool:
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", CAPTURE_GD, "--",
        "--mode=map", f"--target={map_name}",
        f"--out=res://ada_run/captures/grid_substrate",
        # Mutator's _ready() awaits 1.0s before its first apply (line 81 of
        # grid_mutator_base.gd). Then static_mode kills the cycle. So we
        # capture at 3s — well after the first apply settles, well before
        # any second cycle could fire (default cycle = 8s, but disabled
        # anyway by static_mode). Locked-static screenshot.
        "--wait=3",
    ]
    try:
        proc = subprocess.run(cmd, cwd=str(REPO), timeout=timeout, capture_output=True)
    except subprocess.TimeoutExpired:
        print(f"  ! {map_name}: timed out")
        return False
    for angle in (PREFERRED_ANGLE, "above", "iso", "left", "right"):
        if (CAPTURE_OUT / map_name / f"{angle}.png").exists():
            return True
    print(f"  ! {map_name}: no PNGs (rc={proc.returncode})")
    if proc.returncode != 0 and proc.stderr:
        print(f"    stderr tail: {proc.stderr.decode('utf-8', errors='ignore')[-300:]}")
    return False


def harvest_to_gallery(config: dict, map_name: str) -> bool:
    src = CAPTURE_OUT / map_name / f"{PREFERRED_ANGLE}.png"
    if not src.exists():
        for a in ("above", "iso", "left", "right"):
            cand = CAPTURE_OUT / map_name / f"{a}.png"
            if cand.exists():
                src = cand
                break
    if not src.exists():
        return False
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, GALLERY_DIR / f"{config['id']}.png")
    return True


# ── Gallery metadata ────────────────────────────────────────────

def write_gallery_meta(configs: list[dict], rendered: list[str]) -> None:
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)
    entries = []
    for cfg in configs:
        cid = cfg["id"]
        cfg_json = {
            "id": cid,
            "host_shell": cfg["host_shell"],
            "expression": cfg["expression"],
            "notes": cfg.get("notes", ""),
            "research_map": f"{RESEARCH_PREFIX}{cid}",
            "rendered": cid in rendered,
        }
        (GALLERY_DIR / f"{cid}.json").write_text(
            json.dumps(cfg_json, indent=2) + "\n", encoding="utf-8")
        entries.append({
            "id": cid,
            "title": cid.replace("_", " "),
            "image": f"/grid-substrate-gallery/{cid}.png",
            "config": f"/grid-substrate-gallery/{cid}.json",
            "host_shell": cfg["host_shell"],
            "expression": cfg["expression"],
            "notes": cfg.get("notes", ""),
            "map_route": f"/map-3d/{RESEARCH_PREFIX}{cid}",
            "rendered": cid in rendered,
        })
    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": (
            "Grid substrate runner — context-aware visibility. Each entry "
            "is the same `grid_substrate_runner` artifact mounted on a "
            "different shell with a different map-aware expression. The "
            "expression reads ctx['structure'].get_height_at(x,z) so the "
            "same code produces a different pattern depending on the "
            "host map."
        ),
        "entries": entries,
    }
    (GALLERY_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = GALLERY_DIR / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


# ── Main ─────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true",
                    help="Print plan; don't write or run Godot.")
    ap.add_argument("--prebuild", action="store_true",
                    help="Write research host maps + gallery scaffold; skip Godot.")
    ap.add_argument("--force", action="store_true",
                    help="Re-render even if PNG already exists.")
    ap.add_argument("--id", help="Only run this single config id.")
    args = ap.parse_args()

    configs = _load_configs()
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]
        if not configs:
            print(f"No config matched id={args.id}")
            return

    print(f"Configs:    {len(configs)}")
    print(f"Gallery:    {GALLERY_DIR.relative_to(REPO.parent)}")

    if args.dry:
        for c in configs:
            print(f"  {c['id']:36s} shell={c['host_shell']:24s} expr={c['expression']}")
        print("\n[dry run]")
        return

    # 1) Prebuild research host maps (always — cheap and idempotent).
    print("\nPrebuilding host maps:")
    for c in configs:
        try:
            mn = write_research_host(c)
            print(f"  built {mn}")
        except Exception as e:
            print(f"  FAIL build {c['id']}: {e}")

    if args.prebuild:
        write_gallery_meta(configs, [])
        print("\nPrebuilt only (--prebuild). Run again without --prebuild to render.")
        return

    # 2) Find Godot via the established helper.
    godot = _find_godot()
    if not godot:
        print("\nNo Godot found via _find_godot. Set GODOT_EXE env var or install.")
        write_gallery_meta(configs, [])
        return

    # 3) Set capture environment (biome off, capture-active flag).
    prior = _set_capture_flags()
    rendered: list[str] = []
    try:
        for c in configs:
            cid = c["id"]
            png = GALLERY_DIR / f"{cid}.png"
            if png.exists() and not args.force:
                print(f"  skip      {cid}")
                rendered.append(cid)
                continue
            map_name = f"{RESEARCH_PREFIX}{cid}"
            print(f"  capture   {cid:36s} ", end="", flush=True)
            if not capture_one(godot, map_name):
                continue
            if harvest_to_gallery(c, map_name):
                rendered.append(cid)
                print("OK")
            else:
                print("(no PNG to harvest)")
    finally:
        _restore_flags(prior)

    write_gallery_meta(configs, rendered)
    print()
    print(f"Rendered {len(rendered)} / {len(configs)}")
    print(f"Gallery:  http://localhost:3003/grid-substrate-gallery/manifest.json")
    if rendered:
        print(f"Sample:   http://localhost:3003/grid-substrate-gallery/{rendered[0]}.png")
        print(f"Map view: http://localhost:3003/map-3d/{RESEARCH_PREFIX}{rendered[0]}")


if __name__ == "__main__":
    main()
