# Chamber Forces — Technical

The chamber holds a kresling_spire creature that relaxes when the learner's force catalyst projects a steady field.

```gdscript
class_name ForcesCatalyst extends Node3D

@export var field_radius: float = 2.0
@export var field_strength: float = 5.0
@export var steadiness_window: float = 1.0

var field_samples: Array = []  # recent field vectors for steadiness check

func project_field(direction: Vector3) -> void:
    field_samples.append([Time.get_ticks_msec(), direction])
    field_samples = field_samples.filter(func(s): return (Time.get_ticks_msec() - s[0]) < steadiness_window * 1000)
    apply_force_to_nearby_creatures(direction * field_strength)

func compute_steadiness() -> float:
    if field_samples.size() < 2: return 0.0
    var mean_dir: Vector3 = Vector3.ZERO
    for s in field_samples:
        mean_dir += s[1]
    mean_dir /= field_samples.size()
    var variance: float = 0.0
    for s in field_samples:
        variance += (s[1] - mean_dir).length_squared()
    return 1.0 / (1.0 + variance / field_samples.size())
```

## The Kresling Creature

The kresling_spire has a defensive folded posture and a relaxed unfolded one. Steady field causes it to transition from folded to unfolded.

```gdscript
class_name KreslingSpire extends CharacterBody3D

@export var fold_rate: float = 2.0  # degrees per second
@export var steadiness_threshold: float = 0.7

var fold_angle: float = 45.0  # degrees; 45 = folded, 0 = unfolded

func _physics_process(delta: float) -> void:
    var catalyst = get_tree().get_first_node_in_group("forces_catalyst")
    if catalyst == null: return
    var steadiness: float = catalyst.compute_steadiness()
    if steadiness > steadiness_threshold:
        fold_angle = max(0.0, fold_angle - fold_rate * delta)
    else:
        fold_angle = min(45.0, fold_angle + fold_rate * delta / 2)
    update_fold_visual(fold_angle)
```

## Mutual Force

Newton's third law appears as a measurable pull the creature applies to the learner in return.

```gdscript
func apply_reactive_force(to: Node3D) -> Vector3:
    var dir: Vector3 = (global_position - to.global_position).normalized()
    var mag: float = mass / (global_position.distance_squared_to(to.global_position) + 0.1)
    return dir * mag
```

## Science Screen

The wall display renders both bodies as points in a phase-space plot of position and force.

```gdscript
class_name ForcesScienceScreen extends Node3D

var learner_trace: Array = []
var creature_trace: Array = []

func _process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    var creature = get_tree().get_first_node_in_group("kresling_spire")
    learner_trace.append([learner.global_position, learner.get("applied_force")])
    creature_trace.append([creature.global_position, creature.get("reactive_force")])
    render_paired_trace(learner_trace, creature_trace)
```

## Complexity

The chamber's arithmetic is negligible. The rendering of the kresling's folding animation dominates; it uses a shader-based vertex displacement that costs O(1) per vertex.

Within the sequence, Chamber_Forces closes Forces by converting the accumulated vocabulary into relationship. The chamber hands the learner back to the Lab with the forces catalyst in their kit.

## Steadiness Computation

The steadiness metric is the variance of the catalyst field vector over a short window. Low variance means the field direction has been stable; high variance means it has been jittering. The kresling responds to sustained low-variance projection.

```gdscript
func compute_windowed_steadiness(window_samples: Array) -> float:
    if window_samples.is_empty(): return 0.0
    var mean := Vector3.ZERO
    for s in window_samples:
        mean += s
    mean /= window_samples.size()
    var variance: float = 0.0
    for s in window_samples:
        variance += (s - mean).length_squared()
    variance /= window_samples.size()
    return 1.0 / (1.0 + variance)  # high when variance is low
```

The windowing function acts as a low-pass filter, rejecting brief disturbances and rewarding sustained intention.

## Reactive Force Visualization

The kresling's reactive force pulls on the learner through a force field. The visualisation shows both the learner's projected force and the creature's returned force as arrows on the learner's gauntlet.

```gdscript
class_name ReactiveForceDisplay extends Node3D

@export var arrow_scale: float = 0.5

func _process(_delta: float) -> void:
    var outgoing_force: Vector3 = get_parent().current_projection
    var incoming_force: Vector3 = compute_reactive_force()
    update_arrow(outgoing_arrow, outgoing_force * arrow_scale)
    update_arrow(incoming_arrow, incoming_force * arrow_scale)
```

## Kresling Morphology

The kresling creature's body is a folding pattern inspired by origami research — a twisting cylinder whose cross-section rotates as it compresses. The fold angle is a single parameter that controls the body's state from fully folded (defensive, compact) to fully unfolded (relaxed, extended).

```gdscript
class_name KreslingMesh extends MeshInstance3D

@export var n_panels: int = 6
@export var height_per_layer: float = 0.3

func rebuild_mesh(fold_angle_deg: float) -> void:
    var vertices: PackedVector3Array = []
    var fold_rad: float = deg_to_rad(fold_angle_deg)
    for layer in range(5):
        var layer_rotation: float = layer * fold_rad
        for i in range(n_panels):
            var angle: float = i * TAU / n_panels + layer_rotation
            var x: float = cos(angle)
            var z: float = sin(angle)
            vertices.append(Vector3(x, layer * height_per_layer, z))
    # Assemble triangles from vertex list
```

## Befriending State

Once the kresling's fold angle reaches zero and stabilises, the creature transitions to a befriended state. The state is persistent across the session; returning to the chamber finds the kresling already relaxed.

```gdscript
func on_befriended() -> void:
    save_befriended_state(true)
    emit_signal("befriended")
    # Invite the kresling to follow the learner to subsequent chambers
    get_tree().get_first_node_in_group("chamber_roster").add_companion(self)
```

## Complexity

The chamber's arithmetic is minimal. The kresling's mesh rebuild is the most expensive operation, dominated by vertex count; at 6 panels and 5 layers, that is 30 vertices per rebuild, trivial on modern hardware.
