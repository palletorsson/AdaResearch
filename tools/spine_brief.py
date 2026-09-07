"""THE BRIEF — three lines per room, before anyone writes its final.md.

2026-09-07, Palle: "for the missing final.md I think we should do it by giving me
three lines of what you think the room is about ... and I will tell you if you are
right and what needs to be done differently", then: "can we make a URL for this,
for the whole spine, where I can also comment and you can update. we can make it
as how certain and if ruled."

The point is to spend Palle's attention at the cheapest place where he is still
the only one who knows the answer. Correcting a wrong premise costs him one line;
correcting 1450 words built on a wrong premise costs an afternoon and a rewrite.

A brief is four fields, deliberately different in KIND so that a wrong one is
visible. Three lines of description would all read as plausible and he could not
tell which to correct:

  for    the room's job in the sequence      — the thing only Palle knows
  core   artifacts | utilities | relation    — the thing that decides the FORM
  claim  the one thing the text will argue   — the thing that can be wrong
  unsure what I could not settle             — where to spend his attention

plus `certainty` (high|medium|low) and, computed rather than claimed, what I
actually had to go on: whether the room has intent.md, tutorial.md, critical.md.
That last is not decoration. Where those exist the brief is a READING Palle is
checking; where they do not it is a GUESS he is answering. Two different jobs, and
he should be able to see which one a row is asking of him. isosurfaces has 13
rooms missing final.md and ZERO intent.md; wavefunctions has 12 with all three.

`ruled` is computed too: a room whose primary order is a real decision in
artifact_roles.json order[], versus one running on the floor default. Writing text
against an order nobody decided is how the noise got in.

Palle answers in `comment`, and a comment is never overwritten by a rebuild — it
is the half of this file a machine does not own.

  python tools/spine_brief.py --json
  python tools/spine_brief.py --seq=forces
  python tools/spine_brief.py --set --map=VFM_08_Arena --for="..." --core=artifacts \
      --claim="..." --unsure="..." --certainty=medium
  python tools/spine_brief.py --comment --map=VFM_08_Arena --text="you have the exam backwards"
"""
from __future__ import annotations

import argparse
import io
import json
import os
import sys
import time
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
BRIEFS = ROOT / "commons" / "data" / "spine_briefs.json"
ORDER = ROOT / "commons" / "data" / "spine_artifact_order.json"
ROLES = ROOT / "commons" / "data" / "artifact_roles.json"
MAPS = ROOT / "commons" / "maps"
CORES = ("artifacts", "utilities", "relation", "")
CERTS = ("high", "medium", "low", "")


def _load(p: Path, default):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default


def _save(doc: dict) -> None:
    doc["_meta"] = {
        "written": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "writer": "tools/spine_brief.py",
        "note": ("A brief is written by Claude and answered by Palle. `comment` is "
                 "Palle's and is never overwritten by a rebuild."),
    }
    BRIEFS.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def spine_rooms() -> list[tuple[str, str]]:
    """(sequence, map) in spine order, from the one manifest that holds it."""
    out, seen = [], set()
    for e in (_load(ORDER, {}) or {}).get("order", []):
        k = (e.get("sequence", ""), e.get("map", ""))
        if k[1] and k not in seen:
            seen.add(k)
            out.append(k)
    return out


def survey() -> list[dict]:
    """Every spine room with its brief, what it has to go on, and whether it is ruled."""
    doc = _load(BRIEFS, {})
    briefs = doc.get("briefs", {})
    roles = _load(ROLES, {})
    order_of = roles.get("order", {}) or {}
    rows = []
    for seq, m in spine_rooms():
        d = MAPS / m
        b = briefs.get(m, {}) or {}
        ruled = [t for t in ((order_of.get(m) or {}).get("primary") or [])
                 if not str(t).startswith("#")]
        rows.append({
            "seq": seq, "map": m,
            "has_final": (d / "final.md").exists(),
            "has_intent": (d / "intent.md").exists(),
            "has_tutorial": (d / "tutorial.md").exists(),
            "has_critical": (d / "critical.md").exists(),
            # a real decision in order[], not the floor default the manifest falls back to
            "ruled": len(ruled) > 0,
            "n_ruled": len(ruled),
            "for": b.get("for", ""), "core": b.get("core", ""),
            "claim": b.get("claim", ""), "unsure": b.get("unsure", ""),
            "certainty": b.get("certainty", ""),
            "comment": b.get("comment", ""),
            "at": b.get("at", ""),
        })
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--seq", default="")
    ap.add_argument("--map", default="")
    ap.add_argument("--set", action="store_true")
    ap.add_argument("--comment", action="store_true")
    ap.add_argument("--for", dest="for_", default=None)
    ap.add_argument("--core", default=None, choices=list(CORES))
    ap.add_argument("--claim", default=None)
    ap.add_argument("--unsure", default=None)
    ap.add_argument("--certainty", default=None, choices=list(CERTS))
    ap.add_argument("--text", default=None, help="with --comment: Palle's answer")
    a = ap.parse_args()

    if a.set or a.comment:
        if not a.map:
            print(json.dumps({"ok": False, "why": "--map is required"}))
            return 1
        known = {m for _, m in spine_rooms()}
        if a.map not in known:
            print(json.dumps({"ok": False, "why": "%s is not a spine room" % a.map}))
            return 1
        doc = _load(BRIEFS, {})
        doc.setdefault("briefs", {})
        b = doc["briefs"].setdefault(a.map, {})
        if a.comment:
            # Palle's half. Never touched by a rebuild.
            b["comment"] = a.text or ""
            b["commented_at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
        else:
            for k, v in (("for", a.for_), ("core", a.core), ("claim", a.claim),
                         ("unsure", a.unsure), ("certainty", a.certainty)):
                if v is not None:
                    b[k] = v
            b["at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
        _save(doc)
        print(json.dumps({"ok": True, "map": a.map, "brief": b}, ensure_ascii=False))
        return 0

    rows = survey()
    if a.seq:
        rows = [r for r in rows if r["seq"] == a.seq]
    if a.map:
        rows = [r for r in rows if r["map"] == a.map]
    if a.json:
        print(json.dumps({"rooms": rows, "counts": {
            "rooms": len(rows),
            "missing_final": sum(1 for r in rows if not r["has_final"]),
            "briefed": sum(1 for r in rows if r["for"]),
            "answered": sum(1 for r in rows if r["comment"]),
            "ruled": sum(1 for r in rows if r["ruled"]),
        }}, ensure_ascii=False))
        return 0

    print("%-22s %-32s %-5s %-6s %-8s %-4s %s" % ("sequence", "room", "final", "ruled", "certain", "hint", "for"))
    print("-" * 128)
    for r in rows:
        had = "".join(c for c, k in (("i", "has_intent"), ("t", "has_tutorial"), ("c", "has_critical")) if r[k])
        print("%-22s %-32s %-5s %-6s %-8s %-4s %s" % (
            r["seq"], r["map"], "yes" if r["has_final"] else "NO",
            (str(r["n_ruled"]) if r["ruled"] else "—"), r["certainty"] or "—",
            had or "—", (r["for"] or "")[:52]))
    n = len(rows)
    print("\n%d rooms · %d missing final.md · %d briefed · %d answered by Palle · %d ruled" % (
        n, sum(1 for r in rows if not r["has_final"]), sum(1 for r in rows if r["for"]),
        sum(1 for r in rows if r["comment"]), sum(1 for r in rows if r["ruled"])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
