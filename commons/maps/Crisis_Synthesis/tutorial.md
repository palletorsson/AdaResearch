# Crisis Synthesis

Four wings, one summit, one complete formula. Build the synthesis that turns crisis into capacity.

Declare the wing registry.

```gdscript
class_name WingRegistry
extends Node3D

const WINGS := {
    "russell": "paradox",
    "godel": "incompleteness",
    "brouwer": "construction",
    "florensky": "paraconsistency",
}
```

Four wings, four names, four words. The registry is the map key. Each wing hosts one artifact from the sequence.

Place the wings around the summit.

```gdscript
func place_wings() -> void:
    var angle := 0.0
    for key in WINGS:
        var wing := preload("res://commons/maps/elements/crisis_wing.tscn").instantiate()
        wing.position = Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
        wing.set_meta("key", key)
        add_child(wing)
        angle += TAU / WINGS.size()
```

Eight-metre radius around the summit. Equal spacing. No wing is privileged; each presents a distinct response to the crisis.

Render the summit formula.

```gdscript
func render_summit(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 80
    label.modulate = Color(1.0, 0.95, 0.8)
```

The complete formula for the first time. Earlier maps showed fragments. The summit holds the whole.

Wire the bifurcation diagram.

```gdscript
func update_bifurcation(diagram: MeshInstance3D, lambda_value: float) -> void:
    var samples: Array = []
    for i in 100:
        var x := float(i) / 100.0
        samples.append(Vector2(x, _logistic_step(lambda_value, x)))
    diagram.mesh = _mesh_from_samples(samples)
```

The bifurcation rides λ. Low λ is stable; moving λ up opens doublings and then chaos. The diagram explains the critical zones visually.

Slide λ and φ.

```gdscript
func _on_lambda_slider_moved(v: float) -> void:
    lambda_value = v
    update_bifurcation(bif_diagram, v)

func _on_phi_slider_moved(v: float) -> void:
    phi_value = lerp(-1.0, 1.0, v)
    update_wings(phi_value)
```

Each slider rewrites the summit's readout. The wings update to show what their response implies under the current parameters.

Open the wings by proximity.

```gdscript
func _on_player_near_wing(wing: Node3D) -> void:
    wing.set_meta("open", true)
    wing.play_open_animation()
```

Proximity is the trigger, not a button. Walking toward Gödel unlocks Gödel. The learner pieces the argument together at their own pace.

Mark completion on all four visits.

```gdscript
func mark_wing_visited(wing: Node3D) -> void:
    visited[wing.get_meta("key")] = true
    if visited.size() == WINGS.size():
        summit_light.light_energy = 4.0
```

All four wings must be visited before the summit lights fully. The formula only reads complete after every response to the crisis has been witnessed.

You have assembled the crisis into capacity. The next map, Chamber Foundations, embodies Gödel as a creature you cannot distinguish from itself.
<<</MAP>>>

Animate the summit light on full completion.

```gdscript
func animate_summit() -> void:
    var t := Time.get_ticks_msec() / 1000.0
    summit_light.light_energy = 3.0 + sin(t * 0.8) * 0.8
    summit_light.light_color = Color(1.0, 0.9, 0.7)
```

A gentle pulse once the four wings are visited. The pulse is slow enough to read as breath.
