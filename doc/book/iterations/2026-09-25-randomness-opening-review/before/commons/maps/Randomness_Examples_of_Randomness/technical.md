# Randomness_Examples_of_Randomness - Technical Documentation

## Core Concept in Code

### Pollock Drip Painting

```gdscript
extends Node3D

@export var drip_count := 500
@export var canvas_size := Vector2(10, 10)
@export var gravity := 9.8
@export var viscosity := 0.1

var line_renderer: ImmediateMesh
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    line_renderer = ImmediateMesh.new()
    generate_painting()

func generate_painting():
    line_renderer.clear_surfaces()
    line_renderer.surface_begin(Mesh.PRIMITIVE_LINES)

    for i in range(drip_count):
        simulate_drip()

    line_renderer.surface_end()

func simulate_drip():
    # Random start position (hand position over canvas)
    var pos = Vector3(
        rng.randf_range(-canvas_size.x/2, canvas_size.x/2),
        rng.randf_range(0.5, 2.0),  # Height above canvas
        rng.randf_range(-canvas_size.y/2, canvas_size.y/2)
    )

    # Random initial velocity (arm movement)
    var vel = Vector3(
        rng.randf_range(-2, 2),
        rng.randf_range(-0.5, 0.5),
        rng.randf_range(-2, 2)
    )

    var color = random_color()
    var prev_pos = pos

    # Simulate until paint hits canvas
    while pos.y > 0:
        line_renderer.surface_set_color(color)
        line_renderer.surface_add_vertex(prev_pos)
        line_renderer.surface_add_vertex(pos)

        prev_pos = pos

        # Physics
        vel.y -= gravity * 0.01
        vel *= (1.0 - viscosity * 0.01)
        vel += random_air_resistance()

        pos += vel * 0.01

func random_color() -> Color:
    # Pollock palette: blacks, whites, yellows, reds
    var colors = [
        Color.BLACK,
        Color.WHITE,
        Color(0.9, 0.8, 0.2),  # Yellow
        Color(0.8, 0.2, 0.2),  # Red
        Color(0.3, 0.3, 0.3),  # Gray
    ]
    return colors[rng.randi() % colors.size()]

func random_air_resistance() -> Vector3:
    return Vector3(
        rng.randfn(0, 0.1),
        rng.randfn(0, 0.05),
        rng.randfn(0, 0.1)
    )
```

### Pipe Dream

### Random Butterflies

```gdscript
class_name RandomButterfly
extends Node3D

var velocity := Vector3.ZERO
var target := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var wing_phase := 0.0

@export var speed := 2.0
@export var wander_strength := 1.0
@export var bounds := Vector3(5, 3, 5)

func _ready():
    rng.randomize()
    pick_new_target()

func _process(delta):
    # Wing flapping
    wing_phase += delta * 10
    animate_wings()

    # Movement toward target with randomness
    var direction = (target - position).normalized()
    var wander = random_wander()

    velocity = velocity.lerp(direction * speed + wander, delta * 2)
    position += velocity * delta

    # Look in movement direction
    if velocity.length() > 0.1:
        look_at(position + velocity, Vector3.UP)

    # Pick new target when close
    if position.distance_to(target) < 1.0:
        pick_new_target()

func random_wander() -> Vector3:
    return Vector3(
        rng.randfn(0, wander_strength),
        rng.randfn(0, wander_strength * 0.5),
        rng.randfn(0, wander_strength)
    )

func pick_new_target():
    target = Vector3(
        rng.randf_range(-bounds.x, bounds.x),
        rng.randf_range(0.5, bounds.y),
        rng.randf_range(-bounds.z, bounds.z)
    )

func animate_wings():
    # Oscillate wing rotation
    var angle = sin(wing_phase) * 0.5
    $LeftWing.rotation.z = angle
    $RightWing.rotation.z = -angle
```

### Extreme Randomness

## Map-Specific Configuration

### Structure Analysis
- 12×12 symmetric grid
- Simple perimeter wall (height 2)
- Floor at height 1
- Gallery layout with exhibits at corners

### Exhibit Placement
- Northwest (2,2): Pollock - fine art
- Northeast (8,2): Pipes - computer graphics
- Southwest (2,8): Butterflies - nature
- Southeast (8,8): Extreme - limits
- South exit (10,11): Moss - organic

## Key Takeaways

1. **Randomness enables art** - From Pollock to generative graphics
2. **Different applications, same principles** - All use controlled randomness
3. **Chaos has limits** - Extreme randomness becomes noise
4. **Nature uses randomness creatively** - Butterfly flight, moss growth

## Related Systems
- Particle systems
- ImmediateMesh for procedural geometry
- CSG for constructive solid geometry
- Noise functions for organic variation

## Implementation Notes and Complexity

Each example in the gallery is a small standalone demonstration that samples Godot's randf, randi, or randf_range and uses the samples to drive a visible behaviour. The underlying pseudo-random number generator is a Mersenne Twister with a 2 to the 19937 minus 1 period, which is effectively infinite for any realistic number of samples. Samples are O(1) to draw, and the cost of each demonstration is dominated by the rendering rather than by the random generation.

Seeding is the operation that makes a random sequence reproducible. Calling seed(value) resets the PRNG's state; subsequent calls to the sampling functions produce a deterministic sequence conditional on the seed. The map's gallery exposes a seed control so the learner can save a configuration and replay it. Without seeding, each run of the game produces a different gallery, which is often the desired behaviour; with seeding, the gallery becomes a fixed artifact for a given seed.

Distribution shape is the next concern. randf samples uniformly from zero to one; randf_range samples uniformly from an interval. Neither produces Gaussian samples; Gaussian requires either the Box-Muller transform applied to two uniform samples or a rejection-sampling approach, both of which the map demonstrates. The Box-Muller approach is O(1) per sample but involves a logarithm and a sine, which are expensive compared to a uniform draw.

Within the sequence, Examples_of_Randomness is the orientation map. It introduces the sampling primitives the rest of the Randomness sequence will use, and it demonstrates that the primitives are themselves composed of implementation decisions — seed, distribution, range. The map's gallery is a catalogue of primitives, and the catalogue is the vocabulary the sequence will exercise.
