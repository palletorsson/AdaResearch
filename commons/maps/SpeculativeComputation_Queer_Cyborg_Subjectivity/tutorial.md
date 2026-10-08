# Assembling a cyborg body

Treat the avatar as a set of independent parameters before treating it as an identity.

```gdscript
var body_state := {
    "silhouette": "default",
    "fabric": "reflective",
    "posture": "upright",
    "interface": "open"
}

func apply_choice(key: String, value: String) -> void:
    body_state[key] = value
    mirror.render(body_state)
```

Change one key, observe the reflection, and restore it before changing another. Then compose a combination that has no preset name. The exercise is to distinguish a parameter from the category the interface gives it.

The next map, `SpeculativeComputation_Queer_Morphological_Systems`, lets a system itself become the changing body.
