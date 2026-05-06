# Primitives Melencolia

Dürer's 1514 engraving Melencolia I sits over the sequence's closing map. The primitives of the sequence appear as its still-life elements.

Spawn the polyhedron at the map's centre.

```gdscript
func spawn_melencolia_polyhedron() -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.mesh = build_truncated_rhombohedron()
    mesh.position = Vector3(0, 0.5, 0)
    return mesh
```

Dürer's solid is a truncated rhombohedron — six rhombic faces plus two triangular caps. Construction is a one-time SurfaceTool exercise.

Build the truncated rhombohedron vertices.

```gdscript
func truncated_rhombohedron_vertices() -> Array:
    # Approximation — Dürer's solid can be drawn from a cube
    # with two opposing corners sliced off.
    const H := 0.5  # half-height
    return [
        Vector3(-H, -H, -H), Vector3(H, -H, -H),
        Vector3(H, H, -H), Vector3(-H, H, -H),
        Vector3(-H, -H, H), Vector3(H, -H, H),
        Vector3(H, H, H), Vector3(-H, H, H),
    ]
```

Eight vertices of a cube, with two diagonally opposite corners cut. The cut reveals two triangular faces; the remaining cube faces become rhombi.

Place the magic square on a wall.

```gdscript
func spawn_magic_square() -> Node3D:
    const GRID := [
        [16, 3, 2, 13],
        [5, 10, 11, 8],
        [9, 6, 7, 12],
        [4, 15, 14, 1],
    ]
    var panel := Panel3D.new()
    panel.content = format_magic_square(GRID)
    panel.position = Vector3(-2, 1.5, 0)
    return panel
```

Dürer's 4x4 magic square: every row, column, diagonal, and corner sums to 34. The bottom row's middle two numbers are 15 and 14, encoding the engraving's date.

Add the hourglass.

```gdscript
func spawn_hourglass() -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.mesh = build_hourglass_mesh()
    mesh.position = Vector3(1.5, 1, 0)
    add_child(mesh)
    return mesh
```

Two cones tip-to-tip, sharing a common axis. The narrow waist is a cylinder of small radius. Sand particles fall through via particle system.

Animate sand falling.

```gdscript
class_name SandFall extends GPUParticles3D

func _ready() -> void:
    amount = 1024
    lifetime = 3.0
    var mat := ParticleProcessMaterial.new()
    mat.gravity = Vector3(0, -2, 0)
    mat.initial_velocity_min = 0.1
    mat.initial_velocity_max = 0.2
    process_material = mat
    emitting = true
```

GPU particles handle thousands of grains at interactive rates. The emitter sits at the hourglass waist; gravity pulls the grains into the lower chamber.

Place the compass.

```gdscript
func spawn_compass() -> MeshInstance3D:
    var compass := MeshInstance3D.new()
    compass.mesh = build_compass_mesh()  # two legs hinged at top
    compass.position = Vector3(-1, 1, 0)
    return compass
```

A pair of hinged legs joined at the top. Each leg is a thin cylinder; the hinge is a sphere. The compass measures distances — itself a primitive operation.

Add the comet in the sky.

```gdscript
func spawn_comet() -> Node3D:
    var comet := Node3D.new()
    var head := MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.material_override = make_emissive_material(Color.YELLOW)
    comet.add_child(head)
    add_tail_particles(comet)
    comet.position = Vector3(5, 8, -3)
    return comet
```

An emissive sphere with a trailing particle system. The comet is far from the scene but part of the composition.

Compose the full scene.

```gdscript
func compose_melencolia() -> void:
    spawn_melencolia_polyhedron()
    spawn_magic_square()
    spawn_hourglass()
    spawn_compass()
    spawn_comet()
    spawn_scale()
    spawn_bell()
    spawn_putto()
```

Each artifact is a primitive from the sequence made ornamental. The sequence's geometric vocabulary furnishes a 16th-century still life.

You can now compose a scene from the sequence's geometric primitives, animated via particle systems and orchestrated into a Dürer-referenced tableau. The sequence closes here; the next sequence begins in the adjacent corridor.
