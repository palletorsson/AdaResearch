# Trans Body — approach, change, memory

Watch each threshold before entering. Cross it, then look back. The sequence is rotation, deletion and scaling; the comparison is what the room restores and what it keeps.

## Slats turn

`approach_wall.gd` reads visitor coordinates in the wall's local space. Within its reach, the distance calculation includes:

```gdscript
var t: float = absf(cx - _vx[v]) / ap
var d: float = absf(_vz[v]) / rc
var o: float = (1.0 - t) * (1.0 - d)
o = o * o * (3.0 - 2.0 * o)
```

The complete function skips visitors outside the aperture or reach. The final line eases the response. A separate clearance rule opens enough neighbouring slats for the body. The default swing mode rotates the slats around their hinges. Move outside its reach and wait for the response to settle. Merely crossing the wall can leave you close enough to hold it open.

## Cells are removed

`carve_grid.gd` tests the visitor's collision volume with a small added reach:

```gdscript
cut += _bite_at(c, _v_r[i] + bite_m, _v_hs[i])
```

Here `c` is the collision shape's centre in lattice coordinates, `_v_r[i]` its radius and `_v_hs[i]` its vertical half-segment. `bite_m = 0.16` extends the cut beyond the surface where collision stops the visitor. Removed cells leave both the visible lattice and the collision representation. `regrow_s = 0` keeps the cut while this room remains loaded.

The default lattice has four vertical layers at 0.34 m spacing, with 0.29 m cubes. Its top is about 1.335 m above the base. A standing visitor can see above it: the cut is open-topped. The record is a discretised intersection with the visitor collider plus its bite margin, rather than a full cast of a person.

Moving the visitor is translation; deleting lattice cells is a separate operation. Count the cells before and after a cut to see the difference.

## Blocks shrink and return

`approach_scale.gd` converts the nearest body's distance into a size factor:

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Near the body, the factor approaches `min_scale`; far away it approaches one. The artifact applies the same size to mesh and collision box. It also sets the block centre to half the new height, keeping the base on the floor. Horizontal grid locations remain fixed.

At the caption beyond the last row the last row can still be within the 2.2 m sensing reach. Continue into the exit area and wait: these blocks then return. The lattice's missing cells do not. This difference in memory is the room's final comparison. The next hall's growers also resize, but their input is elapsed time, not distance to a visitor.

The encounter recognises supported player collision bodies. A 52 cm-wide test capsule is one model, not a universal body. Player size, controller motion, collision proxies and response time all affect what passage is possible.


## Current museum illustration and seating repair — 23 September

The book's before/after lattice figure uses a fixed elevated camera in the actual isolated museum. Its normal Walker, with a 0.64 m wide and 1.5 m high capsule, was driven through the lattice by physics-tick movement; no cells were removed directly by the capture script. This selected straight walk removed 132 of 484 cells. The cut remains after the body is moved away. These are supplied inputs, not a human or headset observation.

That pass exposed a construction defect in `approach_scale`: the initial AnimatableBody3D pose was centred at y=0 before the node entered the scene tree. Physics synchronization restored that pose after the initial size assignment, and automatic grounding compensated by raising the artifact root 0.575 m. Blocks then rose above the floor on their first size response. Each block is now given its standing centre height before it enters the tree. Mesh and collider bases stay on the deck at full, reduced and restored sizes. No map token, dimensions, sensing reach or size law changed.

`tools/probes/body_book_illustrations.gd` records selected continuous walks through each of the three thresholds, with the body placed at each separate approach. The slats and blocks return after leaving reach; the lattice keeps its removed cells. `tools/probes/body_block_seating.gd` is the small diagnostic used to isolate the old height drift. [Images, exact changes and full evidence](../../../doc/book/iterations/2026-09-23-body-what-remains/index.html).
