# Transformation Introduction

The previous maps built objects in space. This map asks what you can *do* to them. The answer is three operations: translate, rotate, scale. Move a thing. Turn a thing. Resize a thing. Every VR environment, every 3D game, every physics simulation reduces to these three primitives applied in sequence, composed into matrices, evaluated thousands of times per frame.

The blurb frames it as closing a gap. That framing is exact. Translation moves an object across the gap. Rotation reorients it to fit. Scale expands it to fill. Three answers to the same spatial question — and they compose into a single piece of mathematics that the GPU runs in microseconds.

---

## The Transform State

The `Matrix4x4Viewer` artifact makes transform state explicit. Three variables hold everything the learner can manipulate:

```gdscript
var _translate := Vector3.ZERO
var _rotate_y: float = 0.0
var _scale_uniform: float = 1.0
```

These are independent. `_translate` is a position offset. `_rotate_y` is an angle in degrees. `_scale_uniform` is a multiplier. Moving a slider updates one of these. `_update_transform()` then assembles all three into a single `Transform3D`:

```gdscript
func _update_transform() -> void:
    var xform := Transform3D.IDENTITY
    xform = xform.scaled(Vector3.ONE * _scale_uniform)
    xform = xform.rotated(Vector3.UP, deg_to_rad(_rotate_y))
    xform.origin = _translate

    if _cube_root:
        var base_pos: Vector3 = Vector3(0.18, 0.48, -0.02)
        var local_xform := xform
        local_xform.origin += base_pos
        _cube_root.transform = local_xform
```

Scale first, then rotation, then translation. That order matters — it's covered in the composition section. What matters now is that all three operations collapse into one `Transform3D`. The matrix display shows all 16 cells updating in real time. The cube changes shape and position. The numbers change underneath it. One artifact. Two levels of representation. Same fact.

---

## Translation: Moving Without Changing

Translation adds a vector to every point. The object moves. Nothing else changes — no rotation, no deformation, no size shift.

In the matrix display, translation lives in one column: the rightmost column of the 3×3 upper block, displayed in `color_translation` green. Move the MOVE X, MOVE Y, or MOVE Z sliders and only those three cells change. The rest of the matrix stays at the identity.

```gdscript
# Translation never touches the Basis — only the origin
xform.origin = _translate
```

`Transform3D` separates these concerns by design. The `Basis` field handles orientation and scale. The `origin` field holds position. They don't interact until you compose transforms in a specific order.

The color coding in `_update_transform()` makes this concrete: `color_translation` marks column 3, `color_rotation` marks the upper-left 3×3 block. Sliding MOVE X lights up exactly one column. Sliding ROTATE fills the entire 3×3 rotation block with new values. The matrix is a map of which operations own which cells.

This map doesn't yet visualize translation as movement *through* space — a discrete before/after state with a path between them. That becomes the core lesson of **Trans_Translation**, the next map, where translation becomes navigation infrastructure.

---

## Rotation: Orientation as a 3×3 Block

Rotation requires two things: an axis and an angle. The `Matrix4x4Viewer` exposes Y-axis rotation through the ROTATE slider:

```gdscript
xform = xform.rotated(Vector3.UP, deg_to_rad(_rotate_y))
```

`Vector3.UP` is the Y axis. `deg_to_rad(_rotate_y)` converts the slider's 0–360 range to radians. The result modifies the `Basis` — the upper-left 3×3 block in the matrix display, shown in `color_rotation` cyan.

Watch those cells as you rotate. At 0 degrees: `[1, 0, 0 / 0, 1, 0 / 0, 0, 1]` — identity. At 90 degrees around Y, cos(90°) = 0 and sin(90°) = 1, yielding:

```
[ 0   0   1 ]
[ 0   1   0 ]
[-1   0   0 ]
```

The off-diagonal cells fill in. The diagonal shifts. These numbers encode the reoriented coordinate axes. The matrix *is* the rotation — not a record of it, but the operation itself, crystallized into numbers.

### Gimbal Lock

The `Rotation Gimbal` artifact adds something the matrix viewer cannot show: failure. Three nested rings (X=red, Y=green, Z=blue) represent Euler angles — three sequential rotations applied in order. The outer ring drives the inner ones. The artifact exposes the lock threshold:

```gdscript
@export var gimbal_lock_threshold: float
```

When Y approaches ±90 degrees, `_on_y_slider` detects alignment: the X and Z rings collapse into the same plane. Two degrees of freedom merge. Any rotation in that plane can now be expressed as a combination of X and Z — they are no longer independent. A degree of freedom has vanished.

Gimbal lock isn't a bug. It's a geometric property of Euler angles. When Y is exactly 90 degrees, X and Z rotations become coplanar. The system can no longer distinguish between them. Quaternions solve this by representing rotation as a single operation in 4D space rather than three sequential operations in 3D. This map doesn't implement quaternions — that gap is named in the Possible Artifacts section. But the gimbal demonstrates *why* quaternions were invented, which is more durable knowledge than the quaternion algebra alone.

---

## Scale: Size as a Multiplier

Scale multiplies every point's distance from the origin. The `Matrix4x4Viewer` uses uniform scale — all axes equal:

```gdscript
xform = xform.scaled(Vector3.ONE * _scale_uniform)
```

`Vector3.ONE * _scale_uniform` produces `(s, s, s)`. At `s = 1.0`, nothing changes. At `s = 2.0`, the cube doubles in all dimensions. In the matrix, scale lives on the diagonal. A scale of 2.0 produces:

```
[ 2   0   0 ]
[ 0   2   0 ]
[ 0   0   2 ]
```

Move the SCALE slider and watch all three diagonal cells change identically. The cube expands symmetrically. The off-diagonal cells stay zero because uniform scale doesn't mix axes.

Non-uniform scale — different values per axis — would produce a diagonal like `[2, 0.5, 1]`. The shape stretches. This is an affine transformation but not a similarity. It changes angles between faces. The `Matrix4x4Viewer` doesn't expose non-uniform scale directly; this gap is listed in Possible Artifacts below.

The `balance_puzzle` uses scale differently. The `piece_scale` export sets the size of spawned pieces at construction time — scale applied once, not during simulation. The `cube_ratio` export sets what proportion of pieces are cubes versus other shapes. Scale as ratio, not geometry.

---

## Homogeneous Coordinates: One Matrix for All Three

Translation is addition. Rotation and scale are multiplication. A matrix represents only multiplication. So how does translation enter the matrix?

By adding a dimension.

Every 3D point `(x, y, z)` becomes `(x, y, z, 1)` — a 4-vector. A 4×4 matrix can then encode all three operations at once. The `Homogeneous Coordinates` wall panel shows the block structure with color-coded regions: `color_rotation` for the upper-left 3×3, `color_translation` for the fourth column, `color_projection` for the projection row, `color_homogeneous` for the scalar corner. The function `_build_matrix_cells(values, colors)` assigns these colors per cell during construction. The function `_build_point_transform()` demonstrates the actual multiplication: how `[x, y, z, 1]` maps to `[x', y', z', 1]` through a single matrix-vector product.

In `Matrix4x4Viewer`, the bottom row is always:

```gdscript
0.0, 0.0, 0.0, 1.0,
```

That `1.0` at position `[3][3]` is the homogeneous coordinate. It stays fixed for all affine transforms — translation, rotation, scale. Only projection transforms modify the bottom row, and projection is a separate concern (covered in `color_projection` red in the `Homogeneous Coordinates` panel).

This is why Godot's `Transform3D` stores a `Basis` (3×3) plus an `origin` (`Vector3`) rather than a raw 16-element array. It's the same math, restructured for cache efficiency. The homogeneous convention is the foundation underneath every spatial operation in the engine.

---

## What Transforms Preserve: Invariants

The `Invariants Demo` makes a triangle and asks: which properties survive which transforms?

At startup, `_compute_original_measurements()` records the triangle's side lengths, interior angles, and area — ground truth before any transform is applied. `_angle_at_vertex(idx, verts)` uses the dot product of two edge vectors to compute each interior angle. `_triangle_area(verts)` uses the cross-product formula: half the magnitude of the cross product of two edges.

When the learner applies a transform, `_apply_transform(which)` deforms the triangle. `_update_display()` runs `_color_label(lbl, current_val, orig_val)` on each measurement: preserved measurements glow green, changed measurements glow red.

The signatures are precise:

- **Translation** preserves everything. Lengths, angles, area. All green.
- **Rotation** preserves everything. Same geometry, different orientation. All green.
- **Uniform scale** preserves angles but changes lengths and area. Angles are scale-invariant. Lengths scale by `s`. Area scales by `s²`. Two reds, one green.
- **Shear** destroys angles and changes lengths. Nearly everything goes red.

Translation and rotation are rigid transforms — they preserve shape entirely. Scale produces similarity — same shape, different size. Shear is affine but not similarity. Each transform's character is defined by its invariant set.

That last sentence carries the map's central claim. A transformation is not only a change. It is a *signature of what it cannot touch*. The green cells in `_color_label` show what the transform is powerless against. That powerlessness is the definition.

---

## Composition: Order Is a Variable

The `Transform Composition` artifact demonstrates that matrix multiplication is non-commutative. The functions `_make_rotate_y(rad)` and `_make_translate(offset)` each produce a `Transform3D`. `_compose_matrix(first, second)` multiplies them together. Two house shapes undergo the same rotation and translation, but in opposite orders. They land in different places.

```gdscript
@export var rotation_angle: float
@export var translate_dist: float
```

At small values, the divergence is subtle. At `rotation_angle = 90` and a large `translate_dist`, the two results are dramatically separated. `_format_matrix(xf)` formats the live matrix state as a string — both resulting matrices display simultaneously, making the numeric difference visible alongside the geometric one.

The geometry explains itself: rotate-then-translate means the translation happens along the *rotated* axes. Translate-then-rotate means the rotation happens around the original origin — the object orbits rather than spinning in place. Same operations. Different order. Different result.

This is why `_update_transform()` in `Matrix4x4Viewer` applies scale, then rotation, then translation in a fixed sequence. That sequence is a convention — the most useful one for most use cases — but it is not mathematically required. Rearrange the calls and the output changes.

---

## Transformation Under Constraint

The balance puzzle frames transformation as something the physics engine negotiates, not something a programmer applies. The `_physics_process(delta)` loop tracks position and orientation — transform state — for every piece continuously. `_update_stability_check(delta)` uses `stability_velocity_threshold` to detect when all motion has stopped. When `height_threshold` is met while the stack is stable, `_trigger_transformation()` fires.

The designer controls the threshold, not the path. The transform sequence that gets the stack to stability is determined by physics, player choices, and gravity in combination. Translation and rotation happen continuously, driven by contact forces, until the system finds equilibrium.

When the transformation triggers, `_calculate_walker_position(index, total, original_rel)` computes new positions for each piece — the spatial relationships encoded in the stack re-expressed as a walking creature. The pieces don't change shape. Their *relational transformation* changes. The stack becomes locomotion.

The dark sphere doesn't transform in any learner-controlled sense. Its `rotation_speed = 0.15` drives a slow Y-axis spin in `_process(delta)`. Its `pulse_speed = 1.2` drives a sinusoidal emission pulse. Both are autonomous and tiny. The sphere exists so the learner's eye has a stable reference — its near-constancy makes other transformations legible by contrast. An invariant in the perceptual register.

**Trans_Translation** takes the abstract translate operation from this map and builds spatial infrastructure from it: walkways, transport cubes, axis-constrained movement across voids. The concept becomes a system. What's introduced here as a slider value becomes, there, the grammar of navigation.

---

## Possible Artifacts

**non_uniform_scale_demo** — demonstrates stretching along individual axes independently. `Matrix4x4Viewer` exposes only uniform scale (`Vector3.ONE * _scale_uniform`), so the diagonal always has equal values. An artifact with three separate scale sliders and a deformable mesh would make visible the distinction between similarity transforms (uniform scale, preserves angles) and general affine transforms (non-uniform scale, deforms shape).

**quaternion_rotator** — the `Rotation Gimbal` shows when Euler angles fail but does not demonstrate the solution. An artifact displaying the same rotation as both Euler angles and a quaternion `(w, x, y, z)`, interpolating smoothly through the gimbal-lock zone, would complete the argument the gimbal starts. The gimbal shows the problem. This would show what replaces it.

**shear_visualizer** — a dedicated shear artifact with a unit cube and a single shear-factor slider. The `Invariants Demo` includes shear as one of the transforms `_apply_transform(which)` can apply, but the main three cubes in this map are translate, rotate, scale. A standalone shear demo would establish shear as the fourth affine transform type — the one that is neither rigid nor similarity — before the sequence reaches linear algebra maps where shear matrices appear explicitly.