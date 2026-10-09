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


<!-- study-spine:sentence_authority -->

## Return: Permission at three scales

Change one sentence once; follow the same words across label, strip and wall. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, array, inscription, limit. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`sentence`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:sentence_authority -->

### One source change: Permission at three scales

Replace this first entry in SENTENCES with your own short sentence. All three displays read the same array entry. Compare WORD / WHOLE and PACE while keeping that entry fixed. The loop and string array are the learner’s tools; font geometry and pointer fabrication are supplied. Keep the sentence short enough to fit and test all displays.

```gdscript
"YOU MAY REMAIN HERE"
```

Source: `commons/artifacts/spine_studies/sentence_authority.gd`. Use the prepared scene to run and compare.

<!-- study-reference:sentence_authority -->

### Reference and scope

Holzer circulated statements in different public formats. The installation uses original Ada sentences; changing their scale or rhythm does not establish their truth and is not an illustration of an incompleteness proof.

[MoMA: Jenny Holzer, Truisms](https://www.moma.org/collection/works/63755).
