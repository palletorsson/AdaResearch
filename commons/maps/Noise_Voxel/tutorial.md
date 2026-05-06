# Noise Voxel

Sample 3D noise into a voxel grid. Carve solids from density.

Set up the voxel grid.

```gdscript
@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var threshold: float = 0.5

var density: Array = []

func initialise() -> void:
    density.clear()
    for x in grid_size.x:
        density.append([])
        for y in grid_size.y:
            density[x].append([])
            for z in grid_size.z:
                var p := Vector3(x, y, z) * 0.1
                density[x][y].append(noise.get_noise_3dv(p))
```

Each voxel stores a noise value. The density field becomes the raw material.

Threshold to binary.

```gdscript
func is_solid(x: int, y: int, z: int) -> bool:
    return density[x][y][z] > threshold
```

Above threshold is solid; below is empty. The threshold decides what the world looks like.

Render solid voxels.

```gdscript
func render_voxels() -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = BoxMesh.new()
    var solid_voxels: Array = []
    for x in grid_size.x:
        for y in grid_size.y:
            for z in grid_size.z:
                if is_solid(x, y, z):
                    solid_voxels.append(Vector3i(x, y, z))
    multimesh.instance_count = solid_voxels.size()
    for i in solid_voxels.size():
        var t := Transform3D.IDENTITY
        t.origin = Vector3(solid_voxels[i])
        multimesh.set_instance_transform(i, t)
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = multimesh
    add_child(instance)
```

MultiMesh is essential at these voxel counts. One draw call for the entire volume.

Cull interior voxels.

```gdscript
func is_visible(x: int, y: int, z: int) -> bool:
    for axis in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
        var neighbour: Vector3i = Vector3i(x, y, z) + axis
        if neighbour.x < 0 or neighbour.x >= grid_size.x: return true
        if neighbour.y < 0 or neighbour.y >= grid_size.y: return true
        if neighbour.z < 0 or neighbour.z >= grid_size.z: return true
        if not is_solid(neighbour.x, neighbour.y, neighbour.z): return true
    return false
```

A voxel is visible only if at least one neighbour is empty. Interior cubes are invisible and can be skipped.

Animate threshold.

```gdscript
func _process(delta: float) -> void:
    threshold = 0.3 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 0.5)
    regenerate()
```

The threshold oscillates. The world morphs between sparse clouds and dense blocks.

Carve out a tunnel.

```gdscript
func carve_tunnel(start: Vector3i, end: Vector3i, radius: int) -> void:
    var steps: int = int(Vector3(start - end).length())
    for i in steps:
        var t: float = float(i) / steps
        var centre: Vector3 = lerp(Vector3(start), Vector3(end), t)
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                for dz in range(-radius, radius + 1):
                    if Vector3(dx, dy, dz).length() < radius:
                        var voxel: Vector3i = Vector3i(centre) + Vector3i(dx, dy, dz)
                        density[voxel.x][voxel.y][voxel.z] = -1.0
```

Set density to a very negative value, ensuring the voxel is empty. A tunnel runs through the terrain.

You can now sample 3D noise into a density field, threshold to voxels, render via MultiMesh, cull interior voxels, animate threshold, and carve tunnels. Noise_6_Wall extends into shader-based fBm rendering.
