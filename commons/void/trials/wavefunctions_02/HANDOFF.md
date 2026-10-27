# Waves transfer: coordinator review

Batch 22, 21 October 2026. Codex: Pendulum and Sine Space. External Claude Opus: Unit Circle and 3D Wave Propagation. Codex reviewed both delivered floor fragments against their source scenes/scripts, integrated them, and ran native and editor validation. All 28 original IDs, configs and scales are retained. Standard floors remain 42 x 32 m, with 6 m storeys. Curation and chapter rewrites are deferred.

## Editor evidence

All 28 placements export with independently editable geometry (the unbuilt pipe is explicitly a marker). 31 checks pass for move, copy, rotation, native-layout and Desktop-mirror save/reload, stale-save rejection and unchanged source hashes. Browser inspection confirms the restored coloured-ball geometry and the pendulum controls.

## Controls and native evidence

The accepted run has 211 desktop/synthetic-XR assertions. It covers shaft clearance at the centres, arrival, residency, retry and the active visitor camera, plus native input for the draw-point pickup, wave-tray RELEASE/RELIEF/RULE, corridor FREEZE/RESET, Unit Circle RUN/PAUSE and REPLAY, films, and lattice COUPLING/DRIVE. The quarter-turn Unit Circle check uses the slider API and is labelled accordingly. The original bridge and paintings are observed as animations, not asserted to be newly rideable/grabbable. The wave pool retains and moves 400 collision tiles; rider transport and headset performance were not tested. No engine errors in the accepted run. Seven native screenshots and measured bounds are in evidence/.

## Minimal integration fixes

- Void-only adapters skip one-vertex line strips in PendulumWave, OscillationCurve and the three WavePaintings pendulums. All original scene export values are copied when attaching the adapter. Multi-point drawing and runtime controls are inherited.
- Claude's floor-3 handoff assumed the floor-relative colour-ball adapter was already active. It was not: native review found balls resetting near world zero. The coordinator enabled the existing adapter for this original colour-ball placement and added a native floor-relative check in both modes.
- Editor export waits for the original frame-by-frame colour-ball construction to finish before freezing the scene; it does not fabricate substitute balls.
- BigPipeSystem's source disables auto_build and ignores the path token. Its runtime remains empty, with an explicit labelled editor marker for arranging the original placement. It is not a functioning pipe.

## Fit and dependency review

The sine surface retains its original 18 x 14 m geometry. It extends one metre beyond the north edge and meets rear pillars; its raised rim needs access during curation. The neighbouring rain keeps the original bounded recycling behaviour. Foucault reaches about 0.35 m into the upper slab at the retained source height/scale. Some instrument bases and decorative bars extend below the slab.

Claude measured the pool's 13 x 13 m deck correctly, but its claim that the wider catalog bounds were stale was incomplete: native bounds also include waveguide rings. The deck is 1.1 m high and still needs a route onto it. Its source decorative Frequency/Amplitude bars extend below the floor. The 0.25-scale oscillating bridge remains the source tabletop model, with moving StaticBody platforms. Audio monitor input is the existing bus; no new sound feed is invented. Original plinth/grid-architecture dependencies remain recorded for curation.

No source artifact or source chapter is changed. No physical-headset test. Web models are geometry snapshots; Godot runs the original interactions.

Open: http://localhost:3003/lab-editor?mode=void&trial=wavefunctions_02&floor=1
