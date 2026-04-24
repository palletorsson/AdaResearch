# Chamber Swarm — Technical

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
