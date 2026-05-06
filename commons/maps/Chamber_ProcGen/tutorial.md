# Chamber ProcGen

The bricoleur golem rebuilds from scattered parts.

Build the golem.

```gdscript
class_name BricoleurGolem extends CharacterBody3D

var body_parts: Array = []
var detached_fragments: Array = []
@export var reassemble_interval: float = 2.0

var time_since_reassemble: float = 0.0

func _physics_process(delta: float) -> void:
    time_since_reassemble += delta
    if time_since_reassemble >= reassemble_interval:
        time_since_reassemble = 0.0
        reassemble()
```

Periodic reassembly. Every two seconds the golem picks up nearby fragments.

Detach a part.

```gdscript
func on_struck(part: Node3D, force: Vector3) -> void:
    body_parts.erase(part)
    part.reparent(get_tree().root)
    part.freeze = false
    part.apply_impulse(force)
    detached_fragments.append(part)
```

The part becomes a free-flying rigid body. It will settle somewhere nearby.

Find a nearby fragment.

```gdscript
@export var pickup_radius: float = 3.0

func find_nearby_fragment() -> Node3D:
    var best: Node3D = null
    var best_dist: float = pickup_radius
    for frag in detached_fragments:
        var d: float = frag.global_position.distance_to(global_position)
        if d < best_dist:
            best_dist = d; best = frag
    return best
```

Linear search. Pickup_radius is a soft limit on how far the golem can reach.

Attach a fragment.

```gdscript
func attach_fragment(fragment: Node3D) -> void:
    detached_fragments.erase(fragment)
    fragment.reparent(self)
    var attachment_point := compute_attachment_point()
    fragment.position = attachment_point
    fragment.freeze = true
    body_parts.append(fragment)
```

The fragment re-parents to the golem; its position is updated to a chosen attachment point.

Choose an attachment point.

```gdscript
func compute_attachment_point() -> Vector3:
    if body_parts.is_empty():
        return Vector3.ZERO
    var centroid := Vector3.ZERO
    for p in body_parts:
        centroid += p.position
    centroid /= body_parts.size()
    var offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
    return centroid + offset * 0.6
```

Nearby the body's centroid. Random offset means the golem's morphology drifts over time.

Reassemble.

```gdscript
func reassemble() -> void:
    var fragment := find_nearby_fragment()
    if fragment:
        attach_fragment(fragment)
```

One fragment per reassembly tick. Over many ticks the golem restores itself.

Track morphology drift.

```gdscript
var strike_counts: Dictionary = {}

func on_struck_with_tracking(part: Node3D, force: Vector3) -> void:
    var part_type: String = part.get_meta("type", "generic")
    strike_counts[part_type] = strike_counts.get(part_type, 0) + 1
    on_struck(part, force)
```

Record what the learner has hit. Later reassembly can prioritise heavily-struck types.

You can now build the bricoleur_golem, detach parts under impact, find nearby fragments, attach them at a drifting centroid, and track morphology over time. The Procedural Generation sequence closes with ongoing composition as catalyst practice.

Reset the tree.

```gdscript
func reset() -> void:
    nodes.clear()
    parents.clear()
    attractors.clear()
    nodes.append(Vector3.ZERO)
    parents.append(-1)
```

Start fresh. Useful when scatter conditions change.

Spawn fresh fragments when the pile runs low.

```gdscript
func replenish_if_needed(min_fragments: int = 5) -> void:
    if detached_fragments.size() < min_fragments:
        for _i in 3:
            spawn_fresh_fragment()
```

Keeps the chamber in a steady state. The golem never runs out of building material.
