#!/usr/bin/env python3
"""Embodied vector/force toys DNA gallery generator.

Six embodied operations/forces toys, each sweeping its principle's DNA parameter
across the meaningful range so the gallery shows the concept move:
  dot_aligner (alignment) · torque_crank (leverage) · projection_shadow (projection)
  · drag_lane (drag) · launch_arc (angle) · circle_train (speed).

Promotes the registered artifacts into the DNA-gallery system (auto-discovered by
galleryIndex.ts) so the self-improving / eval loop can run on the specimens.
Writes specimen configs + a GalleryView manifest into the encyclopedia
vector-toys-gallery (images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\vector-toys-gallery"

# toy -> (scene, sweep_param, [values], sculpt_height, sculpt_width, principle, extra_dna)
TOYS = {
    "dot_aligner": (
        "res://commons/artifacts/dot_aligner/dot_aligner.tscn",
        "alignment", [0.30, 0.60, 0.92], 2.0, 2.4,
        "dot product — aim · foe = cos θ; alignment locks the beam and converts foe to friend", {},
    ),
    "torque_crank": (
        "res://commons/artifacts/torque_crank/torque_crank.tscn",
        "leverage", [0.20, 0.55, 0.92], 2.0, 2.2,
        "cross product — r × F = |r||F| sin θ; leverage sets the torque that spins the flywheel", {},
    ),
    "projection_shadow": (
        "res://commons/artifacts/projection_shadow/projection_shadow.tscn",
        "projection", [0.25, 0.62, 0.95], 2.0, 2.6,
        "projection — (a · n̂) n̂ as a sun-cast shadow; the object swings from perpendicular to along the rail", {},
    ),
    "drag_lane": (
        "res://commons/artifacts/drag_lane/drag_lane.tscn",
        "drag", [0.20, 0.52, 0.85], 1.6, 3.0,
        "friction / drag — F = -b·v; the runner decays from glide to dead-stop", {},
    ),
    "launch_arc": (
        "res://commons/artifacts/launch_arc/launch_arc.tscn",
        "angle", [0.18, 0.50, 0.82], 1.8, 2.8,
        "projectile — gravity bends the launch vector into a parabola; range peaks at 45°", {"power": 0.7},
    ),
    "circle_train": (
        "res://commons/artifacts/circle_train/circle_train.tscn",
        "speed", [0.25, 0.62, 1.0], 1.4, 2.8,
        "centripetal — a = v²/r; velocity grows linearly, the inward force quadratically", {},
    ),
}

LABELS = ["low", "mid", "high"]


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    entries, render = [], []
    for toy, (scene, param, values, sh, sw, principle, extra) in TOYS.items():
        for i, val in enumerate(values):
            tag = LABELS[i] if i < len(LABELS) else str(i)
            cid = "vt_%s_%s" % (toy, tag)
            dna = {param: val, "complexity": 7, "sculpt_height": sh, "sculpt_width": sw}
            dna.update(extra)
            name = "%s — %s %.2f" % (toy.replace("_", " ").title(), param, val)
            desc = "%s  (%s = %.2f)" % (principle, param, val)
            json.dump({"id": cid, "name": name, "description": desc, "family": toy,
                       "scene": scene, "dna": dna},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"),
                      indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/vector-toys-gallery/%s.png" % cid,
                            "config": "/vector-toys-gallery/%s.json" % cid,
                            "notes": "%s — %s" % (name, desc)})
            render.append("%s\t%s" % (cid, scene))
    json.dump({"version": 1,
               "description": "Embodied vector & force toys — six playable artifacts each sweeping its principle's DNA parameter: dot_aligner (dot) / torque_crank (cross) / projection_shadow (projection) / drag_lane (friction) / launch_arc (projectile) / circle_train (centripetal). The grammar is vectors and forces; you feel each one move.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d vector-toy specimens across %d toys" % (len(entries), len(TOYS)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
