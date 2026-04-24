# Noise One

Fractal Brownian motion. Stack octaves for rich detail.

Sample fBm.

```gdscript
@export var octaves: int = 4
@export var lacunarity: float = 2.0  # frequency multiplier per octave
@export var persistence: float = 0.5  # amplitude multiplier per octave

func fbm(p: Vector2) -> float:
    var total: float = 0.0
    var frequency: float = 1.0
    var amplitude: float = 1.0
    var max_value: float = 0.0
    for _i in octaves:
        total += noise.get_noise_2d(p.x * frequency, p.y * frequency) * amplitude
        max_value += amplitude
        frequency *= lacunarity
        amplitude *= persistence
    return total / max_value
```

Stack multiple octaves at increasing frequency and decreasing amplitude. Normalised to [-1, 1].

Build a torus surface.

```gdscript
func torus_mesh(R: float, r: float, resolution: Vector2i) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for major in resolution.x + 1:
        var u: float = major * TAU / resolution.x
        for minor in resolution.y + 1:
            var v: float = minor * TAU / resolution.y
            var x: float = (R + r * cos(v)) * cos(u)
            var y: float = r * sin(v)
            var z: float = (R + r * cos(v)) * sin(u)
            st.add_vertex(Vector3(x, y, z))
    # triangle indices
    return st.commit()
```

Two-radius parametric torus. R is the main radius; r is the tube radius.

Sample noise on the torus.

```gdscript
func torus_noise(u: float, v: float) -> float:
    return fbm(Vector2(u, v))
```

Evaluate fBm at (u, v) coordinates. The output is used to tint or displace the torus.

Wrap noise without seams.

```gdscript
func wrapped_torus_noise(u: float, v: float) -> float:
    var weight_u1: float = 1 - abs(u - 0.5) * 2
    var weight_u2: float = 1 - abs(u) * 2
    var weight_v1: float = 1 - abs(v - 0.5) * 2
    var weight_v2: float = 1 - abs(v) * 2
    return (
        fbm(Vector2(u, v)) * weight_u1 * weight_v1 +
        fbm(Vector2(u + 1, v)) * weight_u2 * weight_v1 +
        fbm(Vector2(u, v + 1)) * weight_u1 * weight_v2 +
        fbm(Vector2(u + 1, v + 1)) * weight_u2 * weight_v2
    )
```

Blend four noise samples at the torus's seam. Produces a continuous noise without visible seams.

Displace torus vertices.

```gdscript
func displace_torus(mesh: ArrayMesh, amplitude: float) -> ArrayMesh:
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for i in vertices.size():
        var v: Vector3 = vertices[i]
        var u: float = atan2(v.z, v.x) / TAU + 0.5
        var v_coord: float = atan2(v.y, sqrt(v.x * v.x + v.z * v.z) - main_radius) / TAU + 0.5
        var offset: float = wrapped_torus_noise(u, v_coord) * amplitude
        vertices[i] = v + normals[i] * offset
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var new_mesh := ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return new_mesh
```

Displace along the normal. The torus keeps its topology but gains organic texture.

Render octave layers.

```gdscript
func render_octaves_separately() -> void:
    for i in octaves:
        octaves = i + 1
        var mesh := displace_torus(base_mesh, 0.2)
        spawn_torus_at_offset(mesh, Vector3(i * 5, 0, 0))
```

Walk down the row and see how detail accumulates as octaves are added.

You can now compute fBm by stacking octaves, build parametric tori, wrap noise around them seamlessly, and render octave-by-octave. Noise_Voxel extends into 3D voxel displacement.
