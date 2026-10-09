# 3D Wave Propagation

Waves spread from a source. Build ripples that attenuate with distance and interfere where they meet.

Declare the source.

```gdscript
class_name WaveSource
extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var speed: float = 3.0
```

Source holds the three numbers every wave needs. Speed is how fast a crest travels outward.

Sample the wave field at a point.

```gdscript
func sample_at(p: Vector3, t: float) -> float:
    var d := p.distance_to(global_position)
    var falloff: float = 1.0 / max(d, 0.1)
    return amplitude * falloff * sin(TAU * frequency * (t - d / speed))
```

Distance becomes delay. Amplitude falls as one over distance. The sample returns displacement at that point and time.

Render the field on a mesh.

```gdscript
func update_field(mesh: ArrayMesh, t: float) -> void:
    for i in vertices.size():
        var h := 0.0
        for source in sources:
            h += source.sample_at(vertices[i], t)
        heights[i] = h
    mesh.surface_update_vertex_region(0, 0, heights.to_byte_array())
```

Each vertex sums contributions from every source. The mesh updates every frame. Interference emerges from the sum.

Place two sources for a double slit.

```gdscript
func build_double_source() -> void:
    var a := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    var b := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    a.position = Vector3(-1.0, 0, 0)
    b.position = Vector3(1.0, 0, 0)
    sources = [a, b]
```

Two sources, one metre apart. The interference pattern appears as bands. The bands move toward either source as amplitudes change.

Colour peaks and troughs.

```gdscript
func tint_by_height(material: ShaderMaterial) -> void:
    material.set_shader_parameter("peak_color", Color(0.9, 0.7, 0.3))
    material.set_shader_parameter("trough_color", Color(0.2, 0.4, 0.7))
```

Peaks warm, troughs cool. The field becomes weather across a reflective surface.

Let the learner drop a pebble.

```gdscript
func _on_pebble_dropped(pos: Vector3) -> void:
    var s := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    s.position = pos
    s.amplitude = 1.5
    s.lifetime = 3.0
    sources.append(s)
```

A dropped pebble spawns a short-lived source. Ripples expand outward. The learner makes weather.

Attenuate lifetime.

```gdscript
func _process(dt: float) -> void:
    for s in sources:
        s.lifetime -= dt
    sources = sources.filter(func(s): return s.lifetime > 0.0)
```

Sources fade out. The field returns to stillness unless the learner keeps dropping pebbles.

You have released the wave to travel. The next map, Effect Sound, turns the wave audible.
<<</MAP>>>

Readout the nearest source's phase at the player.

```gdscript
func readout_phase(player: Vector3) -> float:
    if sources.is_empty(): return 0.0
    var nearest: Node3D = sources[0]
    for s in sources:
        if s.global_position.distance_to(player) < nearest.global_position.distance_to(player):
            nearest = s
    return nearest.global_position.distance_to(player) / nearest.speed
```

Phase delay is distance divided by speed. The readout shows how far behind the source the learner is standing.
