# Body — what does the room keep?

The encounter has three different consequences: nearby slats turn and return, a low lattice loses cells, and nearby blocks shrink and return. The manuscript already has its critical lead in the partial record left by the visitor. Keep that lead and make it visible.

## Applied

Canonical `commons/maps/Trans_Body/final.md` keeps its opening, three encounter anchors, three code excerpts and closing question. The distance explanation now introduces the two distances before the response details. The carving margin is explained through pressing forward rather than through a long account of an inert implementation. The blocks' resting gap stays explicit without declaring one universal shoulder width. The ending recalls riding the cube and taking the bottle; it no longer casts earlier participation as passive watching.

A paired native museum image shows the low lattice before and after the actual museum body crosses it. Its cut is open above. The chapter preserves “Some of you passed above the entire record” and asks whether the following body will fit. The image is an elevated comparison view, not the visitor's eye view.

The supporting intent now acknowledges earlier participation and identifies dark_sphere as a secondary legacy placement. The tutorial records the illustration and repair. Core text hash is current. Original/current text, exact manuscript diff and all supporting/source differences are retained here.

## The repair

During capture, blocks that had responded once were floating 0.575 m above the deck. The diagnostic in `block-seating-before.json` measured the transition: all nine began on the floor; six responding blocks acquired the extra height, including after returning to full size.

The cause was the initial `AnimatableBody3D` position at the artifact's base. With physics synchronization, the initial centre was restored after the first size assignment; automatic grounding then raised the artifact. Later size changes used the intended local half-height on top of that unintended root offset.

`commons/artifacts/approach_scale/approach_scale.gd` now assigns each body's standing centre height before adding it to the tree. This is the sole production code change. No dimensions, reach, response law, collider sizes, map placement or controls changed. All nine blocks remain seated at initial, reduced and restored sizes; visible mesh and collision agree.

## Evidence

- 80/80 focused checks pass in the isolated production museum. Five supplied movement segments cross the three thresholds using the normal museum CharacterBody3D and `move_and_slide` on physics ticks. The body is placed separately at each encounter's approach; this is not a full continuous entrance-to-exit walk.
- The normal body is 0.64 m wide and 1.5 m high. Its straight lattice crossing removed 132 of 484 cells. Those cells remain absent after departure and the final block comparison. No capture code deletes cells directly.
- The slats close after the body walks out of range. All nine blocks regain their size and remain on the floor. Grounding and mesh/collision equality are checked per block in three states.
- The existing standalone `probe_body_transform_artifacts.gd` regression passes. Its copy here changes only the report output path. Recognised-body response, rejection of an unrecognised character, closure and cut retention remain intact.
- Eight final native views and the composed book figure were inspected. The figure is made only from native captures and captions.

An initial capture probe used an unsupported packed-array method and stopped before the last comparison. Its log is retained; the corrected runner also requires completion of all three comparisons before it can pass. The pre-repair runtime evidence remains in `before-runtime/`. The final run has no script/parse errors and exits 0.

The field's existing narrowest-gap warning can still fire during a successful selected walk: its estimate includes other nearby block pairs. This logging/estimator question is separate from the repaired base-height error and is left as a named follow-up. The actual selected walk supplies the passage evidence here.

Headset comfort, room-scale variation and learner understanding remain untested. No live museum restart, live bake/save replacement or commit. The private runner redirects museum outputs away from the active game.

## Next

The Moving Boundary, canonical map `Trans_Pit`: the same question of available room continues, but a clock supplies the motion whether the visitor approaches or stays still. Read and show that timing before adding another explanation.
