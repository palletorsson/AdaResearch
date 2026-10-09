# Replacement, removal and finite measurement

Three primary artifacts follow the book's order. All ten map placements remain. The old 13×11 room is retained as the rear collection, translated by (3,18) inside a 19×29 enclosure. Its raised cell remains; old exit voids receive museum floor coverage. The new front study area supplies reachable controls and room for the comparisons.

## Controls and data

| Artifact | Controls | Held quantities / changing quantities |
|---|---|---|
| fractal_koch_curve | NEXT, BACK, FORM, TURN, RESET, RULE | Depth 0–4; open endpoints 4 m apart; FORM starts a 3.5 m-sided triangle; TURN reverses peak direction. |
| sierpinski_triangle | NEXT, BACK, VIEW, DEPTH, RESET, RULE | Depth 0–4, side 6 m. VIEW changes drawing of retained/removed parts. DEPTH switches 0.08/0.35 m thickness. |
| box_counting_dimension | FINER, COARSER, COVER, RANGE, RESET, RULE | 8,000 points, seed 2026. Grids 2,4,8,16,32,64. RANGE cycles coarse three, fine three, all six. |

`#lesson:true` installs `commons/artifacts/koch_sierpinski_lesson/koch_sierpinski_lesson.gd` on these placements. It holds their timers, starts at the first construction and reuses the existing algorithms. Each desk has six physical touch buttons in a 3×2 arrangement and a tilted 1.18×0.36 m text plane at alpha 0.14. Source scenes without that flag keep their ordinary modes. The measurement registry entry previously had `map_ready:false`; the hall loader therefore skipped it even though its scene existed. This pass enables the tested scene.

## Koch

`algorithms/fractals/example_8_5_koch_curve_vr.gd` stores start/end dictionaries per generation. `_koch_subdivide` replaces one segment by four joined segments of one-third length. The open lesson begins with local length 0.8 and mesh scale 5, hence 4 m. Counts are 4^n; path lengths are 4(4/3)^n. At n=4 this is 256 segments and about 12.642 m. FORM uses three local sides of length 0.7, giving initial perimeter 10.5 m. Its first replacement has perimeter 14 m. For lesson snowflakes, the counterclockwise initial triangle receives outward peaks; TURN reverses this. Reversed constructions retain segment counts/lengths without inheriting every property of the standard non-overlapping Koch limit.

The lesson draws two triangles per segment as a 0.02 m-wide ribbon. This provides readable width in the compatibility renderer, where a requested line width would not reliably produce it. Finite ribbons, finite polylines and mathematical limiting sets have different dimensional claims. `log(4)/log(3)` describes the standard ideal Koch curve; non-integer dimension is not a universal definition of every fractal.

## Sierpinski

`algorithms/fractals/sierpinskitriangle/sierpinski_triangle.gd` computes midpoints and three corner triangles. At side 6 m, initial area is 9√3 m². The lesson displays only the current kept generation, whose area is 9√3(3/4)^n. Four cuts yield 81 kept triangles and about 4.932 m². Ghost and negative modes draw each newly removed middle across the full construction history: (3^n−1)/2 pieces, or 40 at n=4. Negative mode still computes the corner data. Changing thickness does not alter the planar area calculation.

The original script rotates its root; the lesson instead rotates generated meshes, leaving the desk upright. Rebuild detaches old meshes immediately before deferred deletion. The sculpture has no colliders. The desk and measurement backing do. There is no claim that the triangle's apparent openings support or constrain locomotion.

## Box counting

`algorithms/fractals/box_counting_dimension/box_counting_dimension.gd` owns an independent chaos-game point cloud. This is not a live measurement of either neighbouring sculpture. A dedicated seeded RNG makes RESET reproducible without reseeding the global stream. `N` counts unique grid addresses occupied by at least one point. COVER draws exactly two triangles for every occupied cell at the selected resolution. Display mapping scales the six-unit square to 3.3 m and turns it upright; the readout keeps box size in source units.

RANGE selects three coarse samples, three fine samples, or all six for least-squares slope of log₂(N) versus log₂(1/box_size). All six measured points remain in the plot; the fit is computed only from the named subset and its line is drawn across the plot. The selected grid point has a cross. Box counts remain fixed when changing fit range. The ideal triangle's 1.585 dimension is a comparison, not an expected exact finite output. More resolution can eventually expose sampling sparsity; a finite cloud does not supply detail indefinitely.

## Retained collection and source cautions

`recursion_observatory`, `cube_cabin`, `cube_bookshelf`, `koch_curve_3d`, `sierpinski_pyramid`, and `science_screen` remain secondary; `dark_sphere` is decoration. The observatory supports comparison with prior constructions. The cabin and shelf are assembled architectures. The Koch arch bends a generated curve into a head and legs, repeated through depth; this does not establish a fractal dimension equal to its planar value plus one. The registry's pyramid resolves to `algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd`: it has two distinct top calls plus four lower calls, despite five-copy comments. Treat it as its implemented six-call variant, not a four-copy tetrahedron. The trace screen remains an unconnected reference display; no new trace feed is claimed.

The previous map and prose are archived in `doc/space/koch-sierpinski-2026-09-14/before/`. Runtime evidence separates synthetic input through the project's DesktopPlayer rig, native museum walker interaction, and headset use. Only explicitly recorded checks are verified; VR reach, comfort and Quest frame time remain pending.

Reference for the broader recursion progression: [The Nature of Code, Fractals](https://natureofcode.com/fractals/). Numerical claims above follow these local implementations.
