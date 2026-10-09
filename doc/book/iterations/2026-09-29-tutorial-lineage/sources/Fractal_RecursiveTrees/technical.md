# Recursive trees: endpoints, inheritance and a finite budget

The primary encounter uses `recursive_tree_2` (the tapered-cylinder implementation) and `recursive_tree` (the red geometric implementation). The entire twelve-placement collection remains.

## Growing tree

The opt-in `lesson:true` configuration installs a compact physical desk and starts with a 1.4 m trunk. GROW processes one breadth-first generation. Four generations after the trunk are allowed. ANGLE cycles 15/35/65 degrees relative to the parent; LENGTH cycles 0.50/0.70/0.85; FORKS switches two/three children. Changing these parameters rebuilds to the current generation. RESET restores two forks, 35 degrees, ratio 0.70 and the trunk. RULE is a shortened on-desk summary; final.md quotes two exact lines from `algorithms/fractals/recursivetree/recursive_tree.gd::create_branching_node`.

For b children and d completed generations, the segment total is sum(b^k,k=0..d). Thus b=2,d=4 gives 31 and b=3,d=4 gives 121. The museum configuration disables random perturbation. The underlying script now owns its RNG for repeatable resets outside the lesson too. A 512-segment allocation ceiling also bounds other configurations; the lesson remains below it. Counts refer to segments, not draw calls, triangles, computational entropy or headset performance.

Branch data stores endpoints in tree-local coordinates. All generated segments share that coordinate frame. The tapered-cylinder vertices already run from zero to length; applying an additional half-length offset would create a gap. Length inheritance is applied once per generation, including the first. A parent reference retains the logical graph even though the render nodes share one container. Reset frees only generated geometry and preserves the physical desk.

The original specimen's generated meshes have no branch colliders. Turning a branch changes its embedding, not its parent-child connectivity. Crossing meshes do not automatically merge their graph vertices.

### The solid canopy

Only this hall's growing-tree token adds `room:canopy`. The optional `commons/artifacts/recursive_tree_lesson/branch_canopy.gd` reads the source's generated branch nodes, sharing their actual mesh resources, materials and local transforms. It adds a convex collision hull for each branch, translates the root to hall-relative (8.5, 0, 7.5), and scales the whole receiver uniformly by 1.8. The initial trunk is therefore 2.52 m high. No second branching solver or new controls are introduced.

GROW, ANGLE, LENGTH, FORKS and RESET update both versions. A light state check also follows external source resets, removing stale solids. There are 31 hulls for the binary tree at generation four, and 121 for three forks. Hulls follow the source taper, rather than using a broad invisible barrier. Sharing geometry does not make this a structural engineering model: strength, load, bending, weather and biological response are absent.

Native checks cover all eighteen combinations of two/three forks, 15/35/65 degrees and .50/.70/.85 inherited length at generation four. Their mesh bounds stay inside the front room's walls and before the legacy enclosure. Controlled standing-body walking meets the trunk, steps beside it, passes beneath the default branches and returns to the rear approach. The parameter sweep establishes geometry bounds, not every possible walking or climbing route. Human headset reach, crouching, comfort, Quest profiling and learner acceptance remain pending. Ordinary lesson placements and the finished red-tree study receive no canopy.


## Finished block tree

Scene seed 12345 chooses branch dimensions, direction and descendant counts through a local RNG. This implementation uses three recursive branching levels, not a fixed binary tree. Its existing aftermath modes are available as FORM, STRATA, REACH and ENDS. They restore materials or draw bounds and markers without rebuilding the tree. RESET restores FORM. The bounding volume is a reading of generated extents, not a walkable room.

Branch detail blocks now use the same local frame as their sibling branch mesh. Museum placement and rotation therefore move the whole sculpture consistently. The standalone screen overlay is hidden only when the physical lesson is enabled.

## Space and comparison

The map is 17 × 24 cells. A ten-row approach precedes the retained stepped enclosure recovered in the April and August histories. All twelve placements remain. The two inverted trees are separated, raised and reduced in scale; their clouds use the same fixed phase. One shows strata. The oversized Möbius world is now a small specimen in this hall, with its full-scale implementation retained for its own context. The museum covers the legacy floor voids while the archived grid preserves their provenance.

Buttons retain full touch targets in a 3 × 2 layout; the 1.18 × 0.36 m panel uses a single transparent plane. Desktop input and geometry checks are reported on the review page. Tracked-headset reach and comfort require later testing.

Earlier material remains in the [archived version](../../../doc/space/recursive-trees-2026-09-14/before/commons/maps/Fractal_RecursiveTrees/technical.md) for comparison and future development.
