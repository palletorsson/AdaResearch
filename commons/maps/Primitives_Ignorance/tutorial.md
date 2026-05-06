# Primitives Ignorance

Each object knows its own state. It does not know the larger scene.

Define a local-state object.

```gdscript
class_name LocalObject extends Node3D

var own_position: Vector3 = Vector3.ZERO
var own_velocity: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
    own_position += own_velocity * delta
    global_position = own_position
```

The object tracks its own position and velocity. It has no knowledge of other objects.

Simulate interaction without shared state.

```gdscript
func _physics_process(_delta: float) -> void:
    # Each object computes its own reaction.
    # No central coordinator knows where all objects are.
    var nearby := get_tree().get_nodes_in_group("objects")
    for other in nearby:
        if other == self: continue
        if global_position.distance_to(other.global_position) < 2.0:
            react_to(other)
```

The object queries its environment for neighbours. The query is a local perception, not a global read.

Add a broadcast signal.

```gdscript
signal emitted_event(event_name: String, data: Dictionary)

func emit_local_event(event: String, payload: Dictionary) -> void:
    emitted_event.emit(event, payload)
```

Signals are how local objects talk to each other without knowing about each other. The listeners subscribe independently.

Subscribe to a broadcast.

```gdscript
func _ready() -> void:
    for sibling in get_tree().get_nodes_in_group("broadcasters"):
        sibling.emitted_event.connect(_on_broadcast)

func _on_broadcast(event: String, payload: Dictionary) -> void:
    if event == "alert":
        react_to_alert(payload)
```

The listener reacts only to events it cares about. The broadcaster does not need to know who is listening.

Encapsulate private state.

```gdscript
var _internal_state: Dictionary = {}  # underscore prefix marks private

func public_report() -> Dictionary:
    return {"position": global_position}  # do not expose _internal_state
```

The underscore convention marks fields not meant for external access. Other objects see only what public_report exposes.

Test whether an object knows a fact.

```gdscript
func knows(fact: String) -> bool:
    return fact in _internal_state
```

Knowledge is local. The same fact may be known by some objects and unknown by others.

Propagate knowledge via signals.

```gdscript
func teach(fact: String, value) -> void:
    _internal_state[fact] = value
    emit_local_event("learned", {"fact": fact, "value": value})
```

When an object learns something, it broadcasts. Listeners that care can update their own state.

You can now build local-state objects that communicate by signal rather than by shared memory. Primitives_Portals will next connect two such objects through a single teleporter.

Forget a known fact.

```gdscript
func forget(fact: String) -> void:
    _internal_state.erase(fact)
    emit_local_event("forgot", {"fact": fact})
```

Forgetting is as local as learning. Other objects are notified but do not lose the fact from their own state.

Share a subset of facts with another object.

```gdscript
func share_facts_with(other: Node, facts_to_share: Array) -> void:
    var subset: Dictionary = {}
    for fact in facts_to_share:
        if fact in _internal_state:
            subset[fact] = _internal_state[fact]
    other.receive_shared_facts(subset)
```

Selective sharing. The object chooses which facts to transmit; the recipient decides whether to integrate them.
