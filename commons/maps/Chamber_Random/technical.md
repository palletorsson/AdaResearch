# Chamber Random — Technical

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

## Engagement Metric

The chamber tracks engagement time rather than damage dealt. Befriending the octapod depends on extended presence in the chamber, not on achieving any particular hit rate.