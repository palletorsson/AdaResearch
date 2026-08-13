#!/usr/bin/env python3
"""Fail-closed validation for the museum-wall C27 capture manifest.

The filename remains the executable named by the round-2 acceptance matrix; the
manifest itself is revisioned and may be produced by a later correction round.
No missing field, stale hash, fallback renderer, resized frame, or duplicate is
accepted as evidence.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageStat
except ImportError as exc:  # missing evidence tooling is a failure
    raise SystemExit(f'{{"ok":false,"error":"Pillow unavailable: {exc}"}}')


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_ENTITIES = {
    "atlas", "full_build", "solid", "feature", "window",
    "vitrine", "service", "portal", "endcap",
}
EXPECTED_VIEWS = {"hero", "grazing_detail", "worst_seam"}
EXPECTED_RESOLUTION = (1920, 1080)
HEX64 = re.compile(r"^[0-9a-f]{64}$")

FRAME_FIELDS = {
    "id", "entity", "view", "path", "image_sha256", "source_sha256",
    "source_json", "source_set_sha256", "config", "config_json",
    "config_sha256", "scene", "scene_sha256", "params", "seed", "lod",
    "engine", "renderer", "adapter", "driver_info", "resolution", "aspect",
    "native_pixels", "camera", "environment", "environment_json",
    "environment_sha256", "animation_time_s", "color_transform", "captured_utc",
}
CAMERA_FIELDS = {
    "position", "basis_x", "basis_y", "basis_z", "fov_deg", "near_m",
    "far_m", "projection", "keep_aspect", "exposure_multiplier", "auto_exposure",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve_path(value: str) -> Path:
    if value.startswith("res://"):
        return ROOT / value[6:]
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def require_hash(value: object, label: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not HEX64.fullmatch(value):
        errors.append(f"{label}: expected lowercase SHA-256")


def image_metrics(path: Path) -> dict[str, float]:
    with Image.open(path) as image:
        rgb = image.convert("RGB")
        width, height = rgb.size
        pixels = list(rgb.getdata())
    total = max(1, width * height)
    clipped = sum(1 for r, g, b in pixels if r >= 254 and g >= 254 and b >= 254)
    crushed = sum(1 for r, g, b in pixels if r <= 2 and g <= 2 and b <= 2)
    stats = ImageStat.Stat(rgb)
    return {
        "width": width,
        "height": height,
        "clipped_highlights_pct": clipped * 100.0 / total,
        "crushed_blacks_pct": crushed * 100.0 / total,
        "mean_r": stats.mean[0],
        "mean_g": stats.mean[1],
        "mean_b": stats.mean[2],
    }


def validate(manifest_path: Path) -> dict[str, object]:
    errors: list[str] = []
    warnings: list[str] = []
    metrics: dict[str, dict[str, float]] = {}
    if not manifest_path.is_file():
        return {"ok": False, "errors": [f"manifest missing: {manifest_path}"]}
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {"ok": False, "errors": [f"manifest unreadable: {exc}"]}

    if manifest.get("complete") is not True:
        errors.append("manifest complete is not true")
    if manifest.get("missing_is_failure") is not True:
        errors.append("manifest does not declare missing_is_failure")
    if manifest.get("renderer_actual") not in {"forward_plus", "mobile"}:
        errors.append(f"forbidden renderer: {manifest.get('renderer_actual')!r}")
    if tuple(manifest.get("resolution", [])) != EXPECTED_RESOLUTION:
        errors.append(f"manifest resolution is not {EXPECTED_RESOLUTION}")
    if manifest.get("errors") != []:
        errors.append(f"capture runner reported errors: {manifest.get('errors')!r}")

    source_hashes = manifest.get("source_sha256")
    if not isinstance(source_hashes, dict) or not source_hashes:
        errors.append("source_sha256 missing or empty")
        source_hashes = {}
    source_json = manifest.get("source_json")
    source_set_hash = manifest.get("source_set_sha256")
    require_hash(source_set_hash, "source_set_sha256", errors)
    if not isinstance(source_json, str):
        errors.append("source_json missing")
    elif sha256_bytes(source_json.encode("utf-8")) != source_set_hash:
        errors.append("source_json does not match source_set_sha256")
    else:
        try:
            if json.loads(source_json) != source_hashes:
                errors.append("source_json content differs from source_sha256")
        except json.JSONDecodeError:
            errors.append("source_json is not valid JSON")
    for source, declared in source_hashes.items():
        require_hash(declared, f"source {source}", errors)
        resolved = resolve_path(source)
        if not resolved.is_file():
            errors.append(f"declared source missing: {source}")
        elif sha256_file(resolved) != declared:
            errors.append(f"stale source hash: {source}")

    environment_json = manifest.get("environment_json")
    environment_hash = manifest.get("environment_sha256")
    require_hash(environment_hash, "environment_sha256", errors)
    if not isinstance(environment_json, str):
        errors.append("environment_json missing")
    elif sha256_bytes(environment_json.encode("utf-8")) != environment_hash:
        errors.append("environment_json hash mismatch")

    frames = manifest.get("frames")
    if not isinstance(frames, list):
        return {"ok": False, "errors": errors + ["frames is not a list"]}
    if len(frames) != 27 or manifest.get("frame_count") != 27:
        errors.append(f"C27 requires exactly 27 frames, got {len(frames)}")

    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    seen_hashes: set[str] = set()
    corpus: dict[str, set[str]] = {entity: set() for entity in EXPECTED_ENTITIES}
    for index, frame in enumerate(frames):
        prefix = f"frame[{index}]"
        if not isinstance(frame, dict):
            errors.append(f"{prefix}: not an object")
            continue
        missing = sorted(FRAME_FIELDS - frame.keys())
        if missing:
            errors.append(f"{prefix}: missing fields {missing}")
        entity = frame.get("entity")
        view = frame.get("view")
        frame_id = frame.get("id")
        path_value = frame.get("path")
        if entity not in EXPECTED_ENTITIES:
            errors.append(f"{prefix}: unexpected entity {entity!r}")
        elif view not in EXPECTED_VIEWS:
            errors.append(f"{prefix}: unexpected view {view!r}")
        else:
            corpus[entity].add(view)
        if frame_id != f"{entity}_{view}":
            errors.append(f"{prefix}: id does not equal entity_view")
        if frame_id in seen_ids:
            errors.append(f"duplicate frame id: {frame_id}")
        seen_ids.add(frame_id)
        if not isinstance(path_value, str):
            errors.append(f"{prefix}: path missing")
            continue
        if path_value in seen_paths:
            errors.append(f"duplicate frame path: {path_value}")
        seen_paths.add(path_value)
        image_path = resolve_path(path_value)
        if not image_path.is_file():
            errors.append(f"{prefix}: image missing {path_value}")
            continue
        declared_image_hash = frame.get("image_sha256")
        require_hash(declared_image_hash, f"{prefix} image_sha256", errors)
        current_hash = sha256_file(image_path)
        if current_hash != declared_image_hash:
            errors.append(f"{prefix}: stale image hash")
        if current_hash in seen_hashes:
            errors.append(f"{prefix}: duplicate image bytes")
        seen_hashes.add(current_hash)
        try:
            frame_metrics = image_metrics(image_path)
        except Exception as exc:  # Pillow may identify truncated/corrupt content
            errors.append(f"{prefix}: image decode failed: {exc}")
            continue
        metrics[str(frame_id)] = frame_metrics
        if (frame_metrics["width"], frame_metrics["height"]) != EXPECTED_RESOLUTION:
            errors.append(f"{prefix}: PNG is not native 1920x1080")
        if frame_metrics["clipped_highlights_pct"] > 0.5:
            errors.append(f"{prefix}: clipped highlights {frame_metrics['clipped_highlights_pct']:.3f}% > 0.5%")
        if frame_metrics["crushed_blacks_pct"] > 1.0:
            errors.append(f"{prefix}: crushed blacks {frame_metrics['crushed_blacks_pct']:.3f}% > 1.0%")
        if tuple(frame.get("resolution", [])) != EXPECTED_RESOLUTION:
            errors.append(f"{prefix}: manifest frame resolution mismatch")
        if frame.get("aspect") != "16:9" or frame.get("native_pixels") is not True:
            errors.append(f"{prefix}: non-native or non-16:9 declaration")
        if frame.get("renderer") != manifest.get("renderer_actual"):
            errors.append(f"{prefix}: renderer differs from run manifest")
        if frame.get("source_sha256") != source_hashes:
            errors.append(f"{prefix}: source hashes differ from run manifest")
        camera = frame.get("camera")
        if not isinstance(camera, dict) or CAMERA_FIELDS - camera.keys():
            errors.append(f"{prefix}: incomplete camera manifest")
        config_json = frame.get("config_json")
        config_hash = frame.get("config_sha256")
        require_hash(config_hash, f"{prefix} config_sha256", errors)
        if not isinstance(config_json, str):
            errors.append(f"{prefix}: config_json missing")
        elif sha256_bytes(config_json.encode("utf-8")) != config_hash:
            errors.append(f"{prefix}: config hash mismatch")
        env_json = frame.get("environment_json")
        if env_json != environment_json or frame.get("environment_sha256") != environment_hash:
            errors.append(f"{prefix}: environment differs from run manifest")
        scene = frame.get("scene")
        scene_path = resolve_path(scene) if isinstance(scene, str) else None
        if scene_path is None or not scene_path.is_file():
            errors.append(f"{prefix}: scene missing")
        elif sha256_file(scene_path) != frame.get("scene_sha256"):
            errors.append(f"{prefix}: stale scene hash")

    for entity, views in corpus.items():
        if views != EXPECTED_VIEWS:
            errors.append(f"{entity}: expected {sorted(EXPECTED_VIEWS)}, got {sorted(views)}")
    if set(manifest.get("entity_counts", {})) != EXPECTED_ENTITIES:
        errors.append("entity_counts key set is incomplete")
    elif any(count != 3 for count in manifest["entity_counts"].values()):
        errors.append("every entity_count must be exactly 3")

    return {
        "schema": "ada-museum-wall-c27-validation-v1",
        "ok": not errors,
        "manifest": str(manifest_path),
        "frame_count": len(frames),
        "renderer": manifest.get("renderer_actual"),
        "errors": errors,
        "warnings": warnings,
        "metrics": metrics,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        default="ada_run/museum_aaa_pass/round5_c27_capture_manifest.json",
    )
    parser.add_argument(
        "--out",
        default="ada_run/museum_aaa_pass/round5_c27_capture_validation.json",
    )
    args = parser.parse_args()
    manifest_path = resolve_path(args.manifest)
    result = validate(manifest_path)
    output_path = resolve_path(args.out)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    compact = json.dumps(result, separators=(",", ":"), ensure_ascii=False)
    output_path.write_text(compact, encoding="utf-8")
    print(compact)
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
