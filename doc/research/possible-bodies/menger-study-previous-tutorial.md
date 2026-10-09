# Menger Sponge

27 sub-cubes. Remove 7. Recurse on the remaining 20.

Generate sub-cube positions.

```gdscript
func menger_recursion(origin: Vector3, size: float, depth: int) -> Array:
    if depth == 0:
        return [[origin, size]]
    var result: Array = []
    var third: float = size / 3.0
    for x in 3:
        for y in 3:
            for z in 3:
                # Remove centre of each face and the very centre
                var face_count: int = 0
                if x == 1: face_count += 1
                if y == 1: face_count += 1
                if z == 1: face_count += 1
                if face_count >= 2: continue
                var sub_origin: Vector3 = origin + Vector3(x, y, z) * third
                result += menger_recursion(sub_origin, third, depth - 1)
    return result
```

Seven cubes are face-centres or the very centre. Twenty survive. Recurse on survivors.

Render the cubes.

```gdscript
func render_menger(cubes: Array) -> void:
    for cube in cubes:
        var mesh := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(cube[1], cube[1], cube[1])
        mesh.mesh = box
        mesh.position = cube[0] + Vector3(cube[1], cube[1], cube[1]) / 2
        add_child(mesh)
```

Each surviving cube becomes a MeshInstance3D. The sponge emerges.

Use MultiMesh for performance.

```gdscript
func render_menger_multimesh(cubes: Array) -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = BoxMesh.new()
    multimesh.instance_count = cubes.size()
    for i in cubes.size():
        var t := Transform3D.IDENTITY
        t.origin = cubes[i][0] + Vector3.ONE * cubes[i][1] / 2
        t = t.scaled(Vector3.ONE * cubes[i][1])
        multimesh.set_instance_transform(i, t)
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = multimesh
    add_child(instance)
```

One draw call for all cubes. Essential for deep recursion.

Count surviving cubes per depth.

```gdscript
func count_at_depth(depth: int) -> int:
    return int(pow(20, depth))
```

20^n cubes at depth n. Depth 4: 160,000 cubes.

Fractal dimension.

```gdscript
func menger_dimension() -> float:
    return log(20) / log(3)
```

D = log(20)/log(3) ≈ 2.727. A 3D sponge with dimension between 2 and 3.

Handle deep recursion.

```gdscript
@export var depth_limit: int = 4

func safe_render(depth: int) -> void:
    if depth > depth_limit:
        print("Depth cap reached; limiting to ", depth_limit)
        depth = depth_limit
    var cubes: Array = menger_recursion(Vector3.ZERO, 3.0, depth)
    render_menger_multimesh(cubes)
```

Performance guard. Beyond depth 4, even MultiMesh struggles.

Interactive depth slider.

```gdscript
func _on_depth_changed(new_depth: int) -> void:
    for child in get_children():
        if child is MultiMeshInstance3D: child.queue_free()
    safe_render(new_depth)
```

User-adjustable depth. Scene rebuilds on change.

You can now generate the Menger sponge recursively, render it efficiently with MultiMesh, cap recursion depth, compute its fractal dimension, and support interactive depth changes. Fractal_GoldenSpiral extends into organic spirals.
