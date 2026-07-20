#!/usr/bin/env python3
"""
build_dna_best.py — THE GENERAL DNA GALLERY: the 3 best expressions of every
DNA-researched artifact, one page.

Palle (2026-07-20): "I need the 3 best artifacts of each dna artifact in a
general gallery." Auto-discovers every encyclopedia gallery whose manifest
entries carry a `dna` field (the DNA-sweep signature), groups entries by
artifact, and picks each artifact's top 3:

  1. star evals first — public/<gallery>/evals.json (Palle's verdicts rule)
  2. curated defaults second (per-sweep picks, marked as such)
  3. manifest order last (props rows were authored as designed trios)

Writes public/dna-best/manifest.json in the /dna convention; the /dna-best
page (GalleryView) renders it with the same verdict chips, so rating THERE
also refines future rebuilds.

Usage: python tools/build_dna_best.py
"""
from __future__ import annotations
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PUB = REPO.parent / "ada_encyclopedia" / "public"
OUT = PUB / "dna-best"

# curated picks while a sweep has no stars yet (id endings, best-first)
CURATED = {
    "galton-dna": ["ball_rain", "rows_16_cathedral", "ember_finish"],
    "array-probe-dna": ["radial_9_signal", "linear_7_ember", "grid_16"],
}


def load_evals(slug: str) -> dict:
    p = PUB / slug / "evals.json"
    try:
        return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
    except Exception:
        return {}


def group_key(entry_id: str, slug: str, n_entries: int, ids: list[str]) -> str:
    # "__" convention (props galleries): artifact = the part before "__"
    if "__" in entry_id:
        return entry_id.split("__")[0]
    # sweep galleries (one artifact per gallery): the slug is the artifact
    return slug


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    best_entries: list[dict] = []
    galleries = 0
    artifacts = 0
    for mf in sorted(PUB.glob("*/manifest.json")):
        slug = mf.parent.name
        if slug == "dna-best":
            continue
        try:
            d = json.loads(mf.read_text(encoding="utf-8"))
        except Exception:
            continue
        entries = d.get("entries", [])
        if not (entries and isinstance(entries[0], dict) and "dna" in entries[0]):
            continue
        galleries += 1
        evals = load_evals(slug)
        ids = [str(e.get("id", "")) for e in entries]
        groups: dict[str, list[dict]] = {}
        for e in entries:
            groups.setdefault(group_key(str(e.get("id", "")), slug, len(entries), ids), []).append(e)

        curated = CURATED.get(slug, [])

        def rank(e: dict) -> tuple:
            eid = str(e.get("id", ""))
            stars = 0
            ev = evals.get(eid) or {}
            if isinstance(ev, dict):
                stars = int(ev.get("stars", 0) or 0)
            cur = next((len(curated) - i for i, c in enumerate(curated) if eid.endswith(c)), 0)
            return (-stars, -cur, entries.index(e))

        for gkey, members in sorted(groups.items()):
            artifacts += 1
            top = sorted(members, key=rank)[:3]
            for e in top:
                be = dict(e)
                be["id"] = f"{slug}::{e.get('id', '')}"
                be["gallery"] = slug
                be["artifact"] = gkey
                be["label"] = f"{gkey} — {e.get('label', e.get('id', ''))}"
                best_entries.append(be)

    manifest = {
        "version": 1,
        "description": "The general DNA gallery: the three best expressions of "
                       "every DNA-researched artifact, across all sweep galleries. "
                       "Ranking: Palle's star evals first (per source gallery), "
                       "curated picks second, authored order last. Rebuild: "
                       "python tools/build_dna_best.py",
        "entries": best_entries,
    }
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, indent=1, ensure_ascii=False) + "\n",
        encoding="utf-8", newline="\n")
    print(f"dna-best: {len(best_entries)} entries — {artifacts} artifacts from {galleries} galleries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
