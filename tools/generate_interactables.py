#!/usr/bin/env python
"""
generate_interactables.py — emit parametric variants of the UVAC
interactable control types, for auto-research of "what does a good
playable control look like?".

Each interactable (slider, knob, button, lever, etc.) has a handful of
DNA fields the rack renderer consumes via UVAC's control_definition
dict: type × label × parameter × min × max × default × color × step.
Varying these produces N differently-tuned instances of the same
control, all rendered as distinct PNGs via the existing
capture_rack_configs.gd (single-config mode).

Output: each variant is wrapped in a minimal rack_config (one-cell grid)
and saved as an individual JSON under:
  commons/audio/rack_configs/auto_interactables/<variant>.json

Why wrap in a rack_config? So the existing Godot renderer can consume
the variant without a new script. One variant = one rack = one PNG.

Usage::

    python tools/generate_interactables.py                     # 30 default
    python tools/generate_interactables.py --count 60
    python tools/generate_interactables.py --type knob         # one family
    python tools/generate_interactables.py --clean             # wipe first

After generation, run::

    python tools/module_research.py interactables-auto
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
OUT_DIR = REPO / "commons" / "audio" / "rack_configs" / "auto_interactables"

# ─── Variant space ───────────────────────────────────────────────────────
#
# Each family declares its variable dimensions. The cross-product is
# sampled (not fully enumerated — often too many combinations) with the
# given rng to produce N variants.

PARAMETERS = [
    "freq", "cutoff", "reso", "drive", "depth", "rate", "mix",
    "attack", "decay", "sustain", "release", "pan", "detune",
    "fold", "bias", "threshold", "feedback", "tone",
]

COLORS = [
    "#ff4444", "#ff8844", "#ffcc44", "#88ff44", "#44ffaa",
    "#44ccff", "#4488ff", "#8844ff", "#cc44ff", "#ff44aa",
]

RANGE_PROFILES = [
    ("unit",    0.0, 1.0),     # 0-1 normalized
    ("bipolar", -1.0, 1.0),    # -1 to 1
    ("db",      -60.0, 12.0),  # dB
    ("hz_low",  20.0, 200.0),
    ("hz_mid",  200.0, 2000.0),
    ("hz_high", 2000.0, 20000.0),
    ("time_ms", 1.0, 2000.0),
    ("percent", 0.0, 100.0),
]

STEP_OPTS = [
    ("smooth", None),
    ("step_3", 0.333),
    ("step_5", 0.2),
    ("step_7", 0.143),
    ("step_10", 0.1),
]

# Families: each lists the variant DIMENSIONS exposed. Dimensions not
# listed default to sensible values per family.
FAMILIES: dict[str, dict] = {
    "slider": {
        "types":   ["slider", "slv", "slh", "sls", "slz"],
        "vary":    ["type", "param", "range", "color"],
    },
    "knob": {
        "types":   ["knob"],
        "vary":    ["param", "range", "color"],
    },
    "wheel": {
        "types":   ["wheel"],
        "vary":    ["param", "range", "color"],
    },
    "lever": {
        "types":   ["lever"],
        "vary":    ["param", "range", "color"],
    },
    "button": {
        "types":   ["btn"],
        "vary":    ["param", "action", "color"],
        "actions": ["trigger", "toggle", "momentary"],
    },
    "xy": {
        "types":   ["xy"],
        "vary":    ["param_x", "param_y", "range", "color"],
    },
    "joystick": {
        "types":   ["joystick"],
        "vary":    ["param_x", "param_y", "range", "color"],
    },
    "dial": {
        "types":   ["dial"],
        "vary":    ["param", "range", "color", "steps"],
    },
}

# ─── Builders ────────────────────────────────────────────────────────────

def _wrap_as_rack(variant_id: str, ctrl_def: dict, description: str) -> dict:
    """Wrap a single control_definition in a minimal rack_config so the
    existing Godot renderer can consume it."""
    return {
        "rack_info": {
            "name": variant_id,
            "description": description,
            "version": "auto-1",
            "sound_type": "basic_sine_wave",
            "auto_generated": True,
            "family": "interactable",
        },
        "layout": {
            "padding_px": 30,
            "gap_px": 10,
            "hide_selection": True,
            "hide_buttons": True,
        },
        "grid": [["ctrl"]],
        "control_definitions": {"ctrl": ctrl_def},
    }


def _build_variant(family: str, rng: random.Random) -> tuple[str, dict]:
    fam = FAMILIES[family]
    ctype = rng.choice(fam["types"])
    vary = fam["vary"]

    # Common axes
    param = rng.choice(PARAMETERS) if "param" in vary else "freq"
    range_name, lo, hi = rng.choice(RANGE_PROFILES) if "range" in vary else ("unit", 0.0, 1.0)
    color = rng.choice(COLORS) if "color" in vary else "#8844ff"
    step_name, step_val = rng.choice(STEP_OPTS) if "steps" in vary else ("smooth", None)

    # Family-specific axes
    param_x = rng.choice(PARAMETERS) if "param_x" in vary else "x"
    param_y = rng.choice(PARAMETERS) if "param_y" in vary else "y"
    action = rng.choice(fam.get("actions", ["trigger"])) if "action" in vary else "trigger"

    # Build control_definition
    ctrl: dict = {
        "type": ctype,
        "label": param.upper()[:6],
        "color": color,
    }

    # Two-axis controls
    if ctype in ("xy", "joystick"):
        ctrl["parameter_x"] = param_x
        ctrl["parameter_y"] = param_y
        ctrl["label"] = f"{param_x.upper()[:3]}/{param_y.upper()[:3]}"
        descr = f"{ctype.upper()} — x:{param_x} y:{param_y}, color {color}"
    # Buttons
    elif ctype == "btn":
        ctrl["parameter"] = param
        ctrl["action"] = action
        ctrl["label"] = f"{param[:5].upper()}"
        descr = f"BTN — {action} on {param}, color {color}"
    # Labels / meters (no-op for single-cell auto)
    elif ctype in ("label", "meter"):
        ctrl = {"type": ctype, "label": param.upper(), "text": param.upper()}
        descr = f"{ctype.upper()} — {param}"
    # Everything else: single-param with range
    else:
        ctrl["parameter"] = param
        ctrl["min"] = lo
        ctrl["max"] = hi
        ctrl["default"] = (lo + hi) * 0.5 if lo >= 0 else 0.0
        if step_val is not None:
            ctrl["step"] = step_val
        descr = f"{ctype.upper()} — {param} {range_name}({lo:g}-{hi:g}) {step_name}, color {color}"

    # Make a short unique variant id
    seed_hex = f"{rng.randint(0, 1 << 24):06x}"
    variant_id = f"auto_{family}_{ctype}_{param}_{seed_hex}"[:64]
    return variant_id, _wrap_as_rack(variant_id, ctrl, descr)


def generate(count: int, seed: int, family_filter: str | None, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        n = 0
        for p in OUT_DIR.glob("*.json"):
            try: p.unlink(); n += 1
            except Exception: pass
        print(f"[clean] removed {n} files from {OUT_DIR.name}/")

    families = [family_filter] if family_filter else list(FAMILIES.keys())
    for f in families:
        if f not in FAMILIES:
            print(f"[ERR] unknown family: {f}. Known: {', '.join(FAMILIES)}")
            return 1

    rng = random.Random(seed)
    per_fam = max(1, count // len(families))
    remainder = count - per_fam * len(families)
    emitted = 0
    for i, fam in enumerate(families):
        n = per_fam + (1 if i < remainder else 0)
        for _ in range(n):
            variant_id, cfg = _build_variant(fam, rng)
            (OUT_DIR / f"{variant_id}.json").write_text(
                json.dumps(cfg, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            emitted += 1

    print(f"[ok] wrote {emitted} interactable variants to {OUT_DIR}")
    print("Next: python tools/module_research.py interactables-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=30, help="total variants to emit")
    ap.add_argument("--seed", type=int, default=None, help="RNG seed (random by default)")
    ap.add_argument("--type", dest="family", help="only this family: " + ", ".join(FAMILIES))
    ap.add_argument("--list", action="store_true", help="list families + exit")
    ap.add_argument("--clean", action="store_true", help="wipe auto_interactables/ first")
    args = ap.parse_args()

    if args.list:
        for name, fam in FAMILIES.items():
            print(f"  {name:<10s} types={fam['types']}  vary={fam['vary']}")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed}  count={args.count}  family={args.family or 'all'}")
    return generate(args.count, seed, args.family, args.clean)


if __name__ == "__main__":
    sys.exit(main())
