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


def field_keys(shelf, seq, field):
    """Which plans a chapter is played against. `own` is the control this tool
    was written for; `shelf` is every stampable plan the project owns — the
    museums, the pattern editor's tiles and all 125 spine segments — which is
    the match the crowns were never given."""
    if field == "own":
        return [k for k, v in shelf.items() if v["source"] == "spine-segment"
                and (v.get("extra") or {}).get("sequence") == seq]
    return [k for k, v in shelf.items() if v.get("stampable")]


def plan(field="own"):
    shelf = json.loads(SHELF.read_text(encoding="utf-8"))["patterns"]
    spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    crowns = json.loads((ROOT / "commons/data/museum_crowns.json").read_text(encoding="utf-8"))["crowns"]
    out = []
    for s in spine["spine"]["sequences"]:
        seq = s["name"]
        keys = field_keys(shelf, seq, field)
        if keys and (ROOT / ("doc/reports/map_tournament_%s.json" % seq)).exists():
            out.append({"seq": seq, "phase": s.get("phase", ""), "keys": keys,
                        "crown": crowns.get(seq, {}).get("template", "")})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", default="")
    ap.add_argument("--field", choices=["own", "shelf"], default="own")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    rows = [r for r in plan(a.field) if not a.seq or r["seq"] == a.seq]
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
        # the report's real shape: museum_rows (candidates) + bred_baseline
        best, champ, scored = None, None, 0
        shelf = json.loads(SHELF.read_text(encoding="utf-8"))["patterns"]
        try:
            d = json.loads(rep.read_text(encoding="utf-8"))
            for e in d.get("museum_rows", []):
                if e.get("status") != "ok" or e.get("score") is None:
                    continue
                scored += 1
                key = next((v for v in e.values() if isinstance(v, str) and v in shelf), "")
                if best is None or e["score"] > best[1]:
                    best = (key, e["score"], shelf.get(key, {}).get("source", "?"))
            for e in d.get("bred_baseline", []):
                if e.get("status") == "ok" and e.get("score") is not None:
                    if champ is None or e["score"] > champ[1]:
                        champ = (e.get("recipe", "?"), e["score"])
        except Exception as exc:
            print("    (report unreadable: %s)" % exc)
        results.append({"seq": seq, "phase": r["phase"], "crown": r["crown"],
                        "candidates": len(r["keys"]), "scored": scored,
                        "best": best, "bred_champ": champ,
                        "secs": round(time.time() - t1, 1), "rc": p.returncode})
        print("[%2d/%2d] %-22s %4d cand %5.0fs  best %-28s %5s  bred %5s" %
              (i, len(rows), seq, len(r["keys"]), time.time() - t1,
               (best[0][:28] if best else "-"), ("%.2f" % best[1]) if best else "-",
               ("%.2f" % champ[1]) if champ else "-"))
        OUT.write_text(json.dumps({"elapsed_s": round(time.time() - t0, 1),
                                   "results": results}, indent=1), encoding="utf-8")
    print("\ndone in %.0f min -> %s" % ((time.time() - t0) / 60.0, OUT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
