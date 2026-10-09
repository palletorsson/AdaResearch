# Random Game — Technical

An 8×8 arena of falling cubes with origami enemies creates a probabilistic hazard space.

## Cube Projectile Spawner

```gdscript
class_name CubeProjectileSpawner extends Node3D

enum Mode { UNIFORM, CLUSTERED, WAVE }
@export var mode: Mode = Mode.UNIFORM
@export var grid_size: Vector2i = Vector2i(8, 8)
@export var cube_drop_height: float = 15.0

var cube_cycles: Array = []  # per-tile sink-rise phase

func _ready() -> void:
    for y in range(grid_size.y):
        cube_cycles.append([])
        for x in range(grid_size.x):
            cube_cycles[y].append(randf_range(0.0, TAU))

func _physics_process(delta: float) -> void:
    match mode:
        Mode.UNIFORM:
            for y in range(grid_size.y):
                for x in range(grid_size.x):
                    cube_cycles[y][x] += delta * 1.5
                    update_cube_at(x, y)
        Mode.CLUSTERED:
            apply_clustered_pattern(delta)
        Mode.WAVE:
            apply_wave_pattern(delta)

func update_cube_at(x: int, y: int) -> void:
    var phase: float = cube_cycles[y][x]
    var height: float = sin(phase) * 2.0
    cube_at(x, y).position.y = height
```

## Origami Enemies

Each origami enemy implements a different stochastic movement pattern.

```gdscript
class_name KaleidocycleEnemy extends CharacterBody3D

@export var face_cycle_interval: float = 2.0

var current_face: int = 0
var time_since_cycle: float = 0.0

func _physics_process(delta: float) -> void:
    time_since_cycle += delta
    if time_since_cycle >= face_cycle_interval * randf_range(0.8, 1.2):
        time_since_cycle = 0.0
        current_face = (current_face + 1) % 4
    # Move in a direction determined by current face
    var move_direction: Vector3 = face_movement_vectors[current_face]
    velocity = velocity.lerp(move_direction * 2.0, 0.1)
    move_and_slide()

class_name KreslingSpire extends StaticBody3D

enum SpireState { FLAT, RISING, ATTACKING, COLLAPSING }
var state: SpireState = SpireState.FLAT

func _physics_process(delta: float) -> void:
    match state:
        SpireState.FLAT:
            if randf() < 0.01:  # 1% chance per frame to rise
                state = SpireState.RISING
        SpireState.RISING:
            transition_to_attacking_over_time(delta)
        SpireState.ATTACKING:
            fire_at_learner_if_possible()
            if should_relocate():
                state = SpireState.COLLAPSING
        SpireState.COLLAPSING:
            collapse_and_reposition(delta)
```

## Game Controller

The `r_c` artifact handles overall game state: score, timer, enemy spawns, win conditions.

```gdscript
class_name GameController extends Node

@export var survival_time: float = 60.0
@export var score_per_second: int = 10
@export var enemies_per_wave: int = 3

var time_elapsed: float = 0.0
var score: int = 0
var enemies_active: Array = []

func _process(delta: float) -> void:
    if learner_alive():
        time_elapsed += delta
        score += int(score_per_second * delta)
        maintain_enemy_count()
    else:
        end_game()

func maintain_enemy_count() -> void:
    while enemies_active.size() < enemies_per_wave:
        spawn_random_enemy()
```

## Complexity

Cube cycle updates are O(grid_size²). Enemy AI is O(enemy count) per frame. Per-frame total at typical counts (64 cubes, 8 enemies) is under a millisecond.

## Within the Sequence

Random_Game is the playable capstone of the Randomness sequence. Surviving the arena requires inhabiting distributions rather than predicting instances.

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.

## Persistence

Each run of the arena is independent; scores and survival times are not persisted across runs by default, though an optional leaderboard mode records them locally.

## Game Over

On death, the arena locks briefly and shows a score summary before offering retry. The summary emphasises distribution exposure over score.

## Score Display

A subtle score readout appears at the edge of the arena, updating without drawing the learner's attention away from the hazard field.

## The crossing staging (2026-09-12)

`commons/primitives/cubes/random_cycle_cube.gd`, opt-in through the map token `r_c#stand:chasm#cue:advance`. Defaults are untouched: at `stand:none` the seven existing placements take the identical path they took before, and `advance_seconds` and `hidden_span_seconds` are both 0, which are the shipped behaviours.

| what | where |
|---|---|
| the drawn wait, and its stored deadline | `_next_random_wait(kind)` and `_note_step`; read through `step_state()` |
| the advance cue | `_build_crown` and `_process`, gated on `advance_seconds > 0` |
| the pit's geometry | `_pit_half()`, derived from `stone_count` and `pit_width` |
| the bed, sides, thresholds, kerbs, way out | `_build_crossing` and `_ramp` |
| the row | `_spawn_stones`, one scene instance per stone, each seeded from the crossing's generator |
| the two surfaces | `_build_stele` (the order, cut) and `_build_tablet` / `_update_tablet` (the draws, live) |
| the controls | `_build_controls` — REPLAY, NEW SEED, CUE through `InteractableAreaButton.button_pressed` |
| the far lip | `_build_idol`, with the crossing's seed cut into the plinth |
| the whole state, for a probe | `crossing_state()` |

Three numbers hold the vertical arrangement: the hall floor sits at root-local `CH_FLOOR`, a standing stone's top `CH_PROUD` above it, and the bed's top `CH_BED`, one metre and two centimetres under the floor. `CH_SINK` is set so a sunken stone comes to rest two centimetres proud of that bed — the floor that left you is the floor you land on. The staging is the tile's own child and the tile sinks by moving itself, so `_process` cancels the sink out of the staging's offset; and because the map-authored lane places a body's origin on the deck and does not read the token's `y` offset, `_prepare_crossing` lowers the tile itself before anything is built.