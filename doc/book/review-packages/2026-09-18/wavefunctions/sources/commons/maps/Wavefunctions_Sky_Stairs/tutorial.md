# Sky Stairs

Stairs climb along a sine curve. Build the vertical amphitheater and mount the wave one step at a time.

Declare the staircase.

```gdscript
class_name SineStaircase
extends Node3D

@export var step_count: int = 60
@export var horizontal_span: float = 15.0
@export var amplitude: float = 6.0
@export var frequency: float = 0.25
```

Sixty steps across fifteen horizontal metres. Amplitude peaks six metres above the base line.

Place each step.

```gdscript
func build_steps() -> void:
    for i in step_count:
        var t: float = float(i) / float(step_count)
        var x := t * horizontal_span - horizontal_span * 0.5
        var y := amplitude * sin(TAU * frequency * x)
        var step := preload("res://commons/artifacts/wavefunctions/stair_step.tscn").instantiate()
        step.position = Vector3(x, y, 0.0)
        add_child(step)
```

Each step sits at sine of its x. The staircase is the waveform; walking the staircase is tracing the wave.

Set step sizes.

```gdscript
func size_step(step: Node3D) -> void:
    step.scale = Vector3(0.25, 0.15, 0.6)
```

Narrow and deep. The learner can walk at a normal stride. Depth matters because the wave steepens near peaks.

Tilt the step to the local slope.

```gdscript
func tilt_step(step: Node3D, x: float) -> void:
    var slope: float = TAU * frequency * amplitude * cos(TAU * frequency * x)
    step.rotation.z = -atan(slope * 0.1)
```

Steps tilt into the wave so the walker's foot finds a level top. The tilt is tiny but prevents the feeling of climbing a corrugated roof.

Spawn floating cubes sampling the air.

```gdscript
func populate_cubes() -> void:
    for i in 40:
        var cube := preload("res://commons/artifacts/wavefunctions/float_cube.tscn").instantiate()
        cube.position = Vector3(randf_range(-7, 7), randf_range(0, 12), randf_range(-3, 3))
        add_child(cube)
```

Cubes hang in the air around the staircase. Most are above the wave; some are below. The sample makes the invisible field legible.

Light peaks with a lamp.

```gdscript
func place_peak_lamps() -> void:
    var wavelength: float = 1.0 / frequency
    for i in int(horizontal_span / wavelength) + 1:
        var x: float = i * wavelength - horizontal_span * 0.5
        var lamp := OmniLight3D.new()
        lamp.position = Vector3(x, amplitude + 1.0, 0.0)
        lamp.light_color = Color(1.0, 0.9, 0.6)
        add_child(lamp)
```

Lamps sit above each peak. The learner climbs toward light and descends into cooler air.

Chime on reaching a peak.

```gdscript
func _on_peak_entered(index: int) -> void:
    peak_chime.pitch_scale = 1.0 + index * 0.05
    peak_chime.play()
```

Each peak sounds slightly higher. The climb becomes a melody. Walking is performance.

You have climbed the wave. The next map, TrigWalkingPath, splits sine from cosine into parallel paths.
<<</MAP>>>
