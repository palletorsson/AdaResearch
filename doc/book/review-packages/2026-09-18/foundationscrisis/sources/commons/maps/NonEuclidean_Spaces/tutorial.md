# NonEuclidean Spaces

Two alternatives, equally consistent with the first four postulates. Build a curvature slider that moves continuously between hyperbolic, Euclidean, and elliptic space.

Declare the curvature state.

```gdscript
class_name CurvatureField
extends Node3D

@export var curvature: float = 0.0

func set_curvature(k: float) -> void:
    curvature = clamp(k, -1.0, 1.0)
    _update_grid()
```

A single scalar controls everything. Negative is hyperbolic, zero is Euclidean, positive is elliptic. The slider is the curvature.

Build the base grid.

```gdscript
func _update_grid() -> void:
    for i in grid_vertices.size():
        var v := grid_vertices[i]
        grid_vertices[i] = _warp(v, curvature)
    grid_mesh.update_from(grid_vertices)
```

The grid starts flat. Each frame, vertices warp according to the current curvature. The mesh is the same vertex list differently placed.

Warp a vertex.

```gdscript
func _warp(v: Vector3, k: float) -> Vector3:
    var r := v.length()
    var factor: float = 1.0 + k * r * r * 0.02
    return v * factor
```

Parabolic scaling with distance from origin. Close to the slider, the warp is subtle; far away, it bends dramatically.

Draw two parallel geodesics.

```gdscript
func draw_parallels(k: float) -> void:
    var a := _geodesic(Vector3(-2, 0, -5), Vector3.FORWARD, k)
    var b := _geodesic(Vector3(2, 0, -5), Vector3.FORWARD, k)
    parallels_mesh.draw(a, b)
```

Two lines start parallel. At k=-1 they diverge.

At k=0 they stay parallel. At k=+1 they converge and meet.

Integrate a geodesic step by step.

```gdscript
func _geodesic(start: Vector3, direction: Vector3, k: float) -> PackedVector3Array:
    var points := PackedVector3Array()
    var pos := start
    var dir := direction
    for i in 40:
        pos += dir * 0.2
        dir = (_warp(pos + dir * 0.1, k) - _warp(pos, k)).normalized()
        points.append(_warp(pos, k))
    return points
```

Forty steps per geodesic. Direction updates each step by tangent to the warped grid. The line walks the curvature rather than assuming it.

Label the three regimes.

```gdscript
func label_regime(k: float) -> void:
    if k < -0.1: regime_label.text = "hyperbolic"
    elif k > 0.1: regime_label.text = "elliptic"
    else: regime_label.text = "euclidean"
```

Hyperbolic, euclidean, elliptic. The slider passes through all three continuously. No regime is privileged.

Colour the floor by curvature sign.

```gdscript
func tint_floor(k: float) -> void:
    var mat: StandardMaterial3D = floor.material_override
    mat.albedo_color = Color(0.5 - k * 0.3, 0.5, 0.5 + k * 0.3)
```

Cool toward negative, warm toward positive. The learner's steps tell them which geometry they're inside.

You have moved continuously through three geometries. The next map, Russell Paradox, turns from geometry to logic and finds the first genuine contradiction.
<<</MAP>>>
