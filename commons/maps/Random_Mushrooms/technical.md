# Random_Mushrooms - Technical Documentation

## Core Concept in Code

### Random Growth Simulation

```gdscript
extends Node3D

@export var spawn_count := 50
@export var spawn_radius := 5.0
@export var growth_rate := 0.5
@export var max_size := 1.0

var mushroom_scene: PackedScene
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    spawn_mushrooms()

func spawn_mushrooms():
    for i in range(spawn_count):
        var pos = random_position()
        if is_valid_location(pos):
            create_mushroom(pos)

func random_position() -> Vector3:
    # Random position within radius
    var angle = rng.randf() * TAU
    var distance = sqrt(rng.randf()) * spawn_radius  # sqrt for uniform disk
    return Vector3(
        cos(angle) * distance,
        0,
        sin(angle) * distance
    )

func is_valid_location(pos: Vector3) -> bool:
    # Environmental constraints
    var moisture = sample_moisture(pos)
    var light = sample_light(pos)
    # Probability based on conditions
    return rng.randf() < moisture * (1.0 - light)

func create_mushroom(pos: Vector3):
    var mushroom = mushroom_scene.instantiate()
    mushroom.position = pos
    mushroom.scale = Vector3.ONE * rng.randf_range(0.3, 1.0)
    mushroom.rotation.y = rng.randf() * TAU
    add_child(mushroom)
```

### Spore Dispersal Simulation

```gdscript
class_name Spore
extends Node3D

var velocity := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var lifetime := 10.0

func _ready():
    rng.randomize()
    # Initial ejection velocity
    var angle = rng.randf() * TAU
    var power = rng.randf_range(2.0, 5.0)
    velocity = Vector3(
        cos(angle) * power * 0.3,
        power,
        sin(angle) * power * 0.3
    )

func _process(delta):
    # Wind influence (random perturbation)
    velocity.x += rng.randfn(0, 0.5) * delta
    velocity.z += rng.randfn(0, 0.5) * delta
    # Gravity
    velocity.y -= 9.8 * delta * 0.01  # Slow fall for spores

    position += velocity * delta
    lifetime -= delta

    if position.y <= 0 or lifetime <= 0:
        attempt_germination()

func attempt_germination():
    var success_chance = calculate_germination_chance()
    if rng.randf() < success_chance:
        spawn_mushroom()
    queue_free()
```

## Implementation Details

### RAND Table Visualization

Displaying the 1955 random number book:

```gdscript
extends Node3D

var rand_digits := []  # Loaded from file or embedded

func _ready():
    load_rand_sample()
    display_page()

func load_rand_sample():
    # Sample from RAND's million random digits
    rand_digits = [
        "10097 32533 76520 13586 34673 54876 80959 09117 39292 74945",
        "37542 04805 64894 74296 24805 24037 20636 10402 00822 91665",
        "08422 68953 19645 09303 23209 02560 15953 34764 35080 33606",
        # ... continues
    ]

func display_page():
    var text = ""
    for row in rand_digits:
        text += row + "\n"
    # Display on 3D text mesh or texture
    create_text_display(text)
```

### Bubble Random Particles

```gdscript
extends GPUParticles3D

func _ready():
    process_material = create_random_material()

func create_random_material() -> ParticleProcessMaterial:
    var mat = ParticleProcessMaterial.new()

    # Random initial velocity
    mat.initial_velocity_min = 0.5
    mat.initial_velocity_max = 2.0
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 180.0  # Full sphere

    # Random size
    mat.scale_min = 0.05
    mat.scale_max = 0.2

    # Gravity and turbulence
    mat.gravity = Vector3(0, -0.5, 0)
    mat.turbulence_enabled = true
    mat.turbulence_noise_strength = 1.0
    mat.turbulence_noise_scale = 0.5

    return mat
```

## Historical Context Code

### Simulating Pre-Computer Randomness

```gdscript
# Linear Congruential Generator (1958 Lehmer method)
class_name LCG
extends RefCounted

var state: int
var a: int = 1664525     # multiplier
var c: int = 1013904223  # increment
var m: int = 4294967296  # modulus (2^32)

func _init(seed: int = 0):
    state = seed

func next() -> int:
    state = (a * state + c) % m
    return state

func randf() -> float:
    return float(next()) / float(m)
```

## Map-Specific Configuration

### Structure Analysis
- 12×13 grid with walled perimeter
- Height progression: 3 (corners) → 2 (walls) → 1 (floor)
- Exit gap at (8,12) with height 0

### Interactable Placement
- Organic elements (mushrooms, bubbles) in center-left
- Historical element (RAND book) near exit
- Creates journey from nature to computation

## Key Takeaways

1. **Randomness has history** - Before PRNGs, we published random tables
2. **Biological randomness meets constraint** - Spores disperse randomly, but germination is selective
3. **Table vs generator** - Consuming stored randomness vs generating on demand
4. **Physical sources** - True randomness comes from physical processes

## Related Systems
- `RandomNumberGenerator` - Godot's PRNG
- Particle systems - Random emission and behavior
- Procedural placement - Random positioning with constraints
