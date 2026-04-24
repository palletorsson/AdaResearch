# Chamber QFEP

All modes, all creatures, one room. Build the culminating chamber where befriending has already happened and recognition is the whole gesture.

Declare the chamber manifest.

```gdscript
class_name ChamberManifest
extends Resource

@export var creatures: PackedStringArray = PackedStringArray()
@export var catalyst_modes: PackedStringArray = PackedStringArray()
```

The manifest lists every creature and mode the arc befriended. The chamber reads the manifest to populate itself.

Load each befriended creature.

```gdscript
func spawn_creatures(parent: Node3D) -> void:
    for name in manifest.creatures:
        var path := "res://commons/creatures/%s.tscn" % name
        if ResourceLoader.exists(path):
            var c := load(path).instantiate()
            c.friendly = true
            parent.add_child(c)
```

Every creature arrives marked friendly. The friendly flag suppresses hostile behaviour trees. The creatures wander, not hunt.

Place them in a gathered ring.

```gdscript
func arrange_ring(nodes: Array[Node3D], radius: float) -> void:
    var n := nodes.size()
    for i in n:
        var a := TAU * i / n
        nodes[i].position = Vector3(cos(a) * radius, 0.0, sin(a) * radius)
```

Creatures occupy positions around a shared centre. The centre is where the formula lives. Arrangement is the argument: no one creature is at the head of the room.

Unlock every catalyst mode.

```gdscript
func unlock_all_modes() -> void:
    for mode in manifest.catalyst_modes:
        CatalystBracelet.enable_mode(mode)
    CatalystBracelet.current_mode = ""
```

All modes enabled, none selected. The bracelet rotates freely. The chamber does not ask for a choice; it offers the whole palette.

Write the full formula on the central plinth.

```gdscript
func render_central_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 96
    label.modulate = Color(1.0, 0.95, 0.8)
```

A larger font than any earlier map. The formula is a monument here. The learner arrives knowing what it means.

Listen for greetings from the creatures.

```gdscript
func _on_creature_greeted(creature: Node3D) -> void:
    greetings_log.append(creature.name)
    if greetings_log.size() == manifest.creatures.size():
        open_final_door()
```

Each creature greets once. When every greeting is logged, the final door opens. Completion is recognition accumulated, not performance.

Dim the lights to memory.

```gdscript
func lower_lights() -> void:
    var env := world_environment.environment
    env.ambient_light_energy = 0.25
    env.fog_enabled = true
    env.fog_light_color = Color(0.5, 0.4, 0.6)
```

Warm violet fog replaces bright lab lighting. The laboratory has become a garden. The atmosphere is how memory feels.

Sound the arc closure.

```gdscript
func play_closing_tone() -> void:
    audio.stream = closing_drone
    audio.volume_db = -6.0
    audio.play()
```

A quiet drone marks the end of the formal arc. No fanfare. The chamber trusts the learner to notice what has ended.

You have closed the QFEP Laboratory arc. The next sequences ask what you do with this force once you have it.
<<</MAP>>>
