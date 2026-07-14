"""find_artifact_icons.py — give every spine artifact a front.png icon.

The /space-time filmstrip (and any surface that shows artifact thumbnails)
reads public/artifact-gallery/captures/<base>/front.png in the encyclopedia.
That directory is gitignored (a locally-synced capture area), so this tool
re-derives it from what already exists rather than re-capturing:

  1. census: every interactable base name in every spine-sequence map
  2. search, in order: the gallery's own other angles, the Godot multi_shots
     dir (Roaming), then every public gallery root for <base>.png /
     <base>/front.png / captures/<base>.png
  3. special-cases: promoted DNA-family artifacts whose images live under
     their variant names (dna_* → the DNA galleries)
  4. copy hits into artifact-gallery/captures/<base>/front.png and report
     what still needs a real capture run

Run after new sequences land or captures refresh:
  python tools/find_artifact_icons.py            # report + copy
  python tools/find_artifact_icons.py --dry-run  # report only

First run (2026-07-14): 803/803 spine artifacts covered — 376 already
present, 410 found in scene-catalog/prop-shots/multi_shots, 17 via the
DNA-variant special cases, 0 left to capture.
"""
import argparse
import json
import os
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public"))
GAL = os.path.join(ENC, "artifact-gallery", "captures")
SHOTS = os.path.expandvars(r"%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots")
MIN_BYTES = 4000  # below this it's a blank/failed capture

# promoted DNA-family artifacts: image lives under the variant name
SPECIAL = {
    "dna_modern_art_rothko_chromatic_field": "blog/shader_showcase/rothko_above.png",
    "dna_modern_art_mondrian_de_stijl": "chromatic-fins-gallery/fins_mondrian.png",
    "dna_modern_art_kandinsky_bauhaus_triad": "modern-art-gallery/kandinsky_bauhaus_triad.png",
    "dna_modern_art_albers_homage_warm": "modern-art-gallery/albers_homage_warm.png",
    "dna_color_furniture_furniture_becker_utensilo_bauhaus": "color-furniture-gallery/furniture_becker_utensilo_bauhaus.png",
    "dna_color_furniture_furniture_coco_pendant_warm": "color-furniture-gallery/furniture_coco_pendant_complementary.png",
    "dna_color_furniture_furniture_lamp_warm_glow": "color-furniture-gallery/furniture_lamp_warm_glow.png",
    "dna_color_furniture_furniture_vignelli_metafora_primary": "color-furniture-gallery/furniture_vignelli_metafora_primary.png",
    "dna_color_stacks_stack_complementary_red_green": "color-stacks-gallery/stack_complementary_red_green.png",
    "dna_color_stacks_stack_monochrome_blue": "color-stacks-gallery/stack_monochrome_blue.png",
    "dna_color_stacks_stack_simultaneous_contrast": "color-stacks-gallery/stack_simultaneous_contrast.png",
    "dna_color_stacks_stack_triadic_primary": "color-stacks-gallery/stack_triadic_primary.png",
    "dna_color_stacks_stack_value_steps_warm": "color-stacks-gallery/stack_value_steps_warm.png",
    "dna_primitive_stack_ps01_bauhaus_totem_green": "primitive-stack-gallery/ps01_bauhaus_totem_green.png",
    "loom_alhambra_p6m": "pattern-mill-gallery/loom_fountain_alhambra_p6m.png",
    "loom_escher_mirror": "pattern-mill-gallery/loom_bolt_escher_pmm.png",  # closest kin (pmm bolt)
    "vector_projection_reflection_xl": "principle-geometric-gallery/vectors__07_vector_projection_reflection.png",
}


def ok(path):
    return os.path.isfile(path) and os.path.getsize(path) > MIN_BYTES


def spine_bases():
    spine = json.load(open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"), encoding="utf-8"))
    seq_ids = set(s["name"] for s in spine.get("spine", spine)["sequences"])
    # every map dir whose sequence is on the spine, via the maps' own data
    bases = set()
    maps_dir = os.path.join(ROOT, "commons", "maps")
    # walk all map dirs; membership from the encyclopedia catalog is nicer but
    # this must run without the web server: use sequence field when present,
    # else include (over-approximation is harmless for icon coverage).
    for mn in os.listdir(maps_dir):
        mp = os.path.join(maps_dir, mn, "map_data.json")
        if not os.path.isfile(mp):
            continue
        try:
            d = json.load(open(mp, encoding="utf-8"))
        except Exception:
            continue
        seq = (d.get("map_info", {}).get("metadata", {}) or {}).get("sequence") \
            or d.get("map_info", {}).get("sequence")
        if seq is not None and seq not in seq_ids:
            continue
        for row in d.get("layers", {}).get("interactables", []):
            for c in row:
                tok = str(c).strip()
                if tok:
                    b = tok.split(":")[0].split("#")[0]
                    if b:
                        bases.add(b)
    return bases


def find_source(base):
    for angle in ("iso", "top", "side", "hero", "detail"):
        p = os.path.join(GAL, base, f"{angle}.png")
        if ok(p):
            return p
    for angle in ("front", "iso", "top"):
        p = os.path.join(SHOTS, base, f"{angle}.png")
        if ok(p):
            return p
    if base in SPECIAL:
        p = os.path.join(ENC, SPECIAL[base])
        if ok(p):
            return p
    for root in os.listdir(ENC):
        rp = os.path.join(ENC, root)
        if not os.path.isdir(rp):
            continue
        for cand in (os.path.join(rp, base + ".png"),
                     os.path.join(rp, base, "front.png"),
                     os.path.join(rp, "captures", base + ".png")):
            if ok(cand):
                return cand
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    bases = spine_bases()
    have = [b for b in bases if ok(os.path.join(GAL, b, "front.png"))]
    missing = sorted(b for b in bases if b not in set(have))
    print(f"spine artifacts: {len(bases)} | with icon: {len(have)} | missing: {len(missing)}")
    copied, uncovered = 0, []
    for b in missing:
        src = find_source(b)
        if src is None:
            uncovered.append(b)
            continue
        if not args.dry_run:
            os.makedirs(os.path.join(GAL, b), exist_ok=True)
            shutil.copyfile(src, os.path.join(GAL, b, "front.png"))
        copied += 1
    print(f"{'would copy' if args.dry_run else 'copied'}: {copied} | still uncovered: {len(uncovered)}")
    if uncovered:
        out = os.path.join(ROOT, "doc", "reports", "spine_icons_to_capture.json")
        json.dump(uncovered, open(out, "w"), indent=1)
        print(f"capture worklist -> {out}")
        for b in uncovered[:20]:
            print("  ", b)


if __name__ == "__main__":
    main()
