# -*- coding: utf-8 -*-
"""world_ontology.py — THE LEDGER OF WHAT EXISTS.

Palle 2026-07-25, said twice: "what exist is both what we created but also
(queer) ontology of the world."

The composer had been treating its own declarations as the inventory of the
world. Three times in one day it built a mechanism the world already had — the
hangar wall family, the hb railing, the br/tc bridges — because it asked itself
what existed instead of asking the world. This tool asks the world:

  DECLARED   what the sources of truth say exists (utility registry, artifact
             registries, clusters, patterns, segments, postures)
  MODELLED   what the pathfinder can actually traverse (the engine's own
             admission of what is real)
  PRACTISED  what the corpus does with it (counts across ~1,990 maps — usage is
             a fact about the world, not about our intentions)
  COMPOSED   what the wizard engine references
  RESIDUAL   the queer part: what exists and resists being composed. NOT a
             to-do list. The ledger names it so it can be left alone
             deliberately rather than forgotten accidentally.

  python tools/world_ontology.py            # the ledger
  python tools/world_ontology.py --gap       # only what exists but is uncomposed
  python tools/world_ontology.py --write     # + commons/data/world_ontology.json
"""
import json, re, argparse, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parents[1]


def declared_utilities():
    """Utility codes from the registry that IS the truth source."""
    src = (ROOT / "commons/grid/UtilityRegistry.gd").read_text(encoding="utf-8", errors="ignore")
    out = {}
    for m in re.finditer(r'"([a-z0-9]{1,4})":\s*\{(.*?)\}', src, re.S):
        code, body = m.group(1), m.group(2)
        name = re.search(r'"name":\s*"([^"]*)"', body)
        cat = re.search(r'"category":\s*"([^"]*)"', body)
        out[code] = {"name": name.group(1) if name else "?",
                     "category": cat.group(1) if cat else "?"}
    return out


def modelled_connectors():
    """What the pathfinder can traverse — the engine's own ontology."""
    src = (ROOT / "tools/map_pathfinder.py").read_text(encoding="utf-8", errors="ignore")
    found = {}
    for code, marker in (("wp", "wp_cells"), ("tc", "tc_adj"), ("br", "br_cells"),
                         ("jp", "jp_edges")):
        if marker in src:
            found[code] = marker
    return found


def declared_artifacts():
    reg = ROOT / "commons/artifacts/registry"
    per_file, ready, total = {}, 0, {}
    for f in sorted(reg.glob("*.json")):
        if ".bak" in f.name:
            continue
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        names = [k for k in arts if isinstance(k, str) and not k.startswith("_")]
        per_file[f.stem] = len(names)
        for k in names:
            e = arts[k] if isinstance(arts[k], dict) else {}
            total.setdefault(k, f.stem)
            if e.get("map_ready"):
                ready += 1
    return per_file, total, ready


def practised(codes):
    """What the corpus actually does — usage counts across every map."""
    ucount = collections.Counter()
    acount = collections.Counter()
    maps = 0
    for p in (ROOT / "commons/maps").glob("*/map_data.json"):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        maps += 1
        L = d.get("layers") or {}
        for row in (L.get("utilities") or []):
            for tok in row:
                tok = str(tok).strip()
                if not tok:
                    continue
                base = tok.split(":")[0]
                if base in codes:
                    ucount[base] += 1
        for row in (L.get("interactables") or []):
            for tok in row:
                tok = str(tok).strip()
                if tok:
                    acount[tok.split(":")[0].split("#")[0]] += 1
    return ucount, acount, maps


def composed():
    """What the wizard engine references (its own declared vocabulary)."""
    src = (ROOT / "tools/wizard_compose.py").read_text(encoding="utf-8", errors="ignore")
    codes = set(re.findall(r'"(?:wp|tc|br|jp|hb|el|s|t|d|l|m)(?::[^"]*)?"', src))
    plain = {c.strip('"').split(":")[0] for c in codes}
    arts = set(re.findall(r'"((?:lab_|hangar_|cable_|ceiling_|exit_)[a-z_]+)', src))
    return plain, arts


def residual():
    """The queer part: what exists and resists the grammar."""
    out = {}
    idx = ROOT / "commons/data/grammar_fit_index.json"
    if idx.exists():
        d = json.loads(idx.read_text(encoding="utf-8"))
        rows = d.get("maps", [])
        if rows:
            res = [r["residual"] for r in rows]
            out["maps_fitted"] = len(rows)
            out["mean_residual"] = round(sum(res) / len(res), 3)
            out["high_residual_maps"] = sum(1 for r in res if r >= 0.7)
            out["note_high_residual"] = ("maps the grammar can barely express — hand-craft or "
                                         "noise; the tool cannot tell intention from accident, "
                                         "so these are protected, not queued")
    el = ROOT / "commons/data/artifact_elements.json"
    if el.exists():
        arts = json.loads(el.read_text(encoding="utf-8")).get("artifacts", {})
        out["measured_artifacts"] = len(arts)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gap", action="store_true", help="only what exists and is not composed")
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args()
    import sys
    sys.stdout.reconfigure(encoding="utf-8")

    util = declared_utilities()
    model = modelled_connectors()
    per_file, all_arts, ready = declared_artifacts()
    ucount, acount, nmaps = practised(set(util))
    comp_codes, comp_arts = composed()
    res = residual()

    rows = []
    for code, meta in sorted(util.items()):
        rows.append({
            "code": code, "name": meta["name"], "category": meta["category"],
            "modelled": code in model,
            "corpus_uses": ucount.get(code, 0),
            "composed": code in comp_codes,
        })
    gap = [r for r in rows if not r["composed"] and (r["corpus_uses"] > 0 or r["modelled"])]

    if not a.gap:
        print(f"WORLD ONTOLOGY LEDGER — {nmaps} maps, {len(all_arts)} registered artifacts "
              f"({ready} map_ready), {len(util)} utility codes\n")
        print(f"{'code':5s} {'name':22s} {'cat':10s} {'model':5s} {'corpus':>7s} {'composed'}")
        for r in rows:
            print(f"{r['code']:5s} {r['name'][:22]:22s} {r['category'][:10]:10s} "
                  f"{'yes' if r['modelled'] else '-':5s} {r['corpus_uses']:7d} "
                  f"{'YES' if r['composed'] else 'no'}")
        print()
    print("THE GAP — exists (modelled or practised) but the composer never writes it:")
    for r in gap:
        print(f"  {r['code']:4s} {r['name'][:26]:26s} corpus {r['corpus_uses']:5d}"
              f"{'  [pathfinder-modelled]' if r['modelled'] else ''}")
    if not gap:
        print("  (none — the composer speaks every code the world models or practises)")

    print("\nTHE RESIDUAL — what exists and resists the grammar (protected, not queued):")
    for k, v in res.items():
        print(f"  {k}: {v}")

    if a.write:
        out = {"_readme": __doc__.strip().split("\n\n")[0],
               "_intent": ("Palle 2026-07-25: 'what exist is both what we created but also (queer) "
                           "ontology of the world.' This ledger asks the world instead of asking "
                           "ourselves. The GAP is what exists and we do not compose; the RESIDUAL is "
                           "what exists and resists composition — it is not a backlog."),
               "maps_scanned": nmaps, "artifacts_registered": len(all_arts),
               "artifacts_map_ready": ready, "registries": per_file,
               "utilities": rows, "gap": gap, "residual": res,
               "composer_codes": sorted(comp_codes), "composer_artifacts": sorted(comp_arts),
               "top_artifacts_in_corpus": acount.most_common(15)}
        (ROOT / "commons/data/world_ontology.json").write_text(
            json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
        print("\nwrote commons/data/world_ontology.json")


if __name__ == "__main__":
    main()
