# Tutorial Disco — Technical

A 17×17 dance floor of Area3D tiles, each triggering an audio and visual response when stepped on. A step sequencer captures activations into a loop that plays back at a configurable tempo.

```gdscript
class_name DanceFloor extends Node3D

@export var size: Vector2i = Vector2i(17, 17)
@export var tile_size: float = 0.8

var tiles: Array = []  # 2D array

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var tile := DanceTile.new()
            tile.position = Vector3(x, 0, y) * tile_size
            tile.coordinates = Vector2i(x, y)
            tile.body_entered.connect(_on_tile_activated.bind(tile))
            add_child(tile)
            row.append(tile)
        tiles.append(row)
```

## Step Sequencer

The sequencer divides a short loop into steps and advances one step per tick. Each step's contents are the set of tiles that were active during that step.

```gdscript
class_name StepSequencer extends Node

@export var steps: int = 16
@export var bpm: float = 120.0

var step_contents: Array = []  # array of arrays of Vector2i
var current_step: int = 0
var time_since_step: float = 0.0

func _ready() -> void:
    for _i in range(steps):
        step_contents.append([])

func _process(delta: float) -> void:
    time_since_step += delta
    var step_interval: float = 60.0 / bpm / 4.0  # 16th notes
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_step = (current_step + 1) % steps
        play_step(step_contents[current_step])

func record_tile(coords: Vector2i) -> void:
    if not coords in step_contents[current_step]:
        step_contents[current_step].append(coords)
```

## Mode Switch

Mode buttons change what `play_step` does with the active tiles.

```gdscript
enum Mode { TONE, LIGHT, PROPAGATE }

@export var mode: Mode = Mode.TONE

func play_step(active_tiles: Array) -> void:
    for coords in active_tiles:
        match mode:
            Mode.TONE:
                play_tone_at(coords)
            Mode.LIGHT:
                light_tile(coords, 0.25)  # one beat
            Mode.PROPAGATE:
                propagate_to_neighbours(coords)
```

## Tone Mapping

Each tile's x-coordinate maps to a scale degree and its y-coordinate maps to an octave. A pentatonic scale (C, D, E, G, A) avoids dissonance regardless of which tiles are active simultaneously.

```gdscript
const PENTATONIC := [0, 2, 4, 7, 9]  # semitones from C

func pitch_for_tile(coords: Vector2i) -> float:
    var scale_degree: int = coords.x % PENTATONIC.size()
    var octave: int = coords.y / PENTATONIC.size() - 1
    var semitones: int = octave * 12 + PENTATONIC[scale_degree]
    return 440.0 * pow(2.0, (semitones - 9) / 12.0)  # A4 = 440 Hz
```

## Propagation Mode

In propagate mode, an active tile lights its neighbours briefly. Over successive steps the activation spreads across the floor.

```gdscript
func propagate_to_neighbours(coords: Vector2i) -> void:
    for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var neighbour_coords := coords + offset
        if neighbour_coords.x < 0 or neighbour_coords.x >= tiles.size(): continue
        if neighbour_coords.y < 0 or neighbour_coords.y >= tiles[0].size(): continue
        tiles[neighbour_coords.x][neighbour_coords.y].flash()
```

## Complexity

Tile setup is O(W·H) — 289 tiles at 17×17. Sequencer playback is O(active tiles per step), typically under 10. The visual effects dominate CPU cost, but the rendering is batched via MultiMeshInstance3D so the frame rate stays high.

Within the sequence, Tutorial_Disco is the playful capstone. The array-as-authoring-surface interpretation sets up the compositional concerns of the Wavefunctions sequence.

## Audio Mixing

With 17×17 = 289 possible tone sources, naive per-tile AudioStreamPlayers would exhaust Godot's audio polyphony limits. The map uses a shared audio bus with an oscillator pool: a fixed number of oscillators (say 16) are dynamically assigned to currently-active tiles.

```gdscript
class_name OscillatorPool extends Node

var oscillators: Array = []
const POOL_SIZE := 16

func _ready() -> void:
    for _i in range(POOL_SIZE):
        var osc := AudioStreamPlayer.new()
        osc.stream = preload("res://audio/base_tone.tres")
        add_child(osc)
        oscillators.append(osc)

func play_pitch(pitch: float) -> void:
    for osc in oscillators:
        if not osc.playing:
            osc.pitch_scale = pitch
            osc.play()
            return
    # All oscillators in use — steal the oldest
    var oldest := find_oldest_playing()
    oldest.stop()
    oldest.pitch_scale = pitch
    oldest.play()
```

## Sequencer Persistence

The sequencer's state can be saved and loaded. Each save is a list of (step_index, [tile_coords]) pairs.

```gdscript
func save_pattern(name: String) -> void:
    var save_data := {
        "bpm": bpm,
        "steps": step_contents,
        "mode": mode,
    }
    var file := FileAccess.open("user://disco_%s.json" % name, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
```

## Metronome

A visual metronome marks the current step. It can be a row of lights at the floor's edge that pulse in sync with the beat, or a digital readout showing step/beat numbers.

```gdscript
class_name Metronome extends Node3D

@export var indicator_lights: Array[Node3D]

func update_step(step_index: int, total_steps: int) -> void:
    for i in range(indicator_lights.size()):
        var light := indicator_lights[i]
        var active: bool = (i == step_index * indicator_lights.size() / total_steps)
        light.get_node("MeshInstance3D").material_override.emission_energy_multiplier = 2.0 if active else 0.2
```

## Record vs Playback

A record toggle distinguishes modes. In record mode, stepping on tiles captures them into the sequencer's current step. In playback mode, the tiles only light up when the sequencer plays them back — stepping on a tile does not modify the recorded pattern.

## Scales and Modes

The default pentatonic scale can be swapped for other modes: diatonic (7-note), chromatic (12-note), octatonic (8-note), or custom scales. The scale selection affects the tone-mode pitch mapping but nothing else.

```gdscript
const SCALES := {
    "pentatonic": [0, 2, 4, 7, 9],
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
}
```

## Floor Layout

The floor uses a raised border around the 17×17 active area to prevent the learner from walking off the edge. The border also houses the sequencer, metronome, and mode controls.
