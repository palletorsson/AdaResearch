# Random_Walk - Technical Tutorial

## The Random Walk Algorithm

A random walk is the simplest model of diffusion: accumulate random steps.

```gdscript
class Walker:
    var position: Vector3 = Vector3.ZERO
    var history: Array[Vector3] = []
    var rng: RandomNumberGenerator

    func _init():
        rng = RandomNumberGenerator.new()
        rng.randomize()
        history.append(position)

    func step(step_size: float = 1.0):
        # Random direction in 3D
        var direction = Vector3(
            rng.randf_range(-1, 1),
            rng.randf_range(-1, 1),
            rng.randf_range(-1, 1)
        ).normalized()

        position += direction * step_size
        history.append(position)
        return position
```

### 2D Grid Random Walk

The classic discrete version:

```gdscript
func grid_walk_step() -> Vector2i:
    # Four directions: up, down, left, right
    var direction = rng.randi() % 4
    match direction:
        0: position.y += 1  # North
        1: position.y -= 1  # South
        2: position.x += 1  # East
        3: position.x -= 1  # West
    return position
```

### Properties of Random Walks

```gdscript
# Key statistical property: displacement grows as sqrt(N)
func expected_displacement(steps: int) -> float:
    # RMS displacement after N steps of unit size
    return sqrt(steps)

# Example: after 100 steps, expected distance from origin ~ 10
# After 10000 steps, expected distance ~ 100

# This is the "drunkard's walk" theorem
# Linear steps, but sqrt displacement—inefficient exploration
```

### Visualizing the Walk

```gdscript
extends Node3D

@export var num_steps: int = 128
@export var step_size: float = 0.1
@export var trail_color: Color = Color.WHITE

var walker: Walker
var trail_mesh: ImmediateMesh

func _ready():
    walker = Walker.new()
    trail_mesh = ImmediateMesh.new()

    # Generate the walk
    for i in range(num_steps):
        walker.step(step_size)

    # Draw the trail
    draw_trail()

func draw_trail():
    trail_mesh.clear_surfaces()
    trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

    for point in walker.history:
        trail_mesh.surface_add_vertex(point)

    trail_mesh.surface_end()
```

### The 128-Step Walk

The `random_walk_128` element visualizes exactly 128 steps:

```gdscript
# Why 128?
# - Power of 2 (clean computationally)
# - Long enough to show statistical behavior
# - Short enough to remain legible
# - Expected displacement: sqrt(128) ≈ 11.3 units
```

## Brownian Motion

Random walks model **Brownian motion**—the jittery movement of particles in fluid:

```gdscript
# Continuous Brownian motion approximation
func brownian_step(delta: float, diffusion_coeff: float) -> Vector3:
    # Wiener process: displacement ~ sqrt(dt) * Normal(0,1)
    var sigma = sqrt(2 * diffusion_coeff * delta)
    return Vector3(
        rng.randfn(0, sigma),
        rng.randfn(0, sigma),
        rng.randfn(0, sigma)
    )
```

### Self-Avoiding Walk

A variant that doesn't cross its own path:

```gdscript
var visited: Dictionary = {}

func self_avoiding_step() -> Vector3:
    var attempts = 0
    while attempts < 100:
        var candidate = position + random_direction()
        var key = hash_position(candidate)
        if not visited.has(key):
            visited[key] = true
            position = candidate
            return position
        attempts += 1
    # Stuck—no valid moves
    return position
```

## Implementation Notes

### Pit Structure
The map's void floor (height 0) surrounded by walls (height 2-3) creates an observation deck. Walks are visualized in the pit, viewed from above.

### pixel_cloud Elements
The three `pixel_cloud` elements at corners demonstrate point distributions—related to random walk endpoints after many trials.

### random_walk_collection
Multiple walks displayed together show:
- Variability: same algorithm, different outcomes
- Statistics: ensemble behavior visible
- Comparison: which walks drifted further?

## Key Takeaway

The random walk demonstrates **emergent complexity from simple rules**:
- Each step is trivially random
- But accumulated steps create finely traced paths
- The walker has no memory of direction, only position
- Long-term behavior is predictable statistically (sqrt(N) displacement) but unpredictable individually

This is a fundamental model for diffusion, stock prices, polymer chains, and many natural phenomena. It shows that **randomness + accumulation = complexity**.

## Axiom References
- `commons/context/clipboard/tutorial_text/random_walk_axioms.md`
- `commons/context/clipboard/tutorial_text/info_randomwalk.md`

## Within the Sequence

Random_Walk introduces the random walk as a stochastic process. The walk's accumulated trajectory — the path that emerges from a sequence of independent steps — is the sequence's first example of structure emerging from repeated sampling.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
