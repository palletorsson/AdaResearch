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
