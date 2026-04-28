#!/usr/bin/env python
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "commons" / "installations" / "stand_configs" / "auto"

PALETTES = [
    {
        "metal_color": [0.78, 0.80, 0.84, 1.0],
        "dark_color": [0.07, 0.08, 0.10, 1.0],
        "accent_color": [0.98, 0.60, 0.18, 1.0],
        "screen_color": [0.05, 0.16, 0.18, 1.0],
        "light_color": [1.0, 0.92, 0.78, 1.0],
        "floor_color": [0.13, 0.14, 0.16, 1.0],
    },
    {
        "metal_color": [0.66, 0.69, 0.74, 1.0],
        "dark_color": [0.06, 0.07, 0.08, 1.0],
        "accent_color": [0.35, 0.82, 1.0, 1.0],
        "screen_color": [0.04, 0.11, 0.17, 1.0],
        "light_color": [0.96, 0.97, 1.0, 1.0],
        "floor_color": [0.11, 0.12, 0.14, 1.0],
    },
    {
        "metal_color": [0.72, 0.73, 0.76, 1.0],
        "dark_color": [0.10, 0.10, 0.11, 1.0],
        "accent_color": [0.90, 0.36, 0.28, 1.0],
        "screen_color": [0.10, 0.11, 0.13, 1.0],
        "light_color": [1.0, 0.88, 0.70, 1.0],
        "floor_color": [0.16, 0.16, 0.18, 1.0],
    },
]

FAMILIES = {
    "screen_frame": {"height": (2.4, 3.8), "width": (2.0, 4.0)},
    "audio_totem": {"height": (2.0, 3.4), "width": (1.0, 2.0)},
    "light_stage": {"height": (3.0, 4.6), "width": (3.0, 5.0)},
    "telecom_mast": {"height": (3.4, 5.6), "width": (1.0, 2.5)},
    "media_shelf": {"height": (2.0, 3.0), "width": (2.0, 4.0)},
    "roof_frame": {"height": (3.0, 4.5), "width": (3.0, 5.0)},
}


def qhalf(value: float) -> float:
    return round(value * 2.0) / 2.0


def palette(rng: random.Random) -> dict:
    return dict(rng.choice(PALETTES))


def base_layout(rng: random.Random) -> dict:
    return {"unit_m": 1.0, **palette(rng)}


def upright(x: float, height: float, z: float = 0.0, thickness: float = 0.12) -> dict:
    return {"x": x, "y": round(height * 0.5, 3), "z": z, "height": round(height, 3), "thickness": thickness}


def beam(x: float, y: float, width: float, z: float = 0.0, depth: float = 0.12, thickness: float = 0.12) -> dict:
    return {"x": x, "y": y, "z": z, "width": width, "depth": depth, "thickness": thickness}


def side_speakers(span_w: float, y: float, modules: int = 2) -> list[dict]:
    offset = round(span_w * 0.5 + 0.35, 3)
    return [
        {"x": -offset, "y": y, "z": 0.18, "width": 0.42, "height": 0.36, "depth": 0.38, "modules": modules, "gap": 0.03},
        {"x": offset, "y": y, "z": 0.18, "width": 0.42, "height": 0.36, "depth": 0.38, "modules": modules, "gap": 0.03},
    ]


def build_screen_frame(rng: random.Random) -> tuple[str, dict]:
    span = qhalf(rng.uniform(2.0, 4.0))
    height = qhalf(rng.uniform(2.5, 3.5))
    screen_w = min(span - 0.5, qhalf(rng.uniform(1.5, 2.5)))
    screen_h = qhalf(screen_w * 0.5)
    shelf_y = 0.6 if rng.random() < 0.6 else 0.9
    cid = f"inst_screen_frame_{rng.randint(0, 1 << 20):05x}"
    cfg = {
        "installation_info": {
            "name": f"Screen frame {cid[-5:]}",
            "description": "1m-bay frame with large screen, lower shelf, side speakers, and top light bar.",
            "family": "screen_frame",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": span + 0.8, "depth": 1.0, "height": 0.14},
        "frame": {
            "uprights": [upright(-span * 0.5, height), upright(span * 0.5, height)],
            "beams": [beam(0.0, height, span + 0.2), beam(0.0, shelf_y, span * 0.7, 0.10, 0.18, 0.08)],
        },
        "shelves": [{"x": 0.0, "y": shelf_y, "z": 0.18, "width": qhalf(screen_w), "depth": 0.5, "thickness": 0.06}],
        "screens": [{"x": 0.0, "y": shelf_y + screen_h * 0.65 + 0.3, "z": 0.0, "width": screen_w, "height": screen_h, "depth": 0.08, "frame": 0.06}],
        "speakers": side_speakers(span, shelf_y + 0.2, 2),
        "lights": [{"x": 0.0, "y": height - 0.15, "z": 0.05, "width": span, "count": int(max(3, round(span * 2.0)))}],
        "boxes": [{"x": 0.0, "y": 0.32, "z": 0.22, "width": 0.6, "height": 0.24, "depth": 0.28}],
    }
    return cid, cfg


def build_audio_totem(rng: random.Random) -> tuple[str, dict]:
    height = qhalf(rng.uniform(2.0, 3.0))
    cid = f"inst_audio_totem_{rng.randint(0, 1 << 20):05x}"
    cfg = {
        "installation_info": {
            "name": f"Audio totem {cid[-5:]}",
            "description": "1m column with stacked speakers, half-meter service shelves, and signal boxes.",
            "family": "audio_totem",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": 1.6, "depth": 1.2, "height": 0.12},
        "frame": {
            "uprights": [upright(0.0, height, 0.0, 0.16)],
            "beams": [beam(0.0, 0.8, 0.9, 0.0, 0.26, 0.08), beam(0.0, 1.6, 0.9, 0.0, 0.26, 0.08)],
        },
        "shelves": [
            {"x": 0.0, "y": 0.8, "z": 0.18, "width": 1.0, "depth": 0.5, "thickness": 0.06},
            {"x": 0.0, "y": 1.6, "z": 0.18, "width": 0.5, "depth": 0.5, "thickness": 0.06},
        ],
        "screens": [{"x": 0.0, "y": 2.1, "z": 0.0, "width": 0.5, "height": 0.5, "depth": 0.08, "frame": 0.05}],
        "speakers": [{"x": 0.0, "y": 1.3, "z": 0.18, "width": 0.55, "height": 0.45, "depth": 0.40, "modules": 3, "gap": 0.02}],
        "lights": [{"x": 0.0, "y": height, "z": 0.0, "width": 0.6, "count": 3}],
        "boxes": [{"x": 0.0, "y": 0.3, "z": 0.20, "width": 0.8, "height": 0.25, "depth": 0.32}],
    }
    return cid, cfg


def build_light_stage(rng: random.Random) -> tuple[str, dict]:
    width = qhalf(rng.uniform(3.0, 5.0))
    depth = qhalf(rng.uniform(2.0, 3.0))
    height = qhalf(rng.uniform(3.0, 4.5))
    cid = f"inst_light_stage_{rng.randint(0, 1 << 20):05x}"
    cfg = {
        "installation_info": {
            "name": f"Light stage {cid[-5:]}",
            "description": "2m frame bay scaled into a stage truss with screen, arrays, and lighting line.",
            "family": "light_stage",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": width, "depth": depth, "height": 0.18},
        "frame": {
            "uprights": [
                upright(-width * 0.5, height, -depth * 0.5, 0.14),
                upright(width * 0.5, height, -depth * 0.5, 0.14),
                upright(-width * 0.5, height, depth * 0.5, 0.14),
                upright(width * 0.5, height, depth * 0.5, 0.14),
            ],
            "beams": [
                beam(0.0, height, width, -depth * 0.5),
                beam(0.0, height, width, depth * 0.5),
                beam(-width * 0.5, height, depth, 0.0, 0.12, 0.12),
                beam(width * 0.5, height, depth, 0.0, 0.12, 0.12),
            ],
        },
        "screens": [{"x": 0.0, "y": 1.7, "z": -depth * 0.32, "width": qhalf(width - 1.0), "height": 1.0, "depth": 0.08, "frame": 0.08}],
        "speakers": side_speakers(width, 1.8, 3),
        "lights": [{"x": 0.0, "y": height - 0.15, "z": 0.0, "width": width - 0.3, "count": int(max(6, round(width * 2.5)))}],
        "boxes": [{"x": 0.0, "y": 0.32, "z": depth * 0.28, "width": 1.0, "height": 0.24, "depth": 0.35}],
    }
    return cid, cfg


def build_telecom_mast(rng: random.Random) -> tuple[str, dict]:
    height = qhalf(rng.uniform(4.0, 5.5))
    panel_count = rng.randint(3, 5)
    cid = f"inst_telecom_mast_{rng.randint(0, 1 << 20):05x}"
    panels = []
    radius = 0.45
    for idx in range(panel_count):
        angle = idx / float(panel_count) * math.tau
        panels.append(
            {
                "x": round(radius * math.cos(angle), 3),
                "y": height - 0.95,
                "z": round(radius * math.sin(angle), 3),
                "width": 0.18,
                "height": 1.1,
                "depth": 0.10,
            }
        )
    cfg = {
        "installation_info": {
            "name": f"Telecom mast {cid[-5:]}",
            "description": "1m service base with tall mast, antenna panels, and equipment boxes.",
            "family": "telecom_mast",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": 1.6, "depth": 1.6, "height": 0.10},
        "frame": {
            "uprights": [upright(0.0, height, 0.0, 0.18)],
            "beams": [beam(0.0, 2.0, 1.0, 0.0, 0.26, 0.08)],
        },
        "shelves": [{"x": 0.0, "y": 2.0, "z": 0.0, "width": 1.0, "depth": 0.5, "thickness": 0.06}],
        "speakers": [],
        "screens": [],
        "lights": [{"x": 0.0, "y": height - 0.1, "z": 0.0, "width": 0.5, "count": 2}],
        "panels": panels,
        "boxes": [
            {"x": 0.0, "y": 0.45, "z": 0.18, "width": 0.8, "height": 0.45, "depth": 0.40},
            {"x": 0.0, "y": 1.3, "z": 0.18, "width": 0.55, "height": 0.30, "depth": 0.25},
        ],
    }
    return cid, cfg


def build_media_shelf(rng: random.Random) -> tuple[str, dict]:
    width = qhalf(rng.uniform(2.0, 4.0))
    height = qhalf(rng.uniform(2.0, 3.0))
    screen_w = qhalf(rng.uniform(1.0, 2.0))
    cid = f"inst_media_shelf_{rng.randint(0, 1 << 20):05x}"
    cfg = {
        "installation_info": {
            "name": f"Media shelf {cid[-5:]}",
            "description": "1m frame wall with 0.5m shelves, centered display, and speaker/utility mix.",
            "family": "media_shelf",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": width + 0.6, "depth": 1.2, "height": 0.12},
        "frame": {
            "uprights": [upright(-width * 0.5, height), upright(0.0, height), upright(width * 0.5, height)],
            "beams": [beam(0.0, height, width + 0.2), beam(0.0, 0.9, width + 0.2), beam(0.0, 1.7, width + 0.2)],
        },
        "shelves": [
            {"x": 0.0, "y": 0.9, "z": 0.15, "width": width, "depth": 0.5, "thickness": 0.06},
            {"x": 0.0, "y": 1.7, "z": 0.15, "width": width, "depth": 0.5, "thickness": 0.06},
        ],
        "screens": [{"x": 0.0, "y": 1.35, "z": 0.0, "width": screen_w, "height": 1.0, "depth": 0.08, "frame": 0.06}],
        "speakers": side_speakers(screen_w + 0.5, 1.1, 1),
        "lights": [{"x": 0.0, "y": height - 0.15, "z": 0.02, "width": width, "count": int(max(4, round(width * 2.0)))}],
        "boxes": [
            {"x": -width * 0.25, "y": 0.35, "z": 0.20, "width": 0.5, "height": 0.28, "depth": 0.28},
            {"x": width * 0.25, "y": 0.35, "z": 0.20, "width": 0.5, "height": 0.28, "depth": 0.28},
        ],
    }
    return cid, cfg


def build_roof_frame(rng: random.Random) -> tuple[str, dict]:
    width = qhalf(rng.uniform(3.0, 5.0))
    depth = qhalf(rng.uniform(2.0, 3.0))
    height = qhalf(rng.uniform(3.0, 4.5))
    roof_h = height + 0.5
    cid = f"inst_roof_frame_{rng.randint(0, 1 << 20):05x}"
    cfg = {
        "installation_info": {
            "name": f"Roof frame {cid[-5:]}",
            "description": "2m canopy frame for screens, lights, and suspended audio arrays.",
            "family": "roof_frame",
            "auto_generated": True,
        },
        "layout": base_layout(rng),
        "platform": {"width": width, "depth": depth, "height": 0.18},
        "frame": {
            "uprights": [
                upright(-width * 0.5, height, -depth * 0.5, 0.14),
                upright(width * 0.5, height, -depth * 0.5, 0.14),
                upright(-width * 0.5, height, depth * 0.5, 0.14),
                upright(width * 0.5, height, depth * 0.5, 0.14),
            ],
            "beams": [
                beam(0.0, height, width, -depth * 0.5),
                beam(0.0, height, width, depth * 0.5),
                beam(0.0, roof_h, width * 0.7, 0.0),
            ],
            "braces": [
                {"x": -width * 0.25, "y": height + 0.2, "z": -depth * 0.25, "height": 1.0, "thickness": 0.05, "rot_z": -40.0},
                {"x": width * 0.25, "y": height + 0.2, "z": -depth * 0.25, "height": 1.0, "thickness": 0.05, "rot_z": 40.0},
            ],
        },
        "screens": [{"x": 0.0, "y": 1.8, "z": -depth * 0.28, "width": qhalf(width - 1.2), "height": 1.0, "depth": 0.08, "frame": 0.08}],
        "speakers": side_speakers(width - 0.6, 2.0, 2),
        "lights": [{"x": 0.0, "y": height - 0.05, "z": 0.0, "width": width - 0.5, "count": int(max(6, round(width * 2.0)))}],
        "shelves": [{"x": 0.0, "y": 0.9, "z": depth * 0.22, "width": 1.0, "depth": 0.5, "thickness": 0.06}],
        "boxes": [{"x": 0.0, "y": 0.35, "z": depth * 0.24, "width": 1.0, "height": 0.24, "depth": 0.35}],
    }
    return cid, cfg


BUILDERS = {
    "screen_frame": build_screen_frame,
    "audio_totem": build_audio_totem,
    "light_stage": build_light_stage,
    "telecom_mast": build_telecom_mast,
    "media_shelf": build_media_shelf,
    "roof_frame": build_roof_frame,
}


def quantify(cfg: dict) -> dict:
    counts = {
        "screens": len(cfg.get("screens", [])),
        "speakers": sum(int(s.get("modules", 1)) for s in cfg.get("speakers", [])),
        "lights": sum(int(l.get("count", 1)) for l in cfg.get("lights", [])),
        "shelves": len(cfg.get("shelves", [])),
        "panels": len(cfg.get("panels", [])),
        "boxes": len(cfg.get("boxes", [])),
        "uprights": len(cfg.get("frame", {}).get("uprights", [])),
    }
    xs = []
    ys = []
    for collection in ("screens", "speakers", "lights", "shelves", "panels", "boxes"):
        for item in cfg.get(collection, []):
            x = float(item.get("x", 0.0))
            w = float(item.get("width", 0.12))
            y = float(item.get("y", 0.0))
            h = float(item.get("height", 0.12))
            xs.extend([x - w * 0.5, x + w * 0.5])
            ys.append(y + h * 0.5)
    for post in cfg.get("frame", {}).get("uprights", []):
        x = float(post.get("x", 0.0))
        t = float(post.get("thickness", 0.12))
        xs.extend([x - t * 0.5, x + t * 0.5])
        ys.append(float(post.get("y", 0.0)) + float(post.get("height", 1.0)) * 0.5)
    width = (max(xs) - min(xs)) if xs else 1.0
    height = max(ys) if ys else 1.0
    return {"counts": counts, "width": width, "height": height}


def score_config(family: str, cfg: dict) -> float:
    q = quantify(cfg)
    counts = q["counts"]
    width = q["width"]
    height = q["height"]
    score = 100.0
    score += (counts["screens"] > 0) * 6.0
    score += min(counts["lights"], 10) * 0.5
    score += min(counts["shelves"], 3) * 2.0
    score += min(counts["speakers"], 6) * 1.2
    score += min(counts["panels"], 5) * 1.0
    score -= abs((height / max(width, 0.5)) - 1.2) * 10.0
    if family == "telecom_mast":
        score += counts["panels"] * 4.0
        score += height * 2.0
        score -= counts["screens"] * 2.0
    elif family == "light_stage":
        score += counts["lights"] * 1.6
        score += (counts["uprights"] >= 4) * 8.0
        score += counts["screens"] * 3.0
    elif family == "roof_frame":
        score += counts["lights"] * 1.2
        score += counts["speakers"] * 1.0
        score += counts["screens"] * 2.0
    elif family == "screen_frame":
        score += counts["screens"] * 6.0
        score += counts["speakers"] * 0.8
    elif family == "media_shelf":
        score += counts["shelves"] * 3.0
        score += counts["screens"] * 3.0
    elif family == "audio_totem":
        score += counts["speakers"] * 2.0
        score += counts["shelves"] * 2.0
        score += height * 1.5
    return score


def write_config(cid: str, cfg: dict) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / f"{cid}.json").write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")


def auto_generate(seed: int, family_filter: str | None, candidates: int, keep: int, clean: bool) -> int:
    if clean and OUT_DIR.exists():
        for p in OUT_DIR.glob("*.json"):
            try:
                p.unlink()
            except Exception:
                pass
    families = [family_filter] if family_filter else list(BUILDERS.keys())
    for family in families:
        if family not in BUILDERS:
            print(f"[ERR] unknown family: {family}")
            return 1
    rng = random.Random(seed)
    total = 0
    for family in families:
        scored: list[tuple[float, str, dict]] = []
        for _ in range(candidates):
            cid, cfg = BUILDERS[family](rng)
            score = score_config(family, cfg)
            cfg["installation_info"]["auto_score"] = round(score, 2)
            scored.append((score, cid, cfg))
        scored.sort(key=lambda item: item[0], reverse=True)
        for rank, (_, cid, cfg) in enumerate(scored[:keep], start=1):
            cfg["installation_info"]["selection_rank"] = rank
            write_config(cid, cfg)
            total += 1
        print(f"[auto] {family}: kept {min(keep, len(scored))}/{len(scored)} (best={scored[0][0]:.2f})")
    print(f"[ok] wrote {total} installation configs to {OUT_DIR}")
    print("Next: python tools/module_research.py installation-stands-auto --force")
    return 0


def generate(count: int, seed: int, family_filter: str | None, clean: bool) -> int:
    if clean and OUT_DIR.exists():
        for p in OUT_DIR.glob("*.json"):
            try:
                p.unlink()
            except Exception:
                pass
    families = [family_filter] if family_filter else list(BUILDERS.keys())
    for family in families:
        if family not in BUILDERS:
            print(f"[ERR] unknown family: {family}")
            return 1
    rng = random.Random(seed)
    per_family = max(1, count // len(families))
    remainder = count - per_family * len(families)
    total = 0
    for idx, family in enumerate(families):
        runs = per_family + (1 if idx < remainder else 0)
        for _ in range(runs):
            cid, cfg = BUILDERS[family](rng)
            write_config(cid, cfg)
            total += 1
    print(f"[ok] wrote {total} installation configs to {OUT_DIR}")
    print("Next: python tools/module_research.py installation-stands-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=12)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--family", help=", ".join(BUILDERS))
    ap.add_argument("--clean", action="store_true")
    ap.add_argument("--auto", action="store_true")
    ap.add_argument("--candidates", type=int, default=12)
    ap.add_argument("--keep", type=int, default=2)
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    if args.list:
        for family in BUILDERS:
            print(f"  {family}")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed} family={args.family or 'all'}")
    if args.auto:
        return auto_generate(seed, args.family, args.candidates, args.keep, args.clean)
    return generate(args.count, seed, args.family, args.clean)


if __name__ == "__main__":
    raise SystemExit(main())
