# Compare procedures and representations

This hall follows Fractal_GoldenSpiral and precedes LSystems_Grammar_Lab. It reuses two existing, tested instruments in a new comparison; the underlying algorithm scripts are unchanged.

## Installed controls

- `cantor_set:180#lesson:true`: NEXT/BACK select cuts 0–5; HISTORY switches the full record and latest generation; GHOST marks new removed middles; RESET returns to cut zero; RULE reveals the calculation. Initial length 6 m, thickness 0.12 m, row spacing 0.45 m. The lesson freezes physical intervals.
- `recursive_tree:180:0:0.42#lesson:true`: FORM, STRATA, REACH, ENDS, RESET and RULE. The generated block tree is reduced in scale, while its desk counter-scales to preserve physical button size. Readings share one generated geometry. REACH/ENDS volumes are visual annotations, not colliders.

For Cantor cut n, the current population has 2^n intervals of length 6/3^n m, total 6(2/3)^n m. HISTORY alters visibility and collision for earlier rows without deleting their nodes or advancing the cut. GHOST uses separate meshes without collision; those meshes are not in current_bars. The mathematical limiting set is distinct from these finite thick intervals.

The block tree calls generate_branches(tree_root, branch_origin, num_main_branches, 0, 3). Each accepted call creates branches, optionally details, then calls itself with current_depth + 1. The local RNG is seeded at build. Descendant views traverse the actual nested scene graph, excluding TreeLesson itself. ENDS marks centres of the deepest recorded blocks; these marks should not be described as exact botanical tips. Bounds include empty space, overlap and display choices; they are not an entropy or traversability measurement.

## Source excerpts in final.md

1. `algorithms/fractals/cantorset/cantor_set.gd`, perform_iteration: new_length = bar_length / 3.0.
2. `algorithms/fractals/recursive_tree/recursive_tree.gd`, generate_branches: the depth return and recursive call, copied exactly with surrounding indentation removed.
3. Next hall comparison: `commons/artifacts/lsystem_editor/lsystem_editor.gd`, PRESETS[0] = [F, {F: F+F-F-F+F}, 90.0, 4, Koch Curve]. This is not the equilateral generator shown by koch_curve.

## Room staging

The twelve-row approach leads into the former 19×21 museum enclosure. Its raised sphere cell remains; the obsolete teleporter floor hole is filled. Historical July/August grid maps and the current map are archived under doc/space/fractal-synthesis-2026-09-14. All ten original tokens remain. `fractal_procedure_gallery` adds a physical prompt, warmer lighting, hides standalone screen overlays, and stages selected rear specimens for comparison.

Koch uses its existing trace mode at 0.09 scale. The gasket is held after three subdivisions at 0.3 scale. Cloud wind animation is held. The Fibonacci view calls its original display methods once at time zero and stops its local _process; its downward diagram is raised above the floor. These are explicitly held examples, not new generated procedures. Other works, including the attractor and Romanesco, retain their own animation. The fixture runs only in Fractal_Synthesis and stops scanning after staging; failed discovery reports an error after 15 seconds. Original scenes elsewhere are untouched.

Desktop pointer, geometry and route evidence belong in the dated review receipt. Human headset reach, readability, comfort and Quest performance require a later pass. Rear works retain development opportunities; this hall does not certify every secondary interaction.

Scene reference repairs: koch_curve.tscn now resolves its declared script path instead of a duplicated UID shared with koch_curve_1. apply_grid_config stores evidence before _ready and builds only once meshes exist. RecursiveTreeUI resolves its owning root with get_parent().get_parent(), independent of instance name. The final runtime test includes ordinary and preconfigured Koch scenes.

## Recipe comparison table — 8 October 2026

The room-local `fractal_procedure_gallery.gd` now installs one table between the original Cantor and block-tree desks, at hall-local (9.5, 0, 8.5), facing the approach. It does not alter their generators or the map's artifact tokens. Native validation found the old exit marker at grid (1,31) blocked against the side wall. It now occupies (9,31), aligned with the existing rear doorway; only those two utility cells changed. Walking through that portal completes arrival in LSystems_Grammar_Lab. The destination's own onward exit reports an obstruction and remains a separate next-hall repair.

`commons/artifacts/fractal_recipe_table/recipe.gd` is the complete printed learner program. The installed `museum_recipe_table.gd` inherits it and adds the plinth and nearby NEXT, KEEP, RESTORE and RESET buttons. The carried PointBody chooses one of three retained fractions (1/4, 1/3, 2/5) through its local x position. Its trigger keeps an independent dictionary copy. Both interval arrays are reconstructed from their own settings, with a common display scale of 0.34. Three cuts is the initial depth; five is the cap.

NEXT, RESTORE and RESET are refused while the point is held. RESET edits LIVE only; KEEP replaces the previous snapshot. This is one local in-memory comparison, lost when the instance unloads. No saved drawing, imported student record or cross-hall persistence is implied. The production adapter ignores global Enter; Enter is an additional control in the separate learner reconstruction.

The next hall's Cantor grammar is a comparison for the thirds variant only. Its fitted line segments must be normalized to the six-metre seed before comparison. Quarters and two fifths do not follow from that same F/f grammar. Native assertions and rendered museum evidence are recorded in `doc/book/iterations/2026-10-08-synthesis-a-rule-kept/`; they do not establish headset comfort, Quest performance or learner understanding.
