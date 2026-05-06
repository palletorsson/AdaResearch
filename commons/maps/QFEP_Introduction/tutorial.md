# QFEP Introduction

The formula arrives as four grabbable spheres on a plinth. Pick them up, read their names, feel the weights.

Declare a term sphere.

```gdscript
class_name TermSphere
extends RigidBody3D

@export var symbol: String = "F"
@export var description: String = ""
@export var base_color: Color = Color.WHITE
```

Each sphere is a RigidBody3D that carries a symbol and a description. The formula is a bag of four such spheres. Physics treats them as objects; the learner treats them as ideas.

Instantiate the four terms.

```gdscript
func build_formula(parent: Node3D) -> void:
    _add_term(parent, "F", "free energy", Color(0.9, 0.7, 0.3))
    _add_term(parent, "E", "entropy", Color(0.3, 0.6, 0.9))
    _add_term(parent, "λ", "order-chaos mix", Color(0.8, 0.4, 0.7))
    _add_term(parent, "φ", "rate sensitivity", Color(0.5, 0.9, 0.5))
```

Warm gold for F. Cool blue for E. Magenta for λ.

Green for φ. The colour key stays stable across every map in the sequence.

Lay the spheres on a plinth.

```gdscript
func _add_term(parent: Node3D, sym: String, desc: String, col: Color) -> void:
    var sphere := preload("res://commons/artifacts/qfep/term_sphere.tscn").instantiate()
    sphere.symbol = sym
    sphere.description = desc
    sphere.base_color = col
    parent.add_child(sphere)
```

The helper loads the prefab and configures it from the scene. Changing term data means changing exports, not rewriting the artifact.

Render the symbol on the sphere.

```gdscript
func render_label(label: Label3D) -> void:
    label.text = symbol
    label.modulate = base_color
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
```

Billboarded labels stay readable at every angle. The sphere is both a body and a sign.

Speak the description when grabbed.

```gdscript
func _on_grabbed(_hand: Node) -> void:
    var panel: Label3D = get_tree().get_first_node_in_group("term_readout")
    panel.text = "%s — %s" % [symbol, description]
```

Grabbing a sphere publishes its meaning to a shared panel. The learner reads by touching. The formula becomes a conversation with the body.

Display the assembled formula.

```gdscript
func show_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 64
    label.modulate = Color(1.0, 1.0, 0.95)
```

The full line hangs above the plinth. Learners see the whole before the parts. Later maps will isolate each term.

You have met the formula. The next map, F Term, zooms into free energy and the trap of pure order.
<<</MAP>>>

Colour-key the readout panel.

```gdscript
func colorize_panel(panel: Label3D, sym: String) -> void:
    match sym:
        "F": panel.modulate = Color(0.9, 0.7, 0.3)
        "E": panel.modulate = Color(0.3, 0.6, 0.9)
        "λ": panel.modulate = Color(0.8, 0.4, 0.7)
        "φ": panel.modulate = Color(0.5, 0.9, 0.5)
```

The panel tints to match the sphere the learner just grabbed. Name and colour arrive together.
