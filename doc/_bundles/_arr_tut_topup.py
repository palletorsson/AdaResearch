import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'Tutorial_Pattern': """

Cache the texture for reuse.

```gdscript
var texture_cache: Dictionary = {}

func get_cached_texture(rule_name: String, palette: Array) -> ImageTexture:
    var key: String = rule_name + str(palette)
    if key in texture_cache:
        return texture_cache[key]
    var texture := grid_to_texture(populate_grid(Vector2i(8, 8), rules[rule_name]), palette)
    texture_cache[key] = texture
    return texture
```

Repeated renders of the same rule pull from cache. Useful for tiles that appear in many scenes.
""",
'Tutorial_Single': """

Detect the grip gesture.

```gdscript
func is_grip_pressed(controller: XRController3D) -> bool:
    return controller.get_float("grip") > 0.8
```

The grip button reports a float from 0 to 1. Threshold at 0.8 for a reliable press detection.

Add a brief haptic buzz on grab.

```gdscript
func buzz_controller(controller: XRController3D) -> void:
    controller.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
```

A short pulse confirms the grab. The parameters are frequency, amplitude, duration, and delay.

Limit the grab range.

```gdscript
const GRAB_RANGE := 0.3

func within_grab_range(controller: XRController3D, target: Node3D) -> bool:
    return controller.global_position.distance_to(target.global_position) < GRAB_RANGE
```

30 centimetres is a comfortable reach without overcommitting. Outside the range, the grab doesn't register.
""",
'Tutorial_Row': """

Smooth the pitch change.

```gdscript
var current_pitch: float = 1.0

func smooth_pitch_to(target: float, delta: float) -> void:
    current_pitch = lerp(current_pitch, target, delta * 8.0)
    sound_player.pitch_scale = current_pitch
```

Linear interpolation with factor 8 produces a quick but not instantaneous pitch shift. Crisp without being jarring.

Highlight the cell the learner is standing on.

```gdscript
func highlight_current_cell() -> void:
    var i := current_index()
    for c in get_children():
        if c.has_meta("index"):
            c.modulate = Color.YELLOW if c.get_meta("index") == i else Color.WHITE
```

The highlight moves with the learner. Colour is the visual parallel to the label's index text.
""",
}

for m, a in adds.items():
    p = Path('commons/maps/' + m + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
