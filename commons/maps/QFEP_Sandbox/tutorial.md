# Sandbox

No more guided tours. Every slider unlocked. Build the reactor that responds to whatever combination the learner invents.

Declare the reactor state.

```gdscript
class_name QFEPReactor
extends Node3D

@export var lambda_value: float = 0.4
@export var phi_value: float = 0.6
@export var f_weight: float = 1.0
@export var e_weight: float = 1.0
```

Four exports, all live. No hidden defaults. The reactor reads every parameter from its own properties each frame.

Wire sliders to the reactor.

```gdscript
func _on_lambda_slider_moved(v: float) -> void:
    reactor.lambda_value = v

func _on_phi_slider_moved(v: float) -> void:
    reactor.phi_value = lerp(-1.0, 1.0, v)
```

Two sliders, two writes. No validation gating. If the learner sets λ=1.0 and φ=-1.0, the world becomes a dark dissolution and teaches that setting exists.

Compute QFE from the live state.

```gdscript
func compute_qfe(prev_energy: float, energy: float, dt: float) -> float:
    var f := f_weight
    var e := e_weight * entropy_proxy()
    var delta_e := (energy - prev_energy) / max(dt, 0.0001)
    return f - lambda_value * e + phi_value * delta_e
```

The full formula runs inside the reactor loop. Every slider move changes the result. The display shows QFE as a number alongside its visual effect.

Display the number.

```gdscript
func update_readout() -> void:
    qfe_label.text = "QFE = %+.3f" % current_qfe
    qfe_label.modulate = Color(1.0, 0.6, 0.6) if current_qfe < 0.0 else Color(0.6, 1.0, 0.6)
```

Red for negative, green for positive. No moral valence; just a colour for sign. The learner sees their parameter choices as a scalar.

Translate QFE to world behaviour.

```gdscript
func apply_qfe(qfe: float) -> void:
    world_speed = clamp(0.5 + qfe * 0.5, 0.1, 3.0)
    particle_count_target = int(clamp(200 + qfe * 300, 30, 800))
```

Higher QFE means a livelier world. Lower means a quieter one. The mapping is intentionally simple so the learner can hear their own choices.

Reset to a known state.

```gdscript
func _on_reset_pressed() -> void:
    reactor.lambda_value = 0.4
    reactor.phi_value = 0.6
    reactor.f_weight = 1.0
    reactor.e_weight = 1.0
```

A reset button returns the reactor to the edge default. The learner can always come back. Experimentation is framed as safe.

Log each exploration.

```gdscript
func snapshot() -> void:
    sessions.append({
        "lambda": reactor.lambda_value,
        "phi": reactor.phi_value,
        "qfe": reactor.current_qfe,
        "time": Time.get_ticks_msec(),
    })
```

A snapshot records the live state. The learner leaves a trail of tested combinations. The trail is the curriculum now.

You have taken the force of QFEP. The next map, Synthesis, gathers the arc and hands the formula back as a tool.
<<</MAP>>>
