#!/usr/bin/env python
"""propose_next_gen.py — Read a gallery's evals.json and propose next-gen
configs from the next_gen_hints in each row.

Works across all three galleries (mesh-grammar, substrate, artifact)
because they share the same eval schema.

Heuristic interpretation of hints — pattern-matches on common phrasings
("Try with X", "Reduce X to Y", "Pair with Z", "Try at AxBxC"). Emits a
gen01_<id>.json proposal per hint per high-or-mid-scoring config. Low
scoring configs (1-2 stars) are skipped — their hints are "fix this
fundamentally" not "iterate from this".

Output: a proposed gen01 fragment that the human reviews before merging
into the seed library. We deliberately don't auto-merge — the propose
step is data, the merge step is judgment.

Usage:
  python tools/propose_next_gen.py --gallery substrate
  python tools/propose_next_gen.py --gallery mesh_grammar
  python tools/propose_next_gen.py --gallery artifact
  python tools/propose_next_gen.py --gallery substrate --out proposed.json
"""
from __future__ import annotations
import argparse
import copy
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"

GALLERIES = {
    "mesh_grammar": {
        "lib": REPO_ROOT / "commons" / "mesh_grammar" / "research_configs.json",
        "evals": ENCYCLOPEDIA_DIR / "public" / "mesh-grammar-gallery" / "evals.json",
    },
    "substrate": {
        "lib": REPO_ROOT / "commons" / "substrate_research" / "research_configs.json",
        "evals": ENCYCLOPEDIA_DIR / "public" / "substrate-gallery" / "evals.json",
    },
    "artifact": {
        "lib": REPO_ROOT / "commons" / "artifact_research" / "research_configs.json",
        "evals": ENCYCLOPEDIA_DIR / "public" / "artifact-gallery" / "evals.json",
    },
}


# --- hint interpreters ----------------------------------------------------

# Each interpreter takes (base_config, hint_text) and returns a list of new
# configs (or [] if the hint can't be auto-applied). Hints we can't parse
# are still surfaced — see _verbose_unparsed.

DIM_RE = re.compile(r"(\d+)\s*[xX×]\s*(\d+)\s*[xX×]\s*(\d+)")
NUMBER_RE = re.compile(r"\b(\d+(?:\.\d+)?)\b")


def _interpret_dim_change(base: dict, hint: str) -> list[dict]:
    m = DIM_RE.search(hint)
    if not m:
        return []
    new_dims = [int(m.group(1)), int(m.group(2)), int(m.group(3))]
    if "grid_dims" not in base:
        return []
    out = copy.deepcopy(base)
    out["id"] = _gen_next_id(base["id"], f"dims{new_dims[0]}x{new_dims[1]}x{new_dims[2]}")
    out["grid_dims"] = new_dims
    out["notes"] = f"From hint on {base['id']}: dims->{new_dims}"
    return [out]


def _interpret_visibility_swap(base: dict, hint: str) -> list[dict]:
    out: list[dict] = []
    swaps = ["rule_30", "sierpinski", "rings", "checkerboard", "menger_sponge",
             "sphere_shell", "bfs_frontier_t6"]
    for s in swaps:
        if s in hint and base.get("visibility") != s:
            v = copy.deepcopy(base)
            v["id"] = _gen_next_id(base["id"], f"vis_{s}")
            v["visibility"] = s
            v["notes"] = f"From hint on {base['id']}: visibility->{s}"
            out.append(v)
    return out


def _interpret_grammar_swap(base: dict, hint: str) -> list[dict]:
    out: list[dict] = []
    grammars = ["flower_grammar", "insect_grammar", "bird_grammar"]
    for g in grammars:
        if g in hint and base.get("part_grammar") != g:
            v = copy.deepcopy(base)
            v["id"] = _gen_next_id(base["id"], f"grammar_{g.replace('_grammar', '')}")
            v["enable_part"] = True
            v["part_grammar"] = g
            v["notes"] = f"From hint on {base['id']}: part_grammar->{g}"
            out.append(v)
    return out


def _interpret_glyph_change(base: dict, hint: str) -> list[dict]:
    out: list[dict] = []
    if "glyph_max_cells" in hint or ("max_cells" in hint and "glyph" in base.get("id", "")):
        m = NUMBER_RE.search(hint)
        if m:
            v = copy.deepcopy(base)
            v["id"] = _gen_next_id(base["id"], f"budget{int(float(m.group(1)))}")
            v["glyph_max_cells"] = int(float(m.group(1)))
            v["notes"] = f"From hint on {base['id']}: glyph_max_cells->{m.group(1)}"
            out.append(v)
    if "subdivide_by_pattern_edge" in hint and base.get("glyph_policy") != "subdivide_by_pattern_edge":
        v = copy.deepcopy(base)
        v["id"] = _gen_next_id(base["id"], "policy_edge")
        v["enable_glyph"] = True
        v["glyph_policy"] = "subdivide_by_pattern_edge"
        v["notes"] = f"From hint on {base['id']}: glyph_policy->subdivide_by_pattern_edge"
        out.append(v)
    return out


def _interpret_pair_with(base: dict, hint: str) -> list[dict]:
    """Hints like 'Pair with X' — combine two channels."""
    out: list[dict] = []
    if "pair with" not in hint.lower() and "paired with" not in hint.lower():
        return out
    out.extend(_interpret_grammar_swap(base, hint))
    out.extend(_interpret_visibility_swap(base, hint))
    out.extend(_interpret_glyph_change(base, hint))
    return out


INTERPRETERS = [
    _interpret_dim_change,
    _interpret_visibility_swap,
    _interpret_grammar_swap,
    _interpret_glyph_change,
    _interpret_pair_with,
]


def _gen_next_id(base_id: str, modifier: str) -> str:
    # base id like "gen00_flower_tabletop" -> "gen01_flower_tabletop_<modifier>"
    parts = base_id.split("_", 1)
    gen_part = parts[0]
    rest = parts[1] if len(parts) > 1 else "config"
    next_gen = "gen01"
    if gen_part.startswith("gen"):
        try:
            n = int(gen_part[3:])
            next_gen = f"gen{n+1:02d}"
        except ValueError:
            pass
    return f"{next_gen}_{rest}_{modifier}"


# --- main loop ------------------------------------------------------------

def propose_for_gallery(gallery_name: str, min_stars: int = 3) -> dict:
    paths = GALLERIES[gallery_name]
    if not paths["lib"].exists():
        return {"error": f"library not found: {paths['lib']}"}
    if not paths["evals"].exists():
        return {"error": f"evals not found: {paths['evals']} (score gen00 first)"}

    lib = json.loads(paths["lib"].read_text())
    evals = json.loads(paths["evals"].read_text())
    eval_rows: dict = evals.get("evals", {})

    base_by_id = {c["id"]: c for c in lib["configs"]}

    proposals: list[dict] = []
    unparsed_hints: list[dict] = []
    for cid, row in eval_rows.items():
        if cid not in base_by_id:
            continue
        stars = int(row.get("stars", 0))
        if stars < min_stars:
            # Low-scoring configs need fundamental redesign, not iteration.
            continue
        base = base_by_id[cid]
        hints = row.get("next_gen_hints", []) or []
        for hint in hints:
            applied = []
            for fn in INTERPRETERS:
                applied.extend(fn(base, hint))
            if applied:
                proposals.extend(applied)
            else:
                unparsed_hints.append({"config_id": cid, "hint": hint})

    # Deduplicate proposals by id
    seen: set = set()
    unique: list[dict] = []
    for p in proposals:
        if p["id"] not in seen:
            seen.add(p["id"])
            unique.append(p)

    return {
        "gallery": gallery_name,
        "source_lib": str(paths["lib"].relative_to(REPO_ROOT)),
        "source_evals": str(paths["evals"]),
        "evaluated_count": len(eval_rows),
        "proposals_count": len(unique),
        "proposals": unique,
        "unparsed_hints": unparsed_hints,
        "min_stars": min_stars,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gallery", choices=list(GALLERIES.keys()), required=True)
    parser.add_argument("--out", default=None,
                        help="Output JSON path. Default: stdout.")
    parser.add_argument("--min-stars", type=int, default=3,
                        help="Only iterate configs scoring >= this. Default 3.")
    args = parser.parse_args()

    result = propose_for_gallery(args.gallery, args.min_stars)
    text = json.dumps(result, indent=2)
    if args.out:
        Path(args.out).write_text(text)
        print(f"Wrote {args.out}: {result.get('proposals_count', 0)} proposals, "
              f"{len(result.get('unparsed_hints', []))} unparsed hints")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
