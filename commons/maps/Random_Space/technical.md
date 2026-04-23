# Random_Space - Technical Documentation

## Core Concept in Code

### Random Space Filling Visualization

```gdscript
extends Node3D

@export var bounds := Vector3(5, 3, 5)
@export var particle_count := 500
@export var update_rate := 30  # Updates per second

var particles := []
var rng := RandomNumberGenerator.new()
var time := 0.0

func _ready():
    rng.randomize()
    create_particles()

func _process(delta):
    time += delta
    for i in range(particles.size()):
        update_particle(particles[i], i)

func create_particles():
    for i in range(particle_count):
        var p = create_particle_mesh()
        p.position = random_position()
        particles.append(p)
        add_child(p)

func update_particle(particle: MeshInstance3D, index: int):
    # Noise-based smooth random movement
    var noise = FastNoiseLite.new()
    noise.seed = index

    particle.position = Vector3(
        noise.get_noise_2d(time, index) * bounds.x,
        noise.get_noise_2d(time + 100, index) * bounds.y + bounds.y/2,
        noise.get_noise_2d(time + 200, index) * bounds.z
    )

    # Random color shifting
    var color_shift = noise.get_noise_1d(time * 0.5 + index)
    var material = particle.material_override as StandardMaterial3D
    material.albedo_color = Color.from_hsv(
        fmod(float(index) / particles.size() + color_shift * 0.2, 1.0),
        0.7,
        0.9
    )

func random_position() -> Vector3:
    return Vector3(
        rng.randf_range(-bounds.x, bounds.x),
        rng.randf_range(0, bounds.y),
        rng.randf_range(-bounds.z, bounds.z)
    )
```

### Integrated Multi-System Display

```gdscript
# Main Random_Space controller
extends Node3D

@onready var gaussian_display = $gaussian_random
@onready var butterflies = $random_butterflies
@onready var space_fill = $random_space
@onready var pollock = $pollock_painting_in_3d

var master_rng := RandomNumberGenerator.new()

func _ready():
    # Synchronize seeds for coordinated chaos
    var master_seed = int(Time.get_unix_time_from_system())
    master_rng.seed = master_seed

    # Each subsystem gets a derived seed
    gaussian_display.initialize(master_rng.randi())
    butterflies.initialize(master_rng.randi())
    space_fill.initialize(master_rng.randi())
    pollock.initialize(master_rng.randi())

func _process(delta):
    # Optional: modulate overall chaos level
    var chaos_level = get_chaos_modulation()
    space_fill.set_chaos(chaos_level)
    butterflies.set_activity(chaos_level)
```

## Implementation Details

### Gaussian Random Callback

```gdscript
# Simplified gaussian visualization for finale
extends Node3D

var histogram_bars := []
var sample_count := 0
var rng := RandomNumberGenerator.new()

func initialize(seed: int):
    rng.seed = seed
    create_histogram_bars(30)

func _process(delta):
    # Continuously add samples
    add_sample()
    if sample_count % 10 == 0:
        update_visualization()

func add_sample():
    var value = rng.randfn(0, 1)
    var bin = int((value + 3) / 6 * histogram_bars.size())
    bin = clamp(bin, 0, histogram_bars.size() - 1)
    histogram_bars[bin].count += 1
    sample_count += 1
```

### Butterfly Swarm for Finale

```gdscript
extends Node3D

@export var butterfly_count := 20
var butterflies := []
var rng := RandomNumberGenerator.new()

func initialize(seed: int):
    rng.seed = seed
    spawn_swarm()

func spawn_swarm():
    for i in range(butterfly_count):
        var butterfly = create_butterfly()
        butterflies.append(butterfly)
        add_child(butterfly)

func _process(delta):
    for b in butterflies:
        b.update_flight(delta, rng)
        # Occasional random direction change
        if rng.randf() < 0.01:
            b.pick_new_direction(rng)
```

### Pollock Painting Finale Version

```gdscript
extends Node3D

var drip_lines := []
var rng := RandomNumberGenerator.new()

func initialize(seed: int):
    rng.seed = seed
    generate_painting()

func generate_painting():
    for i in range(200):
        create_drip()

func create_drip():
    var start = Vector3(
        rng.randf_range(-2, 2),
        rng.randf_range(1, 3),
        rng.randf_range(-2, 2)
    )
    var velocity = Vector3(
        rng.randf_range(-1, 1),
        0,
        rng.randf_range(-1, 1)
    )

    # Simulate drip and create line mesh
    var points := PackedVector3Array()
    var pos = start

    while pos.y > 0:
        points.append(pos)
        velocity.y -= 0.1  # Gravity
        velocity *= 0.99   # Drag
        pos += velocity * 0.1

    create_line_mesh(points, random_pollock_color())
```

## Map-Specific Configuration

### Structure Analysis
- 13×14 grid with double-thick walls
- Central 9×10 arena at height 1
- Southern corridor extensions with exits
- Creates enclosed "final arena" feel

### Element Scale
- `random_space` at scale 1.4 is largest element
- Positioned at (6,6) height -0.3m—slightly below floor, filling upward
- Dominates central space, reinforcing its importance

### Dual Exit Symmetry
Two teleporters at (2,12) and (10,12) mirror the map's bilateral structure.

## Key Takeaways

1. **Integration over isolation** - Finale combines elements from entire sequence
2. **Randomness is a family** - Different manifestations share common principles
3. **Space as entropy** - Visualization fills volume with possibility
4. **Completion with choice** - Even endings branch

## Sequence Rewards
```gdscript
# On teleporter activation
func on_sequence_complete():
    GameState.unlock_badge("entropy_badge")
    GameState.unlock_badge("chaos_explorer_badge")
    GameState.mark_sequence_complete("randomness")
    SceneManager.return_to("Lab/map_data_post_color")
```

## Related Systems
- Sequence management system
- Badge/reward system
- Return-to-lab logic
- Cross-map state persistence

## Within the Sequence

Random_Space is the sequence's argument about randomness as a world-making medium. Random parameters generate the space itself — terrain, density, lighting — rather than merely filling a pre-existing space with random content.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
