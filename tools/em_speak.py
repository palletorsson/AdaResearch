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


def set_speak(d: dict, node: str, pearl: str, speak: str | None, says: dict | None) -> None:
    e = _edit_for(d, node, pearl)
    if speak is not None:
        e["speak"] = speak
    if says:
        e.setdefault("says", {}).update(says)


def show(d: dict, node: str) -> None:
    seeded = next((t for t in d.get("trunk", []) if t.get("node") == node), {}) or {}
    for p in seeded.get("pearls", []):
        print(f"{p.get('pearl'):18s} {p.get('speak', '') or '—'}")
        for tok, line in (p.get("says") or {}).items():
            print(f"    {tok:32s} {line}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("node", nargs="?")
    ap.add_argument("pearl", nargs="?")
    ap.add_argument("--speak")
    ap.add_argument("--say", action="append", default=[], metavar="TOKEN=LINE")
    ap.add_argument("--import", dest="imp")
    ap.add_argument("--no-reseed", action="store_true")
    a = ap.parse_args()
    d = json.loads(TRUNK.read_text(encoding="utf-8"))
    changed = False
    if a.imp:
        doc = json.loads(Path(a.imp).read_text(encoding="utf-8"))
        for node, pearls in doc.items():
            for pearl, rec in pearls.items():
                set_speak(d, node, pearl, rec.get("speak"), rec.get("says"))
        changed = True
    elif a.node and a.pearl and (a.speak is not None or a.say):
        says = {}
        for s in a.say:
            k, _, v = s.partition("=")
            says[k.strip()] = v.strip()
        set_speak(d, a.node, a.pearl, a.speak, says)
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
