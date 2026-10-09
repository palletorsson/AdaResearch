# Cave Generation

Give a volume one number per point and march it. Before it, the noise must be given a scale — a ratio between the field and the box that holds it.

Fix the ratio.

```gdscript
@export var noise_scale: float = 13.5
@export var chunk_scale: float = 300.0
@export var iso_level: float = 0.85

func sample_pos(world_pos: Vector3) -> Vector3:
    return (world_pos + noise_offset) * noise_scale / chunk_scale
```

13.5 over 300 metres is 0.045 per metre, so the first octave spans about 22 m. Noise has no size of its own. This division is where the cave gets one.

Sum ridged octaves.

```gdscript
func ridged_sum(p: Vector3, octaves: int) -> float:
    var sum := 0.0
    var amplitude := 1.0
    var weight := 1.0
    for i in octaves:
        var n := 1.0 - absf(noise.get_noise_3d(p.x, p.y, p.z))
        n *= n * weight
        weight = clampf(n * 10.0, 0.0, 1.0)
        sum += n * amplitude
        p *= 2.0
        amplitude *= 0.5
    return sum
```

`1 - abs` folds the noise at zero, so its crossings become creases; squaring sharpens them. `weight` carries forward, so an octave may only paint where the one before it already ridged. Fissures, not static.

Add the one term that knows which way is down.

```gdscript
func density(world_pos: Vector3, plumb_scale: float, octaves: int) -> float:
    var sum := ridged_sum(sample_pos(world_pos), octaves)
    return -(world_pos.y + 100.0) / 300.0 * plumb_scale + sum
```

Everything above it is isotropic. One linear bias makes low regions solid and high air — a horizon from outside, a floor from inside.

Scale that one term.

```gdscript
const PLUMB_SCALES: Dictionary = {
    "bedded": 1.0, "overturned": -1.0, "weightless": 0.0, "steep": 3.0,
}
@export_enum("bedded", "overturned", "weightless", "steep") var plumb: String = "bedded"
```

At `weightless` the term is gone and the sponge is isotropic. Nothing else in the field separates up from down, so the cave stops having a floor.

Choose how many scales to compute.

```gdscript
@export_range(1, 6) var octaves: int = 6

func get_params_array():
    var params = super.get_params_array()
    params.append(float(clampi(octaves, 1, 6)))
    return params
```

Octave k spans about 22 m / 2^k, and the lattice below samples every 4.69 m. Past the second octave the detail is computed and thrown away by the grid that reads it.

Lay the lattice.

```gdscript
const num_voxels_per_axis: int = 8 * 8   # work groups x local size

func run_compute() -> void:
    var list := rendering_device.compute_list_begin()
    rendering_device.compute_list_dispatch(list, 8, 8, 8)
    rendering_device.compute_list_end()
    rendering_device.submit()
```

262,144 cubes, each evaluated at its eight corners and cut against `iso_level`. No cell asks a neighbour anything, so one dispatch does the whole cave.

Count what came back.

```gdscript
num_triangles = counter_data_bytes.to_int32_array()[0]
verts.resize(num_triangles * 3)
```

A counter the cells incremented, not a size known in advance. How much cave there is cannot be told until the field has been evaluated.

Then look at the other body in the room.

```gdscript
@export var use_fallback: bool = false

func _create_simple_cave_mesh() -> void:
    for ring in range(101):
        var t: float = float(ring) / 100.0
        var r: float = 12.0 * (0.7 + 0.6 * sin(t * PI * 8.0))
        for seg in range(40):
            var a: float = float(seg) / 40.0 * TAU
            vertices.append(Vector3(cos(a) * r, sin(a) * r, (t - 0.5) * 200.0))
            normals.append(-Vector3(cos(a), sin(a), 0.0))
```

`marchingcave` sets `use_fallback = true`, so this runs and the shader never loads: a tube of rings around a winding line, normals turned inward. It reads as a cave and shares nothing with one. One surface was found in a field, the other was drawn, and the hall stands them side by side without saying which is which.
