# Synthesis

The formula understood, not just intellectually but felt. Build the closing room where all four terms return as bodies.

Declare the synthesis plinth.

```gdscript
class_name SynthesisPlinth
extends Node3D

@export var terms: Array[Node3D] = []
@export var creature_path: NodePath
```

One plinth, four term bodies, one queer-morphology specimen. The plinth is the altar; the specimen is the living thesis.

Place the term bodies.

```gdscript
func place_terms() -> void:
    var angles := [0.0, 90.0, 180.0, 270.0]
    for i in terms.size():
        var a := deg_to_rad(angles[i])
        terms[i].position = Vector3(cos(a) * 1.2, 0.0, sin(a) * 1.2)
```

Four terms arranged at the corners of a square around the plinth. The learner walks between them reading. The arrangement invites pacing.

Render the formula line.

```gdscript
func show_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 72
    label.modulate = Color(1.0, 1.0, 0.95)
```

The formula hangs above the plinth as it did in the Introduction. What returns is not the same; the learner now carries the terms.

Animate the queer-morphology specimen.

```gdscript
func _process(dt: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    specimen.blend_shapes = Vector3(sin(t), cos(t * 0.7), sin(t * 1.3))
    specimen.scale = Vector3.ONE * (0.9 + 0.05 * sin(t * 0.5))
```

Breath-like blend shapes on the specimen. The morphology is never still. φ>0 made flesh.

Light the terms in sequence.

```gdscript
func sequence_lights() -> void:
    for i in terms.size():
        await get_tree().create_timer(0.5).timeout
        terms[i].emission = 1.5
        await get_tree().create_timer(0.3).timeout
        terms[i].emission = 0.5
```

A quiet choreography invites the learner to attend to each term in turn. The sequence runs once on entry and again on command.

Offer a personal phi signature.

```gdscript
func record_phi_signature(v: float) -> void:
    var signature := {"phi": v, "time": Time.get_unix_time_from_system()}
    UserSettings.set_value("qfep/phi_signature", signature)
```

The learner's chosen φ is saved as a signature. Future maps can read it. The force is not just understood; it becomes identity.

Write the threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "carry it forward →"
    label.modulate = Color(0.9, 0.9, 0.9)
```

The exit sign is a charge, not a farewell. The learner leaves the laboratory with QFEP as a force they own.

You have completed the QFEP Laboratory. The final map, Chamber QFEP, gathers every befriended creature and every catalyst mode into one room.
<<</MAP>>>
