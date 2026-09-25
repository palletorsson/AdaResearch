# boolean_surfaces — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_boolean_surfaces.001`–`.014`: nine applied and closed, five left open with a note. Walking the spine from its far end (forum 260925-tvljg).

| task | hall | what landed |
|---|---|---|
| .002 | Boolean_Verbs | **map edit**: `"piers": false` in `map_info.museum`. The plan (`ada_run/em_plan.json`) is derived and was NOT regenerated here; the next `python tools/em_map_halls.py --apply` picks it up |
| .003 | Boolean_Gallery | **map edit**: `"museum": {"piers": false}` added to `map_info`; same note |
| .004 | Boolean_Works | "the opening is on the end to your right as you arrive, under the sign TRY THE OPENING" |
| .005 | Boolean_Verbs | the seam plate and the building vitrine given a paragraph on the argument bench; the closing sentence points at the building |
| .007 | Boolean_Works | the capture-rig aside replaced with what a body can test |
| .008 | Boolean_Works | the exit aimed at the trail field (and Physarum's opening, edited today, picks it up: "The previous hall cut one hollow for one body...") |
| .009 | Boolean_Works | **map edit**: `csg_compose_workbench` → `csg_compose_workbench:0:0#algebra:complete` (five benches: union, intersection, A − B, B − A, symmetric difference; csg_compose_workbench.gd:244). The paragraph rewritten around the fifth solid. What the code builds is the union with the shared region subtracted, and the shared region is inside, so the chapter says what a visitor will find: from outside it is the union again, a solid carrying a hollow it never shows |
| .010 | Boolean_Works | the task framing cut in the workbench and rack passages; the observation kept |
| .012 | all three | H1 titles from each map_info.title |

Left open, with a note on each:

- .001 (Gallery): re-spacing two rows of overlapping shells is a layout decision (row 27 or not, "six rows" or "seven"); not made here.
- .006 (Gallery + Works): rotating three fronted rows and one coincident_face by 180 is a placement decision that wants a headset look before it is made; the evidence (backing at z −0.016, tags at +0.02, the author's own `:180` on csg_intersection_demo) is strong.
- .011 (Works): removing the DirectionalLight3D and the empty WorldEnvironment from sphere_splitting_showcase.tscn changes the lighting of six halls; a scene change for its own commit.
- .013 (all three): eleven bare `3t` cells print the Point sentence in the grid/desktop lane only; the words are a design choice (`3t:A_UNION_B` etc.).
- .014 (Works): whether the rack of 75 unfrozen 2 m boxes drifts needs a Godot run; the sentence stands as written.

The two dirty map files (Verbs, Works) carry another writer's uncommitted whole-file reindents from 20 September (2,396 and 4,629 lines); the Verbs reindent also added a museum block (`wall_height`, `gate_depth_rows`) HEAD does not have. Each edit was applied to the working tree AND to HEAD's copy, and HEAD's copy with the edit was staged as a blob, so the commit carries one change per file and the foreign hunks stay in the tree as found. Gallery's map was clean and is added plainly. Pathfinder run on all three from the working tree (result in the run log).

Verification: every replacement matched exactly once; footnotes defined; fences balanced; the three chapters CRLF and kept CRLF, no mixed files; all three map files parse as JSON in the tree and in the staged copies.

Disclosure: the three chapters as found carried uncommitted hunks from another writer dated 24 September (a rewrite of the arc, never committed by anyone): Boolean_Verbs (79 lines), Boolean_Gallery (109 lines), Boolean_Works (139 lines). They land here whole; `before/` is the tree as found, so the diffs beside it are this pass alone.
