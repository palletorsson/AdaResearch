# Sine Space

Walk through sin(t) frozen in three dimensions. Build a corridor where the wall is the waveform.

Declare the wall.

```gdscript
class_name SineWall
extends Node3D

@export var amplitude: float = 1.0
@export var frequency: float = 0.5
@export var length: float = 20.0
```

One wall, three parameters. Amplitude is wall height; frequency is crest count along the length.

Tessellate the wall.

```gdscript
func build_wall() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 120:
        var x := float(i) / 120.0 * length
        var y := amplitude * sin(TAU * frequency * x)
        st.add_vertex(Vector3(x, y, 0.0))
        st.add_vertex(Vector3(x, 0.0, 0.0))
    wall_mesh.mesh = st.commit()
```

Vertices step along the length, alternating top and bottom of the wall. The resulting ribbon rises and falls with sine.

Mirror the wall across the corridor.

```gdscript
func build_mirror() -> void:
    mirror_wall.amplitude = amplitude
    mirror_wall.frequency = frequency
    mirror_wall.phase = PI
```

A second wall with phase-shifted sine creates a pinched corridor. The learner walks where the two curves meet.

Sample corridor width at any point.

```gdscript
func corridor_width(x: float) -> float:
    var a := amplitude * sin(TAU * frequency * x)
    var b := amplitude * sin(TAU * frequency * x + PI)
    return abs(a - b)
```

Width varies with position. At certain phases the corridor is wide enough to run through; at others the learner must turn sideways.

Light the peaks warmer.

```gdscript
func tint_height(index: int, height: float) -> void:
    var t: float = clamp((height + amplitude) / (2.0 * amplitude), 0.0, 1.0)
    wall_material.set_instance_shader_parameter("height_tint_%d" % index, Color(1.0, 0.9 - t * 0.4, 0.4))
```

Peaks glow warmer than troughs. The learner sees the waveform as weather.

Spawn markers every wavelength.

```gdscript
func place_markers() -> void:
    var wavelength := 1.0 / frequency
    for i in int(length / wavelength):
        var marker := preload("res://commons/artifacts/wavefunctions/wave_marker.tscn").instantiate()
        marker.position = Vector3(i * wavelength, 0, 0)
        add_child(marker)
```

Markers repeat at the wavelength. Counting markers tells the learner the frequency without reading a panel.

Expose amplitude as a physical lever.

```gdscript
func _on_amplitude_lever_pulled(v: float) -> void:
    amplitude = lerp(0.3, 2.5, v)
    rebuild_wall()
```

Pulling a lever at the corridor entrance rebuilds the walls. The learner changes the weather before walking through it.

You have walked inside a sine function. The next map, Unit Circle, reveals where the wave comes from.
<<</MAP>>>

Save the current corridor as a preset.

```gdscript
func save_preset(slot: int) -> void:
    UserSettings.set_value("sine_space/slot_%d" % slot, {
        "amplitude": amplitude,
        "frequency": frequency,
    })
```

Each slot stores two numbers. Later visits can reload a past corridor.
