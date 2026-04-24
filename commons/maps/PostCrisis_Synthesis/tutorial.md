# PostCrisis Synthesis

One plinth, one sentence, no ornament. Close the arc by compressing it.

Declare the plinth.

```gdscript
class_name SynthesisPlinth
extends Node3D

@export var sentence: String = ""
@export var font_size: int = 48
```

A single export: the sentence. The plinth is a vehicle for one line. Anything else would be a new teaching.

Compose the sentence from the arc.

```gdscript
const ARC_SENTENCE := "Knowing the limits of formalization, we build systems that hold their outside."
```

The sentence names what the sequence discovered. Not a conclusion; a practice. The learner carries it forward.

Render the sentence on the plinth.

```gdscript
func render_sentence(label: Label3D) -> void:
    label.text = ARC_SENTENCE
    label.font_size = font_size
    label.modulate = Color(1.0, 1.0, 0.95)
    label.outline_size = 4
```

Cream text, thin outline, generous kerning. The plinth is a publication, not a monument.

Place the plinth off-centre.

```gdscript
func place_plinth(pos: Vector3) -> void:
    plinth_node.position = pos
    plinth_node.rotation.y = deg_to_rad(-12.0)
```

The angle breaks the gallery axis. The sentence refuses to be the centre of the room. The learner has to walk toward it at a slight turn.

Place four empty plinths around it.

```gdscript
func place_memory_plinths(positions: Array) -> void:
    for p in positions:
        var m := preload("res://commons/maps/elements/memory_plinth.tscn").instantiate()
        m.position = p
        add_child(m)
```

Empty plinths ring the sentence. Each represents a map of the arc. The emptiness invites the learner to remember what stood on each.

Write the door threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "continue →"
    label.modulate = Color(0.9, 0.9, 0.9)
    label.font_size = 32
```

The exit does not say goodbye. It says continue. The arc is open-ended by design.

Fade the lighting toward the door.

```gdscript
func gradient_light(env: WorldEnvironment) -> void:
    var e := env.environment
    e.ambient_light_color = Color(0.7, 0.7, 0.75)
    e.ambient_light_energy = 0.4
    e.ssao_enabled = false
```

Cool, even light. No spotlight on the sentence. The gallery is a reading room, not a shrine.

Reading rooms assume the reader. The light treats the learner as already arrived. Nothing asks them to earn it.

Connect the teleporter.

```gdscript
func on_teleport_ready(t: Node3D) -> void:
    t.set_meta("destination", "next_arc_start")
    t.enable()
```

The teleporter holds a destination meta, not a hardcoded path. The next arc is a reference. The learner steps forward carrying what they have learned.

You have closed the post-foundations arc with one sentence on one plinth. Carry the question into whatever you build next.
