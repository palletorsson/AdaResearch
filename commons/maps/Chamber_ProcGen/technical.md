# Chamber ProcGen — Technical

The chamber hosts a bricoleur_golem whose body is assembled from nearby debris fragments. Each strike knocks pieces off; the golem retrieves them and reassembles into a new configuration.

```gdscript
class_name BricoleurGolem extends CharacterBody3D

var body_parts: Array = []  # list of part nodes currently attached
var detached: Array = []  # list of fragments lying on the floor
@export var reassemble_interval: float = 2.0

var time_since_reassemble: float = 0.0

func _physics_process(delta: float) -> void:
    time_since_reassemble += delta
    if time_since_reassemble > reassemble_interval and not detached.is_empty():
        reassemble()
        time_since_reassemble = 0.0

func on_struck(part: Node3D, force: Vector3) -> void:
    body_parts.erase(part)
    part.freeze = false
    part.apply_impulse(force, Vector3.ZERO)
    detached.append(part)

func reassemble() -> void:
    # Find a fragment nearby to pick up
    var candidates: Array = detached.filter(func(p): return global_position.distance_to(p.global_position) < 3.0)
    if candidates.is_empty():
        return
    var fragment = candidates[randi() % candidates.size()]
    detached.erase(fragment)
    attach_fragment(fragment)

func attach_fragment(fragment: Node3D) -> void:
    fragment.freeze = true
    fragment.reparent(self)
    var attachment_point: Vector3 = choose_attachment_point()
    fragment.position = attachment_point
    body_parts.append(fragment)
```

## Attachment Logic

The attachment-point selection determines the golem's evolving morphology. A naive random attachment produces incoherent body plans. A biased attachment — preferring positions that preserve locomotion — produces bodies that keep working.

```gdscript
func choose_attachment_point() -> Vector3:
    var existing_positions: Array = body_parts.map(func(p): return p.position)
    if existing_positions.is_empty():
        return Vector3.ZERO
    var centroid: Vector3 = Vector3.ZERO
    for p in existing_positions:
        centroid += p
    centroid /= existing_positions.size()
    var candidate: Vector3 = centroid + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
    return candidate
```

## Targeting Influence

The learner's strikes shape which body parts the golem rebuilds. Tracking which parts are struck most often biases the reassembly toward replacing those parts with variants. Over time, the golem adapts to the learner's attack patterns.

```gdscript
var part_strike_count: Dictionary = {}  # part_type -> strike count

func on_struck(part: Node3D, force: Vector3) -> void:
    super(part, force)
    var type = part.get_meta("part_type")
    part_strike_count[type] = part_strike_count.get(type, 0) + 1

func priority_for_type(type: String) -> float:
    return 1.0 + part_strike_count.get(type, 0) * 0.1
```

## Science Screen

The wall display renders the golem's current body as a graph of connected parts. Nodes are parts; edges are attachment relationships. The graph mutates with each strike and reassembly, and the screen shows the mutation as an animated topology.

## Complexity

Body reassembly is O(D) per cycle, where D is the number of detached fragments. Attachment-point selection is O(B) for B currently attached parts. Neither is a bottleneck at the small scales the chamber operates on (typically ~12 parts and ~6 detached fragments at any time).

Within the sequence, Chamber_ProcGen closes Procedural Generation by converting the sequence's generative thesis into a creaturely practice. Destruction feeds reconstruction; the golem is always in process; the assembly never reaches a finished form.

## Morphology Bias

Over many strike-reassemble cycles, the golem's morphology drifts. The drift reflects what the learner struck most often. A golem whose legs are struck repeatedly will rebuild with reinforced legs — more legs, sturdier attachment, faster regeneration of leg fragments. A golem whose torso is targeted develops a more robust torso at the expense of extremities.

```gdscript
class_name MorphologyTracker extends Resource

var strike_history: Array = []
var priority_weights: Dictionary = {"leg": 1.0, "arm": 1.0, "torso": 1.0, "head": 1.0}
@export var drift_rate: float = 0.02

func register_strike(part_type: String) -> void:
    strike_history.append(part_type)
    if strike_history.size() > 100:
        strike_history.pop_front()
    recompute_weights()

func recompute_weights() -> void:
    var counts: Dictionary = {}
    for s in strike_history:
        counts[s] = counts.get(s, 0) + 1
    for t in priority_weights:
        var count = counts.get(t, 0)
        var target_weight: float = 1.0 + count * drift_rate
        priority_weights[t] = lerp(priority_weights[t], target_weight, 0.1)
```

## Assembly Rules

The bricoleur's assembly rule is a simple grammar. Given a set of available fragments and a current body state, the rule selects the next fragment to attach and a candidate attachment point.

```gdscript
func assembly_rule() -> Array:  # [fragment, point]
    var eligible := detached.filter(func(f): return f.distance_to(global_position) < pickup_radius)
    if eligible.is_empty():
        return []
    # Prefer fragments whose type has high priority
    eligible.sort_custom(func(a, b): return priority(a.type) > priority(b.type))
    var fragment = eligible[0]
    var point := choose_attachment_point_for(fragment)
    return [fragment, point]
```

Different assembly rules produce different creature aesthetics. A symmetric rule tries to keep the body bilaterally symmetric. An extension rule favours attaching fragments far from the centre. A compaction rule favours attaching fragments close to existing parts.

## Termination

The bricoleur never stops assembling unless no fragments remain. The chamber ensures a continuous supply of debris by spawning fresh fragments when the floor becomes bare. The infinite-assembly condition is part of the chamber's argument: procedural generation has no natural endpoint.

## Emergent Morphology

The drifting priority weights produce emergent morphology that was not designed by the chamber's author. A learner who consistently targets one part type will evolve a golem that looks different from what any other learner's golem looks like. The chamber's output is a joint product of the learner's behaviour and the chamber's rules, and neither can be credited with authorship alone.

## Persistence

The map does not persist the golem's morphology across sessions. Each entry to the chamber produces a fresh golem. A persistent variant would be a natural extension — the chamber becomes a long-term companion whose morphology records the learner's history with it.
