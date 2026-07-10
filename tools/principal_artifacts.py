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
  --discover         classify every registry artifact covered vs ORPHAN, then
                     cluster orphans by 4 independent signals (scene / script /
                     config-signature / name-token) to surface the next
                     principal-or-kin families -> doc/reports/principal_discovery.json
"""
import json
import re
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


BOILERPLATE_KEYS = {
    "name", "lookup_name", "scene", "description", "category", "artifact_type",
    "sequence", "complexity", "include_in_map_data", "map_sequences", "tags",
    "dev_themes", "dev_category",
}
NAME_TOKENS = {
    "machine", "workbench", "bench", "board", "screen", "display", "puzzle",
    "station", "assemblage", "assembly", "meter", "viewer", "lab", "studio",
    "generator", "simulator",
}
_SCRIPT_RE = re.compile(
    r'ext_resource\s+type="Script"[^\]]*?path="(res://[^"]+\.gd)"')


def _scene_path(scene_res):
    """res:// scene reference -> repo Path"""
    return ROOT / scene_res.replace("res://", "", 1)


def _first_script(scene_res, cache):
    """first ext_resource type=Script path in a .tscn, or None (cached)"""
    if scene_res in cache:
        return cache[scene_res]
    val = None
    p = _scene_path(scene_res)
    try:
        m = _SCRIPT_RE.search(p.read_text(encoding="utf-8", errors="replace"))
        if m:
            val = m.group(1)
    except (OSError, ValueError):
        val = None
    cache[scene_res] = val
    return val


def discover():
    reg = load_registry()
    decl = {}
    if PRINCIPALS.exists():
        decl = json.loads(PRINCIPALS.read_text(encoding="utf-8"))
    principal_scenes = {p["scene"] for p in decl.get("principals", {}).values()}
    kin_members = set()
    for k in decl.get("kin", {}).values():
        kin_members.update(k.get("members", []))
    overrides = set(k for k in decl.get("artifact_overrides", {}) if k != "_note")

    # ---- 1. COVERAGE ---------------------------------------------------
    orphans = {}
    covered = 0
    for name, info in reg.items():
        if (info["scene"] in principal_scenes
                or name in kin_members or name in overrides):
            covered += 1
        else:
            orphans[name] = info
    total = len(reg)
    print(f"coverage: {covered} covered / {len(orphans)} orphans / {total} total")

    sizes = json.loads(SIZES.read_text(encoding="utf-8")).get("sizes", {})

    # ---- 2. CLUSTER ORPHANS by independent signals ---------------------
    # groups: list of (signal, display_name, members frozenset)
    groups = []

    # a. shared scene (>=2)
    by_scene = defaultdict(list)
    for name, info in orphans.items():
        by_scene[info["scene"]].append(name)
    for scene, ks in by_scene.items():
        if len(ks) >= 2:
            stem = scene.replace("res://", "").rsplit("/", 1)[-1].replace(".tscn", "")
            groups.append(("scene", f"scene:{stem}", frozenset(ks)))

    # b. shared root SCRIPT across differing scenes (>=2)
    script_cache = {}
    by_script = defaultdict(set)
    scenes_by_script = defaultdict(set)
    for name, info in orphans.items():
        scr = _first_script(info["scene"], script_cache)
        if scr:
            by_script[scr].add(name)
            scenes_by_script[scr].add(info["scene"])
    for scr, ks in by_script.items():
        if len(ks) >= 2 and len(scenes_by_script[scr]) >= 2:
            stem = scr.replace("res://", "").rsplit("/", 1)[-1].replace(".gd", "")
            groups.append(("script", f"script:{stem}", frozenset(ks)))

    # c. config-signature — entry-key dialect shared by >=4
    by_sig = defaultdict(list)
    for name, info in orphans.items():
        sig = frozenset(info["entry"].keys()) - BOILERPLATE_KEYS
        if sig:
            by_sig[sig].append(name)
    for sig, ks in by_sig.items():
        if len(ks) >= 4:
            keys = sorted(sig)
            label = "+".join(keys[:3]) + ("+..." if len(keys) > 3 else "")
            groups.append(("config", f"config:{label}", frozenset(ks)))

    # d. name-token — final underscore token (>=3)
    by_token = defaultdict(list)
    for name in orphans:
        tok = name.rsplit("_", 1)[-1].lower()
        if tok in NAME_TOKENS:
            by_token[tok].append(name)
    for tok, ks in by_token.items():
        if len(ks) >= 3:
            groups.append(("token", f"token:{tok}", frozenset(ks)))

    # ---- merge groups sharing the SAME member set; union their signals -
    NAME_PRIORITY = {"script": 0, "token": 1, "config": 2, "scene": 3}
    merged = {}
    for signal, dname, members in groups:
        m = merged.setdefault(members, {"signals": set(), "names": []})
        m["signals"].add(signal)
        m["names"].append((NAME_PRIORITY[signal], dname))

    clusters = []
    for members, m in merged.items():
        signals = sorted(m["signals"])
        name = min(m["names"])[1]
        member_list = sorted(members)
        # suggested integration guess from measured oracle sizes
        heights = [sizes[n]["height_m"] for n in member_list
                   if n in sizes and sizes[n].get("height_m") is not None]
        bases = [sizes[n]["base_m"] for n in member_list
                 if n in sizes and sizes[n].get("base_m") is not None]
        avg_h = sum(heights) / len(heights) if heights else 0.0
        avg_b = sum(bases) / len(bases) if bases else 0.0
        if avg_h > 0.8 and avg_b >= 1.5:
            integ = "self"
        elif avg_b >= 6.0:
            integ = "field"
        else:
            integ = "review"
        score = len(member_list) * len(signals)
        clusters.append({
            "name": name,
            "signals": signals,
            "score": score,
            "members": member_list,
            "suggested_integration": integ,
        })
    clusters.sort(key=lambda c: (-c["score"], c["name"]))

    # ---- 3. print top 25 ----------------------------------------------
    print(f"\norphan clusters (top 25 of {len(clusters)}):")
    for c in clusters[:25]:
        sig = "+".join(c["signals"])
        print(f"  [{sig:20s}] {c['name']:34s} n={len(c['members']):3d} "
              f"score={c['score']:3d} -> {c['suggested_integration']}")
        print(f"        {', '.join(c['members'][:6])}")

    # ---- 4. write full report -----------------------------------------
    out = ROOT / "doc" / "reports" / "principal_discovery.json"
    payload = {
        "coverage": {"covered": covered, "orphans": len(orphans), "total": total},
        "clusters": [{"name": c["name"], "signals": c["signals"],
                      "members": c["members"],
                      "suggested_integration": c["suggested_integration"]}
                     for c in clusters],
    }
    out.write_text(json.dumps(payload, indent=1), encoding="utf-8", newline="\n")
    print(f"\nwrote {len(clusters)} clusters -> {out.name}")
    return 0


def suspect_double_stand():
    """housed declarations whose measured height suggests they bring their own
    stand (the coin_toss class) — never double-stand; review to 'self'."""
    sys.path.insert(0, str(ROOT / "tools"))
    import mission_graph as mg
    sizes = json.loads(SIZES.read_text(encoding="utf-8"))["sizes"]
    suspects = []
    for name, (integ, fam) in sorted(mg._integration().items()):
        if integ not in ("wrap", "cube", "plinth"):
            continue
        h = sizes.get(name, {}).get("height_m") or 0
        if h >= 0.9:
            suspects.append({"name": name, "integration": integ,
                             "family": fam, "height_m": h})
    out = ROOT / "doc" / "reports" / "double_stand_suspects.json"
    out.write_text(json.dumps({"rule": "artifacts that bring their own "
        "pedestal/stand are integration:self — never double-stand",
        "suspects": suspects}, indent=1), encoding="utf-8", newline="\n")
    print(f"{len(suspects)} double-stand suspects -> {out.name}")
    for s2 in suspects[:12]:
        print(f"  {s2['name']:36s} {s2['integration']}:{s2['family']} h={s2['height_m']}m")
    return 0


def advise():
    """the CONSIDERATE pass (Palle: 'these errors should not occur — we need
    a way to get more considerate in relation to the artifacts'): derive the
    integration each housed artifact's FORM asks for, from its measured shape,
    and diff against what is declared. Run BEFORE declaring; rerun after.
    Rules (aabb w,h,d from the oracle):
      base >= 6m                      -> field   (it IS the environment)
      thin plane (min dim <= 0.18*max, h >= 0.7) -> frame/table_display
      flat slab  (h < 0.35, base >= 1)-> frame/table_display (stand it up)
      tall (h >= 0.9)                 -> self    (brings its own stand;
                                          pedestal if elevation is wanted)
      small (all dims <= 0.45)        -> plinth/podium
      true volume (dims comparable)   -> cube family
    """
    sys.path.insert(0, str(ROOT / "tools"))
    import mission_graph as mg
    sizes = json.loads(SIZES.read_text(encoding="utf-8"))["sizes"]

    def form_advice(name):
        s2 = sizes.get(name, {})
        ab = s2.get("aabb_size")
        if not ab or not s2.get("base_m"):
            return "unmeasured", "?"
        w, h, dd = float(ab[0]), float(ab[1]), float(ab[2])
        base = max(w, dd)
        thin = min(w, dd)
        if base >= 6.0:
            return "field", f"{w:.1f}x{h:.1f}x{dd:.1f} room-scale"
        if h >= 0.7 and thin <= 0.18 * max(base, h):
            return "frame|table_display", f"{w:.1f}x{h:.1f}x{dd:.1f} vertical plane"
        if h < 0.35 and base >= 1.0:
            return "frame|table_display", f"{w:.1f}x{h:.1f}x{dd:.1f} flat slab (stand it up)"
        if h >= 0.9:
            return "self(+pedestal)", f"{w:.1f}x{h:.1f}x{dd:.1f} tall — own stand likely"
        if max(w, h, dd) <= 0.45:
            return "plinth|podium", f"{w:.1f}x{h:.1f}x{dd:.1f} small"
        return "cube", f"{w:.1f}x{h:.1f}x{dd:.1f} volume"

    conflicts, agreements = [], 0
    for name, (integ, fam) in sorted(mg._integration().items()):
        advice, why = form_advice(name)
        declared = integ if integ in ("self", "field") else (fam or integ)
        ok = (advice == "unmeasured"
              or declared in advice
              or (advice == "self(+pedestal)" and declared in ("self", "pedestal"))
              or (advice == "cube" and integ in ("cube",))
              or (advice == "plinth|podium" and declared in ("plinth", "podium"))
              or (advice == "frame|table_display" and (
                  "table_display" in str(declared) or declared == "frame")))
        if ok:
            agreements += 1
        else:
            conflicts.append({"name": name, "declared": f"{integ}:{fam}",
                              "form_advises": advice, "evidence": why})
    out = ROOT / "doc" / "reports" / "integration_advice.json"
    out.write_text(json.dumps({"agreements": agreements,
                               "conflicts": conflicts}, indent=1),
                   encoding="utf-8", newline="\n")
    print(f"advise: {agreements} agree, {len(conflicts)} conflicts -> {out.name}")
    for c in conflicts[:15]:
        print(f"  {c['name']:34s} declared {c['declared']:26s} "
              f"form: {c['form_advises']:20s} ({c['evidence']})")
    return 0




def metrics():
    """THE EM-SQUARE MERGE: measured testimony (doc/reports/
    artifact_metrics_measured.json) + declared metrics{} on principals
    (declared wins) -> commons/data/artifact_metrics.json, the runtime
    lookup the wrapper layout engine reads. Instances inherit their
    principal's metrics; overrides/kin reps carry their own."""
    sys.path.insert(0, str(ROOT / "tools"))
    import mission_graph as mg
    measured = json.loads((ROOT / "doc/reports/artifact_metrics_measured.json")
                          .read_text(encoding="utf-8")).get("metrics", {})
    decl = json.loads(PRINCIPALS.read_text(encoding="utf-8"))
    reg = load_registry()
    scene_to_principal = {p["scene"]: (n, p) for n, p in decl["principals"].items()}
    out = {}
    for name in mg._integration():
        pinfo = reg.get(name)
        m = None
        src = None
        if pinfo and pinfo["scene"] in scene_to_principal:
            pn, p = scene_to_principal[pinfo["scene"]]
            m = p.get("metrics") or measured.get(pn)
            src = "declared" if p.get("metrics") else "measured:" + pn
        if m is None:
            m = measured.get(name)
            src = "measured"
        if m is None or m.get("unmeasurable"):
            continue
        m = dict(m)
        size = m.get("size", [1, 1, 1])
        if max(size) > 8:
            m["unreliable_rest_aabb"] = True
        m["source"] = src
        out[name] = m
    dst = ROOT / "commons" / "data" / "artifact_metrics.json"
    dst.write_text(json.dumps({"_note": "the em-square: per-artifact base "
        "contract (anchor_y/size/pose/base). Declared metrics{} on principals "
        "beat measurement. Consumed by CubeWrapperLibrary.fit_artifact.",
        "metrics": out}, indent=1), encoding="utf-8", newline="\n")
    unreliable = [n for n, m in out.items() if m.get("unreliable_rest_aabb")]
    print(f"metrics: {len(out)} artifacts -> {dst.name}; "
          f"{len(unreliable)} unreliable rest AABBs: {unreliable[:5]}")
    return 0


def main() -> int:
    if "--audit" in sys.argv:
        return audit()
    if "--advise" in sys.argv:
        return advise()
    if "--metrics" in sys.argv:
        return metrics()
    if "--suspect-double-stand" in sys.argv:
        return suspect_double_stand()
    if "--discover" in sys.argv:
        return discover()
    if "--sync-footprints" in sys.argv:
        return sync_footprints()
    if "--verify" in sys.argv:
        return verify()
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
