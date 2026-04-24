# Noise Columns

Classical columns reshape under coherent noise. Baroque emerges.

Create a noise-driven displacement.

```gdscript
var noise := FastNoiseLite.new()

func setup_noise(seed: int = 12345) -> void:
    noise.seed = seed
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 0.3
```

FastNoiseLite is Godot's built-in noise generator. Perlin is the classic choice.

Displace a cylinder's vertices.

```gdscript
func displace_column_vertices(mesh: ArrayMesh, strength: float) -> ArrayMesh:
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for i in vertices.size():
        var v: Vector3 = vertices[i]
        var offset: float = noise.get_noise_3dv(v) * strength
        var radial: Vector3 = Vector3(v.x, 0, v.z).normalized()
        vertices[i] = v + radial * offset
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var new_mesh := ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return new_mesh
```

Noise drives radial displacement. The column bulges and contracts along its length.

Build the base column mesh.

```gdscript
func build_column_mesh(height: float = 3.0, radius: float = 0.5, resolution: Vector2i = Vector2i(16, 32)) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(resolution.y + 1):
        var t: float = float(ring) / resolution.y
        for side in range(resolution.x + 1):
            var angle: float = float(side) / resolution.x * TAU
            var v := Vector3(cos(angle) * radius, t * height, sin(angle) * radius)
            st.add_vertex(v)
    # triangle indices...
    return st.commit()
```

A parametric cylinder. Resolution balances smoothness against vertex count.

Animate the displacement.

```gdscript
@export var displacement_strength: float = 0.0
@export var target_strength: float = 0.5

func _process(delta: float) -> void:
    displacement_strength = lerp(displacement_strength, target_strength, delta * 0.5)
    mesh_instance.mesh = displace_column_vertices(base_mesh, displacement_strength)
```

Smooth transition from classical to baroque. The column morphs in real time.

Sample a terrain height field.

```gdscript
func terrain_height(x: float, z: float, frequency: float, amplitude: float) -> float:
    return noise.get_noise_2d(x * frequency, z * frequency) * amplitude
```

Samples a 2D noise field. Use this as the Y coordinate for terrain vertices.

Build a terrain mesh.

```gdscript
func build_terrain(size: Vector2i, world_size: Vector2, amplitude: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in size.y + 1:
        for x in size.x + 1:
            var world_x: float = x * world_size.x / size.x
            var world_z: float = z * world_size.y / size.y
            var world_y: float = terrain_height(world_x, world_z, 0.2, amplitude)
            st.add_vertex(Vector3(world_x, world_y, world_z))
    # triangle strip indices...
    st.generate_normals()
    return st.commit()
```

Each vertex sits at a noise-sampled height. The terrain rolls smoothly.

You can now build noise-displaced columns and height-field terrain via coherent noise. Noise_One extends into fBm (fractal Brownian motion).
