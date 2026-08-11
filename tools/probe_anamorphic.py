#!/usr/bin/env python3
"""probe_anamorphic.py — is the verdict a fact about the artifact, or about where we stood?

THE CLAIM UNDER TEST. Every tile in every DNA gallery, some three hundred across seven
sequences, was shot from ONE fixed viewpoint: capture_config_sweep's YAW 0.62, PITCH -0.26.
That is not a neutral default, it is a standpoint. An anamorphic body — one whose form
resolves only from an oblique angle, Holbein's skull in The Ambassadors — is by construction
invisible to that camera no matter how loudly it differs in the room.

So the pipeline can only ever have said: "this axis does not change what the camera at 0.62
happened to be facing." It has been reporting that as "this axis does nothing."

THE TEST. Take the axes the critic currently calls WEAK or INERT — the ones it has already
declared close to dead — and re-render them from four other standpoints. If an axis bites
from somewhere else, the verdict was never about the artifact.

  python tools/probe_anamorphic.py --gallery=swarm-dna --token=boids_aquarium --axis=accord

Writes doc/reports/anamorphic_<token>.json and renders into
ada_encyclopedia/public/anamorphic/<token>__<view>__<variant>.png
"""
from __future__ import annotations
import argparse
import itertools
import json
import math
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
OUT = ENC / "anamorphic"
GODOT = r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"

# The canonical standpoint, and four others. The names matter: this is a gallery about
# where somebody was standing, so the views are named for the standing and not for numbers.
VIEWS: dict[str, tuple[float, float]] = {
    "canonical": (0.62, -0.26),    # what every published tile has ever seen
    "opposite": (0.62 + math.pi, -0.26),
    "square-on": (0.0, -0.10),
    "from-above": (0.62, -1.05),
    "from-below": (0.62, 0.30),
}


def registry() -> dict:
    out: dict = {}
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict) and (e.get("scene") or e.get("scene_path")):
                    out.setdefault(tok, e)
    return out


def focus_pair(pa: Path, pb: Path) -> tuple[float, float]:
    """The critic's own numbers: crop to subject, 160x160, hottest 5%, luminance + colour."""
    from PIL import Image, ImageChops

    def bbox(p: Path):
        im = Image.open(p).convert("RGB")
        d = ImageChops.difference(im, Image.new("RGB", im.size, im.getpixel((3, 3))))
        return d.convert("L").point(lambda v: 255 if v > 10 else 0).getbbox()

    b1, b2 = bbox(pa), bbox(pb)
    if not b1 or not b2:
        return 0.0, 0.0
    box = (min(b1[0], b2[0]), min(b1[1], b2[1]), max(b1[2], b2[2]), max(b1[3], b2[3]))
    la = list(Image.open(pa).convert("L").crop(box).resize((160, 160)).getdata())
    lb = list(Image.open(pb).convert("L").crop(box).resize((160, 160)).getdata())
    d = sorted((abs(x - y) / 255.0 for x, y in zip(la, lb)), reverse=True)
    k = max(1, len(d) // 20)
    lum = sum(d[:k]) / k
    ra = list(Image.open(pa).convert("RGB").crop(box).resize((160, 160)).getdata())
    rb = list(Image.open(pb).convert("RGB").crop(box).resize((160, 160)).getdata())
    d2 = sorted((max(abs(x[i] - y[i]) for i in range(3)) / 255.0 for x, y in zip(ra, rb)),
                reverse=True)
    return lum, sum(d2[:k]) / k


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--token", required=True)
    ap.add_argument("--axis", required=True)
    args = ap.parse_args()

    reg = registry()
    entry = reg.get(args.token)
    if not entry:
        print(f"{args.token}: no registry entry with a scene")
        return 1
    scene = entry.get("scene") or entry.get("scene_path")
    values = ((entry.get("dna") or {}).get("axes") or {}).get(args.axis)
    if not values:
        print(f"{args.token}.{args.axis}: not a declared axis")
        return 1
    values = [v for v in values if isinstance(v, str)]

    OUT.mkdir(parents=True, exist_ok=True)
    results: dict[str, dict] = {}

    for view, (yaw, pitch) in VIEWS.items():
        variants = [{"label": f"{args.token}__{view}__{v}", "artifact": args.token,
                     "scene": scene, "params": {args.axis: v}} for v in values]
        spec = {"scene": scene, "out_dir": f"res://{OUT.relative_to(REPO.parent).as_posix()}"
                if OUT.is_relative_to(REPO.parent) else str(OUT),
                "yaw": yaw, "pitch": pitch, "variants": variants}
        # out_dir must be a path Godot can write; use an absolute one.
        spec["out_dir"] = str(OUT).replace("\\", "/")
        sp = REPO / "ada_run" / "anamorphic_spec.json"
        sp.write_text(json.dumps(spec, indent=1), encoding="utf-8")
        print(f"· {view}: yaw {yaw:.2f} pitch {pitch:.2f} ...")
        subprocess.run([GODOT, "--path", str(REPO), "--xr-mode", "off", "--no-window",
                        "--script", "res://commons/testing/capture_config_sweep.gd",
                        "--", f"--spec={sp}"], cwd=str(REPO),
                       capture_output=True, text=True, timeout=900)

        pairs = []
        for a, b in itertools.combinations(values, 2):
            pa = OUT / f"{args.token}__{view}__{a}.png"
            pb = OUT / f"{args.token}__{view}__{b}.png"
            if pa.exists() and pb.exists():
                lum, col = focus_pair(pa, pb)
                pairs.append({"a": a, "b": b, "focus": round(lum, 5), "colour": round(col, 5)})
        if pairs:
            best = max(pairs, key=lambda p: p["focus"])
            mean = sum(p["focus"] for p in pairs) / len(pairs)
            results[view] = {"mean_focus": round(mean, 5), "best_pair": best,
                             "pairs": pairs}
            verdict = ("bites" if mean >= 0.12 else "WEAK" if mean >= 0.03 else "INERT")
            print(f"    mean focus {mean*100:5.2f}%  ({verdict})   best pair "
                  f"{best['a']}/{best['b']} at {best['focus']*100:.2f}%")

    canon = results.get("canonical", {}).get("mean_focus", 0.0)
    others = {k: v["mean_focus"] for k, v in results.items() if k != "canonical"}
    best_view = max(others, key=others.get) if others else None
    report = {
        "_note": ("Does the verdict describe the artifact, or the standpoint? Every published "
                  "DNA tile was shot from the canonical view. If another standpoint scores "
                  "materially higher, the pipeline has been reporting its own position as a "
                  "fact about the work."),
        "token": args.token, "axis": args.axis, "views": VIEWS,
        "canonical_mean_focus": canon,
        "best_other_view": best_view,
        "best_other_mean_focus": others.get(best_view) if best_view else None,
        "ratio": round(others[best_view] / canon, 2) if best_view and canon > 0 else None,
        "results": results,
    }
    rp = REPO / "doc" / "reports" / f"anamorphic_{args.token}.json"
    rp.write_text(json.dumps(report, indent=1), encoding="utf-8")
    if best_view and canon > 0:
        print(f"\n  canonical {canon*100:.2f}%   best other ({best_view}) "
              f"{others[best_view]*100:.2f}%   ratio {others[best_view]/canon:.2f}x")
    print(f"  wrote {rp}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
