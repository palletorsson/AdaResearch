#!/usr/bin/env python3
"""champions.py — the judge's leaderboard, consolidated for the eye.

map_tournament.py scored 14 floor strategies per sequence by the EDGE FITNESS
(encounter order tau, promise, dolly-in, hero dominance rank1, desire cycles).
The reports sit one-per-sequence in doc/reports/map_tournament_*.json; the
champions stand on disk as Trial_<recipe>_<seq>. But the judge is synthetic —
it has never met Palle's eye (blog 2026-07-14: "the leaderboard's first
disagreement with Palle's eye will be worth more than everything that agreed").

This consolidates every leaderboard into ONE digest the /tournament surface
reads: per sequence the judge's champion + the full ranked field + each row's
fitness breakdown, so the eye can walk the champion, rule, and the DISAGREEMENT
(judge's pick vs Palle's pick) becomes the finding — the gardener loop closed
with the human in it.

  python tools/champions.py            # write the digest + print the table
  python tools/champions.py --print    # just print
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPORTS = ROOT / "doc" / "reports"
MAPS = ROOT / "commons" / "maps"
OUT = ROOT / "doc" / "reports" / "champions.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def _map_exists(name: str) -> bool:
    return (MAPS / name / "map_data.json").exists()


def build() -> dict:
    seqs = []
    for rp in sorted(REPORTS.glob("map_tournament_*.json")):
        try:
            d = json.loads(rp.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        rows = [r for r in d.get("rows", []) if r.get("status") == "ok"]
        if not rows:
            continue
        # the judge ranks by composite score, high wins
        field = sorted(rows, key=lambda r: r.get("score", 0.0), reverse=True)
        champ = field[0]
        for i, r in enumerate(field):
            r["judge_rank"] = i + 1
            r["on_disk"] = _map_exists(r.get("map", ""))
        seqs.append({
            "seq": d.get("seq", rp.stem.replace("map_tournament_", "")),
            "seed": d.get("seed"),
            "champion": champ.get("recipe"),
            "champion_map": champ.get("map"),
            "champion_score": champ.get("score"),
            "runner_up": field[1].get("recipe") if len(field) > 1 else None,
            "margin": round(champ.get("score", 0) - field[1].get("score", 0), 2)
            if len(field) > 1 else None,
            "field": field,
        })
    # which recipes win, across the spine (the "eight champions" tally)
    tally = {}
    for s in seqs:
        tally[s["champion"]] = tally.get(s["champion"], 0) + 1
    return {
        "_note": "the judge's leaderboard per sequence; Palle's eye rules on "
                 "/tournament, disagreements via gallery-evals gallery=tournament",
        "sequences": seqs,
        "championship_tally": dict(sorted(tally.items(),
                                          key=lambda kv: -kv[1])),
        "sequence_count": len(seqs),
    }


def main() -> int:
    digest = build()
    if "--print" not in sys.argv:
        OUT.write_text(json.dumps(digest, indent=1), encoding="utf-8", newline="\n")
        print(f"champions digest: {digest['sequence_count']} sequences -> {OUT.name}")
    print("\nchampionship tally:",
          ", ".join(f"{k} {v}" for k, v in digest["championship_tally"].items()))
    print(f"\n{'sequence':22s} {'champion':10s} {'score':>6s} {'margin':>7s} "
          f"{'2nd':10s} {'cycles':>7s}")
    for s in digest["sequences"]:
        c = s["field"][0]
        print(f"{s['seq']:22s} {s['champion']:10s} {s['champion_score']:6.2f} "
              f"{str(s['margin']):>7s} {str(s['runner_up']):10s} "
              f"{str(c.get('cycles')):>7s}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
