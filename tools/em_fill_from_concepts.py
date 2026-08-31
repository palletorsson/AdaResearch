"""em_fill_from_concepts.py — put the good artifacts where they belong.

2026-08-29, Palle, walking sparse halls: "it seems like many good artifacts are
missing. see here all the possible artifacts /concept-galleries and this is not
all." Measured the same day: 200+ artifacts with real scenes on disk stand in NO
map of their own chapter, while 25 halls run under the density rule (<=4 bodies
AND <10% floor coverage).

This is the fill pass. The CONCEPT MAP is the placement brain:

  pool     per chapter = (concept-canon tokens + additions/hero seats + the
           chapter registry's own tokens) MINUS tokens already placed in the
           chapter's declared maps, MINUS corpus furniture (df > 20), kept only
           when the registry's scene file actually exists on disk
  affinity each canon token knows its CONCEPT; each declared map's existing
           tokens vote for the concepts it already speaks — a token goes to the
           map that most speaks its concept (ties -> the emptiest map)
  order    heroes/additions first, then applied > large > medium > small,
           recommended before not, rare before common
  target   Palle's rule made mechanical: fill a map until it has >=5 bodies AND
           >=10%% floor coverage; never past 11 bodies or 22%% coverage
  cells    floor "1" only; never the door columns (the walk), never within one
           cell of another body; wall-backed pieces line the walls; footprint
           side x side of clear floor required

  python tools/em_fill_from_concepts.py            dry — the full plan, no writes
  python tools/em_fill_from_concepts.py --apply    write the source maps

Skips git-dirty maps (another session's work). After --apply: pathfinder the
changed maps, re-derive the museum (tiles must not change — placement stays off
the carved walk), and re-run em_best_of: the hero pool just grew.
"""
from __future__ import annotations

import glob
import json
import math
import os
import pathlib
import random
import re
import subprocess
import sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[1]
ALIAS = {"forces": "vector_forces", "cellularautomata": "ca", "lsystems": "lsystem",
         "softbodies": "softbody", "proceduralgeneration": "procgen"}
SPINE = ["primitives", "transformation", "color", "change", "forces", "formfinding",
         "wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
         "lsystems", "proceduralgeneration", "softbodies", "isosurfaces",
         "boolean_surfaces", "swarmintelligence", "machinelearning", "graphtheory",
         "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]
TIER_RANK = {"hero": 0, "applied": 1, "large": 2, "medium": 3, "small": 4, "registry": 5}
FURNITURE_DF = 20
TARGET_ARTS, TARGET_COV = 5, 10.0
CAP_ARTS, CAP_COV = 11, 22.0


def load_registry_index():
    """token -> {scene, fp, wall_backing} from every registry file."""
    idx = {}
    for f in glob.glob(str(ROOT / "commons" / "artifacts" / "registry" / "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts") or {}
        items = list(arts.items()) if isinstance(arts, dict) else [
            (e.get("lookup_name", ""), e) for e in arts if isinstance(e, dict)]
        reg_name = os.path.basename(f)[:-5]
        for tok, e in items:
            if not tok or not isinstance(e, dict):
                continue
            sn = e.get("spatial_needs") or {}
            try:
                fp = max(1, int(sn.get("footprint_cells", 1))) if isinstance(sn, dict) else 1
            except Exception:
                fp = 1
            wb = bool(sn.get("wall_backing", False)) if isinstance(sn, dict) else False
            scene = str(e.get("scene", ""))
            for key in {tok, str(e.get("lookup_name", ""))}:
                if key and key not in idx:
                    idx[key] = {"scene": scene, "fp": fp, "wall": wb, "registry": reg_name}
    return idx


def scene_on_disk(entry) -> bool:
    scene = (entry or {}).get("scene", "")
    if not scene.startswith("res://"):
        return False
    return (ROOT / scene[6:]).exists()


def corpus_df():
    tok_maps = defaultdict(set)
    for p in glob.glob(str(ROOT / "commons" / "maps" / "*" / "map_data.json")):
        name = os.path.basename(os.path.dirname(p))
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for row in (d.get("layers") or {}).get("interactables") or []:
            for cell in row:
                c = str(cell).strip()
                if c and c != "0":
                    tok_maps[c.split("#")[0].split(":")[0]].add(name)
    return {t: len(ms) for t, ms in tok_maps.items()}


def concept_doc(ch):
    for name in (ch, ALIAS.get(ch, "")):
        p = ROOT / "doc" / f"{name}_concept_map.json"
        if name and p.exists():
            return json.load(open(p, encoding="utf-8"))
    return None


def additions(ch):
    p = ROOT / "doc" / f"{ch}_concept_additions.json"
    if p.exists():
        d = json.load(open(p, encoding="utf-8"))
        return {k: v for k, v in d.items() if not k.startswith("_")}
    return {}


def map_layers(name):
    p = ROOT / "commons" / "maps" / name / "map_data.json"
    if not p.exists():
        return None
    return json.load(open(p, encoding="utf-8"))


def placed_tokens(md):
    out = []
    for row in md["layers"].get("interactables") or []:
        for c in row:
            c = str(c).strip()
            if c and c != "0":
                out.append(c.split("#")[0].split(":")[0])
    return out


def fill_map(md, queue, reg, rng, ignore_caps=False):
    """Place queued tokens into floor cells. Mutates md. Returns placed list."""
    st = md["layers"]["structure"]
    H = len(st)
    W = len(st[0]) if H else 0
    inter = md["layers"].setdefault("interactables", [])
    while len(inter) < H:
        inter.append([""] * W)
    for r in range(H):
        row = list(inter[r]) if not isinstance(inter[r], list) else inter[r]
        while len(row) < W:
            row.append("")
        inter[r] = row

    floor = [[str(st[r][c]).strip() == "1" for c in range(W)] for r in range(H)]
    occupied = set()
    for r in range(H):
        for c in range(W):
            v = str(inter[r][c]).strip()
            if v and v != "0":
                occupied.add((r, c))
    door_cols = set(range((W - 3) // 2 - 1, (W - 3) // 2 + 4))

    def clear_block(r, c, side):
        for dr in range(side):
            for dc in range(side):
                rr, cc = r + dr, c + dc
                if not (0 <= rr < H and 0 <= cc < W) or not floor[rr][cc]:
                    return False
                for orr, occ in occupied:
                    if abs(orr - rr) <= 1 and abs(occ - cc) <= 1:
                        return False
        return True

    def wall_adjacent(r, c):
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < H and 0 <= cc < W and str(st[rr][cc]).strip() in ("w", "2", "3", "4", "5"):
                return True
        return False

    placed = []
    floor_count = sum(1 for r in range(H) for c in range(W) if floor[r][c])
    cover = sum(reg.get(t, {}).get("fp", 1) for t in placed_tokens(md))
    for tok in queue:
        n_arts = len(occupied)
        if not ignore_caps and (n_arts >= CAP_ARTS or 100.0 * cover / max(1, floor_count) >= CAP_COV):
            break
        fp = reg.get(tok, {}).get("fp", 1)
        side = max(1, math.ceil(math.sqrt(fp)))
        wants_wall = reg.get(tok, {}).get("wall", False) or side == 1
        cands = []
        for r in range(1, H - 1):
            for c in range(1, W - 1):
                if c in door_cols and side == 1:
                    continue
                if any((c + dc) in door_cols for dc in range(side)):
                    continue
                if not clear_block(r, c, side):
                    continue
                wa = wall_adjacent(r, c)
                cands.append((0 if (wa == wants_wall) else 1, rng.random(), r, c))
        if not cands:
            continue
        cands.sort()
        _p, _j, r, c = cands[0]
        inter[r][c] = tok
        for dr in range(side):
            for dc in range(side):
                occupied.add((r + dr, c + dc))
        cover += fp
        placed.append((tok, r, c))
    return placed


def placement_status(chapter: str) -> dict:
    """token -> [maps of this chapter that contain it], over the declared maps."""
    ma = json.load(open(ROOT / "commons" / "data" / "map_authored.json", encoding="utf-8"))
    out = defaultdict(list)
    for m in ma.get(chapter, []):
        md = map_layers(m)
        if md is None:
            continue
        for t in set(placed_tokens(md)):
            out[t].append(m)
    return dict(out)


def add_single(chapter: str, token: str) -> dict:
    """Place ONE token into the chapter map that most speaks its concept.
    The gallery's 'add to map' button. Ignores density caps - an explicit
    human add always tries. Writes the map. Returns a JSON-able verdict."""
    reg = load_registry_index()
    if not scene_on_disk(reg.get(token)):
        return {"ok": False, "error": "no scene on disk for '%s'" % token}
    status = placement_status(chapter)
    if token in status:
        return {"ok": True, "already": True, "maps": status[token]}
    ma = json.load(open(ROOT / "commons" / "data" / "map_authored.json", encoding="utf-8"))
    r = subprocess.run(["git", "status", "--porcelain", "--", "commons/maps/"],
                       capture_output=True, text=True, cwd=ROOT)
    dirty = {pathlib.Path(l[3:]).parts[-2] for l in r.stdout.splitlines() if l.strip()}
    doc = concept_doc(chapter)
    tok_concept = {}
    if doc:
        for cname, meta in (doc.get("concept_meta") or {}).items():
            for toks in (meta.get("tiers") or {}).values():
                for t in toks:
                    tok_concept.setdefault(str(t), cname)
    for t, cn in additions(chapter).items():
        tok_concept[t] = cn
    cn = tok_concept.get(token, "")
    best = None
    mds = {}
    for m in ma.get(chapter, []):
        md = map_layers(m)
        if md is None:
            continue
        mds[m] = md
        votes = Counter()
        for t in placed_tokens(md):
            c2 = tok_concept.get(t)
            if c2:
                votes[c2] += 1
        aff = votes.get(cn, 0) if cn else 0
        key = (0 if m not in dirty else 1, -aff, len(placed_tokens(md)), m)
        if best is None or key < best[0]:
            best = (key, m)
    if best is None:
        return {"ok": False, "error": "chapter '%s' has no declared maps" % chapter}
    m = best[1]
    if m in dirty:
        # every map dirty (mid-session): still allowed for an explicit add,
        # but say so - the human clicked, the human owns the tree
        pass
    md = mds[m]
    got = fill_map(md, [token], reg, random.Random(11), ignore_caps=True)
    if not got:
        return {"ok": False, "error": "no clear floor block in '%s' for footprint" % m}
    p = ROOT / "commons" / "maps" / m / "map_data.json"
    raw = p.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in raw else "\n"
    txt = json.dumps(md, indent=1, ensure_ascii=False)
    txt = re.sub(r"\[((?:\s+\"[^\]]*?)+)\s+\]",
                 lambda mm: "[ " + re.sub(r"\s+", " ", mm.group(1)).strip() + " ]", txt)
    p.write_text((txt + "\n").replace("\n", nl), encoding="utf-8", newline="")
    tok2, rr, cc = got[0]
    return {"ok": True, "map": m, "cell": [cc, rr], "concept": cn}


def main() -> int:
    apply = "--apply" in sys.argv
    only = None
    add_tok = None
    status_ch = None
    for a in sys.argv[1:]:
        if a.startswith("--chapter="):
            only = a.split("=", 1)[1]
        if a.startswith("--add-token="):
            add_tok = a.split("=", 1)[1]
        if a.startswith("--status="):
            status_ch = a.split("=", 1)[1]
    if status_ch:
        print(json.dumps({"ok": True, "placed": placement_status(status_ch)}, ensure_ascii=False))
        return 0
    if add_tok:
        print(json.dumps(add_single(only or "", add_tok), ensure_ascii=False))
        return 0
    reg = load_registry_index()
    df = corpus_df()
    ma = json.load(open(ROOT / "commons" / "data" / "map_authored.json", encoding="utf-8"))
    r = subprocess.run(["git", "status", "--porcelain", "--", "commons/maps/"],
                       capture_output=True, text=True, cwd=ROOT)
    dirty = {pathlib.Path(l[3:]).parts[-2] for l in r.stdout.splitlines() if l.strip()}

    rng = random.Random(7)
    grand = 0
    report = {}
    for ch in SPINE:
        if only and ch != only:
            continue
        maps = [m for m in ma.get(ch, []) if m not in dirty]
        mds = {}
        chapter_placed = set()
        for m in maps:
            md = map_layers(m)
            if md is None:
                continue
            mds[m] = md
            chapter_placed.update(placed_tokens(md))

        doc = concept_doc(ch)
        tok_concept = {}
        tok_tier = {}
        tok_rec = {}
        if doc:
            for cname, meta in (doc.get("concept_meta") or {}).items():
                for tier, toks in (meta.get("tiers") or {}).items():
                    for t in toks:
                        t = str(t)
                        tok_concept.setdefault(t, cname)
                        if TIER_RANK.get(tier, 9) < TIER_RANK.get(tok_tier.get(t, "registry"), 9):
                            tok_tier[t] = tier
            for cname, rows in (doc.get("groups") or {}).items():
                for row in rows:
                    if isinstance(row, dict) and row.get("lookup"):
                        tok_rec[str(row["lookup"])] = bool(row.get("recommended", False))
        for t, cname in additions(ch).items():
            tok_concept[t] = cname
            tok_tier[t] = "hero"
        for t, e in reg.items():
            if e.get("registry") == ch and t not in tok_tier:
                tok_tier.setdefault(t, "registry")
                tok_concept.setdefault(t, "")

        pool = []
        for t, tier in tok_tier.items():
            if t in chapter_placed or df.get(t, 0) > FURNITURE_DF:
                continue
            if not scene_on_disk(reg.get(t)):
                continue
            pool.append(t)
        pool.sort(key=lambda t: (TIER_RANK.get(tok_tier.get(t, "registry"), 9),
                                 0 if tok_rec.get(t, False) else 1, df.get(t, 0), t))

        # concept affinity: which map speaks which concept
        map_concepts = {}
        for m, md in mds.items():
            votes = Counter()
            for t in placed_tokens(md):
                cn = tok_concept.get(t)
                if cn:
                    votes[cn] += 1
            map_concepts[m] = votes

        queues = defaultdict(list)
        loads = {m: len(placed_tokens(md)) for m, md in mds.items()}
        for t in pool:
            cn = tok_concept.get(t, "")
            best = None
            for m in mds:
                aff = map_concepts[m].get(cn, 0) if cn else 0
                key = (-aff, loads[m], m)
                if best is None or key < best[0]:
                    best = (key, m)
            if best:
                queues[best[1]].append(t)
                loads[best[1]] += 1

        rows = []
        for m, md in mds.items():
            got = fill_map(md, queues.get(m, []), reg, rng)
            if got:
                rows.append((m, got))
                grand += len(got)
                if apply:
                    p = ROOT / "commons" / "maps" / m / "map_data.json"
                    raw = p.read_text(encoding="utf-8")
                    nl = "\r\n" if "\r\n" in raw else "\n"
                    s = json.dumps(md, indent=1, ensure_ascii=False)
                    s = re.sub(r"\[((?:\s+\"[^\]]*?)+)\s+\]",
                               lambda mm: "[ " + re.sub(r"\s+", " ", mm.group(1)).strip() + " ]", s)
                    p.write_text((s + "\n").replace("\n", nl), encoding="utf-8", newline="")
        if rows:
            print(f"\n== {ch} ==")
            for m, got in rows:
                names = ", ".join(t for t, _r, _c in got[:6]) + ("…" if len(got) > 6 else "")
                print(f"  {m:<46} +{len(got)}: {names}")
        report[ch] = {m: [t for t, _r, _c in got] for m, got in rows}

    out = ROOT / "doc" / "reports" / "em_fill_report.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"\n{'PLACED' if apply else 'would place'} {grand} artifacts · report -> doc/reports/em_fill_report.json")
    if not apply:
        print("(dry run — pass --apply to write)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
