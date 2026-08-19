#!/usr/bin/env python3
"""textD — the SPEAK: a short line per pearl and per body, following the string.

    python tools/em_speak.py primitives                       # read the chapter's speak
    python tools/em_speak.py primitives point --speak "the one point"
    python tools/em_speak.py primitives point --say origin="(0,0,0), the root of all vectors, Vector.ZERO"
    python tools/em_speak.py --import speak.json              # {chapter: {pearl: {speak, says:{token: line}}}}

Palle, 2026-08-19: "let's think about textD as short speak, following the
pearls … the clock is already running, the folding past keeps running, the
frame counter, point zero; origin, (0,0,0), the root of all vectors,
Vector.ZERO, the one point; no points without a coordinate system …"

Stored WITH the pearl (trunk_branches.json hand_pearls -> pearls[].speak /
.says), so the 1D string and its textD are one record; the museum reads it
at build time and writes the body's line under its inventory number on the
standing plaque, and the pearl's line on a plaque at the segment's entry.
"""
from __future__ import annotations
import argparse, json, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def _edit_for(d: dict, node: str, pearl: str) -> dict:
    edits = d.setdefault("hand_pearls", {}).setdefault(node, [])
    seeded = next((t for t in d.get("trunk", []) if t.get("node") == node), {}) or {}
    pmap = next((q.get("map") for q in seeded.get("pearls", []) if q.get("pearl") == pearl), "")
    hit = next((e for e in edits if e.get("pearl") == pearl or (pmap and e.get("map") == pmap)), None)
    if hit is None:
        hit = {"map": pmap, "pearl": pearl}
        edits.append(hit)
    return hit


def set_speak(d: dict, node: str, pearl: str, speak: str | None, says: dict | None, by: str = "hand") -> None:
    """by: hand (Palle) | claude (written in his register from the orders) — travels to the walls as provenance."""
    e = _edit_for(d, node, pearl)
    if speak is not None:
        e["speak"] = speak
        e["speak_by"] = by
    if says:
        e.setdefault("says", {}).update(says)
        sb = e.setdefault("says_by", {})
        for k in says:
            sb[k] = by


def show(d: dict, node: str) -> None:
    seeded = next((t for t in d.get("trunk", []) if t.get("node") == node), {}) or {}
    for p in seeded.get("pearls", []):
        print(f"{p.get('pearl'):18s} [{p.get('speak_by', '-')}] {p.get('speak', '') or '—'}")
        by = p.get("says_by") or {}
        for tok, line in (p.get("says") or {}).items():
            print(f"    {tok:32s} [{by.get(tok, '-')}] {line}")


# ── the draft: the corpus speaks for itself, until Palle does ─────────────────
import re, subprocess
def _first_clause(text: str, limit: int) -> str:
    text = re.sub(r"\s+", " ", str(text or "")).strip().strip("`*_")
    if not text:
        return ""
    # cut at the first sentence end, else at a dash/semicolon, else hard
    m = re.search(r"^(.{12,%d}?[.!?])(\s|$)" % limit, text)
    cut = m.group(1) if m else text[:limit]
    if len(cut) >= limit and " " in cut:
        cut = cut[:cut.rfind(" ")]
    return cut.strip().rstrip(",;:—-").strip()


def draft(d: dict, node_filter: str = "") -> dict:
    """Fill speak_draft / says_draft on hand_pearls from: the map's blurb (the
    pearl line), each body's @identity truth (else registry description). Hand
    lines are never touched. Returns counts."""
    truths: dict = {}
    try:
        out = subprocess.run([sys.executable, str(REPO / "tools" / "query_identities.py"), "truths"], capture_output=True, text=True, encoding="utf-8", errors="replace").stdout
        for line in out.splitlines():
            m = re.match(r"^\s+([A-Za-z0-9_]+):\s+(.*)$", line)
            if m:
                truths[m.group(1)] = m.group(2).strip()
    except Exception:
        pass
    desc: dict = {}
    for f in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            doc = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        def walk(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    if isinstance(v, dict) and ("scene" in v or "lookup_name" in v):
                        if v.get("description") and k not in desc:
                            desc[k] = str(v["description"])
                    else:
                        walk(v)
        walk(doc)
    n_pearls = n_says = 0
    for t in d.get("trunk", []):
        node = t.get("node")
        if node_filter and node != node_filter:
            continue
        for q in t.get("pearls", []):
            pearl, mp = q.get("pearl", ""), q.get("map", "")
            e = _edit_for(d, node, pearl)
            blurb = REPO / "commons" / "maps" / mp / "blurb.md"
            if blurb.exists():
                line = _first_clause(blurb.read_text(encoding="utf-8", errors="replace"), 140)
                if line:
                    e["speak_draft"] = line; n_pearls += 1
            sd = e.setdefault("says_draft", {})
            for tok in q.get("tokens", []):
                src = truths.get(tok) or desc.get(tok) or ""
                line = _first_clause(src, 110)
                if line:
                    sd[tok] = line; n_says += 1
    return {"pearls": n_pearls, "says": n_says}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("node", nargs="?")
    ap.add_argument("pearl", nargs="?")
    ap.add_argument("--speak")
    ap.add_argument("--say", action="append", default=[], metavar="TOKEN=LINE")
    ap.add_argument("--import", dest="imp")
    ap.add_argument("--draft", nargs="?", const="", default=None, metavar="NODE", help="draft every pearl/body line from the corpus (truths, blurbs, descriptions); stamped draft")
    ap.add_argument("--no-reseed", action="store_true")
    ap.add_argument("--by", default="hand", help="provenance of the lines written: hand (Palle) | claude")
    a = ap.parse_args()
    d = json.loads(TRUNK.read_text(encoding="utf-8"))
    changed = False
    if a.draft is not None:
        res = draft(d, a.draft or (a.node or ""))
        print(f"drafted {res['pearls']} pearl line(s) and {res['says']} body line(s) from the corpus — stamped draft; hand lines untouched")
        changed = True
    elif a.imp:
        doc = json.loads(Path(a.imp).read_text(encoding="utf-8"))
        for node, pearls in doc.items():
            for pearl, rec in pearls.items():
                set_speak(d, node, pearl, rec.get("speak"), rec.get("says"), rec.get("by", a.by))
        changed = True
    elif a.node and a.pearl and (a.speak is not None or a.say):
        says = {}
        for s in a.say:
            k, _, v = s.partition("=")
            says[k.strip()] = v.strip()
        set_speak(d, a.node, a.pearl, a.speak, says, a.by)
        changed = True
    if changed:
        TRUNK.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        if not a.no_reseed:
            subprocess.run([sys.executable, str(REPO / "tools" / "build_trunk_pearls.py")], cwd=REPO, capture_output=True)
            d = json.loads(TRUNK.read_text(encoding="utf-8"))
    if a.node:
        show(d, a.node)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
