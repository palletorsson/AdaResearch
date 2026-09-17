#!/usr/bin/env python3
"""dream_biome.py — the biome's dream: replay what the cages recorded, and run what they never did.

Design: doc/COMBINATORY_BIOME.md §6 (after Dream-RSI, arXiv:2609.14858: a recorded history as a
replay world). The record is ada_run/biome_lineage.jsonl, written by commons/artifacts/
biome_vitrine — one line per organism event (cage, seeded, spawned, born, culled, generation).
This tool never edits it.

  python tools/dream_biome.py report [--stage X] [--run R] [--session S]
      every cage in the log: generations, born / culled, survivors by kingdom at the end
  python tools/dream_biome.py stale [--stage X]
      kingdoms present in a cage's record with no survivor at its last generation; lineages
      (born ids) with no living descendant at the end
  python tools/dream_biome.py sufficient [--stage X]
      the smallest set of kingdom words that accounts for every survivor (a set cover over
      four words — small, and honest about being one)
  python tools/dream_biome.py reachable <stage>
      the closure — what the vocabulary allows at that stage (mirrors biome_grammar.gd)
  python tools/dream_biome.py counterfactual --stage X --allow W [--seed 7] [--generations 6] [--size 8]
      run the cage at stage X twice, headless, with the same seed: as recorded (baseline) and
      with the word W granted (the injection); report the difference. This is the one thing a
      frozen replay cannot do; here a generation of critters is cheap, so it runs.

Every empirical answer is tagged with the fitness it was measured under (`fitness_fn` in the
cage row): a kingdom that never survives under `default` may survive under another.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.join(REPO, "ada_run", "biome_lineage.jsonl")
LOG_USER = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Ada Research Zero One", "biome_lineage.jsonl")
VOCAB = os.path.join(REPO, "commons", "data", "biome_vocabulary.json")
SPINE = os.path.join(REPO, "commons", "maps", "curriculum_spine.json")
AUTHORED = os.path.join(REPO, "commons", "data", "map_authored.json")
GODOT = os.environ.get("ADA_GODOT", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
KINGDOMS = ["tree", "creature", "flower", "fungus"]


# ── the record ─────────────────────────────────────────────────────────────────

def read_log(paths=(LOG, LOG_USER)) -> list[dict]:
    rows: list[dict] = []
    for p in paths:
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return rows


def cages_of(rows: list[dict], stage: str | None = None, run: str | None = None, session: str | None = None) -> dict[str, list[dict]]:
    """Group rows by (session, cage): one cage build = one key."""
    out: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        if stage and r.get("stage") != stage:
            continue
        if run and r.get("run") != run:
            continue
        if session and r.get("session") != session:
            continue
        out["%s | %s" % (r.get("session", "?"), r.get("cage", "?"))].append(r)
    return out


def summarize(rows: list[dict]) -> dict:
    head = next((r for r in rows if r.get("event") == "cage"), {})
    gens = [r for r in rows if r.get("event") == "generation"]
    last = gens[-1] if gens else None
    born = [r for r in rows if r.get("event") == "born"]
    culled = [r for r in rows if r.get("event") == "culled"]
    seeded = [r for r in rows if r.get("event") == "seeded"]
    spawned = [r for r in rows if r.get("event") == "spawned"]
    # survivors: the live population at the last generation (creatures breed and are culled),
    # PLUS the seeded organisms — a painted flower or colony stands until the cage is rebuilt;
    # it is not in the breeder's population and must not read as dead
    survivors = last["population"] if last else [{"id": r["id"], "kingdom": r["kingdom"]} for r in spawned]
    by_k: dict[str, int] = defaultdict(int)
    for s in survivors:
        by_k[s.get("kingdom", "?")] += 1
    seeded_k: dict[str, int] = defaultdict(int)
    for s in seeded:
        seeded_k[s.get("kingdom", "?")] += 1
        by_k[s.get("kingdom", "?")] += 1
    return {
        "stage": head.get("stage"), "sequence": head.get("sequence"), "seed": head.get("seed"),
        "allow": head.get("allow", ""), "run": head.get("run", ""), "fitness_fn": head.get("fitness_fn", "default"),
        "family": head.get("family"), "closure": head.get("closure", {}),
        "generations": len(gens), "born": len(born), "culled": len(culled),
        "seeded": dict(seeded_k), "spawned": len(spawned), "survivors": dict(by_k),
        "avg_fitness_last": last.get("avg_fitness") if last else None, "forced": bool(last.get("forced")) if last else None,
        "rows": len(rows),
    }


# ── the vocabulary (mirrors biome_grammar.gd) ───────────────────────────────────

def load_walk() -> tuple[dict, list[str], dict[str, list[str]]]:
    vocab = json.load(open(VOCAB, encoding="utf-8"))
    sp = json.load(open(SPINE, encoding="utf-8"))
    sp = sp.get("spine", sp)
    spine = [s["name"] for s in sp.get("sequences", []) if s.get("name")]
    halls = {k: list(v) for k, v in json.load(open(AUTHORED, encoding="utf-8")).items() if isinstance(v, list)}
    return vocab, spine, halls


def position_of(stage: str, spine: list[str], halls: dict[str, list[str]]) -> dict:
    for seq, maps in halls.items():
        if stage in maps:
            return {"known": True, "sequence": seq, "spine": spine.index(seq) if seq in spine else -1, "hall": maps.index(stage), "is_hall": True}
    if stage in spine:
        return {"known": True, "sequence": stage, "spine": spine.index(stage), "hall": len(halls.get(stage, [])) - 1, "is_hall": False}
    return {"known": False, "sequence": "", "spine": -1, "hall": -1, "is_hall": False}


def closure(stage: str) -> dict:
    vocab, spine, halls = load_walk()
    pos = position_of(stage, spine, halls)
    out = {"made_of": [], "does": [], "knows": [], "position": pos}
    if not pos["known"]:
        return out

    def merge(entry: dict) -> None:
        for col in ("made_of", "does", "knows"):
            for w in entry.get(col, []) or []:
                if w not in out[col]:
                    out[col].append(w)

    for si, seq in enumerate(spine):
        if si > pos["spine"]:
            break
        merge(vocab["sequences"].get(seq, {}))
        for hi, m in enumerate(halls.get(seq, [])):
            if si == pos["spine"] and pos["hall"] >= 0 and hi > pos["hall"]:
                break
            merge(vocab["halls"].get(m, {}))
    return out


# ── the questions ──────────────────────────────────────────────────────────────

def cmd_report(args) -> None:
    groups = cages_of(read_log(), args.stage, args.run, args.session)
    if not groups:
        print("no lineage rows (ada_run/biome_lineage.jsonl or the user:// copy) match")
        return
    print("%-22s %-12s %5s %4s %5s %6s %6s  %-38s %s" % ("stage", "run", "seed", "gens", "born", "culled", "surv", "survivors by kingdom", "fitness"))
    for key, rows in sorted(groups.items(), key=lambda kv: (kv[1][0].get("t", ""), kv[0])):
        s = summarize(rows)
        surv = sum(s["survivors"].values())
        print("%-22s %-12s %5s %4d %5d %6d %6d  %-38s %s%s" % (
            (s["stage"] or "?")[:22], (s["run"] or "-")[:12], s["seed"], s["generations"], s["born"], s["culled"], surv,
            ", ".join("%d %s" % (v, k) for k, v in sorted(s["survivors"].items())) or "-",
            s["fitness_fn"], (" (allow %s)" % s["allow"]) if s["allow"] else ""))


def cmd_stale(args) -> None:
    groups = cages_of(read_log(), args.stage)
    for key, rows in groups.items():
        s = summarize(rows)
        if s["generations"] == 0:
            continue
        present = set(s["seeded"].keys()) | {r.get("kingdom") for r in rows if r.get("event") in ("spawned", "born")}
        alive = set(s["survivors"].keys())
        stale_k = sorted(k for k in present if k and k not in alive)
        # lineages: born ids with no living descendant at the end
        last = [r for r in rows if r.get("event") == "generation"][-1]
        living = {p["id"] for p in last["population"]}
        parents_of = {r["id"]: r.get("parents", []) for r in rows if r.get("event") == "born"}
        ancestors_alive: set[str] = set()
        for lid in living:
            stack = [lid]
            while stack:
                x = stack.pop()
                if x in ancestors_alive:
                    continue
                ancestors_alive.add(x)
                stack.extend(parents_of.get(x, []))
        dead_lines = sorted(i for i in parents_of if i not in ancestors_alive)
        print("%s — stage %s, %d generations under fitness `%s`:" % (key, s["stage"], s["generations"], s["fitness_fn"]))
        print("   stale kingdoms (present, no survivor): %s" % (", ".join(stale_k) or "none"))
        print("   lineages with no living descendant: %d of %d born" % (len(dead_lines), len(parents_of)))


def cmd_sufficient(args) -> None:
    groups = cages_of(read_log(), args.stage)
    for key, rows in groups.items():
        s = summarize(rows)
        if s["generations"] == 0:
            continue
        surv = s["survivors"]
        # greedy set cover over kingdom words (each survivor is covered by its own kingdom word)
        chosen: list[str] = []
        remaining = dict(surv)
        while remaining:
            best = max(remaining, key=lambda k: remaining[k])
            chosen.append(best)
            del remaining[best]
        closure_words = s["closure"].get("made_of", []) + s["closure"].get("does", []) + s["closure"].get("knows", [])
        unused = [w for w in closure_words if w in KINGDOMS and w not in chosen]
        print("%s — stage %s: sufficient kingdom words %s; allowed but unused at the end: %s (fitness `%s`)" % (
            key, s["stage"], chosen or ["none"], unused or ["none"], s["fitness_fn"]))


def cmd_reachable(args) -> None:
    c = closure(args.stage)
    if not c["position"]["known"]:
        print("%s is neither a hall nor a sequence of the ladder" % args.stage)
        return
    print("closure at %s (%s, spine %d, hall %d):" % (args.stage, c["position"]["sequence"], c["position"]["spine"], c["position"]["hall"]))
    for col in ("made_of", "does", "knows"):
        print("  %-8s %s" % (col, " ".join(c[col]) or "—"))
    vocab, _, _ = load_walk()
    all_words: set[str] = set()
    for src in ("halls", "sequences"):
        for entry in vocab[src].values():
            for col in ("made_of", "does", "knows"):
                all_words.update(entry.get(col, []) or [])
    not_yet = sorted(all_words - set(c["made_of"]) - set(c["does"]) - set(c["knows"]))
    print("  not yet: %s" % (" ".join(not_yet) or "—"))


def run_dream(stage: str, seed: int, gens: int, size: int, allow: str, label: str) -> dict:
    cmd = [GODOT, "--headless", "--path", REPO, "--xr-mode", "off", "--script",
           "res://commons/testing/run_biome_dream.gd", "--",
           "--stage=%s" % stage, "--seed=%d" % seed, "--generations=%d" % gens, "--size=%d" % size,
           "--run=%s" % label]
    if allow:
        cmd.append("--allow=%s" % allow)
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=300, cwd=REPO)
    for line in (out.stdout + out.stderr).splitlines():
        if line.startswith("[dream] "):
            return json.loads(line[len("[dream] "):])
    raise SystemExit("the runner printed no [dream] line; last lines:\n" + "\n".join((out.stdout + out.stderr).splitlines()[-12:]))


def cmd_counterfactual(args) -> None:
    base = run_dream(args.stage, args.seed, args.generations, args.size, "", "baseline")
    inj = run_dream(args.stage, args.seed, args.generations, args.size, args.allow, "allow-%s" % args.allow)
    print("counterfactual at %s, seed %d, %d generations, fitness `default`:" % (args.stage, args.seed, args.generations))
    print("  %-16s %-28s %-28s" % ("", "as recorded", "with `%s`" % args.allow))
    for k, label in (("closure", "closure made of"), ("kingdoms", "kingdoms"), ("seeds", "seeds"),
                     ("live_before", "live at build"), ("live_after", "live at the end"),
                     ("births", "born"), ("deaths", "culled"), ("by_kingdom", "survivors")):
        b = base.get(k)
        i = inj.get(k)
        if k == "closure":
            b = " ".join(b.get("made_of", [])) if isinstance(b, dict) else b
            i = " ".join(i.get("made_of", [])) if isinstance(i, dict) else i
        print("  %-16s %-28s %-28s%s" % (label, str(b)[:28], str(i)[:28], "" if b == i else "   <- differs"))
    print("  presence        %s / %s" % (
        " ".join("%s %d%%" % (k, round(v * 100)) for k, v in base.get("presence", {}).items()),
        " ".join("%s %d%%" % (k, round(v * 100)) for k, v in inj.get("presence", {}).items())))
    print("  lineage rows written: baseline %s, injected %s" % (base.get("lineage", {}).get("rows"), inj.get("lineage", {}).get("rows")))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("report"); r.add_argument("--stage"); r.add_argument("--run"); r.add_argument("--session")
    s = sub.add_parser("stale"); s.add_argument("--stage")
    u = sub.add_parser("sufficient"); u.add_argument("--stage")
    c = sub.add_parser("reachable"); c.add_argument("stage")
    x = sub.add_parser("counterfactual"); x.add_argument("--stage", required=True); x.add_argument("--allow", required=True)
    x.add_argument("--seed", type=int, default=7); x.add_argument("--generations", type=int, default=6); x.add_argument("--size", type=int, default=8)
    args = p.parse_args()
    {"report": cmd_report, "stale": cmd_stale, "sufficient": cmd_sufficient, "reachable": cmd_reachable,
     "counterfactual": cmd_counterfactual}[args.cmd](args)


if __name__ == "__main__":
    main()
