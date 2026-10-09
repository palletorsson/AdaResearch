# Line Space Workshop

A primary encounter in `Point_Lines`: three small studies built from independently grabbable, fixed-length segments.

1. **Combine:** parallel → plus → X → grid.
2. **Leave the plane:** flat grid → separated crossings → twelve-edge frame.
3. **Change your view:** parallel rails → a planar drawing whose three segments meet.

Each bay has NEXT and RESET on a one-metre-high plinth. NEXT cycles that bay's presets; RESET restores its current preset. Both refuse replacement while any of the bay's rods is held. XRTools handles grabbing and turning; release freezes the new arrangement. The rods use physics layer 3 (mask value 4), matching the project's pickup functions. Whole rods move: endpoints are markers, not separate stretching handles. No faces are generated.

`line_space_workshop.gd` owns geometry and controls. `workshop_rod.gd` extends the existing XRTools pickable implementation. The scene is registered in `commons/artifacts/registry/primitives.json` and placed at grid `(12,11)`, facing 180°, without an added support plinth. The three control pedestals belong to the artifact itself. Its 3.8 × 2.3 metre floor marking is visual; only the control pedestals are solid.

The book passage is `<!-- @line_space_workshop -->` in `commons/maps/Point_Lines/final.md`. The saved encounter is `combine` in `commons/data/encounter_routes/Point_Lines.json`. Older line studies remain in the hall as comparisons.

The teaching distinction is between an actual spatial relation and its projection. Moving one family of grid lines 0.25 m in depth makes projected crossings into separated segments. Parallel rails retain their direction in space; the drawing really joins endpoints. The frame prepares the later distinction between triangle edges and a filled face.

Validation: `ada_run/line_workshop_check.tscn` exercises geometry, control callbacks, the real grab driver, held-reset protection, release position and collision layers. `ada_run/line_workshop_route_check.cjs` checks the production encyclopedia route model and preservation of earlier content. `ada_run/line_workshop_museum_check.tscn` loads the actual endless museum and captures the placement. Headset reach, readability and comfort remain for in-person testing.
