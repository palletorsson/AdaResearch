#!/usr/bin/env python3
"""chapter_stage.py — the staging brief: the bridge from a finished chapter to its final map.

"The chapter is the score; the map is the performance." For a sequence, this
gathers everything the hangar staging needs from data that already exists:

  roster     the chapter's walk (tutorial JSON) — the admission list
  tier       concept-ladder tier (small/medium/large/applied) from doc/<seq>_concept_map.json
  scale      physical rank from size_group / measured base_m (the gaze law's input)
  staging    dressing-room posture -> staging-DNA type (the setting is typed, not invented)
  prose      does the authored overlay carry a sentence for it? (no prose, no plinth)
  rhythm     the scale sequence along the walk, scored like prosody — flag clashes and flats
  alignment  placed-but-unwritten / written-but-unplaced
  grid       suggested grid from summed footprints (footprint determines the grid)
  floor plan the 8-page grammar mapped to the map's phases

Usage:
  python tools/chapter_stage.py randomness fractals
Output:
  doc/book/staging_briefs/<seq>.md (+ stdout summary)
"""
from __future__ import annotations

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
AUTHORED = os.path.join(REPO, "doc", "tutorial_authored")
ROOMS = os.path.join(REPO, "commons", "artifacts", "dressing_rooms")
DNA = os.path.join(REPO, "commons", "data", "staging_dna.json")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
DOC = os.path.join(REPO, "doc")
OUT_DIR = os.path.join(REPO, "doc", "book", "staging_briefs")

# seq id -> canonical concept-map file stem (the 10 canonical maps)
CONCEPT_MAP_ALIASES = {"fractals": "fractal", "randomness": "randomness", "cellularautomata": "ca",
                       "lsystems": "lsystem", "softbodies": "softbody", "proceduralgeneration": "procgen",
                       "foundationscrisis": "foundations", "qfeplaboratory": "qfep",
                       "postfoundationscrisis": "postcrisis"}
SCALE_NAMES = ["small", "medium", "large", "xlarge"]
SIZE_GROUP_RANK = {"compact": 0, "medium": 1, "large": 2, "environment": 3, "xlarge": 3}

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def base_m_of(entry) -> float | None:
    if isinstance(entry, (int, float)):
        return float(entry)
    if isinstance(entry, dict):
        if isinstance(entry.get("base_m"), (int, float)):
            return float(entry["base_m"])
        ab = entry.get("aabb_size") or entry.get("aabb")
        if isinstance(ab, list) and len(ab) >= 3:
            return float(max(ab[0], ab[2]))
    return None


def ladder_tiers(seq: str) -> dict[str, str]:
    """artifact lookup -> small/medium/large/applied from the seq's concept map."""
    stem = CONCEPT_MAP_ALIASES.get(seq, seq)
    cm = load_json(os.path.join(DOC, f"{stem}_concept_map.json"))
    out: dict[str, str] = {}
    if not isinstance(cm, dict):
        return out
    for meta in (cm.get("concept_meta") or {}).values():
        for tier, names in (meta.get("tiers") or {}).items():
            for n in names or []:
                out.setdefault(n, tier)
    return out


def scale_rank(name: str, params, sizes) -> tuple[int, float | None]:
    b = base_m_of(sizes.get(name))
    # measured reality beats the registry's declared size_group
    if b is not None:
        return (0 if b < 1.5 else 1 if b < 4 else 2 if b < 10 else 3), b
    sg = (params or {}).get("size_group")
    if sg in SIZE_GROUP_RANK:
        return SIZE_GROUP_RANK[sg], b
    return 1, b


def brief(seq: str, dna_types: dict, sizes: dict) -> str | None:
    t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
    if not t:
        print(f"!! no tutorial for {seq}")
        return None
    overlay = load_json(os.path.join(AUTHORED, f"{seq}.json")) or {}
    prose: set[str] = set()
    for key in ("primitive", "walk1", "walk2"):
        arts = (overlay.get(key) or {}).get("artifacts")
        if isinstance(arts, dict):
            prose |= set(arts)

    walk = []
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            walk.append(p["artifact"])
        elif p["kind"] == "walk":
            walk += [a for a in p.get("artifacts") or []]
    if not walk:
        print(f"!! empty walk for {seq}")
        return None

    tiers = ladder_tiers(seq)
    rows = []
    for a in walk:
        name = a.get("name", "?")
        rank, b = scale_rank(name, a.get("parameters"), sizes)
        room = load_json(os.path.join(ROOMS, f"{name}.json")) or {}
        posture = room.get("posture") or "pedestal"
        # measured grid_cells first, then dressing-room footprint
        gc = (sizes.get(name) or {}).get("grid_cells") if isinstance(sizes.get(name), dict) else None
        if isinstance(gc, list) and len(gc) >= 2:
            cells = max(1, int(math.ceil(gc[0])) * int(math.ceil(gc[1])))
        else:
            fp = room.get("footprint") or (a.get("parameters") or {}).get("footprint") or [1, 1, 1]
            cells = max(1, int(math.ceil(fp[0])) * int(math.ceil(fp[2]))) if isinstance(fp, list) and len(fp) >= 3 else 1
        rows.append({
            "name": name, "tier": tiers.get(name, "—"), "rank": rank, "base_m": b,
            "type": dna_types.get(posture, "specimen"), "posture": posture,
            "cells": cells, "prose": name in prose,
        })

    # rhythm: the scale sequence along the walk, scored like prosody
    ranks = [r["rank"] for r in rows]
    pairs = list(zip(ranks, ranks[1:]))
    contrast = sum(1 for a, b in pairs if abs(a - b) >= 1) / len(pairs) if pairs else 1.0
    clashes = [f"{rows[i]['name']} + {rows[i+1]['name']} (both {SCALE_NAMES[ranks[i]]})"
               for i, (a, b) in enumerate(pairs) if a == b and a >= 2]
    flats = []
    run = 1
    for i, (a, b) in enumerate(pairs):
        run = run + 1 if a == b else 1
        if run == 3:
            flats.append(f"{rows[i-1]['name']} → {rows[i+1]['name']} ({SCALE_NAMES[a]} ×3)")

    unwritten = [r["name"] for r in rows if not r["prose"]]
    orphans = sorted(prose - {r["name"] for r in rows})
    total_cells = sum(r["cells"] for r in rows)
    area = total_cells * 3          # clearance + path (the gaze law needs room)
    cols = max(7, int(math.ceil(math.sqrt(area / 1.5))))
    rowsn = int(math.ceil(area / cols))
    hero = max(rows, key=lambda r: (r["rank"], r["base_m"] or 0))
    benches = [r["name"] for r in rows if r["tier"] == "applied" or r["type"] in ("instrument", "performer")]
    tier_mix = {k: sum(1 for r in rows if r["tier"] == k) for k in ("small", "medium", "large", "applied", "—")}
    dig = t.get("dig") or {}

    L = [f"# Staging brief — {t.get('name', seq)}", ""]
    L += [f"> {t.get('truth', '')}", ""] if t.get("truth") else []
    L += [f"Roster: {len(rows)} walked · dig {dig.get('walked', '?')} of {dig.get('pearls', '?')}"
          + (" · hand-cut" if dig.get("curated") else " · formula-cut"),
          f"Ladder mix: {tier_mix['small']} small / {tier_mix['medium']} medium / {tier_mix['large']} large / "
          f"{tier_mix['applied']} applied" + (f" / {tier_mix['—']} unclassified" if tier_mix["—"] else ""), ""]
    L += ["| # | artifact | ladder | scale | base_m | staging | cells | prose |",
          "|---|----------|--------|-------|--------|---------|-------|-------|"]
    for i, r in enumerate(rows, 1):
        bm = f"{r['base_m']:.1f}" if r["base_m"] else "?"
        L.append(f"| {i} | {r['name']} | {r['tier']} | {SCALE_NAMES[r['rank']]} | {bm} "
                 f"| {r['type']} ({r['posture']}) | {r['cells']} | {'✓' if r['prose'] else '—'} |")
    L += ["", f"## Rhythm — contrast {contrast:.0%}",
          "Scale line: " + " ".join(SCALE_NAMES[r][0].upper() for r in ranks), ""]
    for c in clashes:
        L.append(f"- CLASH (two larges adjacent): {c}")
    for f_ in flats:
        L.append(f"- FLAT (3+ same scale): {f_}")
    if not clashes and not flats:
        L.append("- no clashes, no flats — the melody holds")
    L += ["", "## Alignment — no prose, no plinth"]
    L.append(f"- placed but unwritten ({len(unwritten)}): " + (", ".join(unwritten) or "none"))
    L.append(f"- written but unplaced ({len(orphans)}): " + (", ".join(orphans) or "none"))
    L += ["", f"## Grid — footprint determines it",
          f"- Σ footprint {total_cells} cells ×3 clearance ≈ {area} → suggest **{cols} × {rowsn}**", "",
          "## Floor plan — the 8-page grammar as phases",
          f"1. THRESHOLD — {hero['name']} visible on entry (hero; viewing distance scales with size)",
          f"2. PRIMITIVE — {rows[0]['name']}, close and small: the first encounter",
          f"3. THE WALK — encounter order enforced: " + " → ".join(r["name"] for r in rows[1:]),
          f"4. THE TURN — bench cluster: " + (", ".join(benches) or "(no applied-tier artifact — flag)"),
          "5. REFLECTION — text pocket: the chapter's critical page + ledger on a wall screen",
          f"6. SEED/EXIT — teleporter with a sightline toward {t['pages'][-1].get('next', '?')}"]
    # Declared blanks become reserved empty plinths — the museum's missing exhibit.
    for b in (t.get("blanks") if isinstance(t.get("blanks"), list) else []):
        L.append(f"7. EMPTY PLINTH — reserved: {b.get('note', '')[:120]}")
    L.append("")
    return "\n".join(L)


def main() -> int:
    targets = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not targets:
        print("usage: chapter_stage.py <seq> [<seq> ...]")
        return 1
    dna = load_json(DNA) or {"templates": {}}
    dna_types = {v.get("posture"): t for t, v in dna["templates"].items()}
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    os.makedirs(OUT_DIR, exist_ok=True)
    for seq in targets:
        b = brief(seq, dna_types, sizes)
        if not b:
            continue
        path = os.path.join(OUT_DIR, f"{seq}.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write(b)
        print(f"— {seq} -> {path}")
        print("\n".join(b.split("\n")[:6]))
        print()
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("stage", f"staging brief regenerated: {seq}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
