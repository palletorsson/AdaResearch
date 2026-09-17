#!/usr/bin/env python3
"""Biome gallery auto-research generator — one cage, seven composition families, the ladder.

The biome cage (commons/artifacts/biome_vitrine) draws ONE composition per seed and the
halls of the ladder are its states: a grey point in Point_One, a line, a lattice, planes,
colour with the rainbow, chance with the randomness halls. The seed picks a FAMILY — where
the same elements fall. Three families were built into the cage; four more were written by
four agents who never saw each other's, to one contract (commons/biome_layers/families/).

This tool is the surreal-lab loop applied to the cage (tools/generate_surreal_lab_configs.py):
breed specimens by DATA, render them all in ONE Godot boot through the DNA sweep rig
(commons/testing/capture_config_sweep.gd), then publish a GalleryView manifest with the DNA
under every tile. Two sections:

  ladder   every family x every hall of the ladder x seed 7 — the same work growing seven
           ways, one tile per state. Nothing is culled here: the ladder IS the argument.
  bred     the fullest state (the last hall) x every family x N seeds, and per family the
           three seeds that look LEAST alike are kept (farthest-first on pixel distance,
           selection "farthest-first-v1"). The culled ones stay in the manifest under
           `culled`, with their distances, so the dark spot stays open: this is a fact
           about that selection, not about the seeds.

It also measures the thing the fan-out claims — that the families differ: for every hall,
the mean pairwise pixel difference between the seven family tiles (doc/reports/
biome_family_bite.json). A family that measures alike to another would be decoration.

Usage (from the repo root; one Godot boot per section, serialised):
  python tools/generate_biome_gallery.py --smoke                 # 3 tiles, check the camera
  python tools/generate_biome_gallery.py                         # both sections
  python tools/generate_biome_gallery.py --section=ladder
  python tools/generate_biome_gallery.py --section=bred --seeds=12
  python tools/generate_biome_gallery.py --skip-render           # re-score + re-publish
  python tools/generate_biome_gallery.py --families=klee,moholy --halls=Random_Game

Output:
  ada_run/biome_sweep/<section>/<label>.png            the frames (derived, not tracked)
  ada_encyclopedia/public/biome-gallery/manifest.json  + <label>.png + <label>.json
  doc/reports/biome_family_bite.json                   the family-difference measurement
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ENC = Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
GAL = ENC / "public" / "biome-gallery"
SWEEP = REPO / "ada_run" / "biome_sweep"
GODOT = r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
SCENE = "res://commons/artifacts/biome_vitrine/biome_vitrine.tscn"
VOCAB = REPO / "commons" / "data" / "biome_vocabulary.json"
FAM_DIR = REPO / "commons" / "biome_layers" / "families"
REPORT = REPO / "doc" / "reports" / "biome_family_bite.json"

# The three families built into the cage, with the references its own comments give.
BUILTIN = {
    "diagonal": ("El Lissitzky, Proun (1919-24)",
                 "A dominant diagonal across the floor, its golden section the focus, the planes tilted along it."),
    "vertical": ("El Lissitzky, Proun tower",
                 "A short axis and everything lifted: the work stands up, the planes laid flat and high, the beam high."),
    "split": ("Piet Mondrian, Composition with fields (1921)",
              "The floor divided at golden sections, axes parallel to the walls, the planes standing nearly upright and low."),
}
FILE_FAMILIES = ["kandinsky", "malevich", "klee", "moholy"]
ALL_FAMILIES = list(BUILTIN) + FILE_FAMILIES
LAST_HALL = "Random_Game"
DIFF_T = 24          # a pixel "differs" when any channel moves more than this (0-255)
PITCH = -0.62        # steeper than the canonical -0.26: the cage is open at the top
YAW = 0.62
FRAMING = 0.98


def family_meta(name: str) -> tuple[str, str, bool]:
    """(reference, line, present). A file family's constants are read from its script."""
    if name in BUILTIN:
        ref, line = BUILTIN[name]
        return ref, line, True
    p = FAM_DIR / f"{name}.gd"
    if not p.exists():
        return "", "", False
    src = p.read_text(encoding="utf-8", errors="replace")
    ref = re.search(r'const\s+REFERENCE\s*:?=\s*"([^"]*)"', src)
    line = re.search(r'const\s+LINE\s*:?=\s*"([^"]*)"', src)
    return (ref.group(1) if ref else ""), (line.group(1) if line else ""), True


def halls() -> list[tuple[str, list[str]]]:
    d = json.loads(VOCAB.read_text(encoding="utf-8"))
    out = []
    for h, v in d["halls"].items():
        words = list(v.get("made_of", [])) + list(v.get("does", [])) + list(v.get("knows", []))
        out.append((h, words))
    return out


def pretty(hall: str) -> str:
    return hall.replace("_", " ")


def label_of(fam: str, hall: str, seed: int) -> str:
    return f"bio__{fam}__{hall}__s{seed}"


def token_of(fam: str, hall: str, seed: int) -> str:
    return f"biome_vitrine:90#stage:{hall}#size:5#seed:{seed}#family:{fam}#evolve:off"


def variant(fam: str, hall: str, seed: int) -> dict:
    return {"label": label_of(fam, hall, seed),
            "params": {"stage": hall, "seed": seed, "family": fam, "size": 5,
                       "evolve": "off", "record": "off", "controls": "none", "glow": "on",
                       "entry": "off"}}


def write_spec(section: str, variants: list[dict], pitch: float, framing: float) -> Path:
    out_dir = SWEEP / section
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    for old in ("_done.txt", "_rejects.json"):
        if (out_dir / old).exists():
            (out_dir / old).unlink()
    spec = {"scene": SCENE, "out_dir": f"res://ada_run/biome_sweep/{section}",
            "yaw": YAW, "pitch": pitch, "framing": framing, "fixed_camera": True,
            "variants": variants}
    p = SWEEP / f"spec_{section}.json"
    p.write_text(json.dumps(spec, indent=1), encoding="utf-8")
    return p


def render(section: str, spec: Path, grace: int) -> bool:
    out_dir = SWEEP / section
    args = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
            # expect the DIRECTORY: the first PNG is the first result (the fixed-camera pass
            # over every variant comes before it, hence the long grace), and a stall of
            # two minutes between frames means the rig died, not that a cage is slow
            f"--expect={out_dir}", f"--grace={grace}", "--stall=120", "--",
            GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
            "--script", "res://commons/testing/capture_config_sweep.gd", "--",
            f"--spec=res://ada_run/biome_sweep/spec_{section}.json"]
    t0 = time.time()
    r = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=3600)
    dt = time.time() - t0
    n = len(list(out_dir.glob("bio__*.png")))
    print(f"  [{section}] {n} frames in {dt:.0f}s (watchdog exit {r.returncode})")
    rej = out_dir / "_rejects.json"
    if rej.exists():
        try:
            rj = json.loads(rej.read_text(encoding="utf-8"))
            if int(rj.get("rejected", 0)) > 0:
                print(f"  [{section}] REJECTED PARAMS — read {rej}:")
                print("   ", json.dumps(rj)[:600])
        except Exception as e:  # noqa: BLE001
            print(f"  [{section}] could not read {rej}: {e}")
    if r.returncode != 0:
        print((r.stderr or r.stdout or "")[-800:])
    return (out_dir / "_done.txt").exists()


# ── measurement ──────────────────────────────────────────────────────────────────
def load_gray(p: Path):
    from PIL import Image
    import numpy as np
    im = Image.open(p).convert("RGB")
    if im.size != (190, 190):
        im = im.resize((190, 190), Image.BILINEAR)   # 4x down: the distance is about composition
    return np.asarray(im, dtype=np.int16)


def diff_frac(a, b) -> float:
    import numpy as np
    d = np.abs(a - b).max(axis=2)
    return float((d > DIFF_T).mean())


def subject_frac(a) -> float:
    import numpy as np
    bg = a[2, 2]
    d = np.abs(a - bg).max(axis=2)
    return float((d > DIFF_T).mean())


def farthest_first(items: list[tuple[str, object]], k: int) -> tuple[list[str], dict]:
    """Pick k of the items that look least alike: start from the one farthest from the
    mean image, then repeatedly add the one farthest from every pick so far."""
    import numpy as np
    if len(items) <= k:
        return [i for i, _ in items], {}
    mean = np.mean([a for _, a in items], axis=0)
    first = max(items, key=lambda it: diff_frac(it[1], mean))
    picks = [first]
    dist: dict = {}
    while len(picks) < k:
        best, best_d = None, -1.0
        for it in items:
            if it in picks:
                continue
            d = min(diff_frac(it[1], p[1]) for p in picks)
            if d > best_d:
                best, best_d = it, d
        picks.append(best)
    for it in items:
        dist[it[0]] = round(min(diff_frac(it[1], p[1]) for p in picks if p is not it) if it not in picks
                            else min((diff_frac(it[1], p[1]) for p in picks if p is not it), default=0.0), 4)
    return [i for i, _ in picks], dist


# ── main ─────────────────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--section", default="all", choices=["all", "ladder", "bred"])
    ap.add_argument("--families", default="")
    ap.add_argument("--halls", default="")
    ap.add_argument("--seeds", type=int, default=12)
    ap.add_argument("--keep", type=int, default=3)
    ap.add_argument("--smoke", action="store_true")
    ap.add_argument("--skip-render", action="store_true")
    ap.add_argument("--pitch", type=float, default=PITCH)
    ap.add_argument("--framing", type=float, default=FRAMING)
    ap.add_argument("--grace", type=int, default=600)
    a = ap.parse_args()

    fams = [f for f in (a.families.split(",") if a.families else ALL_FAMILIES) if f]
    present = []
    for f in fams:
        ref, line, ok = family_meta(f)
        if not ok:
            print(f"  family `{f}` has no file under {FAM_DIR} — skipped")
            continue
        present.append(f)
    fams = present
    hl = halls()
    if a.halls:
        want = set(a.halls.split(","))
        hl = [h for h in hl if h[0] in want]
    if a.smoke:
        fams = fams[:1]
        hl = [h for h in hl if h[0] in ("Point_One", "Color_Rainbow", LAST_HALL)] or hl[:3]
    sections = ["ladder", "bred"] if a.section == "all" else [a.section]
    if a.smoke:
        sections = ["ladder"]

    # 1. breed
    plan: dict[str, list[dict]] = {}
    if "ladder" in sections:
        plan["ladder"] = [variant(f, h, 7) for f in fams for h, _ in hl]
    if "bred" in sections:
        plan["bred"] = [variant(f, LAST_HALL, s) for f in fams for s in range(11, 11 + a.seeds)]
    for sec, vs in plan.items():
        print(f"{sec}: {len(vs)} variants ({len(fams)} families)")

    # 2. render — one boot per section, serialised
    if not a.skip_render:
        for sec, vs in plan.items():
            spec = write_spec(sec, vs, a.pitch, a.framing)
            ok = render(sec, spec, a.grace)
            if not ok:
                print(f"  [{sec}] no _done.txt — the rig did not finish; publishing what rendered")

    # 3. measure + select
    GAL.mkdir(parents=True, exist_ok=True)
    words = {h: w for h, w in hl}
    entries: list[dict] = []
    culled: list[dict] = []
    bite: dict = {"at": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "threshold": DIFF_T, "seed": 7,
                  "families": fams, "per_hall": {}, "per_pair": {}, "note":
                  "fraction of pixels (190x190 downsample of the 760x760 tile) whose max channel "
                  "moves more than the threshold between two families of the same hall and seed"}
    if "ladder" in plan:
        imgs: dict[tuple[str, str], object] = {}
        for v in plan["ladder"]:
            p = SWEEP / "ladder" / f"{v['label']}.png"
            if p.exists():
                imgs[(v["params"]["family"], v["params"]["stage"])] = load_gray(p)
        pair_acc: dict[str, list[float]] = {}
        for h, _ in hl:
            ds = []
            for i, f1 in enumerate(fams):
                for f2 in fams[i + 1:]:
                    if (f1, h) in imgs and (f2, h) in imgs:
                        d = diff_frac(imgs[(f1, h)], imgs[(f2, h)])
                        ds.append(d)
                        pair_acc.setdefault(f"{f1}|{f2}", []).append(d)
            if ds:
                bite["per_hall"][h] = {"mean": round(sum(ds) / len(ds), 4), "min": round(min(ds), 4),
                                       "max": round(max(ds), 4), "pairs": len(ds)}
        for k, v in pair_acc.items():
            bite["per_pair"][k] = {"mean": round(sum(v) / len(v), 4), "min": round(min(v), 4), "halls": len(v)}
        order = 0
        for f in fams:
            ref, line, _ = family_meta(f)
            for hi, (h, w) in enumerate(hl):
                v = variant(f, h, 7)
                src = SWEEP / "ladder" / f"{v['label']}.png"
                if not src.exists():
                    continue
                order += 1
                entries.append(_entry(v, f, h, 7, hi, "ladder", order, ref, line, w, src,
                                      subject=subject_frac(imgs[(f, h)])))
    if "bred" in plan:
        for f in fams:
            ref, line, _ = family_meta(f)
            cands = []
            for s in range(11, 11 + a.seeds):
                v = variant(f, LAST_HALL, s)
                p = SWEEP / "bred" / f"{v['label']}.png"
                if p.exists():
                    cands.append((v["label"], load_gray(p)))
            keep, dist = farthest_first(cands, a.keep)
            for s in range(11, 11 + a.seeds):
                v = variant(f, LAST_HALL, s)
                src = SWEEP / "bred" / f"{v['label']}.png"
                if not src.exists():
                    continue
                e = _entry(v, f, LAST_HALL, s, len(hl) - 1, "bred", 1000 + s, ref, line,
                           words.get(LAST_HALL, []), src, subject=None)
                e["selection"] = "farthest-first-v1"
                e["nearest_pick"] = dist.get(v["label"])
                if v["label"] in keep:
                    e["rank"] = keep.index(v["label"]) + 1
                    entries.append(e)
                else:
                    culled.append(e)

    # 4. publish
    entries.sort(key=lambda e: (ALL_FAMILIES.index(e["family"]) if e["family"] in ALL_FAMILIES else 99,
                                e["order"]))
    for e in entries + culled:
        src = Path(e.pop("_src"))
        shutil.copyfile(src, GAL / f"{e['id']}.png")
        cfg = {k: e[k] for k in ("id", "family", "reference", "line", "stage", "hall_index", "seed",
                                 "section", "token", "words", "scene")}
        cfg["dna"] = {"stage": e["stage"], "seed": e["seed"], "family": e["family"], "size": 5}
        (GAL / f"{e['id']}.json").write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
    n_l = sum(1 for e in entries if e["section"] == "ladder")
    n_b = sum(1 for e in entries if e["section"] == "bred")
    hall_means = [v["mean"] for v in bite["per_hall"].values()]
    desc = (f"The biome cage's composition families across the ladder — {len(fams)} families x "
            f"{len(hl)} halls at seed 7 ({n_l} tiles), and {n_b} bred seeds of the fullest state kept "
            f"from {n_b + len(culled)} by farthest-first selection ({len(culled)} culled, listed below). "
            + (f"Families differ by {100 * sum(hall_means) / len(hall_means):.1f}% of pixels on average "
               f"per hall (min {100 * min(hall_means):.1f}%, max {100 * max(hall_means):.1f}%). "
               if hall_means else "")
            + "Click a tile for its DNA and the map token that places it.")
    manifest = {"version": 1, "schema_version": 1, "description": desc,
                "generated": time.strftime("%Y-%m-%dT%H:%M:%S"), "tool": "tools/generate_biome_gallery.py",
                "families": {f: {"reference": family_meta(f)[0], "line": family_meta(f)[1]} for f in fams},
                "entries": entries, "culled": culled}
    (GAL / "manifest.json").write_text(json.dumps(manifest, indent=1, ensure_ascii=False), encoding="utf-8")
    if not (GAL / "evals.json").exists():
        (GAL / "evals.json").write_text("{}", encoding="utf-8")
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    if bite["per_hall"]:
        REPORT.write_text(json.dumps(bite, indent=1), encoding="utf-8")
        print(f"family bite -> {REPORT}: per-hall mean {100 * sum(hall_means) / len(hall_means):.1f}%")
        weak = sorted(bite["per_pair"].items(), key=lambda kv: kv[1]["mean"])[:3]
        for k, v in weak:
            print(f"  least different pair {k}: {100 * v['mean']:.1f}% mean over {v['halls']} halls")
    print(f"published {len(entries)} tiles (+{len(culled)} culled) -> {GAL}")
    print("page: http://127.0.0.1:3003/biome-gallery")
    return 0


def _entry(v, f, h, seed, hi, section, order, ref, line, w, src, subject):
    e = {"id": v["label"], "image": f"/biome-gallery/{v['label']}.png",
         "config": f"/biome-gallery/{v['label']}.json",
         "subtitle": f, "family": f, "reference": ref, "line": line,
         "stage": h, "hall_index": hi, "seed": seed, "section": section, "order": order,
         "words": w, "token": token_of(f, h, seed), "scene": SCENE,
         "notes": (f"{f} · {pretty(h)} · seed {seed}" + (f" — {', '.join(w)}" if w else "")
                   + (f" · {line}" if line and hi == 0 else "")),
         "_src": str(src)}
    if subject is not None:
        e["subject_frac"] = round(subject, 4)
    return e


if __name__ == "__main__":
    sys.exit(main())
