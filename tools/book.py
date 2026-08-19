#!/usr/bin/env python3
"""THE BOOK — a pearl is a list of LINES. One authored file per chapter.

    python tools/book.py migrate --chapter primitives     # trunk (hand edits) -> commons/data/book/primitives.json
    python tools/book.py compile --chapter primitives     # book -> hand_pearls in trunk_branches.json -> reseed
    python tools/book.py show    --chapter primitives     # the book, printed as the page

Palle, 2026-08-19: "have the order of the pearl and the text side by side. The text
should be built by the artifact pearl poem text that can be added, edited and removed."

Today four fields describe one pearl — tokens (the order), says (text per token),
tokens_add/remove/order (edits to the order), speak/page2/foyer (text that is not a
token's). The book collapses them: a pearl is a LIST OF LINES, in order. A line is

    {"token": "you_are_here", "text": "You are here", "by": "hand"}      an artifact, with its words
    {"token": "folding_past"}                                           an artifact, no words yet
    {"text": "You arrive late. No reboot.\n…", "by": "hand"}            words only -> the wall
    + optional "place": "foyer" (the lobby builder places it), "indent", "gap" (verse)

The order of the list is the order of the walk, the plan and the page. Reorder a
line and the body moves; delete a line and the body leaves; add a line and it
enters. Text-only lines: the first is the pearl's page line (speak), the rest are
the hall's stanza (page2) — both derived, not stored twice.

The book is the AUTHOR for the pearls it holds. `compile` writes the equivalent
hand_pearls edits into trunk_branches.json and reseeds, so every tool downstream
(spine_run, em_bake, the museum, /speak) is untouched. A pearl the book does not
hold keeps whatever hand edit it had.
"""
from __future__ import annotations
import argparse, json, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
BOOK_DIR = REPO / "commons" / "data" / "book"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def book_path(chapter: str) -> Path:
    return BOOK_DIR / f"{chapter}.json"


def load_book(chapter: str) -> dict:
    p = book_path(chapter)
    if not p.exists():
        return {"chapter": chapter, "speak": "", "speak_by": "", "pearls": []}
    return json.loads(p.read_text(encoding="utf-8"))


def save_book(b: dict) -> Path:
    BOOK_DIR.mkdir(parents=True, exist_ok=True)
    p = book_path(b["chapter"])
    p.write_text(json.dumps(b, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return p


# ── migrate: trunk -> book ─────────────────────────────────────────────────

def migrate(chapter: str) -> dict:
    d = json.loads(TRUNK.read_text(encoding="utf-8"))
    node = next((t for t in d.get("trunk", []) if t.get("node") == chapter), None)
    if not node:
        raise SystemExit(f"no chapter {chapter}")
    book = {"chapter": chapter, "speak": str(node.get("speak", "")), "speak_by": str(node.get("speak_by", "")) if node.get("speak") else "", "pearls": []}
    for p in node.get("pearls", []):
        says = p.get("says", {}) or {}
        says_by = p.get("says_by", {}) or {}
        verse = p.get("verse", {}) or {}
        foyer = list(p.get("foyer", []) or [])
        lines: list[dict] = []
        if p.get("speak"):
            ln = {"text": str(p["speak"]), "by": str(p.get("speak_by", "hand"))}
            if foyer:
                ln["place"] = "foyer"
            lines.append(ln)
        page2_done = not p.get("page2")
        toks = list(p.get("tokens", []))
        for i, tok in enumerate(toks):
            ln: dict = {"token": tok}
            if says.get(tok):
                ln["text"] = str(says[tok]); ln["by"] = str(says_by.get(tok, "hand"))
            if tok in foyer:
                ln["place"] = "foyer"
            if (p.get("supports") or {}).get(tok):
                ln["support_m"] = float(p["supports"][tok])
            if (p.get("locks") or {}).get(tok):
                ln["lock"] = list(p["locks"][tok])
            v = verse.get(tok)
            if isinstance(v, dict):
                if v.get("indent"): ln["indent"] = int(v["indent"])
                if v.get("gap"): ln["gap"] = int(v["gap"])
            lines.append(ln)
            # page 2 stands where the foyer ends and the hall begins
            if not page2_done and foyer and tok in foyer and (i + 1 >= len(toks) or toks[i + 1] not in foyer):
                lines.append({"text": str(p["page2"]), "by": "hand"}); page2_done = True
        if not page2_done:
            lines.insert(1 if lines and "token" not in lines[0] else 0, {"text": str(p["page2"]), "by": "hand"})
        bp = {"pearl": p.get("pearl", ""), "map": p.get("map", ""), "lines": lines}
        if p.get("rooms") is not None: bp["rooms"] = int(p["rooms"])
        if p.get("join"): bp["join"] = True
        if p.get("ordered"): bp["ordered"] = True     # composed: the list IS the cast (else the dealer adds relatives)
        if p.get("hero"): bp["hero"] = p["hero"]
        book["pearls"].append(bp)
    return book


# ── compile: book -> hand_pearls -> reseed ─────────────────────────────────

def compile_book(chapter: str, reseed: bool = True) -> dict:
    book = load_book(chapter)
    d = json.loads(TRUNK.read_text(encoding="utf-8"))
    node = next((t for t in d.get("trunk", []) if t.get("node") == chapter), None)
    if not node:
        raise SystemExit(f"no chapter {chapter}")
    edits: list[dict] = list(d.setdefault("hand_pearls", {}).get(chapter, []))
    cur_by_map = {p.get("map"): p for p in node.get("pearls", [])}
    report = []
    for bp in book.get("pearls", []):
        m = bp.get("map", "")
        cur = cur_by_map.get(m, {})
        e = next((x for x in edits if x.get("map") == m and not x.get("new")), None)
        if e is None:
            e = {"map": m}; edits.append(e)
        toks = [ln["token"] for ln in bp.get("lines", []) if ln.get("token")]
        # the seeded BASE of this pearl: what the maps give it before any hand edit —
        # the current tokens less the ones a hand edit added, plus the ones it removed
        prev_add = set(e.get("tokens_add", [])) | set(e.get("foyer", []))
        base = [t for t in cur.get("tokens", []) if t not in prev_add] + [t for t in e.get("tokens_remove", []) if t not in cur.get("tokens", [])]
        base_set = set(base)
        # ORDERED = composed: the list is the cast and its order is the walk. A pearl
        # nobody has composed yet stays dealt (relatives may join it) — until a line is
        # moved, added or removed in the editor, which marks it composed.
        if bp.get("ordered"):
            e["tokens_order"] = toks
        else:
            e.pop("tokens_order", None)
        e["tokens_add"] = [t for t in toks if t not in base_set]
        e["tokens_remove"] = sorted(t for t in base_set if t not in set(toks))
        # words
        text_lines = [ln for ln in bp.get("lines", []) if not ln.get("token") and str(ln.get("text", "")).strip()]
        if text_lines:
            e["speak"] = str(text_lines[0]["text"]); e["speak_by"] = str(text_lines[0].get("by") or "hand")
        else:
            e.pop("speak", None); e.pop("speak_by", None)
        rest = [str(ln["text"]) for ln in text_lines[1:]]
        if rest:
            e["page2"] = "\n\n".join(rest)
        else:
            e.pop("page2", None)
        says, says_by, verse = {}, {}, {}
        for ln in bp.get("lines", []):
            tok = ln.get("token")
            if not tok:
                continue
            if str(ln.get("text", "")).strip():
                says[tok] = str(ln["text"]).strip(); says_by[tok] = str(ln.get("by") or "hand")
            v = {}
            if ln.get("indent"): v["indent"] = int(ln["indent"])
            if ln.get("gap"): v["gap"] = int(ln["gap"])
            if v: verse[tok] = v
        e["says"], e["says_by"] = says, says_by
        # a line may ask for a PLINTH: support_m on the line -> the plan row's support
        # a line may be LOCKED to a tile cell (Palle: "lock certain artifacts in position"):
        # lock: [x, z] -> the negotiator's fixed cell, reserved before the poem deals
        locks = {ln["token"]: [int(ln["lock"][0]), int(ln["lock"][1])] for ln in bp.get("lines", []) if ln.get("token") and isinstance(ln.get("lock"), list) and len(ln["lock"]) >= 2}
        if locks: e["locks"] = locks
        else: e.pop("locks", None)
        supports = {ln["token"]: float(ln["support_m"]) for ln in bp.get("lines", []) if ln.get("token") and ln.get("support_m")}
        if supports: e["supports"] = supports
        else: e.pop("supports", None)
        e.pop("says_draft", None)
        if verse: e["verse"] = verse
        else: e.pop("verse", None)
        foyer = [ln["token"] for ln in bp.get("lines", []) if ln.get("token") and ln.get("place") == "foyer"]
        if foyer: e["foyer"] = foyer
        else: e.pop("foyer", None)
        if bp.get("rooms") is not None: e["rooms"] = int(bp["rooms"])
        if bp.get("join"): e["join"] = True
        else: e.pop("join", None)
        if bp.get("pearl") and bp["pearl"] != cur.get("pearl"): e["pearl"] = bp["pearl"]
        if bp.get("hero"): e["hero"] = bp["hero"]
        report.append(f"  {bp.get('pearl', m):18s} {len(toks):2d} bodies · +{len(e['tokens_add'])} -{len(e['tokens_remove'])} · {len(says)} lines · {len(text_lines)} wall text")
    d["hand_pearls"][chapter] = edits
    if book.get("speak"):
        d.setdefault("hand_nodes", {})[chapter] = {"speak": book["speak"], "speak_by": book.get("speak_by") or "hand"}
    TRUNK.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"BOOK COMPILE: {chapter} — {len(book.get('pearls', []))} pearls -> hand_pearls")
    for r in report: print(r)
    if reseed:
        subprocess.run([sys.executable, str(REPO / "tools" / "build_trunk_pearls.py")], cwd=REPO, check=False)
    return {"pearls": len(book.get("pearls", [])), "report": report}


# ── show: the page ─────────────────────────────────────────────────────────

def show(chapter: str) -> None:
    b = load_book(chapter)
    print(f"{chapter.upper()}" + (f" — {b['speak']}" if b.get("speak") else ""))
    for p in b.get("pearls", []):
        print(f"\n  {p.get('pearl')}  (map {p.get('map')}" + (f", rooms {p['rooms']}" if p.get("rooms") is not None else "") + (", joins the hall above" if p.get("join") else "") + ")")
        for ln in p.get("lines", []):
            tok = ln.get("token", "")
            txt = str(ln.get("text", "")).replace("\n", "\n" + " " * 30)
            place = " ·foyer" if ln.get("place") == "foyer" else ""
            print(f"    {tok:26s}{place:7s} {txt}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["migrate", "compile", "show"])
    ap.add_argument("--chapter", required=True)
    ap.add_argument("--no-reseed", action="store_true")
    a = ap.parse_args()
    if a.cmd == "migrate":
        b = migrate(a.chapter); p = save_book(b)
        print(f"BOOK MIGRATE: {a.chapter} — {len(b['pearls'])} pearls, {sum(len(x['lines']) for x in b['pearls'])} lines -> {p}")
    elif a.cmd == "compile":
        compile_book(a.chapter, reseed=not a.no_reseed)
    else:
        show(a.chapter)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
