# -*- coding: utf-8 -*-
"""own_room_match.py — every chapter played against its own room.

The board that ruled the eight crowns tested 24 chapters against 5 museums, and
could not have tested anything else: the field gate required a `museum` field,
so a chapter never met the room its own sequence already uses. Eight crowns were
ruled without that control on the board.

This runs it. For each of the 24 spine sequences, the candidates are the
sequence's OWN segments (tools/spine_segments.py, cut at corridor scale), played
on the identical cast, through the same pathfinder gate and the same judge as
every previous match. Nothing else changes.

The result is a baseline, not a verdict. If a crowned chapter's own room
outscores its crown, that is a ruling worth revisiting. If it does not, the crown
has the control it was missing.

    python tools/own_room_match.py            # all 24
    python tools/own_room_match.py --seq=color
"""
import json, argparse, os, subprocess, sys, time, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHELF = ROOT / "commons/data/template_shelf.json"
OUT = ROOT / "doc/reports/own_room_match.json"


def plan():
    shelf = json.loads(SHELF.read_text(encoding="utf-8"))["patterns"]
    spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    crowns = json.loads((ROOT / "commons/data/museum_crowns.json").read_text(encoding="utf-8"))["crowns"]
    out = []
    for s in spine["spine"]["sequences"]:
        seq = s["name"]
        keys = [k for k, v in shelf.items() if v["source"] == "spine-segment"
                and (v.get("extra") or {}).get("sequence") == seq]
        if keys and (ROOT / ("doc/reports/map_tournament_%s.json" % seq)).exists():
            out.append({"seq": seq, "phase": s.get("phase", ""), "keys": keys,
                        "crown": crowns.get(seq, {}).get("template", "")})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", default="")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    rows = [r for r in plan() if not a.seq or r["seq"] == a.seq]
    print("%d chapters, %d own-room candidates" % (len(rows), sum(len(r["keys"]) for r in rows)))
    results = []
    t0 = time.time()
    for i, r in enumerate(rows, 1):
        seq = r["seq"]
        t1 = time.time()
        p = subprocess.run([sys.executable, str(ROOT / "tools/museum_match.py"),
                            "--seq=%s" % seq, "--museums=%s" % ",".join(r["keys"])],
                           capture_output=True, text=True, cwd=str(ROOT))
        rep = ROOT / ("doc/reports/museum_match_%s.json" % seq)
        best, champ = None, None
        try:
            d = json.loads(rep.read_text(encoding="utf-8"))
            rowset = d if isinstance(d, list) else (d.get("results") or d.get("rows") or [])
            for e in rowset:
                if not isinstance(e, dict):
                    continue
                nm, sc = str(e.get("name") or e.get("key") or ""), e.get("score")
                if sc is None:
                    continue
                if nm in r["keys"] and (best is None or sc > best[1]):
                    best = (nm, sc)
                if e.get("kind") == "bred" and (champ is None or sc > champ[1]):
                    champ = (nm, sc)
        except Exception:
            pass
        # the tool prints the ranked table; parse it as the durable record
        table = [l for l in p.stdout.splitlines() if l.strip()[:2].rstrip(".").isdigit()]
        results.append({"seq": seq, "phase": r["phase"], "crown": r["crown"],
                        "candidates": len(r["keys"]), "table": table[:6],
                        "own_best": best, "bred_champ": champ,
                        "secs": round(time.time() - t1, 1), "rc": p.returncode})
        print("[%2d/%2d] %-24s %2d cand  %5.0fs  %s" %
              (i, len(rows), seq, len(r["keys"]), time.time() - t1,
               (table[0].strip() if table else "no table")))
        OUT.write_text(json.dumps({"elapsed_s": round(time.time() - t0, 1),
                                   "results": results}, indent=1), encoding="utf-8")
    print("\ndone in %.0f min -> %s" % ((time.time() - t0) / 60.0, OUT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
