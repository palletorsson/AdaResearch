#!/usr/bin/env python
"""
morphology_research.py - Batch-render and auto-research morphology grammar configs.
DNA = role hierarchy + selector path + recursive budget decay.
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import random
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GODOT_EXE = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
CONFIG_PATH = REPO_ROOT / "commons" / "morphology_grammar" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "morphology-gallery"
STAGE_DIR_NAME = "morphology_gallery"
AUTO_PREFIX = "morph_auto_"
AUTO_STAGE_DIR = REPO_ROOT / "commons" / "morphology_grammar" / "_staging"
ALL_FAMILIES = [
    "tree",
    "hand",
    "house",
    "table",
    "chair",
    "shelf",
    "desk",
    "body_limb",
    "hand_chain",
    "drag_pageant",
    "drag_club_kid",
    "drag_avant_garde",
    "bio_furniture",
    "history_furniture",
    "scifi_props",
    "scifi_creatures",
]
MIXED_FAMILY = "mixed_forms"
SUPPORTED_OPS = {
    "extrude",
    "steered_extrude",
    "move_panel",
    "rotate_panel",
    "scale_panel",
    "inset_panel",
    "grid_extrude",
    "subdivide_extrude_fan",
    "finger_array",
    "cluster_cap",
    "aperture_grid",
    "gable_cap",
}


def _find_godot_userdata() -> Path | None:
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        return None
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists():
        return None
    for d in ud.iterdir():
        stage = d / STAGE_DIR_NAME
        if stage.exists():
            return stage
    for d in ud.iterdir():
        if "ada" in d.name.lower():
            return d / STAGE_DIR_NAME
    return None


def _stage_config(config: dict) -> tuple[Path, str]:
    AUTO_STAGE_DIR.mkdir(parents=True, exist_ok=True)
    cfg_staging = AUTO_STAGE_DIR / f"{config['id']}.json"
    cfg_staging.write_text(json.dumps(config, indent=2), encoding="utf-8")
    return cfg_staging, f"res://commons/morphology_grammar/_staging/{config['id']}.json"


def _run_godot(script: str, res_cfg: str, user_out: str, timeout: int = 180) -> subprocess.CompletedProcess:
    args = [
        GODOT_EXE,
        "--path",
        str(REPO_ROOT),
        "--xr-mode",
        "off",
        "--no-window",
        "--script",
        script,
        "--",
        f"--config={res_cfg}",
        f"--out={user_out}",
    ]
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout)


def evaluate_one(config: dict) -> dict | None:
    _, res_cfg = _stage_config(config)
    user_out = f"user://{STAGE_DIR_NAME}/{config['id']}.metrics.json"
    proc = _run_godot("res://commons/testing/evaluate_morphology.gd", res_cfg, user_out)
    if proc.returncode != 0:
        print(f"    eval failed {config['id']} rc={proc.returncode}")
        if proc.stderr:
            print(proc.stderr[-500:])
        return None

    stage = _find_godot_userdata()
    if stage is None:
        print(f"    eval missing userdata for {config['id']}")
        return None
    metrics_path = stage / f"{config['id']}.metrics.json"
    if not metrics_path.exists():
        print(f"    eval output missing for {config['id']}")
        return None
    return json.loads(metrics_path.read_text(encoding="utf-8"))


def render_one(config: dict, force: bool) -> bool:
    cid = config["id"]
    out_png = OUTPUT_DIR / f"{cid}.png"
    out_wire_png = OUTPUT_DIR / f"{cid}_wire.png"
    out_cfg = OUTPUT_DIR / f"{cid}.json"
    if out_png.exists() and out_wire_png.exists() and out_cfg.exists() and not force:
        print(f"  skip  {cid}")
        return True

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_cfg.write_text(json.dumps(config, indent=2), encoding="utf-8")
    _, res_cfg = _stage_config(config)

    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    proc = _run_godot("res://commons/testing/render_morphology.gd", res_cfg, user_out)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode}) stderr: {proc.stderr[-500:]}")
        return False

    stage = _find_godot_userdata()
    src = None
    if stage is not None:
        cand = stage / f"{cid}.png"
        if cand.exists():
            src = cand
    if src is None:
        print("    rendered but PNG not found")
        return False

    out_png.write_bytes(src.read_bytes())
    print(f"    -> public/morphology-gallery/{cid}.png")

    wire_cfg = copy.deepcopy(config)
    wire_cfg["id"] = cid
    wire_cfg["render_mode"] = "wireframe"
    _, wire_res_cfg = _stage_config(wire_cfg)
    wire_user_out = f"user://{STAGE_DIR_NAME}/{cid}_wire.png"
    wire_proc = _run_godot("res://commons/testing/render_morphology.gd", wire_res_cfg, wire_user_out)
    if wire_proc.returncode != 0:
        print(f"    FAILED wireframe (rc={wire_proc.returncode}) stderr: {wire_proc.stderr[-500:]}")
        return False
    wire_src = None
    if stage is not None:
        wire_cand = stage / f"{cid}_wire.png"
        if wire_cand.exists():
            wire_src = wire_cand
    if wire_src is None:
        print("    rendered wireframe but PNG not found")
        return False
    out_wire_png.write_bytes(wire_src.read_bytes())
    print(f"    -> public/morphology-gallery/{cid}_wire.png")
    return True


def _rule(cfg: dict, rid: str) -> dict:
    for rule in cfg.get("rules", []):
        if rule.get("id") == rid:
            return rule
    raise KeyError(f"Rule {rid} not found in {cfg.get('id')}")


def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def _jitter(rng: random.Random, value: float, rel: float, lo: float, hi: float) -> float:
    return round(_clamp(value * (1.0 + rng.uniform(-rel, rel)), lo, hi), 3)


def _pick(rng: random.Random, values):
    return values[rng.randrange(len(values))]


def _jitter_bias(rng: random.Random, values, delta: float, lo: float, hi: float) -> list[float]:
    return [round(_clamp(float(v) + rng.uniform(-delta, delta), lo, hi), 3) for v in values]


def _auto_note(cfg: dict, summary: dict) -> str:
    family = cfg["family"]
    boxes = summary.get("boxes_by_role", {})
    bbox = summary.get("bbox_size", [0, 0, 0])
    if family == MIXED_FAMILY:
        roles = sorted(k for k, v in boxes.items() if v)
        return f"Auto-researched mixed-family variant: roles {', '.join(roles[:6])}, {summary.get('total_boxes', 0)} total volumes, bbox {bbox[0]:.2f}×{bbox[1]:.2f}×{bbox[2]:.2f}."
    if family == "tree":
        return f"Auto-researched tree variant: {boxes.get('branch', 0)} branch volumes, {boxes.get('tip', 0)} terminal tips, height {bbox[1]:.2f}."
    if family == "hand":
        return f"Auto-researched hand variant: {boxes.get('trunk', 0)} finger extrusions, palm kept flat and contiguous."
    if family == "house":
        return f"Auto-researched house variant: {boxes.get('aperture', 0)} apertures under {boxes.get('cap', 0)} roof planes."
    if family == "table":
        return f"Auto-researched table variant: {boxes.get('trunk', 0)} support legs under a single tabletop mass."
    if family == "chair":
        return f"Auto-researched chair variant: {boxes.get('trunk', 0)} legs with {boxes.get('wall', 0)} backrest panels grown from one seat body."
    if family == "shelf":
        return f"Auto-researched shelf variant: {boxes.get('aperture', 0)} front bays inside one frame body."
    if family == "desk":
        return f"Auto-researched desk variant: {boxes.get('aperture', 0)} drawer recesses with {boxes.get('trunk', 0)} support legs."
    if family == "body_limb":
        return f"Auto-researched body-limb variant: {boxes.get('trunk', 0)} arm trunks, {boxes.get('tip', 0)} forearm tips, {boxes.get('cap', 0)} terminal caps."
    if family == "hand_chain":
        return f"Auto-researched hand-chain variant: {boxes.get('trunk', 0)} finger bases extended into {boxes.get('tip', 0)} smaller phalange tips."
    if family == "drag_pageant":
        return f"Auto-researched pageant variant: gown/train volume {boxes.get('garment', 0)}, wig volume {boxes.get('hair', 0)}, shoulder sparkle {boxes.get('ornament', 0)}."
    if family == "drag_club_kid":
        return f"Auto-researched club-kid variant: {boxes.get('heel', 0)} platform parts, {boxes.get('ornament', 0)} rig/headpiece spikes, corset shell {boxes.get('garment', 0)}."
    if family == "drag_avant_garde":
        return f"Auto-researched avant-garde variant: cape/train mass {boxes.get('garment', 0)}, asymmetric ornament {boxes.get('ornament', 0)}, heel lift {boxes.get('heel', 0)}."
    return f"Auto-researched morphology variant: {boxes}."


def _ratio_band(value: float, low: float, high: float) -> float:
    if value <= 0:
        return 0.0
    if low <= value <= high:
        return 1.0
    if value < low:
        return max(0.0, value / max(low, 1e-6))
    return max(0.0, high / value)


def _target_score(value: float, target: float, tolerance: float) -> float:
    return max(0.0, 1.0 - abs(value - target) / max(tolerance, 1e-6))


def _region_count(summary: dict, role: str, region: str) -> float:
    return float(summary.get("box_region_counts", {}).get(f"{role}/{region}", 0))


def _role_center(summary: dict, role: str) -> tuple[float, float, float]:
    raw = summary.get("role_mean_centers", {}).get(role, [0.0, 0.0, 0.0])
    if not isinstance(raw, list) or len(raw) < 3:
        return 0.0, 0.0, 0.0
    return float(raw[0]), float(raw[1]), float(raw[2])


def _asymmetry(left: float, right: float) -> float:
    total = left + right
    if total <= 1e-6:
        return 0.0
    return abs(left - right) / total


def score_candidate(family: str, summary: dict) -> float:
    boxes = summary.get("boxes_by_role", {})
    bbox = summary.get("bbox_size", [0.0, 0.0, 0.0])
    x, y, z = [float(v) for v in bbox]
    footprint = max(x, z, 1e-6)
    total_boxes = float(summary.get("total_boxes", 0))

    if family == MIXED_FAMILY:
        roles = [role for role, count in boxes.items() if count > 0]
        support_asym = _asymmetry(
            _region_count(summary, "support", "left") + _region_count(summary, "wall", "left"),
            _region_count(summary, "support", "right") + _region_count(summary, "wall", "right"),
        )
        crown_height = _role_center(summary, "cap")[1]
        score = 0.0
        score += 1.8 * _ratio_band(len(roles), 4, 8)
        score += 1.4 * _ratio_band(total_boxes, 6, 28)
        score += 1.2 * _ratio_band(y / footprint, 0.5, 2.8)
        score += 1.1 * _ratio_band(z / max(x, 1e-6), 0.35, 1.9)
        score += 1.0 * _ratio_band(boxes.get("support", 0), 2, 8)
        score += 0.9 * _ratio_band(boxes.get("wall", 0) + boxes.get("cushion", 0), 1, 8)
        score += 0.8 * _ratio_band(boxes.get("cap", 0) + boxes.get("tip", 0), 0, 6)
        score += 0.9 * _ratio_band(support_asym, 0.08, 0.72)
        score += 0.8 * _ratio_band(abs(crown_height), 0.0, max(y * 0.8, 0.2))
        score -= 0.2 * max(0.0, boxes.get("aperture", 0) - 10.0)
        return round(score, 4)

    if family == "tree":
        score = 0.0
        score += 1.4 * _target_score(boxes.get("body", 0), 1, 1)
        score += 1.7 * _target_score(boxes.get("trunk", 0), 1, 1)
        score += 2.4 * _target_score(boxes.get("branch", 0), 3, 2)
        score += 1.8 * _ratio_band(boxes.get("tip", 0), 3, 8)
        score += 2.5 * _ratio_band(y / footprint, 1.8, 4.8)
        score += 0.8 * _ratio_band(total_boxes, 5, 14)
        score -= 0.6 * boxes.get("aperture", 0)
        return round(score, 4)

    if family == "hand":
        flatness = max(x, z, 1e-6) / max(y, 1e-6)
        score = 0.0
        score += 1.2 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.8 * _target_score(boxes.get("trunk", 0), 5, 2)
        score += 1.1 * _target_score(boxes.get("cap", 0), 1, 1)
        score += 1.8 * _ratio_band(flatness, 3.0, 12.0)
        score += 1.1 * _ratio_band(total_boxes, 6, 12)
        return round(score, 4)

    if family == "house":
        height_ratio = y / footprint
        score = 0.0
        score += 1.4 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.2 * _target_score(boxes.get("aperture", 0), 6, 4)
        score += 1.9 * _target_score(boxes.get("cap", 0), 2, 1)
        score += 1.5 * _ratio_band(height_ratio, 0.55, 1.2)
        score += 0.9 * _ratio_band(total_boxes, 8, 18)
        score -= 0.3 * boxes.get("tip", 0)
        return round(score, 4)

    if family == "table":
        height_ratio = y / footprint
        score = 0.0
        score += 1.5 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.5 * _target_score(boxes.get("trunk", 0), 4, 2)
        score += 2.0 * _ratio_band(height_ratio, 0.55, 1.05)
        score += 0.9 * _ratio_band(total_boxes, 5, 12)
        score -= 0.5 * boxes.get("aperture", 0)
        return round(score, 4)

    if family == "chair":
        height_ratio = y / footprint
        score = 0.0
        score += 1.4 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.0 * _target_score(boxes.get("trunk", 0), 4, 2)
        score += 1.9 * _target_score(boxes.get("wall", 0), 1, 1)
        score += 1.6 * _ratio_band(height_ratio, 0.85, 1.7)
        score += 0.9 * _ratio_band(total_boxes, 6, 12)
        return round(score, 4)

    if family == "shelf":
        height_ratio = y / max(x, 1e-6)
        score = 0.0
        score += 1.5 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.6 * _ratio_band(boxes.get("aperture", 0), 8, 20)
        score += 1.8 * _ratio_band(height_ratio, 1.0, 2.4)
        score += 0.9 * _ratio_band(total_boxes, 10, 24)
        score -= 0.4 * boxes.get("trunk", 0)
        return round(score, 4)

    if family == "desk":
        height_ratio = y / footprint
        score = 0.0
        score += 1.4 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.2 * _target_score(boxes.get("trunk", 0), 4, 2)
        score += 1.8 * _ratio_band(boxes.get("aperture", 0), 4, 10)
        score += 1.4 * _ratio_band(height_ratio, 0.45, 1.05)
        score += 0.9 * _ratio_band(total_boxes, 8, 18)
        return round(score, 4)

    if family == "body_limb":
        height_ratio = y / footprint
        score = 0.0
        score += 1.5 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.0 * _target_score(boxes.get("trunk", 0), 2, 1)
        score += 1.5 * _target_score(boxes.get("tip", 0), 2, 1)
        score += 1.0 * _ratio_band(boxes.get("cap", 0), 1, 5)
        score += 1.8 * _ratio_band(height_ratio, 0.9, 2.4)
        score += 0.8 * _ratio_band(total_boxes, 6, 16)
        return round(score, 4)

    if family == "hand_chain":
        flatness = max(x, z, 1e-6) / max(y, 1e-6)
        score = 0.0
        score += 1.3 * _target_score(boxes.get("body", 0), 1, 1)
        score += 2.4 * _target_score(boxes.get("trunk", 0), 5, 2)
        score += 2.0 * _target_score(boxes.get("tip", 0), 5, 3)
        score += 1.0 * _target_score(boxes.get("cap", 0), 1, 1)
        score += 1.6 * _ratio_band(flatness, 3.0, 12.0)
        score += 0.8 * _ratio_band(total_boxes, 10, 20)
        return round(score, 4)

    if family == "drag_pageant":
        garment_center = _role_center(summary, "garment")
        hair_center = _role_center(summary, "hair")
        symmetry = 1.0 - _asymmetry(
            _region_count(summary, "ornament", "left"),
            _region_count(summary, "ornament", "right"),
        )
        height_ratio = y / max(x, z, 1e-6)
        score = 0.0
        score += 0.9 * _target_score(boxes.get("body", 0), 8, 4)
        score += 2.1 * _ratio_band(boxes.get("garment", 0), 8, 20)
        score += 1.7 * _ratio_band(boxes.get("hair", 0), 8, 22)
        score += 1.0 * _ratio_band(boxes.get("ornament", 0), 4, 16)
        score += 2.0 * _ratio_band(height_ratio, 1.8, 3.6)
        score += 1.1 * _target_score(abs(garment_center[0]), 0.0, 0.32)
        score += 1.0 * _ratio_band(-garment_center[1], 0.35, 1.6)
        score += 1.0 * _ratio_band(hair_center[1], 0.65, 1.8)
        score += 0.8 * symmetry
        score += 0.7 * _ratio_band(total_boxes, 28, 78)
        score -= 0.4 * boxes.get("heel", 0)
        return round(score, 4)

    if family == "drag_club_kid":
        ornament_center = _role_center(summary, "ornament")
        hair_center = _role_center(summary, "hair")
        ornament_asym = _asymmetry(
            _region_count(summary, "ornament", "left"),
            _region_count(summary, "ornament", "right"),
        )
        height_ratio = y / max(x, z, 1e-6)
        score = 0.0
        score += 0.9 * _target_score(boxes.get("body", 0), 5, 3)
        score += 2.0 * _ratio_band(boxes.get("heel", 0), 10, 30)
        score += 2.2 * _ratio_band(boxes.get("ornament", 0), 14, 52)
        score += 1.1 * _ratio_band(boxes.get("garment", 0), 4, 12)
        score += 1.0 * _ratio_band(boxes.get("hair", 0), 4, 16)
        score += 1.5 * _ratio_band(height_ratio, 1.3, 2.6)
        score += 1.2 * _ratio_band(abs(ornament_center[0]), 0.18, 1.05)
        score += 1.0 * _ratio_band(hair_center[1], 0.45, 1.4)
        score += 0.9 * _ratio_band(ornament_asym, 0.18, 0.86)
        score += 0.8 * _ratio_band(total_boxes, 24, 92)
        return round(score, 4)

    if family == "drag_avant_garde":
        garment_center = _role_center(summary, "garment")
        ornament_center = _role_center(summary, "ornament")
        garment_asym = _asymmetry(
            _region_count(summary, "garment", "left") + _region_count(summary, "ornament", "left"),
            _region_count(summary, "garment", "right") + _region_count(summary, "ornament", "right"),
        )
        garment_back_bias = (_region_count(summary, "garment", "back") + 1.0) / (_region_count(summary, "garment", "front") + 1.0)
        height_ratio = y / max(x, z, 1e-6)
        width_ratio = z / max(x, 1e-6)
        score = 0.0
        score += 0.9 * _target_score(boxes.get("body", 0), 5, 3)
        score += 2.3 * _ratio_band(boxes.get("garment", 0), 8, 20)
        score += 1.4 * _ratio_band(boxes.get("ornament", 0), 10, 28)
        score += 1.0 * _ratio_band(boxes.get("hair", 0), 6, 18)
        score += 1.2 * _ratio_band(boxes.get("heel", 0), 8, 24)
        score += 1.4 * _ratio_band(height_ratio, 1.1, 2.4)
        score += 1.4 * _ratio_band(width_ratio, 0.6, 1.4)
        score += 1.3 * _ratio_band(-garment_center[2], 0.28, 1.6)
        score += 1.1 * _ratio_band(abs(garment_center[0]) + abs(ornament_center[0]), 0.22, 1.6)
        score += 0.9 * _ratio_band(garment_back_bias, 1.4, 7.0)
        score += 0.8 * _ratio_band(garment_asym, 0.16, 0.92)
        score += 0.7 * _ratio_band(total_boxes, 24, 82)
        return round(score, 4)

    return 0.0


def mutate_tree(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}tree_{idx:02d}"
    cfg["notes"] = "Auto-generated tree candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.35, 0.18, 0.48),
        _jitter(rng, float(base["seed"]["size"][1]), 0.3, 0.10, 0.24),
        _jitter(rng, float(base["seed"]["size"][2]), 0.35, 0.18, 0.48),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.62)) + rng.uniform(-0.12, 0.12), 0.42, 0.9), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.44)) + rng.uniform(-0.08, 0.08), 0.28, 0.58), 3)

    body = _rule(cfg, "body_to_trunk")
    fan = _rule(cfg, "trunk_to_branch_fan")
    tip = _rule(cfg, "branch_to_tip")

    body["params"]["length"] = _jitter(rng, float(body["params"]["length"]), 0.28, 0.85, 1.6)
    body["params"]["scale"] = _jitter(rng, float(body["params"]["scale"]), 0.24, 0.36, 0.72)
    body["budget_factor"] = _jitter(rng, float(body["budget_factor"]), 0.12, 0.68, 0.92)

    fan["params"]["count"] = _pick(rng, [2, 3, 3, 4, 5])
    fan["params"]["length"] = _jitter(rng, float(fan["params"]["length"]), 0.30, 0.42, 1.0)
    fan["params"]["scale"] = _jitter(rng, float(fan["params"]["scale"]), 0.22, 0.34, 0.72)
    fan["params"]["splay_deg"] = round(_clamp(float(fan["params"]["splay_deg"]) + rng.uniform(-12, 16), 10, 42), 2)
    fan["params"]["lateral_spread"] = _jitter(rng, float(fan["params"]["lateral_spread"]), 0.35, 0.35, 0.95)
    fan["budget_factor"] = _jitter(rng, float(fan["budget_factor"]), 0.18, 0.42, 0.8)

    tip["params"]["length"] = _jitter(rng, float(tip["params"]["length"]), 0.35, 0.18, 0.56)
    tip["params"]["scale"] = _jitter(rng, float(tip["params"]["scale"]), 0.18, 0.5, 0.92)
    tip["budget_factor"] = _jitter(rng, float(tip["budget_factor"]), 0.15, 0.18, 0.52)
    return cfg


def mutate_hand(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}hand_{idx:02d}"
    cfg["notes"] = "Auto-generated hand candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.22, 0.95, 1.7),
        _jitter(rng, float(base["seed"]["size"][1]), 0.22, 0.16, 0.34),
        _jitter(rng, float(base["seed"]["size"][2]), 0.2, 0.65, 1.02),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.82)) + rng.uniform(-0.16, 0.1), 0.58, 1.02), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.38)) + rng.uniform(-0.08, 0.08), 0.26, 0.5), 3)

    fingers = _rule(cfg, "palm_to_fingers")
    wrist = _rule(cfg, "palm_to_wrist")

    fingers["params"]["count"] = _pick(rng, [4, 5, 5, 5, 6])
    fingers["params"]["length"] = _jitter(rng, float(fingers["params"]["length"]), 0.25, 0.38, 0.84)
    fingers["params"]["fill"] = _jitter(rng, float(fingers["params"]["fill"]), 0.12, 0.72, 0.96)
    fingers["params"]["thickness_scale"] = _jitter(rng, float(fingers["params"]["thickness_scale"]), 0.12, 0.88, 1.2)
    fingers["budget_factor"] = _jitter(rng, float(fingers["budget_factor"]), 0.14, 0.54, 0.86)

    wrist["params"]["length"] = _jitter(rng, float(wrist["params"]["length"]), 0.25, 0.14, 0.36)
    wrist["params"]["scale"] = _jitter(rng, float(wrist["params"]["scale"]), 0.18, 0.28, 0.56)
    return cfg


def mutate_house(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}house_{idx:02d}"
    cfg["notes"] = "Auto-generated house candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.22, 1.15, 2.1),
        _jitter(rng, float(base["seed"]["size"][1]), 0.18, 0.72, 1.34),
        _jitter(rng, float(base["seed"]["size"][2]), 0.18, 0.88, 1.48),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.7)) + rng.uniform(-0.12, 0.12), 0.5, 0.92), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.34)) + rng.uniform(-0.06, 0.08), 0.24, 0.46), 3)

    apertures = _rule(cfg, "front_apertures")
    roof = _rule(cfg, "roof_cap")

    apertures["params"]["cols"] = _pick(rng, [3, 3, 4])
    apertures["params"]["rows"] = _pick(rng, [2, 2, 3])
    apertures["params"]["scale"] = _jitter(rng, float(apertures["params"]["scale"]), 0.16, 0.52, 0.8)
    apertures["params"]["length"] = _jitter(rng, float(apertures["params"]["length"]), 0.25, 0.04, 0.12)
    apertures["params"]["door_col"] = int(apertures["params"]["cols"]) // 2
    apertures["params"]["door_height_scale"] = _jitter(rng, float(apertures["params"]["door_height_scale"]), 0.16, 1.18, 1.82)

    roof["params"]["pitch_deg"] = round(_clamp(float(roof["params"]["pitch_deg"]) + rng.uniform(-8, 10), 18, 42), 2)
    roof["params"]["thickness"] = _jitter(rng, float(roof["params"]["thickness"]), 0.18, 0.06, 0.13)
    roof["params"]["overhang"] = _jitter(rng, float(roof["params"]["overhang"]), 0.08, 1.0, 1.2)
    return cfg


def mutate_table(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}table_{idx:02d}"
    cfg["notes"] = "Auto-generated table candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.18, 1.35, 2.4),
        _jitter(rng, float(base["seed"]["size"][1]), 0.18, 0.14, 0.34),
        _jitter(rng, float(base["seed"]["size"][2]), 0.18, 0.82, 1.42),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.66)) + rng.uniform(-0.12, 0.12), 0.48, 0.88), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.35)) + rng.uniform(-0.06, 0.06), 0.26, 0.46), 3)

    legs = _rule(cfg, "tabletop_to_legs")
    legs["params"]["length"] = _jitter(rng, float(legs["params"]["length"]), 0.24, 0.78, 1.52)
    legs["params"]["scale"] = _jitter(rng, float(legs["params"]["scale"]), 0.22, 0.16, 0.38)
    return cfg


def mutate_chair(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}chair_{idx:02d}"
    cfg["notes"] = "Auto-generated chair candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.18, 0.92, 1.42),
        _jitter(rng, float(base["seed"]["size"][1]), 0.16, 0.16, 0.32),
        _jitter(rng, float(base["seed"]["size"][2]), 0.16, 0.84, 1.2),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.88)) + rng.uniform(-0.12, 0.12), 0.66, 1.08), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.38)) + rng.uniform(-0.06, 0.06), 0.28, 0.48), 3)

    legs = _rule(cfg, "seat_to_legs")
    back = _rule(cfg, "seat_to_backrest")
    legs["params"]["length"] = _jitter(rng, float(legs["params"]["length"]), 0.24, 0.64, 1.18)
    legs["params"]["scale"] = _jitter(rng, float(legs["params"]["scale"]), 0.18, 0.16, 0.34)
    back["params"]["length"] = _jitter(rng, float(back["params"]["length"]), 0.22, 0.54, 1.08)
    back["params"]["scale"] = _jitter(rng, float(back["params"]["scale"]), 0.08, 0.84, 1.0)
    return cfg


def mutate_shelf(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}shelf_{idx:02d}"
    cfg["notes"] = "Auto-generated shelf candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.16, 1.18, 1.92),
        _jitter(rng, float(base["seed"]["size"][1]), 0.18, 1.44, 2.32),
        _jitter(rng, float(base["seed"]["size"][2]), 0.16, 0.44, 0.82),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.68)) + rng.uniform(-0.12, 0.12), 0.48, 0.88), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.28)) + rng.uniform(-0.05, 0.06), 0.18, 0.4), 3)

    bays = _rule(cfg, "shelf_front_bays")
    bays["params"]["cols"] = _pick(rng, [2, 3, 3, 4])
    bays["params"]["rows"] = _pick(rng, [3, 4, 4, 5])
    bays["params"]["length"] = _jitter(rng, float(bays["params"]["length"]), 0.28, 0.08, 0.18)
    bays["params"]["scale"] = _jitter(rng, float(bays["params"]["scale"]), 0.14, 0.68, 0.9)
    return cfg


def mutate_desk(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}desk_{idx:02d}"
    cfg["notes"] = "Auto-generated desk candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.18, 1.42, 2.32),
        _jitter(rng, float(base["seed"]["size"][1]), 0.16, 0.68, 1.08),
        _jitter(rng, float(base["seed"]["size"][2]), 0.16, 0.82, 1.18),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.74)) + rng.uniform(-0.12, 0.12), 0.54, 0.94), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.34)) + rng.uniform(-0.06, 0.06), 0.24, 0.44), 3)

    legs = _rule(cfg, "desk_to_legs")
    drawers = _rule(cfg, "desk_front_drawers")
    legs["params"]["length"] = _jitter(rng, float(legs["params"]["length"]), 0.24, 0.62, 1.06)
    legs["params"]["scale"] = _jitter(rng, float(legs["params"]["scale"]), 0.16, 0.16, 0.34)
    drawers["params"]["cols"] = _pick(rng, [2, 2, 3])
    drawers["params"]["rows"] = _pick(rng, [2, 3, 3, 4])
    drawers["params"]["length"] = _jitter(rng, float(drawers["params"]["length"]), 0.22, 0.05, 0.12)
    drawers["params"]["scale"] = _jitter(rng, float(drawers["params"]["scale"]), 0.14, 0.58, 0.82)
    return cfg


def mutate_body_limb(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}body_limb_{idx:02d}"
    cfg["notes"] = "Auto-generated body-limb candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.18, 0.62, 1.02),
        _jitter(rng, float(base["seed"]["size"][1]), 0.2, 1.02, 1.72),
        _jitter(rng, float(base["seed"]["size"][2]), 0.18, 0.42, 0.74),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.18)) + rng.uniform(-0.16, 0.16), 0.02, 0.48), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.36)) + rng.uniform(-0.06, 0.06), 0.24, 0.48), 3)

    head = _rule(cfg, "body_to_head")
    arms = _rule(cfg, "body_to_arms")
    forearm = _rule(cfg, "arm_to_forearm")
    terminal = _rule(cfg, "hand_terminal_split")
    head["params"]["length"] = _jitter(rng, float(head["params"]["length"]), 0.18, 0.14, 0.34)
    head["params"]["scale"] = _jitter(rng, float(head["params"]["scale"]), 0.12, 0.46, 0.72)
    arms["params"]["length"] = _jitter(rng, float(arms["params"]["length"]), 0.24, 0.38, 0.82)
    arms["params"]["scale"] = _jitter(rng, float(arms["params"]["scale"]), 0.18, 0.24, 0.46)
    forearm["params"]["length"] = _jitter(rng, float(forearm["params"]["length"]), 0.24, 0.16, 0.34)
    forearm["params"]["scale"] = _jitter(rng, float(forearm["params"]["scale"]), 0.16, 0.48, 0.82)
    terminal["params"]["length"] = _jitter(rng, float(terminal["params"]["length"]), 0.18, 0.04, 0.12)
    terminal["params"]["scale"] = _jitter(rng, float(terminal["params"]["scale"]), 0.14, 0.5, 0.82)
    return cfg


def mutate_hand_chain(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}hand_chain_{idx:02d}"
    cfg["notes"] = "Auto-generated hand-chain candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.2, 1.02, 1.84),
        _jitter(rng, float(base["seed"]["size"][1]), 0.18, 0.16, 0.32),
        _jitter(rng, float(base["seed"]["size"][2]), 0.18, 0.62, 0.96),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.86)) + rng.uniform(-0.14, 0.12), 0.64, 1.06), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.34)) + rng.uniform(-0.06, 0.06), 0.24, 0.44), 3)

    fingers = _rule(cfg, "palm_to_fingers_chain")
    phalange = _rule(cfg, "finger_to_phalange")
    wrist = _rule(cfg, "palm_to_wrist_chain")
    fingers["params"]["count"] = _pick(rng, [4, 5, 5, 5, 6])
    fingers["params"]["length"] = _jitter(rng, float(fingers["params"]["length"]), 0.24, 0.34, 0.76)
    fingers["params"]["fill"] = _jitter(rng, float(fingers["params"]["fill"]), 0.12, 0.72, 0.96)
    phalange["params"]["length"] = _jitter(rng, float(phalange["params"]["length"]), 0.22, 0.12, 0.34)
    phalange["params"]["scale"] = _jitter(rng, float(phalange["params"]["scale"]), 0.14, 0.58, 0.9)
    wrist["params"]["length"] = _jitter(rng, float(wrist["params"]["length"]), 0.2, 0.14, 0.34)
    wrist["params"]["scale"] = _jitter(rng, float(wrist["params"]["scale"]), 0.14, 0.32, 0.58)
    return cfg


def mutate_drag_pageant(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}drag_pageant_{idx:02d}"
    cfg["notes"] = "Auto-generated pageant drag candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.14, 0.72, 1.02),
        _jitter(rng, float(base["seed"]["size"][1]), 0.14, 1.22, 1.62),
        _jitter(rng, float(base["seed"]["size"][2]), 0.14, 0.48, 0.74),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.74)) + rng.uniform(-0.12, 0.12), 0.56, 0.92), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.32)) + rng.uniform(-0.05, 0.05), 0.24, 0.42), 3)

    gown = _rule(cfg, "pageant_to_gown")
    train = _rule(cfg, "pageant_train")
    shoulders = _rule(cfg, "pageant_to_shoulders")
    head = _rule(cfg, "pageant_to_head")
    hair_sweep = _rule(cfg, "pageant_hair_sweep")
    wig = _rule(cfg, "pageant_wig")
    gown["params"]["length"] = _jitter(rng, float(gown["params"]["length"]), 0.18, 0.82, 1.32)
    gown["params"]["scale"] = _jitter(rng, float(gown["params"]["scale"]), 0.12, 1.22, 1.72)
    gown["budget_factor"] = _jitter(rng, float(gown["budget_factor"]), 0.16, 0.44, 0.78)
    train["params"]["length"] = _jitter(rng, float(train["params"]["length"]), 0.24, 0.46, 1.08)
    train["params"]["scale"] = _jitter(rng, float(train["params"]["scale"]), 0.12, 0.92, 1.34)
    train["params"]["bitangent_bias"] = _jitter(rng, float(train["params"]["bitangent_bias"]), 0.18, 0.38, 1.02)
    train["params"]["world_bias"] = _jitter_bias(rng, train["params"]["world_bias"], 0.14, -0.9, 0.9)
    shoulders["params"]["length"] = _jitter(rng, float(shoulders["params"]["length"]), 0.22, 0.14, 0.38)
    shoulders["params"]["scale"] = _jitter(rng, float(shoulders["params"]["scale"]), 0.16, 0.34, 0.62)
    shoulders["params"]["tangent_bias"] = _jitter(rng, float(shoulders["params"]["tangent_bias"]), 0.32, 0.0, 0.5)
    head["params"]["length"] = _jitter(rng, float(head["params"]["length"]), 0.18, 0.16, 0.34)
    head["params"]["scale"] = _jitter(rng, float(head["params"]["scale"]), 0.14, 0.42, 0.7)
    head["budget_factor"] = _jitter(rng, float(head["budget_factor"]), 0.18, 0.42, 0.82)
    hair_sweep["params"]["length"] = _jitter(rng, float(hair_sweep["params"]["length"]), 0.24, 0.12, 0.28)
    hair_sweep["params"]["scale"] = _jitter(rng, float(hair_sweep["params"]["scale"]), 0.16, 0.58, 0.96)
    hair_sweep["params"]["world_bias"] = _jitter_bias(rng, hair_sweep["params"]["world_bias"], 0.12, -0.8, 0.8)
    wig["params"]["length"] = _jitter(rng, float(wig["params"]["length"]), 0.2, 0.16, 0.32)
    wig["params"]["scale"] = _jitter(rng, float(wig["params"]["scale"]), 0.14, 1.08, 1.48)
    return cfg


def mutate_drag_club_kid(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}drag_club_kid_{idx:02d}"
    cfg["notes"] = "Auto-generated club-kid drag candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.16, 0.78, 1.14),
        _jitter(rng, float(base["seed"]["size"][1]), 0.14, 1.02, 1.42),
        _jitter(rng, float(base["seed"]["size"][2]), 0.16, 0.54, 0.78),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.82)) + rng.uniform(-0.12, 0.12), 0.64, 1.02), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.34)) + rng.uniform(-0.05, 0.05), 0.24, 0.44), 3)

    platforms = _rule(cfg, "clubkid_to_platforms")
    rig = _rule(cfg, "clubkid_to_rig")
    corset = _rule(cfg, "clubkid_to_corset")
    head = _rule(cfg, "clubkid_to_head")
    piece = _rule(cfg, "clubkid_headpiece")
    spikes = _rule(cfg, "clubkid_spikes")
    platforms["params"]["length"] = _jitter(rng, float(platforms["params"]["length"]), 0.2, 0.62, 1.04)
    platforms["params"]["scale"] = _jitter(rng, float(platforms["params"]["scale"]), 0.18, 0.22, 0.46)
    rig["params"]["length"] = _jitter(rng, float(rig["params"]["length"]), 0.24, 0.28, 0.62)
    rig["params"]["scale"] = _jitter(rng, float(rig["params"]["scale"]), 0.18, 0.32, 0.62)
    rig["params"]["world_bias"] = _jitter_bias(rng, rig["params"]["world_bias"], 0.14, -0.8, 0.8)
    rig["budget_factor"] = _jitter(rng, float(rig["budget_factor"]), 0.2, 0.18, 0.62)
    corset["params"]["length"] = _jitter(rng, float(corset["params"]["length"]), 0.2, 0.12, 0.28)
    corset["params"]["scale"] = _jitter(rng, float(corset["params"]["scale"]), 0.18, 0.46, 0.78)
    corset["params"]["world_bias"] = _jitter_bias(rng, corset["params"]["world_bias"], 0.08, -0.4, 0.4)
    head["params"]["length"] = _jitter(rng, float(head["params"]["length"]), 0.16, 0.14, 0.3)
    head["params"]["scale"] = _jitter(rng, float(head["params"]["scale"]), 0.14, 0.42, 0.7)
    head["budget_factor"] = _jitter(rng, float(head["budget_factor"]), 0.18, 0.42, 0.82)
    piece["params"]["length"] = _jitter(rng, float(piece["params"]["length"]), 0.22, 0.18, 0.46)
    piece["params"]["scale"] = _jitter(rng, float(piece["params"]["scale"]), 0.2, 0.28, 0.72)
    piece["params"]["world_bias"] = _jitter_bias(rng, piece["params"]["world_bias"], 0.18, -0.8, 0.8)
    piece["budget_factor"] = _jitter(rng, float(piece["budget_factor"]), 0.22, 0.12, 0.46)
    spikes["params"]["count"] = _pick(rng, [3, 4, 4, 5])
    spikes["params"]["length"] = _jitter(rng, float(spikes["params"]["length"]), 0.24, 0.12, 0.34)
    spikes["params"]["scale"] = _jitter(rng, float(spikes["params"]["scale"]), 0.18, 0.92, 1.42)
    return cfg


def mutate_drag_avant_garde(base: dict, rng: random.Random, idx: int) -> dict:
    cfg = copy.deepcopy(base)
    cfg["id"] = f"{AUTO_PREFIX}drag_avant_garde_{idx:02d}"
    cfg["notes"] = "Auto-generated avant-garde drag candidate."
    cfg["seed"]["size"] = [
        _jitter(rng, float(base["seed"]["size"][0]), 0.16, 0.64, 0.96),
        _jitter(rng, float(base["seed"]["size"][1]), 0.16, 1.12, 1.62),
        _jitter(rng, float(base["seed"]["size"][2]), 0.16, 0.46, 0.72),
    ]
    cfg["camera_yaw"] = round(_clamp(float(base.get("camera_yaw", 0.62)) + rng.uniform(-0.16, 0.16), 0.38, 0.88), 3)
    cfg["camera_pitch"] = round(_clamp(float(base.get("camera_pitch", 0.34)) + rng.uniform(-0.05, 0.05), 0.24, 0.44), 3)

    cape = _rule(cfg, "avant_to_cape")
    train = _rule(cfg, "avant_train_extension")
    major = _rule(cfg, "avant_to_major_sleeve")
    minor = _rule(cfg, "avant_to_minor_sleeve")
    head = _rule(cfg, "avant_to_head")
    crown = _rule(cfg, "avant_headpiece")
    heels = _rule(cfg, "avant_to_heels")
    cape["params"]["length"] = _jitter(rng, float(cape["params"]["length"]), 0.2, 0.72, 1.24)
    cape["params"]["scale"] = _jitter(rng, float(cape["params"]["scale"]), 0.16, 1.24, 1.92)
    cape["params"]["bitangent_bias"] = _jitter(rng, float(cape["params"]["bitangent_bias"]), 0.2, 0.24, 0.92)
    cape["params"]["world_bias"] = _jitter_bias(rng, cape["params"]["world_bias"], 0.18, -1.0, 0.8)
    cape["budget_factor"] = _jitter(rng, float(cape["budget_factor"]), 0.18, 0.34, 0.82)
    train["params"]["length"] = _jitter(rng, float(train["params"]["length"]), 0.24, 0.42, 1.02)
    train["params"]["scale"] = _jitter(rng, float(train["params"]["scale"]), 0.16, 0.92, 1.42)
    train["params"]["world_bias"] = _jitter_bias(rng, train["params"]["world_bias"], 0.2, -1.2, 0.8)
    major["params"]["length"] = _jitter(rng, float(major["params"]["length"]), 0.24, 0.36, 0.82)
    major["params"]["scale"] = _jitter(rng, float(major["params"]["scale"]), 0.2, 0.22, 0.52)
    major["params"]["world_bias"] = _jitter_bias(rng, major["params"]["world_bias"], 0.16, -0.8, 0.8)
    minor["params"]["length"] = _jitter(rng, float(minor["params"]["length"]), 0.24, 0.12, 0.42)
    minor["params"]["scale"] = _jitter(rng, float(minor["params"]["scale"]), 0.18, 0.14, 0.32)
    minor["params"]["world_bias"] = _jitter_bias(rng, minor["params"]["world_bias"], 0.12, -0.5, 0.5)
    head["params"]["length"] = _jitter(rng, float(head["params"]["length"]), 0.16, 0.14, 0.28)
    head["params"]["scale"] = _jitter(rng, float(head["params"]["scale"]), 0.16, 0.36, 0.62)
    head["budget_factor"] = _jitter(rng, float(head["budget_factor"]), 0.18, 0.42, 0.8)
    crown["params"]["length"] = _jitter(rng, float(crown["params"]["length"]), 0.18, 0.14, 0.34)
    crown["params"]["scale"] = _jitter(rng, float(crown["params"]["scale"]), 0.18, 0.24, 0.72)
    crown["params"]["world_bias"] = _jitter_bias(rng, crown["params"]["world_bias"], 0.18, -0.8, 0.8)
    heels["params"]["length"] = _jitter(rng, float(heels["params"]["length"]), 0.18, 0.46, 0.86)
    heels["params"]["scale"] = _jitter(rng, float(heels["params"]["scale"]), 0.18, 0.16, 0.34)
    return cfg


def _average_size(configs: list[dict]) -> list[float]:
    sizes = [cfg.get("seed", {}).get("size", [1.0, 1.0, 1.0]) for cfg in configs]
    count = max(len(sizes), 1)
    return [
        round(sum(float(s[i]) for s in sizes) / count, 3)
        for i in range(3)
    ]


def _clone_rule(rule: dict, rid: str) -> dict:
    out = copy.deepcopy(rule)
    out["id"] = rid
    return out


def _jitter_numbers(value, rng: random.Random):
    if isinstance(value, dict):
        return {k: _jitter_numbers(v, rng) for k, v in value.items()}
    if isinstance(value, list):
        return [_jitter_numbers(v, rng) for v in value]
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        v = float(value)
        mag = max(abs(v), 0.12)
        lo = v - mag * 0.28
        hi = v + mag * 0.28
        if abs(v) <= 1.5:
            lo = max(lo, -1.5)
            hi = min(hi, 1.5)
        return round(rng.uniform(lo, hi), 3)
    return value


def _make_transform_rule(idx: int, role: str, selector: str, op: str, rng: random.Random) -> dict:
    params: dict
    if op == "move_panel":
        params = {
            "normal_offset": round(rng.uniform(-0.06, 0.12), 3),
            "tangent_offset": round(rng.uniform(-0.22, 0.22), 3),
            "bitangent_offset": round(rng.uniform(-0.18, 0.18), 3),
        }
    elif op == "rotate_panel":
        params = {
            "axis": _pick(rng, ["normal", "normal", "tangent", "bitangent"]),
            "angle_deg": round(rng.uniform(-26.0, 28.0), 3),
            "normal_offset": round(rng.uniform(-0.02, 0.06), 3),
        }
    elif op == "scale_panel":
        params = {
            "scale_x": round(rng.uniform(0.58, 1.34), 3),
            "scale_y": round(rng.uniform(0.58, 1.34), 3),
            "normal_offset": round(rng.uniform(-0.04, 0.08), 3),
        }
    else:
        params = {
            "scale": round(rng.uniform(0.54, 0.88), 3),
            "depth": round(rng.uniform(0.02, 0.12), 3),
        }
    return {
        "id": f"mixed_transform_{idx:02d}_{op}",
        "when": {
            "role": role,
            "max_depth": _pick(rng, [0, 0, 1]),
            "min_budget": round(rng.uniform(0.18, 0.68), 3),
        },
        "selector": selector,
        "op": op,
        "params": params,
        "child_role": role,
        "budget_factor": round(rng.uniform(0.22, 0.74), 3),
    }


def _inject_transform_rules(cfg: dict, rng: random.Random) -> None:
    transform_ops = ["move_panel", "rotate_panel", "scale_panel", "inset_panel"]
    roles = []
    for rule in cfg.get("rules", []):
        when = rule.get("when", {})
        role = str(when.get("role", ""))
        if role and role not in roles:
            roles.append(role)
    roles = [r for r in roles if r in {"body", "support", "wall", "cushion", "garment"}] or ["body"]
    selectors = ["up", "front", "back", "left", "right"]
    for idx in range(_pick(rng, [1, 2, 2, 3])):
        role = _pick(rng, roles)
        selector = _pick(rng, selectors)
        op = _pick(rng, transform_ops)
        cfg["rules"].append(_make_transform_rule(idx + 1, role, selector, op, rng))


def _mixed_rule_pool(configs: list[dict]) -> list[tuple[dict, dict]]:
    pool: list[tuple[dict, dict]] = []
    for cfg in configs:
        for rule in cfg.get("rules", []):
            if not isinstance(rule, dict):
                continue
            if str(rule.get("op", "")) not in SUPPORTED_OPS:
                continue
            when = rule.get("when", {})
            if not isinstance(when, dict):
                continue
            if str(when.get("role", "")) == "":
                continue
            if int(when.get("min_depth", 0)) > 1:
                continue
            pool.append((cfg, rule))
    return pool


def generate_mixed_candidates(bases: list[dict], count: int, rng: random.Random) -> list[dict]:
    pool = _mixed_rule_pool(bases)
    out: list[dict] = []
    if not pool or len(bases) < 2:
        return out

    for idx in range(1, count + 1):
        donor_count = min(len(bases), _pick(rng, [2, 2, 3, 3, 4]))
        donors = rng.sample(bases, donor_count)
        anchor = donors[0]
        cfg = {
            "id": f"{AUTO_PREFIX}mixed_{idx:02d}",
            "family": MIXED_FAMILY,
            "notes": "Auto-generated mixed-family candidate.",
            "camera_yaw": round(sum(float(d.get("camera_yaw", 0.72)) for d in donors) / donor_count + rng.uniform(-0.12, 0.12), 3),
            "camera_pitch": round(sum(float(d.get("camera_pitch", 0.34)) for d in donors) / donor_count + rng.uniform(-0.06, 0.06), 3),
            "seed": {
                "type": anchor.get("seed", {}).get("type", "box"),
                "size": _average_size(donors),
                "role": "body",
                "budget": 1.0,
            },
            "iterations": int(round(sum(int(d.get("iterations", 6)) for d in donors) / donor_count)),
            "rules": [],
        }
        cfg["seed"]["size"] = [
            _jitter(rng, float(cfg["seed"]["size"][0]), 0.28, 0.42, 1.92),
            _jitter(rng, float(cfg["seed"]["size"][1]), 0.28, 0.18, 1.84),
            _jitter(rng, float(cfg["seed"]["size"][2]), 0.28, 0.28, 1.64),
        ]
        cfg["camera_yaw"] = round(_clamp(float(cfg["camera_yaw"]), 0.12, 1.1), 3)
        cfg["camera_pitch"] = round(_clamp(float(cfg["camera_pitch"]), 0.16, 0.52), 3)
        cfg["iterations"] = max(5, min(8, int(cfg["iterations"])))

        donor_families = {str(d.get("family", "")) for d in donors}
        available_roles = {"body"}
        candidates = pool[:]
        rng.shuffle(candidates)
        target_rules = _pick(rng, [4, 5, 5, 6])

        while len(cfg["rules"]) < target_rules and candidates:
            donor_cfg, rule = candidates.pop()
            if str(donor_cfg.get("family", "")) not in donor_families:
                continue
            when = rule.get("when", {})
            role = str(when.get("role", ""))
            if role not in available_roles:
                continue
            new_rule = _clone_rule(rule, f"mixed_{idx:02d}_{len(cfg['rules'])+1:02d}_{str(rule.get('id', 'rule'))}")
            new_rule["params"] = _jitter_numbers(new_rule.get("params", {}), rng)
            if "budget_factor" in new_rule:
                new_rule["budget_factor"] = round(_clamp(float(new_rule["budget_factor"]) + rng.uniform(-0.12, 0.12), 0.0, 0.92), 3)
            child_role = str(new_rule.get("child_role", ""))
            if child_role:
                available_roles.add(child_role)
            cfg["rules"].append(new_rule)

        if cfg["rules"]:
            _inject_transform_rules(cfg, rng)
            cfg["notes"] = f"Auto-generated mixed-family candidate from {', '.join(sorted(donor_families))}."
            out.append(cfg)
    return out


def generate_candidates(base: dict, count: int, rng: random.Random) -> list[dict]:
    family = base.get("family")
    out = []
    for idx in range(1, count + 1):
        if family == "tree":
            out.append(mutate_tree(base, rng, idx))
        elif family == "hand":
            out.append(mutate_hand(base, rng, idx))
        elif family == "house":
            out.append(mutate_house(base, rng, idx))
        elif family == "table":
            out.append(mutate_table(base, rng, idx))
        elif family == "chair":
            out.append(mutate_chair(base, rng, idx))
        elif family == "shelf":
            out.append(mutate_shelf(base, rng, idx))
        elif family == "desk":
            out.append(mutate_desk(base, rng, idx))
        elif family == "body_limb":
            out.append(mutate_body_limb(base, rng, idx))
        elif family == "hand_chain":
            out.append(mutate_hand_chain(base, rng, idx))
        elif family == "drag_pageant":
            out.append(mutate_drag_pageant(base, rng, idx))
        elif family == "drag_club_kid":
            out.append(mutate_drag_club_kid(base, rng, idx))
        elif family == "drag_avant_garde":
            out.append(mutate_drag_avant_garde(base, rng, idx))
    return out


def auto_research(lib: dict, family_filter: str | None, candidates_per_family: int, keep_per_family: int, seed: int, mixed: bool = False) -> list[dict]:
    rng = random.Random(seed)
    base_configs = [
        cfg for cfg in lib["configs"]
        if not str(cfg.get("id", "")).startswith(AUTO_PREFIX)
        and (family_filter is None or cfg.get("family") == family_filter)
    ]
    selected_families = {cfg["family"] for cfg in base_configs}
    survivors: list[dict] = []

    if mixed:
        print(f"Auto research: mixed families ({candidates_per_family} candidates)")
        candidates = generate_mixed_candidates(base_configs, candidates_per_family, rng)
        scored = []
        for candidate in candidates:
            metrics = evaluate_one(candidate)
            if metrics is None:
                continue
            score = score_candidate(MIXED_FAMILY, metrics)
            candidate["_metrics"] = metrics
            candidate["_score"] = score
            scored.append(candidate)
            print(f"  {candidate['id']}: score={score:.3f} boxes={metrics.get('boxes_by_role', {})} bbox={metrics.get('bbox_size', [])}")
        scored.sort(key=lambda c: c["_score"], reverse=True)
        keepers = scored[:keep_per_family]
        for rank, keeper in enumerate(keepers, start=1):
            keeper["id"] = f"{AUTO_PREFIX}mixed_top{rank:02d}"
            keeper["notes"] = _auto_note(keeper, keeper["_metrics"])
            keeper.pop("_score", None)
            keeper.pop("_metrics", None)
        survivors.extend(keepers)
        lib["configs"] = [
            cfg for cfg in lib["configs"]
            if not (str(cfg.get("id", "")).startswith(AUTO_PREFIX) and cfg.get("family") == MIXED_FAMILY)
        ] + survivors
        CONFIG_PATH.write_text(json.dumps(lib, indent=2), encoding="utf-8")
        return survivors

    for base in base_configs:
        family = base["family"]
        print(f"Auto research: {family} ({candidates_per_family} candidates)")
        candidates = generate_candidates(base, candidates_per_family, rng)
        scored = []
        for candidate in candidates:
            metrics = evaluate_one(candidate)
            if metrics is None:
                continue
            score = score_candidate(family, metrics)
            candidate["_metrics"] = metrics
            candidate["_score"] = score
            scored.append(candidate)
            print(f"  {candidate['id']}: score={score:.3f} boxes={metrics.get('boxes_by_role', {})} bbox={metrics.get('bbox_size', [])}")

        scored.sort(key=lambda c: c["_score"], reverse=True)
        keepers = scored[:keep_per_family]
        for rank, keeper in enumerate(keepers, start=1):
            keeper["id"] = f"{AUTO_PREFIX}{family}_top{rank:02d}"
            keeper["notes"] = _auto_note(keeper, keeper["_metrics"])
            keeper.pop("_score", None)
            keeper.pop("_metrics", None)
        survivors.extend(keepers)

    lib["configs"] = [
        cfg for cfg in lib["configs"]
        if not (str(cfg.get("id", "")).startswith(AUTO_PREFIX) and cfg.get("family") in selected_families)
    ] + survivors

    CONFIG_PATH.write_text(json.dumps(lib, indent=2), encoding="utf-8")
    return survivors


def build_manifest(lib: dict) -> None:
    entries = []
    for cfg in lib["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists():
            continue
        entries.append(
            {
                "id": cfg["id"],
                "notes": cfg.get("notes", ""),
                "family": cfg.get("family", ""),
                "image": f"/morphology-gallery/{cfg['id']}.png",
                "wire_image": f"/morphology-gallery/{cfg['id']}_wire.png" if (OUTPUT_DIR / f"{cfg['id']}_wire.png").exists() else "",
                "config": f"/morphology-gallery/{cfg['id']}.json",
            }
        )
    manifest = {
        "version": lib.get("version", 1),
        "description": lib.get("description", ""),
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--auto", action="store_true")
    parser.add_argument("--family")
    parser.add_argument("--mixed", action="store_true")
    parser.add_argument("--candidates", type=int, default=8)
    parser.add_argument("--keep", type=int, default=2)
    parser.add_argument("--seed", type=int, default=46)
    args = parser.parse_args()

    if not CONFIG_PATH.exists():
        print(f"Config not found: {CONFIG_PATH}")
        return 1

    lib = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if args.auto:
        survivors = auto_research(lib, args.family, max(args.candidates, 1), max(args.keep, 1), args.seed, mixed=args.mixed)
        if not survivors:
            print("No auto-research survivors.")
            return 1
        print(f"Selected {len(survivors)} auto variants")
        for cfg in survivors:
            print(f"  keep {cfg['id']} ({cfg['family']})")
            if not render_one(cfg, True):
                return 2
        build_manifest(lib)
        return 0

    configs = lib["configs"]
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]
        if not configs:
            print(f"No config {args.id}")
            return 1

    print(f"Morphology: {len(configs)} configs -> {OUTPUT_DIR}")
    ok, fail = [], []
    for cfg in configs:
        print(f"  render {cfg['id']} ({cfg.get('family', '?')}) ...")
        (ok if render_one(cfg, args.force) else fail).append(cfg["id"])

    build_manifest(lib)
    print(f"\nManifest: {len(json.loads((OUTPUT_DIR / 'manifest.json').read_text(encoding='utf-8'))['entries'])} entries   OK: {len(ok)}  Fail: {len(fail)}")
    if fail:
        for f in fail:
            print(f"  - {f}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
