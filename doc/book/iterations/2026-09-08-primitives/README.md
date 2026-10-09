# Primitives: first ten-action pass

This pass revised all ten primitives `final.md` manuscripts and their primary encounter order, repaired shared instruments, added a repeatable triangle comparison, and transferred one recording experiment into `Trans_Translation`. The live results and next actions are on [Museum Progress](http://localhost:3003/museum-progress?sequence=primitives).

The sequence now has a source-grounded draft for each room. That is a writing and implementation milestone. No teacher-led or solo learning encounter has been accepted from these checks.

## What was established

- The snap sphere's retained metre values distinguish adjacent 0.05 m positions; lattice indices, released marker and sampled tip agree in the inspected Point One and Grid configurations. The table remains visible after release.
- Dot and stick pens show retained count, capacity, movement threshold and grid. Their timer-derived relative supplies a different description because time, including stationary time, can add samples there. The actual-scene probe passes 76 checks.
- A supplied 1 m/s body previously produced 5 m/s when the walking recorder admitted a sample after five frames. Matching elapsed time to the measured displacement fixes that error; timed, distance-gated and every-frame comparisons pass.
- The same six-corner L produces four fan triangles from either starting corner, but beginning at B sends two triangle centroids outside the boundary. The new **NEW OUTLINE** control preserves completed faces and permits changing the first corner. Actual pointer-button and timed-placement events passed.
- All ten rooms have one primary group with an explicit order. The spine exporter now understands grouped role records and expands their internal order; the full manifest was regenerated from all 190 rooms.
- The manuscripts no longer promise unplaced artifacts, every-frame pen history, a permanent visited-cell dictionary, or the portal animation's nonexistent 54-step experiment. Mathematical conditions, current behavior, interpretation and proposed builds remain distinct.

The scoped measurements are in [snap_and_pen.json](snap_and_pen.json), [trace_speed.json](trace_speed.json), [triangle_fan.json](triangle_fan.json) and [routes.json](routes.json). Four revisable lessons were appended to `doc/curation_lessons.json`. The source review and manuscript fingerprints are in [manuscript_review.json](manuscript_review.json).

## Run the next room walk

Start with Grid, where a small implemented correction has a clear comparison. Use the actual chapter and controls. Record the mode, room, source revision, viewing distance and any assistance supplied.

For the teacher-led walk, let each learner make a prediction and act before offering the explanation. Ask someone other than the operator to describe the result. Record where the group needed a hint or could not see the same thing.

For the solo walk, give the learner the chapter and room without additional instructions. Record where they stop, skip an encounter, misidentify a control or read ahead for an answer. Ask them to explain the same distinction used in the group walk. Matching answers are evidence to assess, not something to infer from matching text.

| Room | Attempt before explanation | Check the learner can distinguish |
| --- | --- | --- |
| Point One | Move the point slightly, then compare the world card, coloured frame and target. | A position, its reference, rounded display and the target's tolerance. |
| Lines | Connect snap points, move an endpoint, then follow or depart from the floor marking. | Geometry, persistent adjacency and a direction given to a body. |
| Trace | Loop, pause and make a small bend with default and 80 mm pens in free space. | Movement trigger, rounding and accepted-point capacity; a pause need not add a position. |
| Grid | Compare adjacent sphere positions, then walk a loop on the recorder's coarser lattice. | A 0.05 m hand instrument, a 1 m walking lattice and the finer sampled reference. |
| Triangle Context | Close a triangle; draw the specified L from A and then B using NEW OUTLINE. | The same boundary, a changed first vertex and a fill that crosses the intended boundary. |
| Polythedra | Compare the open trihedron, tetrahedron and prism's enclosure or obstruction. | Rendered surface, collision and an actual route or support. |
| Animated Cube | Compare the net and two builders; deform one and retain the other as a comparison. | Faces and rendering triangles, fixed connectivity and a changed geometric shape. |
| Ignorance | Compare three sphere approximations from two distances and read the budget display. | A calculated budget, visible faceting and a tolerance chosen for a purpose. |
| Portals | Compare a reachable early and later ring, then reverse the reading order. | Finite refinement, an ideal limit, and an aperture versus transportation. |
| Melencolia | Predict a connection pattern, complete it, then choose a purpose it did not test. | Recognition, geometric correctness and useful consequence. The support platform remains a proposed build. |

For each attempt record: **prediction → action actually possible → observed result → learner's account → named limit → next discrepancy**. Record teacher and solo results separately. A blocked view or unreachable control is a spatial finding even when the underlying script works.

## Spatial findings still to resolve

The existing map model found a structural entry-to-exit route in all ten rooms. Its cached body footprints flag Point One and Lines. These are inspection leads: runtime floor construction, collision and unmeasured artifacts can differ from the static model.

Full Grid captures and isolated control captures were inspected. The new snap table and restart instructions fit without clipping at about one metre in the isolated render. Older floating coordinates have angle and occlusion problems. The whole-map GL compatibility capture also showed material problems; it cannot establish headset legibility or an accepted walkthrough.

Melencolia's current completion hides the puzzle but spawning is disabled, so the promised support does not appear. This is a build candidate with a reach-and-use test. The portal ladder has nineteen 4.5 m intervals; its full footprint and return route need an in-room inspection. Neither issue is solved by having a tagged paragraph.

## Reuse the mechanism with its limits

Translation received the same recorder speed correction, a revised trace passage and one authored outline. Transport remains its primary encounter. A pause is included in the unsnapped recorder's next measured interval; a coloured segment is not proof of an instantaneous speed or a complete account of a journey.

The timer-derived pen was the useful exception: it shares code while deliberately keeping a different kind of event. The reusable practice is to inspect the trigger, coordinate frame, retained fields, quantization and eviction for each instrument, then choose a gesture that exposes an omission. The current schema need not decide which gestures or purposes deserve to count.

## Re-run bounded checks

From the repository root, with the Godot executable available as `godot`:

```text
python -m unittest tools.test_museum_progress tools.test_museum_actions tools.test_build_spine_artifact_order
python tools/build_spine_artifact_order.py --seq=primitives --print
godot --headless --path . --xr-mode off --script res://tools/probes/museum_snap_and_pen.gd
godot --headless --path . --xr-mode off --script res://tools/probes/museum_trace_speed.gd
godot --headless --path . --xr-mode off --script res://tools/probes/museum_triangle_fan.gd
```

The probes use real scenes with supplied positions. They do not measure human learning or headset ergonomics. Existing project autoload/audio/logging diagnostics also appeared during the runs; the recorded assertions concern the named instrument behavior.
