# Form-Finding: Equilibrium

Where forces cancel, form holds still. Before it, weights that are real numbers and distances you are free to choose.

Weigh a leaf from its own geometry.

```gdscript
const SHEET_T := 0.003      # 3 mm aluminium sheet
const DENSITY := 2700.0     # kg/m³

var r: float = _rng.randf_range(0.09, 0.24)
var mass: float = PI * r * r * SHEET_T * DENSITY
```

The mass is not a label on the disc. It is the disc — radius, thickness, density. Change the radius and the whole mobile is re-solved.

Place the pivot by the lever law.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d))
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

τ = w·d. The heavier child gets the shorter arm, because each distance is scaled by the *other* one's weight. The arm is solved, not drawn.

Let every arm hang from the arm above.

```gdscript
func _build_subtree(d: int) -> Dictionary:
    if d <= 0:
        return {"node": root, "mass": _make_leaf(pivot)["mass"]}
    var left: Dictionary = _build_subtree(d - 1)
    var right: Dictionary = _build_subtree(d - 1)
    return {"node": root, "mass": left["mass"] + right["mass"]}
```

Each subtree reports its mass upward. A parent balances two numbers without looking inside either.

Break the law, and let the leftover moment become an angle.

```gdscript
dl = arm * 0.5      # halved — the rod cut in the middle instead
dr = arm * 0.5
var tilt: float = asin(clampf((wr * dr - wl * dl) / (arm * total), -1.0, 1.0))
lp = pivot + Vector3(-dl * cos(tilt), dl * sin(tilt), 0)
rp = pivot + Vector3(dr * cos(tilt), -dr * sin(tilt), 0)
```

Residual moment, normalised by the largest moment the arm could carry. Zero residual is zero tilt — which is why a balanced mobile never reaches this branch.

Brace a section instead of thickening it.

```gdscript
var br: float = leg_r * 0.55
for i in range(4):
    var j: int = (i + 1) % 4
    parent.add_child(_cylinder_between(corners_b[i], corners_t[j], br, brace_mat))
    parent.add_child(_cylinder_between(corners_b[j], corners_t[i], br, brace_mat))
    parent.add_child(_cylinder_between(corners_t[i], corners_t[j], br, brace_mat))
```

Two diagonals and a tie per face, at just over half the leg radius. The strength is in the bracing, not the bulk.

Recurse the bracing.

```gdscript
var ym: float = (y0 + y1) * 0.5
var w_mid: float = (w_bot + w_top) * 0.5
_truss_segment(parent, y0, ym, w_bot, w_mid, d - 1, leg_mat, brace_mat)
_truss_segment(parent, ym, y1, w_mid, w_top, d - 1, leg_mat, brace_mat)
```

Every strut becomes a truss of thinner struts; `leg_r` runs 0.05 down to 0.018 with depth. Strength from geometry, not mass. Walk inside and you are in a beam made of beams.

Lock three angles.

```gdscript
var v_top := Vector3(0.0, tri_height * 0.6, 0.0)
var v_bl := Vector3(-tri_width * 0.5, -tri_height * 0.4, 0.0)
var v_br := Vector3(tri_width * 0.5, -tri_height * 0.4, 0.0)
_add_strut(v_top, v_bl, strut_mat)
_add_strut(v_bl, v_br, strut_mat)
_add_strut(v_br, v_top, strut_mat)
```

Push a square and it racks into a diamond. A triangle cannot: its angles are already fixed by the lengths of its sides.

Load it, and watch it refuse.

```gdscript
_phase += delta * load_speed
var load: float = maxf(0.0, sin(_phase)) * load_amplitude
scale = Vector3(1.0 + load * 0.4, 1.0 - load, 1.0)
```

It squashes and springs back. Nothing here is stacked. The form holds because forces balance in a field, not because mass piles up in a column.

You can now weigh a part from its geometry, solve a pivot instead of drawing one, recurse bracing into a self-similar truss, and lock a frame with three members. Gaudí hung weighted chains and turned the photograph upside down — tension inverted is compression, and the arch was found rather than imposed. FormFinding_Annealing asks what to do when the rest you reach is only the nearest one.
