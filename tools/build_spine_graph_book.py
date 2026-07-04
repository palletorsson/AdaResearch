#!/usr/bin/env python3
"""build_spine_graph_book.py — the book lens for /spine-graph.

Marks, on the full 772-artifact workbench, which nodes the manuscript actually
walks (the excavated ring) and how deep each stratum goes — so the trench is
visible as a path cut through the whole site.

Output (ada_encyclopedia/public/spine-graph-book.json):
  {
    "arts": { "<lookup>": { "ch": 8, "seq": "randomness" }, ... },   # walked in the book
    "seqs": { "<seq>":    { "ch": 8, "walked": 11, "pearls": 65, "authored": 1 }, ... }
  }

Usage: python tools/build_spine_graph_book.py
Rebuild after any tutorial rebuild (it reads the tutorial JSONs).
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
OUT = os.path.join(ENC, "public", "spine-graph-book.json")


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def main() -> int:
    frame = load_json(FRAME)
    if not frame:
        print(f"!! no frame: {FRAME}")
        return 1
    arts: dict[str, dict] = {}
    seqs: dict[str, dict] = {}
    num = 0
    for part in frame["parts"]:
        for seq in part["sequences"]:
            num += 1
            t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
            if not t:
                seqs[seq] = {"ch": num, "walked": 0, "pearls": 0, "authored": 0}
                continue
            walked = []
            for p in t.get("pages", []):
                if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
                    walked.append(p["artifact"].get("name"))
                elif p["kind"] == "walk":
                    walked += [a.get("name") for a in p.get("artifacts") or []]
            for name in walked:
                if name and name not in arts:
                    arts[name] = {"ch": num, "seq": seq}
            dig = t.get("dig") or {}
            seqs[seq] = {"ch": num, "walked": len(walked),
                         "pearls": dig.get("pearls", len(walked)),
                         "authored": 1 if t.get("authored") else 0}
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"arts": arts, "seqs": seqs}, f, indent=0, separators=(",", ":"))
    print(f"book lens: {len(arts)} walked artifacts across {len(seqs)} strata -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
