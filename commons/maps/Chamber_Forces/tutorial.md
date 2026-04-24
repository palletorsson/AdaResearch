# Chamber Forces

The final chamber. A steady field calms the kresling.

Build the forces catalyst.

```gdscript
class_name ForcesCatalyst extends Node3D

@export var field_radius: float = 2.0
@export var field_strength: float = 5.0

func project_field(direction: Vector3) -> void:
    for body in get_bodies_in_radius(field_radius):
        var force: Vector3 = direction * field_strength
        body.apply_central_force(force)
```

Projects a force field rather than firing a projectile. Any body within the radius receives the field's force.

Track field steadiness.

```gdscript
var field_samples: Array = []  # array of (time, direction)

func record_field_sample(direction: Vector3) -> void:
    field_samples.append([Time.get_ticks_msec(), direction])
    field_samples = field_samples.filter(func(s): return Time.get_ticks_msec() - s[0] < 1000)
```

A one-second window of recent samples. Older samples fall out of the window.

Compute steadiness.

```gdscript
func compute_steadiness() -> float:
    if field_samples.size() < 2: return 0.0
    var mean: Vector3 = Vector3.ZERO
    for s in field_samples:
        mean += s[1]
    mean /= field_samples.size()
    var variance: float = 0.0
    for s in field_samples:
        variance += (s[1] - mean).length_squared()
    return 1.0 / (1.0 + variance / field_samples.size())
```

High when the field has been stable, low when the field has been jittering. The creature responds to high steadiness.

Build the kresling creature.

```gdscript
class_name KreslingSpire extends CharacterBody3D

@export var fold_angle: float = 45.0  # defensive
@export var calm_threshold: float = 0.7

func _process(delta: float) -> void:
    var catalyst = get_tree().get_first_node_in_group("forces_catalyst")
    if catalyst and catalyst.compute_steadiness() > calm_threshold:
        fold_angle = max(0.0, fold_angle - 5.0 * delta)
    else:
        fold_angle = min(45.0, fold_angle + 2.0 * delta)
    update_fold_visual(fold_angle)
```

Fold angle decays toward zero under steady field; grows back otherwise. The creature relaxes slowly and re-tenses more slowly.

Render the kresling's fold.

```gdscript
func update_fold_visual(angle_deg: float) -> void:
    # The kresling geometry compresses as angle drops
    var scale_factor: float = 1.0 - (angle_deg / 90.0) * 0.5
    scale = Vector3(1, scale_factor, 1)
```

Vertical compression scales with the fold angle. Zero angle is full extension; 45° is compact.

Detect befriending.

```gdscript
var time_at_zero_fold: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if fold_angle < 1.0:
        time_at_zero_fold += delta
    else:
        time_at_zero_fold = 0.0
    if time_at_zero_fold > 3.0:
        befriend()
```

Three seconds of full extension triggers befriending. The creature then joins the learner's roster of companions.

Record the befriending.

```gdscript
func befriend() -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("kresling_spire")
    emit_signal("befriended")
```

Persistence across sessions. The creature reappears in later chambers as a passive companion.

You can now build the forces catalyst, compute field steadiness, and befriend the kresling_spire creature through sustained calm. The catalyst is yours after the chamber — the Lab will receive you back with it in your kit.
