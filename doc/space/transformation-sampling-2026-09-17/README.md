# What moved between the pictures?

Four working transformation studies, 17 September 2026.

**Later spatial revision:** the Godot pose carriers now rotate at a viewing height of 1.7 m, with a companion axial sweep. This document records the earlier stationary-ring experiment; see [the current encounter and evidence](../zoetrope-encounter-2026-09-17/README.md).

[Try the animated browser studies](http://localhost:3003/research/possible-bodies/transformation-zoetrope.html).

## What the experiment does

Every station compares a continuously updated body with its most recent sampled pose. Twelve fixed poses record one cycle. Change the shared body between cube, sphere and unequal tetrahedron; add a witness mark; change the sampling interval; pause or reset. The browser also lets the reader scrub through a cycle.

| Study | Operation | What to attend to |
| --- | --- | --- |
| Translate | Horizontal offset `0.6 * sin(theta)` | Geometry persists while position changes relative to the fixed frame. |
| Rotate | One turn about Y per four seconds | A plain cube repeats its occupied geometry at quarter-turns; an off-centre mark makes those orientations distinguishable. |
| Scale | Uniform factor `1 + 0.3 * sin(theta)` | Proportions persist while lengths, area and volume change. |
| Combine | Scale, then rotate, then translate (`T * R * S`) | Several changes can disappear together when observation returns only at the complete period. |

The phase is `theta = TAU * time / 4`. The held pose uses `floor((time + 1e-9) / interval) * interval`, anchored at time zero. Changing the interval preserves the running clock. Four-second sampling always observes the same phase for these deliberately periodic motions. This is a property of these motions and this sampling rule, not a claim that translation or scaling generally leaves an object unchanged.

Start with the plain cube and one-second sampling. Watch Rotate, then add its mark. Try the tetrahedron at the same interval. Finally select four seconds and compare all four continuous views with their held samples. A complex body also returns after a full turn; complexity alone does not prevent recurrence.

## Relation to the existing zoetrope

`commons/artifacts/grand_zoetrope/grand_zoetrope.gd` contains twelve stored bounce poses on a rotating drum with slit walls. The individual bounce poses do not deform over time. In a physical 3D zoetrope, successive views of differently posed objects can give apparent animation; see [Philipp Artus's zoetrope](https://philippartus.com/zoetrope/).

This new bench isolates the sampling question. Its pose ring is stationary, and its live objects really change transform each frame. The held comparison is a sample-and-hold illustration, not a flashing display or a simulation of retinal perception. It does not establish that the existing drum already achieves a convincing zoetrope illusion in VR.

The distinction matters for the book: the returning shape does not prove that nothing happened. A mark, a clock and a fixed reference frame each retain a different part of the event.

## Files and use

- Reusable artifact: `commons/artifacts/transformation_sampling/transformation_sampling.tscn`.
- Pure motion model: `commons/artifacts/transformation_sampling/motion.gd`.
- Desktop fixture: `commons/testing/transformation_sampling_lab.tscn`. Run this scene in Godot; its top controls change body, mark, interval and playback, and focus each station. The artifact also supplies five physical pushbuttons.
- Registry key: `transformation_sampling` in `commons/artifacts/registry/transforms.json`.
- Browser source: `doc/research/possible-bodies/transformation-zoetrope.html`; copied to the local encyclopedia's matching public path.
- Reusable Godot checks: `commons/testing/probe_transformation_sampling.gd`.
- Render capture: `commons/testing/shoot_transformation_sampling.gd`.

The bench is registered and available for placement. It has not been inserted into a spine hall, and no `final.md` was rewritten for this experiment.

## Evidence and limits

`test-results.json` records **80/80 passing Godot checks**: actual pointer-button wiring, live-clock advance and pause, held samples, all three body rebuilds and marks, all 48 fixed poses, cube symmetry versus indexed-point movement, asymmetric full-turn return, distance/area/volume invariants and composition order. Production source hashes stayed stable during the test. No script errors; unrelated project startup warnings are retained in the logs.

Browser review exercised body selection, the witness mark, pause/play, reset, scrub and all three sampling intervals. At paused time 3.5 seconds with a four-second interval, the displayed sample remained 0.000 seconds. At time 1.000 seconds with a one-third-second interval, the sample reached 1.000 seconds. Playback resumes and disables scrubbing. The current page fits its measured default viewport without horizontal overflow.

`check-browser-state.cjs` separately checks the browser script against a mocked DOM: **17/17 state and formula checks pass**, recorded in `browser-state-checks.json` and `.txt`. Run it with `node doc/space/transformation-sampling-2026-09-17/check-browser-state.cjs`. These checks complement the actual browser review; they do not replace rendering checks.

The browser represents the ideal sphere with a fixed tessellation while rotating its material mark. Godot uses a finite sphere mesh, so it approximates continuous rotational symmetry. Neither result proves perceptual equivalence pixel by pixel. No headset test or performance claim is made.

Godot rendered and saved all eight images here; the overview and focused rotation were visually reviewed after arranging the benches and camera, and the earlier asymmetric view was checked for visible geometry.

![Rotation study: a live pose, a held sample and twelve fixed poses](rotate.png)

The next spatial decision is whether this becomes a small symmetry encounter beside the existing rotation artifact, or a comparison at the combined door. Keep bodily passage and optical sameness legible as separate experiments.
