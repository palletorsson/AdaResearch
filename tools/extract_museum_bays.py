#!/usr/bin/env python3
"""
extract_museum_bays.py — step 1 of the template/museum unification: factor the
museum tiles into BAYS (doc/plans/template_museum_unification.md).

WHY. tools/scan_museum_fragments.py measured every museum tile as 40-83%
internally repetitive — the Grande Galerie is 7 distinct rows across 36, the
Guggenheim 5 across 30. The tiles are UNROLLED LOOPS: the bays are already
there and the format lost them. This factors them back out, so a bay can be a
brush, a chapter can get as many bays as it has artifacts, and a bay run can
carry one artifact's DNA series.

WHAT A BAY IS. A maximal row-block that repeats CONSECUTIVELY, plus the
non-repeating stretches between such blocks (repeat 1). A museum becomes an
ordered list of {bay, repeat}. Bays are then deduplicated BY CONTENT across
all museums, which is where reuse between buildings becomes visible and
countable rather than asserted.

THE GATE. An extraction is only true if it round-trips: every museum
recomposed from its bay sequence must be BYTE-IDENTICAL to the tile shipped in
template_patterns.json. That check runs on every invocation and sets the exit
code, so this works as a gate; --self-test additionally corrupts a known-good
factoring four ways and requires the gate to catch all four (an instrument
nobody has watched fail has not been tested).

The shipped tiles stay the truth. This writes commons/data/museum_bays.json as
a parallel, provably-equivalent encoding — nothing downstream is switched over
by this tool.

Usage:
  python tools/extract_museum_bays.py            # extract + gate + write
  python tools/extract_museum_bays.py --dry-run  # extract + gate, write nothing
  python tools/extract_museum_bays.py --self-test
Exit code = number of museums whose recomposition does not round-trip.
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
OUT = REPO / "commons" / "data" / "museum_bays.json"
SLOTS = {"1s", "2s", "3s"}


def museums() -> dict:
    data = json.loads(PATTERNS.read_text(encoding="utf-8"))
    return {k: p for k, p in data.get("patterns", {}).items()
            if isinstance(p, dict) and p.get("museum")}


def factor(rows: list) -> list:
    """[(block, repeat), ...] — consecutive repeats found greedily, by coverage.

    Preferring the block that covers the MOST rows (ties to the shorter period)
    is what recovers a bay rather than a row: the Grande Galerie's aisle repeats
    as a 2-row unit twelve times, and a period-1 rule would report twelve
    single-row bays that no one could paint with.
    """
    segs: list = []
    i, n = 0, len(rows)
    while i < n:
        best = None
        for p in range(1, (n - i) // 2 + 1):
            k = 1
            while i + (k + 1) * p <= n and rows[i + k * p:i + (k + 1) * p] == rows[i:i + p]:
                k += 1
            if k >= 2:
                covered = p * k
                if best is None or covered > best[2] or (covered == best[2] and p < best[0]):
                    best = (p, k, covered)
        if best:
            p, k, _ = best
            segs.append((rows[i:i + p], k))
            i += p * k
            continue
        # no repeat starts here: run forward until one does, and keep that
        # stretch as a single bay (thresholds and end-stops are one-offs)
        j = i + 1
        while j < n:
            if any(rows[j:j + p] == rows[j + p:j + 2 * p]
                   for p in range(1, (n - j) // 2 + 1)):
                break
            j += 1
        segs.append((rows[i:j], 1))
        i = j
    return segs


MIN_MOTIF_H = 2


def split_nonconsecutive(segs: list) -> list:
    """Second pass: split one-off stretches on blocks that recur NON-adjacently.

    Step 1 only found consecutive repeats, and two buildings defeated it
    entirely — bilbao-atrium-radial and mezquita-hypostyle came out as a single
    30-row 'bay', which is not a brush, it is the tile again. Their rows DO
    repeat (13 and 11 distinct rows), just never adjacently: a radial plan
    alternates its motifs instead of running them. This finds the longest block
    that occurs twice or more inside a one-off stretch and splits there, so the
    motif becomes its own bay and the material between it stays honest.

    Only splits — never edits a row — so the round-trip gate holds by
    construction whatever this does.
    """
    out: list = []
    for block, k in segs:
        if k != 1 or len(block) < 2 * MIN_MOTIF_H:
            out.append((block, k))
            continue
        pieces = [block]
        changed = True
        while changed:
            changed = False
            nxt: list = []
            for piece in pieces:
                n = len(piece)
                found = None
                for h in range(n // 2, MIN_MOTIF_H - 1, -1):
                    for i in range(0, n - h + 1):
                        motif = piece[i:i + h]
                        j = i + h
                        while j <= n - h:
                            if piece[j:j + h] == motif:
                                found = (i, j, h)
                                break
                            j += 1
                        if found:
                            break
                    if found:
                        break
                if not found:
                    nxt.append(piece)
                    continue
                i, j, h = found
                for seg in (piece[:i], piece[i:i + h], piece[i + h:j],
                            piece[j:j + h], piece[j + h:]):
                    if seg:
                        nxt.append(seg)
                changed = True
            pieces = nxt
        out.extend((p, 1) for p in pieces)
    return out


def merge_runs(segs: list) -> list:
    """Re-fold adjacent identical blocks the splitter left as separate segments."""
    out: list = []
    for block, k in segs:
        if out and out[-1][0] == block:
            out[-1] = (block, out[-1][1] + k)
        else:
            out.append((block, k))
    return out


def recompose(segs: list) -> list:
    out: list = []
    for block, k in segs:
        for _ in range(k):
            out.extend(block)
    return out


def sig(block: list) -> str:
    return "/".join("|".join(str(c) for c in row) for row in block)


def describe(block: list) -> dict:
    flat = [str(c) for row in block for c in row]
    return {
        "h": len(block), "w": len(block[0]) if block else 0,
        "slots": sum(1 for c in flat if c in SLOTS),
        "hero": any(c == "3s" for c in flat),
        "walls": sum(1 for c in flat if c == "4"),
        "void": sum(1 for c in flat if c in ("", " ")),
    }


def extract(mus: dict) -> tuple[dict, list]:
    """(payload, failures) — failures are museums that do not round-trip."""
    by_sig: dict = {}
    order: list = []
    seq: dict = {}
    failures: list = []
    for key in sorted(mus):
        tile = [list(r) for r in mus[key]["tile"]]
        segs = merge_runs(split_nonconsecutive(factor(tile)))
        if recompose(segs) != tile:
            failures.append(key)
        chain = []
        for block, k in segs:
            s = sig(block)
            if s not in by_sig:
                by_sig[s] = {"owner": key, "index": len([b for b in order
                                                         if by_sig[b]["owner"] == key]),
                             "rows": block, "used_by": [], "instances": 0,
                             **describe(block)}
                order.append(s)
            b = by_sig[s]
            if key not in b["used_by"]:
                b["used_by"].append(key)
            b["instances"] += k
            chain.append({"sig": s, "repeat": k})
        seq[key] = chain
    names = {s: f'{by_sig[s]["owner"]}#b{by_sig[s]["index"]}' for s in order}
    bays = {}
    for s in order:
        b = dict(by_sig[s])
        b.pop("index", None)
        bays[names[s]] = b
    museums_out = {k: [{"bay": names[c["sig"]], "repeat": c["repeat"]} for c in chain]
                   for k, chain in seq.items()}
    shared = {n: b for n, b in bays.items() if len(b["used_by"]) > 1}
    payload = {
        "_readme": "Museum tiles factored into BAYS (step 1 of "
                   "doc/plans/template_museum_unification.md). A bay is a maximal "
                   "consecutively-repeating row block; museums are ordered "
                   "[{bay, repeat}]. Deduplicated by content across all museums. "
                   "Provenance: measured — every museum here recomposes "
                   "BYTE-IDENTICAL to its tile in template_patterns.json, which is "
                   "still the shipped truth. Regenerate with "
                   "tools/extract_museum_bays.py after any tile change.",
        "extracted": "2026-08-03",
        "museum_count": len(mus),
        "bay_count": len(bays),
        "shared_bay_count": len(shared),
        "bays": bays,
        "museums": museums_out,
    }
    return payload, failures


def usable(name: str, b: dict) -> bool:
    """Is this bay a BRUSH, or only a bookkeeping fragment?

    101 bays is a factoring; a palette is a vocabulary. A single row is real
    (the open-floor row is the most-shared unit in the corpus) but nobody can
    compose with it, and a bay with no slots and no reuse says nothing. So a
    brush must be at least two rows deep AND either hold a slot or already be
    shared between buildings.
    """
    return b["h"] >= 2 and (b["slots"] >= 1 or len(b["used_by"]) > 1)


def emit_brushes(payload: dict, mus: dict) -> int:
    """Merge usable bays into template_patterns.json as stamp patterns.

    A bay is already in the pattern format — cells, w, h — so the painter needs
    no new geometry code to stamp one: the vocabulary is what was missing, not
    the machinery. Bays carry their lineage (from_museum, shared_with,
    instances) so a chimera painted from two buildings can name both parents.
    Additive: entries are keyed `bay:<name>` and carry bay=true, so every
    consumer that filters on `museum` (the validator, the chain check, the
    endless museum's dealing arc) is untouched.
    """
    data = json.loads(PATTERNS.read_text(encoding="utf-8"))
    pats = data.setdefault("patterns", {})
    kept = 0
    for name, b in payload["bays"].items():
        if not usable(name, b):
            continue
        owner = b["owner"]
        src = mus.get(owner, {})
        building = str(src.get("museum", owner)).split(",")[0]
        others = [m for m in b["used_by"] if m != owner]
        bits = [f'{b["h"]}x{b["w"]}']
        if b["slots"]:
            bits.append(f'{b["slots"]} slot' + ("s" if b["slots"] != 1 else ""))
        if b["hero"]:
            bits.append("hero")
        if others:
            bits.append(f"shared x{len(b['used_by'])}")
        # ASCII separators only: a middle dot written here came back through the
        # JSON round-trip as mojibake in the palette. Same class as the PIL
        # em-dash fault — label text crosses too many encodings to be clever in.
        pats[f"bay:{name}"] = {
            "label": f'{building} bay - {" - ".join(bits)}',
            "color": src.get("color", "#5a5a66"),
            "w": b["w"], "h": b["h"], "mode": "stamp", "tile": b["rows"],
            "bay": True, "from_museum": owner, "building": building,
            "shared_with": others, "instances": b["instances"],
            "slots": b["slots"], "hero": b["hero"],
        }
        kept += 1
    PATTERNS.write_text(json.dumps(data, indent=1), encoding="utf-8")
    return kept


def selftest() -> int:
    """Corrupt a known-good factoring four ways; the round-trip gate must catch all."""
    import copy
    good = [["4"] * 5 for _ in range(3)] + [["1", "1", "1s", "1", "1"],
                                            ["1", "1", "1", "1", "1"]] * 4 + \
        [["1", "1", "3s", "1", "1"]]
    segs = factor(good)
    ok = recompose(segs) == good
    print(f"  {'PASS' if ok else 'FAIL'}  A known-good tile round-trips "
          f"({len(segs)} bays, {len(good)} rows)")
    results = [ok]
    for name, mut in [
        ("a cell edited in one bay", lambda s: s[0][0][0].__setitem__(0, "1")),
        ("a repeat count lowered", lambda s: s.__setitem__(1, (s[1][0], s[1][1] - 1))),
        ("a bay dropped", lambda s: s.pop(0)),
        ("two bays swapped", lambda s: (s.__setitem__(0, s[-1]), s.__setitem__(-1, s[0]))),
    ]:
        s = copy.deepcopy(segs)
        mut(s)
        caught = recompose(s) != good
        results.append(caught)
        print(f"  {'PASS' if caught else 'FAIL'}  gate catches: {name}")
    n = sum(1 for r in results if r)
    print(f"self-test: {n}/{len(results)} controls passed")
    return 0 if n == len(results) else 1


def main() -> int:
    if "--self-test" in sys.argv or "--selftest" in sys.argv:
        return selftest()
    mus = museums()
    payload, failures = extract(mus)
    bays, museums_out = payload["bays"], payload["museums"]
    print(f"{'museum':40} rows -> bays  (distinct)")
    print("-" * 72)
    total_rows = 0
    for k in sorted(museums_out):
        chain = museums_out[k]
        rows = sum(bays[c["bay"]]["h"] * c["repeat"] for c in chain)
        total_rows += rows
        print(f"{k:40} {rows:4} -> {len(chain):3} bays ({len({c['bay'] for c in chain}):2} distinct)")
    shared = {n: b for n, b in bays.items() if len(b["used_by"]) > 1}
    print("-" * 72)
    print(f"{len(mus)} museums · {total_rows} rows · {len(bays)} distinct bays "
          f"· {len(shared)} shared by 2+ buildings")
    if shared:
        print("\nbays already shared between buildings (the reuse, measured):")
        for n, b in sorted(shared.items(), key=lambda kv: -len(kv[1]["used_by"]))[:10]:
            print(f"  {n:44} {b['h']}x{b['w']} in {len(b['used_by'])} museums, "
                  f"{b['instances']} instances")
    heroes = sum(1 for b in bays.values() if b["hero"])
    print(f"\n{heroes} bays carry the hero slot · "
          f"{sum(b['slots'] for b in bays.values())} slots across all distinct bays")
    if failures:
        print(f"\nROUND-TRIP FAILED for {len(failures)}: {failures}")
        return len(failures)
    print(f"\nround-trip: {len(mus)}/{len(mus)} museums recompose BYTE-IDENTICAL")
    brushes = [n for n, b in bays.items() if usable(n, b)]
    print(f"{len(brushes)}/{len(bays)} bays qualify as brushes "
          f"(>=2 rows and either a slot or shared between buildings)")
    if "--dry-run" in sys.argv:
        print("(--dry-run: nothing written)")
        return 0
    OUT.write_text(json.dumps(payload, indent=1), encoding="utf-8")
    print(f"-> {OUT.relative_to(REPO)}")
    if "--brushes" in sys.argv:
        n = emit_brushes(payload, mus)
        print(f"-> {n} bay brushes merged into "
              f"{PATTERNS.relative_to(REPO)} (keys `bay:*`, additive)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
