# Random_Rotate_Random_XYZ - Technical Documentation

## Core Concept in Code

### Independent Axis Rotation

```gdscript
extends Node3D

var rotation_speed := Vector3.ZERO

func _ready():
    randomize_rotation()

func randomize_rotation():
    # Each axis gets independent random angular velocity
    rotation_speed = Vector3(
        randf_range(-PI, PI),
        randf_range(-PI, PI),
        randf_range(-PI, PI)
    )

func _process(delta):
    rotation += rotation_speed * delta
```

### Continuous vs Discrete Randomization

```gdscript
# Discrete: randomize once, keep rotating
func discrete_random_rotation():
    rotation = Vector3(
        randf_range(0, TAU),
        randf_range(0, TAU),
        randf_range(0, TAU)
    )

# Continuous: randomize every frame (chaotic)
func _process(delta):
    rotation = Vector3(
        randf_range(0, TAU),
        randf_range(0, TAU),
        randf_range(0, TAU)
    )

# Noise-driven: smooth random rotation
var time := 0.0
var noise := FastNoiseLite.new()

func _process(delta):
    time += delta
    rotation = Vector3(
        noise.get_noise_1d(time) * TAU,
        noise.get_noise_1d(time + 100) * TAU,
        noise.get_noise_1d(time + 200) * TAU
    )
```

## Implementation Details

### The Random_Rotate_Random_XYZ Component

The visualization likely shows objects with:
1. Random initial orientation
2. Random angular velocity per axis
3. Optional: random acceleration (turbulence)

```gdscript
class_name RandomRotator
extends Node3D

@export var speed_range := Vector2(0.5, 2.0)
@export var randomize_on_spawn := true

var angular_velocity := Vector3.ZERO

func _ready():
    if randomize_on_spawn:
        _randomize_velocity()

func _randomize_velocity():
    angular_velocity = Vector3(
        randf_range(-1, 1) * randf_range(speed_range.x, speed_range.y),
        randf_range(-1, 1) * randf_range(speed_range.x, speed_range.y),
        randf_range(-1, 1) * randf_range(speed_range.x, speed_range.y)
    )

func _process(delta):
    rotation += angular_velocity * delta
```

### Uniform Random Rotation (Correct Method)

For truly uniform distribution over all orientations:

```gdscript
# Method 1: Quaternion from 4 Gaussian samples
func uniform_random_rotation() -> Quaternion:
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    # Four independent Gaussian samples
    var x = rng.randfn()
    var y = rng.randfn()
    var z = rng.randfn()
    var w = rng.randfn()

    # Normalize to unit quaternion
    var length = sqrt(x*x + y*y + z*z + w*w)
    return Quaternion(x/length, y/length, z/length, w/length)

# Method 2: Shoemake's uniform quaternion
func shoemake_random_rotation() -> Quaternion:
    var u1 = randf()
    var u2 = randf() * TAU
    var u3 = randf() * TAU

    var sq1 = sqrt(1.0 - u1)
    var sq2 = sqrt(u1)

    return Quaternion(
        sq1 * sin(u2),
        sq1 * cos(u2),
        sq2 * sin(u3),
        sq2 * cos(u3)
    )
```

## Map-Specific Configuration

### Structure Analysis
- 13×16 grid, all tiles at height 2
- Exit gap at (6, 14) with height 0
- Creates a uniform elevated platform

### Boundary Field
The `bf:0.5:0.5:11.5:15.5:2.2:1.5` creates containment boundaries.

### Lighting
Red-shifted ambient [2.4, 0.4, 0.5] creates dramatic effect—unusual for randomness maps. This may highlight the rotation demonstration through color contrast.

## Key Takeaways

1. **3D randomness = 3 independent samples** - each axis needs its own random value
2. **Euler angles have limitations** - gimbal lock makes some orientations unreachable
3. **Quaternions for uniform sampling** - Shoemake's method gives truly uniform random orientations
4. **Independence creates naturalness** - correlated axes look artificial

## Related Systems
- `Transform3D.rotated()` - applying rotation
- `Quaternion` - gimbal-lock-free rotation representation
- `basis` property - orientation as 3x3 matrix
