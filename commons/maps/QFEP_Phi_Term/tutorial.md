# Phi Term

φ is the attitude toward change. Negative φ resists; positive φ welcomes. Build a room where your φ choice reshapes what the world lets you do.

Declare the phi dial.

```gdscript
class_name PhiDial
extends Node3D

signal phi_changed(value: float)

@export var value: float = 0.0

func set_value(v: float) -> void:
    value = clamp(v, -1.0, 1.0)
    phi_changed.emit(value)
```

One exported value, clamped to [-1, 1]. Negative resists, zero is neutral, positive welcomes. The signal is how the world hears it.

Grab the dial.

```gdscript
func _on_dial_grabbed(offset: float) -> void:
    set_value(value + offset * turn_gain)
    dial_label.text = "φ = %+.2f" % value
```

The learner turns a physical dial. Each degree updates φ. The label shows the sign explicitly because the sign is the lesson.

Apply φ to a morphing object.

```gdscript
func _on_phi_changed(v: float) -> void:
    morph_target.blend_shapes = _shape_for(v)
    morph_target.metallic = 0.3 + 0.5 * clamp(v, 0.0, 1.0)
```

The object becomes smoother and more iridescent as φ rises. Negative φ hardens it. Zero holds a neutral pose.

Let the rate of change matter.

```gdscript
func delta_energy(prev_state: float, state: float, dt: float) -> float:
    return (state - prev_state) / max(dt, 0.0001)
```

ΔE/Δt is the instantaneous rate. φ multiplies this rate. The formula's third term is a response to motion, not to position.

Accumulate the φ·ΔE contribution.

```gdscript
func phi_contribution(v: float, prev: float, state: float, dt: float) -> float:
    return v * delta_energy(prev, state, dt)
```

Positive φ amplifies fast change into reward. Negative φ amplifies it into penalty. The same rate becomes two very different forces depending on sign.

Paint the room's floor by φ sign.

```gdscript
func tint_floor(v: float) -> void:
    var mat: StandardMaterial3D = floor_mesh.material_override
    if v < 0.0:
        mat.albedo_color = Color(0.3, 0.2, 0.2)
    else:
        mat.albedo_color = Color(0.2, 0.3, 0.4)
```

Burgundy floor for preservation; cool blue for becoming. The room changes under the learner's feet with the dial.

Display the political reading.

```gdscript
func update_reading(v: float) -> void:
    if v < -0.2: reading.text = "conservative"
    elif v > 0.2: reading.text = "queer"
    else: reading.text = "neutral"
```

The reading names φ without euphemism. The formula is a politics; the dial lets the learner declare one.

You have built the attitude term. The next map, Edge Of Chaos, zooms into where φ-positive systems find their most productive balance.
<<</MAP>>>

Lock the dial if the learner requests it.

```gdscript
func lock_dial(locked: bool) -> void:
    dial.can_turn = not locked
    dial_lock_label.text = "locked" if locked else ""
```

Locking preserves a chosen φ while the learner explores. The dial stays readable but stops accepting input.
