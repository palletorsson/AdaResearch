#!/usr/bin/env python3
"""
promote_to_artifact.py
=======================

Turn any DNA-gallery finding into a placeable artifact, two ways:

  TOKEN MODE  (default):
    Print the interactables-layer token to drop in a map_data.json.
    Reuses existing per-grammar builder artifacts where available
    (facade_builder, composition_artifact, etc.). Falls back to
    image_billboard for galleries without a builder.

  REGISTRY MODE  (--emit-registry):
    Write a registry entry for the finding under
    commons/artifacts/registry/dna_promoted.json. Once
    GridInteractablesComponent supports `delegate_to`, the entry can
    name the existing builder + per-instance params, and the finding
    becomes a first-class registry citizen. Until then, the registry
    entry uses the same builder lookup directly with parameters baked
    into the entry's `parameters` block.

Why this file (not a GDScript dispatcher): every grammar already has
its own builder artifact in the registry. A central dispatcher would
duplicate logic that already lives in the per-grammar artifacts.
This Python helper just spells the token / registry entry — the
runtime behavior comes from the existing artifacts.

Usage:
    python tools/promote_to_artifact.py facade-gallery classical
    python tools/promote_to_artifact.py lsystem-gallery ls21_cpfg_weeping_plant
    python tools/promote_to_artifact.py facade-gallery classical --emit-registry
    python tools/promote_to_artifact.py --list   # show all best-of items
"""

from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path
from typing import Callable

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia"
BEST_OF_DIR = REPO / "commons" / "generated" / "gallery_best_of"
BEST_OF_CONFIGS = BEST_OF_DIR / "configs"
BEST_OF_IMAGES = BEST_OF_DIR / "images"
BEST_OF_MANIFEST = BEST_OF_DIR / "manifest.json"

PROMOTED_REGISTRY = REPO / "commons" / "artifacts" / "registry" / "dna_promoted.json"

# ── Gallery → existing-artifact mapping ─────────────────────────
# When a curated finding is promoted, this table says which already-
# registered artifact to instantiate and how to translate the finding's
# config into the artifact's apply_grid_config parameters.
#
# Each entry: { artifact: <lookup_name>, params: <fn(cfg, entry_id) -> dict> }
#
# `params` returns the dict that goes into the token's `#k:v#k:v` tail
# (or into the registry entry's parameters block in registry mode).
#
# Galleries without a row here fall through to image_billboard with
# image_path pointing at the curated screenshot.

def _facade_params(cfg: dict, entry_id: str) -> dict:
    return {"preset": cfg.get("id", entry_id)}


def _config_path_only(gallery_slug: str):
    """Most artifact wrappers just want a config_path pointing at the
    harvested config in best_of/configs/<gallery>__<entry>.json."""
    def _fn(cfg: dict, entry_id: str) -> dict:
        return {
            "config_path": f"res://commons/generated/gallery_best_of/configs/{gallery_slug}__{entry_id}.json",
        }
    return _fn


def _primstack_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/primitive-stack-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _color_stack_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/color-stacks-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _color_furniture_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/color-furniture-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _modern_art_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/modern-art-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _modern_design_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/modern-design-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _modern_arch_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/modern-architecture-gallery__{entry_id}.json",
        "grammar": "primitive_stack",
    }


def _turrell_params(cfg: dict, entry_id: str) -> dict:
    return {
        "config_path": f"res://commons/generated/gallery_best_of/configs/turrell-spaces-gallery__{entry_id}.json",
    }


GALLERY_MAP: dict[str, dict] = {
    "facade-gallery": {
        "artifact": "facade_builder",
        "params": _facade_params,
    },
    "primitive-stack-gallery": {
        "artifact": "composition_artifact",
        "params": _primstack_params,
    },
    "lsystem-gallery": {
        "artifact": "lsystem_artifact",
        "params": _config_path_only("lsystem-gallery"),
    },
    "pattern-gallery": {
        "artifact": "pattern_artifact",
        "params": _config_path_only("pattern-gallery"),
    },
    "rd-gallery": {
        "artifact": "rd_artifact",
        "params": _config_path_only("rd-gallery"),
    },
    "trajectory-gallery": {
        "artifact": "trajectory_artifact",
        "params": _config_path_only("trajectory-gallery"),
    },
    "mesh-grammar-gallery": {
        "artifact": "mesh_grammar_artifact",
        "params": _config_path_only("mesh-grammar-gallery"),
    },
    "color-stacks-gallery": {
        "artifact": "composition_artifact",
        "params": _color_stack_params,
    },
    "color-furniture-gallery": {
        "artifact": "composition_artifact",
        "params": _color_furniture_params,
    },
    "modern-art-gallery": {
        "artifact": "composition_artifact",
        "params": _modern_art_params,
    },
    "modern-design-gallery": {
        "artifact": "composition_artifact",
        "params": _modern_design_params,
    },
    "modern-architecture-gallery": {
        "artifact": "composition_artifact",
        "params": _modern_arch_params,
    },
    "turrell-spaces-gallery": {
        "artifact": "chromatic_form_artifact",
        "params": _turrell_params,
    },
    # graph-grammar, morphology, soft-body — not yet wrapped → image_billboard.
}


def _image_billboard_params(gallery: str, entry_id: str) -> dict:
    return {
        "image_path": f"res://commons/generated/gallery_best_of/images/{gallery}__{entry_id}.png",
    }


# ── Helpers ──────────────────────────────────────────────────────

def load_best_of_manifest() -> dict:
    if not BEST_OF_MANIFEST.exists():
        return {"items": []}
    return json.loads(BEST_OF_MANIFEST.read_text(encoding="utf-8"))


def load_finding_config(gallery: str, entry_id: str) -> dict:
    p = BEST_OF_CONFIGS / f"{gallery}__{entry_id}.json"
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


PREBAKED_DIR = REPO / "commons" / "generated" / "gallery_best_of" / "scenes"


def resolve(gallery: str, entry_id: str, prefer_prebaked: bool = True) -> tuple[str, dict, str]:
    """Return (artifact_lookup, params_dict, render_mode).
    render_mode is one of:
      "prebaked" - a baked .tscn exists; use prebaked_loader (fastest, default)
      "live"     - run the grammar's wrapper artifact (recompiles each load)
      "image"    - fallback image_billboard with the curated PNG
    """
    # 1. Prebaked .tscn beats everything when available.
    if prefer_prebaked:
        baked = PREBAKED_DIR / f"{gallery}__{entry_id}.tscn"
        if baked.exists():
            return "prebaked_loader", {
                "scene_path": f"res://commons/generated/gallery_best_of/scenes/{gallery}__{entry_id}.tscn",
            }, "prebaked"

    # 2. Live wrapper if the gallery has one mapped.
    if gallery in GALLERY_MAP:
        spec = GALLERY_MAP[gallery]
        cfg = load_finding_config(gallery, entry_id)
        params = spec["params"](cfg, entry_id)
        return spec["artifact"], params, "live"

    # 3. Image fallback for galleries without a wrapper.
    return "image_billboard", _image_billboard_params(gallery, entry_id), "image"


def make_token(artifact: str, params: dict, rotation: int = 0, y_offset: float = 0.0) -> str:
    head = f"{artifact}:{rotation}:{y_offset}"
    if not params:
        return head
    tail = "#".join(f"{k}:{v}" for k, v in params.items())
    return f"{head}#{tail}"


# ── Registry emit (for delegate_to / direct modes) ──────────────

def emit_registry_entry(gallery: str, entry_id: str, mode: str) -> dict:
    """Generate a registry artifact entry that promotes a finding.

    mode='direct': sets `scene` to the builder's tscn and bakes params
        into the parameters block. Works with the current registry
        loader IF the artifact reads its parameters at _ready (some do,
        some only via apply_grid_config + tokens).
    mode='delegate': sets `delegate_to` + `delegate_params` — depends on
        the GridInteractablesComponent extension landing.
    """
    artifact, params, render_mode = resolve(gallery, entry_id)
    lookup = f"dna_{gallery.replace('-gallery','').replace('-','_')}_{entry_id}"
    name_pretty = entry_id.replace("_", " ").title()
    notes = f"Promoted from /dna {gallery} entry '{entry_id}'."

    base = {
        "lookup_name": lookup,
        "name": f"DNA: {name_pretty}",
        "description": notes,
        "category": "dna_promoted",
        "complexity": "intermediate",
        "include_in_map_data": True,
        "map_ready": True,
        "map_sequences": [],
        "footprint": [1, 1, 2],
        "tags": ["dna", "promoted", gallery, render_mode],
        "qfep_connection": "F_order: a curated finding given a name in the registry.",
        "size_group": "compact",
    }

    if mode == "delegate":
        base["delegate_to"] = artifact
        base["delegate_params"] = params
        # No `scene` field — GridInteractablesComponent looks up artifact via delegate_to.
    else:
        # 'direct' — point at the existing builder's scene + bake params.
        # Caveat: only works if the builder's _ready can read params via meta
        # OR the calling map_data also passes them in the token.
        scene_map = {
            "facade_builder":        "res://commons/artifacts/facade_builder/facade_builder.tscn",
            "composition_artifact":  "res://commons/artifacts/composition_artifact/composition_artifact.tscn",
            "lsystem_artifact":      "res://commons/artifacts/lsystem_artifact/lsystem_artifact.tscn",
            "pattern_artifact":      "res://commons/artifacts/pattern_artifact/pattern_artifact.tscn",
            "rd_artifact":           "res://commons/artifacts/rd_artifact/rd_artifact.tscn",
            "trajectory_artifact":   "res://commons/artifacts/trajectory_artifact/trajectory_artifact.tscn",
            "mesh_grammar_artifact": "res://commons/artifacts/mesh_grammar_artifact/mesh_grammar_artifact.tscn",
            "prebaked_loader":       "res://commons/artifacts/prebaked_loader/prebaked_loader.tscn",
            "image_billboard":       "res://commons/artifacts/image_billboard/image_billboard.tscn",
        }
        base["scene"] = scene_map.get(artifact, "")
        base["parameters"] = dict(params)
        base["parameters"].update({"footprint": [1, 1, 2], "size_group": "compact"})
    return {lookup: base}


def write_registry_entry(gallery: str, entry_id: str, mode: str) -> Path:
    payload = emit_registry_entry(gallery, entry_id, mode)
    if PROMOTED_REGISTRY.exists():
        existing = json.loads(PROMOTED_REGISTRY.read_text(encoding="utf-8"))
        existing.setdefault("artifacts", {}).update(payload)
    else:
        existing = {
            "id": "dna_promoted",
            "name": "DNA Promoted Findings",
            "description": (
                "Curated /dna gallery findings promoted to first-class "
                "registry artifacts. Each entry either delegates to an "
                "existing builder via delegate_to (when supported) or "
                "directly sets the builder's scene + parameters."
            ),
            "category": "dna_promoted",
            "theoreticalGrounding": "Curation as registry growth.",
            "artifacts": payload,
        }
    PROMOTED_REGISTRY.write_text(
        json.dumps(existing, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8")
    return PROMOTED_REGISTRY


# ── CLI ──────────────────────────────────────────────────────────

def cmd_list() -> None:
    m = load_best_of_manifest()
    items = m.get("items", [])
    print(f"Best-of items: {len(items)}")
    for it in items:
        g = it.get("gallery", "?")
        e = it.get("entry_id", "?")
        stars = it.get("stars", 0)
        verdict = it.get("verdict", "")
        in_map = "*" if g in GALLERY_MAP else " "
        print(f"  [{in_map}] {stars}*  {g:30s} {e:40s}  {verdict}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("gallery", nargs="?", help="Gallery slug (e.g. facade-gallery)")
    ap.add_argument("entry_id", nargs="?", help="Entry id within the gallery")
    ap.add_argument("--list", action="store_true",
                    help="List all best-of items + show which have a builder mapping")
    ap.add_argument("--emit-registry", action="store_true",
                    help="Write a registry entry instead of just printing the token")
    ap.add_argument("--mode", choices=["delegate", "direct"], default="delegate",
                    help="Registry mode: delegate (uses delegate_to, requires extension) "
                         "or direct (uses scene + parameters; works today)")
    ap.add_argument("--rotation", type=int, default=0)
    ap.add_argument("--y-offset", type=float, default=0.0, dest="y_offset")
    args = ap.parse_args()

    if args.list:
        cmd_list()
        return

    if not (args.gallery and args.entry_id):
        ap.print_help()
        sys.exit(1)

    artifact, params, render_mode = resolve(args.gallery, args.entry_id)
    print(f"gallery:      {args.gallery}")
    print(f"entry_id:     {args.entry_id}")
    print(f"render mode:  {render_mode} (artifact: {artifact})")
    print()

    if args.emit_registry:
        path = write_registry_entry(args.gallery, args.entry_id, args.mode)
        print(f"Registry written to: {path.relative_to(REPO)}")
        print(f"Mode: {args.mode}")
        return

    token = make_token(artifact, params, rotation=args.rotation, y_offset=args.y_offset)
    print("Token (drop into map_data.json's interactables layer):")
    print()
    print(f"    {token}")
    print()


if __name__ == "__main__":
    main()
