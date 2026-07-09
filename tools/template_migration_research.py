#!/usr/bin/env python3
"""template_migration_research.py — auto-research round 2: does MIGRATION help?

Round 1 (template_hybrid_research) found: capacity×intimacy is the productive
cross; drama is a true specialist. The engine-change hypothesis: let the
capacity and intimacy populations EXCHANGE MIGRANTS each generation (drama
stays isolated). Before touching the engine, prove it in a harness:

  A/B, same seeds:
    ISOLATED  — capacity and intimacy evolve separately (the engine's way)
    MIGRATION — each generation, the top rooms of each population breed
                cross-population children injected into BOTH pools

  Metric: the GENERALIST score (min fitness across all three tastes,
  drama included though nobody breeds for it) of the best room found.

If migration's generalist beats isolated's on both seeds, the rule earns its
place in gallery_evolve. Champion lands as TemplateLab_MIG_GEN (walkable).
Report: doc/reports/template_migration_research.md
"""
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import gallery_evolve as ge

POP, GENS, ELITE, MIGRANTS = 14, 5, 3, 2
TASTES = ("capacity", "intimacy")          # the breeding tastes
ALL = ("capacity", "drama", "intimacy")    # the judging tastes


def scores_of(genome) -> dict:
    data, slots = ge.compile_gallery(dict(genome), gid="mig")
    m = ge.measure(data, slots)
    return {p: ge.fitness(p, m) for p in ALL}


def generalist(sc: dict) -> float:
    return min(sc.values())


def evolve_pair(rng, migration: bool):
    """co-evolve the two taste populations; return (best_genome, best_generalist, trace)."""
    pops = {t: [ge.make_genome(rng) for _ in range(POP)] for t in TASTES}
    best_g, best_s = None, -1e9
    trace = []
    for gen in range(GENS):
        scored = {}
        for t in TASTES:
            rows = []
            for g in pops[t]:
                sc = scores_of(g)
                rows.append((sc[t], g, sc))
                gs = generalist(sc)
                if gs > best_s:
                    best_g, best_s = g, gs
            rows.sort(key=lambda x: -x[0])
            scored[t] = rows
        trace.append({"gen": gen + 1, "best_generalist": round(best_s, 2)})
        # breed within each taste
        for t in TASTES:
            rows = scored[t]
            nxt = [dict(r[1]) for r in rows[:ELITE]]
            while len(nxt) < POP - (MIGRANTS if migration else 0):
                a = max(rng.sample(rows, 3), key=lambda x: x[0])[1]
                b = max(rng.sample(rows, 3), key=lambda x: x[0])[1]
                child = ge.crossover(rng, dict(a), dict(b))
                if rng.random() < 0.7:
                    child = ge.mutate(rng, child)
                nxt.append(child)
            pops[t] = nxt
        # migration: cross-population children injected into BOTH pools
        if migration:
            top_c = [r[1] for r in scored["capacity"][:MIGRANTS]]
            top_i = [r[1] for r in scored["intimacy"][:MIGRANTS]]
            for t in TASTES:
                for k in range(MIGRANTS):
                    child = ge.crossover(rng, dict(top_c[k % len(top_c)]),
                                         dict(top_i[k % len(top_i)]))
                    if rng.random() < 0.5:
                        child = ge.mutate(rng, child)
                    pops[t].append(child)
    return best_g, best_s, trace


def main() -> int:
    seeds = [int(s) for s in
             next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--seeds=")),
                  "11,23").split(",")]
    results = []
    overall_best = (None, -1e9)
    for seed in seeds:
        row = {"seed": seed}
        for mode, mig in (("isolated", False), ("migration", True)):
            rng = random.Random(seed)          # SAME rng start for both arms
            g, s, trace = evolve_pair(rng, mig)
            row[mode] = round(s, 2)
            row[f"{mode}_trace"] = trace
            if mig and s > overall_best[1]:
                overall_best = (g, s)
            print(f"seed {seed} {mode:9s}: best generalist {round(s,2)}")
        row["delta"] = round(row["migration"] - row["isolated"], 2)
        results.append(row)

    wins = sum(1 for r in results if r["delta"] > 0)
    verdict = ("MIGRATION WINS" if wins == len(results) else
               "ISOLATED HOLDS" if wins == 0 else "SPLIT")

    # write the migration champion as a walkable map
    if overall_best[0] is not None:
        data, _ = ge.compile_gallery(dict(overall_best[0]), gid="TemplateLab_MIG_GEN")
        data["map_info"]["name"] = "TemplateLab_MIG_GEN"
        data["map_info"]["lookup_name"] = "TemplateLab_MIG_GEN"
        out = ROOT / "commons" / "maps" / "TemplateLab_MIG_GEN"
        out.mkdir(parents=True, exist_ok=True)
        with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, indent=1)

    lines = ["# Template migration research — do exchanged migrants breed better generalists?",
             "",
             f"A/B per seed, same RNG start: ISOLATED (engine's way) vs MIGRATION "
             f"({MIGRANTS} cross-population children into both pools per generation). "
             f"pop {POP}, {GENS} generations, tastes bred: capacity+intimacy; "
             "generalist = min fitness across all three tastes (drama judges, nobody breeds for it).",
             "",
             "| seed | isolated | migration | Δ |",
             "|---|---|---|---|"]
    for r in results:
        lines.append(f"| {r['seed']} | {r['isolated']} | {r['migration']} | **{r['delta']:+}** |")
    lines += ["", "## Verdict", "", f"**{verdict}** ({wins}/{len(results)} seeds)."]
    if overall_best[0]:
        g = overall_best[0]
        lines.append(f"Migration champion (generalist {round(overall_best[1],2)}): "
                     f"form={g.get('form')}, {g.get('w')}×{g.get('d')}, podium {g.get('podium_motif')}, "
                     f"niches every {g.get('niche_every')}, floating walls {g.get('floating_walls')}, "
                     f"light {g.get('light')} — walk it: /map-viewer?map=TemplateLab_MIG_GEN")
    lines += ["", "In-loop scoring uses the engine's quick reachability (terraced forms "
              "penalized as in round 1 — both arms equally biased, so the A/B stands).", ""]
    rep = ROOT / "doc" / "reports" / "template_migration_research.md"
    rep.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    (ROOT / "doc" / "reports" / "template_migration_research.json").write_text(
        json.dumps({"results": results, "verdict": verdict}, indent=1),
        encoding="utf-8", newline="\n")
    print(f"\nVERDICT: {verdict}  ->  {rep}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
