#!/usr/bin/env python3
"""build_seams_gallery.py — the bias-landscape gallery data.

Emits ada_encyclopedia/public/seams.json from the seam catalog
(doc/SEAM_PER_SEQUENCE.md, encoded here) + capture existence. Each station
gets its Godot capture when the artifact is built, else a design placeholder.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = ROOT.parent / "ada_encyclopedia"
CAPS = ENC / "public" / "artifact-gallery" / "captures"

# seq, family, seam, promised, shipped, crossing, artifact-lookup (or None),
# status override (None -> computed from capture; "chapter" for order-pilot)
CATALOG = [
 ("primitives","sampling","the sampled line","a continuous path following the hand","a staircase of held samples","magnify — walk into the tunnel","archimedean_tunnel",None),
 ("transformation","lattice","the stepped transform","continuous SE(3) motion","snaps on a lattice of transforms","reach for the angle between two steps","stepped_transform",None),
 ("symmetry","lattice","finite symmetry","continuous symmetry","n-fold; exactly 17 wallpaper groups","try to make a pattern outside the 17 rooms",None,None),
 ("array_tutorial","lattice","the lattice","continuous space","integer indices, no between-cells","reach for element 2.5 — you snap to the nearest","lattice_walk",None),
 ("color","lattice","the gamut","the spectrum","a 3×8-bit lattice; out-of-gamut clamped","eat the mushroom — the gamut shrinks","banding_gradient",None),
 ("change","sampling","the finite difference","the instantaneous derivative","a rate measured over one frame","zoom — the smooth curve is a chord-staircase (Zeno)","zeno_staircase",None),
 ("forces","sampling","the step","continuous dynamics","Euler/Verlet jumps","stiffen a spring and it explodes; a fast ball tunnels the wall","euler_drift",None),
 ("formfinding","lattice","tolerance","a true equilibrium curve","settled to an epsilon","zoom the 'settled' form — it still trembles",None,None),
 ("wavefunctions","sampling","Nyquist","a continuous wave","samples","raise the pitch past half the sample rate — it descends","aliasing_wave",None),
 ("randomness","determinism","the crank vs the harvest","fair independent chance","a formula chewing a seed","set the seed twice — the walk traces itself","galton_friction",None),
 ("noise","determinism","the entropy floor","real chaos","gradient noise (Perlin is a crank too)","push structure toward max entropy — it collapses into the field","noise_floor",None),
 ("cellularautomata","determinism","deterministic random","a living/random field","a fully deterministic rule; a torus faking the plane","rewind Rule 30's seed — it repeats; Life breaks at the edge","rule30_random",None),
 ("fractals","depth-cap","the floor","endless self-similarity","a finite iteration budget","zoom past iteration N — the detail is gone, flat","depth_cap",None),
 ("lsystems","depth-cap","grammar as seed","an organic infinite plant","a deterministic unfolding of a tiny string","the forest is one seed; growth halts at the budget","grammar_seed",None),
 ("proceduralgeneration","depth-cap","the seed is the world","infinite variety","a finite formula generated on demand","walk away and back — recreated identically from its seed",None,None),
 ("softbodies","lattice","the mass-spring lattice","an elastic continuum","point masses on springs","squeeze — it is faceted; stiffen — it detonates","spring_lattice",None),
 ("isosurfaces","lattice","marching cubes","a smooth implicit surface","triangles guessed between grid samples","lower the resolution — the blob turns to lego","marching_squares",None),
 ("boolean_surfaces","lattice","coincident-face precision","an exact cut","floats at the interface","subtract two shapes — the boundary z-fights and flickers",None,None),
 ("swarmintelligence","sampling","finite agents","emergence from infinite locals","N boids on a discrete tick","slow the tick — the 'living' motion is frame-by-frame bookkeeping",None,None),
 ("machinelearning","compression","the model is the seam","understanding","a compressed table interpolated","off its training set it is confident and wrong — Ada reading herself","model_seam",None),
 ("graphtheory","lattice","space to graph","real terrain","nodes and edges","you can only be at a node, never between","node_snap",None),
 ("foundationscrisis","limit","the computability limit","provability / decidability","the halting wall","the sorter rolls randf() because the decider is forbidden",None,"chapter"),
 ("qfeplaboratory","limit","measuring what can't be held","continuous entropy / order","quantized meters and dials","the entropy meter saturates — it cannot read true max entropy",None,None),
 ("postfoundationscrisis","limit","the confession","living after the limit","the seam owned","the 'no god's-eye' artifact hands you a god's-eye slider, and confesses it",None,"chapter"),
]

FAMILY_NOTE = {
 "sampling": "the continuous read at intervals; the holes between are gone",
 "lattice": "space, motion, state quantized to representable points",
 "depth-cap": "the infinite budgeted to a finite unfolding",
 "determinism": "the crank passing as the harvest",
 "compression": "the model is the seam",
 "limit": "where computation meets what it cannot hold, and says so",
}


def main() -> int:
    rows = []
    for i, (seq, fam, seam, promised, shipped, crossing, art, override) in enumerate(CATALOG):
        image = None
        if art and (CAPS / art / "front.png").exists():
            image = f"/artifact-gallery/captures/{art}/front.png"
        status = override or ("built" if image else "design")
        rows.append({"n": i + 1, "seq": seq, "family": fam, "seam": seam,
                     "promised": promised, "shipped": shipped, "crossing": crossing,
                     "artifact": art, "image": image, "status": status})
    built = sum(1 for r in rows if r["status"] == "built")
    data = {"total": len(rows), "built": built,
            "families": FAMILY_NOTE, "stations": rows}
    out = ENC / "public" / "seams.json"
    out.write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"seams.json: {built}/{len(rows)} built -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
