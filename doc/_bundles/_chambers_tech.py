from pathlib import Path

content = {}

content['Trans_Pit'] = """# Trans Pit — Technical

Three rooms stage translation, rotation, and scaling as lethal hazards. Each room has fire pits at height 1 and a transformation-driven obstacle that pushes the learner toward them.

## Translation Room

Pusher blocks translate along a fixed axis at configured speed and distance.

```gdscript
class_name PusherBlock extends StaticBody3D

@export var axis: Vector3 = Vector3.RIGHT
@export var distance: float = 4.0
@export var speed: float = 2.0
@export var pause_duration: float = 0.5

var start_position: Vector3
var phase: float = 0.0  # 0..1, 0 at start, 1 at end

enum State { MOVING_FORWARD, PAUSED_AT_END, MOVING_BACK, PAUSED_AT_START }
var state: State = State.MOVING_FORWARD
var time_in_state: float = 0.0

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    time_in_state += delta
    match state:
        State.MOVING_FORWARD:
            phase = min(1.0, phase + delta * speed / distance)
            if phase >= 1.0: state = State.PAUSED_AT_END; time_in_state = 0.0
        State.PAUSED_AT_END:
            if time_in_state >= pause_duration: state = State.MOVING_BACK; time_in_state = 0.0
        State.MOVING_BACK:
            phase = max(0.0, phase - delta * speed / distance)
            if phase <= 0.0: state = State.PAUSED_AT_START; time_in_state = 0.0
        State.PAUSED_AT_START:
            if time_in_state >= pause_duration: state = State.MOVING_FORWARD; time_in_state = 0.0
    global_position = start_position + axis * distance * phase
```

## Rotation Room

A revolving wall rotates at constant angular velocity, sweeping the arena.

```gdscript
class_name RevolvingWall extends StaticBody3D

@export var angular_velocity: float = 1.0  # radians per second

func _physics_process(delta: float) -> void:
    rotate_y(angular_velocity * delta)
```

## Scaling Room

A grower block expands at a steady scale rate, shrinking the safe footprint.

```gdscript
class_name GrowerBlock extends StaticBody3D

@export var scale_rate: float = 0.2  # scale units per second
@export var max_scale: float = 3.0

var current_scale: float = 1.0

func _physics_process(delta: float) -> void:
    current_scale = min(max_scale, current_scale + scale_rate * delta)
    scale = Vector3.ONE * current_scale

func reset() -> void:
    current_scale = 1.0
    scale = Vector3.ONE
```

## Fire Hazard

Fire pits use the shared h:fire hazard code from the DangerZone utility registry. Contact with a fire pit triggers the DeathEffect sequence.

```gdscript
# DangerZone lookup
func hazard_at(coords: Vector2i) -> String:
    return utilities.get(coords, {}).get("hazard", "")

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        if hazard_at(current_cell(body)) == "fire":
            DeathEffect.trigger(body, "fire")
```

## Room Layout

Each room is a small enclosed area with fire pits around its perimeter and the transformation obstacle in its centre or line of travel. The rooms are connected by short corridors so the learner can progress or retry.

## Complexity

Pusher and grower updates are O(1) per frame. The revolving wall is also O(1). Fire hazard checks are O(1) per body per frame. The whole map runs comfortably at VR frame rate.

## Within the Sequence

Trans_Pit converts the sequence's algebraic transformations into physical stakes. The learner has studied translation, rotation, and scaling as operations; this map makes the operations hazards when applied to inhabited space.
"""

content['Chamber_Transformation'] = """# Chamber Transformation — Technical

The chamber holds a miura_crawler creature that responds to the transformation catalyst by folding rather than taking damage.

## Catalyst Projection

The transformation catalyst fires a projectile tagged with a folding operator. On contact, the operator is applied to the creature's fold state.

```gdscript
class_name TransformationCatalyst extends Node3D

@export var fire_cooldown: float = 0.4
var time_since_fire: float = 0.0

func _process(delta: float) -> void:
    time_since_fire += delta

func fire(direction: Vector3) -> void:
    if time_since_fire < fire_cooldown: return
    time_since_fire = 0.0
    var projectile := FOLD_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 8.0
    projectile.operator = "fold"
    get_tree().root.add_child(projectile)
```

## Miura Crawler Fold State

The creature has a single state variable — fold_amount — that interpolates from 0 (fully unfolded) to 1 (fully folded flat). Each catalyst hit pushes the state toward 1.

```gdscript
class_name MiuraCrawler extends CharacterBody3D

@export var fold_decay_rate: float = 0.1  # per second; folds drift back to unfolded
@export var hit_fold_increment: float = 0.3

var fold_amount: float = 0.0

func _process(delta: float) -> void:
    fold_amount = max(0.0, fold_amount - fold_decay_rate * delta)
    update_mesh_for_fold(fold_amount)

func on_catalyst_hit(operator: String) -> void:
    if operator == "fold":
        fold_amount = min(1.0, fold_amount + hit_fold_increment)
```

## Miura Pattern Mesh Deformation

The Miura fold pattern is a tessellation of parallelograms that alternate their crease directions. As fold_amount increases, the pattern compresses along one axis.

```gdscript
func update_mesh_for_fold(amount: float) -> void:
    var vertices: PackedVector3Array = base_vertices.duplicate()
    var compression: float = 1.0 - amount * 0.8  # 20% of extent at fully folded
    for i in range(vertices.size()):
        var v := vertices[i]
        # Compress along the fold axis (y)
        v.y *= compression
        # Add crease displacement
        var crease_offset: float = amount * 0.3 * sin(v.x * PI)
        v.z += crease_offset
        vertices[i] = v
    mesh.surface_update_vertex_region(0, 0, vertices.to_byte_array())
```

## Science Screen Logging

Each fold event is logged as a scatter-plot entry: (fold_amount, time).

```gdscript
class_name TransformationScreen extends Node3D

var events: Array = []  # [{fold_amount, time, compression_ratio}]

func log_fold(amount: float, compression_ratio: float) -> void:
    events.append({
        "fold_amount": amount,
        "time": Time.get_ticks_msec() / 1000.0,
        "compression_ratio": compression_ratio,
    })
    redraw_scatter()
```

## Befriending

After sustained folded state (fold_amount above 0.8 for several seconds), the crawler enters a befriended state and follows the learner to subsequent chambers.

```gdscript
var sustained_fold_time: float = 0.0
@export var befriend_threshold: float = 3.0

func _process(delta: float) -> void:
    super(delta)
    if fold_amount > 0.8:
        sustained_fold_time += delta
    else:
        sustained_fold_time = max(0.0, sustained_fold_time - delta)
    if sustained_fold_time > befriend_threshold:
        befriend()
```

## Complexity

Projectile updates are O(active projectiles). Mesh deformation is O(vertex count) per fold update, but updates are infrequent (only on hit or passive decay). The chamber runs at full VR frame rate with several active projectiles.

## Within the Sequence

Chamber_Transformation is the first creature encounter in the curriculum. It establishes the catalyst-as-state-inducer pattern that every subsequent chamber extends.
"""

content['Chamber_Color'] = """# Chamber Color — Technical

The chamber's kaleidocycle_enemy responds to the chromatic catalyst. Red, blue, green, and yellow each trigger a different state transition on the creature's cycling attack faces.

## Chromatic Catalyst

```gdscript
class_name ChromaticCatalyst extends Node3D

@export var current_hue: Color = Color.RED
@export var fire_cooldown: float = 0.3

var time_since_fire: float = 0.0

func _process(delta: float) -> void:
    time_since_fire += delta

func cycle_hue() -> void:
    const HUE_CYCLE := [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
    var i: int = HUE_CYCLE.find(current_hue)
    current_hue = HUE_CYCLE[(i + 1) % HUE_CYCLE.size()]
    update_visual()

func fire(direction: Vector3) -> void:
    if time_since_fire < fire_cooldown: return
    time_since_fire = 0.0
    var projectile := HUE_PROJECTILE_SCENE.instantiate()
    projectile.hue = current_hue
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 10.0
    get_tree().root.add_child(projectile)
```

## Kaleidocycle Creature

The kaleidocycle cycles through four attack faces. Each face is associated with a colour vulnerability and a colour that settles it.

```gdscript
class_name KaleidocycleEnemy extends CharacterBody3D

enum Face { FIRE, ICE, SPIKE, SHIELD }
const FACE_HUES: Dictionary = {
    Face.FIRE: Color.RED,
    Face.ICE: Color.BLUE,
    Face.SPIKE: Color.GREEN,
    Face.SHIELD: Color.YELLOW,
}

var current_face: int = Face.FIRE
@export var cycle_interval: float = 2.0

var time_since_cycle: float = 0.0

func _process(delta: float) -> void:
    time_since_cycle += delta
    if time_since_cycle >= cycle_interval:
        time_since_cycle = 0.0
        current_face = (current_face + 1) % 4
        update_visual_for_face()

func on_projectile_hit(hue: Color) -> void:
    var expected_hue: Color = FACE_HUES[current_face]
    var match_strength: float = hue_alignment(hue, expected_hue)
    if match_strength > 0.8:
        on_face_triggered()
    else:
        on_mismatch()
```

## Hue Alignment

The alignment between two colours is computed from their HSV distance.

```gdscript
func hue_alignment(a: Color, b: Color) -> float:
    var a_hsv := rgb_to_hsv(a)
    var b_hsv := rgb_to_hsv(b)
    var hue_dist: float = min(abs(a_hsv.x - b_hsv.x), 1.0 - abs(a_hsv.x - b_hsv.x))
    return 1.0 - hue_dist * 2.0
```

## Science Screen Chromatic Axis

Events are scattered on a one-dimensional chromatic axis showing which hues hit which faces.

```gdscript
class_name ColorScienceScreen extends Node3D

var events: Array = []

func log_hit(hue: Color, face: int, success: bool) -> void:
    events.append({
        "hue_angle": rgb_to_hsv(hue).x * 360.0,
        "face": face,
        "success": success,
        "time": Time.get_ticks_msec() / 1000.0,
    })
    redraw_scatter()
```

## Miura Observer

A befriended miura_crawler from a previous chamber watches from the corner. Its presence is passive — it registers the learner's progress but does not intervene.

## Complexity

Projectile updates are O(1) each. Cycle scheduling is O(1) per creature. The hue-alignment check is O(1) per hit. The whole chamber runs at full VR frame rate with many active projectiles.

## Within the Sequence

Chamber_Color completes the Color sequence's argument that colour is a channel for communication rather than a property of objects.
"""

content['Random_Game'] = """# Random Game — Technical

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
"""

content['Chamber_Random'] = """# Chamber Random — Technical

The chamber stages mutual unpredictability: the chaos catalyst fires projectiles with PRNG-seeded trajectories, and the octapod_crawler moves with noise-perturbed pursuit.

## Chaos Catalyst

```gdscript
class_name ChaosCatalyst extends Node3D

@export var projectile_speed: float = 8.0
@export var noise_amplitude: float = 2.0

func fire(aim_direction: Vector3) -> void:
    var seed: int = Time.get_ticks_msec()
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    # Perturb the aim by random noise
    var perturbed: Vector3 = aim_direction + Vector3(
        rng.randfn(0.0, noise_amplitude / 10.0),
        rng.randfn(0.0, noise_amplitude / 10.0),
        rng.randfn(0.0, noise_amplitude / 10.0),
    )
    perturbed = perturbed.normalized()
    var projectile := CHAOS_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = perturbed * projectile_speed
    projectile.noise_seed = seed
    get_tree().root.add_child(projectile)
```

## Mid-Flight Drift

Projectiles drift during flight according to a noise function.

```gdscript
class_name ChaosProjectile extends RigidBody3D

@export var drift_amplitude: float = 1.0
var noise_seed: int

func _physics_process(delta: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var rng := RandomNumberGenerator.new()
    rng.seed = noise_seed + int(t * 10)
    var drift := Vector3(
        rng.randfn(0.0, drift_amplitude / 5.0),
        rng.randfn(0.0, drift_amplitude / 5.0),
        rng.randfn(0.0, drift_amplitude / 5.0),
    )
    apply_central_force(drift)
```

## Octapod Crawler

The octapod's pursuit has a noise term that destabilises its intercept trajectory.

```gdscript
class_name OctapodCrawler extends CharacterBody3D

@export var max_speed: float = 3.0
@export var noise_weight: float = 0.4

func _physics_process(delta: float) -> void:
    var to_learner: Vector3 = learner.global_position - global_position
    var direct := to_learner.normalized()
    var noise_dir := Vector3(randfn(), randfn(), randfn()).normalized()
    var blended := direct.lerp(noise_dir, noise_weight).normalized()
    velocity = blended * max_speed
    move_and_slide()
```

## Science Screen — Statistical Footprint

The scatter plot accumulates hit/miss positions over time. The cloud of hit points shows the learner's effective fire distribution; the cloud of movement points shows the octapod's path distribution.

```gdscript
class_name ChaosScreen extends Node3D

var hit_points: Array = []  # Vector3 positions
var miss_points: Array = []
var octapod_positions: Array = []

func log_hit(pos: Vector3) -> void:
    hit_points.append(pos)
    redraw_scatter()

func log_miss(pos: Vector3) -> void:
    miss_points.append(pos)
    redraw_scatter()

func log_octapod(pos: Vector3) -> void:
    octapod_positions.append(pos)
    if octapod_positions.size() > 500:
        octapod_positions.pop_front()
```

## Befriending Without Victory

The chamber does not reward defeat. Instead, it rewards sustained engagement — extended time spent in the chamber produces a befriending state for the octapod, who then follows the learner to later chambers.

```gdscript
var time_in_chamber: float = 0.0
@export var befriend_threshold: float = 30.0

func _process(delta: float) -> void:
    time_in_chamber += delta
    if time_in_chamber > befriend_threshold and not octapod.befriended:
        octapod.befriend()
```

## Complexity

Projectile physics, octapod movement, and scatter-plot rendering are all O(active entity count). The chamber runs at full VR frame rate.

## Within the Sequence

Chamber_Random stages entropy as a shared condition rather than a one-sided weapon.
"""

content['Lab_Path'] = """# Lab Path — Technical

A shared corridor template used by every sequence to transition back to the Lab. A 5×5 grid, low ceiling, one ambient element, one teleporter.

## Template Scene

```gdscript
class_name LabPath extends Node3D

@export var source_sequence: String = ""
@export var target_lab_state: String = ""

func _ready() -> void:
    setup_lighting()
    spawn_dark_sphere()
    position_teleporter()

func setup_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.light_energy = 0.3
    light.rotation = Vector3(-0.5, 0.2, 0)
    add_child(light)
    var env := WorldEnvironment.new()
    env.environment = preload("res://commons/environments/lab_path.tres")
    add_child(env)

func spawn_dark_sphere() -> void:
    var sphere := DARK_SPHERE_SCENE.instantiate()
    sphere.position = Vector3(2.5, 1.5, 2.5)  # centre of the 5x5 grid at ~1.5m height
    add_child(sphere)

func position_teleporter() -> void:
    var teleporter := TELEPORTER_SCENE.instantiate()
    teleporter.position = Vector3(2.5, 0.0, 4.5)  # end of the corridor
    teleporter.target_scene = "res://commons/maps/Lab/map.tscn"
    teleporter.target_state = target_lab_state
    add_child(teleporter)
```

## Dark Sphere Ambient

The dark_sphere artifact pulses slowly with purple emission.

```gdscript
class_name DarkSphere extends MeshInstance3D

@export var pulse_period: float = 6.0
@export var base_emission: Color = Color(0.15, 0.05, 0.35)

func _process(_delta: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var phase: float = sin(t / pulse_period * TAU)
    var pulse_amount: float = (phase + 1.0) / 2.0
    var mat: StandardMaterial3D = material_override
    mat.emission_energy_multiplier = 0.5 + pulse_amount * 1.5
    rotate_y(0.1 * _delta)  # slow rotation
```

## Transition State

The lab_path passes a state token to the Lab that the Lab can read. The token records which sequence the learner just completed, so the Lab can reveal new artifacts or open new sequences accordingly.

```gdscript
# On teleport
func transition_to_lab() -> void:
    GameState.current_lab_state = target_lab_state
    get_tree().change_scene_to_file("res://commons/maps/Lab/map.tscn")
```

## Minimal Set of Assets

The map uses only four scene files: the corridor mesh, the dark sphere, the teleporter, and the spawn point. This minimalism is deliberate — the corridor is supposed to feel emptier than the sequence's active maps.

## Load Time

Because the scene is small, loading is fast. The learner does not wait at the transition; the scene change is perceptually instantaneous.

## Variants

Each sequence's lab_path is nearly identical, differing only in the source_sequence and target_lab_state parameters. This is implemented by subclassing the shared template scene with minimal overrides.

```gdscript
class_name NoiseLabPath extends LabPath

func _init() -> void:
    source_sequence = "noise"
    target_lab_state = "noise_complete"
```

## Complexity

The scene is O(1) in complexity. Per-frame cost is dominated by the dark sphere's rendering with emission, which is still under a millisecond on modern hardware.

## Within the Sequence

Lab_Path is the sequence's exit threshold. It teaches nothing and delivers nothing new, which is the point.
"""

content['Chamber_Noise'] = """# Chamber Noise — Technical

The chamber has no creature. The learner authors a small terrain via a noise-parameter bench.

## Parameter Bench

```gdscript
class_name NoiseParameterBench extends Node3D

@export var noise: FastNoiseLite

var params: Dictionary = {
    "frequency": 0.1,
    "amplitude": 1.0,
    "octaves": 4,
    "displacement": 0.5,
    "distribution": "perlin",  # "perlin", "simplex", "value"
}

func _on_slider_changed(param_name: String, value: float) -> void:
    params[param_name] = value
    apply_to_noise()
    terrain.regenerate()

func apply_to_noise() -> void:
    noise.frequency = params.frequency
    noise.fractal_octaves = int(params.octaves)
    match params.distribution:
        "perlin": noise.noise_type = FastNoiseLite.TYPE_PERLIN
        "simplex": noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
        "value": noise.noise_type = FastNoiseLite.TYPE_VALUE
```

## Terrain Generation

The terrain is a grid of tiles whose heights come from the noise function.

```gdscript
class_name NoiseTerrain extends Node3D

@export var grid_size: Vector2i = Vector2i(32, 32)
@export var tile_size: float = 0.5

var noise: FastNoiseLite
var tile_nodes: Array = []

func regenerate() -> void:
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var world_pos: Vector3 = Vector3(x, 0, y) * tile_size
            var noise_value: float = noise.get_noise_2d(world_pos.x, world_pos.z)
            var height: float = noise_value * params.amplitude * params.displacement
            if y < tile_nodes.size() and x < tile_nodes[y].size():
                tile_nodes[y][x].position.y = height
```

## Science Screen — Three Views

The science screen displays three synchronised views: 2D map, heightmap, and parameter list.

```gdscript
class_name NoiseScienceScreen extends Node3D

func redraw() -> void:
    draw_2d_map()
    draw_heightmap()
    draw_parameter_list()

func draw_2d_map() -> void:
    # Render the noise field as a colour image
    var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var v: float = noise.get_noise_2d(x * params.frequency, y * params.frequency)
            v = (v + 1.0) / 2.0  # map to [0,1]
            image.set_pixel(x, y, Color(v, v, v, 1.0))
    map_texture = ImageTexture.create_from_image(image)

func draw_heightmap() -> void:
    # Render a side-view slice of the terrain
    pass
```

## Configuration Gallery

A small gallery records saved terrains. Each save captures the current parameter values plus a screenshot.

```gdscript
class_name TerrainGallery extends Node3D

var saved_configs: Array = []

func save_current(params: Dictionary) -> void:
    var thumb: ImageTexture = capture_thumbnail()
    saved_configs.append({
        "params": params.duplicate(),
        "thumbnail": thumb,
        "saved_at": Time.get_datetime_string_from_system(),
    })
    add_gallery_entry(saved_configs.back())

func load_config(index: int) -> void:
    var config = saved_configs[index]
    for param_name in config.params:
        set_slider_value(param_name, config.params[param_name])
```

## Complexity

Terrain regeneration is O(grid_size²) and runs whenever a parameter changes. At 32×32 that is 1024 noise lookups; modern CPUs handle this in under a millisecond.

## Within the Sequence

Chamber_Noise is the only catalyst chamber without a creature. World-building is the practice it rewards.
"""

content['Chamber_CA'] = """# Chamber CA — Technical

The chamber puts two cellular automata in contact: the learner's cellular catalyst seeds patterns into the lifeform_walker's Game-of-Life hide.

## Cellular Catalyst

```gdscript
class_name CellularCatalyst extends Node3D

@export var seed_pattern: Array = [
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 1],
]  # glider

func fire(aim_direction: Vector3) -> void:
    var projectile := CA_PROJECTILE_SCENE.instantiate()
    projectile.seed_pattern = seed_pattern
    projectile.global_position = global_position
    projectile.linear_velocity = aim_direction * 8.0
    get_tree().root.add_child(projectile)
```

## Lifeform Walker

The creature's hide is a live 2D Conway's Game of Life grid. When a catalyst projectile hits, the projectile's seed pattern is stamped onto the hide at the impact point.

```gdscript
class_name LifeformWalker extends CharacterBody3D

@export var hide_size: Vector2i = Vector2i(32, 32)

var hide_grid: Array  # 2D array of bool
var next_gen: Array

func _ready() -> void:
    hide_grid = []
    for y in range(hide_size.y):
        hide_grid.append([])
        for x in range(hide_size.x):
            hide_grid[y].append(randf() < 0.2)
    next_gen = hide_grid.duplicate(true)

@export var generation_interval: float = 0.2
var time_since_gen: float = 0.0

func _process(delta: float) -> void:
    time_since_gen += delta
    if time_since_gen >= generation_interval:
        time_since_gen = 0.0
        step_game_of_life()
        update_hide_texture()

func step_game_of_life() -> void:
    for y in range(hide_size.y):
        for x in range(hide_size.x):
            var neighbours := count_live_neighbours(x, y)
            var alive: bool = hide_grid[y][x]
            if alive:
                next_gen[y][x] = (neighbours == 2 or neighbours == 3)
            else:
                next_gen[y][x] = (neighbours == 3)
    var temp = hide_grid
    hide_grid = next_gen
    next_gen = temp

func count_live_neighbours(x: int, y: int) -> int:
    var count := 0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + hide_size.x) % hide_size.x
            var ny: int = (y + dy + hide_size.y) % hide_size.y
            if hide_grid[ny][nx]: count += 1
    return count

func stamp_pattern(pattern: Array, at: Vector2i) -> void:
    for dy in range(pattern.size()):
        for dx in range(pattern[dy].size()):
            var tx: int = (at.x + dx) % hide_size.x
            var ty: int = (at.y + dy) % hide_size.y
            if pattern[dy][dx] == 1:
                hide_grid[ty][tx] = true
```

## Hide Rendering

The hide is rendered as a shader-sampled texture. Live cells appear as lighter pixels; dead cells as darker.

```gdscript
func update_hide_texture() -> void:
    var image := Image.create(hide_size.x, hide_size.y, false, Image.FORMAT_RGBA8)
    for y in range(hide_size.y):
        for x in range(hide_size.x):
            var c: Color = Color.WHITE if hide_grid[y][x] else Color(0.1, 0.1, 0.1)
            image.set_pixel(x, y, c)
    hide_texture = ImageTexture.create_from_image(image)
```

## Science Screen

The screen shows both grids side by side: catalyst's current pattern and creature's current hide. Surviving gliders are highlighted.

## Complexity

Game of Life step is O(W·H) per generation. At 32×32 grid and 5 Hz update rate, that is 5120 cell updates per second — trivial.

## Within the Sequence

Chamber_CA closes Cellular Automata with rule systems meeting rule systems. The chamber hands the learner back with the cellular catalyst in their kit.
"""

content['Chamber_Fractals'] = """# Chamber Fractals — Technical

The fractal catalyst fires branching projectiles; the fractal_hydra regrows heads recursively. Neither system has a natural stopping point.

## Branching Projectile

```gdscript
class_name FractalProjectile extends RigidBody3D

@export var branch_depth: int = 2
@export var branch_angle: float = 20.0  # degrees
@export var branches_per_hit: int = 4

func on_hit(collision: KinematicCollision3D) -> void:
    if branch_depth <= 0:
        queue_free()
        return
    spawn_branches(collision.get_normal())
    queue_free()

func spawn_branches(normal: Vector3) -> void:
    var parent_dir: Vector3 = linear_velocity.normalized()
    for i in range(branches_per_hit):
        var child := FRACTAL_PROJECTILE_SCENE.instantiate()
        var offset_angle: float = TAU * i / branches_per_hit
        var axis: Vector3 = normal
        var direction: Vector3 = parent_dir.rotated(axis, offset_angle)
        direction = direction.rotated(axis.cross(parent_dir).normalized(), deg_to_rad(branch_angle))
        child.linear_velocity = direction * linear_velocity.length() * 0.7
        child.branch_depth = branch_depth - 1
        child.global_position = global_position
        get_tree().root.add_child(child)
```

## Fractal Hydra

Each head is a child node; cutting a head removes it and spawns two new heads in nearby positions.

```gdscript
class_name FractalHydra extends CharacterBody3D

var heads: Array = []

func _ready() -> void:
    for i in range(3):
        spawn_head()

func on_head_cut(head: Node3D) -> void:
    heads.erase(head)
    head.queue_free()
    # Regrow two new heads
    for _i in range(2):
        spawn_head_near(head.global_position)

func spawn_head() -> void:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = global_position + Vector3(randf_range(-1, 1), randf_range(0.5, 2), randf_range(-1, 1))
    head.cut.connect(_on_head_cut.bind(head))
    heads.append(head)
    add_child(head)

func spawn_head_near(position: Vector3) -> void:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
    head.cut.connect(_on_head_cut.bind(head))
    heads.append(head)
    add_child(head)
```

## Science Screen — Depth Axis

The scatter plot tracks catalyst branch depth and hydra head count over time. Both curves tend to increase.

```gdscript
class_name FractalScreen extends Node3D

var projectile_depths: Array = []
var hydra_head_counts: Array = []
var timestamps: Array = []

func log_state(proj_depth: int, head_count: int) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    timestamps.append(t)
    projectile_depths.append(proj_depth)
    hydra_head_counts.append(head_count)
    redraw_curves()
```

## Depth-Limited Termination

Both systems have implicit depth limits to prevent infinite recursion. The catalyst's branch_depth defaults to 2 (each shot produces 4 + 16 = 20 branches total). The hydra's heads do not grow indefinitely; a cap of 20 simultaneous heads prevents the scene from overwhelming the physics engine.

```gdscript
@export var max_hydra_heads: int = 20

func on_head_cut(head: Node3D) -> void:
    heads.erase(head)
    head.queue_free()
    var new_head_count: int = min(2, max_hydra_heads - heads.size())
    for _i in range(new_head_count):
        spawn_head_near(head.global_position)
```

## Complexity

Projectile branching is O(branches_per_hit^depth); at depth 2 and 4 branches, that is up to 16 final projectiles per shot. Hydra head management is O(heads). The chamber caps counts to keep per-frame cost bounded.

## Within the Sequence

Chamber_Fractals stages infinite regress as a combat problem the learner cannot win by finishing.
"""

content['Chamber_LSystems'] = """# Chamber LSystems — Technical

The chamber hosts a branching_vine whose body is generated by an L-system. The learner's branching catalyst fires projectiles that also grow via L-system rules.

## L-System Evaluation

```gdscript
class_name LSystem extends Resource

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F[+F][-F]"}
@export var angle: float = 25.0

func expand(generations: int) -> String:
    var current: String = axiom
    for _i in range(generations):
        var expanded: String = ""
        for c in current:
            expanded += rules.get(c, c)
        current = expanded
    return current
```

## Turtle Interpretation

The expanded string is interpreted by a 3D turtle that draws the resulting geometry.

```gdscript
class_name Turtle3D

var position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.UP
var right: Vector3 = Vector3.RIGHT
var stack: Array = []

func interpret(lstring: String, angle_deg: float, segment_length: float) -> Array:
    var segments: Array = []
    for c in lstring:
        match c:
            "F":
                var end = position + direction * segment_length
                segments.append([position, end])
                position = end
            "+":
                direction = direction.rotated(right, deg_to_rad(angle_deg))
            "-":
                direction = direction.rotated(right, deg_to_rad(-angle_deg))
            "[":
                stack.push_back({"pos": position, "dir": direction, "right": right})
            "]":
                var state = stack.pop_back()
                position = state.pos
                direction = state.dir
                right = state.right
    return segments
```

## Branching Catalyst

Each shot applies a few generations of L-system expansion on impact.

```gdscript
class_name BranchingCatalyst extends Node3D

@export var lsystem: LSystem
@export var expansion_depth: int = 2

func fire(aim: Vector3) -> void:
    var projectile := TENDRIL_SCENE.instantiate()
    projectile.lsystem = lsystem
    projectile.expansion_depth = expansion_depth
    projectile.global_position = global_position
    projectile.linear_velocity = aim * 8.0
    get_tree().root.add_child(projectile)

class_name TendrilProjectile extends RigidBody3D

var lsystem: LSystem
var expansion_depth: int

func on_hit(collision: KinematicCollision3D) -> void:
    var lstring := lsystem.expand(expansion_depth)
    var segments := Turtle3D.new().interpret(lstring, lsystem.angle, 0.3)
    spawn_geometry(segments, collision.get_position(), collision.get_normal())
    queue_free()
```

## Branching Vine

The vine's body follows its own L-system with different rules.

```gdscript
class_name BranchingVine extends CharacterBody3D

@export var lsystem: LSystem

func respond_to_catalyst(catalyst_position: Vector3) -> void:
    # Spawn a lateral in the catalyst's direction
    var lstring: String = lsystem.expand(1)
    var direction: Vector3 = (catalyst_position - global_position).normalized()
    var segments: Array = Turtle3D.new().interpret(lstring, lsystem.angle, 0.4)
    spawn_lateral_geometry(segments, direction)
```

## Science Screen — Rewrite Trace

The screen records both L-systems' rewrite histories. Each generation's string is logged with the production rules that expanded it.

```gdscript
class_name LSystemScreen extends Node3D

var catalyst_trace: Array = []
var vine_trace: Array = []

func log_expansion(source: String, generation: int, expanded: String) -> void:
    var trace: Array = catalyst_trace if source == "catalyst" else vine_trace
    trace.append({
        "generation": generation,
        "expanded": expanded,
        "timestamp": Time.get_ticks_msec() / 1000.0,
    })
    redraw_trace_display()
```

## Complexity

L-system expansion is O(|expanded|) per generation. Turtle interpretation is O(|lstring|). Both are fast for modest expansion depths; the chamber caps depth at 3 to prevent unbounded geometry growth.

## Within the Sequence

Chamber_LSystems stages grammar as a shared language between learner and creature.
"""

content['Chamber_SoftBodies'] = """# Chamber SoftBodies — Technical

The chamber has no catalyst mode. The learner pushes the spring_hopper directly, and the push propagates as a deformation wave through the mass-spring lattice.

## Mass-Spring Lattice

```gdscript
class_name MassSpringBody extends Node3D

var masses: Array = []   # positions
var velocities: Array = []  # velocities
var springs: Array = []  # [i, j, rest_length, stiffness]
@export var damping: float = 0.5
@export var mass_value: float = 1.0

func build_lattice(size: Vector3i, spacing: float) -> void:
    for z in range(size.z):
        for y in range(size.y):
            for x in range(size.x):
                masses.append(Vector3(x, y, z) * spacing)
                velocities.append(Vector3.ZERO)
    # Edge springs
    for z in range(size.z):
        for y in range(size.y):
            for x in range(size.x):
                var idx: int = index_of(x, y, z, size)
                if x + 1 < size.x:
                    springs.append([idx, index_of(x + 1, y, z, size), spacing, 20.0])
                if y + 1 < size.y:
                    springs.append([idx, index_of(x, y + 1, z, size), spacing, 20.0])
                if z + 1 < size.z:
                    springs.append([idx, index_of(x, y, z + 1, size), spacing, 20.0])
```

## Physics Step

```gdscript
func _physics_process(delta: float) -> void:
    var forces: Array = []
    for _i in range(masses.size()):
        forces.append(Vector3.ZERO)
    # Spring forces
    for spring in springs:
        var i: int = spring[0]; var j: int = spring[1]
        var rest: float = spring[2]; var k: float = spring[3]
        var delta_p: Vector3 = masses[j] - masses[i]
        var current_length: float = delta_p.length()
        var extension: float = current_length - rest
        var direction: Vector3 = delta_p.normalized()
        var force: Vector3 = direction * extension * k
        forces[i] += force
        forces[j] -= force
    # Integrate
    for i in range(masses.size()):
        var acceleration: Vector3 = forces[i] / mass_value
        velocities[i] = (velocities[i] + acceleration * delta) * (1.0 - damping * delta)
        masses[i] += velocities[i] * delta
```

## Push Response

When the learner pushes the hopper, the push applies a force to nearby masses and propagates through the lattice.

```gdscript
func apply_push(push_position: Vector3, push_force: Vector3, radius: float) -> void:
    for i in range(masses.size()):
        var distance: float = masses[i].distance_to(push_position)
        if distance < radius:
            var falloff: float = 1.0 - distance / radius
            velocities[i] += push_force * falloff
```

## Mesh Reconstruction

The visual mesh is reconstructed each frame from the mass positions.

```gdscript
func rebuild_visual_mesh() -> void:
    var array_mesh := ArrayMesh.new()
    var vertices: PackedVector3Array = []
    for m in masses:
        vertices.append(m)
    var arrays: Array = []
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    arrays[ArrayMesh.ARRAY_INDEX] = compute_surface_indices()
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh_instance.mesh = array_mesh
```

## Science Screen — Field Display

The screen renders displacement as a continuous field using colour intensity and traces energy over time.

```gdscript
class_name SoftScreen extends Node3D

var displacement_samples: Array = []  # grid of displacement magnitudes
var energy_trace: Array = []

func sample_displacement_field() -> void:
    displacement_samples.clear()
    for m in spring_hopper.masses:
        var rest_pos: Vector3 = spring_hopper.rest_position_for(m)
        var displacement_mag: float = (m - rest_pos).length()
        displacement_samples.append(displacement_mag)
    redraw_field_display()

func sample_energy() -> void:
    var total_potential: float = 0.0
    var total_kinetic: float = 0.0
    for spring in spring_hopper.springs:
        var dp: float = (spring_hopper.masses[spring[1]] - spring_hopper.masses[spring[0]]).length() - spring[2]
        total_potential += 0.5 * spring[3] * dp * dp
    for v in spring_hopper.velocities:
        total_kinetic += 0.5 * spring_hopper.mass_value * v.length_squared()
    energy_trace.append([total_potential, total_kinetic])
```

## Complexity

Spring forces are O(spring count) per step. Integration is O(mass count). For a 5×5×5 lattice with 3×125 = 375 springs and 125 masses, the step cost is negligible. Larger lattices are possible via GPU compute shaders.

## Within the Sequence

Chamber_SoftBodies closes the Soft Bodies sequence with contact as distributed wave.
"""

content['Chamber_Swarm'] = """# Chamber Swarm — Technical

The swarm catalyst spawns a small flock of boids; the swarm_hive creature has its own flock. Both flocks run Reynolds' rules with different parameters.

## Boid Flocking

```gdscript
class_name BoidFlock extends Node3D

@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var max_speed: float = 3.0
@export var perception_radius: float = 2.0

var boids: Array = []  # positions
var velocities: Array = []

func _physics_process(delta: float) -> void:
    for i in range(boids.size()):
        var sep: Vector3 = compute_separation(i)
        var ali: Vector3 = compute_alignment(i)
        var coh: Vector3 = compute_cohesion(i)
        var steering: Vector3 = sep * separation_weight + ali * alignment_weight + coh * cohesion_weight
        velocities[i] += steering * delta
        velocities[i] = velocities[i].limit_length(max_speed)
        boids[i] += velocities[i] * delta

func compute_separation(idx: int) -> Vector3:
    var away: Vector3 = Vector3.ZERO
    var count: int = 0
    for j in range(boids.size()):
        if j == idx: continue
        var distance: float = boids[idx].distance_to(boids[j])
        if distance < perception_radius * 0.5:
            away += (boids[idx] - boids[j]) / (distance + 0.01)
            count += 1
    return away / max(count, 1)

func compute_alignment(idx: int) -> Vector3:
    var avg_velocity: Vector3 = Vector3.ZERO
    var count: int = 0
    for j in range(boids.size()):
        if j == idx: continue
        if boids[idx].distance_to(boids[j]) < perception_radius:
            avg_velocity += velocities[j]
            count += 1
    if count == 0: return Vector3.ZERO
    return (avg_velocity / count - velocities[idx])

func compute_cohesion(idx: int) -> Vector3:
    var center: Vector3 = Vector3.ZERO
    var count: int = 0
    for j in range(boids.size()):
        if j == idx: continue
        if boids[idx].distance_to(boids[j]) < perception_radius:
            center += boids[j]
            count += 1
    if count == 0: return Vector3.ZERO
    return (center / count - boids[idx])
```

## Cross-Flock Interaction

When two flocks share a volume, their boids sense each other and the Reynolds rules apply across flock boundaries.

```gdscript
class_name SharedSwarmSpace extends Node3D

var flocks: Array = []  # list of BoidFlock

func compute_cross_flock_steering(boid_index: int, origin_flock: BoidFlock) -> Vector3:
    var sep: Vector3 = Vector3.ZERO
    var count: int = 0
    for other_flock in flocks:
        if other_flock == origin_flock: continue
        for j in range(other_flock.boids.size()):
            var distance: float = origin_flock.boids[boid_index].distance_to(other_flock.boids[j])
            if distance < origin_flock.perception_radius:
                sep += (origin_flock.boids[boid_index] - other_flock.boids[j]) / (distance + 0.01)
                count += 1
    return sep / max(count, 1)
```

## Science Screen — Alignment-Cohesion Axes

The screen plots each flock's average velocity and centroid position over time on perpendicular axes.

```gdscript
class_name SwarmScreen extends Node3D

var catalyst_trace: Array = []
var hive_trace: Array = []

func log_frame(catalyst_flock, hive_flock) -> void:
    catalyst_trace.append({
        "avg_velocity": average_velocity(catalyst_flock),
        "centroid": centroid(catalyst_flock),
    })
    hive_trace.append({
        "avg_velocity": average_velocity(hive_flock),
        "centroid": centroid(hive_flock),
    })
    redraw_traces()
```

## Complexity

Each boid's steering is O(neighbours) with naive neighbour search O(N) per boid. Total cost is O(N²) per frame. Spatial partitioning (uniform grid or KD-tree) reduces this to O(N·log N). The chamber uses 8 boids per flock, so O(N²) is trivial.

## Within the Sequence

Chamber_Swarm closes Swarm Intelligence with two self-organising systems meeting.
"""

content['Chamber_Foundations'] = """# Chamber Foundations — Technical

The paradox_stalker creature exists in two overlapping ghost states. Only one inflicts damage; the other is undetectable from inside the chamber.

## Dual-State Creature

```gdscript
class_name ParadoxStalker extends CharacterBody3D

var ghost_a: ParadoxGhost
var ghost_b: ParadoxGhost
var lethal_ghost: ParadoxGhost  # one of the two, randomised per encounter

func _ready() -> void:
    ghost_a = spawn_ghost("a")
    ghost_b = spawn_ghost("b")
    lethal_ghost = ghost_a if randf() < 0.5 else ghost_b

func spawn_ghost(id: String) -> ParadoxGhost:
    var ghost := PARADOX_GHOST_SCENE.instantiate()
    ghost.ghost_id = id
    add_child(ghost)
    return ghost

func _physics_process(_delta: float) -> void:
    # Both ghosts move identically, so they remain visually indistinguishable
    var target := learner.global_position
    var direct_direction: Vector3 = (target - global_position).normalized()
    for ghost in [ghost_a, ghost_b]:
        ghost.velocity = direct_direction * 1.0
        ghost.move_and_slide()
```

## Damage Routing

Only the lethal ghost can damage the learner on contact.

```gdscript
class_name ParadoxGhost extends CharacterBody3D

@export var ghost_id: String = "a"

func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("learner"): return
    var stalker: ParadoxStalker = get_parent()
    if self == stalker.lethal_ghost:
        DeathEffect.trigger(body, "paradox")
    else:
        # Pass-through; no effect
        pass
```

## No Catalyst

The learner has no catalyst in this chamber. The attempt to distinguish the ghosts is performed by firing existing catalysts from previous chambers; none distinguishes them, because no in-chamber test could.

```gdscript
# Catalyst hit routes to both ghosts
func on_any_catalyst_hit(hit_ghost: ParadoxGhost) -> void:
    # Regardless of which ghost was hit, the hit registers but does nothing identifying
    if randf() < 0.5:
        # Show a hit marker on ghost_a
        pass
    else:
        # Show a hit marker on ghost_b
        pass
```

## Science Screen — Converging Hit Rate

The screen plots a running hit-rate curve that converges to exactly 0.5 regardless of the learner's strategy.

```gdscript
class_name ParadoxScreen extends Node3D

var attempts: int = 0
var hits: int = 0
var hit_rate_curve: Array = []

func log_attempt(was_lethal_hit: bool) -> void:
    attempts += 1
    if was_lethal_hit:
        hits += 1
    hit_rate_curve.append(float(hits) / attempts)
    redraw_curve()
```

## Godelian Interpretation

The chamber's lesson is a limit rather than a skill. No in-chamber test resolves the paradox_stalker's identity because the distinguishing information is not in the chamber.

```gdscript
# An honest panel explains this
class_name HonestPanel extends Node3D

var explanation := ("The two ghosts are indistinguishable from any test you can run inside the chamber. "
    + "This is not a skill problem. No strategy raises the hit rate above 0.5. "
    + "Some questions cannot be answered from within the system that poses them.")
```

## Complexity

Ghost movement is O(1) per frame. Damage routing is O(1) per collision. The chamber's arithmetic is negligible.

## Within the Sequence

Chamber_Foundations closes Foundations Crisis by making incompleteness a body-level condition.
"""

content['Chamber_QFEP'] = """# Chamber QFEP — Technical

The culminating chamber hosts a qfep_calibrator that responds to the coherence of combined catalyst modes rather than to any single projection.

## Multi-Mode Catalyst

```gdscript
class_name QFEPCompositeCatalyst extends Node3D

var active_modes: Array = []  # e.g. ["forces", "chromatic", "fractal", "branching"]

func enable_mode(mode_name: String) -> void:
    if not mode_name in active_modes:
        active_modes.append(mode_name)

func fire_composite(aim: Vector3) -> void:
    for mode_name in active_modes:
        spawn_mode_projectile(mode_name, aim)
    emit_signal("composite_fired", active_modes.duplicate())
```

## QFEP Calibrator

The calibrator responds to mode coherence. A single mode produces no reaction; multiple modes in a tuned combination produce an extended response.

```gdscript
class_name QFEPCalibrator extends Node3D

@export var target_combination: Array = ["forces", "chromatic", "fractal"]
@export var activation_threshold: float = 0.8

var recent_compositions: Array = []

func on_composite_fired(active_modes: Array) -> void:
    recent_compositions.append({
        "modes": active_modes,
        "time": Time.get_ticks_msec() / 1000.0,
    })
    if recent_compositions.size() > 20:
        recent_compositions.pop_front()
    var alignment: float = compute_alignment_with_target(active_modes)
    if alignment > activation_threshold:
        respond_with_full_motion()

func compute_alignment_with_target(active_modes: Array) -> float:
    var intersection: int = 0
    for mode in active_modes:
        if mode in target_combination:
            intersection += 1
    var union: int = active_modes.size() + target_combination.size() - intersection
    return float(intersection) / max(union, 1)
```

## Formula Display

The science screen displays the QFEP formula and highlights each term as the corresponding mode activates.

```gdscript
class_name QFEPFormulaDisplay extends Node3D

@export var formula_text: String = "QFE = F - λE(S) + φΔE(S,t)"

func highlight_mode(mode_name: String) -> void:
    match mode_name:
        "forces": highlight_term("F")
        "chaos", "random": highlight_term("λE(S)")
        "transformation": highlight_term("φΔE(S,t)")

func highlight_term(term: String) -> void:
    # Find the term's position in the formula and flash it
    var start: int = formula_text.find(term)
    if start == -1: return
    # Apply a brief emission effect to that substring
    emit_signal("term_highlighted", term, start)
```

## Wave Composite

The screen collapses the composite into a single waveform whose shape encodes the active mode combination.

```gdscript
class_name QFEPWaveDisplay extends Node3D

func compose_waveform(active_modes: Array, time: float) -> float:
    var result: float = 0.0
    var weights := {"forces": 1.0, "chaos": 0.7, "chromatic": 0.5, "fractal": 0.6, "branching": 0.4, "transformation": 0.8, "swarm": 0.5, "cellular": 0.6}
    for mode_name in active_modes:
        var freq: float = 2.0 + hash(mode_name) % 3
        var amp: float = weights.get(mode_name, 0.5)
        result += amp * sin(freq * time * TAU)
    return result
```

## Befriended Creature Roster

All creatures befriended through earlier chambers appear in this chamber as companions.

```gdscript
class_name CreatureRoster extends Node3D

func populate_from_save_state() -> void:
    var save = GameState.save_data
    for creature_name in save.befriended_creatures:
        var creature_scene: PackedScene = load_creature_scene(creature_name)
        var instance = creature_scene.instantiate()
        instance.position = find_companion_position(creature_name)
        add_child(instance)
        instance.set_friendly_posture()
```

## Configuration Save

Each session's composite configurations are saved to the learner's profile, becoming part of their curriculum history.

```gdscript
func save_session_configs() -> void:
    var profile: LearnerProfile = GameState.profile
    profile.add_qfep_configuration({
        "modes": active_modes.duplicate(),
        "timestamp": Time.get_datetime_string_from_system(),
    })
    profile.save_to_disk()
```

## Complexity

Mode coherence computation is O(|modes|). Waveform composition is O(|modes|) per sample. The chamber's arithmetic is negligible compared to the creature animations it hosts.

## Within the Sequence

Chamber_QFEP is the curriculum's closing handoff — the formula becomes operable rather than studied.
"""

for m, c in content.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(c, encoding='utf-8')

print('done', len(content))
