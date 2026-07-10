#!/usr/bin/env python3
"""principal_artifacts.py — PRINCIPAL ARTIFACTS: one type, many instances.

Palle: "artifacts that have similar display interfaces... harmonize the
interfaces... ultimately sync down into the map's footprint knowledge."

A PRINCIPAL is a canonical artifact type: ONE scene + ONE harmonized
interface; its instances are registry entries that differ only by config
(the motif/cartridge move, made explicit and load-bearing). The principal
declares the artifact's DISPLAY footprint once — pose, cells, height — and
every instance inherits it, so the size oracle stops trusting per-instance
AABB measurements that catch a plane lying flat (grid2d measured h=0.02)
or nothing at all (grid3d: 9 instances unmeasured).

Declarations: commons/data/principal_artifacts.json
  principals.<name>: {scene, kind, interface[], display{grid_cells,height_m,
                      base_m, pose}, bed}

Commands:
  --audit            find ALL shared-scene families (candidates + drift)
  --sync-footprints  write each principal's display truth into
                     artifact_sizes.json for every instance
                     (source: "principal" — the type is the truth)
"""
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REG = ROOT / "commons" / "artifacts" / "registry"
SIZES = ROOT / "commons" / "data" / "artifact_sizes.json"
PRINCIPALS = ROOT / "commons" / "data" / "principal_artifacts.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def load_registry():
    """lookup_name -> {scene, registry_file, entry}"""
    out = {}
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
                name = e.get("lookup_name", k)
                out[name] = {"scene": e["scene"], "file": rp.name, "entry": e}
    return out


def audit():
    reg = load_registry()
    by_scene = defaultdict(list)
    for name, info in reg.items():
        by_scene[info["scene"]].append(name)
    fams = {s: ks for s, ks in by_scene.items() if len(ks) >= 3}
    sizes = json.loads(SIZES.read_text(encoding="utf-8"))["sizes"]
    declared = {}
    if PRINCIPALS.exists():
        declared = json.loads(PRINCIPALS.read_text(encoding="utf-8")).get("principals", {})
    declared_scenes = {p["scene"] for p in declared.values()}
    print(f"shared-scene families (>=3 instances): {len(fams)}\n")
    rows = sorted(fams.items(), key=lambda kv: -len(kv[1]))
    for scene, ks in rows:
        measured = sum(1 for k in ks if sizes.get(k, {}).get("base_m"))
        hs = sorted({round(sizes.get(k, {}).get("height_m", 0), 2)
                     for k in ks if sizes.get(k, {}).get("base_m")})
        mark = "PRINCIPAL" if scene in declared_scenes else "candidate"
        short = scene.replace("res://", "")
        print(f"  [{mark}] {len(ks):3d}x  {short}")
        print(f"        measured {measured}/{len(ks)}, heights seen: {hs[:6]}")
    return 0


def sync_footprints():
    if not PRINCIPALS.exists():
        print("no principal_artifacts.json yet — declare principals first")
        return 1
    decl = json.loads(PRINCIPALS.read_text(encoding="utf-8"))["principals"]
    reg = load_registry()
    doc = json.loads(SIZES.read_text(encoding="utf-8"))
    sizes = doc["sizes"]
    total = 0
    for pname, p in decl.items():
        disp = p.get("display", {})
        if not disp:
            continue
        instances = [n for n, i in reg.items() if i["scene"] == p["scene"]]
        for n in instances:
            # PRECEDENCE: an explicit per-instance registry footprint [w,h,d]
            # beats the type truth — the same scene can serve different poses
            # (Buren columns are 1x6 stripes; array_disco is a floor).
            fp = reg[n]["entry"].get("footprint")
            if isinstance(fp, list) and len(fp) == 3:
                w, h, dd = float(fp[0]), float(fp[1]), float(fp[2])
                sizes[n] = {"aabb_size": [w, h, dd], "base_m": max(w, dd),
                            "height_m": h, "max_dimension_m": max(w, h, dd),
                            "grid_cells": [w, dd],
                            "registry": reg[n]["file"].replace(".json", ""),
                            "principal": pname, "source": "registry"}
                total += 1
                continue
            gc = disp.get("grid_cells", [1, 1])
            sizes[n] = {
                "aabb_size": [float(disp.get("base_m", gc[0])),
                              float(disp.get("height_m", 1.0)),
                              float(disp.get("depth_m", gc[1]))],
                "base_m": float(disp.get("base_m", gc[0])),
                "height_m": float(disp.get("height_m", 1.0)),
                "max_dimension_m": max(float(disp.get("base_m", gc[0])),
                                       float(disp.get("height_m", 1.0))),
                "grid_cells": [float(gc[0]), float(gc[1])],
                "registry": reg[n]["file"].replace(".json", ""),
                "principal": pname,
                "source": "principal",
            }
            total += 1
        print(f"  {pname:14s} -> {len(instances)} instances inherit "
              f"{gc} cells x {disp.get('height_m')}m ({disp.get('pose','standing')})")
    # KIN families: interface-similar, separate scenes. Their members carry
    # their OWN measurements when they exist — kin truth only FILLS gaps
    # (sync: "fill"), it never overrides a real measurement.
    kin = json.loads(PRINCIPALS.read_text(encoding="utf-8")).get("kin", {})
    kin_total = 0
    for kname, k in kin.items():
        disp = k.get("display")
        if not disp and not k.get("prefer_registry"):
            continue
        filled = 0
        for n in k.get("members", []):
            if n not in reg:
                continue
            prev = sizes.get(n, {})
            keep_measured = prev.get("base_m") and prev.get("source") not in ("kin-fill", "registry")
            if keep_measured and not k.get("prefer_registry"):
                continue                     # real measurement — leave it alone
            # (own kin-fill entries are re-written so corrections propagate)
            fp = reg[n]["entry"].get("footprint")
            if isinstance(fp, list) and len(fp) == 3:
                w, h, dd = float(fp[0]), float(fp[1]), float(fp[2])
                sizes[n] = {"aabb_size": [w, h, dd], "base_m": max(w, dd),
                            "height_m": h, "max_dimension_m": max(w, h, dd),
                            "grid_cells": [w, dd],
                            "registry": reg[n]["file"].replace(".json", ""),
                            "principal": f"kin:{kname}", "source": "registry"}
                kin_total += 1
                continue
            if not disp:
                continue                     # registry-only kin, no fill truth
            gc = disp.get("grid_cells", [1, 1])
            sizes[n] = {
                "aabb_size": [float(disp.get("base_m", gc[0])),
                              float(disp.get("height_m", 1.0)),
                              float(disp.get("depth_m", gc[1]))],
                "base_m": float(disp.get("base_m", gc[0])),
                "height_m": float(disp.get("height_m", 1.0)),
                "max_dimension_m": max(float(disp.get("base_m", gc[0])),
                                       float(disp.get("height_m", 1.0))),
                "grid_cells": [float(gc[0]), float(gc[1])],
                "registry": reg[n]["file"].replace(".json", ""),
                "principal": f"kin:{kname}",
                "source": "kin-fill",
            }
            filled += 1
            kin_total += 1
        if filled:
            print(f"  kin:{kname:12s} -> filled {filled} missing members "
                  f"({disp.get('grid_cells')} x {disp.get('height_m')}m)")
    doc["_principal_sync"] = "tools/principal_artifacts.py --sync-footprints"
    with open(SIZES, "w", encoding="utf-8", newline="\n") as f:
        json.dump(doc, f, indent=1)
    print(f"synced {total} principal instances + {kin_total} kin fills -> {SIZES.name}")
    return 0


def verify():
    """diff registry spatial claims against the oracle for every principal
    and kin member; conflicts -> doc/reports/principal_verify.json"""
    decl = json.loads(PRINCIPALS.read_text(encoding="utf-8"))
    reg = load_registry()
    sizes = json.loads(SIZES.read_text(encoding="utf-8"))["sizes"]
    members = {}
    for pname, p in decl.get("principals", {}).items():
        for n, i in reg.items():
            if i["scene"] == p["scene"]:
                members[n] = pname
    for kname, k in decl.get("kin", {}).items():
        for n in k.get("members", []):
            members.setdefault(n, f"kin:{kname}")
    conflicts = []
    for n, owner in sorted(members.items()):
        e = reg.get(n, {}).get("entry", {})
        s = sizes.get(n, {})
        if not s.get("base_m"):
            continue
        oracle_cells = s.get("grid_cells", [1, 1])
        oracle_area = oracle_cells[0] * oracle_cells[1]
        oracle_h = s.get("height_m", 0)
        sn = e.get("spatial_needs") or {}
        fp_cells = sn.get("footprint_cells")
        if fp_cells and abs(fp_cells - oracle_area) >= 2:
            conflicts.append({"name": n, "owner": owner, "field": "footprint_cells",
                              "registry": fp_cells, "oracle": oracle_area})
        fp = e.get("footprint")
        if isinstance(fp, list) and len(fp) == 3:
            if abs(float(fp[1]) - oracle_h) > 0.8:
                conflicts.append({"name": n, "owner": owner, "field": "footprint[h]",
                                  "registry": fp[1], "oracle": oracle_h})
            if abs(float(fp[0]) * float(fp[2]) - oracle_area) >= 2:
                conflicts.append({"name": n, "owner": owner, "field": "footprint[area]",
                                  "registry": f"{fp[0]}x{fp[2]}", "oracle": oracle_area})
    out = ROOT / "doc" / "reports" / "principal_verify.json"
    out.write_text(json.dumps({"members_checked": len(members),
                               "conflicts": conflicts}, indent=1),
                   encoding="utf-8", newline="\n")
    print(f"verified {len(members)} members: {len(conflicts)} conflicts -> {out.name}")
    for c in conflicts[:15]:
        print(f"  {c['name']:34s} [{c['owner']}] {c['field']}: "
              f"registry={c['registry']} vs oracle={c['oracle']}")
    return 0


def main() -> int:
    if "--audit" in sys.argv:
        return audit()
    if "--sync-footprints" in sys.argv:
        return sync_footprints()
    if "--verify" in sys.argv:
        return verify()
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
