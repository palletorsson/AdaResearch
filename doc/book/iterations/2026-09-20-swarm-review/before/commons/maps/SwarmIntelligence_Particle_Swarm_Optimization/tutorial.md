# Particle Swarm Optimization

Particles search the space. Each remembers its best; all share the global best.

Define a particle.

```gdscript
class_name PSOParticle

var position: Vector2
var velocity: Vector2
var personal_best_position: Vector2
var personal_best_score: float = INF
```

Position, velocity, and personal best tracked. Each particle is self-contained.

Initialise a swarm.

```gdscript
func initialise_swarm(count: int, bounds: Rect2) -> Array:
    var swarm: Array = []
    for _i in count:
        var p := PSOParticle.new()
        p.position = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
        p.velocity = Vector2(randfn(0, 1), randfn(0, 1))
        p.personal_best_position = p.position
        swarm.append(p)
    return swarm
```

Random initial positions and velocities. Covers the search space broadly.

Evaluate the fitness function.

```gdscript
func rastrigin(p: Vector2) -> float:
    var A: float = 10.0
    var n: int = 2
    return A * n + (p.x * p.x - A * cos(2.0 * PI * p.x)) + (p.y * p.y - A * cos(2.0 * PI * p.y))
```

Rastrigin has many local minima and one global minimum at the origin. Standard test function.

Update velocity.

```gdscript
@export var inertia: float = 0.7
@export var cognitive: float = 1.5
@export var social: float = 1.5

func update_velocity(particle: PSOParticle, global_best: Vector2) -> void:
    var r1: float = randf()
    var r2: float = randf()
    particle.velocity = (
        particle.velocity * inertia +
        (particle.personal_best_position - particle.position) * cognitive * r1 +
        (global_best - particle.position) * social * r2
    )
    particle.velocity = particle.velocity.limit_length(5.0)
```

Three contributions: inertia (keep going), cognitive (toward personal best), social (toward global best). Random factors add exploration.

Update position.

```gdscript
func update_position(particle: PSOParticle) -> void:
    particle.position += particle.velocity
```

Simple Euler step. The particle moves according to its new velocity.

Update bests.

```gdscript
var global_best_position: Vector2
var global_best_score: float = INF

func update_bests(particle: PSOParticle) -> void:
    var score: float = rastrigin(particle.position)
    if score < particle.personal_best_score:
        particle.personal_best_score = score
        particle.personal_best_position = particle.position
    if score < global_best_score:
        global_best_score = score
        global_best_position = particle.position
```

Check current position against personal and global bests. Update if improved.

Run one iteration.

```gdscript
func iteration(swarm: Array) -> void:
    for particle in swarm:
        update_velocity(particle, global_best_position)
        update_position(particle)
        update_bests(particle)
```

One update per particle. Over many iterations, the swarm converges on the global minimum.

You can now initialise a swarm, evaluate fitness via Rastrigin, update velocities with inertia/cognitive/social terms, and track personal and global bests. SwarmIntelligence_Swarm_Intelligence_Algorithms extends into a gallery of algorithms.

Reset the simulation.

```gdscript
func reset_swarm(count: int, bounds: Rect2) -> Array:
    return initialise_swarm(count, bounds)
```

Fresh start. Same bounds, new random initial conditions.
