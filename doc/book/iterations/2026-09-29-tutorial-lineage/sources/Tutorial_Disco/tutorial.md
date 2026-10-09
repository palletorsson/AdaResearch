# Disco

A 17×17 dance floor. Each tile triggers when stepped on. A step sequencer loops the pattern.

Build the floor.

```gdscript
const FLOOR_SIZE := Vector2i(17, 17)

func build_dance_floor() -> void:
    for y in FLOOR_SIZE.y:
        for x in FLOOR_SIZE.x:
            var tile := DANCE_TILE_SCENE.instantiate()
            tile.position = Vector3(x, 0, y)
            tile.set_meta("coords", Vector2i(x, y))
            tile.body_entered.connect(_on_tile_entered.bind(tile))
            add_child(tile)
```

289 tiles. Each is an Area3D that detects body entry.

Handle tile activation.

```gdscript
func _on_tile_entered(tile: Area3D) -> void:
    var coords: Vector2i = tile.get_meta("coords")
    play_tone_for(coords)
    light_tile(tile, 0.5)
    if recording:
        record_in_step(coords)
```

Playback plus recording, depending on current mode.

Map a tile to a pitch.

```gdscript
const PENTATONIC := [0, 2, 4, 7, 9]  # semitones from root

func pitch_for(coords: Vector2i) -> float:
    var scale_index: int = coords.x % PENTATONIC.size()
    var octave: int = coords.y / PENTATONIC.size()
    var semitones: int = octave * 12 + PENTATONIC[scale_index]
    return 440.0 * pow(2.0, (semitones - 9) / 12.0)  # A4 = 440 Hz
```

Pentatonic scale avoids dissonance. The floor's columns map to scale degrees; rows map to octaves.

Light a tile briefly.

```gdscript
func light_tile(tile: Area3D, duration: float) -> void:
    var mesh := tile.get_node("Mesh")
    var original: Color = mesh.material_override.albedo_color
    mesh.material_override.emission_enabled = true
    mesh.material_override.emission = Color(1, 1, 0)
    var tween := create_tween()
    tween.tween_property(mesh.material_override, "emission_energy_multiplier", 0.0, duration)
```

Bright yellow emission that fades over the duration. The visual cue lasts long enough to register but not long enough to overlap with the next beat.

Record into the step sequencer.

```gdscript
var steps: Array = []  # array of arrays of Vector2i
const STEP_COUNT := 16
var current_step: int = 0

func _ready() -> void:
    for _i in STEP_COUNT:
        steps.append([])

func record_in_step(coords: Vector2i) -> void:
    if not coords in steps[current_step]:
        steps[current_step].append(coords)
```

Each step holds the set of tiles active during that beat. Multiple activations at the same beat stack into one step.

Advance the sequencer.

```gdscript
@export var bpm: float = 120.0
var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    var step_duration: float = 60.0 / bpm / 4.0  # 16th notes
    if time_since_step >= step_duration:
        time_since_step = 0.0
        current_step = (current_step + 1) % STEP_COUNT
        play_step(steps[current_step])
```

Tempo-based advancement. At 120 BPM with 16th notes, the sequencer advances every 0.125 seconds.

Play a step.

```gdscript
func play_step(active_tiles: Array) -> void:
    for coords in active_tiles:
        var tile := find_tile(coords)
        if tile:
            play_tone_for(coords)
            light_tile(tile, 0.1)
```

Every tile in the step fires simultaneously. A strummed chord or a polyrhythmic pulse.

You can now build a dance floor, map tiles to pitches via a pentatonic scale, record into a step sequencer, and play the sequence back at any tempo. Chamber_Arrays closes the sequence with arrangement-as-catalyst.
