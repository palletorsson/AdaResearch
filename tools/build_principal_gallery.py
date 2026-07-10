#!/usr/bin/env python3
"""build_principal_gallery.py — DNA galleries of all similar artifacts.

Palle: "is there a better way to start, like making dna galleries of all
similar artifacts?" — yes: SEE the family before ruling on the type. This
builds /principal-gallery: every shared-scene family (>=3 instances) laid
out as DNA — the BASE genes (config keys identical across all instances)
vs the CARTRIDGE genes (keys that vary: the actual axis of variation) —
plus each family's principal declaration (if any), footprint status
(principal-synced / measured / missing), and capture images where they
exist. The harmonization rulings (canonical footprint, interface contract,
merge candidates) get made looking at this, not typed blind.

Output: ada_encyclopedia/public/principal-gallery.json
"""
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = ROOT.parent / "ada_encyclopedia"
REG = ROOT / "commons" / "artifacts" / "registry"
CAPS = ENC / "public" / "artifact-gallery" / "captures"
OUT = ENC / "public" / "principal-gallery.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BOILERPLATE = {"name", "lookup_name", "scene", "description"}


def main() -> int:
    sizes = json.loads((ROOT / "commons/data/artifact_sizes.json")
                       .read_text(encoding="utf-8"))["sizes"]
    principals = {}
    pfile = ROOT / "commons/data/principal_artifacts.json"
    if pfile.exists():
        principals = json.loads(pfile.read_text(encoding="utf-8"))["principals"]
    by_scene_principal = {p["scene"]: (n, p) for n, p in principals.items()}

    by_scene = defaultdict(list)
    for rp in sorted(REG.glob("*.json")):
        try:
            d = json.loads(rp.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        for k, e in arts.items():
            if isinstance(e, dict) and e.get("scene"):
                by_scene[e["scene"]].append(
                    {"name": e.get("lookup_name", k), "registry": rp.name, "entry": e})

    families = []
    for scene, insts in by_scene.items():
        if len(insts) < 3:
            continue
        # DNA: keys shared-with-identical-value = base; varying = cartridge
        keysets = [set(i["entry"].keys()) - BOILERPLATE for i in insts]
        all_keys = set().union(*keysets)
        base_genes, cartridge = [], {}
        for key in sorted(all_keys):
            vals = [json.dumps(i["entry"].get(key), sort_keys=True, ensure_ascii=False)
                    for i in insts]
            if len(set(vals)) == 1 and all(key in ks for ks in keysets):
                base_genes.append(key)
            else:
                cartridge[key] = sum(1 for v in set(vals))
        pname, pdecl = by_scene_principal.get(scene, (None, None))
        stem = Path(scene).stem.replace("_substrate", "")
        rows = []
        for i in sorted(insts, key=lambda x: x["name"]):
            s = sizes.get(i["name"], {})
            src = s.get("source") or ("measured" if s.get("base_m") else "missing")
            cap = f"artifact-gallery/captures/{i['name']}/front.png" \
                if (CAPS / i["name"] / "front.png").exists() else None
            rows.append({"name": i["name"], "registry": i["registry"],
                         "cartridge": {k: i["entry"].get(k) for k in cartridge
                                       if k in i["entry"]},
                         "size": {"cells": s.get("grid_cells"),
                                  "h": s.get("height_m"), "source": src},
                         "capture": cap})
        fam_cap = next((r["capture"] for r in rows if r["capture"]), None)
        if not fam_cap and (CAPS / stem / "front.png").exists():
            fam_cap = f"artifact-gallery/captures/{stem}/front.png"
        # interface drift: cartridge keys not in the declared contract
        drift = []
        if pdecl:
            iface = set(pdecl.get("interface", []))
            drift = sorted(k for k in cartridge if k not in iface and
                           k not in ("category", "artifact_type", "sequence",
                                     "complexity", "include_in_map_data",
                                     "map_config", "tags"))
        families.append({
            "scene": scene.replace("res://", ""),
            "stem": stem,
            "count": len(insts),
            "principal": pname,
            "declaration": pdecl,
            "base_genes": base_genes,
            "cartridge_genes": sorted(cartridge),
            "drift": drift,
            "capture": fam_cap,
            "instances": rows,
        })
    families.sort(key=lambda f: (-bool(f["principal"]), -f["count"]))
    OUT.write_text(json.dumps(
        {"generated_by": "tools/build_principal_gallery.py",
         "families": families}, indent=1, ensure_ascii=False),
        encoding="utf-8", newline="\n")
    declared = sum(1 for f in families if f["principal"])
    print(f"principal-gallery.json: {len(families)} families "
          f"({declared} declared principals, "
          f"{sum(f['count'] for f in families)} instances) -> {OUT}")
    for f in families[:10]:
        mark = f["principal"] or "—"
        print(f"  {f['count']:3d}x {f['stem']:22s} principal={mark:16s} "
              f"cartridge={f['cartridge_genes'][:4]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
