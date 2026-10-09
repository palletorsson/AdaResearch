# Paint — the surface keeps working

The chapter already gives colour a new problem: a gesture arrives on a surface that is changing without waiting for its maker. Its account of the two inputs, drawing coordinates, finite resolution, feedback, fading and unequal clocks is supported by the placed artifact. There is no reason to rewrite mature prose merely to make this pass visible.

## Decisions

- Preserved every existing paragraph, code excerpt and artifact anchor in Color_Paint/final.md, including the Albers comparison and the handoff to Color_Walls.
- Added one shared four-state figure after “Which part of the image can you still call yours?” It uses native frames from the actual production museum: before pickup, a second gesture, release and a later image. One camera, automatic input running throughout.
- Added bounded evidence to technical.md and field_notes.md; refreshed only this hall’s manuscript hash in the core encounter file. Intent, tutorial and critical companion remain unchanged.
- Kept the complete museum configuration, primary/secondary works, scripts, scenes, controls and shader. No production repair was needed.

## Findings

30 focused runtime assertions pass. A supplied grabber picks up an existing live pigment and moves it through actual ray hits on the rectangular canvas. The captured ball is orange ff9900, radius 24 pixels, snap resolution 64; its settings were not overridden. It writes 79 samples. Release stops manual input and restores its dock while the automatic painter continues.

A separate diagnostic pauses automatic input after manual release and after pending brush input clears. Over 120 rendered frames the image changes and mean RGB distance from white falls from 0.21413 to 0.15950. This supports feedback/fading in this run. The pause is a probe condition, not a visitor control. The retained image is not a retrievable gesture history or evidence of physical pigment mixing.

The ordinary museum controller reaches the tray and returns using supplied key input. The 98 Albers studies remain. The retained gallery image shows several studies through an opening; it is not a complete, unobstructed view of the wall. Native and composed canvas images have been inspected.

## Scope and provenance

Before sources are in before/ and baseline-hashes.json. The manuscript has exact before/after files and a unified diff. Runtime report, native PNGs, raw canvas images, source hashes and a reproducible probe are retained here. build_figures.py assembles the real images; build.py produces the reading/review page. verification.json records preservation and HTTP checks.

No tracked hand, headset comfort, colour calibration, learner or performance result is claimed. No live restart, live bake/save overwrite, commit or frozen full-book/audio rebuild. A first gallery camera was mostly occluded; the closer retained capture is explicitly partial. No claim of a full-hall traversal.

Next: Color_Walls — colour becomes a partition that organises the room.
