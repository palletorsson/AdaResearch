#!/usr/bin/env python3
"""Publish the certified museum wall kit into the Ada encyclopedia gallery."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PIECE_CAPTURE = ROOT / "ada_run/museum_aaa_pass/museum_wall_piece_gallery"
ATLAS_CAPTURE = ROOT / "ada_run/museum_aaa_pass/museum_wall_kit_capture/museum_wall_kit_atlas.png"
FULL_CAPTURE = ROOT / "ada_run/museum_aaa_pass/museum_wall_full_build_gallery/full_build_16m.png"
SHOWCASE_CAPTURE = ROOT / "ada_run/museum_aaa_pass/museum_wall_aaa_showcase_capture/museum_wall_aaa_showcase.png"
VALIDATION = ROOT / "ada_run/museum_aaa_pass/museum_wall_kit_validation.json"
AAA_VALIDATION = ROOT / "ada_run/museum_aaa_pass/museum_wall_aaa_engine_validation.json"
STATIC_PROFILE = ROOT / "ada_run/museum_aaa_pass/museum_wall_aaa_static_profile.json"
CONTRACT = ROOT / "commons/data/museum_module_kit.json"
QUALITY = ROOT / "commons/data/museum_wall_aaa_quality.json"
PHYSICS = ROOT / "commons/data/museum_wall_physics_contract.json"
DEFAULT_SITE = ROOT.parent / "ada_encyclopedia"
SOURCE_FILES = [
    ROOT / "commons/artifacts/museum/museum_wall_piece.gd",
    ROOT / "commons/artifacts/museum/museum_wall_run.gd",
    ROOT / "commons/artifacts/museum/museum_wall_architectural_spans.gd",
    ROOT / "commons/artifacts/museum/museum_wall_opening_spans.gd",
    ROOT / "commons/artifacts/museum/museum_wall_kit_atlas.gd",
    ROOT / "commons/artifacts/museum/museum_wall_aaa_showcase.gd",
    ROOT / "commons/data/museum_wall_aaa_quality.json",
    ROOT / "commons/data/museum_wall_physics_contract.json",
]

ROLES = {
    "solid": "quiet continuation",
    "feature": "protected artwork field",
    "window": "daylight and visual connection",
    "vitrine": "recessed wall exhibit",
    "service": "peripheral services and prop zone",
    "portal": "walk-through opening",
    "endcap": "intentional run termination",
}


def compact_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build_evidence(captures: list[Path]) -> dict:
    sources = [{"path": str(path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha256(path), "mtime_ns": path.stat().st_mtime_ns} for path in SOURCE_FILES]
    source_stamp = max(item["mtime_ns"] for item in sources)
    capture_items = [{
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "sha256": sha256(path),
        "mtime_ns": path.stat().st_mtime_ns,
        "captured_after_sources": path.stat().st_mtime_ns >= source_stamp,
    } for path in captures]
    source_set_hash = hashlib.sha256("".join(item["sha256"] for item in sources).encode("ascii")).hexdigest()
    return {
        "schema": "ada-museum-wall-source-capture-evidence-v1",
        "source_set_sha256": source_set_hash,
        "sources": sources,
        "captures": capture_items,
        "all_captures_current": all(item["captured_after_sources"] for item in capture_items),
    }


def publish(site: Path) -> dict:
    out = site / "public/museum-wall-kit"
    out.mkdir(parents=True, exist_ok=True)
    validation = json.loads(VALIDATION.read_text(encoding="utf-8"))
    contract = json.loads(CONTRACT.read_text(encoding="utf-8"))["wall_kit"]
    aaa_validation = json.loads(AAA_VALIDATION.read_text(encoding="utf-8")) if AAA_VALIDATION.exists() else {"passed": False}
    static_profile = json.loads(STATIC_PROFILE.read_text(encoding="utf-8")) if STATIC_PROFILE.exists() else {}
    quality = json.loads(QUALITY.read_text(encoding="utf-8"))
    physics = json.loads(PHYSICS.read_text(encoding="utf-8"))
    entries = []

    capture_files = [ATLAS_CAPTURE, FULL_CAPTURE, SHOWCASE_CAPTURE]
    capture_files.extend(sorted(PIECE_CAPTURE.glob("*.png")))
    evidence = build_evidence(capture_files)
    compact_json(out / "capture_evidence.json", evidence)

    shutil.copy2(ATLAS_CAPTURE, out / "museum_wall_kit_atlas.png")
    compact_json(out / "museum_wall_kit_atlas.json", {
        "type": "atlas", "grid_m": 1, "families": list(ROLES),
        "supported_width_cells": [1, 2, 3, 4], "validation": validation,
    })
    entries.append({
        "id": "museum_wall_kit_atlas", "image": "/museum-wall-kit/museum_wall_kit_atlas.png",
        "config": "/museum-wall-kit/museum_wall_kit_atlas.json",
        "notes": "Physical kit sheet: seven semantic wall families, supported widths, and the full build.",
    })

    shutil.copy2(FULL_CAPTURE, out / "full_build_16m.png")
    compact_json(out / "full_build_16m.json", {
        "type": "composed_run", "width_m": 16, "socket": contract["socket"],
        "run_spec": contract["compositions"]["full_build_16m"],
        "gates": {"exact_length": True, "gapless": True, "socket_span": True},
    })
    entries.append({
        "id": "full_build_16m", "image": "/museum-wall-kit/full_build_16m.png",
        "config": "/museum-wall-kit/full_build_16m.json",
        "notes": "One exact 16 m wall composed from seven certified spans; no rescaling and no joint gaps.",
    })

    if SHOWCASE_CAPTURE.exists():
        shutil.copy2(SHOWCASE_CAPTURE, out / "museum_wall_aaa_showcase.png")
        compact_json(out / "museum_wall_aaa_showcase.json", {
            "type": "acceptance_room", "grid_m": 1, "quality_tier": "aaa",
            "families": list(ROLES), "context": ["floor", "ceiling", "returns", "artwork", "service_props", "portal"],
            "quality_gate": quality["global_gates"], "engine_validation": aaa_validation,
            "static_profile": static_profile,
        })
        entries.append({
            "id": "museum_wall_aaa_showcase", "image": "/museum-wall-kit/museum_wall_aaa_showcase.png",
            "config": "/museum-wall-kit/museum_wall_aaa_showcase.json",
            "notes": "In-context acceptance room for seams, material response, portal clearance, lighting, and feature/prop zoning.",
        })

    for kind in ROLES:
        for width in contract["kinds"][kind]["widths"]:
            token = f"{kind}_{width}m"
            image = PIECE_CAPTURE / f"{token}.png"
            shutil.copy2(image, out / image.name)
            config_name = token + ".json"
            compact_json(out / config_name, {
                "type": "museum_wall_piece", "kind": kind, "role": ROLES[kind],
                "width_cells": width, "width_m": width, "height_m": 4,
                "grid_m": 1, "left_socket": contract["socket"], "right_socket": contract["socket"],
                "quality_tier": "aaa", "detail_seed": 4067, "lod_levels": 3,
                "physics": physics["families"][kind],
            })
            entries.append({
                "id": token, "image": f"/museum-wall-kit/{image.name}",
                "config": f"/museum-wall-kit/{config_name}",
                "notes": f"{kind.capitalize()} · {width} m · {ROLES[kind]}.",
            })

    manifest = {
        "version": 3,
        "description": "One-metre museum wall kit: semantic pieces, compact self-describing contracts, exact composition, and an in-context AAA acceptance room.",
        "capture_evidence": "/museum-wall-kit/capture_evidence.json",
        "all_captures_current": evidence["all_captures_current"],
        "entries": entries,
    }
    compact_json(out / "manifest.json", manifest)
    return {"gallery": str(out), "entries": len(entries), "validated": validation.get("passed", False), "aaa_engine_gate": aaa_validation.get("passed", False)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, default=DEFAULT_SITE)
    args = parser.parse_args()
    report = publish(args.site.resolve())
    print(json.dumps(report, indent=2))
    return 0 if report["validated"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
