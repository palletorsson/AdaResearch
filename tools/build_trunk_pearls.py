#!/usr/bin/env python3
"""The pearls — a trunk node is a STRING of heroes, not one hero.

Palle (2026-08-18): "What we want is a pearl of heroes like the point, line,
the trace, the grid, triangle, quad, pyramid, mesh, primitives. Then have
their siblings like for the line: laser, measure line, perspective line,
parallel lines, anti lines, dna lines and synthesis lines. This should be
reflected in the museum."

The trunk (build_trunk_branches.py) had one node per sequence with one hero,
and the museum poured a whole sequence into ONE building: primitives' 82
tokens became 28 interior bodies in first-come order, the pearls (the maps)
flattened away. But the sequence's MAPS already are the string — Point_One,
Point_Lines, Point_Trace, Point_Line_Grid, Point_Triangle_Context, ... — in
book order, each with a lead.

This seeds `pearls` under every trunk node from the sequence's maps:

    pearl   short name from the map name (Point_Lines -> "lines"), hand-renamable
    map     the map it came from
    hero    the map's dig hero (load-bearing, else promoted, else the map's
            first token in spine order); hero_by says which
    tokens  the map's tokens in spine order (siblings-to-be)

and RE-ANCHORS derived branches to a pearl when their `via` token (the node
token they grew from) belongs to a pearl's map — so `varies perspective_lines`
hangs off primitives/lines, not primitives-in-general. Hand branches and
hand pearl edits (rename, reorder, merge, hero) are kept verbatim on reseed,
under `hand_pearls`. Sequences with one map get one pearl = the node.

    python tools/build_trunk_pearls.py                 # seed / reseed pearls into trunk_branches.json
    python tools/build_trunk_pearls.py --node primitives --show   # print the string
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")   # blurbs carry π and em-dashes; cp1252 refuses them

REPO = Path(__file__).resolve().parent.parent
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
ORDER = REPO / "commons" / "data" / "spine_artifact_order.json"
POLICIES = REPO / "commons" / "data" / "artifact_order_policies.json"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS = REPO / "commons" / "maps"


def load(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def short_name(seq: str, map_name: str) -> str:
    """Point_Lines -> lines; Primitives_Melencolia -> melencolia; Point_One -> point."""
    n = map_name
    for pre in (seq.title(), seq.capitalize(), "Point_", "Primitives_", "Chamber_", seq.replace("_", " ").title().replace(" ", "_") + "_"):
        if n.lower().startswith(pre.lower()) and len(n) > len(pre):
            n = n[len(pre):]
            break
    n = re.sub(r"[_\-]+", " ", n).strip().lower()
    if n in ("one", "1"):
        n = "point"
    return n or map_name.lower()


def blurb_first(map_name: str) -> str:
    p = MAPS / map_name / "blurb.md"
    if not p.exists():
        return ""
    txt = p.read_text(encoding="utf-8", errors="replace").strip()
    return re.split(r"(?<=[.!?])\s", txt, 1)[0][:160]


def seed(trunk_doc: dict) -> dict:
    order = load(ORDER)["order"]
    dig = load(POLICIES)["policies"]["dig"]
    hand_pearls: dict = trunk_doc.get("hand_pearls", {})      # node -> [{map|pearl, ...}] hand edits
    hand_nodes: dict = trunk_doc.get("hand_nodes", {})        # node -> {speak, speak_by}: the CHAPTER's line (tools/em_speak.py)
    out_nodes = []
    for t in trunk_doc.get("trunk", []):
        node = t["node"]
        seq_file = SEQ_DIR / f"{node}.json"
        maps: list[str] = []
        if seq_file.exists():
            sj = load(seq_file)
            s = (sj.get("sequences") or {}).get(node) or sj
            maps = [str(m) if isinstance(m, str) else str(m.get("name", "")) for m in (s.get("maps") or [])]
        # tokens per map, spine order
        by_map: dict[str, list[str]] = {}
        for r in order:
            if r["sequence"] == node:
                by_map.setdefault(r["map"], []).append(r["lookup"])
        if not maps:
            maps = list(by_map.keys())
        for m in by_map:
            if m not in maps:
                maps.append(m)              # a map with tokens but not in the sequence list still counts
        pearls = []
        for i, m in enumerate(maps):
            toks = by_map.get(m, [])
            hero, hero_by = "", ""
            for why in ("load-bearing", "promoted from depth"):
                cand = [r["lookup"] for r in dig if r["sequence"] == node and r.get("map") == m and r["why"] == why]
                if cand:
                    hero, hero_by = cand[0], "dig:" + why
                    break
            if not hero and toks:
                hero, hero_by = toks[0], "first in spine order"
            pearls.append({"pearl": short_name(node, m), "map": m, "index": i, "hero": hero, "hero_by": hero_by,
                           "tokens": toks, "blurb": blurb_first(m)})
        # HAND EDITS on pearls — the ruling grammar of /pearls (all optional, by `map`,
        # or `new: true` for a pearl the maps never had):
        #   pearl        rename          hero        re-hero (hero_by "hand")
        #   drop         the pearl goes; its tokens are ORPHANS unless moved first
        #   order        position in the string
        #   tokens_add   tokens moved IN (from another pearl of this node)
        #   tokens_remove tokens moved OUT
        #   new + tokens a pearl made by hand: {"new": true, "pearl": "quad", "tokens": [...]}
        edits = hand_pearls.get(node, [])
        for e in edits:
            if e.get("new"):
                pearls.append({"pearl": str(e.get("pearl", "new")), "map": str(e.get("map", "")) or ("hand:" + str(e.get("pearl", "new"))),
                               "index": int(e.get("order", len(pearls))), "hero": str(e.get("hero", "")) or (list(e.get("tokens", [])) or [""])[0],
                               "hero_by": "hand" if e.get("hero") else "first in the pearl", "tokens": list(e.get("tokens", [])), "blurb": str(e.get("blurb", "")),
                               "hand": True})
        for e in edits:
            for p in pearls:
                if p["map"] == e.get("map") and not e.get("new"):
                    if e.get("pearl"):
                        p["pearl"] = e["pearl"]
                    if e.get("hero"):
                        p["hero"], p["hero_by"] = e["hero"], "hand"
                    if e.get("drop"):
                        p["dropped"] = True
                    if "order" in e:
                        p["index"] = int(e["order"])
                    if e.get("rooms") is not None:
                        p["rooms"] = int(e["rooms"])       # how much of the tile this pearl gets (tools/em_rooms.py)
                    # textD (tools/em_speak.py): the hand's line wins, a draft from the
                    # corpus fills the rest; provenance travels (speak_by / says_by)
                    if e.get("page2"):
                        p["page2"] = str(e["page2"])       # the hall's stanza when page 1 stands in the foyer
                    if e.get("join") is not None:
                        # SHARED HALL (Palle, 2026-08-19: "point and line, lines should share the
                        # first exhibition space"): this pearl is a PAGE of the pearl before it —
                        # its own node in the string and its own poem, but the negotiator deals
                        # it into the previous pearl's hall, after the previous pearl's lines
                        p["join"] = bool(e["join"])
                    if e.get("foyer"):
                        # THE POEM STARTS IN THE FOYER (Palle, 2026-08-19): these tokens are lines
                        # of the pearl but the lobby builder places them (window, well, wall) —
                        # they stay in the poem's order and leave the hall's cast
                        p["foyer"] = list(e["foyer"])
                        for tk in p["foyer"]:
                            if tk not in p["tokens"]:
                                p["tokens"].append(tk)
                    if e.get("verse"):
                        p["verse"] = dict(e["verse"])        # textD as POETRY: {token: {indent, gap}} — the white space (tools/em_speak.py)
                    if e.get("speak") or e.get("speak_draft"):
                        p["speak"] = str(e.get("speak") or e.get("speak_draft"))
                        p["speak_by"] = (e.get("speak_by") or "hand") if e.get("speak") else "draft"
                    if e.get("says") or e.get("says_draft"):
                        merged = dict(e.get("says_draft") or {})
                        by = {k: "draft" for k in merged}
                        hb = e.get("says_by") or {}
                        for k, v in (e.get("says") or {}).items():
                            merged[k] = v; by[k] = hb.get(k, "hand")
                        p["says"] = merged
                        p["says_by"] = by
                    if e.get("blurb"):
                        p["blurb"] = str(e["blurb"])
                    p["tokens"] = [t for t in p["tokens"] if t not in set(e.get("tokens_remove", []))]
                    if e.get("tokens_remove"):
                        # a body the hand took OUT stays out — also of the negotiator's cast,
                        # which would otherwise bring it back as a relative or a branch
                        p["excluded"] = sorted(set(p.get("excluded", [])) | set(e["tokens_remove"]))
                    # tokens_order: the hand's reading order of the bodies (/speak paragraph) —
                    # the order the walk meets them; unknown tokens keep their place after
                    if e.get("tokens_order"):
                        want = [t for t in e["tokens_order"] if t in p["tokens"] or t in (e.get("tokens_add") or [])]
                        rest = [t for t in p["tokens"] if t not in want]
                        p["tokens"] = want + rest
                        # READING ORDER (2026-08-19): a pearl the hand has ordered is a POEM —
                        # its tokens ARE its cast, in this order; the negotiator deals them
                        # down the hall in this order (z-monotone), nothing else enters
                        p["ordered"] = True
                    for tk in e.get("tokens_add", []):       # not `t`: that is the NODE record below
                        if tk not in p["tokens"]:
                            p["tokens"].append(tk)
        # a token moved IN somewhere is moved OUT of wherever else it sat
        moved: set[str] = set()
        for e in edits:
            moved.update(e.get("tokens_add", []))
            if e.get("new"):
                moved.update(e.get("tokens", []))
        for p in pearls:
            owner = next((e for e in edits if (e.get("new") and p["map"] == (str(e.get("map", "")) or "hand:" + str(e.get("pearl", "new"))) and True)
                          or (not e.get("new") and e.get("map") == p["map"] and e.get("tokens_add"))), None)
            keep = set(owner.get("tokens", []) if owner and owner.get("new") else (owner.get("tokens_add", []) if owner else []))
            p["tokens"] = [t for t in p["tokens"] if t not in moved or t in keep]
            if p["hero"] and p["hero"] not in p["tokens"] and p["tokens"] and p["hero_by"] != "hand":
                p["hero"], p["hero_by"] = p["tokens"][0], "first in spine order"
        pearls = sorted([p for p in pearls if not p.get("dropped")], key=lambda p: (p["index"], p["pearl"]))
        for i, p in enumerate(pearls):
            p["index"] = i
        t = dict(t)
        t["pearls"] = pearls
        if hand_nodes.get(node, {}).get("speak"):
            t["speak"] = str(hand_nodes[node]["speak"]); t["speak_by"] = str(hand_nodes[node].get("speak_by", "hand"))
        out_nodes.append(t)
    trunk_doc["trunk"] = out_nodes
    # re-anchor branches to pearls by their `via` token (derived) or hand-set `pearl`
    pearl_of: dict[tuple, str] = {}
    for t in out_nodes:
        for p in t["pearls"]:
            for tok in p["tokens"]:
                pearl_of.setdefault((t["node"], tok), p["pearl"])
    n_re = 0
    for b in trunk_doc.get("branches", []):
        if b.get("provenance") == "hand" and b.get("pearl"):
            continue
        via = b.get("via") or ""
        pe = pearl_of.get((b["anchor"], via)) or pearl_of.get((b["anchor"], b.get("token", "")))
        if pe:
            b["pearl"] = pe
            n_re += 1
    trunk_doc["counts"] = {**trunk_doc.get("counts", {}), "pearls": sum(len(t["pearls"]) for t in out_nodes), "branches_on_pearls": n_re}
    return trunk_doc


def show(doc: dict, node: str) -> None:
    t = next((x for x in doc["trunk"] if x["node"] == node), None)
    if not t:
        print("no such node"); return
    bs = [b for b in doc.get("branches", []) if b["anchor"] == node]
    print(f"== {node}: {len(t['pearls'])} pearls (from its maps), {len(bs)} branches ({sum(1 for b in bs if b.get('pearl'))} on a pearl)")
    for p in t["pearls"]:
        mine = [b for b in bs if b.get("pearl") == p["pearl"]]
        by_kind: dict[str, list[str]] = {}
        for b in mine:
            by_kind.setdefault(b["kind"], []).append(b["token"])
        print(f"\n  {p['index']+1:2d}. {p['pearl']:14s} <- {p['map']:26s} hero {p['hero'] or '?':28s} ({p['hero_by']})  {len(p['tokens'])} tokens")
        if p["blurb"]:
            print(f"      \"{p['blurb'][:110]}\"")
        print(f"      siblings: {', '.join(x for x in p['tokens'] if x != p['hero'])[:150]}")
        for k in ("extends", "varies", "edge", "contradicts", "queers", "synthesizes"):
            if by_kind.get(k):
                print(f"      {k:12s} {', '.join(by_kind[k][:8])}{' …' if len(by_kind[k]) > 8 else ''}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--node", default="")
    ap.add_argument("--show", action="store_true")
    ap.add_argument("--dry", action="store_true", help="do not write")
    a = ap.parse_args()
    doc = load(TRUNK)
    doc = seed(doc)
    if not a.dry:
        TRUNK.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"pearls: {doc['counts']['pearls']} across {len(doc['trunk'])} nodes · {doc['counts']['branches_on_pearls']} branches re-anchored to a pearl{'' if a.dry else ' -> ' + str(TRUNK.relative_to(REPO))}")
    if a.node:
        show(doc, a.node)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
