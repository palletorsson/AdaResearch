#!/usr/bin/env python3
"""THE RED THREAD PAGE — regenerate it as rooms get written.

    python tools/red_thread_page.py --out <file.html>

Reads three things and folds them into one page:

  ada_run/spine_triage.json          DERIVED  the reading pass: one verdict per room
                                              (GOOD / THIN / SPLIT / EMPTY), the thread
                                              per sequence, the evidence, the KEEP line
  commons/data/red_thread_rulings.json AUTHORED Palle's one-line ruling on a room's
                                              argument. A SPLIT room with a ruling is decided.
  commons/maps/<Map>/final.md + map_data.json   re-surveyed on every run: a room with a
                                              final.md is WRITTEN, whatever the triage said,
                                              and its tags are checked against the map

The triage verdict is kept as `verdict_was` so the page can say "written, was SPLIT".
Publish the output with the Artifact tool to the page's existing URL (see the
red-thread memory) so the link stays the same.
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRIAGE = ROOT / "ada_run" / "spine_triage.json"
RULINGS = ROOT / "commons" / "data" / "red_thread_rulings.json"
TEMPLATE = ROOT / "tools" / "red_thread_template.html"
MAPS = ROOT / "commons" / "maps"

TAG = re.compile(r"<!--\s*@([A-Za-z0-9_]+)\s*-->")


def placed_tokens(map_name: str) -> set[str]:
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return set()
    try:
        layers = json.loads(p.read_text(encoding="utf-8")).get("layers", {})
    except Exception:  # noqa: BLE001
        return set()
    out: set[str] = set()
    for row in layers.get("interactables", []):
        for c in row:
            t = str(c).strip()
            if t and t != "-":
                out.add(t.split(":")[0].split("#")[0])
    for row in layers.get("utilities", []):
        for c in row:
            t = str(c).strip()
            if t and t != "-":
                out.add(t.split(":")[0].lstrip("@#"))
    return out


def resurvey(m: dict) -> None:
    """Refresh what the disk says about one room: written?, how long, tags placed?"""
    fin = MAPS / m["map"] / "final.md"
    if not fin.exists():
        m["final"] = 0
        m["final_tags"] = 0
        m["final_tags_placed"] = 0
        return
    src = fin.read_text(encoding="utf-8")
    tags = TAG.findall(src)
    placed = placed_tokens(m["map"])
    m["final"] = len(src.split())
    m["final_tags"] = len(tags)
    m["final_tags_placed"] = sum(1 for t in tags if t in placed)


def build(out: Path) -> dict:
    if not TRIAGE.exists():
        sys.exit("no %s — run the triage first" % TRIAGE)
    data = json.loads(TRIAGE.read_text(encoding="utf-8"))
    rulings = {}
    if RULINGS.exists():
        rulings = json.loads(RULINGS.read_text(encoding="utf-8")).get("rooms", {})

    written = 0
    decided = 0
    for m in data["maps"]:
        resurvey(m)
        m["verdict_was"] = m.get("verdict_was") or m["verdict"]
        r = rulings.get(m["map"])
        m["ruling"] = r["argument"] if r else ""
        m["ruling_date"] = r["date"] if r else ""
        if m["final"] > 0:
            m["verdict"] = "WRITTEN"
            written += 1
        else:
            m["verdict"] = m["verdict_was"]
        if m["verdict_was"] == "SPLIT" and (m["ruling"] or m["verdict"] == "WRITTEN"):
            decided += 1

    stale = sum(m["final_tags"] - m["final_tags_placed"] for m in data["maps"])
    meta = data.setdefault("meta", {})
    meta.update(
        maps=len(data["maps"]),
        sequences=len(data["sequences"]),
        written=written,
        split_decided=decided,
        stale_tags=stale,
        generated=date.today().isoformat(),
    )

    html = TEMPLATE.read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    if "/*__DATA__*/" not in html:
        sys.exit("template has no /*__DATA__*/ placeholder")
    out.parent.mkdir(parents=True, exist_ok=True)
    io.open(out, "w", encoding="utf-8", newline="\n").write(html.replace("/*__DATA__*/", payload, 1))
    return meta


def main() -> int:
    ap = argparse.ArgumentParser(description="regenerate the Red Thread page")
    ap.add_argument("--out", required=True, help="where to write the .html (publish this path)")
    args = ap.parse_args()
    meta = build(Path(args.out))
    print("red thread: %d rooms, %d written, %d SPLIT decided, %d stale tag(s) -> %s"
          % (meta["maps"], meta["written"], meta["split_decided"], meta["stale_tags"], args.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
