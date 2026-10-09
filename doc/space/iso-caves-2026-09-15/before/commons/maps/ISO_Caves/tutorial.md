# The Same Surface, Entered

Outside: terrain with arches. Inside: a cave. Same field, same triangles — the only thing that changed is which side of the surface you stand on.

```gdscript
func density(p: Vector3) -> float:
    var ground := noise2d.get_noise_2d(p.x, p.z) * 4.0 - p.y
    var tunnels := noise3d.get_noise_3d(p.x * 0.5, p.y * 0.5, p.z * 0.5)
    return ground + tunnels * 3.0
```

The 3D noise term doesn't just make overhangs — where it runs strongly negative *below* ground level, it eats the interior. The cave is not modeled; it is the region the subtraction hollowed out. Negative space as a first-class output.

For a walkable cave, the mesh needs collision and its triangles must face *inward*:

```gdscript
func make_walkable(mesh: ArrayMesh) -> StaticBody3D:
    var body := StaticBody3D.new()
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    body.add_child(mi)
    var shape := CollisionShape3D.new()
    shape.shape = mesh.create_trimesh_shape()
    body.add_child(shape)
    return body
```

Marching cubes hands you this for free: because the algorithm triangulates the *boundary between inside and outside*, the same wall is correct from both sides. An exterior arch and an interior vault are one surface wearing two readings.

Carve a guaranteed route so the cave is traversable, not just true:

```gdscript
func carve_path(a: Vector3, b: Vector3, r: float = 1.6) -> void:
    for t in 64:
        var p := a.lerp(b, t / 63.0)
        p.y += sin(t * 0.3) * 0.8         # let the tunnel wander
        brush(p, r, -2.0)                  # subtract density along the line
```

A moving subtraction is a corridor. This is the map-generation trick under half this project's caves: guarantee connectivity by carving, let noise provide everything you didn't specify.

Try: walk in until the entrance light disappears, then turn around. The passage reads completely differently outbound — same geometry, other side of the threshold. The cave teaches what the isovalue always meant: inside and outside are one decision, and you are standing in it.
