#!/usr/bin/env python3
"""
cabinet_sweep.py — the DNA-sweep loop for the cabinet family (and any artifact).

Palle: "a faster way to iterate — the props-dna-gallery loop." That loop is
data-driven: you vary an artifact by its knobs, batch-render the whole matrix
in ONE boot, and compare on a sheet — no code edit per variant.

  python tools/cabinet_sweep.py galton_board \
      --set finish=rams,terminal --set plinth_height=0.0,0.4,0.8

sweeps the cartesian product (2 x 3 = 6 variants), renders them in one Godot
boot (params set before _ready, so the housing rebuilds for free), and tiles
doc/reports/sweep_galton_board.png with each cell labelled by its params.

Then adopt the winning values back into the artifact's @export defaults.

Flags:
  --set KEY=V1,V2,...   a knob to vary (repeatable). Values parse as
                        int/float/bool/string automatically.
  --scene RES_PATH      override the scene (else resolved from the canon /
                        registry by artifact name).
  --max N               cap the number of variants (safety; default 24).
"""
from __future__ import annotations
import argparse
import itertools
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_EXE",
                       r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
# the capturer writes res://ada_run/sweep, which in a --path . run is the REPO
SWEEP_OUT = REPO / "ada_run" / "sweep"
CANON = REPO / "commons" / "data" / "cabinet_grammar.json"
SPEC = REPO / "ada_run" / "sweep_spec.json"


def resolve_scene(artifact: str) -> str:
    for m in json.loads(CANON.read_text(encoding="utf-8")).get("members", []):
        if m["artifact"] == artifact:
            return m["scene"]
    import glob
    for f in glob.glob(str(REPO / "commons/artifacts/registry/*.json")):
        reg = json.loads(Path(f).read_text(encoding="utf-8")).get("artifacts", {})
        if artifact in reg:
            sp = reg[artifact].get("scene_path") or reg[artifact].get("scene")
            if sp:
                return sp
    return ""


def coerce(v: str):
    lo = v.lower()
    if lo in ("true", "false"):
        return lo == "true"
    try:
        return int(v)
    except ValueError:
        pass
    try:
        return float(v)
    except ValueError:
        return v


def canon_members() -> list[tuple[str, str]]:
    ms = json.loads(CANON.read_text(encoding="utf-8")).get("members", [])
    return [(m["artifact"], m["scene"]) for m in ms]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("artifact", nargs="?", default=None)
    ap.add_argument("--all", action="store_true",
                    help="sweep EVERY canon member across the axes (cross-member sheet)")
    ap.add_argument("--set", action="append", default=[], metavar="KEY=V1,V2")
    ap.add_argument("--scene", default="")
    ap.add_argument("--max", type=int, default=40)
    args = ap.parse_args()

    if not args.set:
        print("nothing to sweep — pass at least one --set KEY=V1,V2,...")
        return 1

    axes: list[tuple[str, list]] = []
    for spec in args.set:
        if "=" not in spec:
            print(f"bad --set '{spec}' (want KEY=V1,V2)")
            return 1
        key, vals = spec.split("=", 1)
        axes.append((key.strip(), [coerce(v.strip()) for v in vals.split(",") if v.strip()]))
    keys = [k for k, _ in axes]
    combos = list(itertools.product(*[vs for _, vs in axes]))

    # targets: every canon member (--all), or the single named artifact
    if args.all:
        targets = canon_members()
        sweep_name = "family_" + "_".join(keys)
    else:
        if not args.artifact:
            print("name an artifact, or pass --all")
            return 1
        sc = args.scene or resolve_scene(args.artifact)
        if not sc:
            print(f"could not resolve a scene for '{args.artifact}'")
            return 1
        targets = [(args.artifact, sc)]
        sweep_name = args.artifact

    variants = []
    for art, sc in targets:
        for combo in combos:
            params = dict(zip(keys, combo))
            axtag = "__".join(f"{k}-{combo[i]}" for i, k in enumerate(keys))
            variants.append({
                "label": f"{art}__{axtag}", "artifact": art,
                "scene": sc, "params": params,
            })
    if len(variants) > args.max:
        print(f"{len(variants)} variants exceeds --max {args.max}; raise --max or narrow")
        return 1

    # Framing hint. The sweep fits the whole artifact by default, which
    # under-frames any axis that lives in a detail rather than the silhouette —
    # line_interface's readout rendered at ~30 px in a 700 px frame, so four
    # different values were indistinguishable from an inert axis. An artifact
    # can ask for a tighter shot with "framing" in its registry dna block.
    framing = 1.0
    if targets:
        import glob as _glob
        for _f in _glob.glob(str(REPO / "commons/artifacts/registry/*.json")):
            try:
                _reg = json.loads(Path(_f).read_text(encoding="utf-8")).get("artifacts", {})
            except Exception:
                continue
            _e = _reg.get(targets[0][0])
            if isinstance(_e, dict) and isinstance(_e.get("dna"), dict):
                try:
                    _v = float(_e["dna"].get("framing", 1.0))
                except (TypeError, ValueError):
                    _v = 1.0
                if 0.05 < _v < 20.0:
                    framing = _v
                break

    # Fixture: config an artifact needs SUPPLIED before its axis can be seen at
    # all. library_rack builds nothing in _ready by design — it has no shelf
    # until a collection arrives — so sweeping guard alone rendered five blank
    # frames scoring 0.00%, a dead axis by measurement across 70 placements.
    fixture: dict = {}
    if targets:
        import glob as _g2
        for _f in _g2.glob(str(REPO / "commons/artifacts/registry/*.json")):
            try:
                _reg = json.loads(Path(_f).read_text(encoding="utf-8")).get("artifacts", {})
            except Exception:
                continue
            _e = _reg.get(targets[0][0])
            if isinstance(_e, dict) and isinstance(_e.get("dna"), dict):
                _fx = _e["dna"].get("fixture")
                if isinstance(_fx, dict):
                    fixture = _fx
                break
    if fixture:
        print(f"  fixture from registry: {fixture}")
        for v in variants:
            merged = dict(fixture)
            merged.update(v["params"])
            v["params"] = merged

    SPEC.parent.mkdir(exist_ok=True)
    SPEC.write_text(json.dumps({
        "scene": targets[0][1],
        "out_dir": "res://ada_run/sweep",
        "framing": framing,
        "variants": variants,
    }, indent=1), encoding="utf-8")
    if framing != 1.0:
        print(f"  framing hint from registry: x{framing}")

    # clear old shots + done marker
    if SWEEP_OUT.exists():
        for p in SWEEP_OUT.glob("*.png"):
            p.unlink()
    (SWEEP_OUT / "_done.txt").unlink() if (SWEEP_OUT / "_done.txt").exists() else None

    print(f"· sweeping {sweep_name}: {len(variants)} variants, one boot …")
    done = SWEEP_OUT / "_done.txt"
    SWEEP_OUT.mkdir(parents=True, exist_ok=True)
    # Watch the sweep DIR, not the final _done.txt: each variant's PNG counts
    # as progress, so a long batch (32 variants ~46s) doesn't trip the 45s
    # boot-grace before the last shot lands.
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={SWEEP_OUT}", "--",
           GODOT, "--path", str(REPO), "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_config_sweep.gd",
           "--", f"--spec={SPEC}"]
    subprocess.run(cmd, cwd=str(REPO))
    if not done.exists():
        print("sweep failed (no _done.txt) — check the Godot log")
        return 1

    return tile(sweep_name, variants, keys, cross_member=args.all)


def _report_bite(sweep_name: str, shots: list) -> None:
    """Measure how much each variant actually changed the image, and say so.

    A sweep sheet looks like a verdict whether or not the axis did anything.
    Three separate causes produce the same innocent-looking grid of tiles: an
    axis that genuinely does nothing, an axis whose value never reached the
    node that owns it, and a subject too small to read. Until this ran, telling
    them apart meant diffing tiles by hand — which is how line_interface spent
    an afternoon misdiagnosed as inert when its value simply was not arriving.

    Writes doc/reports/sweep_<name>_bite.json alongside the sheet so the
    research ledger can carry the number instead of an impression.
    """
    try:
        from PIL import Image, ImageChops
    except ImportError:
        return
    if len(shots) < 2:
        return

    # Compare SUBJECT SILHOUETTES, pairwise, not frames against one baseline.
    #
    # Two failures forced this. Baselining on the first shot reported BITES for
    # an axis that changes nothing, because the environment has not settled on
    # shot one and its background sits at a different tint, so every later
    # variant differs from it across the whole frame. Baselining on the SECOND
    # shot then reported 0.00% for cube_scene, whose `solid` value differs from
    # the other four by 86% — because solid was shot one, and the four values
    # being compared are identical to each other. One baseline cannot survive
    # either case.
    #
    # Masking each image against ITS OWN background colour cancels the tint
    # difference, and taking the max over all pairs means a single distinct
    # value cannot hide wherever it lands in the order.
    # Silhouette alone is not enough either: cube_scene's grain changes the
    # INSIDE of a cube whose outline never moves, so a mask comparison scored it
    # 0.00% just as confidently as the baseline did. Compare colour, but only
    # where at least one variant has a subject — background is excluded, so the
    # unsettled first frame's tint cannot register, and internal structure can.
    def load(path):
        im = Image.open(path).convert("RGB")
        bg = im.getpixel((3, 3))
        return im, bg

    try:
        loaded = [(params, *load(p)) for (_a, params, p) in shots]
    except OSError:
        return
    if len(loaded) < 2:
        return
    w, h = loaded[0][1].size
    total = w * h

    def subject(im, bg):
        px = im.load()
        s = bytearray(w * h)
        i = 0
        for y in range(h):
            for x in range(w):
                r, g, b = px[x, y]
                s[i] = 1 if (abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])) > 26 else 0
                i += 1
        return s

    subs = [(p, im, subject(im, bg)) for (p, im, bg) in loaded]
    rows = []
    peak = 0.0
    for i in range(len(subs)):
        for j in range(i + 1, len(subs)):
            (pa, ia, sa), (pb, ib, sb) = subs[i], subs[j]
            if ia.size != ib.size:
                continue
            da, db = ia.load(), ib.load()
            changed = 0
            k = 0
            for y in range(h):
                for x in range(w):
                    if sa[k] or sb[k]:
                        ra, ga, ba = da[x, y]
                        rb, gb, bb = db[x, y]
                        if abs(ra - rb) + abs(ga - gb) + abs(ba - bb) > 26:
                            changed += 1
                    k += 1
            pct = round(100.0 * changed / max(1, total), 3)
            peak = max(peak, pct)
            rows.append({"a": pa, "b": pb, "changed_px": changed, "changed_pct": pct})
    if not rows:
        return
    verdict = ("BITES" if peak >= 2.0 else
               "faint - under 2% of the frame moved" if peak > 0.05 else
               "NO VISIBLE CHANGE - the axis did nothing a still can show")
    print(f"  bite: peak {peak:.2f}% of pixels changed across variants — {verdict}")
    out = REPO / "doc" / "reports" / f"sweep_{sweep_name}_bite.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"sweep": sweep_name, "peak_changed_pct": peak,
                               "verdict": verdict, "variants": rows}, indent=1),
                   encoding="utf-8")


def tile(sweep_name: str, variants: list[dict], keys: list[str],
         cross_member: bool = False) -> int:
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print(f"  (Pillow missing — shots in {SWEEP_OUT})")
        return 0
    shots = [(v.get("artifact", ""), v["params"], SWEEP_OUT / f"{v['label']}.png")
             for v in variants if (SWEEP_OUT / f"{v['label']}.png").exists()]
    if not shots:
        print("  no shots produced")
        return 1
    _report_bite(sweep_name, shots)
    n = len(shots)
    # cross-member sweep: one ROW per member, its finishes side by side, so
    # cols = combos-per-member. Single artifact: up to 4 wide.
    if cross_member:
        distinct = len({s[0] for s in shots}) or 1
        cols = max(1, n // distinct)
    else:
        cols = 4 if n > 4 else n
    rows = (n + cols - 1) // cols
    cell, lab = 360, 28
    sheet = Image.new("RGB", (cols * cell, rows * (cell + lab)), (18, 18, 22))
    draw = ImageDraw.Draw(sheet)
    for i, (art, params, path) in enumerate(shots):
        im = Image.open(path).convert("RGB")
        im.thumbnail((cell, cell))
        cx = (i % cols) * cell + (cell - im.width) // 2
        cy = (i // cols) * (cell + lab) + lab + (cell - im.height) // 2
        sheet.paste(im, (cx, cy))
        pcap = "  ".join(f"{k}={params[k]}" for k in keys)
        cap = f"{art}  ·  {pcap}" if art else pcap
        draw.text(((i % cols) * cell + 6, (i // cols) * (cell + lab) + 7),
                  cap, fill=(220, 224, 232))
    out = REPO / "doc" / "reports" / f"sweep_{sweep_name}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"  sweep sheet: {out}  ({len(shots)} variants)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
