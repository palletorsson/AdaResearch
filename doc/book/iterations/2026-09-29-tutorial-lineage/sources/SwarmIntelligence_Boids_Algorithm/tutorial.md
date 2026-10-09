# Boids Algorithm

Reynolds' three rules. Separation, alignment, cohesion.

Define a boid.

```gdscript
class_name Boid

var position: Vector3
var velocity: Vector3

func random_boid(bounds: AABB, max_speed: float) -> Boid:
    var b := Boid.new()
    b.position = Vector3(
        randf_range(bounds.position.x, bounds.end.x),
        randf_range(bounds.position.y, bounds.end.y),
        randf_range(bounds.position.z, bounds.end.z)
    )
    b.velocity = Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized() * max_speed
    return b
```

Position and velocity. No acceleration — the steering forces drive the velocity directly.

Compute separation.

```gdscript
@export var separation_radius: float = 1.0

func separation(self_boid: Boid, flock: Array) -> Vector3:
    var steer := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        var distance: float = self_boid.position.distance_to(other.position)
        if distance < separation_radius and distance > 0:
            var away: Vector3 = (self_boid.position - other.position).normalized() / distance
            steer += away
            count += 1
    if count > 0: steer /= count
    return steer
```

Push away from close neighbours. Weighted by inverse distance — closer neighbours repel harder.

Compute alignment.

```gdscript
@export var perception_radius: float = 3.0

func alignment(self_boid: Boid, flock: Array) -> Vector3:
    var avg_velocity := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            avg_velocity += other.velocity
            count += 1
    if count == 0: return Vector3.ZERO
    return (avg_velocity / count - self_boid.velocity).normalized()
```

Match the average velocity of nearby boids. The boid turns toward the flock's shared direction.

Compute cohesion.

```gdscript
func cohesion(self_boid: Boid, flock: Array) -> Vector3:
    var centre := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            centre += other.position
            count += 1
    if count == 0: return Vector3.ZERO
    return ((centre / count) - self_boid.position).normalized()
```

Move toward the centre of nearby boids. The flock stays together.

Combine the three forces.

```gdscript
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0

func compute_steering(self_boid: Boid, flock: Array) -> Vector3:
    return (
        separation(self_boid, flock) * separation_weight +
        alignment(self_boid, flock) * alignment_weight +
        cohesion(self_boid, flock) * cohesion_weight
    )
```

Three rules, three weights. Tuning the weights changes the flock's character.

Update all boids.

```gdscript
@export var max_speed: float = 4.0

func _physics_process(delta: float) -> void:
    for boid in flock:
        var steering: Vector3 = compute_steering(boid, flock)
        boid.velocity += steering * delta
        boid.velocity = boid.velocity.limit_length(max_speed)
        boid.position += boid.velocity * delta
```

Each boid computes its steering independently. O(N²) for a naive implementation; spatial partitioning reduces this.

You can now build boids, compute Reynolds' three rules, combine them with weights, and update the flock. SwarmIntelligence_Agent_Based_Modeling_ABM extends into stateful agents.
