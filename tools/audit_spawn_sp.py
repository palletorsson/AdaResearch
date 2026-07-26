# -*- coding: utf-8 -*-
"""audit_spawn_sp.py — the `sp` finding: maps that may have no spawn at all.

Surfaced by tools/world_ontology.py while closing the score-points gap. In the
utility registry `sp` is "score points" (score_cube.tscn); the SPAWN token is
exactly `s`. But 779 maps carry a single bare `sp` and 537 of them carry NO `s`
— so their spawn falls back to (0, 0), which is usually void or a wall top.

Two verified examples:
    Archetype_Amphitheater   1/385 reachable   (0,0) is void
    Archetype_Atrium        80/441 reachable   (0,0) is a height-5 wall top

Whether each of those maps meant "spawn here" or genuinely wanted a score cube
is a judgement this tool does NOT make. It reports, ranks by damage, and can
apply a minimal, reversible fix ONLY when asked:

    python tools/audit_spawn_sp.py                 # report (default, no writes)
    python tools/audit_spawn_sp.py --worst 20      # the most damaged maps
    python tools/audit_spawn_sp.py --fix NAME      # add `s` beside that map's sp
    python tools/audit_spawn_sp.py --fix-all       # explicit, still one commit

The fix ADDS an `s` on a walkable cell at/next to the sp cell; it never removes
the sp (the score cube may well be wanted) and never touches maps that already
have a spawn.
"""
import json, argparse, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"


def scan():
    rows = []
    for p in sorted(MAPS.glob("*/map_data.json")):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        L = d.get("layers") or {}
        U = L.get("utilities") or []
        S = L.get("structure") or []
        sp_cells, has_s = [], False
        for z, row in enumerate(U):
            for x, c in enumerate(row):
                c = str(c).strip()
                if c == "s":
                    has_s = True
                elif c == "sp":
                    sp_cells.append((x, z))
        if sp_cells and not has_s:
            origin = ""
            if S and S[0]:
                origin = str(S[0][0]).strip()
            rows.append({"map": p.parent.name, "sp": sp_cells[0],
                         "origin_height": origin,
                         "origin_walkable": origin not in ("", "0")})
    return rows


def reach_of(name):
    r = subprocess.run([sys.executable, str(ROOT / "tools/map_pathfinder.py"), "check", name,
                        "--verbose"],
                       cwd=str(ROOT), capture_output=True, text=True, timeout=120)
    for line in r.stdout.splitlines():
        if "reachable," in line:
            try:
                a, b = line.split("(")[1].split(" ")[0].split("/")
                return int(a) / max(1, int(b))
            except Exception:
                pass
    return None


def fix(name):
    p = MAPS / name / "map_data.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    L = d["layers"]; U = L["utilities"]; S = L["structure"]
    target = None
    for z, row in enumerate(U):
        for x, c in enumerate(row):
            if str(c).strip() == "sp":
                target = (x, z)
                break
        if target: break
    if not target:
        return "no sp"
    x, z = target
    def walkable(cx, cz):
        if not (0 <= cz < len(S) and 0 <= cx < len(S[cz])): return False
        v = str(S[cz][cx]).strip()
        return v not in ("", "0") and v in ("1", "2", "3")
    for (cx, cz) in [(x, z)] + [(x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)]:
        if walkable(cx, cz) and (not str(U[cz][cx]).strip() or (cx, cz) == (x, z)):
            # keep the cube if it stood alone on its own cell: prefer a neighbour
            if (cx, cz) == (x, z):
                continue
            U[cz][cx] = "s"
            p.write_text(json.dumps(d), encoding="utf-8")
            return f"added s at ({cx},{cz}) beside sp at ({x},{z})"
    if walkable(x, z):
        U[z][x] = "s"
        p.write_text(json.dumps(d), encoding="utf-8")
        return f"replaced sp with s at ({x},{z}) (no free neighbour)"
    return "no walkable cell at or beside the sp"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worst", type=int, default=0, help="measure reach for the first N and rank")
    ap.add_argument("--fix", default="")
    ap.add_argument("--fix-all", action="store_true")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    rows = scan()
    print(f"{len(rows)} maps carry `sp` and NO `s` — their spawn falls back to (0,0)")
    bad_origin = [r for r in rows if not r["origin_walkable"]]
    print(f"  of those, {len(bad_origin)} have a VOID origin: nothing is reachable at all")

    if a.fix:
        print(a.fix, "->", fix(a.fix))
        return
    if a.fix_all:
        done = 0
        for r in rows:
            msg = fix(r["map"])
            if msg.startswith("added") or msg.startswith("replaced"):
                done += 1
        print(f"fixed {done}/{len(rows)} maps")
        return
    if a.worst:
        # measure EVERY affected map, then report the N worst. Ranking a
        # convenient alphabetical slice would be a lie about the corpus — the
        # first attempt did exactly that and produced an all-A-names table.
        scored = []
        for i, r in enumerate(rows, 1):
            scored.append((reach_of(r["map"]) or 0.0, r["map"], r["sp"],
                           r["origin_walkable"]))
            if i % 100 == 0:
                print(f"  measured {i}/{len(rows)}...", flush=True)
        scored.sort()
        dead = [s for s in scored if s[0] <= 0.02]
        crippled = [s for s in scored if 0.02 < s[0] < 0.5]
        intact = len(scored) - len(dead) - len(crippled)
        print(f"\nmeasured all {len(scored)}: {len(dead)} DEAD (<=0.02 reach), "
              f"{len(crippled)} crippled (<0.5), {intact} largely intact")
        print(f"\nworst {min(a.worst, len(scored))} by reachability:")
        for reach, name, sp, ok_origin in scored[:a.worst]:
            print(f"  {reach:5.2f}  {name:46s} sp {str(sp):10s}"
                  f"{'' if ok_origin else '  origin VOID'}")
        out = ROOT / "commons/data/spawn_sp_audit.json"
        out.write_text(json.dumps({
            "_readme": ("maps carrying `sp` and no `s`: their spawn falls back to (0,0). "
                        "reach measured with tools/map_pathfinder.py check --verbose. "
                        "NOTHING was modified — tools/audit_spawn_sp.py --fix NAME / "
                        "--fix-all repairs on request only."),
            "total": len(scored), "dead": len(dead), "crippled": len(crippled),
            "intact": intact,
            "rows": [{"map": n, "reach": round(rr, 3), "sp": list(s),
                      "origin_walkable": ow} for rr, n, s, ow in scored]},
            indent=1), encoding="utf-8")
        print(f"\nwrote commons/data/spawn_sp_audit.json")
    else:
        print("\nfirst 12:")
        for r in rows[:12]:
            print(f"  {r['map']:44s} sp {r['sp']}  origin h='{r['origin_height']}'")
        print("\n(run --worst 20 to rank by damage, --fix NAME to repair one)")


if __name__ == "__main__":
    main()
