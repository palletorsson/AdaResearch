# Force as Place

A chasm, a machine, a dial. The vector you set becomes a region of the world — force stops being an event and becomes an address.

The vector machine exposes a field's components as controls:

```gdscript
# vector_machine.gd — three sliders in, one field out
@export var zone: Area3D          # the force_field_zone over the void

func _on_slider_x(v: float) -> void: zone.field_force.x = v
func _on_slider_y(v: float) -> void: zone.field_force.y = v
func _on_slider_z(v: float) -> void: zone.field_force.z = v
```

Dial, then test with a thrown cube. The cube is your probe — it enters with whatever velocity your arm gave it, and the zone integrates from there:

```gdscript
# inside the zone, each physics tick:
# v += (field_force) * dt          (per unit mass)
# p += v * dt
```

Predicting the landing is projectile math with an edited gravity. Inside the zone the effective acceleration is `g_eff = Vector3(0, -9.8, 0) + field_force`; the cube's arc is a parabola bent around *that* instead:

```gdscript
func predict_arc(p0: Vector3, v0: Vector3, g_eff: Vector3, steps: int = 60) -> Array[Vector3]:
    var pts: Array[Vector3] = []
    var p := p0; var v := v0
    for i in steps:
        v += g_eff * 0.05
        p += v * 0.05
        pts.append(p)
    return pts
```

Draw the prediction as a dotted line from the machine and the tuning loop closes: dial, watch the ghost arc bend, throw, compare. When the ghost kisses the far ledge, commit your own body to the same field.

The map's title is its thesis, and it is worth saying in code terms: the vector is not attached to any object. It is attached to a *volume*. Whatever enters — cube, player, anything with mass — is grammatically the same to the field:

```gdscript
for b in bodies_inside:
    b.apply_central_force(field_force * b.mass)   # no if-statements about who you are
```

Try: find the dial setting where a thrown cube lands back in your hand — a field that curves flight into a boomerang. Then note there was no boomerang code anywhere. The return was a property of the *place*, and you tuned the place. That is the chapter's parting idea, and the QFEP lab will spend eight rooms on its consequences.
