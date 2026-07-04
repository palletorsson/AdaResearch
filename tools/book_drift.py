#!/usr/bin/env python3
"""book_drift.py — the field journal: what the world changes under the book.

The book is an excavation of a moving site: artifacts get added, removed,
captured, and re-truthed while the chapters stand still. This tool snapshots
the book's view of the world and diffs it against the previous snapshot,
appending dated entries to the field journal — the archive gains time.

Tracked per spine sequence (from the tutorial JSONs + three-orders):
  - walked artifacts (the excavated ring) appearing / disappearing
  - captures and @identity truth-claims appearing / disappearing per artifact
  - pearls at depth (the unexcavated stratum) growing / shrinking
  - rooms added / removed
Plus registry-wide artifact counts per registry file (the world level).

State:  doc/book/dig_snapshot.json   (machine, overwritten each run)
Output: doc/book/FIELD_JOURNAL.md    (append-only, human-readable)

Usage: python tools/book_drift.py          # diff against last snapshot, journal, re-snapshot
       python tools/book_drift.py --dry    # show the diff, change nothing
Run it after the tutorial rebuild step in the book pipeline.
"""
from __future__ import annotations

import datetime
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
THREE_ORDERS = os.path.join(ENC, "public", "three-orders.json")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
SNAP = os.path.join(REPO, "doc", "book", "dig_snapshot.json")
JOURNAL = os.path.join(REPO, "doc", "book", "FIELD_JOURNAL.md")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def take_snapshot() -> dict:
    frame = load_json(FRAME) or {"parts": []}
    to = load_json(THREE_ORDERS) or {}
    pearls_by_seq = {s["seq"]: sorted(s.get("pearls", [])) for s in to.get("sequences", [])}

    seqs = {}
    for part in frame.get("parts", []):
        for seq in part.get("sequences", []):
            t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
            arts, rooms = {}, []
            if t:
                for p in t.get("pages", []):
                    pool = []
                    if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
                        pool = [p["artifact"]]
                    elif p["kind"] == "walk":
                        pool = [a for a in p.get("artifacts") or [] if isinstance(a, dict)]
                    elif p["kind"] == "world":
                        rooms = [m.get("name", "") for m in p.get("maps") or []]
                    for a in pool:
                        arts[a.get("name", "?")] = {
                            "img": 1 if a.get("image") else 0,
                            "truth": 1 if a.get("truth") else 0,
                        }
            seqs[seq] = {
                "pearls": pearls_by_seq.get(seq, []),
                "walked": sorted(arts),
                "arts": arts,
                "rooms": rooms,
            }

    registry = {}
    if os.path.isdir(REG_DIR):
        for f in sorted(os.listdir(REG_DIR)):
            if not f.endswith(".json"):
                continue
            d = load_json(os.path.join(REG_DIR, f))
            if not isinstance(d, dict):
                continue
            a = d.get("artifacts") if isinstance(d.get("artifacts"), dict) else d
            registry[f] = sum(1 for v in a.values() if isinstance(v, dict))
    return {"sequences": seqs, "registry": registry}


def diff(old: dict, new: dict) -> list[str]:
    lines = []
    oreg, nreg = old.get("registry", {}), new.get("registry", {})
    for f in sorted(set(oreg) | set(nreg)):
        a, b = oreg.get(f, 0), nreg.get(f, 0)
        if a != b:
            lines.append(f"- registry/{f}: {a} → {b} artifacts ({b - a:+d})")
    oseq, nseq = old.get("sequences", {}), new.get("sequences", {})
    for seq in sorted(set(oseq) | set(nseq)):
        o, n = oseq.get(seq), nseq.get(seq)
        if o is None:
            lines.append(f"- **{seq}**: new stratum opened ({len(n['walked'])} walked)")
            continue
        if n is None:
            lines.append(f"- **{seq}**: stratum removed from the spine")
            continue
        sub = []
        ow, nw = set(o["walked"]), set(n["walked"])
        for x in sorted(nw - ow):
            sub.append(f"walked +{x}")
        for x in sorted(ow - nw):
            sub.append(f"walked −{x}")
        op, np_ = set(o.get("pearls", [])), set(n.get("pearls", []))
        for x in sorted(np_ - op):
            sub.append(f"pearl surfaced at depth: {x}")
        for x in sorted(op - np_):
            sub.append(f"pearl gone from depth: {x}")
        for name in sorted(ow & nw):
            oa, na = o["arts"].get(name, {}), n["arts"].get(name, {})
            if not oa.get("img") and na.get("img"):
                sub.append(f"capture appeared: {name}")
            if oa.get("img") and not na.get("img"):
                sub.append(f"capture lost: {name}")
            if not oa.get("truth") and na.get("truth"):
                sub.append(f"truth-claim appeared: {name}")
            if oa.get("truth") and not na.get("truth"):
                sub.append(f"truth-claim lost: {name}")
        orm, nrm = set(o.get("rooms", [])), set(n.get("rooms", []))
        for x in sorted(nrm - orm):
            sub.append(f"room +{x}")
        for x in sorted(orm - nrm):
            sub.append(f"room −{x}")
        if sub:
            lines.append(f"- **{seq}**: " + "; ".join(sub))
    return lines


def main() -> int:
    dry = "--dry" in sys.argv[1:]
    new = take_snapshot()
    old = load_json(SNAP)
    today = datetime.date.today().isoformat()

    n_walked = sum(len(s["walked"]) for s in new["sequences"].values())
    n_pearls = sum(len(s["pearls"]) for s in new["sequences"].values())
    n_reg = sum(new["registry"].values())

    if old is None:
        entry = [f"## {today} — baseline",
                 "",
                 f"Site surveyed: {len(new['sequences'])} strata, {n_walked} artifacts walked, "
                 f"{n_pearls} pearls known, {n_reg} artifacts in the registry. "
                 "The journal starts here; from now on, only what moves gets written.", ""]
    else:
        changes = diff(old, new)
        if not changes:
            print(f"no drift ({n_walked} walked / {n_pearls} pearls / {n_reg} registry) — journal untouched")
            if not dry:
                with open(SNAP, "w", encoding="utf-8") as f:
                    json.dump(new, f, indent=1)
            return 0
        entry = [f"## {today}", ""] + changes + [""]

    print("\n".join(entry))
    if dry:
        print("(dry run — nothing written)")
        return 0

    os.makedirs(os.path.dirname(JOURNAL), exist_ok=True)
    if not os.path.exists(JOURNAL):
        with open(JOURNAL, "w", encoding="utf-8") as f:
            f.write("# FIELD JOURNAL — drift of the site under the book\n\n"
                    "> Append-only. Machine-written by `tools/book_drift.py` after each tutorial\n"
                    "> rebuild. The dig line in each chapter reports the state; this journal\n"
                    "> keeps the history — what the world added, removed, captured, and\n"
                    "> re-truthed while the chapters stood still.\n\n")
    with open(JOURNAL, "a", encoding="utf-8") as f:
        f.write("\n".join(entry) + "\n")
    with open(SNAP, "w", encoding="utf-8") as f:
        json.dump(new, f, indent=1)
    print(f"journal -> {JOURNAL}")
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    body = [ln for ln in entry if ln.startswith("-")] or entry[2:3]
    log_event("drift", "; ".join(ln.lstrip("- ") for ln in body)[:300])
    return 0


if __name__ == "__main__":
    sys.exit(main())
