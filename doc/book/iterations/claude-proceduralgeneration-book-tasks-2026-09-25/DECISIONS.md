# proceduralgeneration — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_proceduralgeneration.001`–`.014`: thirteen applied and closed, one left open with a note. Walking the spine from its far end (forum 260925-tvljg). Prose and one drawn figure; no map, scene or code was changed.

| task | hall | what landed |
|---|---|---|
| .001 | PG_Caves_Mazes | the desktop check gone; the generator carries the claim (every cell visited, walls removed only between visited cells, one connected tree) |
| .002 | PG_Space_Colonization | the colours the hall draws: mauve threads for requests, gold stubs for unit directions, the white half-metre step (colonization_lesson.gd:109-116) |
| .003 | PG_Branching_Growth | "the Organic Space work nearby" |
| .004 | PG_Mirrored_Patterns | the closing sentence names Soft Bodies and what carries across; the Soft Bodies opener (edited today) reaches back to this sequence |
| .005 | PG_Genetic_Evolution | the paragraph leads with genome, builder and evaluator; one bridge (Shape Grammars' six-specimen family, the Forge's height test) |
| .006 | PG_Genetic_Evolution | the prose option: the cased screen below the decks named, and what it does not read |
| .007 | PG_Mirrored_Patterns | "which the desk calls rhizome, lets every site join its three nearest neighbours"; `[^rhizome]` credits Deleuze and Guattari and says why the opening is a tree |
| .008 | PG_Sculpted_Forms | the excerpt attributed to the section cut, "carrying the operation the four cores already have" (dome.gd:425, :456-462) |
| .009 | PG_Sculpted_Forms | "repaired scene" gone |
| .010 | PG_Percolation_Network | "along one whole side of the cube"; "those on the side facing the source" |
| .011 | PG_Space_Colonization | **figure**: a line diagram drawn from the study's own numbers (root, three pink points, three gold unit directions, the white step), `doc/book/figures/proceduralgeneration/first-step-three-requests.png`, generated with matplotlib and checked in code: the child lands at (0, 0.5) |
| .013 | PG_Space_Colonization | the name said where the chapter says "the name of this artifact"; `[^runions]` credits Runions, Lane and Prusinkiewicz (2007) |
| .014 | PG_Sculpted_Forms | the extent as a number: two cells each way, a two-and-a-half-metre box around a one-metre cube (cube_size 1.0, voxel_size 0.5) |

Left open:

- .012 (PG_Caves_Mazes / PG_Mirrored_Patterns): the two desk TITLES live in `commons/artifacts/timing_machines/pg_workshop.gd`, which is untracked in git (another writer's uncommitted file), so the desk cannot be changed from here; retitling the two chapters to the plates instead is an authorial call.

Verification: every replacement matched exactly once; footnotes defined; fences balanced; endings preserved per file (Space_Colonization LF, the rest CRLF; no mixed files); the figure's arithmetic asserted in the generating script.

Disclosure: PG_Genetic_Evolution as found carried a one-line uncommitted hunk from another writer (24 September); it lands here whole: PG_Genetic_Evolution (2 lines). `before/` is the tree as found, so the diffs beside it are this pass alone.
