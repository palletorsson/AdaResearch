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

Check the square the angel is not looking at.

```gdscript
func durer_square() -> Array:
    return [[16, 3, 2, 13],
            [5, 10, 11, 8],
            [9, 6, 7, 12],
            [4, 15, 14, 1]]

func line_sums(sq: Array) -> Array:
    var sums: Array = []
    for r in 4:
        sums.append(sq[r][0] + sq[r][1] + sq[r][2] + sq[r][3])
    for c in 4:
        sums.append(sq[0][c] + sq[1][c] + sq[2][c] + sq[3][c])
    sums.append(sq[0][0] + sq[1][1] + sq[2][2] + sq[3][3])
    sums.append(sq[0][3] + sq[1][2] + sq[2][1] + sq[3][0])
    sums.append(sq[0][0] + sq[0][3] + sq[3][0] + sq[3][3])   # the corners
    sums.append(sq[1][1] + sq[1][2] + sq[2][1] + sq[2][2])   # the centre
    for qr in [0, 2]:
        for qc in [0, 2]:
            sums.append(sq[qr][qc] + sq[qr][qc + 1] + sq[qr + 1][qc] + sq[qr + 1][qc + 1])
    return sums
```

Sixteen lines, and every one of them is 34: four rows, four columns, two diagonals, the corners, the centre, the four quarters. The bottom row reads 4, 15, 14, 1, and the middle two are the year. It uses every number from one to sixteen exactly once, so nothing is left over and nothing is missing. It is for nothing. It is finite, exact and complete.

```gdscript
func is_complete(sq: Array) -> bool:
    var seen: Array = []
    for row in sq:
        for v in row:
            seen.append(v)
    seen.sort()
    return seen == range(1, 17)
```

Count the solid at her feet.

```gdscript
func cut_cube_counts() -> Dictionary:
    # a cube with two opposite corners sliced off
    var v := 8 - 2 + 6      # each cut removes a corner and leaves a triangle of three
    var e := 12 + 6         # each cut adds three edges
    var f := 6 + 2          # each cut adds one face
    return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}
```

Twelve, eighteen, eight. Two. The number the chapter has been giving you since the corner, once more, on the last solid.

Try to leave.

```gdscript
func go_anywhere(from: Vector3, by: Transform3D) -> Vector3:
    return by * from
```

Every transformation of a position is a position. There is no function that takes a `Vector3` and returns somewhere that is not one. The universe you have built in this chapter is closed under everything you can do in it, and the next chapter is the whole of what you can do.

You can now check that a finite object is exact and complete, count the last solid, and see that no operation leads out. Transformation is next, and it is about the one thing this chapter never did: moving.
