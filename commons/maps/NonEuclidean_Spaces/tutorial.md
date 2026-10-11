# NonEuclidean Spaces

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed triangle workbench switches between PLANE, SPHERE and DISK. Its angle calculation uses edge tangents in the selected model. The separate curvature slider changes a surface sketch. The radial warp below supplies neither those metrics nor their geodesics; it is not a reconstruction of that workbench.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Distance models
- Geodesics
- Triangle comparisons

Inspect the difference between deforming coordinates and defining a distance model. The installed hall compares three hosts; this older sketch only alters a drawing.

Declare the curvature state.

```gdscript
class_name CurvatureField
extends Node3D

@export var curvature: float = 0.0

func set_curvature(k: float) -> void:
    curvature = clamp(k, -1.0, 1.0)
    _update_grid()
```

This scalar is a deformation parameter. Its sign and name do not give the mesh a hyperbolic or spherical metric.

Build the base grid.

```gdscript
func _update_grid() -> void:
    for i in grid_vertices.size():
        var v := grid_vertices[i]
        grid_vertices[i] = _warp(v, curvature)
    grid_mesh.update_from(grid_vertices)
```

Each call overwrites the stored vertices. Repeated calls compound the warp rather than rebuilding from a retained original. The snippet has no frame callback and does not define grid_mesh.update_from.

Warp a vertex.

```gdscript
func _warp(v: Vector3, k: float) -> Vector3:
    var r := v.length()
    var factor: float = 1.0 + k * r * r * 0.02
    return v * factor
```

The multiplier depends on squared distance from the origin. For vertices in the plane y = 0, the result remains in that plane. It does not create the hall’s sphere or saddle.

Inspect the paths called geodesics in this prototype.

```gdscript
func draw_parallels(k: float) -> void:
    var a := _geodesic(Vector3(-2, 0, -5), Vector3.FORWARD, k)
    var b := _geodesic(Vector3(2, 0, -5), Vector3.FORWARD, k)
    parallels_mesh.draw(a, b)
```

The paths begin with parallel directions. At k = 0 the warp is the identity. Their behaviour at other values must not be used as evidence for spherical or hyperbolic parallels: no corresponding metric has been supplied.

Inspect the path update.

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

Forty iterations update a direction using differences of warped positions. Calling this function _geodesic does not establish that its paths are geodesics in any of the three intended models.

Label the three regimes.

```gdscript
func label_regime(k: float) -> void:
    if k < -0.1: regime_label.text = "hyperbolic"
    elif k > 0.1: regime_label.text = "elliptic"
    else: regime_label.text = "euclidean"
```

These are thresholded labels, not measured geometries. In a replacement lesson, select the host model explicitly and compute angles from its edge tangents, as the installed workbench does.

Colour the floor by curvature sign.

```gdscript
func tint_floor(k: float) -> void:
    var mat: StandardMaterial3D = floor.material_override
    mat.albedo_color = Color(0.5 - k * 0.3, 0.5, 0.5 + k * 0.3)
```

The parameter changes the tint. It changes neither the player’s movement metric nor the geometry of the museum floor.

Keep the distinction between a declared model and a persuasive picture. Russell Paradox next asks whether a declared membership rule can be satisfied.
<<</MAP>>>
