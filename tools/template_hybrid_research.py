#!/usr/bin/env python3
"""template_hybrid_research.py — auto-research: do cross-taste HYBRIDS beat specialists?

gallery_evolve breeds three separate populations (capacity, drama, intimacy)
and never lets them touch. placement_research taught us "no base algorithm
wins" — the analogous question one level up: is the best ROOM a specialist
(bred for one taste) or a generalist (a cross-taste hybrid)?

Method:
  1. Evolve the three specialist champions (the engine's own loop).
  2. Breed offspring across tastes (CAPxDRA, CAPxINT, DRAxINT) via the
     engine's crossover+mutate.
  3. Score EVERY room on ALL THREE fitnesses (real-pathfinder override for
     the terraced false-fail).
  4. Compare: specialist score (own-taste) vs GENERALIST score (min across
     the three tastes — the room that never embarrasses itself).

Champions land as TemplateLab_HYB_* maps (walkable at /map-viewer).
Report: doc/reports/template_hybrid_research.md (+ .json).
"""
import json
import random
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import gallery_evolve as ge

PROFILES = ("capacity", "drama", "intimacy")


def score_all(genome, name="labscore") -> dict:
    """compile once, score on all three profiles, with real-pathfinder override."""
    data, slots = ge.compile_gallery(dict(genome), gid=name)
    m = ge.measure(data, slots)
    if not m.get("reachable"):
        # write to a scratch map and ask the real pathfinder
        data["map_info"]["name"] = "TemplateLab_Score"
        data["map_info"]["lookup_name"] = "TemplateLab_Score"
        out = ROOT / "commons" / "maps" / "TemplateLab_Score"
        out.mkdir(parents=True, exist_ok=True)
        (out / "map_data.json").write_text(json.dumps(data), encoding="utf-8")
        r = subprocess.run([sys.executable, str(ROOT / "tools" / "map_pathfinder.py"),
                            "check", "TemplateLab_Score"],
                           capture_output=True, text=True, timeout=60)
        if "1 OK, 0 FAIL" in (r.stdout + r.stderr):
            m["reachable"] = True
    return {p: round(ge.fitness(p, m), 2) for p in PROFILES}


def write_champion(genome, name):
    data, slots = ge.compile_gallery(dict(genome), gid=name)
    data["map_info"]["name"] = name
    data["map_info"]["lookup_name"] = name
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)


def main() -> int:
    seed = int(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--seed=")), "11"))
    kids = int(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--kids=")), "8"))
    rng = random.Random(seed)

    print("1) evolving the three specialists (engine's own loop)…")
    champs = {}
    for p in PROFILES:
        scored, _history = ge.evolve(p, rng)   # [(fitness, genome, measure), ...]
        s, g, _m = scored[0]
        champs[p] = g
        print(f"   {p}: engine score {round(s,2)} form={g.get('form')} light={g.get('light')}")

    print("2) breeding cross-taste offspring…")
    rows = []
    for p in PROFILES:  # the specialists themselves enter the tournament
        sc = score_all(champs[p])
        rows.append({"id": f"SPEC_{p[:3].upper()}", "parents": p, "genome": champs[p], "scores": sc})
    pairs = [("capacity", "drama"), ("capacity", "intimacy"), ("drama", "intimacy")]
    for a, b in pairs:
        for i in range(kids):
            child = ge.mutate(rng, ge.crossover(rng, dict(champs[a]), dict(champs[b])))
            sc = score_all(child)
            rows.append({"id": f"HYB_{a[:3].upper()}x{b[:3].upper()}_{i+1}",
                         "parents": f"{a}×{b}", "genome": child, "scores": sc})

    # generalist metric: worst-case across tastes (never embarrasses itself)
    for r in rows:
        s = r["scores"]
        r["generalist"] = round(min(s.values()), 2)
        r["mean"] = round(sum(s.values()) / 3, 2)

    rows.sort(key=lambda r: -r["generalist"])
    best_gen = rows[0]
    spec_best_gen = max((r for r in rows if r["id"].startswith("SPEC")), key=lambda r: r["generalist"])
    hybrids = [r for r in rows if r["id"].startswith("HYB")]
    hyb_beats = best_gen["id"].startswith("HYB")

    print("3) writing champions as walkable maps…")
    write_champion(best_gen["genome"], "TemplateLab_HYB_GEN")
    for p in PROFILES:
        write_champion(champs[p], f"TemplateLab_SPEC_{p[:3].upper()}")

    # report
    lines = ["# Template hybrid research — specialists vs cross-taste hybrids", "",
             f"Seed {seed}, {kids} offspring per cross ({len(hybrids)} hybrids + 3 specialists).",
             "Generalist score = MIN fitness across the three tastes.", "",
             "| room | parents | capacity | drama | intimacy | generalist | mean |",
             "|---|---|---|---|---|---|---|"]
    for r in rows[:14]:
        s = r["scores"]
        lines.append(f"| {r['id']} | {r['parents']} | {s['capacity']} | {s['drama']} | "
                     f"{s['intimacy']} | **{r['generalist']}** | {r['mean']} |")
    lines += ["", "## Finding", ""]
    if hyb_beats:
        g = best_gen["genome"]
        lines.append(f"**The hybrid wins.** {best_gen['id']} ({best_gen['parents']}) tops the "
                     f"generalist table at {best_gen['generalist']} vs the best specialist's "
                     f"{spec_best_gen['generalist']} ({spec_best_gen['id']}). Genome: form={g.get('form')}, "
                     f"light={g.get('light')}, niches every {g.get('niche_every')}, podium {g.get('podium_motif')}, "
                     f"floating walls {g.get('floating_walls')}. Cross-taste breeding finds rooms that "
                     f"hold capacity, drama AND intimacy at once — the taste populations should touch.")
    else:
        lines.append(f"**The specialist holds.** {spec_best_gen['id']} stays the best generalist "
                     f"({spec_best_gen['generalist']}) — crossing tastes diluted more than it blended. "
                     f"Specialist populations earn their separation.")
    lines += ["", f"Walk them: /map-viewer?map=TemplateLab_HYB_GEN and TemplateLab_SPEC_CAP/DRA/INT.", ""]
    rep = ROOT / "doc" / "reports" / "template_hybrid_research.md"
    rep.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    (ROOT / "doc" / "reports" / "template_hybrid_research.json").write_text(
        json.dumps({"seed": seed, "rows": rows}, indent=1), encoding="utf-8", newline="\n")
    print(f"report -> {rep}")
    print(f"WINNER: {best_gen['id']} generalist={best_gen['generalist']} "
          f"(best specialist: {spec_best_gen['id']} {spec_best_gen['generalist']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
