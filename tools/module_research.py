#!/usr/bin/env python
"""
module_research.py — single entrypoint for auto-research across all builder
modules (facade, pokemon-studio, audio-rack, glass-rack, grid-editor).

Each module is a row in MODULES below. A row declares:
  - where its configs live on disk
  - which Godot script consumes one config
  - which gallery dir receives the rendered PNG + paired JSON
  - how to name arguments in the Godot invocation

Usage::

    python tools/module_research.py --list                      # show modules
    python tools/module_research.py audio-rack --dry-run        # plan only
    python tools/module_research.py audio-rack                  # render all
    python tools/module_research.py pokemon --limit 5           # first 5
    python tools/module_research.py facade --force              # re-render

After each batch the matching public/<gallery>/manifest.json is regenerated
by calling build_gallery_manifest.py — ratings then appear on /dna and on
each gallery page immediately.

This tool is intentionally thin: all the rendering intelligence lives in
the per-module Godot scripts under commons/testing/. Adding a new module
means adding one row here, not a new script.
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
PUBLIC = ENCYC / "public"

def resolve_godot() -> str:
    if os.environ.get("GODOT_EXE"): return os.environ["GODOT_EXE"]
    for c in [
        "C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe",
        "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
    ]:
        if Path(c).exists(): return c
    return "godot"

GODOT_EXE = resolve_godot()

# ─── Module registry ────────────────────────────────────────────────────
#
# Each entry tells the runner how to translate one config file into one
# rendered PNG. The actual rendering lives in the declared Godot script.
#
#   config_glob    — filesystem glob relative to REPO, e.g. "commons/foo/*.json"
#   godot_script   — res:// path to the .gd that processes one config
#   gallery        — public/<gallery> slug — where PNGs land
#   arg_scheme     — how to pass config+out to the Godot script:
#                      "config_out"    → --config=<path> --out=<user://...>
#                      "scene_out"     → --scene=<path> --out=<user://...>
#                      "dna_out"       → --dna=<path>    --out=<user://...>
#   stage_dir      — user:// subdir where Godot writes PNGs; runner copies them
#                     to the gallery. Must match what the .gd hardcodes.

MODULES: dict[str, dict] = {
    "facade": {
        "config_glob":  "commons/facade_parts/presets/*.json",
        "godot_script": "res://commons/testing/render_facade.gd",
        "gallery":      "facade-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "facade_gallery",
        "description":  "Italian + classical facades via FacadeComposer.",
    },
    "audio-rack": {
        "config_glob":  "commons/audio/rack_configs/*.json",
        "godot_script": "res://commons/testing/capture_rack_configs.gd",
        "gallery":      "rack-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "rack_gallery",
        "description":  "Hand-authored eurorack signal-chain configs.",
    },
    "audio-rack-auto": {
        # Auto-generated racks from archetype templates. See
        # tools/generate_rack_configs.py. Runs through the same Godot
        # renderer as audio-rack; outputs separate gallery so rated
        # winners stay distinct from hand-authored ones.
        "config_glob":  "commons/audio/rack_configs/auto/*.json",
        "godot_script": "res://commons/testing/capture_rack_configs.gd",
        "gallery":      "rack-auto-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "rack_auto_gallery",
        "description":  "Auto-generated racks — archetype templates (subtractive, FM, drum, filter bank, delay, LFO, granular, wavefolder, S&H, minimal). Generate via tools/generate_rack_configs.py.",
    },
    "interactables-auto": {
        # Per-control variants wrapped in minimal rack configs — each
        # variant is one control_definition rendered via UVAC.
        # Generate via tools/generate_interactables.py.
        "config_glob":  "commons/audio/rack_configs/auto_interactables/*.json",
        "godot_script": "res://commons/testing/capture_rack_configs.gd",
        "gallery":      "interactables-auto-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "interactables_auto_gallery",
        "description":  "Auto-generated interactable variants via UVAC. 8 families (slider/knob/wheel/lever/button/xy/joystick/dial) × param × range × color × step.",
    },
    "compositions-auto": {
        # Auto-researched rack compositions. Each config is a real UVAC
        # rack_config (grid + control_definitions) — rendered through the
        # production UniversalVRAudioController pipeline, so physical
        # interactable handles (slider_smooth.tscn, dial_smooth.tscn,
        # push_button.tscn...) mount behind 2D RackControlBase face
        # plates with audio parameter wiring intact. Grab a handle,
        # move an audio param.
        "config_glob":  "commons/audio/rack_configs/compositions/*.json",
        "godot_script": "res://commons/testing/capture_rack_configs.gd",
        "gallery":      "compositions-auto-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "rack_gallery",
        "description":  "Auto-generated UVAC rack compositions. 9 layout types × counts 2-8 × varied parameter targets × varied sound_types. Generated by tools/generate_compositions.py; rendered via UVAC's capture_rack_configs.gd — real physical handles with audio wiring.",
    },
    "interactable-demos": {
        # The rich composite demo scenes — interactable_demo.tscn shows
        # ALL controls in one view (CONTROLS + EXTRA_BUTTONS + NEW_MODULES
        # + PASSIVE_ELEMENTS + COMPOUNDS). These carry procedural types
        # (touch_grid, rotary_selector, needle_meter, patch_matrix, text)
        # that UVAC doesn't expose individually.
        "config_glob":  "commons/interactables/demo_*.tscn",
        "include_extra": ["commons/interactables/interactable_demo.tscn"],
        "godot_script": "res://commons/testing/perfect_shot.gd",
        "gallery":      "interactable-demos-gallery",
        "arg_scheme":   "perfect_scene",
        "stage_dir":    "perfect_shots",
        "description":  "Composite demo scenes — interactable_demo + demo_passive + demo_compounds + demo_singles. Captures the full procedural-module set inline (rect buttons, toggle, touch_grid, rotary_selector, needle_meter, patch_matrix, text).",
    },
    "pipes-auto": {
        # Unified turtle-graphics pipe system — covers both GlassRackController
        # (lab glass, pipe_radius=0.02) and BigPipeSystem (drain pipes,
        # pipe_radius=0.8). Same DNA grammar ("f,f,r,f" turtle codes), two
        # visual scales picked by rack_info.system = "glass" | "big_pipe".
        # Rendered via capture_pipe_system.gd.
        "config_glob":  "commons/audio/pipe_configs/*.json",
        "godot_script": "res://commons/testing/capture_pipe_system.gd",
        "gallery":      "pipes-auto-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "pipes",
        "description":  "Unified turtle-graphics pipe systems — lab glass (glass_rack) + big drain pipes (big_pipe_system). Same 'f,f,r,f' turtle-code DNA, scale picked via rack_info.system. Generate via tools/generate_pipe_configs.py.",
    },
    "grid-editor": {
        "config_glob":  "commons/testing/grid_config*.json",
        "godot_script": "res://commons/testing/capture_real_grid_bio.gd",
        "gallery":      "grid-editor-gallery",
        "arg_scheme":   "config_out",
        "stage_dir":    "grid_gallery",
        "description":  "Grid subset layouts + bio accretion configs.",
    },
    "pokemon": {
        "config_glob":  "ada_encyclopedia/public/captures/critter-gallery/dna/*.json",
        "godot_script": "res://commons/testing/perfect_shot.gd",
        "gallery":      "critter-gallery",
        "arg_scheme":   "critter_dna",
        "stage_dir":    "perfect_shots",   # perfect_shot.gd hardcodes its own out dir
        "description":  "CritterDNA variations via perfect_shot --mode=critter.",
    },
    # Batch-all modules: the Godot script produces N PNGs in a single run
    # (no config input). The runner copies every PNG found in the stage dir.
    "interactables": {
        "batch_all":    True,
        "godot_script": "res://commons/testing/capture_rack_3d_batch.gd",
        "gallery":      "interactables-gallery",
        "arg_scheme":   "batch_out",
        "stage_dir":    "interactables_gallery",
        "description":  "14 interactable control types (slider×4, knob, wheel, XY, joystick, lever, button, meter, label, divider, group) via UVAC inline rendering.",
    },
    # Per-element scene renders — each atomic .tscn from commons/interactables
    # as its own PNG. Distinct from `interactables` above: that uses UVAC's
    # inline control_definitions; this loads the actual interactable scene
    # file, which may carry custom scripts, materials, and child nodes.
    "interactable-scenes": {
        "config_glob":  "commons/interactables/*.tscn",
        "exclude":      ["demo_", "interactable_demo", "_2d3d", "_test"],
        "godot_script": "res://commons/testing/perfect_shot.gd",
        "gallery":      "interactable-scenes-gallery",
        "arg_scheme":   "perfect_scene",
        "stage_dir":    "perfect_shots",
        "description":  "17 atomic interactable .tscn files — sliders, levers, joysticks, wheel, buttons, dial — each scene rendered via perfect_shot --mode=scene.",
    },
    # UVAC is the controller behind `audio-rack`. Listed here as a pointer —
    # its DNA is the rack_config JSON files already wired by audio-rack.
    "universal-audio": {
        "alias_of":     "audio-rack",
        "description":  "Alias of audio-rack. UVAC scene is the Godot-side renderer; rack_configs/*.json is the DNA.",
    },
}

# ─── Godot user-data discovery ──────────────────────────────────────────

def godot_user_root() -> Path:
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData/Roaming"))
        return base / "Godot" / "app_userdata"
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Godot/app_userdata"
    return Path.home() / ".local/share/godot/app_userdata"

def find_project_user_dir() -> Path | None:
    for name in ["Ada Research Zero One", "Ada_Research_Zero_One",
                 "AdaResearch_46", "AdaResearch"]:
        p = godot_user_root() / name
        if p.exists():
            return p
    return None

# ─── Per-config invocation ──────────────────────────────────────────────

def build_args(mod: dict, cfg_path: Path, out_user: str) -> list[str]:
    scheme = mod["arg_scheme"]
    res_cfg = _to_res_path(cfg_path)
    if scheme == "config_out":
        return [f"--config={res_cfg}", f"--out={out_user}"]
    if scheme == "scene_out":
        return [f"--scene={res_cfg}", f"--out={out_user}"]
    if scheme == "dna_out":
        abs_str = str(cfg_path).replace("\\", "/")
        return [f"--dna={abs_str}", f"--out={out_user}"]
    if scheme == "critter_dna":
        # perfect_shot.gd wants absolute path + --mode=critter
        abs_str = str(cfg_path).replace("\\", "/")
        return ["--mode=critter", f"--dna={abs_str}", f"--out={out_user}"]
    if scheme == "perfect_scene":
        # perfect_shot.gd --mode=scene takes the path in --target=<path>
        return ["--mode=scene", f"--target={res_cfg}", f"--out={out_user}"]
    if scheme == "batch_out":
        # batch-all scripts take only an output dir — the script decides
        # what to render. cfg_path is unused / synthetic.
        return [f"--out={out_user}"]
    raise ValueError(f"unknown arg_scheme: {scheme}")

def _to_res_path(p: Path) -> str:
    """Convert an absolute path under REPO to a res:// URL. Falls back to
    absolute file:// if the path is outside the Godot project."""
    try:
        rel = p.resolve().relative_to(REPO.resolve())
        return f"res://{str(rel).replace(os.sep, '/')}"
    except ValueError:
        return str(p).replace("\\", "/")

def render_one(mod: dict, cfg_path: Path, force: bool, timeout: int) -> tuple[bool, str]:
    """Run one config through its Godot script. Returns (ok, note)."""
    cid = cfg_path.stem
    gallery_dir = PUBLIC / mod["gallery"]
    out_png = gallery_dir / f"{cid}.png"
    out_cfg = gallery_dir / f"{cid}.json"

    if out_png.exists() and not force:
        return True, "skip (exists)"

    gallery_dir.mkdir(parents=True, exist_ok=True)

    user_dir = find_project_user_dir()
    if not user_dir:
        return False, "godot user dir not found"
    stage = user_dir / mod["stage_dir"]
    stage.mkdir(parents=True, exist_ok=True)
    user_out = f"user://{mod['stage_dir']}/{cid}.png"

    args = [
        GODOT_EXE, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", mod["godot_script"], "--no-bridges", "--",
        *build_args(mod, cfg_path, user_out),
    ]

    t0 = time.time()
    try:
        proc = subprocess.run(args, capture_output=True, text=True,
                              timeout=timeout, encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return False, "timeout"
    except FileNotFoundError:
        return False, f"godot not found at {GODOT_EXE}"
    elapsed = time.time() - t0

    # Resolve the produced PNG. Two patterns in the wild:
    #   (A) single file:  <stage>/<cid>.png        (facade, audio-rack)
    #   (B) directory:    <stage>/<cid>.png/       with front.png, left.png, top.png
    #                                              inside (perfect_shot, capture_rack_3d_batch)
    # For (B) we pick the best single image to land as the gallery hero
    # and optionally mirror siblings to /multi_shots so 4-angle UIs work.
    staged = stage / f"{cid}.png"
    if not staged.exists():
        # Some scripts drop output into <stage>/<cid>/ without the .png suffix
        alt = stage / cid
        if alt.exists() and alt.is_dir():
            staged = alt
        else:
            tail = (proc.stdout + proc.stderr).strip().splitlines()[-2:]
            return False, f"no output png. tail: {' | '.join(tail)[:160]}"

    src_png: Path | None = None
    multi_angle_src: Path | None = None
    if staged.is_file():
        src_png = staged
    elif staged.is_dir():
        # Recursive walk — perfect_shot nests outputs at
        # <out>/critters/<id>/hero.png, capture scripts may vary.
        all_pngs = sorted(staged.rglob("*.png"))
        if all_pngs:
            # Prefer hero > front > overview > first
            def rank(p: Path) -> tuple[int, str]:
                name = p.name.lower()
                if name == "hero.png":     return (0, str(p))
                if name == "front.png":    return (1, str(p))
                if name == "overview.png": return (2, str(p))
                return (9, str(p))
            all_pngs.sort(key=rank)
            src_png = all_pngs[0]
            # Multi-angle source = the dir containing src_png (siblings are angles)
            multi_angle_src = src_png.parent
    if src_png is None:
        return False, "no hero png in staged dir"

    # Copy with retry — Godot may briefly hold the file open on Win32.
    last_err: Exception | None = None
    for attempt in range(5):
        try:
            shutil.copy2(src_png, out_png)
            last_err = None
            break
        except PermissionError as e:
            last_err = e
            time.sleep(0.4 * (attempt + 1))
    if last_err:
        return False, f"copy blocked after retries: {last_err}"

    # If multi-angle captures exist, mirror the rest into the gallery so
    # galleries wanting a 4-angle view (like /artifact/[token]) can read
    # them at /<gallery>/<cid>/<angle>.png.
    if multi_angle_src is not None:
        multi_out = gallery_dir / cid
        multi_out.mkdir(parents=True, exist_ok=True)
        for sib in multi_angle_src.iterdir():
            if sib.suffix.lower() != ".png" or not sib.is_file():
                continue
            try:
                shutil.copy2(sib, multi_out / sib.name)
            except Exception:
                pass

    # Pair the config JSON next to the image so galleries can surface DNA
    try:
        shutil.copy2(cfg_path, out_cfg)
    except Exception:
        pass  # not fatal — image still rendered

    return True, f"ok {elapsed:.1f}s"

# ─── Main ────────────────────────────────────────────────────────────────

def _run_batch_all(name: str, mod: dict, force: bool, dry_run: bool, timeout: int) -> int:
    """Run a batch-all module: Godot script is invoked once with just --out,
    and is expected to write every PNG into the stage dir. The runner
    copies all PNGs to the public gallery, one manifest entry each."""
    gallery_dir = PUBLIC / mod["gallery"]
    user_dir = find_project_user_dir()
    if not user_dir:
        print(f"[{name}] godot user dir not found")
        return 2
    stage = user_dir / mod["stage_dir"]

    if dry_run:
        print(f"[{name}] batch-all: would invoke {mod['godot_script']} -> {stage}")
        return 0

    # Clear the stage first so we only pick up this run's output
    if stage.exists():
        for p in stage.glob("*.png"):
            try: p.unlink()
            except Exception: pass
    stage.mkdir(parents=True, exist_ok=True)

    args = [
        GODOT_EXE, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", mod["godot_script"], "--no-bridges", "--",
        f"--out=user://{mod['stage_dir']}/",
    ]
    print(f"[{name}] batch-all: running {mod['godot_script']}")
    t0 = time.time()
    try:
        proc = subprocess.run(args, capture_output=True, text=True,
                              timeout=timeout, encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        print(f"[{name}] timeout"); return 2

    elapsed = time.time() - t0
    pngs = sorted(stage.glob("*.png"))
    if not pngs:
        tail = (proc.stdout + proc.stderr).strip().splitlines()[-3:]
        print(f"[{name}] no PNGs produced after {elapsed:.1f}s")
        print(f"  tail: {' | '.join(tail)[:240]}")
        return 2

    gallery_dir.mkdir(parents=True, exist_ok=True)
    ok = 0
    for src in pngs:
        dst = gallery_dir / src.name
        # Retry copy — Godot may briefly hold files after exit on Win32
        last_err: Exception | None = None
        for attempt in range(5):
            try:
                shutil.copy2(src, dst); last_err = None; break
            except PermissionError as e:
                last_err = e; time.sleep(0.4 * (attempt + 1))
        if last_err is None:
            ok += 1
        else:
            print(f"  [copy fail] {src.name}: {last_err}")

    print(f"[{name}] batch-all done: {ok}/{len(pngs)} copied in {elapsed:.1f}s")

    # Regenerate manifest
    candidates = [
        ENCYC / "tools" / "build_gallery_manifest.py",
        REPO / "tools" / "build_gallery_manifest.py",
    ]
    mtool = next((p for p in candidates if p.exists()), None)
    if mtool:
        subprocess.run([sys.executable, str(mtool), mod["gallery"]], check=False)
    return 0 if ok > 0 else 2


def list_modules() -> None:
    print(f"{'module':<16} {'gallery':<24} {'source':<52} {'script / note'}")
    print("-" * 140)
    for name, m in MODULES.items():
        if m.get("alias_of"):
            print(f"{name:<16} {'(alias)':<24} {'→ ' + m['alias_of']:<52} {m.get('description','')}")
            continue
        if m.get("batch_all"):
            print(f"{name:<16} {m['gallery']:<24} {'(batch-all, no configs)':<52} {m['godot_script']}")
            print(f"{'':<16} {'':<24} {'':<52} {m['description']}")
            continue
        glob_pat = m.get("config_glob", "")
        base = Path(glob_pat).parent
        glob_name = Path(glob_pat).name
        # Resolve relative to REPO; absolute / encyclopedia paths too
        if glob_pat.startswith("ada_encyclopedia/"):
            base_abs = REPO.parent / base
        elif Path(glob_pat).is_absolute():
            base_abs = base
        else:
            base_abs = REPO / base
        configs = list(base_abs.glob(glob_name)) if base_abs.exists() else []
        print(f"{name:<16} {m['gallery']:<24} {glob_pat:<52} {m['godot_script']}")
        print(f"{'':<16} {'':<24} ({len(configs)} configs found)  {m['description']}")

def run(name: str, force: bool, dry_run: bool, limit: int, timeout: int) -> int:
    mod = MODULES.get(name)
    if not mod:
        print(f"[ERR] unknown module: {name}. See --list.")
        return 1

    # Follow alias entries (e.g. universal-audio → audio-rack)
    if mod.get("alias_of"):
        target = mod["alias_of"]
        print(f"[{name}] alias of '{target}' — delegating.")
        return run(target, force, dry_run, limit, timeout)

    # Batch-all modules: one Godot invocation produces N PNGs, not 1 per config.
    if mod.get("batch_all"):
        return _run_batch_all(name, mod, force, dry_run, timeout)

    # Resolve config paths. Some modules point outside REPO (e.g. pokemon
    # DNA lives in the encyclopedia dir) — handle absolute globs too.
    glob_pattern = mod["config_glob"]
    if Path(glob_pattern).is_absolute():
        base = Path(glob_pattern).parent
        glob = Path(glob_pattern).name
    elif glob_pattern.startswith("ada_encyclopedia/"):
        base = REPO.parent / Path(glob_pattern).parent
        glob = Path(glob_pattern).name
    else:
        base = REPO / Path(glob_pattern).parent
        glob = Path(glob_pattern).name
    configs = sorted(base.glob(glob)) if base.exists() else []

    # include_extra: paths to add beyond the glob result (relative to REPO).
    for extra in (mod.get("include_extra") or []):
        ep = REPO / extra if not Path(extra).is_absolute() else Path(extra)
        if ep.exists() and ep not in configs:
            configs.append(ep)

    # Exclude: if the module declares `exclude` patterns, drop any config
    # whose stem/filename contains one of those substrings. Useful when a
    # glob over-matches (e.g. commons/interactables/*.tscn pulls in demos).
    excludes: list[str] = mod.get("exclude") or []
    if excludes:
        before = len(configs)
        configs = [c for c in configs if not any(e in c.name for e in excludes)]
        if before > len(configs):
            print(f"  [filter] dropped {before - len(configs)} matching {excludes}")

    if not configs:
        print(f"[{name}] no configs found matching {glob_pattern}")
        print(f"  base: {base}")
        print(f"  hint: create configs in that dir, or adjust MODULES in module_research.py")
        return 2

    if limit > 0:
        configs = configs[:limit]

    print(f"[{name}] {len(configs)} config(s), gallery -> public/{mod['gallery']}")
    print(f"  godot script: {mod['godot_script']}")
    if dry_run:
        for c in configs:
            print(f"  [plan] {c.name}")
        return 0

    ok, fail = 0, 0
    for i, c in enumerate(configs, 1):
        success, note = render_one(mod, c, force, timeout)
        mark = "OK " if success else "FAIL"
        print(f"  [{i:3d}/{len(configs)}] {mark} {c.stem:<30s} {note}", flush=True)
        if success: ok += 1
        else: fail += 1

    print(f"\n[{name}] done: {ok} ok, {fail} fail")

    # Regenerate the gallery manifest so /dna sees the new entries.
    # The tool lives in the encyclopedia repo's tools/ dir.
    if ok > 0:
        candidates = [
            ENCYC / "tools" / "build_gallery_manifest.py",
            REPO / "tools" / "build_gallery_manifest.py",
        ]
        manifest_tool = next((p for p in candidates if p.exists()), None)
        if manifest_tool:
            try:
                subprocess.run([sys.executable, str(manifest_tool), mod["gallery"]], check=False)
            except Exception as e:
                print(f"  [warn] manifest regen failed: {e}")
        else:
            print(f"  [warn] build_gallery_manifest.py not found in {candidates}")

    return 0 if fail == 0 else 2


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("module", nargs="?", help="one of: " + ", ".join(MODULES.keys()))
    ap.add_argument("--list", action="store_true", help="list modules and exit")
    ap.add_argument("--force", action="store_true", help="re-render existing")
    ap.add_argument("--dry-run", action="store_true", help="list configs only")
    ap.add_argument("--limit", type=int, default=0, help="cap config count")
    ap.add_argument("--timeout", type=int, default=120, help="per-config seconds")
    args = ap.parse_args()

    if args.list or not args.module:
        list_modules()
        return 0
    return run(args.module, args.force, args.dry_run, args.limit, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
