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

The complete function skips visitors outside the aperture or reach. The final line eases the response. A separate clearance rule opens enough neighbouring slats for the body. The default swing mode rotates the slats around their hinges. Step back and the wall closes.

## Cells are removed

`carve_grid.gd` tests the visitor's collision volume with a small added reach:

```gdscript
cut += _bite_at(c, _v_r[i] + bite_m, _v_hs[i])
```

Here `c` is the collision shape's centre in lattice coordinates, `_v_r[i]` its radius and `_v_hs[i]` its vertical half-segment. `bite_m = 0.16` extends the cut beyond the surface where collision stops the visitor. Removed cells leave both the visible lattice and the collision representation. `regrow_s = 0` keeps the cut while this room remains loaded.

Moving the visitor is translation; deleting lattice cells is a separate operation. Count the cells before and after a cut to see the difference.

## Blocks shrink and return

`approach_scale.gd` converts the nearest body's distance into a size factor:

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Near the body, the factor approaches `min_scale`; far away it approaches one. The artifact applies the same size to mesh and collision box. It also sets the block centre to half the new height, keeping the base on the floor. Horizontal grid locations remain fixed.

Leave and these blocks return. The lattice's missing cells do not. This difference in memory is the room's final comparison. The next hall's growers also resize, but their input is elapsed time, not distance to a visitor.
