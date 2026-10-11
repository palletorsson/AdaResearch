# Russell Paradox

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed workbench tests IN and OUT against the unrestricted demand, then against a finite domain. Its lesson controls are enabled and it starts at cell 5. The box sketch below needs declared labels, nodes and event connections; it does not construct an unrestricted Russell set.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Membership predicates
- Finite domains
- Self reference
- Restricted construction

Inspect a finite membership filter, then distinguish it from the unrestricted demand tested by the installed workbench.

Declare a set container.

```gdscript
class_name SetBox
extends Node3D

@export var members: Array[String] = []

func contains_self() -> bool:
    return members.has(label)
```

A box holds named members. `contains_self` checks whether the box's own label is in its own member list. A self-label in data is not a recursive function call.

Populate two example boxes.

```gdscript
func populate() -> void:
    even_box.members = ["2", "4", "6"]
    boxes_box.members = ["box1", "box2", "boxes_box"]
```

The even-number box does not contain itself. The box-of-boxes does. Two clean examples before the paradox.

Filter a supplied finite collection.

```gdscript
func collect_non_self_containing(all_sets: Array[SetBox]) -> Array[String]:
    var out: Array[String] = []
    for s in all_sets:
        if not s.contains_self():
            out.append(s.label)
    return out
```

The filter returns labels from the supplied all_sets array at that moment. Its finite domain and the time of evaluation matter.

Store the snapshot in another box.

```gdscript
func build_russell_box(all_sets: Array[SetBox]) -> void:
    russell.members = collect_non_self_containing(all_sets)
    russell.label = "russell"
```

The result contains labels selected from the supplied domain. Storing it does not make it satisfy unrestricted comprehension or update it when its inputs change.

Check membership.

```gdscript
func russell_paradox() -> String:
    var in_self := russell.members.has("russell")
    if in_self:
        return "russell is in russell → russell must NOT contain itself"
    else:
        return "russell is not in russell → russell MUST contain itself"
```

These strings state the two consequences of the unrestricted demand. They do not prove that the finite snapshot just constructed satisfies that demand.

Render the paradox as a spinning box.

```gdscript
func _process(dt: float) -> void:
    russell_mesh.rotation.y += dt * 0.6
    var t := sin(Time.get_ticks_msec() / 500.0)
    russell_mesh.scale = Vector3.ONE * (1.0 + 0.1 * t)
```

The box pulses because _process changes its scale with a sine. The animation illustrates restlessness; no logical contradiction forces it to move.

Alarm when the learner opens the box.

```gdscript
func _on_russell_opened() -> void:
    alarm_sound.play()
    alarm_light.visible = true
    readout.text = russell_paradox()
```

This proposed opening handler triggers an alarm and a text display. The membership argument, not the alarm, identifies the inconsistent unrestricted assumption.

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

The counts report stored array lengths when this function is called. No automatic recollection or change listener is supplied here.

Disable inference when Russell is opened.

```gdscript
func disable_inference() -> void:
    classical_engine.enabled = false
    inference_lamp.light_energy = 0.0
```

This disables a proposed node named classical_engine. No inference engine is defined here; switching a property is not a logical derivation.

Offer a restart.

```gdscript
func _on_reset_pressed() -> void:
    russell.members.clear()
    alarm_light.visible = false
    classical_engine.enabled = true
```

Reset clears the stored array and changes two supplied-node properties. It does not repair the unrestricted definition. The replacement lesson must test both Boolean assumptions and then show what restricting the domain changes.
