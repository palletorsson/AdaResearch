# Russell Paradox

The set of all sets that don't contain themselves. Build two boxes and the third box that breaks both.

Declare a set container.

```gdscript
class_name SetBox
extends Node3D

@export var members: Array[String] = []

func contains_self() -> bool:
    return members.has(label)
```

A box holds named members. `contains_self` checks whether the box's own label is in its own member list. Recursion as a property.

Populate two example boxes.

```gdscript
func populate() -> void:
    even_box.members = ["2", "4", "6"]
    boxes_box.members = ["box1", "box2", "boxes_box"]
```

The even-number box does not contain itself. The box-of-boxes does. Two clean examples before the paradox.

Build Russell's set.

```gdscript
func collect_non_self_containing(all_sets: Array[SetBox]) -> Array[String]:
    var out: Array[String] = []
    for s in all_sets:
        if not s.contains_self():
            out.append(s.label)
    return out
```

The filter returns all boxes that do not contain themselves. This list is the rule for the third box.

Create the paradox box.

```gdscript
func build_russell_box(all_sets: Array[SetBox]) -> void:
    russell.members = collect_non_self_containing(all_sets)
    russell.label = "russell"
```

Russell's box collects every non-self-containing box. Then ask whether it belongs to itself.

Check membership.

```gdscript
func russell_paradox() -> String:
    var in_self := russell.members.has("russell")
    if in_self:
        return "russell is in russell → russell must NOT contain itself"
    else:
        return "russell is not in russell → russell MUST contain itself"
```

Either answer produces the opposite requirement. The function returns the two halves of the paradox as a sentence.

Render the paradox as a spinning box.

```gdscript
func _process(dt: float) -> void:
    russell_mesh.rotation.y += dt * 0.6
    var t := sin(Time.get_ticks_msec() / 500.0)
    russell_mesh.scale = Vector3.ONE * (1.0 + 0.1 * t)
```

The box pulses because it cannot resolve. Its geometry is a visual restlessness.

Alarm when the learner opens the box.

```gdscript
func _on_russell_opened() -> void:
    alarm_sound.play()
    alarm_light.visible = true
    readout.text = russell_paradox()
```

The alarm is not playful. Naive set theory is broken at the foundation. The readout says so in full.

You have met the first genuine contradiction. The next map, Gödel Incompleteness, encodes logic in numbers and finds the limit even careful systems share.
<<</MAP>>>

Count the members of each box on a readout.

```gdscript
func readout_counts(panel: Label3D) -> void:
    panel.text = "even: %d
boxes: %d
russell: %d" % [
        even_box.members.size(),
        boxes_box.members.size(),
        russell.members.size(),
    ]
```

The counts let the learner compare sizes at a glance. Russell's count shifts whenever a non-self-containing set is added elsewhere in the room.

Disable inference when Russell is opened.

```gdscript
func disable_inference() -> void:
    classical_engine.enabled = false
    inference_lamp.light_energy = 0.0
```

Classical inference halts. The lamp darkens. The room makes the failure of the system visible.

Offer a restart.

```gdscript
func _on_reset_pressed() -> void:
    russell.members.clear()
    alarm_light.visible = false
    classical_engine.enabled = true
```

Reset clears the paradox and re-enables inference. The learner can rebuild from scratch. The sequence continues.
