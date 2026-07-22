#!/usr/bin/env python3
"""improve_fungus.py — the auto-research loop for mushroom look.

The project's method: every config becomes a PNG, Claude looks at the images
and keeps the better ones. This runs one generation of that loop on a fungus
DNA family.

  # 1. propose: mutate a family's curated presets into N candidates
  python tools/improve_fungus.py propose --family alien_lumen --n 8

  # 2. render: fungus_dna_gallery_lab draws every candidate (one PNG each)
  python tools/improve_fungus.py render        # (or run the lab yourself)

  # 3. Claude judges the candidate PNGs in the scratch dir, then:
  python tools/improve_fungus.py promote --winners cand_03,cand_07
  #   → copies winners over the weakest variants of the family (sibling-safe:
  #     the originals are backed up to fungus_presets/_backup/ first)

Candidates live in a SCRATCH gallery dir the lab renders in isolation, so the
curated set is never touched until `promote`. Mutation perturbs only the
look genes (cap dome, proportions, gill richness, glow, surface, colour),
never body_type; each gene is clamped to a sane range.
"""
import argparse
import copy
import glob
import hashlib
import json
import os
import random
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRESET_DIR = os.path.join(ROOT, "algorithms", "nature_system", "morphology", "fungus_presets")
BACKUP_DIR = os.path.join(PRESET_DIR, "_backup")
# scratch dir the lab renders (must exist for the lab's dir check)
SCRATCH = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "fungus-improve-scratch"))

# gene -> (sigma, lo, hi). Only look genes; body_type/segments held.
GENES = {
    "scale": (0.12, 0.4, 1.4),
    "part_curve": (0.15, 0.0, 1.0),   # cap dome flat→convex→conical
    "part_width": (0.12, 0.3, 1.0),   # cap diameter
    "part_length": (0.15, 0.3, 1.2),  # stem height
    "part_taper": (0.15, 0.0, 1.0),
    "symmetry": (1.2, 3.0, 10.0),     # gill/pore count
    "edge_type": (0.15, 0.0, 1.0),
    "leaf_density": (0.15, 0.1, 0.9), # spore density
    "transparency": (0.08, 0.0, 0.5),
    "iridescence": (0.12, 0.0, 1.0),  # glow
    "roughness": (0.12, 0.2, 0.9),
    "pattern_type": (0.2, 0.0, 1.0),
    "pattern_density": (0.15, 0.0, 0.8),
}
COLOR_SIGMA = 0.06


def _clampf(v, lo, hi):
    return max(lo, min(hi, v))


def mutate(base, rng):
    out = copy.deepcopy(base)
    for g, (sig, lo, hi) in GENES.items():
        if g in out:
            out[g] = round(_clampf(float(out[g]) + rng.gauss(0, sig), lo, hi), 4)
    for k in ["primary_color", "secondary_color", "tertiary_color"]:
        if k in out and isinstance(out[k], list) and len(out[k]) >= 3:
            out[k] = [round(_clampf(c + rng.gauss(0, COLOR_SIGMA), 0.0, 1.0), 4) for c in out[k][:3]]
    return out


def cmd_propose(args):
    bases = sorted(glob.glob(os.path.join(PRESET_DIR, f"fd_{args.family}_*.json")))
    if not bases:
        raise SystemExit(f"no curated presets for family {args.family}")
    os.makedirs(SCRATCH, exist_ok=True)
    # clear old candidates
    for f in glob.glob(os.path.join(SCRATCH, "*")):
        os.remove(f)
    rng = random.Random(int(hashlib.sha1(args.family.encode()).hexdigest(), 16))
    # candidate 0 = the current best (control), rest = mutations of random bases
    for i in range(args.n):
        base = json.load(open(bases[i % len(bases)], encoding="utf-8"))
        cand = base if i == 0 else mutate(base, rng)
        cid = "fd_cand_%02d" % i
        cand["_id"] = cid
        cand["_cluster"] = args.family
        cand["body_type"] = 3.0
        cand.pop("_deform", None)
        json.dump(cand, open(os.path.join(SCRATCH, cid + ".json"), "w", encoding="utf-8"), indent=2)
    print(f"proposed {args.n} candidates for '{args.family}' -> {SCRATCH}")
    print("candidate 00 is the unchanged control.")
    print("render:  python tools/improve_fungus.py render")


def cmd_render(args):
    import subprocess
    godot = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
    watchdog = os.path.join(ROOT, "tools", "godot_watchdog.py")
    import sys
    cmd = [sys.executable, watchdog, "--grace=90", "--stall=40",
           "--expect=" + SCRATCH, "--",
           godot, "--path", ".", "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/fungus_dna_gallery_lab.gd",
           "--", "--gallery-dir=" + SCRATCH.replace("\\", "/")]
    r = subprocess.run(cmd, cwd=ROOT)
    pngs = glob.glob(os.path.join(SCRATCH, "*.png"))
    print(f"rendered {len(pngs)} candidate PNGs in {SCRATCH} (rc={r.returncode})")
    print("judge them, then: python tools/improve_fungus.py promote --family <f> --winners cand_03,cand_07")


def cmd_promote(args):
    winners = [w.strip() for w in args.winners.split(",") if w.strip()]
    winners = [w if w.startswith("fd_") else "fd_" + w for w in winners]
    bases = sorted(glob.glob(os.path.join(PRESET_DIR, f"fd_{args.family}_*.json")))
    if not bases:
        raise SystemExit(f"no curated presets for family {args.family}")
    os.makedirs(BACKUP_DIR, exist_ok=True)
    # replace the LAST N variants (the weakest by convention — the loop keeps
    # the low-numbered curated ones and overwrites the tail with winners)
    targets = bases[-len(winners):]
    for win, target in zip(winners, targets):
        src = os.path.join(SCRATCH, win + ".json")
        if not os.path.isfile(src):
            print(f"  SKIP {win}: not in scratch")
            continue
        shutil.copy2(target, os.path.join(BACKUP_DIR, os.path.basename(target)))
        cand = json.load(open(src, encoding="utf-8"))
        cand["_id"] = os.path.basename(target)[:-5]
        cand["_cluster"] = args.family
        json.dump(cand, open(target, "w", encoding="utf-8"), indent=2)
        print(f"  promoted {win} -> {os.path.basename(target)} (backup saved)")
    print("done. recapture the gallery to see the improved family.")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("propose"); p.add_argument("--family", required=True); p.add_argument("--n", type=int, default=8)
    sub.add_parser("render")
    q = sub.add_parser("promote"); q.add_argument("--family", required=True); q.add_argument("--winners", required=True)
    args = ap.parse_args()
    {"propose": cmd_propose, "render": cmd_render, "promote": cmd_promote}[args.cmd](args)


if __name__ == "__main__":
    main()
