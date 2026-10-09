# Bernini

Solomonic columns are sines wrapped around cylinders. Build the vertex displacement that turns stone into frozen motion.

Declare the column generator.

```gdscript
class_name SolomonicColumn
extends MeshInstance3D

@export var height: float = 4.0
@export var base_radius: float = 0.3
@export var twist_amount: float = 0.4
@export var twist_frequency: float = 3.0
```

Height, base radius, twist amount, twist frequency. The solomonic spiral is two sines along the vertical axis.

Build the ring loop.

```gdscript
func ring_at(y: float) -> PackedVector3Array:
    var ring := PackedVector3Array()
    var twist_x: float = twist_amount * sin(TAU * twist_frequency * y / height)
    var twist_z: float = twist_amount * cos(TAU * twist_frequency * y / height)
    for i in 24:
        var angle := TAU * i / 24.0
        var x := base_radius * cos(angle) + twist_x
        var z := base_radius * sin(angle) + twist_z
        ring.append(Vector3(x, y, z))
    return ring
```

Each ring is 24 vertices around the central axis, with its centre displaced by a small sine. The stack of displaced rings produces the helix.

Stack the rings into a mesh.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    for i in 40:
        var y := float(i) / 40.0 * height
        for v in ring_at(y):
            st.add_vertex(v)
    mesh = st.commit()
```

Forty rings yield a smooth column. Each ring is the same size; the centres spiral. Baroque geometry with twenty-odd lines.

Add vertex colours for depth.

```gdscript
func colour_vertex(st: SurfaceTool, pos: Vector3) -> void:
    var t: float = clamp(pos.y / height, 0.0, 1.0)
    st.set_color(Color(0.8 - t * 0.2, 0.7 - t * 0.1, 0.6))
```

The column darkens slightly at the top. Ambient light reads as contour. Bernini's drama becomes geometric tinting.

Layer noise on the surface.

```gdscript
func perturb(vertex: Vector3, noise: FastNoiseLite) -> Vector3:
    var offset: float = noise.get_noise_3dv(vertex * 4.0) * 0.02
    return vertex + vertex.normalized() * offset
```

Tiny perturbations break the mathematical smoothness. The column reads as stone, not plastic.

Animate the twist over time.

```gdscript
func animate_twist(t: float) -> void:
    twist_amount = 0.3 + 0.1 * sin(t * 0.5)
    build_mesh()
```

The column breathes. It rebuilds slowly as if still being carved. The studio becomes active.

Place a candle at the base for raking light.

```gdscript
func place_candle_light() -> void:
    var light := OmniLight3D.new()
    light.position = Vector3(1.5, 0.3, 0.0)
    light.light_color = Color(1.0, 0.85, 0.6)
    add_child(light)
```

A warm off-centre light grazes the surface. Highlights trace the spiral. Baroque lighting completes the effect.

You have cast sine into stone. The next map, John Cage, turns from oscillation to silence.
<<</MAP>>>
