# Finite intervals, their history and an extruded passage

Two primaries: `cantor_set`, then `example_8_4_cantor_pagoda_vr`. All eight existing placements, including three stochastic trees, remain. Explicit map placement restores the cloud omitted by the previous museum arrangement. The original 19 × 23 enclosure, 13 × 9 raised deck and two approach wedges remain; museum floor coverage closes legacy exit voids.

## Bar instrument

`lesson:true` installs `commons/artifacts/cantor_lesson/cantor_lesson.gd`. The ordinary falling/instant modes remain available elsewhere. This lesson uses frozen bars, L=6 m, thickness 0.12 m, vertical row spacing 0.45 m and a 0.35 m base offset. It starts at n=0 and admits n=0..5. NEXT/BACK rebuild deterministic generations with the same middle-third code. RESET restores n=0, history on and removal gone.

HISTORY hides earlier rows and disables their collision layers/masks. It does not modify the latest interval set. GHOST shows only the middle thirds newly removed at each displayed generation, as MeshInstance3D without collision. Earlier gaps remain empty; a row of ghosts is not a solid reconstruction of the original interval. RULE reveals a short summary on the desk. Exact GDScript excerpts in final.md are from `cantor_set.gd::perform_iteration` and the pagoda's `_create_block`; the three equations are mathematical notation, not executable GDScript.

The latest row has 2^n pieces, each L/3^n long, total L*(2/3)^n. The desk sums actual current BoxShape widths. At n=5 this gives 32 pieces, 0.790123 m kept and 63 solid bars across the full history. Finite bars have positive total length and thickness. Zero measure and uncountability refer to the mathematical limiting set, not the displayed mesh. Counts are not entropy or performance measurements.

## Pagoda instrument

The lesson sets base width 9 m, block height 2.2 m and n=1..3. CUT/LESS change the number of cuts. The latest generation is the bottom storey; older generations are stacked above it. DEPTH cycles extrusion through 2, 4, 1 m; this changes neither X intervals nor their count. LATEST hides earlier storeys and disables their collisions. RESET returns to n=1, extrusion 2 m and visible history. Rebuilds replace only generated blocks and preserve controls. Maximum lesson allocation is 15 blocks.

At n=3 the lowest storey has 8 blocks totalling 2.666667 m of the 9 m width. Gaps include 3 m, 1 m and 1/3 m. This is an extrusion of finite 1D Cantor generations, not a three-dimensional Cantor dust and not a claim that its polygon mesh has fractal dimension. A fixed collision proxy makes different gaps traversable. The pagoda's `get_level_info` now reports summed kept width separately from one interval's width, and uses the inverted physical storey height. Depth zero in the underlying sculpture also avoids a division by zero in its colour calculation.

## Museum placement and controls

The authored deck provides a 1 m support height, applied once by the museum. The pagoda desk sits on the lower museum floor before the deck. The bar desk sits beside the approach. Both use full-size touch buttons in a 3 × 2 layout and a 1.18 × 0.36 m transparent screen. The secondary Nature of Code artifact is a linear Cantor display, configured to five cuts; the former references to radial circles were incorrect and are archived.

Runtime evidence and input limitations are recorded on the illustrated Cantor review page. Physical headset reach, comfort and Quest performance remain to test.
