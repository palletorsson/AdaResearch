#!/usr/bin/env python3
"""Infer per-artifact NEEDS across the registry -> doc/artifact_needs.json.

`needs` = what an artifact needs to LIVE (life-support) + how it loads the structure:
    power, fluid, data, vent, waste : bool   (a source must be routed to it)
    load  : 0..2                             (2 = heavy -> needs a supported slab)
    hangs : bool                             (needs a ceiling)

Inferred from tags / category / lookup_name (+ footprint). Mirrors
commons/artifacts/_hangar/needs_model.gd so the generator (Python) and the runtime (GDScript)
agree on the same defaults.

The catalogue doc/artifact_needs.json is DERIVED + regenerable (like LOD_TREE / atlas), and is
what tools/kernel_map.py reads. `--apply` additionally folds `needs` into each artifact's
spatial_needs in the registries (indent-preserving; only where absent unless --force).

  python tools/infer_needs.py            # write doc/artifact_needs.json + print the distribution
  python tools/infer_needs.py --apply    # also bake spatial_needs.needs into the registries
"""
import argparse, json, sys, re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.plan_utils import ROOT, load_all_registries

REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
OUT = ROOT / "doc" / "artifact_needs.json"

# keyword sets — keep in lock-step with needs_model.gd
POWER = ["screen", "readout", "monitor", "display", "console", "light", "lamp", "panel",
         "terminal", "meter", "gauge", "scanner", "machine", "reactor", "server", "computer", "motor"]
DATA  = ["screen", "readout", "monitor", "display", "console", "data", "server", "computer",
         "terminal", "network", "scanner", "compute"]
FLUID = ["sink", "wash", "fluid", "water", "coolant", "pump", "tank", "drain", "hydro", "bath"]
HEAVY = ["machine", "reactor", "engine", "server", "cabinet", "furnace", "burner", "motor",
         "generator", "compressor", "fume", "autoclave", "press", "forge", "tank"]
HANGS = ["lamp", "light", "vent", "duct", "fan", "sign", "banner", "rail", "gantry"]

LIFE = ["power", "fluid", "data", "vent", "waste"]


def _has(s, kws):
    return any(k in s for k in kws)


def infer(tags, category, lookup, spatial_needs):
    n = {"power": False, "fluid": False, "data": False, "vent": False, "waste": False, "load": 0, "hangs": False}
    s = (" ".join(tags) + " " + str(category) + " " + str(lookup)).lower()
    if _has(s, POWER): n["power"] = True
    if _has(s, DATA): n["data"] = True
    if _has(s, FLUID): n["fluid"] = True; n["waste"] = True
    if _has(s, HEAVY): n["power"] = True; n["vent"] = True; n["load"] = 2
    if _has(s, HANGS): n["hangs"] = True
    try:
        fp = int(spatial_needs.get("footprint_cells", 1) or 1)
    except (TypeError, ValueError):
        fp = 1
    if fp >= 6: n["load"] = max(n["load"], 2)
    elif fp >= 3: n["load"] = max(n["load"], 1)
    ex = spatial_needs.get("needs")
    if isinstance(ex, dict):
        n.update(ex)
    return n


def detect_indent(text):
    """Return the file's indent unit ('\\t' or N spaces) so a re-dump matches the existing format."""
    for line in text.splitlines():
        m = re.match(r"^(\t+| +)\S", line)
        if m:
            lead = m.group(1)
            return "\t" if lead.startswith("\t") else lead
    return "\t"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="also bake spatial_needs.needs into the registries")
    ap.add_argument("--force", action="store_true", help="overwrite existing needs")
    a = ap.parse_args()

    reg = load_all_registries()
    cat = {}
    dist = {k: 0 for k in LIFE + ["hangs"]}
    load_dist = {0: 0, 1: 0, 2: 0}
    for lookup in sorted(reg.keys()):
        e = reg[lookup]
        sn = e.get("spatial_needs") if isinstance(e.get("spatial_needs"), dict) else {}
        tags = e.get("tags") if isinstance(e.get("tags"), list) else []
        n = infer(tags, e.get("category", ""), lookup, sn)
        cat[lookup] = n
        for k in dist:
            if n[k]:
                dist[k] += 1
        load_dist[int(n["load"])] += 1

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"_meta": {"count": len(cat), "life_support": dist, "load": load_dist},
                               "needs": cat}, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} for {len(cat)} artifacts")
    print("life-support:", dist)
    print("load (0/1/2):", load_dist)

    if a.apply:
        by_file = {}
        for lookup, e in reg.items():
            f = e.get("_registry_file")
            key = e.get("_registry_key", lookup)
            if f:
                by_file.setdefault(f, []).append((key, cat[lookup]))
        for f, items in sorted(by_file.items()):
            p = REGISTRY_DIR / f
            if not p.is_file():
                continue
            raw = p.read_text(encoding="utf-8")
            data = json.loads(raw)
            arts = data.get("artifacts", {})
            ch = 0
            for key, n in items:
                if key in arts and isinstance(arts[key], dict):
                    sn = arts[key].setdefault("spatial_needs", {})
                    if "needs" in sn and not a.force:
                        continue
                    sn["needs"] = n
                    ch += 1
            if ch:
                p.write_text(json.dumps(data, indent=detect_indent(raw), ensure_ascii=False) + "\n", encoding="utf-8")
                print(f"  +needs -> {f}: {ch}")


if __name__ == "__main__":
    main()
