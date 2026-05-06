# PG Sculpted Forms

Accumulation. Cubes pile; domes arc; membranes laminate.

Drop cubes to form a mound.

```gdscript
func drop_cube(drop_position: Vector3) -> RigidBody3D:
    var cube := RigidBody3D.new()
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    cube.add_child(mesh)
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    cube.add_child(shape)
    cube.global_position = drop_position
    add_child(cube)
    return cube
```

RigidBody3D for physics. Gravity and collision handle the settling.

Rain cubes over time.

```gdscript
@export var drop_rate: float = 2.0

var time_since_drop: float = 0.0

func _process(delta: float) -> void:
    time_since_drop += delta
    if time_since_drop >= 1.0 / drop_rate:
        time_since_drop = 0.0
        drop_cube(Vector3(randf_range(-0.5, 0.5), 8.0, randf_range(-0.5, 0.5)))
```

Two cubes per second. The mound grows unevenly as cubes land on each other.

Build a dome segment.

```gdscript
func build_dome_segment(latitude: float, longitude: float, radius: float) -> MeshInstance3D:
    var segment := MeshInstance3D.new()
    segment.mesh = BoxMesh.new()
    segment.mesh.size = Vector3(0.2, 0.2, 0.2)
    var x: float = radius * sin(latitude) * cos(longitude)
    var y: float = radius * cos(latitude)
    var z: float = radius * sin(latitude) * sin(longitude)
    segment.position = Vector3(x, y, z)
    add_child(segment)
    return segment
```

Spherical coordinates. Each segment sits on the dome's surface.

Populate the dome.

```gdscript
@export var dome_ring_count: int = 8
@export var dome_radius: float = 3.0

func build_dome() -> void:
    for ring in dome_ring_count:
        var latitude: float = ring * PI / 2 / dome_ring_count  # 0 to PI/2
        var segments_in_ring: int = max(8, int(16 * sin(latitude)))
        for seg in segments_in_ring:
            var longitude: float = seg * TAU / segments_in_ring
            build_dome_segment(latitude, longitude, dome_radius)
```

Fewer segments near the top, more near the equator. Density adapts to the dome's curvature.

Build a membrane.

```gdscript
func build_membrane(width: float, height: float, layer_count: int, offset_per_layer: float) -> void:
    for layer in layer_count:
        var membrane := MeshInstance3D.new()
        membrane.mesh = QuadMesh.new()
        membrane.mesh.size = Vector2(width, height)
        membrane.position = Vector3(0, layer * offset_per_layer, 0)
        add_child(membrane)
```

Thin layers stacked. Each offset slightly; together they form a thick surface.

Curve the membranes.

```gdscript
func curve_membrane(membrane: MeshInstance3D, amplitude: float) -> void:
    var mesh: ArrayMesh = membrane.mesh
    var st := SurfaceTool.new()
    st.create_from(mesh, 0)
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Displace vertices according to a sin curve
    # Full implementation omitted for brevity
```

Vertex displacement by a sinusoid. The flat quad becomes a curved sheet.

You can now drop cubes to form a mound, build a dome with spherical-coordinate segments, layer membranes with offsets, and curve them into sheets. PG_Mirrored_Patterns extends into symmetry-amplified generation.
