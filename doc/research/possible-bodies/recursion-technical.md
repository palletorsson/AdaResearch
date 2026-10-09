# Fractal_Recursion: inspect the operation before naming the form

The hall has four primary artifacts and retains six supporting works. Its tokens opt into `lesson:true`; other placements retain their existing behavior. Controls are physical push buttons arranged three across in two rows on a 1.12 m-wide desk. Each control is within 0.8 m of the same nominal reach point. The 1.18 × 0.36 m readout uses one transparent plane (14% opacity), a thin frame and opaque outlined text; it is tilted 35 degrees. Button touch targets retain their original size. RULE reveals the explanation; all four start waiting for input.

## 1. One self-call

`algorithms/fractals/example_8_2_recursion_vr.gd` draws one square and calls `_draw_recursive_pattern` once with `size * size_reduction` and `d - 1`. The initial size in this hall is 2.2 m; the ratio is 0.5. The source returns when `d <= 0` or `size < 0.01`. MORE and LESS request depths 1–7, producing 1–7 square meshes at these settings. The smallest term at depth seven is 0.034375 m.

LAYOUT switches between nested and abreast arrangements. COLLAPSE changes all drawn sizes to the last term's size. It preserves the number of generated squares and the mathematical term list; consequently the readout says *smallest term*, not visible footprint. This tail recursion can also be expressed iteratively. A nested image is not proof of a recursive implementation.

## 2. Four self-calls

`algorithms/fractals/example_8_3_recursion_circles_vr.gd` draws a ring and calls itself at four shifted centres in the XY plane, each with a smaller radius and one fewer level. For the desk's depths, the population is `(4^d - 1) / 3`: 1, 5, 21, 85, 341. The outer radius is 2 m. PACKING cycles fused 0.6, contact 0.5, open 0.35, dust 0.25; at DUST and depth five, the requested fifth-level radius is 2 × 0.25⁴ = 0.0078125 m, below the 0.01 m cutoff, so only 85 rings are generated. All four packings generate 85 at depth four.

The lesson fixture initially turns the native horizontal TorusMesh into the XY plane. This display orientation does not move the recursively generated centres. TURN returns to the source's tumbling orientation and rotation speed 0.3; stopping restores the face-on comparison. The source's periodic ten-second pause still operates while turning. Packing and depth changes reset the display pose for comparison.

## 3. Choose one cell

`algorithms/fractals/cubesubdivision/cube_subdivision.gd` subdivides **one selected cell per step**. It removes one and adds eight; after `s` splits there are `1 + 7*s` extant cells. This is not uniform eight-way subdivision of the whole population. Twelve steps leave 85 cells.

DRILL selects the fixed corner of the newest litter. SPREAD selects a shallowest extant cell. LOTS selects from the population using the private random generator seeded with 31415. Changing mode restarts; BEGIN replays that mode from the same seed. The initial transform is preserved by `_rebuild()`; the old `reset()` method is not used because it clears all cells without rebuilding the initial cube.

```gdscript
var new_scale = cube_scale * 0.5 * 0.9
var offset = cube_scale.x * 0.25
```

A child is 0.45 times its parent's scale. The gap is a display choice. DRILL reaches depth 12 in twelve steps; SPREAD reaches depth 3. Equal extant counts do not imply equal distributions of detail. The readout counts tracked extant cells, not queued nodes waiting to be freed at the end of a frame.

## 4. An authored chair

`algorithms/fractals/cubesubdivision/recursive_chair.gd` runs five construction stages under NEXT: cut and lift, flatten seat, extend legs, extend back, add armrests. The first stage divides a 1.5 m cube into a 3×3×3 lattice, assigns 4 leg cells, 9 seat cells and 3 back cells, and excludes 11. It also lifts the lattice by 0.75 m relative to the original centre. The completed model contains 20 kept parts after adding four armrest/support parts.

GHOST and SCAR instantiate the 11 removed positions; GONE hides them. Switching visibility replays the current deterministic construction stage so its retained geometry stays consistent. BEGIN resets to the original cube. NEXT stops at five rather than appending repeated armrests. These are authored stages, not a recursive self-call. The model is an exhibit; the text does not promise a functional seat.

## Space and continuation

The map uses its authored 17×25 layout in the endless museum, with a continuous floor, three-cell entrance and exit, a central aisle and four desks. Main artifacts keep scale 1 so the metre-based controls remain reachable. The table and staircase are displayed beyond them; the pagoda is raised and reduced to clear the floor. The independent science-screen sample is not a live recursion profiler. All ten prior artifact tokens are retained.

The opt-in fixture suppresses standalone directional lights inside this hall, retaining shared museum lighting and local lamps. The desks reuse `commons/artifacts/timing_machines/machine_stage.gd` and the project's physical push button. `commons/artifacts/recursion_lesson/recursion_lesson.gd` connects controls to the original implementations.

Next: Fractal_RecursiveTrees. Carry the function, its parameters and its stopping conditions; investigate how a branching call places and transforms its children.
