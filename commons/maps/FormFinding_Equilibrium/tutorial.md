# Form-Finding: Equilibrium

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Lever balance
- Mass-distance products
- Solved arm lengths
- Model assumptions

The installed mobile draws a static balance from modelled masses and chosen distances. The excerpts below expose its construction and two neighbouring displays; they are not one complete script or a dynamic load test.

Weigh a leaf from its own geometry.

```gdscript
const SHEET_T := 0.003      # 3 mm aluminium sheet
const DENSITY := 2700.0     # kg/m³

var r: float = _rng.randf_range(0.09, 0.24)
var mass: float = PI * r * r * SHEET_T * DENSITY
```

The model assigns a mass from radius, thickness and density. Rebuilding with a different radius changes that mass and the computed pivots. Rods and wires contribute no mass to this calculation.

Place the pivot by the lever law.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d))
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

Here `wl` and `wr` store masses. Torque magnitude would be `m*g*d` for each vertical load on the horizontal arm; the shared gravity factor cancels when comparing the two sides. The heavier child gets the shorter arm. The code solves those distances, then draws the result. The installed source also varies `arm` by a seeded multiplier from 0.85 to 1.15, omitted from this excerpt; the balance relation is unchanged.

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

For a source comparison, set the mobile's exported `lever` to `halved` and rebuild. The installed map uses `solved`; there is no live lever-mode control in this hall. The alternate branch draws equal arms and converts the remaining imbalance into a tilt:

```gdscript
dl = arm * 0.5      # halved — the rod cut in the middle instead
dr = arm * 0.5
var tilt: float = asin(clampf((wr * dr - wl * dl) / (arm * total), -1.0, 1.0))
lp = pivot + Vector3(-dl * cos(tilt), dl * sin(tilt), 0)
rp = pivot + Vector3(dr * cos(tilt), -dr * sin(tilt), 0)
```

The mass-distance difference is divided by `arm * total`, then mapped through `asin`. This is an authored diagram of residual imbalance, not a physically solved equilibrium angle. Equal masses give zero tilt. Predict the direction for a heavier right-hand child, inspect the rebuilt diagram, then restore `solved`.

Brace a section instead of thickening it.

```gdscript
var br: float = leg_r * 0.55
for i in range(4):
    var j: int = (i + 1) % 4
    parent.add_child(_cylinder_between(corners_b[i], corners_t[j], br, brace_mat))
    parent.add_child(_cylinder_between(corners_b[j], corners_t[i], br, brace_mat))
    parent.add_child(_cylinder_between(corners_t[i], corners_t[j], br, brace_mat))
```

Two diagonals and a tie per face, at just over half the leg radius. This constructs visible bracing. No load or strength is measured by these mesh-building calls.

Recurse the bracing.

```gdscript
var ym: float = (y0 + y1) * 0.5
var w_mid: float = (w_bot + w_top) * 0.5
_truss_segment(parent, y0, ym, w_bot, w_mid, d - 1, leg_mat, brace_mat)
_truss_segment(parent, ym, y1, w_mid, w_top, d - 1, leg_mat, brace_mat)
```

The recursive calls divide the tower into upper and lower storeys; they do not replace each strut with a truss. Finer corner members overlap the coarser ones. Repetition builds this geometry without proving that it is lighter or stronger under a specified load.

Lock three angles.

```gdscript
var v_top := Vector3(0.0, tri_height * 0.6, 0.0)
var v_bl := Vector3(-tri_width * 0.5, -tri_height * 0.4, 0.0)
var v_br := Vector3(tri_width * 0.5, -tri_height * 0.4, 0.0)
_add_strut(v_top, v_bl, strut_mat)
_add_strut(v_bl, v_br, strut_mat)
_add_strut(v_br, v_top, strut_mat)
```

An ideal planar triangle with fixed side lengths cannot rack as an unbraced hinged four-bar frame can. This excerpt only places three struts; it does not implement that comparative experiment.

Inspect what the triangle's apparent loading actually runs:

```gdscript
_phase += delta * load_speed
var load: float = maxf(0.0, sin(_phase)) * load_amplitude
scale = Vector3(1.0 + load * 0.4, 1.0 - load, 1.0)
```

The sine writes directly to scale. No force is applied and no spring restores the body. Its squash is an animation; it cannot validate the structural claim above.

Keep the mobile's mass-distance relation and distinguish it from the tower's repeated geometry and the triangle's prescribed animation. FormFinding_Annealing asks what to do when a search reaches only a nearby minimum.
