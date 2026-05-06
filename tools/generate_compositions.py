#!/usr/bin/env python
"""
generate_compositions.py — emit UVAC rack_config.json files describing
compound rack panels for auto-research.

Each composition is a real UVAC rack_config with:
  - rack_info: name, sound_type, archetype
  - layout: padding/gap
  - grid: 2D array of control IDs (UVAC resolves positions from this)
  - control_definitions: per-cell {type, label, parameter, min, max, default}

When rendered through commons/testing/capture_rack_configs.gd (UVAC's
existing renderer), each config spawns physical interactables from
commons/interactables/*.tscn (slider_smooth, dial_smooth, push_button,
joystick_smooth…) behind 2D RackControlBase face plates, with audio
parameter wiring intact. Physical handles move → audio params move.

Generation varies axes the UVAC renderer actually draws:
  - composition type   (layout shape)
  - count              (2-8 repeats)
  - parameter target   (freq, cutoff, amp, pan, ...) — changes labels
  - sound_type         (sine_wave, synth_wave, heartbeat, ...)

Output: commons/audio/rack_configs/compositions/<id>.json

Usage::

    python tools/generate_compositions.py --count 40 --seed 17
    python tools/generate_compositions.py --type sliders_v --clean
    python tools/generate_compositions.py --list

After generation::

    python tools/module_research.py compositions-auto
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "commons" / "audio" / "rack_configs" / "compositions"

# ─── Parameter vocabulary (drives labels) ────────────────────────────────

PARAMETERS = {
    "freq":    {"label": "FREQ",   "min": 20.0, "max": 4000.0, "default": 440.0},
    "cutoff":  {"label": "CUT",    "min": 20.0, "max": 12000.0, "default": 1000.0},
    "reso":    {"label": "RES",    "min": 0.0,  "max": 1.0, "default": 0.3},
    "amp":     {"label": "AMP",    "min": 0.0,  "max": 1.0, "default": 0.7},
    "pan":     {"label": "PAN",    "min": -1.0, "max": 1.0, "default": 0.0},
    "drive":   {"label": "DRIVE",  "min": 0.0,  "max": 10.0, "default": 1.0},
    "depth":   {"label": "DEPTH",  "min": 0.0,  "max": 1.0, "default": 0.5},
    "rate":    {"label": "RATE",   "min": 0.01, "max": 20.0, "default": 2.0},
    "mix":     {"label": "MIX",    "min": 0.0,  "max": 1.0, "default": 0.5},
    "feedback":{"label": "FBK",    "min": 0.0,  "max": 0.95, "default": 0.3},
    "tone":    {"label": "TONE",   "min": 0.0,  "max": 1.0, "default": 0.5},
    "attack":  {"label": "ATK",    "min": 0.001, "max": 2.0, "default": 0.05},
    "decay":   {"label": "DEC",    "min": 0.001, "max": 2.0, "default": 0.2},
    "release": {"label": "REL",    "min": 0.001, "max": 4.0, "default": 0.3},
}

SOUND_TYPES = [
    "basic_sine_wave", "synth_wave", "heartbeat",
    "lab_hum", "pickup_mario", "tunable_becoming",
]

# ─── Composition types (map to UVAC grid + control_definitions) ──────────
#
# Each builder returns (grid, control_definitions). Grid is a 2D array of
# control IDs; control_definitions is a dict keyed by the same IDs. UVAC
# resolves cell positions by layout, so the grid shape *is* the layout.

def _ctrl(ctype: str, param_name: str, label_override: str | None = None) -> dict:
    p = PARAMETERS[param_name]
    ctrl: dict = {
        "type": ctype,
        "label": label_override or p["label"],
        "parameter": param_name,
        "min": p["min"],
        "max": p["max"],
        "default": p["default"],
    }
    return ctrl


def build_sliders_v(n: int, rng: random.Random) -> tuple[list, dict]:
    # n vertical sliders in one horizontal row
    keys = [f"sv_{i}" for i in range(n)]
    grid = [keys]
    defs = {k: _ctrl("slv", rng.choice(list(PARAMETERS.keys()))) for k in keys}
    return grid, defs


def build_sliders_h(n: int, rng: random.Random) -> tuple[list, dict]:
    # n horizontal sliders stacked vertically
    keys = [f"sh_{i}" for i in range(n)]
    grid = [[k] for k in keys]
    defs = {k: _ctrl("slh", rng.choice(list(PARAMETERS.keys()))) for k in keys}
    return grid, defs


def build_knobs(n: int, rng: random.Random) -> tuple[list, dict]:
    keys = [f"kn_{i}" for i in range(n)]
    grid = [keys]
    defs = {k: _ctrl("knob", rng.choice(list(PARAMETERS.keys()))) for k in keys}
    return grid, defs


def build_buttons(n: int, rng: random.Random) -> tuple[list, dict]:
    keys = [f"bt_{i}" for i in range(n)]
    grid = [keys]
    defs: dict = {}
    for i, k in enumerate(keys):
        defs[k] = {
            "type": "btn",
            "label": f"TRIG {i + 1}",
            "parameter": f"trigger_{i}",
            "action": "trigger",
        }
    return grid, defs


def build_meters_v(n: int, rng: random.Random) -> tuple[list, dict]:
    keys = [f"mt_{i}" for i in range(n)]
    grid = [keys]
    defs: dict = {}
    for i, k in enumerate(keys):
        defs[k] = {"type": "mtr", "label": f"METER {i + 1}"}
    return grid, defs


def build_levers_v(n: int, rng: random.Random) -> tuple[list, dict]:
    # n levers in one row
    keys = [f"lv_{i}" for i in range(n)]
    grid = [keys]
    defs = {k: _ctrl("lever", rng.choice(list(PARAMETERS.keys()))) for k in keys}
    return grid, defs


def build_monitor_sliders(n: int, rng: random.Random) -> tuple[list, dict]:
    # Row 1: waveform monitor spanning all n columns
    # Row 2: n vertical sliders
    mon_keys = ["mon"] * n  # UVAC-style: repeated key in a row = span
    slv_keys = [f"sv_{i}" for i in range(n)]
    grid = [mon_keys, slv_keys]
    defs: dict = {
        "mon": {"type": "simple_waveform", "label": "OUT", "parameter": "output"},
    }
    for k in slv_keys:
        defs[k] = _ctrl("slv", rng.choice(list(PARAMETERS.keys())))
    return grid, defs


def build_mixed_row(n: int, rng: random.Random) -> tuple[list, dict]:
    # Alternate knob / slv across one row
    keys = []
    defs: dict = {}
    for i in range(n):
        if i % 2 == 0:
            k = f"kn_{i}"; ctype = "knob"
        else:
            k = f"sv_{i}"; ctype = "slv"
        keys.append(k)
        defs[k] = _ctrl(ctype, rng.choice(list(PARAMETERS.keys())))
    grid = [keys]
    return grid, defs


def build_xy_row(n: int, rng: random.Random) -> tuple[list, dict]:
    # Row of XY pads — 2D control for spatial params
    keys = [f"xy_{i}" for i in range(n)]
    grid = [keys]
    defs: dict = {}
    params = list(PARAMETERS.keys())
    for i, k in enumerate(keys):
        px = rng.choice(params); py = rng.choice(params)
        defs[k] = {
            "type": "xy",
            "label": f"{PARAMETERS[px]['label']}/{PARAMETERS[py]['label']}",
            "parameter_x": px,
            "parameter_y": py,
        }
    return grid, defs


# ─── Composition registry ─────────────────────────────────────────────

TYPES: dict[str, dict] = {
    "sliders_v":       {"build": build_sliders_v,       "count_range": (2, 6), "label_fmt": "{n}x SLIDER V"},
    "sliders_h":       {"build": build_sliders_h,       "count_range": (2, 4), "label_fmt": "{n}x SLIDER H"},
    "knobs":           {"build": build_knobs,           "count_range": (2, 5), "label_fmt": "{n}x KNOB"},
    "buttons":         {"build": build_buttons,         "count_range": (2, 5), "label_fmt": "{n}x BUTTON"},
    "meters_v":        {"build": build_meters_v,        "count_range": (2, 5), "label_fmt": "{n}x METER"},
    "levers_v":        {"build": build_levers_v,        "count_range": (2, 5), "label_fmt": "{n}x LEVER"},
    "monitor_sliders": {"build": build_monitor_sliders, "count_range": (2, 4), "label_fmt": "MON+{n} SLIDERS"},
    "mixed_row":       {"build": build_mixed_row,       "count_range": (3, 6), "label_fmt": "MIX-{n}"},
    "xy_row":          {"build": build_xy_row,          "count_range": (2, 4), "label_fmt": "{n}x XY"},
}


def gen_one(rng: random.Random, type_key: str) -> tuple[str, dict]:
    spec = TYPES[type_key]
    lo, hi = spec["count_range"]
    count = rng.randint(lo, hi)
    label = spec["label_fmt"].format(n=count)
    sound_type = rng.choice(SOUND_TYPES)

    grid, defs = spec["build"](count, rng)

    seed_tag = f"{rng.randint(0, 1 << 20):05x}"
    cid = f"{type_key}_{count}_{sound_type}_{seed_tag}"

    return cid, {
        "rack_info": {
            "name":  label,
            "description": f"{label} — auto-generated UVAC composition. "
                           f"sound_type={sound_type}, composition_type={type_key}.",
            "version": "auto-1",
            "sound_type": sound_type,
            "auto_generated": True,
            "composition_type": type_key,
            "composition_count": count,
        },
        "layout": {
            "padding_px": 20,
            "gap_px": 14,
        },
        "grid": grid,
        "control_definitions": defs,
    }


def generate(count: int, seed: int, type_filter: str | None, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        n = 0
        for p in OUT_DIR.glob("*.json"):
            try: p.unlink(); n += 1
            except Exception: pass
        print(f"[clean] removed {n} files from {OUT_DIR.name}/")

    if type_filter and type_filter not in TYPES:
        print(f"[ERR] unknown type: {type_filter}. Known: {', '.join(TYPES)}")
        return 1

    types = [type_filter] if type_filter else list(TYPES.keys())
    rng = random.Random(seed)
    per = max(1, count // len(types))
    remainder = count - per * len(types)
    emitted = 0
    for i, t in enumerate(types):
        n = per + (1 if i < remainder else 0)
        for _ in range(n):
            cid, cfg = gen_one(rng, t)
            (OUT_DIR / f"{cid}.json").write_text(
                json.dumps(cfg, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            emitted += 1

    print(f"[ok] wrote {emitted} UVAC rack_configs to {OUT_DIR}")
    print("Next: python tools/module_research.py compositions-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=32)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--type", dest="type_filter", help="one of: " + ", ".join(TYPES))
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--clean", action="store_true")
    args = ap.parse_args()

    if args.list:
        for k, v in TYPES.items():
            print(f"  {k:<18s} count {v['count_range'][0]}-{v['count_range'][1]}  '{v['label_fmt']}'")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed}  count={args.count}  type={args.type_filter or 'all'}")
    return generate(args.count, seed, args.type_filter, args.clean)


if __name__ == "__main__":
    sys.exit(main())
