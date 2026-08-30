#!/usr/bin/env python3
"""THE PIPELINE, MEASURED — one JSON describing the whole text chain.

    python tools/pipeline_state.py            # human
    python tools/pipeline_state.py --json     # machine, for /pipeline
    python tools/pipeline_state.py --write    # + doc/reports/pipeline_state.json

2026-08-30, Palle: "make a url that visualize the pipeline."

WHAT IT DESCRIBES. Ada Research is, in Palle's words, "a tutorial gone strange":
each artifact explains one part of its own world, starting at the point and
ending somewhere in non-Euclidean space, irreducibility, QFEP. That arc is not a
mood — curriculum_spine.json declares it as seven phases in order, and the book
follows the spine. So the pipeline has a shape that can be drawn:

    the arc      24 chapters across 7 phases, F_order to synthesis
    the layers   four registers of text, of very different sizes
    the wants    what is unwritten, in both directions
    the gates    what can currently be shown to be wrong

THE LAYER SIZES ARE THE POINT, and they were a surprise when first measured:

    artifact headers   1539 KB   670 of 770 book works (87%)
    wall texts           50 KB   803 lines
    hall tutorials       190 of 213 halls, naming the work in 6% of cases

The per-artifact base layer is thirty times the poem and sits unassembled in the
.gd files. A page that draws the pipeline without that proportion draws a
different project.

EVERY NUMBER HERE IS RE-DERIVED, none is transcribed. The repo is edited while
this runs, so the file records `generated` and the page shows it.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from concord import (BOOK, spine_order, spine_meta, registry, placements,  # noqa: E402
                     book_lines, header_of)

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

MAPS = REPO / "commons" / "maps"


def gate(cmd: list) -> dict:
    """Run one gate and keep its JSON. A gate that cannot run reports that it
    could not, never a zero — a missing verdict and a clean verdict must not look
    the same, which is the whole lesson of the release-gate report that sat green
    for 81 days."""
    try:
        p = subprocess.run([sys.executable] + cmd, cwd=REPO, capture_output=True,
                           text=True, encoding="utf-8", errors="replace", timeout=300)
        return {"ok": True, "exit": p.returncode, "data": json.loads(p.stdout or "{}")}
    except Exception as e:
        return {"ok": False, "why": str(e)[:200]}


def main() -> int:
    ap = argparse.ArgumentParser(description="the whole text pipeline, measured")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--fast", action="store_true", help="skip the gates (they cost ~35s)")
    a = ap.parse_args()

    t0 = time.time()
    reg, place, bl = registry(), placements(), book_lines()
    meta = spine_meta()
    order = spine_order()

    # ── the arc: one row per chapter, in spine order ──
    arc = []
    tot = {"halls": 0, "works": 0, "said": 0, "noted": 0, "tut": 0, "head": 0}
    seen_head: dict = {}
    for ch in order:
        try:
            doc = json.loads((BOOK / (ch + ".json")).read_text(encoding="utf-8"))
        except Exception:
            continue
        pearls = [p for p in doc.get("pearls", []) if not p.get("drop")]
        works = said = noted = tut = head = 0
        for p in pearls:
            mp = str(p.get("map", ""))
            if (MAPS / mp / "tutorial.md").exists():
                tut += 1
            for l in p.get("lines", []):
                tk = str(l.get("token", "")).strip()
                if not tk:
                    continue
                works += 1
                if str(l.get("text", "")).strip():
                    said += 1
                if str(l.get("note", "")).strip():
                    noted += 1
                if tk not in seen_head:
                    seen_head[tk] = len(header_of(reg.get(tk, {}) or {}))
                if seen_head[tk] >= 120:
                    head += 1
        m = meta.get(ch, {})
        arc.append({"chapter": ch, "order": m.get("order"), "phase": m.get("phase", ""),
                    "qfep_role": m.get("qfep_role", ""), "halls": len(pearls),
                    "works": works, "said": said, "noted": noted,
                    "tutorials": tut, "with_header": head})
        tot["halls"] += len(pearls); tot["works"] += works; tot["said"] += said
        tot["noted"] += noted; tot["tut"] += tut; tot["head"] += head

    phases = []
    for ch in order:
        ph = meta.get(ch, {}).get("phase", "")
        if ph and ph not in phases:
            phases.append(ph)

    # ── the layers, by size, because the proportion is the finding ──
    head_chars = sum(seen_head.values())
    wall_chars = sum(len(str(l.get("text", ""))) for l in bl)
    note_chars = sum(len(str(l.get("note", ""))) for l in bl)
    crit_files = list(MAPS.glob("*/critical.md"))
    tut_files = list(MAPS.glob("*/tutorial.md"))

    def kb(paths) -> float:
        n = 0
        for p in paths:
            try:
                n += p.stat().st_size
            except Exception:
                pass
        return round(n / 1024, 1)

    layers = [
        {"id": "header", "label": "what each work explains", "where": "its own .gd header",
         "kb": round(head_chars / 1024, 1), "have": sum(1 for v in seen_head.values() if v >= 120),
         "of": len(seen_head), "base": True},
        {"id": "tutorial", "label": "what the room teaches", "where": "commons/maps/*/tutorial.md",
         "kb": kb(tut_files), "have": tot["tut"], "of": tot["halls"], "base": True},
        {"id": "critical", "label": "the critical registers", "where": "commons/maps/*/critical.md",
         "kb": kb(crit_files), "have": len(crit_files), "of": tot["halls"], "base": False},
        {"id": "wall", "label": "the sentence on the wall", "where": "commons/data/book/*.json",
         "kb": round(wall_chars / 1024, 1), "have": tot["said"], "of": tot["works"], "base": False},
        {"id": "note", "label": "the reflection", "where": "line.note in the book",
         "kb": round(note_chars / 1024, 1), "have": tot["noted"], "of": tot["works"], "base": False},
    ]

    booktok = {l["token"] for l in bl if l["token"]}
    out = {
        "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "took_s": None,
        "arc": arc, "phases": phases, "layers": layers,
        "book": {"chapters": len(arc), "halls": tot["halls"], "works": tot["works"],
                 "said": tot["said"], "noted": tot["noted"],
                 "approx_pages": max(1, round(tot["works"] / 4))},
        "corpus": {"registry": len(reg), "placed": len(place), "in_book": len(booktok)},
        "wants": {
            "work_no_words": len((set(place) & set(reg)) - booktok),
            "slot_no_words": sum(1 for l in bl if l["token"] and not l["text"].strip()),
            "line_no_work": len([t for t in booktok if t not in place]),
        },
        "surfaces": [
            {"path": "/studio", "does": "make the book, one chapter at a time", "writes": True},
            {"path": "/wall-texts", "does": "every sentence, and what each work explains", "writes": True},
            {"path": "/wall-map", "does": "one hall, and this work in the text", "writes": True},
            {"path": "/lines", "does": "the book as rows, order and locks", "writes": True},
            {"path": "/book", "does": "the six prose sections of a map", "writes": True},
            {"path": "/edges", "does": "the 269 edge sentences", "writes": True},
            {"path": "the museum", "does": "walk it, read the wall, write a reflection", "writes": True},
        ],
    }

    if not a.fast:
        g_edge = gate(["tools/edge_gate.py", "--json"])
        g_cite = gate(["tools/cite_gate.py", "--json"])
        g_want = gate(["tools/want_gate.py", "--json"])
        out["gates"] = [
            {"id": "edge", "name": "edge anchors", "tool": "tools/edge_gate.py",
             "asks": "does each edge sentence still stand on the words it was read from",
             **({"exit": g_edge["exit"], "tally": {k: g_edge["data"].get(k) for k in ("edges", "HELD", "NEAR", "LOST", "UNGROUNDED")}}
                if g_edge["ok"] else {"error": g_edge.get("why")})},
            {"id": "cite", "name": "artifact citations", "tool": "tools/cite_gate.py",
             "asks": "is the passage still where the book says it is",
             **({"exit": g_cite["exit"], "tally": g_cite["data"].get("totals", {})}
                if g_cite["ok"] else {"error": g_cite.get("why")})},
            {"id": "want", "name": "wants closed honestly", "tool": "tools/want_gate.py",
             "asks": "when a want closes, did it close honestly",
             **({"exit": g_want["exit"], "tally": g_want["data"].get("verdicts", {}),
                 "fails": g_want["data"].get("fails"), "distinct": g_want["data"].get("distinct_problems")}
                if g_want["ok"] else {"error": g_want.get("why")})},
        ]
    out["took_s"] = round(time.time() - t0, 1)

    if a.write:
        d = REPO / "doc" / "reports"
        d.mkdir(parents=True, exist_ok=True)
        p = d / "pipeline_state.json"
        tmp = Path(str(p) + ".tmp")
        tmp.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
        for _ in range(30):
            try:
                os.replace(tmp, p)
                break
            except OSError:
                time.sleep(0.3)
        print("wrote %s" % p, file=sys.stderr)

    if a.json:
        print(json.dumps(out, ensure_ascii=False, indent=1))
        return 0

    b = out["book"]
    print("THE PIPELINE, %s  (%.1fs)" % (out["generated"], out["took_s"]))
    print()
    print("  BOOK   %d chapters · %d halls · %d works · %d said · ~%d pages" %
          (b["chapters"], b["halls"], b["works"], b["said"], b["approx_pages"]))
    print("  ARC    %s" % " -> ".join(out["phases"]))
    print()
    print("  LAYERS OF TEXT")
    for l in out["layers"]:
        print("    %-26s %8.1f KB   %4d/%-4d  %s" %
              (l["label"], l["kb"], l["have"], l["of"], "BASE" if l["base"] else ""))
    print()
    print("  WANTS  %d works with no words · %d slots empty · %d lines with no work" %
          (out["wants"]["work_no_words"], out["wants"]["slot_no_words"], out["wants"]["line_no_work"]))
    for g in out.get("gates", []):
        print("  GATE   %-22s exit %s  %s" % (g["name"], g.get("exit", "?"),
                                              json.dumps(g.get("tally", g.get("error", "")))[:80]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
