#!/usr/bin/env python3
"""sequence_drafts.py — versioned rosters: the first call, made rulable.

Palle (2026-07-18): "I look, but cannot rule, because the first call is
unruled: what maps should be in the spine of each sequence. Some are clear
(primitives, noise, randomness); others (forces, softbodies) are not
curriculums. Two things keep a draft tight: think of the sequence as a
TUTORIAL that teaches the subject — then think of the ANTI and where it fits.
Maybe different versions: first just the learning tutorial, then adding the
anti and seams, then other laws ruling the order, so we can SEE how the
sequence processes under different laws."

This builds exactly those versions, on rule-zero's material and under
rule-zero's law (P-9/P-10: ruled > measured > register > ghost > heuristic —
heuristics PROPOSE, never bind; counter-pairs SLEEP in dig reports until
ruled, L-021):

  V1 TUTORIAL   the tight red thread: ONE map per slot of the 8-slot grammar
                (threshold primitive walk turn critical world close seed;
                walk may take two), selected from the current roster by
                provenance-ranked signals. 30 maps -> ~9. Gaps declared, not
                papered over.
  V2 +ANTI      V1 with the anti surfaced: the dig report's counter-pairs
                (sleeping) attached as GHOST insertions at the turn/critical
                slots — where the critical charge lives. Proposals only.
  V3 LAWS       the same V1 selection reordered under each cheap honest law
                on hand — slot grammar (identity), footprint ascending (the
                gaze law's cousin: small meets you first), cast density
                (sparse -> dense), truth-echo (heroes that echo the sequence
                truth arrive late = the walk EARNS the load-bearing) — with
                Kendall tau vs V1 so the drift under each law is a number.

Nothing binds. Every value carries provenance. Palle rules on
/sequence-drafts; adopted drafts become the sequence's first ruling.

  python tools/sequence_drafts.py --seq=forces
  python tools/sequence_drafts.py --seq=softbodies
  python tools/sequence_drafts.py --all
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RZ = ROOT.parent / "ada_encyclopedia" / "public" / "rule_zero.json"
DIGS = ROOT / "doc" / "book" / "dig_reports"
SIZES = ROOT / "commons" / "data" / "artifact_sizes.json"
OUT_DIR = ROOT / "doc" / "book" / "sequence_drafts"
OUT_ENC = ROOT.parent / "ada_encyclopedia" / "public" / "sequence_drafts.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SLOTS = ["threshold", "primitive", "walk", "walk2", "turn",
         "critical", "world", "close", "seed"]
# walk2 = the tutorial's second walk page; fed by the same "walk" slot pool


def _sizes():
    try:
        return json.loads(SIZES.read_text(encoding="utf-8"))["sizes"]
    except Exception:
        return {}


def _dig(seq: str) -> dict:
    """counter-pairs + roles from the dig report (they SLEEP there — L-021)."""
    p = DIGS / f"{seq}.md"
    out = {"load_bearing": [], "counter": [], "pairs": []}
    if not p.exists():
        return out
    t = p.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r"^\|\s*([a-zA-Z0-9_]+)\s*\|\s*\**([a-z\-?]+)\**\s*\|",
                         t, re.M):
        name, role = m.group(1), m.group(2)
        if role.startswith("load"):
            out["load_bearing"].append(name)
        elif role.startswith("counter"):
            out["counter"].append(name)
    for m in re.finditer(r"^- \*\*([a-zA-Z0-9_]+)\s+⟷\s+([a-zA-Z0-9_]+)\*\*\s+—\s+(.+)$",
                         t, re.M):
        out["pairs"].append({"a": m.group(1), "b": m.group(2),
                             "why": m.group(3).strip()[:90]})
    return out


def _seams() -> dict:
    """seq -> seam row from the seam catalog (the bias landscape — the OTHER
    anti: amber ideal vs blue counterfeit, one seam artifact per sequence)."""
    try:
        import build_seams_gallery as sg
        return {row[0]: {"seam": row[2], "artifact": row[6],
                         "crossing": row[5]}
                for row in sg.CATALOG if row[6]}
    except Exception:
        return {}


def _name_kin(seq: str, map_name: str) -> bool:
    """does the map's name belong to the sequence's own family?"""
    stem = re.sub(r"[^a-z]", "", seq.lower())[:6]
    flat = re.sub(r"[^a-z]", "", map_name.lower())
    return stem[:4] in flat


def _pick_score(row: dict, seq: str, dig: dict) -> tuple:
    """provenance-ranked: ruled > register > measured signals > heuristic."""
    hero = str(row.get("hero", "")).split(" ")[0]
    return (
        1 if "ruled" in str(row.get("slot_prov", "")) else 0,
        1 if row.get("in_register") else 0,
        1 if hero in dig["load_bearing"] else 0,
        1 if row.get("walked") else 0,
        1 if row.get("tutorial") else 0,
        1 if _name_kin(seq, row.get("map", "")) else 0,
        1 if row.get("dug") else 0,
        1 if row.get("exists") else 0,
        row.get("cast_n", 0),
    )


def _tau(order_a: list, order_b: list) -> float:
    """Kendall tau between two orderings of the same items."""
    pos = {m: i for i, m in enumerate(order_b)}
    items = [m for m in order_a if m in pos]
    n = len(items)
    if n < 2:
        return 1.0
    conc = disc = 0
    for i in range(n):
        for j in range(i + 1, n):
            d = pos[items[i]] - pos[items[j]]
            if d < 0:
                conc += 1
            elif d > 0:
                disc += 1
    tot = conc + disc
    return round((conc - disc) / tot, 2) if tot else 1.0


def build_seq(rz_seq: dict) -> dict:
    seq = rz_seq["id"]
    rows = rz_seq.get("rows", {})
    dig = _dig(seq)
    sizes = _sizes()

    # V1 — the tutorial thread: one map per slot, provenance-picked
    by_slot = {}
    for r in rows.values():
        by_slot.setdefault(str(r.get("slot", "")), []).append(r)
    n_rows = max((r.get("order", 0) for r in rows.values()), default=1)

    def _band(r: dict, slot: str) -> float:
        """position-band affinity: a ruled roster order is EVIDENCE — a map's
        current position should land near its slot's position in the arc."""
        si = SLOTS.index(slot) / (len(SLOTS) - 1)
        pos = (r.get("order", 1) - 1) / max(1, n_rows - 1)
        return -abs(pos - si)

    # THE CHAMBER CONVENTION (register-grade): Chamber_* is the catalyst
    # chamber — the sequence's closing seed by project law, never mid-thread.
    chamber = next((r for r in rows.values()
                    if str(r.get("map", "")).startswith("Chamber_")
                    and r.get("exists")), None)

    # slot-fill hints for slots rule-zero's position heuristic never assigned:
    # the ghost proposes from the UNUSED pool by name/cast signals (P-10)
    HINT = {
        "primitive": lambda r: (1 if re.search(
            r"(foundat|act1|_01_|intro|preview|what)", r["map"], re.I) else 0,
            -r.get("cast_n", 99)),
        "turn": lambda r: (1 if re.search(
            r"(chaos|invert|counter|reform|obstic|obstacle|press)", r["map"], re.I) else 0,
            r.get("cast_n", 0)),
        "critical": lambda r: (1 if str(r.get("hero", "")).split(" ")[0]
                               in dig["load_bearing"] else 0,
                               1 if r.get("walked") else 0),
        "world": lambda r: (1 if re.search(
            r"(arena|world|field|systems|applied)", r["map"], re.I) else 0,
            r.get("cast_n", 0)),
        # close: a synthesis/cross-sequence map exists but rule-zero's position
        # heuristic can collide two late maps onto one slot, dropping the 8th
        # body map and leaving close empty (the ML_Synthesis case, 2026-07-19).
        # Ghost-fill from the unused pool, name-hinted to synthesis-shaped maps;
        # the position band (already close-affine for a last map) does the rest.
        "close": lambda r: (1 if re.search(
            r"(synth|cross.?seq|assemblage|conclu|coda|finale|reflect|close|summary)",
            r["map"], re.I) else 0,
            1 if r.get("walked") else 0),
    }
    # HOLLOWNESS GUARD (2026-07-19, found by the softbodies fold): maps whose
    # hero is a wayfinding anchor (gallery_marker_*) are 12x12 empty floors
    # with a you-are-here stake — furniture, not rooms. Position must never
    # out-rank hollowness; exclude them from every slot pick.
    rows = {k: r for k, r in rows.items()
            if not str(r.get("hero", "")).startswith("gallery_marker")}
    by_slot = {}
    for r in rows.values():
        by_slot.setdefault(str(r.get("slot", "")), []).append(r)

    v1, used = [], set()
    if chamber is not None:
        used.add(chamber["map"])            # reserved for the seed slot
    for slot in SLOTS:
        if slot == "seed" and chamber is not None:
            hero = str(chamber.get("hero", "")).split(" ")[0]
            v1.append({"slot": "seed", "map": chamber["map"], "hero": hero,
                       "hero_prov": chamber.get("hero_prov"),
                       "slot_prov": "register (chamber convention)",
                       "lb": hero in dig["load_bearing"],
                       "walked": bool(chamber.get("walked")),
                       "cast_n": chamber.get("cast_n", 0),
                       "prov": "register — Chamber_* closes the sequence"})
            continue
        pool_slot = "walk" if slot == "walk2" else slot
        pool = [r for r in by_slot.get(pool_slot, [])
                if r.get("map") not in used and r.get("exists")]
        ghost_fill = False
        if not pool and slot in HINT:
            cand = [r for r in rows.values()
                    if r.get("map") not in used and r.get("exists")
                    and not str(r.get("map", "")).startswith("Chamber_")]
            # close is OPTIONAL: fill it only from a synthesis-SHAPED map (the
            # ML_Synthesis case), never pad it with an arbitrary late map — many
            # chapters legitimately end at world+seed and their close must gap.
            if slot == "close":
                cand = [r for r in cand if HINT["close"](r)[0] == 1]
            if cand:
                # position band FIRST (a ruled order is evidence), name hints second
                pool = sorted(cand, key=lambda r: (round(_band(r, slot), 2),
                                                   HINT[slot](r)),
                              reverse=True)[:1]
                ghost_fill = True
        if not pool:
            v1.append({"slot": slot, "map": None, "gap": True,
                       "prov": "declared gap — no existing map holds this slot"})
            continue
        pick = sorted(pool, key=lambda r: (_pick_score(r, seq, dig),
                                           _band(r, slot)),
                      reverse=True)[0]
        used.add(pick["map"])
        hero = str(pick.get("hero", "")).split(" ")[0]
        v1.append({"slot": slot, "map": pick["map"], "hero": hero,
                   "hero_prov": pick.get("hero_prov"),
                   "slot_prov": pick.get("slot_prov"),
                   "lb": hero in dig["load_bearing"],
                   "walked": bool(pick.get("walked")),
                   "cast_n": pick.get("cast_n", 0),
                   "prov": ("ghost (slot-fill from unused pool)" if ghost_fill
                            else "heuristic (provenance-ranked pick)")})

    picked = [e["map"] for e in v1 if e.get("map")]

    # V2 — the anti, surfaced (SLEEPING — proposals at turn/critical)
    anti = []
    for slot in ("turn", "critical"):
        host = next((e for e in v1 if e["slot"] == slot and e.get("map")), None)
        if not host:
            continue
        for p in dig["pairs"][:6]:
            if p["a"] == host.get("hero") or p["b"] == host.get("hero"):
                other = p["b"] if p["a"] == host.get("hero") else p["a"]
                anti.append({"slot": slot, "host_map": host["map"],
                             "anti": other, "why": p["why"],
                             "prov": "ghost — counter-pair sleeping in dig (L-021)"})
    if not anti and dig["pairs"]:
        host = next((e for e in v1 if e["slot"] in ("turn", "critical")
                     and e.get("map")), None)
        if host:
            p = dig["pairs"][0]
            anti.append({"slot": host["slot"], "host_map": host["map"],
                         "anti": f"{p['a']} ⟷ {p['b']}", "why": p["why"],
                         "prov": "ghost — top sleeping counter-pair (L-021)"})
    for a in anti:
        a["kind"] = "counter-pair"
    # the SEAM — the sequence's bias-landscape artifact (built, cataloged):
    # the crossing belongs where the critical charge lives
    seam = _seams().get(seq)
    if seam:
        host = next((e for e in v1 if e["slot"] == "critical"
                     and e.get("map")), None) or \
               next((e for e in v1 if e["slot"] == "world"
                     and e.get("map")), None)
        if host:
            anti.append({"kind": "seam", "slot": host["slot"],
                         "host_map": host["map"], "anti": seam["artifact"],
                         "why": f"{seam['seam']} — {seam['crossing']}",
                         "prov": "register (seam catalog) — placement ghost"})

    # V3 — the same selection under different laws
    def footprint(m):
        e = next((x for x in v1 if x.get("map") == m), {})
        s = sizes.get(str(e.get("hero", "")), {})
        return float(s.get("base_m", 1.0) or 1.0)

    def density(m):
        e = next((x for x in v1 if x.get("map") == m), {})
        return e.get("cast_n", 0)

    def truth_echo(m):
        e = next((x for x in v1 if x.get("map") == m), {})
        return 1 if e.get("lb") else 0

    laws = {
        "slot-grammar": {"order": picked,
                         "law": "the tutorial arc itself (V1 identity)"},
        "footprint-ascending": {
            "order": sorted(picked, key=footprint),
            "law": "small meets you first — the gaze law's cousin"},
        "density-rising": {
            "order": sorted(picked, key=density),
            "law": "sparse -> dense; the world thickens"},
        "truth-earned": {
            "order": sorted(picked, key=truth_echo),
            "law": "load-bearing heroes arrive late — the walk earns them"},
    }
    for name, l in laws.items():
        l["tau_vs_tutorial"] = _tau(l["order"], picked)

    return {"seq": seq, "phase": rz_seq.get("phase"),
            "truth": rz_seq.get("truth"),
            "current_n": rz_seq.get("n_maps"),
            "tight_n": len(picked),
            "v1_tutorial": v1,
            "v2_anti": anti,
            "v3_laws": laws,
            "dig_counter_pool": dig["counter"],
            "law_note": "P-9/P-10 + L-021: every value proposes; Palle rules"}


def main() -> int:
    if not RZ.exists():
        print("rule_zero.json missing — run tools/build_rule_zero.py first")
        return 1
    rz = json.loads(RZ.read_text(encoding="utf-8"))
    arg = lambda k: next((a.split("=", 1)[1] for a in sys.argv
                          if a.startswith(f"--{k}=")), None)
    want = arg("seq")
    do_all = "--all" in sys.argv
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    drafts = []
    for s in rz["sequences"]:
        if not do_all and want and s["id"] != want:
            continue
        if not do_all and not want and s["id"] not in ("forces", "softbodies"):
            continue
        d = build_seq(s)
        drafts.append(d)
        (OUT_DIR / f"{s['id']}.json").write_text(
            json.dumps(d, indent=1, ensure_ascii=False),
            encoding="utf-8", newline="\n")
        picked = [e for e in d["v1_tutorial"] if e.get("map")]
        gaps = [e["slot"] for e in d["v1_tutorial"] if e.get("gap")]
        print(f"{s['id']:22s} {d['current_n']:3d} maps -> tight {len(picked)}"
              f"  gaps: {','.join(gaps) if gaps else '-'}"
              f"  anti: {len(d['v2_anti'])} sleeping")
        for e in d["v1_tutorial"]:
            if e.get("map"):
                print(f"   {e['slot']:10s} {e['map']:34s} <{e.get('hero')}>"
                      f"{' LB' if e.get('lb') else ''}"
                      f"{' walked' if e.get('walked') else ''}")
    # combined file for the encyclopedia page
    combined = {"drafts": {d["seq"]: d for d in drafts}}
    if OUT_ENC.exists():
        try:
            prev = json.loads(OUT_ENC.read_text(encoding="utf-8"))
            prev.get("drafts", {}).update(combined["drafts"])
            combined = prev
        except json.JSONDecodeError:
            pass
    OUT_ENC.write_text(json.dumps(combined, indent=1, ensure_ascii=False),
                       encoding="utf-8", newline="\n")
    print(f"\n-> {OUT_ENC.name}: {len(combined.get('drafts', {}))} sequences")
    return 0


if __name__ == "__main__":
    sys.exit(main())
