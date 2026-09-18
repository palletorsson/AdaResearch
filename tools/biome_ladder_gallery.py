#!/usr/bin/env python3
"""biome_ladder_gallery.py — the biome object scaled down to primitives, and morphed back.

Generation 14 gave the object a `stage` (the ladder's words gate every layer, as in the cage)
and a `phase` (the newest layer absent → growing → grown). This renders two strips through
the DNA sweep rig and publishes them as /biome-ladder in the encyclopedia:

  ladder   one DNA at every hall of the walk (Point_One … Random_Game) and then the later
           sequences (noise, cellularautomata, fractals, lsystems, proceduralgeneration,
           softbodies, swarmintelligence, machinelearning, graphtheory) and `full`, phase 1
  morph    the same DNA at three halls with phase 1.0, 0.75, 0.5, 0.25, 0.0 — the world
           un-growing to the hall before

  python tools/biome_ladder_gallery.py                # seed 7's DNA, both strips
  python tools/biome_ladder_gallery.py --dna 11       # another of the six DNAs by seed
  python tools/biome_ladder_gallery.py --skip-render  # republish from ada_run/biome_ladder

Output: ada_run/biome_ladder/<strip>/*.png, ada_encyclopedia/public/biome-ladder/manifest.json
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import biome_rsi as rsi  # noqa: E402  (the six DNAs, the rig call, the slug conventions)

SLUG = "biome-ladder"
GAL = rsi.ENC / "public" / SLUG
RUN = REPO / "ada_run" / "biome_ladder"
VOCAB = REPO / "commons" / "data" / "biome_vocabulary.json"
LATER = ["noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration", "softbodies",
         "swarmintelligence", "machinelearning", "graphtheory"]
MORPH_HALLS = ["Trans_Translation", "Color_Rainbow", "Random_Mushrooms"]
PHASES = [1.0, 0.75, 0.5, 0.25, 0.0]


def halls() -> list[str]:
    d = json.loads(VOCAB.read_text(encoding="utf-8"))
    return list(d["halls"].keys())


def dna_by_seed(seed: int):
    for d in rsi.DNAS:
        if d[0] == seed:
            return d
    return rsi.DNAS[0]


def variant(d, stage: str, phase: float) -> dict:
    seed, m, r, w = d
    label = "%s__%s_p%03d" % (rsi.label_of(d), stage, round(phase * 100))
    return {"label": label, "params": {"seed": seed, "size": rsi.SIZE, "moisture": m, "relief": r, "wildness": w,
                                       "record": "on", "stage": stage, "phase": phase}}


def render(strip: str, variants: list[dict], grace: int) -> int:
    out = RUN / strip
    out.mkdir(parents=True, exist_ok=True)
    for old in list(out.glob("*.png")) + [out / "_done.txt", out / "_rejects.json"]:
        if old.exists():
            old.unlink()
    spec = {"scene": rsi.SCENE, "out_dir": f"res://ada_run/biome_ladder/{strip}", "yaw": rsi.YAW, "pitch": rsi.PITCH,
            "framing": rsi.FRAMING, "fixed_camera": True, "variants": variants}
    spec_p = RUN / f"spec_{strip}.json"
    spec_p.write_text(json.dumps(spec, indent=1), encoding="utf-8")
    args = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"), f"--expect={out}", f"--grace={grace}",
            "--stall=120", "--", rsi.GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
            "--script", "res://commons/testing/capture_config_sweep.gd", "--",
            f"--spec=res://ada_run/biome_ladder/spec_{strip}.json"]
    t0 = time.time()
    r = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=3600)
    n = len(list(out.glob("*.png")))
    print(f"  [{strip}] {n}/{len(variants)} frames in {time.time() - t0:.0f}s (watchdog exit {r.returncode})")
    rej = out / "_rejects.json"
    if rej.exists():
        rj = json.loads(rej.read_text(encoding="utf-8"))
        if int(rj.get("rejected", 0)) > 0:
            print(f"  [{strip}] REJECTED PARAMS — read {rej}")
    return n


def publish(d, gen: int) -> None:
    GAL.mkdir(parents=True, exist_ok=True)
    entries = []
    order = 0
    stages = halls() + LATER + ["full"]
    for i, stage in enumerate(stages):
        v = variant(d, stage, 1.0)
        src = RUN / "ladder" / f"{v['label']}.png"
        if not src.exists():
            continue
        order += 1
        fid = v["label"]
        shutil.copyfile(src, GAL / f"{fid}.png")
        cfg = {"id": fid, "strip": "ladder", "stage": stage, "phase": 1.0, "index": i, "generation": gen,
               "dna": {"seed": d[0], "moisture": d[1], "relief": d[2], "wildness": d[3], "size": rsi.SIZE},
               "token": "biome_object:0#seed:%d#size:%d#moisture:%.2f#relief:%.2f#wildness:%.2f#stage:%s" % (d[0], rsi.SIZE, d[1], d[2], d[3], stage)}
        (GAL / f"{fid}.json").write_text(json.dumps(cfg, indent=2), encoding="utf-8")
        entries.append({"id": fid, "image": f"/{SLUG}/{fid}.png", "config": f"/{SLUG}/{fid}.json",
                        "strip": "the ladder — one DNA, every stage of the walk, phase 1", "order": order,
                        "notes": f"{i}. {stage.replace('_', ' ')} · seed {d[0]}"})
    for hall in MORPH_HALLS:
        for ph in PHASES:
            v = variant(d, hall, ph)
            src = RUN / "morph" / f"{v['label']}.png"
            if not src.exists():
                continue
            order += 1
            fid = v["label"]
            shutil.copyfile(src, GAL / f"{fid}.png")
            cfg = {"id": fid, "strip": "morph", "stage": hall, "phase": ph, "generation": gen,
                   "dna": {"seed": d[0], "moisture": d[1], "relief": d[2], "wildness": d[3], "size": rsi.SIZE},
                   "token": "biome_object:0#seed:%d#size:%d#moisture:%.2f#relief:%.2f#wildness:%.2f#stage:%s#phase:%.2f" % (d[0], rsi.SIZE, d[1], d[2], d[3], hall, ph)}
            (GAL / f"{fid}.json").write_text(json.dumps(cfg, indent=2), encoding="utf-8")
            entries.append({"id": fid, "image": f"/{SLUG}/{fid}.png", "config": f"/{SLUG}/{fid}.json",
                            "strip": f"the morph — {hall.replace('_', ' ')}, phase 1 → 0 (un-growing to the hall before)",
                            "order": order, "notes": f"{hall.replace('_', ' ')} · phase {ph:.2f} · seed {d[0]}"})
    desc = ("The biome object scaled down to primitives and morphed back. Generation %d gave the object a stage — "
            "the ladder's words gate every layer, as in the glass cage: a flat plane and one point at Point One, a "
            "line, a lattice, a face, solids, the pool, relief with translation, colour, flowers, chance, fungus, "
            "then noise, trees at L-systems, residents at machine learning — and a phase, the newest layer absent, "
            "growing, grown. The ladder strip is one DNA at every stage; the morph strips run a hall's phase from 1 "
            "to 0, the world un-growing to the hall before. Click a tile for its token." % gen)
    (GAL / "manifest.json").write_text(json.dumps({"version": 1, "schema_version": 1, "description": desc,
                                                   "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
                                                   "tool": "tools/biome_ladder_gallery.py", "entries": entries},
                                                  indent=1), encoding="utf-8")
    if not (GAL / "evals.json").exists():
        (GAL / "evals.json").write_text("{}", encoding="utf-8")
    print(f"published {len(entries)} tiles -> {GAL}")
    print(f"page: http://127.0.0.1:3003/{SLUG}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dna", type=int, default=7)
    ap.add_argument("--skip-render", action="store_true")
    ap.add_argument("--grace", type=int, default=600)
    a = ap.parse_args()
    d = dna_by_seed(a.dna)
    gen, _ = rsi.code_generation()
    if not a.skip_render:
        ladder = [variant(d, s, 1.0) for s in halls() + LATER + ["full"]]
        print(f"ladder: {len(ladder)} stages")
        render("ladder", ladder, a.grace)
        morph = [variant(d, h, ph) for h in MORPH_HALLS for ph in PHASES]
        print(f"morph: {len(morph)} frames")
        render("morph", morph, a.grace)
    publish(d, gen)
    return 0


if __name__ == "__main__":
    sys.exit(main())
