# Wavefunctions Intro

A room lined with oscilloscopes. Four cubes teach the grammar. Start where every periodic motion starts.

Declare the waveform kinds.

```gdscript
enum WaveKind { SINE, SQUARE, SAWTOOTH, TRIANGLE }

@export var kind: WaveKind = WaveKind.SINE
@export var amplitude: float = 1.0
@export var frequency: float = 1.0
```

Four kinds, three parameters. The enum is the alphabet. Amplitude and frequency are the first two letters.

Sample a sine wave.

```gdscript
func sample_sine(t: float) -> float:
    return amplitude * sin(TAU * frequency * t)
```

Time goes in, displacement comes out. The function is the entire contract. Everything else is visualization.

Render the trace to an oscilloscope line.

```gdscript
func render_trace(line: Line2D, width: float) -> void:
    line.clear_points()
    for i in 128:
        var x := float(i) / 128.0 * width
        var t := float(i) / 128.0
        line.add_point(Vector2(x, -sample(t) * 40.0))
```

Green pixels sweep left to right. The trace is the waveform made visible. Oscillation becomes legible as a shape.

Spawn the four teaching cubes.

```gdscript
func build_cubes(parent: Node3D) -> void:
    for i in 4:
        var cube := preload("res://commons/artifacts/wavefunctions/teach_cube.tscn").instantiate()
        cube.kind = i
        cube.position = Vector3(i * 1.5 - 2.25, 1.0, 0.0)
        parent.add_child(cube)
```

Four cubes in a row. Static, rotating, oscillating, transforming. The progression runs left to right: rest, motion, return, change.

Animate the oscillating cube.

```gdscript
func animate_oscillating(cube: Node3D, t: float) -> void:
    cube.position.y = 1.0 + 0.5 * sin(TAU * t)
```

The cube rises and falls between 0.5 and 1.5. The learner sees the sine trace on the scope and the cube in the air as the same curve.

Switch kinds by button.

```gdscript
func _on_kind_button_pressed(k: int) -> void:
    current_kind = k
    sample_func = _sampler_for(k)
    trace_line.clear_points()
```

Each press selects a waveform. The sampler changes; the scope redraws. The button cycles through the alphabet.

Expose the parameter sliders.

```gdscript
func _on_amplitude_slider(v: float) -> void:
    amplitude = lerp(0.1, 2.0, v)

func _on_frequency_slider(v: float) -> void:
    frequency = lerp(0.2, 4.0, v)
```

Two sliders control the trace. Turning amplitude taller or frequency faster is done by hand. The math is the room.

You have met the grammar. The next map, Pendulum, grounds sine in gravity.
<<</MAP>>>

Cycle the kind on a timer.

```gdscript
func auto_cycle(dt: float) -> void:
    cycle_time += dt
    if cycle_time > 3.0:
        current_kind = (current_kind + 1) % 4
        cycle_time = 0.0
```

A demo mode walks through the four kinds automatically. The learner sees the shapes transition without touching controls.
