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
    # ── KIN families: interface-similar, SEPARATE scenes (harmonization
    # candidates). Three detectors: declared (principal_artifacts.json kin{}),
    # name stems (pattern_machine_a..d), suffix conventions (*_workbench,
    # *_machine). Only names not already in a scene family.
    import re
    all_names = {}
    for scene, insts in by_scene.items():
        for i in insts:
            all_names[i["name"]] = i
    in_family = set()
    for f in families:
        in_family.update(r["name"] for r in f["instances"])

    def kin_family(kname, members, basis, note=""):
        rows = []
        for n in sorted(members):
            i = all_names.get(n)
            if not i:
                continue
            s = sizes.get(n, {})
            src = s.get("source") or ("measured" if s.get("base_m") else "missing")
            cap = f"artifact-gallery/captures/{n}/front.png" \
                if (CAPS / n / "front.png").exists() else None
            rows.append({"name": n, "registry": i["registry"],
                         "cartridge": {"scene": Path(str(i["entry"]["scene"])).stem},
                         "size": {"cells": s.get("grid_cells"),
                                  "h": s.get("height_m"), "source": src},
                         "capture": cap})
        if len(rows) < 3:
            return None
        return {"scene": f"(kin — {len(rows)} separate scenes)", "stem": kname,
                "count": len(rows), "principal": None, "declaration": None,
                "basis": basis, "note": note,
                "base_genes": [], "cartridge_genes": ["scene"], "drift": [],
                "capture": next((r["capture"] for r in rows if r["capture"]), None),
                "instances": rows}

    kin_declared = json.loads(pfile.read_text(encoding="utf-8")).get("kin", {}) \
        if pfile.exists() else {}
    for kname, kd in kin_declared.items():
        kf = kin_family(kname, [m for m in kd.get("members", []) if m not in in_family],
                        "declared", kd.get("note", ""))
        if kf:
            families.append(kf)
            in_family.update(r["name"] for r in kf["instances"])
    # stem clusters: strip one trailing _<letter> or _<digits> segment
    stems = defaultdict(list)
    for n in all_names:
        if n in in_family:
            continue
        m = re.match(r"^(.*)_(?:[a-z]|\d+)$", n)
        if m and len(m.group(1)) >= 6:
            stems[m.group(1)].append(n)
    for stem, members in stems.items():
        kf = kin_family(stem + "_*", members, "stem",
                        "numbered/lettered variants — separate scenes")
        if kf:
            families.append(kf)
            in_family.update(r["name"] for r in kf["instances"])
    # suffix conventions: the interactive-machine benches
    for suffix in ("workbench", "machine"):
        members = [n for n in all_names
                   if n not in in_family and n.lower().endswith(suffix)]
        kf = kin_family(f"*_{suffix}", members, "suffix",
                        f"the {suffix} convention — one design pattern, "
                        f"{len(members)} implementations")
        if kf:
            families.append(kf)
            in_family.update(r["name"] for r in kf["instances"])

    for f in families:
        f.setdefault("basis", "scene")
    families.sort(key=lambda f: (-bool(f["principal"]), -f["count"]))

    # ── per-family DNA galleries (props-dna-gallery convention): flat slug
    # public/principal-dna-<family>/manifest.json, <=10 image-first entries,
    # GalleryView-compatible so Palle can verdict each instance.
    for f in families:
        slug = re.sub(r"[^a-z0-9\-_]", "", f["stem"].lower().replace("*", "")
                      .replace("__", "_").strip("_").replace("_", "-"))
        gal_dir = ENC / "public" / f"principal-dna-{slug}"
        fallback = f.get("capture")
        entries = []
        picked = sorted(f["instances"], key=lambda r: (r["capture"] is None, r["name"]))[:10]
        for r in picked:
            img = r["capture"] or fallback
            if not img:
                continue
            size = r["size"]
            fpr = (f"{size['cells'][0]:g}x{size['cells'][1]:g} · {size['h']}m"
                   if size.get("cells") else "no footprint")
            cart = " · ".join(f"{k}: {str(v)[:28]}" for k, v in
                              list(r.get("cartridge", {}).items())[:2])
            entries.append({"id": r["name"], "image": "/" + img,
                            "label": r["name"],
                            "subtitle": cart or f["stem"],
                            "notes": f"{fpr} ({size.get('source')})"
                                     + ("" if r["capture"] else " · family image"),
                            "prop": f["stem"]})
        if not entries:
            f["gallery"] = None
            continue
        gal_dir.mkdir(parents=True, exist_ok=True)
        (gal_dir / "manifest.json").write_text(json.dumps(
            {"description": f.get("note") or f"{f['stem']} — {f['count']} instances, "
             f"showing {len(entries)}", "entries": entries},
            indent=1, ensure_ascii=False), encoding="utf-8", newline="\n")
        f["gallery"] = f"principal-dna-{slug}"
        f["slug"] = slug
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
