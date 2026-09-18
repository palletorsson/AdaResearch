#!/usr/bin/env python3
"""biome_rsi.py — recursive self-improvement of the biome object, on record.

The object is commons/artifacts/biome_object/biome_object.gd. Every generation renders the
SAME six DNAs (so tiles compare across generations), measures each tile, and appends the
generation to ada_run/biome_rsi/lineage.jsonl: what changed (the code's CHANGELOG line), the
measures, the parent, the verdict. A critic (an agent, looking at the tiles) proposes the
next change; a builder applies it and bumps GENERATION; this tool renders, measures and
records; a generation that measures worse than its parent is culled and the code goes back.

The measure is NAMED and it is not the verdict: integration-v1 =
    0.40 * kingdoms_present / 6           (water, mineral, fungus, flora, fauna, cover)
  + 0.30 * min(1, connections / 6)        (fungus cells touching a tree or a flower)
  + 0.30 * min(1, colour_bins / 10)       (distinct hues over the tile's subject pixels)
plus change = fraction of pixels that moved against the parent generation's tile of the
same DNA. A better tile that the measure cannot see is the critic's to argue, and a worse
tile the measure likes is the critic's to refuse — the number is a floor, like the bite.

Usage (repo root; one Godot boot per render):
  python tools/biome_rsi.py render  --gen 0 --note "the object"      # tiles + state + measures + lineage row
  python tools/biome_rsi.py measure --gen 1                            # re-measure (against the parent)
  python tools/biome_rsi.py compare --gen 1 --against 0
  python tools/biome_rsi.py verdict --gen 1 --kept --why "..."         # or --culled
  python tools/biome_rsi.py publish                                    # /biome-rsi, every generation a row

Output:
  ada_run/biome_rsi/gen_<N>/<label>.png, state_<label>.json, measures.json
  ada_run/biome_rsi/lineage.jsonl
  ada_encyclopedia/public/biome-rsi/manifest.json (+ tiles + configs)
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ENC = Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
SLUG = "biome-rsi"
GAL = ENC / "public" / SLUG
RUN = REPO / "ada_run" / "biome_rsi"
STATE = RUN / "state"
LINEAGE = RUN / "lineage.jsonl"
GODOT = r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
SCENE = "res://commons/artifacts/biome_object/biome_object.tscn"
CODE = REPO / "commons" / "artifacts" / "biome_object" / "biome_object.gd"
SIZE = 12
# the six DNAs every generation renders: (seed, moisture, relief, wildness)
DNAS = [(7, 0.50, 0.50, 0.60), (11, 0.80, 0.30, 0.70), (13, 0.30, 0.80, 0.40),
        (17, 0.60, 0.60, 0.90), (19, 0.45, 0.40, 0.50), (23, 0.70, 0.75, 0.80)]
YAW = 0.62
PITCH = -0.55
FRAMING = 0.52     # a 12 m ground is wide and flat: fit-by-diagonal leaves it small at 1.0
DIFF_T = 24


def label_of(d):
    seed, m, r, w = d
    return "s%d_m%02d_r%02d_w%02d" % (seed, round(m * 100), round(r * 100), round(w * 100))


def code_generation() -> tuple[int, str]:
    src = CODE.read_text(encoding="utf-8")
    g = re.search(r"const GENERATION\s*:?=\s*(\d+)", src)
    gen = int(g.group(1)) if g else -1
    lines = re.findall(r'"(gen \d+: [^"]*)"', src)
    last = lines[-1] if lines else ""
    return gen, last


def gen_dir(n: int) -> Path:
    return RUN / f"gen_{n}"


# ── render ───────────────────────────────────────────────────────────────────────
def render(n: int, note: str, parent: int | None, grace: int) -> bool:
    cg, changelog = code_generation()
    if cg != n:
        print(f"  the code says GENERATION {cg}, you asked to render gen {n} — bump the constant first")
        return False
    out = gen_dir(n)
    out.mkdir(parents=True, exist_ok=True)
    for old in list(out.glob("*.png")) + list(out.glob("state_*.json")) + [out / "_done.txt", out / "_rejects.json"]:
        if old.exists():
            old.unlink()
    STATE.mkdir(parents=True, exist_ok=True)
    for d in DNAS:
        p = STATE / f"{label_of(d)}.json"
        if p.exists():
            p.unlink()
    variants = []
    for d in DNAS:
        seed, m, r, w = d
        variants.append({"label": label_of(d), "params": {"seed": seed, "size": SIZE, "moisture": m,
                                                          "relief": r, "wildness": w, "record": "on"}})
    spec = {"scene": SCENE, "out_dir": f"res://ada_run/biome_rsi/gen_{n}", "yaw": YAW, "pitch": PITCH,
            "framing": FRAMING, "fixed_camera": True, "variants": variants}
    spec_p = RUN / f"spec_gen_{n}.json"
    spec_p.write_text(json.dumps(spec, indent=1), encoding="utf-8")
    args = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"), f"--expect={out}", f"--grace={grace}",
            "--stall=120", "--", GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
            "--script", "res://commons/testing/capture_config_sweep.gd", "--",
            f"--spec=res://ada_run/biome_rsi/spec_gen_{n}.json"]
    t0 = time.time()
    r = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=1800)
    frames = sorted(out.glob("s*.png"))
    print(f"  [gen {n}] {len(frames)} frames in {time.time() - t0:.0f}s (watchdog exit {r.returncode})")
    if r.returncode != 0:
        print((r.stderr or r.stdout or "")[-600:])
    rej = out / "_rejects.json"
    if rej.exists():
        rj = json.loads(rej.read_text(encoding="utf-8"))
        if int(rj.get("rejected", 0)) > 0:
            print(f"  [gen {n}] REJECTED PARAMS — read {rej}")
    for d in DNAS:
        p = STATE / f"{label_of(d)}.json"
        if p.exists():
            shutil.copyfile(p, out / f"state_{label_of(d)}.json")
    meas = measure(n, parent)
    _log({"gen": n, "parent": parent, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "note": note,
          "changelog": changelog, "frames": len(frames), "measures": meas["summary"], "verdict": "pending"})
    return len(frames) == len(DNAS)


# ── measure ──────────────────────────────────────────────────────────────────────
def _load(p: Path):
    from PIL import Image
    import numpy as np
    im = Image.open(p).convert("RGB").resize((190, 190), Image.BILINEAR)
    return np.asarray(im, dtype=np.int16)


def _tile_measures(a):
    import numpy as np
    bg = a[2, 2]
    sub = (np.abs(a - bg).max(axis=2) > DIFF_T)
    frac = float(sub.mean())
    px = a[sub]
    bins = 0
    if len(px) > 0:
        r, g, b = px[:, 0] / 255.0, px[:, 1] / 255.0, px[:, 2] / 255.0
        mx = np.maximum(np.maximum(r, g), b)
        mn = np.minimum(np.minimum(r, g), b)
        d = mx - mn
        sat = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
        h = np.zeros_like(mx)
        m = d > 1e-6
        rc, gc, bc = (mx - r) / np.maximum(d, 1e-6), (mx - g) / np.maximum(d, 1e-6), (mx - b) / np.maximum(d, 1e-6)
        h = np.where(mx == r, bc - gc, np.where(mx == g, 2.0 + rc - bc, 4.0 + gc - rc))
        h = (h / 6.0) % 1.0
        keep = m & (sat > 0.18) & (mx > 0.12)
        if keep.any():
            hist, _ = np.histogram(h[keep], bins=24, range=(0.0, 1.0))
            bins = int((hist > max(3, 0.01 * keep.sum())).sum())
    ys, xs = np.nonzero(sub)
    ratio = float((ys.max() - ys.min() + 1) / max(1, xs.max() - xs.min() + 1)) if len(ys) else 0.0
    # legibility-v1 (added after the gen-0 critique: integration-v1 saturates once every world
    # has six layers, so the things the critic looks FOR get their own named numbers):
    #   water_px   share of subject pixels that read blue (the pool is visible, not buried)
    #   ground_var std of luminance over the subject (a ground that shows its moisture varies)
    #   green_px   share of subject pixels that read green (the living cover)
    water = green = 0.0
    gvar = 0.0
    if len(px) > 0:
        r, g, b = px[:, 0].astype(float), px[:, 1].astype(float), px[:, 2].astype(float)
        water = float(((b > r + 18) & (b > g + 8)).mean())
        green = float(((g > r + 12) & (g > b + 12)).mean())
        gvar = float((0.299 * r + 0.587 * g + 0.114 * b).std() / 255.0)
    return {"subject_frac": round(frac, 4), "colour_bins": bins, "bbox_ratio": round(ratio, 3),
            "water_px": round(water, 4), "green_px": round(green, 4), "ground_var": round(gvar, 4)}


def measure(n: int, parent: int | None) -> dict:
    out = gen_dir(n)
    rows = {}
    for d in DNAS:
        lab = label_of(d)
        png = out / f"{lab}.png"
        row = {"label": lab, "dna": {"seed": d[0], "moisture": d[1], "relief": d[2], "wildness": d[3]}}
        st_p = out / f"state_{lab}.json"
        st = json.loads(st_p.read_text(encoding="utf-8")) if st_p.exists() else {}
        cnt = st.get("counts", {})
        kp = len(st.get("kingdoms_present", []))
        conn = int(cnt.get("connections", 0))
        row["state"] = {"kingdoms_present": kp, "connections": conn, "organisms": st.get("organisms", 0),
                        "build_ms": st.get("build_ms", 0), "counts": cnt}
        if png.exists():
            a = _load(png)
            row["tile"] = _tile_measures(a)
            if parent is not None and (gen_dir(parent) / f"{lab}.png").exists():
                b = _load(gen_dir(parent) / f"{lab}.png")
                import numpy as np
                row["change_vs_parent"] = round(float((np.abs(a - b).max(axis=2) > DIFF_T).mean()), 4)
        else:
            row["tile"] = {"subject_frac": 0.0, "colour_bins": 0, "bbox_ratio": 0.0}
        row["integration_v1"] = round(0.40 * kp / 6.0 + 0.30 * min(1.0, conn / 6.0)
                                      + 0.30 * min(1.0, row["tile"]["colour_bins"] / 10.0), 4)
        t = row["tile"]
        # thresholds set ABOVE gen 0 (water 2.5 %, ground var 0.119, green ~0.2) so the number
        # has room to move; a saturated floor measures nothing
        row["legibility_v1"] = round(0.4 * min(1.0, t["water_px"] / 0.06) + 0.3 * min(1.0, t["ground_var"] / 0.18)
                                     + 0.3 * min(1.0, t["green_px"] / 0.35), 4)
        rows[lab] = row
    vals = [r["integration_v1"] for r in rows.values()]
    legs = [r["legibility_v1"] for r in rows.values()]
    summary = {"integration_v1_mean": round(sum(vals) / len(vals), 4) if vals else 0.0,
               "integration_v1_min": round(min(vals), 4) if vals else 0.0,
               "legibility_v1_mean": round(sum(legs) / len(legs), 4) if legs else 0.0,
               "water_px_mean": round(sum(r["tile"]["water_px"] for r in rows.values()) / len(rows), 4),
               "ground_var_mean": round(sum(r["tile"]["ground_var"] for r in rows.values()) / len(rows), 4),
               "kingdoms_mean": round(sum(r["state"]["kingdoms_present"] for r in rows.values()) / len(rows), 2),
               "connections_mean": round(sum(r["state"]["connections"] for r in rows.values()) / len(rows), 2),
               "colour_bins_mean": round(sum(r["tile"]["colour_bins"] for r in rows.values()) / len(rows), 2),
               "subject_mean": round(sum(r["tile"]["subject_frac"] for r in rows.values()) / len(rows), 4),
               "build_ms_max": max((r["state"]["build_ms"] for r in rows.values()), default=0)}
    if any("change_vs_parent" in r for r in rows.values()):
        ch = [r["change_vs_parent"] for r in rows.values() if "change_vs_parent" in r]
        summary["change_vs_parent_mean"] = round(sum(ch) / len(ch), 4)
    res = {"gen": n, "parent": parent, "fitness": "integration-v1", "rows": rows, "summary": summary}
    (out / "measures.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
    print(f"  [gen {n}] integration-v1 mean {summary['integration_v1_mean']:.3f} (min {summary['integration_v1_min']:.3f}) · "
          f"legibility-v1 {summary['legibility_v1_mean']:.3f} (water {100 * summary['water_px_mean']:.1f}% of subject, ground var {summary['ground_var_mean']:.3f}) · "
          f"kingdoms {summary['kingdoms_mean']}/6 · connections {summary['connections_mean']} · hues {summary['colour_bins_mean']} · "
          f"subject {100 * summary['subject_mean']:.1f}% · build {summary['build_ms_max']} ms"
          + (f" · change vs gen {parent}: {100 * summary['change_vs_parent_mean']:.1f}%" if "change_vs_parent_mean" in summary else ""))
    return res


def compare(n: int, against: int) -> None:
    a = json.loads((gen_dir(n) / "measures.json").read_text(encoding="utf-8"))
    b = json.loads((gen_dir(against) / "measures.json").read_text(encoding="utf-8"))
    print(f"  {'dna':<18} {'gen ' + str(against):>10} {'gen ' + str(n):>10}  delta   change")
    for lab, ra in a["rows"].items():
        rb = b["rows"].get(lab, {})
        ia, ib = ra["integration_v1"], rb.get("integration_v1", 0.0)
        print(f"  {lab:<18} {ib:>10.3f} {ia:>10.3f} {ia - ib:+.3f}  {100 * ra.get('change_vs_parent', 0):.1f}%")
    sa, sb = a["summary"], b["summary"]
    print(f"  legibility-v1 {sb.get('legibility_v1_mean', 0):.3f} -> {sa.get('legibility_v1_mean', 0):.3f}; water {100 * sb.get('water_px_mean', 0):.1f}% -> {100 * sa.get('water_px_mean', 0):.1f}%; ground var {sb.get('ground_var_mean', 0):.3f} -> {sa.get('ground_var_mean', 0):.3f}")
    print(f"  mean {sb['integration_v1_mean']:.3f} -> {sa['integration_v1_mean']:.3f} ({sa['integration_v1_mean'] - sb['integration_v1_mean']:+.3f}); "
          f"kingdoms {sb['kingdoms_mean']} -> {sa['kingdoms_mean']}; connections {sb['connections_mean']} -> {sa['connections_mean']}; "
          f"hues {sb['colour_bins_mean']} -> {sa['colour_bins_mean']}")


# ── lineage ──────────────────────────────────────────────────────────────────────
def _log(row: dict) -> None:
    RUN.mkdir(parents=True, exist_ok=True)
    with LINEAGE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def _lineage() -> list[dict]:
    if not LINEAGE.exists():
        return []
    return [json.loads(l) for l in LINEAGE.read_text(encoding="utf-8").splitlines() if l.strip()]


def verdict(n: int, kept: bool, why: str) -> None:
    rows = _lineage()
    hit = False
    for r in reversed(rows):
        if r.get("gen") == n:
            r["verdict"] = "kept" if kept else "culled"
            r["why"] = why
            r["judged_at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
            hit = True
            break
    if not hit:
        print(f"  no lineage row for gen {n}")
        return
    LINEAGE.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")
    print(f"  gen {n}: {'kept' if kept else 'culled'} — {why}")


# ── publish ──────────────────────────────────────────────────────────────────────
def publish() -> None:
    GAL.mkdir(parents=True, exist_ok=True)
    rows = _lineage()
    gens = sorted({r["gen"] for r in rows})
    entries = []
    order = 0
    by_gen = {}
    for r in rows:
        by_gen[r["gen"]] = r
    for n in gens:
        mp = gen_dir(n) / "measures.json"
        if not mp.exists():
            continue
        meas = json.loads(mp.read_text(encoding="utf-8"))
        lr = by_gen[n]
        for d in DNAS:
            lab = label_of(d)
            src = gen_dir(n) / f"{lab}.png"
            if not src.exists():
                continue
            order += 1
            row = meas["rows"][lab]
            fid = f"gen{n:02d}__{lab}"
            shutil.copyfile(src, GAL / f"{fid}.png")
            cfg = {"id": fid, "generation": n, "parent": lr.get("parent"), "verdict": lr.get("verdict"),
                   "why": lr.get("why", ""), "changelog": lr.get("changelog", ""), "note": lr.get("note", ""),
                   "dna": row["dna"], "size": SIZE, "measures": {k: v for k, v in row.items() if k not in ("dna", "label")},
                   "fitness": "integration-v1", "scene": SCENE,
                   "token": "biome_object:0#seed:%d#size:%d#moisture:%.2f#relief:%.2f#wildness:%.2f" % (
                       d[0], SIZE, d[1], d[2], d[3])}
            (GAL / f"{fid}.json").write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
            st = row["state"]
            entries.append({"id": fid, "image": f"/{SLUG}/{fid}.png", "config": f"/{SLUG}/{fid}.json",
                            "generation": f"gen {n} — {lr.get('changelog', lr.get('note', ''))}"[:140],
                            "subtitle": f"gen {n}", "gen": n, "verdict": lr.get("verdict"), "order": order,
                            "notes": (f"gen {n} · seed {d[0]} · m {d[1]:.2f} r {d[2]:.2f} w {d[3]:.2f} · "
                                      f"integration {row['integration_v1']:.2f} · {st['kingdoms_present']}/6 layers · "
                                      f"{st['connections']} connections · {row['tile']['colour_bins']} hues · legibility {row.get('legibility_v1', 0):.2f}"
                                      + (f" · {100 * row['change_vs_parent']:.0f}% changed" if "change_vs_parent" in row else "")
                                      + (f" · {lr.get('verdict')}" if lr.get("verdict") else ""))})
    means = []
    for n in gens:
        mp = gen_dir(n) / "measures.json"
        if mp.exists():
            means.append((n, json.loads(mp.read_text(encoding="utf-8"))["summary"]["integration_v1_mean"], by_gen[n].get("verdict")))
    desc = ("The biome as one object, improved generation by generation with the lineage on record. The same six DNAs "
            "(seed · moisture · relief · wildness) are rendered every generation; each tile carries its measures "
            "(integration-v1, named: layers present, fungus touching wood, hues) and the generation's change. "
            + " → ".join(f"gen {n} {m:.2f}{' (culled)' if v == 'culled' else ''}" for n, m, v in means)
            + ". Rows are generations; read a column top to bottom and the same world gets better. Click a tile for its DNA and the map token.")
    (GAL / "manifest.json").write_text(json.dumps({"version": 1, "schema_version": 1, "description": desc,
                                                   "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
                                                   "tool": "tools/biome_rsi.py", "lineage": rows, "entries": entries},
                                                  indent=1, ensure_ascii=False), encoding="utf-8")
    if not (GAL / "evals.json").exists():
        (GAL / "evals.json").write_text("{}", encoding="utf-8")
    print(f"published {len(entries)} tiles over {len(gens)} generation(s) -> {GAL}")
    print(f"page: http://127.0.0.1:3003/{SLUG}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["render", "measure", "compare", "verdict", "publish"])
    ap.add_argument("--gen", type=int, default=-1)
    ap.add_argument("--parent", type=int, default=None)
    ap.add_argument("--against", type=int, default=None)
    ap.add_argument("--note", default="")
    ap.add_argument("--why", default="")
    ap.add_argument("--kept", action="store_true")
    ap.add_argument("--culled", action="store_true")
    ap.add_argument("--grace", type=int, default=240)
    a = ap.parse_args()
    if a.cmd == "render":
        parent = a.parent if a.parent is not None else (a.gen - 1 if a.gen > 0 else None)
        return 0 if render(a.gen, a.note, parent, a.grace) else 1
    if a.cmd == "measure":
        parent = a.parent if a.parent is not None else (a.gen - 1 if a.gen > 0 else None)
        measure(a.gen, parent)
        return 0
    if a.cmd == "compare":
        compare(a.gen, a.against if a.against is not None else a.gen - 1)
        return 0
    if a.cmd == "verdict":
        verdict(a.gen, a.kept and not a.culled, a.why)
        return 0
    publish()
    return 0


if __name__ == "__main__":
    sys.exit(main())
