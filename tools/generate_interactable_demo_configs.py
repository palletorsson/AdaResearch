#!/usr/bin/env python
"""
generate_interactable_demo_configs.py - emit JSON configs for configurable
InteractableDemo boards.

Each config reuses the same component vocabulary as commons/interactables/
InteractableDemo.gd, but rearranges which rows appear and how dense each row is.
One config = one composite board = one gallery render.

Usage:
    python tools/generate_interactable_demo_configs.py
    python tools/generate_interactable_demo_configs.py --count 18 --seed 46
    python tools/generate_interactable_demo_configs.py --family hybrid_console
    python tools/generate_interactable_demo_configs.py --auto --candidates 24 --keep 2
    python tools/generate_interactable_demo_configs.py --clean
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
OUT_DIR = REPO / "commons" / "interactables" / "demo_configs" / "auto"

CONTROLS = [
    {"scene": "res://commons/interactables/push_button.tscn", "label": "BUTTON", "y": 0.0},
    {"scene": "res://commons/interactables/push_button_front.tscn", "label": "BUTTON\nFRONT", "y": 0.0, "rot_y": 180.0},
    {"scene": "res://commons/interactables/dial_smooth.tscn", "label": "KNOB", "y": 0.0},
    {"scene": "res://commons/interactables/slider_smooth.tscn", "label": "SLIDER V", "y": 0.0},
    {"scene": "res://commons/interactables/slider_horizontal.tscn", "label": "SLIDER H", "y": 0.0},
    {"scene": "res://commons/interactables/slider_snap.tscn", "label": "SNAP", "y": 0.0},
    {"scene": "res://commons/interactables/slider_zero.tscn", "label": "ZERO", "y": 0.0},
    {"scene": "res://commons/interactables/lever_smooth.tscn", "label": "LEVER", "y": 0.0},
    {"scene": "res://commons/interactables/wheel_smooth.tscn", "label": "WHEEL", "y": 0.0},
    {"scene": "res://commons/interactables/joystick_smooth.tscn", "label": "JOYSTICK", "y": -0.05},
    {"scene": "res://commons/interactables/slider_plane.tscn", "label": "XY PAD", "y": -0.05},
]

EXTRA_BUTTONS = [
    {"type": "rect_sm", "label": "RECT SM"},
    {"type": "rect_wide", "label": "RECT WIDE"},
    {"type": "rect_tall", "label": "RECT TALL"},
    {"type": "toggle", "label": "TOGGLE"},
]

PASSIVE_ELEMENTS = [
    {"builder": "build_speaker_dots", "label": "SPEAKER DOTS", "width": 1},
    {"builder": "build_speaker_lines", "label": "SPEAKER LINES", "width": 1},
    {"builder": "build_speaker_grid", "label": "SPEAKER GRID", "width": 1},
    {"builder": "build_vu_meter_v", "label": "VU METER V", "width": 1},
    {"builder": "build_vu_meter_h", "label": "VU METER H", "width": 1},
    {"monitor": "scope", "slots": 2, "label": "SCOPE", "width": 2},
    {"monitor": "scope", "slots": 3, "label": "SCOPE WIDE", "width": 3},
    {"monitor": "spectrum", "slots": 2, "label": "SPECTRUM", "width": 2},
    {"monitor": "lissajous", "slots": 2, "label": "LISSAJOUS", "width": 2},
]

COMPOUNDS = [
    {"type": "sliders_v", "count": 2, "label": "2x SLIDER V", "width": 2},
    {"type": "sliders_v", "count": 3, "label": "3x SLIDER V", "width": 2},
    {"type": "sliders_v", "count": 4, "label": "4x SLIDER V", "width": 2},
    {"type": "sliders_h", "count": 2, "label": "2x SLIDER H", "width": 2},
    {"type": "sliders_h", "count": 3, "label": "3x SLIDER H", "width": 2},
    {"type": "sliders_h", "count": 4, "label": "4x SLIDER H", "width": 2},
    {"type": "monitor_sliders", "count": 3, "label": "MONITOR+SLIDERS", "width": 2},
    {"type": "speaker_meters", "count": 2, "label": "SPEAKER+METERS", "width": 2},
    {"type": "meters_v", "count": 3, "label": "3x METERS", "width": 1},
]

NEW_MODULES = [
    {"type": "touch_grid", "label": "TOUCH\nGRID", "width": 1},
    {"type": "rotary_selector", "label": "ROTARY\nSELECTOR", "width": 1},
    {"type": "needle_meter", "label": "NEEDLE\nMETER", "width": 1},
    {"type": "patch_matrix", "label": "PATCH\nMATRIX", "width": 1},
    {"type": "text_static_1", "label": "TEXT 1", "width": 1},
    {"type": "text_static_2", "label": "TEXT 2", "width": 2},
    {"type": "text_static_3", "label": "TEXT 3", "width": 3},
    {"type": "text_scroll_1", "label": "SCROLL 1", "width": 1},
    {"type": "text_scroll_2", "label": "SCROLL 2", "width": 2},
    {"type": "text_scroll_3", "label": "SCROLL 3", "width": 3},
]

PALETTES = [
    {
        "panel_color": [0.78, 0.75, 0.67, 1.0],
        "frame_color": [0.25, 0.23, 0.20, 1.0],
        "accent_color": [0.75, 0.38, 0.13, 1.0],
        "dark_color": [0.10, 0.10, 0.10, 1.0],
        "cream_color": [0.78, 0.75, 0.67, 1.0],
    },
    {
        "panel_color": [0.66, 0.69, 0.72, 1.0],
        "frame_color": [0.18, 0.22, 0.27, 1.0],
        "accent_color": [0.94, 0.48, 0.19, 1.0],
        "dark_color": [0.07, 0.08, 0.10, 1.0],
        "cream_color": [0.82, 0.84, 0.88, 1.0],
    },
    {
        "panel_color": [0.64, 0.60, 0.56, 1.0],
        "frame_color": [0.20, 0.16, 0.15, 1.0],
        "accent_color": [0.86, 0.25, 0.48, 1.0],
        "dark_color": [0.12, 0.10, 0.11, 1.0],
        "cream_color": [0.80, 0.76, 0.70, 1.0],
    },
    {
        "panel_color": [0.56, 0.64, 0.61, 1.0],
        "frame_color": [0.16, 0.20, 0.19, 1.0],
        "accent_color": [0.27, 0.73, 0.90, 1.0],
        "dark_color": [0.06, 0.08, 0.08, 1.0],
        "cream_color": [0.77, 0.81, 0.79, 1.0],
    },
]

FAMILIES = {
    "control_survey": {
        "controls": (7, 10),
        "extra_buttons": (2, 4),
        "passive": (0, 2),
        "compounds": (0, 2),
        "new_modules": (0, 2),
        "spacing": (0.24, 0.30),
    },
    "hybrid_console": {
        "controls": (4, 6),
        "extra_buttons": (1, 3),
        "passive": (2, 4),
        "compounds": (2, 4),
        "new_modules": (2, 4),
        "spacing": (0.25, 0.31),
    },
    "passive_matrix": {
        "controls": (2, 4),
        "extra_buttons": (0, 1),
        "passive": (4, 6),
        "compounds": (1, 2),
        "new_modules": (1, 3),
        "spacing": (0.24, 0.29),
    },
    "compound_bench": {
        "controls": (3, 5),
        "extra_buttons": (0, 2),
        "passive": (1, 2),
        "compounds": (4, 6),
        "new_modules": (0, 2),
        "spacing": (0.25, 0.32),
    },
    "prototype_wall": {
        "controls": (2, 4),
        "extra_buttons": (1, 2),
        "passive": (1, 2),
        "compounds": (0, 2),
        "new_modules": (5, 7),
        "spacing": (0.23, 0.29),
    },
    "text_signal_lab": {
        "controls": (2, 4),
        "extra_buttons": (0, 2),
        "passive": (2, 3),
        "compounds": (1, 2),
        "new_modules": (4, 6),
        "spacing": (0.24, 0.30),
    },
}

ROW_TARGETS = {
    "controls": 7.0,
    "passive_elements": 5.0,
    "compounds": 4.5,
    "new_modules": 4.5,
}


def _sample(pool: list[dict], count_range: tuple[int, int], rng: random.Random) -> list[dict]:
    lo, hi = count_range
    n = rng.randint(lo, min(hi, len(pool)))
    return rng.sample(pool, n)


def _row_slots(items: list[dict]) -> float:
    total = 0.0
    for item in items:
        total += float(item.get("width", 1))
    return total


def _spacing_penalty(spacing: float, target: float) -> float:
    return abs(spacing - target) * 14.0


def _score_config(family: str, cfg: dict) -> float:
    score = 100.0
    layout = cfg["layout"]
    rows = {
        "controls": list(cfg.get("controls", [])) + list(cfg.get("extra_buttons", [])),
        "passive_elements": list(cfg.get("passive_elements", [])),
        "compounds": list(cfg.get("compounds", [])),
        "new_modules": list(cfg.get("new_modules", [])),
    }

    slot_counts = {name: _row_slots(items) for name, items in rows.items()}
    active_rows = [name for name, slots in slot_counts.items() if slots > 0.0]
    if len(active_rows) < 2:
        score -= 25.0

    for name, slots in slot_counts.items():
        if slots <= 0.0:
            continue
        score -= abs(slots - ROW_TARGETS[name]) * 5.0
        if slots < 2.0:
            score -= 10.0
        if slots > 8.5:
            score -= (slots - 8.5) * 8.0

    nonzero_slots = [slot_counts[name] for name in active_rows]
    if nonzero_slots:
        score -= (max(nonzero_slots) - min(nonzero_slots)) * 3.5

    row_drop_1 = layout["row_y"] - layout["row2_y"]
    row_drop_2 = layout["row2_y"] - layout["row3_y"]
    row_drop_3 = layout["row3_y"] - layout["row4_y"]
    score -= abs(row_drop_1 - 0.43) * 28.0
    score -= abs(row_drop_2 - 0.43) * 20.0
    score -= abs(row_drop_3 - 0.43) * 16.0
    score -= _spacing_penalty(layout["spacing"], 0.265)

    if family == "control_survey":
        score += slot_counts["controls"] * 1.5
        score -= slot_counts["new_modules"] * 1.5
    elif family == "hybrid_console":
        if slot_counts["controls"] >= 5 and slot_counts["passive_elements"] >= 4 and slot_counts["compounds"] >= 4:
            score += 8.0
    elif family == "passive_matrix":
        score += slot_counts["passive_elements"] * 2.2
        score -= slot_counts["controls"] * 0.8
    elif family == "compound_bench":
        score += slot_counts["compounds"] * 2.0
        if slot_counts["controls"] > 6:
            score -= 6.0
    elif family == "prototype_wall":
        score += slot_counts["new_modules"] * 2.0
        if slot_counts["new_modules"] < 5:
            score -= 14.0
    elif family == "text_signal_lab":
        textish = sum(1 for item in cfg.get("new_modules", []) if str(item.get("type", "")).startswith("text_"))
        score += textish * 3.0

    return score


def _family_titles(family: str) -> dict:
    pretty = family.replace("_", " ").title()
    return {
        "main": pretty.upper(),
        "row2": "PASSIVE + MONITORS",
        "row3": "COMPOUND ARRANGEMENTS",
        "row4": "PROTOTYPE MODULES",
    }


def _build_config(family: str, rng: random.Random) -> tuple[str, dict]:
    spec = FAMILIES[family]
    controls = _sample(CONTROLS, spec["controls"], rng)
    extra_buttons = _sample(EXTRA_BUTTONS, spec["extra_buttons"], rng)
    passive = _sample(PASSIVE_ELEMENTS, spec["passive"], rng)
    compounds = _sample(COMPOUNDS, spec["compounds"], rng)
    new_modules = _sample(NEW_MODULES, spec["new_modules"], rng)
    palette = dict(rng.choice(PALETTES))
    spacing = round(rng.uniform(*spec["spacing"]), 3)
    row_y = round(rng.uniform(1.00, 1.15), 3)
    row2_y = round(row_y - rng.uniform(0.38, 0.50), 3)
    row3_y = round(row2_y - rng.uniform(0.38, 0.50), 3)
    row4_y = round(row3_y - rng.uniform(0.38, 0.50), 3)
    seed_tag = f"{rng.randint(0, 1 << 20):05x}"
    cid = f"idem_{family}_{seed_tag}"
    pretty_name = family.replace("_", " ").title()
    cfg = {
        "demo_info": {
            "name": pretty_name,
            "description": f"Auto-generated {family} board composed from the InteractableDemo vocabulary.",
            "family": family,
            "auto_generated": True,
        },
        "titles": _family_titles(family),
        "layout": {
            **palette,
            "spacing": spacing,
            "control_z": 0.02,
            "label_y_offset": -0.18,
            "row_y": row_y,
            "row2_y": row2_y,
            "row3_y": row3_y,
            "row4_y": row4_y,
        },
        "controls": controls,
        "extra_buttons": extra_buttons,
        "passive_elements": passive,
        "compounds": compounds,
        "new_modules": new_modules,
    }
    cfg["demo_info"]["name"] = f"{pretty_name} {seed_tag}"
    return cid, cfg


def _write_config(cid: str, cfg: dict) -> None:
    (OUT_DIR / f"{cid}.json").write_text(
        json.dumps(cfg, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def auto_generate(seed: int, family_filter: str | None, candidates: int, keep: int, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        removed = 0
        for p in OUT_DIR.glob("*.json"):
            try:
                p.unlink()
                removed += 1
            except Exception:
                pass
        print(f"[clean] removed {removed} files from {OUT_DIR}")

    families = [family_filter] if family_filter else list(FAMILIES.keys())
    for family in families:
        if family not in FAMILIES:
            print(f"[ERR] unknown family: {family}. Known: {', '.join(FAMILIES)}")
            return 1

    rng = random.Random(seed)
    emitted = 0
    for family in families:
        scored: list[tuple[float, str, dict]] = []
        for _ in range(candidates):
            cid, cfg = _build_config(family, rng)
            score = _score_config(family, cfg)
            cfg.setdefault("demo_info", {})["auto_score"] = round(score, 2)
            scored.append((score, cid, cfg))
        scored.sort(key=lambda item: item[0], reverse=True)
        for rank, (_, cid, cfg) in enumerate(scored[:keep], start=1):
            cfg["demo_info"]["selection_rank"] = rank
            _write_config(cid, cfg)
            emitted += 1
        best_score = scored[0][0] if scored else 0.0
        print(f"[auto] {family}: kept {min(keep, len(scored))}/{len(scored)} (best={best_score:.2f})")

    print(f"[ok] wrote {emitted} interactable demo configs to {OUT_DIR}")
    print("Next: python tools/module_research.py interactable-layouts-auto --force")
    return 0


def generate(count: int, seed: int, family_filter: str | None, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        removed = 0
        for p in OUT_DIR.glob("*.json"):
            try:
                p.unlink()
                removed += 1
            except Exception:
                pass
        print(f"[clean] removed {removed} files from {OUT_DIR}")

    families = [family_filter] if family_filter else list(FAMILIES.keys())
    for family in families:
        if family not in FAMILIES:
            print(f"[ERR] unknown family: {family}. Known: {', '.join(FAMILIES)}")
            return 1

    rng = random.Random(seed)
    per_family = max(1, count // len(families))
    remainder = count - per_family * len(families)
    emitted = 0
    for idx, family in enumerate(families):
        n = per_family + (1 if idx < remainder else 0)
        for _ in range(n):
            cid, cfg = _build_config(family, rng)
            _write_config(cid, cfg)
            emitted += 1

    print(f"[ok] wrote {emitted} interactable demo configs to {OUT_DIR}")
    print("Next: python tools/module_research.py interactable-layouts-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=12)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--family", help=", ".join(FAMILIES))
    ap.add_argument("--clean", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--auto", action="store_true")
    ap.add_argument("--candidates", type=int, default=18)
    ap.add_argument("--keep", type=int, default=2)
    args = ap.parse_args()

    if args.list:
        for family, spec in FAMILIES.items():
            print(f"  {family:<16s} controls={spec['controls']} passive={spec['passive']} compounds={spec['compounds']} new={spec['new_modules']}")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    if args.auto:
        print(f"seed={seed} candidates={args.candidates} keep={args.keep} family={args.family or 'all'} mode=auto")
        return auto_generate(seed, args.family, args.candidates, args.keep, args.clean)
    print(f"seed={seed} count={args.count} family={args.family or 'all'} mode=sample")
    return generate(args.count, seed, args.family, args.clean)


if __name__ == "__main__":
    raise SystemExit(main())
