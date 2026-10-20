# B11 — what sheltered you now moves

2026-10-13 · **Implemented.** See [TRANSFORMATION.md](TRANSFORMATION.md) for the result, native captures and 82/82 phase/collision checks. Claude's unchanged probe was rerun by Codex: 114 flights, exit 0. Existing 54/54 stage, 47/47 desktop and 27/27 Primitives checks also pass. The planning record below preserves the original baseline and scope; it is not a list of pending implementation tasks.

Runtime change: `commons/hazards/biome_ladder/ladder_encounter.gd`. Codex phase/collision probe: `tools/probes/biome_transformation_cover.gd`. Claude's probe source was left unchanged. Next requested handoff: Claude independently reviews the implementation and new phase evidence.

## What Claude established

Claude added `tools/probes/biome_ladder_cover.gd` and recorded 106 actual skull-projectile flights in `ada_run/biome_ladder_cover/report.json`. At the planning review, all four recorded source hashes matched the then-current files. That baseline is preserved in `claude-cover-before.json`. The report records 10:05; Claude's review entry was appended at 10:35.

| Stage | Exposed shots reaching player | Standing shots stopped behind forms | Lower-aim shots stopped |
|---|---|---|---|
| Primitives | 3/3 | 6/12: all six tall shelters, none of the six low forms | 11/12 |
| Transformation | 5/5 | 0/11 | 9/11 |
| Arrays | 5/5 | 0/10 | 10/10 |
| Colour | 5/5 | 0/10 | 10/10 |

Two additional screened lane shots in Primitives were stopped. The probe exits 1 because no tested standing shelter works in stages 1–3. Those stages still use the earlier low, outlying forms: `_landscape()` currently restricts taller cover to `stage == 0`. This is a missing continuation of B10, not evidence that its Primitives cover failed.

Limits: heads are held still; landscape motion remains active. These are sampled encounters, not coverage of every motion phase. “Crouched” lowers the aim target to 1 m without changing the player's capsule, so it does not validate headset ducking. Collision outcomes come from real flights; an additional ray/overlap query identifies a non-player contact after a projectile disappears. The approximate box prediction agrees with physics on 103/106 shots and should remain diagnostic, not the acceptance oracle.

## The next play experience

Recognise the box that protected you in Primitives. In Transformation, another box turns and changes what it screens; a sphere moves; a cylinder changes size. Wait, step out, fire, return. Arrays repeats these useful relations. Colour changes how the same world is read. A new operation adds a decision while an earlier ability remains useful.

## Build in this order

| Task | Concrete change | Proposed owner and files | Evidence required |
|---|---|---|---|
| B11.1 Carry cover forward | Retain tall boxes/cylinders and their near-route placement in all four stages. Keep the entrance pair of boxes still as reliable refuge; later forms can move. Low spheres/cones remain contrasting forms. | Codex: `commons/hazards/biome_ladder/ladder_encounter.gd`, `_landscape()` | A real shot is stopped behind a standing-height shelter in every stage; stepping out permits a hit. |
| B11.2 Make operations readable | Spheres translate along the route. Far boxes rotate about Y. Cylinders scale from their floor contact, with minimum height 2 m. Keep cones still this pass. The entrance pair stays fixed. Give each moving form one operation. | Codex: same file, `_landscape()` and `_physics_process()` | Two timed captures from one view show each operation; no rotation-only sphere; visual geometry and collider follow together. |
| B11.3 Preserve the floor progression | Primitives and Transformation use the outlined white floor. Arrays introduces the checkerboard. Colour retains its current disco floor. | Codex: same file, `_ground()` and `_update_floor()` | Stage 1 and 2 captures visibly differ for this reason; floor material assertions. |
| B11-test Independent acceptance | Extend the existing cover probe with explicit motion phases and named protected/exposed fixtures. Preserve the current report as a baseline. | Claude requested, not yet claimed: `tools/probes/biome_ladder_cover.gd`; findings in `CLAUDE-REVIEW.md` | Before/after report, source hashes, actual projectile contacts, clearly stated sampling limits. |
| B11-publish Close the iteration | Update the plan and captures only after checks pass. | Codex: publisher, `PLAN.md`, `HANDOVER.md`, own probes | Native before/after views and a short statement of what changed and what still needs play. |

Claude's suggested tipping cone is useful but deferred: a credible floor pivot and sweep add another placement problem. Visible box rotation already teaches the turn. Colour impacts and Tiling should each receive their own iteration.

## Acceptance for the implementation

- Preserve B10's static Primitives layout. Later stages inherit useful shelter. Do not require every low form to shield a standing player.
- Verify a fixed refuge in every stage and a rotating/scaling shelter at minimum, midpoint and maximum phases. Include fully grown hostile balls. First record geometry at an explicit phase, then test live motion during flight; label these separately.
- A visitor behind the designated refuge takes no hit from its screened head; a corresponding clear position receives that head's shot. Cover is relative to a firing direction, not immunity from the whole arena.
- Scaling stays anchored to the floor. Do not reuse scaling about a fixed centre that lifts the base or sinks it. Keep collider dimensions and transform consistent with the visible mesh.
- Across the motion cycle, keep a continuous central passage at least 1.8 m wide and verify a player-capsule sweep. Keep controls and pickups reachable. Record the narrowest measured passage; do not carry the static 2.1 m claim into moving stages without measuring it.
- Capture a turn that opens and closes a firing view from the same observation point. Motion should change an available action, not merely animate scenery.
- Rerun the independent cover test, the desktop input suite and the four-stage suite. Update assertions that intentionally described B10 as stage-0-only; preserve their collision and progression guarantees. Record all failures and process exit codes.
- Keep saved museum unlocks isolated in probes. One-hit ladder heads, three-hit player health, shot speed and skull count retain their current values.

## What follows

1. Desktop play of B11: can Palle recognise shelter, time an opening and use it? Then headset review of aim, ducking and motion comfort.
2. B12 Colour: a shot leaves a persistent, readable floor mark; RESET clears it. Settle independent tile materials and the relation to the disco clock in that task.
3. B07 Tiling: copy a legible mark using a source and a rule; then consider source/copy heads. The proposal exists, the encounter does not.

Keep the complete Arrays row on arrival. A successful shot creates the absent member. That choice makes absence a consequence of the player's action. No tutorial or final.md revision is required for B11.

## Coordination

Codex completed the runtime edit and its own phase tests; Claude is invited to review the new evidence independently. Claude's completed cover probe is already received, so the old “awaiting first test” handoff is obsolete. Any further Claude test extension remains a request until Claude records a claim. Coordinate through these shared source files while forum publication is unavailable. Do not edit each other's runtime or probe files without an explicit handoff.

Open the visual plan at `http://localhost:3003/biome-plan/index.html#next`. Edit this source file and PLAN.md, then run `python -X utf8 tools/publish_biome_ladder_play.py` to refresh the page.
