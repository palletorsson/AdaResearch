#!/usr/bin/env python3
"""
inject_canon_into_conveyor.py
==============================

Read a curated set of primitive_stack configs (color-stacks, modern-art,
modern-design, modern-architecture) and inject them as a "compositions"
category in commons/primitives/assembly/products.json. Each composition
becomes a conveyor-belt product whose slots are the primitive_stack
sequence — same shapes, same colors, same per-slot scales — with
stack_mode=true so the runtime auto-stacks them vertically.

After injection, the conveyor can build:
  /assembly/conveyor?puzzle_type=mondrian
  /assembly/conveyor?puzzle_type=mies_barcelona_pavilion
…and emits the assembled totem on the output belt.

Run:
    python tools/inject_canon_into_conveyor.py
"""

from __future__ import annotations
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia"
PRODUCTS = REPO / "commons" / "primitives" / "assembly" / "products.json"

# Curated picks — short, legible compositions (3–6 primitives each).
# Stack mode autostacks; we only need shape + color + scale per primitive.
PICKS: list[tuple[str, str, str, str]] = [
    # (gallery_slug, entry_id, conveyor_key, display_name)
    ("modern-art-gallery", "mondrian_de_stijl",         "mondrian",       "Mondrian: De Stijl"),
    ("modern-art-gallery", "malevich_black_square",     "malevich",       "Malevich: Black Square"),
    ("modern-art-gallery", "kandinsky_bauhaus_triad",   "kandinsky",      "Kandinsky: Bauhaus triad"),
    ("modern-art-gallery", "newman_zip",                "newman",         "Newman: Zip"),
    ("modern-art-gallery", "rothko_chromatic_field",    "rothko",         "Rothko: chromatic field"),
    ("modern-art-gallery", "kelly_hard_edge",           "kelly",          "Kelly: hard-edge"),
    ("modern-design-gallery", "rietveld_red_blue_chair","rietveld",       "Rietveld: Red/Blue Chair"),
    ("modern-design-gallery", "saarinen_tulip_pedestal","tulip",          "Saarinen: Tulip"),
    ("modern-design-gallery", "castiglioni_arco",       "arco",           "Castiglioni: Arco"),
    ("modern-architecture-gallery", "mies_barcelona_pavilion", "barcelona", "Mies: Barcelona Pavilion"),
    ("modern-architecture-gallery", "lecorbusier_villa_savoye","savoye",    "Le Corbusier: Villa Savoye"),
    ("modern-architecture-gallery", "wright_fallingwater",     "fallingwater","Wright: Fallingwater"),
    ("color-stacks-gallery", "stack_complementary_red_green",  "complement_rg","Complementary: red/green"),
    ("color-stacks-gallery", "stack_triadic_primary",          "triadic_primary","Triadic: primary"),
]


def load_config(gallery: str, entry_id: str) -> dict | None:
    p = ENC / "public" / gallery / f"{entry_id}.json"
    if not p.exists():
        print(f"  MISSING: {p}")
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def primstack_to_slots(cfg: dict) -> list[dict]:
    """Convert a primitive_stack `sequence` to conveyor slots."""
    slots = []
    for prim in cfg.get("sequence", []):
        s = prim.get("scale", 1.0)
        slots.append({
            "type": prim.get("shape", "cube"),
            "color": prim.get("color", "#888888"),
            # Conveyor visuals are tiny; clamp scale so big totems don't tower.
            "scale": [max(0.5, min(s, 1.6))] * 3,
        })
    return slots


def reward_scene_for(gallery: str, entry_id: str) -> str:
    """Point at the prebaked .tscn — output belt emits the real totem."""
    return f"res://commons/generated/gallery_best_of/scenes/{gallery}__{entry_id}.tscn"


def main():
    products_data = json.loads(PRODUCTS.read_text(encoding="utf-8"))

    products: dict[str, dict] = {}
    sequence: list[str] = []
    for gallery, entry_id, key, name in PICKS:
        cfg = load_config(gallery, entry_id)
        if not cfg:
            continue
        slots = primstack_to_slots(cfg)
        if not slots:
            print(f"  empty   {key}")
            continue
        products[key] = {
            "name": name,
            "slots": slots,
            "stack_mode": True,
            "reward_type": key,
            "reward_scene": reward_scene_for(gallery, entry_id),
        }
        sequence.append(key)
        print(f"  {key:20s} {len(slots)} slots from {gallery}__{entry_id}")

    products_data.setdefault("categories", {})["compositions"] = {
        "name": "Modern Compositions",
        "products": products,
        "default_sequence": sequence,
    }

    aliases = products_data.setdefault("aliases", {})
    for key in products.keys():
        aliases[key] = {"category": "compositions", "product": key}
    aliases["compositions"] = {"category": "compositions"}
    aliases["modern_canon"] = {"category": "compositions"}
    aliases["canon"] = {"category": "compositions"}

    PRODUCTS.write_text(json.dumps(products_data, indent="\t") + "\n", encoding="utf-8")
    print(f"\nWrote {len(products)} compositions into {PRODUCTS.relative_to(REPO)}")


if __name__ == "__main__":
    main()
