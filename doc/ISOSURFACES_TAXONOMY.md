# Isosurfaces, taught in the order the engine needs it

> Fifteenth sequence through the recipe (2026-08-27). Cheat-code: **a field sampled,
> then an ArrayMesh built where it crosses a number you CHOSE.** The surface is an
> opinion about a threshold.

June's canon was the weakest in the corpus: truncated map blurbs as "concepts", one
literally named *"Two hundred and fifty"*. No bespoke builder and no alias owned the
file, so the canon is now authored in `tools/build_concept_map.py` (CONFIG.isosurfaces)
and the generic builder owns it going forward. **localhost:3003/isosurfaces-concepts** —
24 tiles, 10 sections. Truth kept: *"Define a field, extract a surface."*

## The ladder
1. **The field** — a function from position to number. No geometry yet: space with an
   opinion everywhere, most of it invisible.
2. **The threshold** — pick a number and call it the skin. `iso = 0.5` is a DECISION.
3. **The sample grid** — you cannot ask every point, so you ask a lattice. Resolution
   is a budget (the third time this shape appears: smoothness, solver passes, now
   samples — the engine keeps charging for continuity).
4. **The fifteen cases** — 256 corner states, 15 after symmetry.
5. **The interpolation** — where between two corners? Midpoint is blocky; interpolating
   on the field values is smooth. Same cases, different world.
6. **The normal from the field** — the gradient IS the normal; lighting free from the
   same function that made the shape.
7. **Metaballs & implicit sums** — sum fields and they MERGE with no seam.
8. **Distance fields (SDF)** — let the number be distance and the field is sculptural.
9. **Landscapes & caves** — the same threshold read from above or from inside.
10. **The field that moves** — the skin is recomputed, never deformed, so it splits and
    heals with nobody managing topology.

## The super: the_threshold_opinion

A courtroom for a number. In the dock, ONE field standing as a lattice of rods whose
lengths are its own values — the invisible made visible. Around it, **five surfaces
extracted from that same field at five thresholds**, each marched for real and reporting
its own crossing count: fat, lean, pinched, thin, broken into islands. Nothing in the
field changed between them. A resolution row asks the same threshold of 4, 8 and 14
lattices; a brass rack holds the fifteen cases; two wells are caught mid-merge, seamless.
2,379 meshes, every skin marched at build time. Seated at The threshold.

## Also closed this pass: the noise canon's scoring bug

The noise CONFIG (authored in the turn that was redirected to CA) declared
`"registries": ["noise.json"]` — but every noise body lives in `randomness.json`. The
scan found **2 artifacts where the sequence has 34**, and the failure was invisible
because noise.json exists and holds something else. Fixed by the graphtheory pattern:
keep the narrow registry, assign the 32 real tokens through
`doc/noise_concept_additions.json`.

That exposed a flaw in the carry-forward rule I added for transformation: when a config
fix EMPTIES the catch-all, carry-forward resurrected the previous run's leftovers — 110
stale tokens came back into Off-the-ladder. The rule now never carries the catch-all
forward. Noise: 34 tiles across its 9 rungs, every one populated. Its super is the one
piece still outstanding.
