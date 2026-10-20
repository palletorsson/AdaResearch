# One history, two receivers; one resemblance, two procedures

The active hall compares `ca_rule_explorer` with `sierpinski_pyramid`. Its stable ID, CA_AgentsCircuits, retains an older circuit proposal. Wireworld and CellularAutomata3DStacked are not installed in this map. Their earlier notes and code examples remain in [wireworld-proposal.md](wireworld-proposal.md), as development material.

## Start with the same state

The explorer’s `#study:neighbours#rule:90` configuration begins paused with 32 cells, one central occupied cell, and space for 24 stored rows. The usual panel selects a rule; STEP applies one synchronous neighbourhood update. SEED switches between one cell and two adjacent cells, resets the history and pauses. RST replays the selected seed; it does not override that choice.

The actual evaluator in `commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd` is:

```gdscript
var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
return (rule >> neighborhood) & 1 == 1
```

Indices wrap. From the single seed under Rule 90, generations 0–15 display triangular relationships. At generation 16 the two expanding edges meet on the 32-cell ring and cancel. Subsequent rows are empty. This is a finite periodic demonstration, not an indefinitely growing triangle.

## Let the history occupy the comparison space

This map alone adds `#room:comparison`. `neighbour_study.gd` installs `comparison_floor.gd`, a read-only receiver with 32 × 24 available sites at 0.18 m pitch. It covers 5.76 × 4.32 m between the desk and the pyramid. At most 768 small tiles are drawn with one MultiMesh. Unused history rows have zero-size transforms.

The desk stores newest first. The floor reverses that stored order so walking away from the desk follows the oldest retained row toward the newest. After 24 rows it displays a moving window, not the complete history. The caption gives the actual retained generation range. Colours come from the same explorer values. Rule, seed, reset, step and run remain the existing controls; the receiver has no rule evaluator, clock, random input, buttons or collision.

A dark cell is a drawn zero, not a hole cut through the museum floor. Walking into it introduces a comparison of representation and bodily support without changing the automaton’s meaning.

## Compare making, not just outlines

The pyramid uses `algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd`. Its inherited recipe makes six calls at each depth: four lower corners and two upper placements. Depth four gives 6⁴ = 1,296 cube instances. Descendant spacing halves while leaf size stays fixed. Some cubes overlap. The hall keeps the existing .42 scale, plinth and placement; the optional later comparison controls are not enabled here.

Changing the explorer’s seed changes its history and the floor image. It does not rebuild the pyramid. A related triangular appearance does not establish the same computation, topology, or traversable openings. Neither this finite image nor the pyramid establishes computational universality; that requires a separate construction and argument.

## Evidence

The native museum probe and before/after photographs are in `doc/book/iterations/2026-09-25-ca-pattern-correspondence/`. Checks cover actual mouse-ray controls, an independent Pascal-parity expectation for the first sixteen Rule 90 rows, exact desk/floor correspondence, reset and scrolling, preserved pyramid transforms, and controlled CharacterBody walking. Headset comfort and learner understanding remain to be tested.


## Complete learner reconstruction — 8 October 2026

`tutorial.md` now prints `procedures.gd`, `comparison.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_AgentsCircuits`. They run on the existing Day Zero `PointStudy`. The first file owns the two procedures; the second builds the table, plinth, instances, labels, support and input. The third is byte-identical to CA_SoftRules. No prepared study children are required.

The 32-cell rule reads old left/right and writes their Boolean inequality. Centre does not affect Rule 90. The learner stores chronological independent snapshots, stops at 24 rows and renders unused rows at zero scale. The museum retains its existing newest-first storage and scrolling receiver. The supplied recursive function preserves all six installed offsets, including the extra crown; depth three yields 216 leaf entries versus the installed depth four's 1296. Entries may overlap. Every leaf cube keeps a fixed size. Learner cube instances are visual, on a solid plinth; they do not recreate the large prefab's individual colliders.

The comparison branch of `neighbour_study.gd` now mounts the existing `hand_point.gd` adapter, already used by the opening. Moving the held point selects the current row address. Its trigger calls the existing STEP operation and pauses. Release parks it at the selected address. Moving it does not edit state. The compact model uses Enter for STEP, R to replay, C to switch the seed. The installed SEED/RST controls remain VR-operable.

Room changes preserve all three authored artifact tokens, their placements and the level floor. A sculpture reservation clears incidental objects from the approach. The generic gate is disabled; entry and exit move to source(6,0)/(6,17), with supported approaches. Only this hall's generated plan row is rederived.

Validation: 29 learner and 38 museum assertions pass in native Godot 4.6. All eight truth cases and 240 mixed-start updates match the general evaluator. Actual ordered recursive placements at depths 0–4 match the learner recipe. The three-seed transfer predicts [13,19] and unchanged copies. Two deliberate faults are detected. Native supplied XRTools poses test pickup, inspection, trigger and release in both models. A CharacterBody walks over dark floor cells without changing the record. Four routes provide 158 layer-1 capsule and level-floor samples.

The initial learner run found a typed-array ternary assignment; `seed_sites.assign(...)` fixes the printed script. The initial museum colour equality was too strict for native MultiMesh storage. The final measured maximum RGB difference is 0.00009766, below one 8-bit channel step; transforms and Boolean records remain checked independently. First-pass logs are retained in the report's diagnostics.

The main explorer, comparison floor and pyramid scripts remain byte-identical to this pass's baseline. Final runs have no SCRIPT ERROR or Parse Error. No physical headset, Quest performance, independent student, full portal transfer or full secondary-interaction audit is claimed. Existing blank wall frames remain. Image inspection caught an inherited five-copy caption, inconsistent with this configuration's extra crown. Only this hall's two captions and obsolete Wireworld blurb are corrected in the book/source/shipped catalogue records. Native assertions verify both new wall captions. No other hall's catalogue text is changed.

Review: `doc/book/iterations/2026-10-08-ca-two-ways-to-make/index.html`, before/after above and inside images, full texts, exact scripts, native receipts and review ZIP. Next: CA_EdgeOfChaos.
