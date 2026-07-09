#!/usr/bin/env python3
"""template_lab.py — one-shot genome -> walkable room, for the /template-lab loop.

The browser is the shortcut: Three.js renders a compiled room in seconds
(no engine boot, no capture pipeline), so template research runs at
interactive speed. This wrapper IMPORTS the other session's engine
(gallery_evolve: genome, compile, measure, fitness) untouched and adds the
two verbs the lab needs:

  --compile --genome-json='{...}' [--name=TemplateLab_Live]
      compile ONE genome to a named map + return measures/fitness as JSON
  --evolve --profile=capacity|drama|intimacy [--gens=2] [--pop=10] [--seed=N]
      quick in-process evolution, returns the champion genome + score (no map)
  --random [--seed=N]
      a fresh random genome (the dice roll)

Output: one JSON object on stdout. The map (if compiled) lands in
commons/maps/<name>/map_data.json — instantly viewable at
/map-viewer?map=<name> (walk + fly).
"""
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import gallery_evolve as ge  # the other session's engine, imported not edited


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def flag(name):
    return f"--{name}" in sys.argv


def compile_one(genome: dict, name: str) -> dict:
    g = dict(genome)
    data, slots = ge.compile_gallery(g, gid=name)
    # write under the requested map name
    data["map_info"]["name"] = name
    data["map_info"]["lookup_name"] = name
    out_dir = ROOT / "commons" / "maps" / name
    out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    m = ge.measure(data, slots)
    # the engine's quick in-memory reachability doesn't model wedges/terraces;
    # the REAL pathfinder is the truth — override when it passes.
    pf_ok = None
    if not m.get("reachable"):
        import subprocess
        r = subprocess.run([sys.executable, str(ROOT / "tools" / "map_pathfinder.py"),
                            "check", name], capture_output=True, text=True, timeout=60)
        pf_ok = "1 OK, 0 FAIL" in (r.stdout + r.stderr)
        if pf_ok:
            m["reachable"] = True
    scores = {p: round(ge.fitness(p, m), 3) for p in ("capacity", "drama", "intimacy")}
    return {"ok": True, "map": name, "genome": g, "measure": m, "fitness": scores,
            "pathfinder_override": pf_ok, "view": f"/map-viewer?map={name}"}


def main() -> int:
    seed = int(arg("seed", str(random.randrange(1_000_000))))
    rng = random.Random(seed)

    if flag("random"):
        print(json.dumps({"ok": True, "genome": ge.make_genome(rng), "seed": seed}))
        return 0

    if flag("evolve"):
        profile = arg("profile", "capacity")
        gens = int(arg("gens", "2"))
        pop = int(arg("pop", "10"))
        if profile == "generalist" or flag("migration"):
            # the proven rule (template_migration_research: 3/3 seeds, +5..+6.6):
            # capacity+intimacy co-evolve with migrant exchange; best generalist wins
            from template_migration_research import evolve_pair
            g, s, _trace = evolve_pair(rng, migration=True)
            print(json.dumps({"ok": True, "profile": "generalist", "genome": g,
                              "score": round(s, 3), "seed": seed}))
            return 0
        # engine's own loop returns ([(fitness, genome, measure), ...], history)
        try:
            scored, _history = ge.evolve(profile, rng)
            score, champ, _m = scored[0]
            print(json.dumps({"ok": True, "profile": profile, "genome": champ,
                              "score": round(score, 3), "seed": seed}))
            return 0
        except Exception:
            pass
        # fallback: tiny tournament in-process
        popl = [ge.make_genome(rng) for _ in range(pop)]
        best, best_s = None, -1e9
        for _ in range(gens):
            scored = []
            for g in popl:
                data, slots = ge.compile_gallery(dict(g), gid="lab")
                s = ge.fitness(profile, ge.measure(data, slots))
                scored.append((s, g))
                if s > best_s:
                    best, best_s = g, s
            scored.sort(key=lambda x: -x[0])
            keep = [g for _, g in scored[: max(2, pop // 3)]]
            popl = keep + [ge.mutate(rng, dict(rng.choice(keep))) for _ in range(pop - len(keep))]
        print(json.dumps({"ok": True, "profile": profile, "genome": best,
                          "score": round(best_s, 3), "seed": seed}))
        return 0

    if flag("compile"):
        gj = arg("genome-json")
        genome = json.loads(gj) if gj else ge.make_genome(rng)
        name = arg("name", "TemplateLab_Live")
        print(json.dumps(compile_one(genome, name)))
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
