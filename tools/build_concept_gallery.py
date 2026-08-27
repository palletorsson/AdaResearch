"""build_concept_gallery.py — a sequence's concept atlas as a SELECTABLE image gallery.

2026-08-27, Palle: "what I want here is like the gallery of images, like
localhost:3003/forces-props-dna with the name of the algorithm or principal under
images of the artifacts and name. Where I can select what artifact should be part
of maps."

So: one tile per artifact, portrait + artifact name + ITS PRINCIPLE as the subtitle,
ordered concept-by-concept, rendered by the same GalleryView the DNA galleries use —
because GalleryView already carries the selection mechanic (verdict chips persisted to
public/<gallery>/evals.json via /api/gallery-evals). The page declares map-membership
verdicts (retire / corpus only / in maps / hero); tools/read_concept_selections.py
reads the evals back on this side, so a click in the browser is a fact the retire
swap can consume.

SOURCES, in trust order:
  doc/<domain>_concept_map.json      the concept canon + scored membership (June gen)
  the sequence's own maps            which tokens are PLACED today (walked live here,
                                     because the June file predates the fold)
  doc/<seq>_concept_additions.json   the hand layer: tokens the canon has never met
                                     (today: the seven new prop-gallery objects),
                                     {token: concept} — refused if the concept is not
                                     in the canon, so a typo cannot invent a section
Portraits: public/scene-catalog/<token>.png, else the newest public/<dna-slug>/
<token>__*.png (the prop gallery shot its own portraits), else the tile says so.

Run:  python tools/build_concept_gallery.py forces
Writes: <encyclopedia>/public/<seq>-concepts/manifest.json (no PNGs are copied —
entries reference the images where they already live).
"""
from __future__ import annotations
import json
import os
import sys
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public"))

# sequence id -> concept-map basename, where they differ (same aliasing the coverage
# audit in doc/CONCEPT_ATLAS.md used)
ALIAS = {
    "forces": "vector_forces",
    "cellularautomata": "ca",
    "lsystems": "lsystem",
    "softbodies": "softbody",
    "proceduralgeneration": "procgen",
    "foundationscrisis": "foundationscrisis",
    "postfoundationscrisis": "postfoundationscrisis",
    "fractals": "fractals",
}


def placed_census(seq_id: str) -> dict[str, int]:
    """Token -> placement count across the sequence's CURRENT maps."""
    seqf = os.path.join(ROOT, "commons", "maps", "sequences", f"{seq_id}.json")
    doc = json.load(open(seqf, encoding="utf-8"))
    # sequence files come in two shapes: {"sequences": {id: {...}}} and flat {...};
    # map entries come as strings or as {"name": ...} dicts. Tolerate all four.
    seq = doc.get("sequences", {}).get(seq_id) if isinstance(doc.get("sequences"), dict) else None
    if seq is None and isinstance(doc.get("sequences"), dict) and len(doc["sequences"]) == 1:
        seq = next(iter(doc["sequences"].values()))
    if seq is None:
        seq = doc
    counts: dict[str, int] = {}
    map_names = []
    for m in seq.get("maps", []):
        map_names.append(m if isinstance(m, str) else (m.get("name") or m.get("map") or ""))
    for name in map_names:
        mp = os.path.join(ROOT, "commons", "maps", str(name), "map_data.json")
        if not os.path.exists(mp):
            continue
        md = json.load(open(mp, encoding="utf-8"))
        for row in (md.get("layers") or md).get("interactables") or []:
            for c in row:
                c = str(c).strip()
                if c and c != "0":
                    tok = c.split(":")[0]
                    counts[tok] = counts.get(tok, 0) + 1
    return counts


def portrait(token: str, seq_id: str) -> str | None:
    p = os.path.join(ENC, "scene-catalog", f"{token}.png")
    if os.path.exists(p):
        return f"/scene-catalog/{token}.png"
    # the DNA galleries shoot per-variant frames; prefer the shipped/default one
    hits = sorted(glob.glob(os.path.join(ENC, "*", f"{token}__*.png")))
    if hits:
        shipped = [h for h in hits if "shipped" in os.path.basename(h) or "props" in os.path.basename(h)]
        pick = (shipped or hits)[0]
        rel = os.path.relpath(pick, ENC).replace(os.sep, "/")
        return "/" + rel
    # dna_promoted tokens are prefixed registry names over gallery families whose PNGs
    # drop the family prefix: dna_color_stacks_stack_complementary_red_green lives at
    # color-stacks-gallery/stack_complementary_red_green.png. Try each suffix cut.
    # a NEW artifact's first portrait lives in the capture bench's output, not yet in
    # the catalog. Adopt it: copy multi_shots/<token>/front_mid.png into scene-catalog,
    # so the catalog grows with the corpus instead of freezing at its last generation.
    shot = os.path.join(os.path.expandvars("%APPDATA%"), "Godot", "app_userdata",
                        "Ada Research Zero One", "multi_shots", token, "front_mid.png")
    if os.path.exists(shot):
        import shutil
        dest = os.path.join(ENC, "scene-catalog", f"{token}.png")
        shutil.copyfile(shot, dest)
        return f"/scene-catalog/{token}.png"
    if token.startswith("dna_"):
        parts = token[4:].split("_")
        for i in range(1, len(parts)):
            tail = "_".join(parts[i:])
            hits = sorted(glob.glob(os.path.join(ENC, "*-gallery", f"{tail}.png")))
            if hits:
                rel = os.path.relpath(hits[0], ENC).replace(os.sep, "/")
                return "/" + rel
    return None


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    seq_id = sys.argv[1]
    domain = ALIAS.get(seq_id, seq_id)
    cmf = os.path.join(ROOT, "doc", f"{domain}_concept_map.json")
    if not os.path.exists(cmf):
        print(f"no concept map for {seq_id} ({cmf}) — build it first")
        return 1
    cm = json.load(open(cmf, encoding="utf-8"))
    placed = placed_census(seq_id)

    additions: dict[str, str] = {}
    addf = os.path.join(ROOT, "doc", f"{seq_id}_concept_additions.json")
    if os.path.exists(addf):
        raw = json.load(open(addf, encoding="utf-8"))
        additions = {k: v for k, v in raw.items() if not k.startswith("_")}
        bad = [t for t, c in additions.items() if c not in cm["concepts"]]
        if bad:
            # a typo must not invent a section — the canon is the concept list
            print(f"REFUSED additions with unknown concepts: {bad}")
            return 1

    entries = []
    seen: set[str] = set()
    missing_portraits: list[str] = []
    for concept in cm["concepts"]:
        meta = cm.get("concept_meta", {}).get(concept, {})
        truth = str(meta.get("truth", ""))
        members = [g["lookup"] for g in cm.get("groups", {}).get(concept, [])]
        members += [t for t, c in additions.items() if c == concept]
        for token in members:
            if token in seen:
                continue
            seen.add(token)
            img = portrait(token, seq_id)
            if img is None:
                missing_portraits.append(token)
                continue
            n = placed.get(token, 0)
            status = (f"PLACED x{n} in {seq_id} maps" if n
                      else ("NEW - prop gallery, not yet placed" if token in additions
                            else "corpus only - in no current map"))
            entries.append({
                "id": token,
                "prop": token,
                "index": 0,
                "label": token,
                "subtitle": concept,               # the principle, under the image
                "notes": f"{concept} — {truth}  ·  {status}",
                "image": img,
                "dna": {},
            })

    out_dir = os.path.join(ENC, f"{seq_id}-concepts")
    os.makedirs(out_dir, exist_ok=True)
    manifest = {
        "version": 1,
        "description": (f"{seq_id}: every artifact under its principle. Chips are MAP "
                        f"MEMBERSHIP - what you select here is read back by "
                        f"tools/read_concept_selections.py and drives the placement swap."),
        "capture_size": [760, 760],
        "partial_axes": {},
        "entries": entries,
    }
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    print(f"{len(entries)} tiles across {len(cm['concepts'])} concepts -> {out_dir}/manifest.json")
    if missing_portraits:
        # a silent drop would read as "covered" — say what fell out (the no-silent-caps rule)
        print(f"NO PORTRAIT ({len(missing_portraits)}): {', '.join(missing_portraits[:10])}"
              + (" ..." if len(missing_portraits) > 10 else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
