#!/usr/bin/env python3
"""
rescore_bred_champions.py — the bred field under the ruled judge.

The patience ruling (2026-08-01) changed the binding score AFTER every
tournament baseline was recorded, so the bred numbers on file are
score_promise_only values wearing the old name. This rescoresthe surviving
bred CHAMPION of each sequence with the ruled experience_score, writing one
file per sequence to doc/reports/bred_rescore/<seq>.json — the standing
caveat ("rescore before comparing") made executable.

  python tools/rescore_bred_champions.py --seqs=randomness,color
"""
from __future__ import annotations
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
OUT_DIR = os.path.join(ROOT, "doc", "reports", "bred_rescore")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from map_tournament import experience_score  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seqs", required=True)
    args = ap.parse_args()
    os.makedirs(OUT_DIR, exist_ok=True)
    for seq in args.seqs.split(","):
        seq = seq.strip()
        rep_p = os.path.join(ROOT, "doc", "reports", f"map_tournament_{seq}.json")
        if not os.path.isfile(rep_p):
            print(f"{seq}: no tournament report")
            continue
        rep = json.load(open(rep_p, encoding="utf-8"))
        ok = sorted([r for r in rep["rows"] if r.get("status") == "ok"],
                    key=lambda r: -r["score"])
        if not ok:
            print(f"{seq}: no bred champion")
            continue
        champ = f"Trial_{ok[0]['recipe']}_{seq}"
        if not os.path.isfile(os.path.join(MAPS_DIR, champ, "map_data.json")):
            print(f"{seq}: champion {champ} not on disk")
            continue
        s, detail = experience_score(champ)
        if s is None:
            print(f"{seq}: SCORE FAIL {detail}")
            continue
        out = {"seq": seq, "champion": champ, "recipe": ok[0]["recipe"],
               "classic_score": ok[0]["score"], **detail}
        json.dump(out, open(os.path.join(OUT_DIR, f"{seq}.json"), "w", encoding="utf-8"), indent=1)
        print(f"{seq:24} {ok[0]['recipe']:10} classic {ok[0]['score']:5.2f} -> ruled {detail['score']:5.2f} (patience {detail['patience']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
