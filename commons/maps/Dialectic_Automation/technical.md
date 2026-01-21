# Dialectic Automation - Technical Notes

## The criticalinfo Utility

### Syntax
```
criticalinfo:<dialectic_name>:<rotation>:<scale>
```

### Parameters
- `dialectic_name`: References JSON file in `commons/infoboards_3d/content/dialectic/`
- `rotation`: Y-axis rotation in degrees (default: 0)
- `scale`: Panel scale factor (default: 1.0)

### Example Usage
```json
"interactables": [
    ["criticalinfo:automation_dialectic:0:0.8", " ", " "]
]
```

## Dialectic JSON Structure

Located at: `res://commons/infoboards_3d/content/dialectic/automation_dialectic.json`

```gdscript
# Loading dialectic content
var dialectic_path = "res://commons/infoboards_3d/content/dialectic/%s.json" % dialectic_name
var file = FileAccess.open(dialectic_path, FileAccess.READ)
var json = JSON.parse_string(file.get_as_text())

# Layout parameters
var z_spacing = json._meta.layout.z_spacing  # Distance between levels
var x_spacing = json._meta.layout.x_spacing  # Distance between branches
var panel_scale = json._meta.layout.panel_scale

# Iterating through levels
for level_data in json.levels:
    var z_pos = level_data.level * z_spacing

    for panel in level_data.panels:
        var x_pos = panel.x * x_spacing
        var position = Vector3(x_pos, 0, z_pos)

        spawn_panel(panel, position)
```

## Panel Generation

```gdscript
func spawn_panel(panel_data: Dictionary, position: Vector3):
    var panel = info_board_template.instantiate()
    panel.position = position

    # Set content
    panel.set_title(panel_data.title)
    panel.set_position_text(panel_data.position)
    panel.set_narrative(panel_data.narrative)

    if panel_data.has("code"):
        panel.set_code(panel_data.code.block, panel_data.code.language)

    if panel_data.has("qfep"):
        panel.set_qfep(panel_data.qfep.term, panel_data.qfep.description)

    if panel_data.has("transition") and panel_data.transition != null:
        panel.set_transition(panel_data.transition)

    add_child(panel)
```

## Panel Layout Calculation

```gdscript
# For a 9-level dialectic with z_spacing=3.0:
# Level 0: z=0
# Level 1: z=3
# Level 2: z=6
# ...
# Level 8: z=24

# Total depth needed: 8 * 3 + buffer = ~27 units
# Map depth of 30 provides margin for spawn and exit
```

## Theme Colors (for panel styling)

```gdscript
const THEME_COLORS = {
    "thesis": Color(0.8, 0.2, 0.2),      # Red
    "counter": Color(0.2, 0.4, 0.8),     # Blue
    "critique": Color(0.8, 0.7, 0.2),    # Yellow
    "pragmatic": Color(0.2, 0.7, 0.3),   # Green
    "reality_check": Color(0.9, 0.5, 0.2), # Orange
    "hacker_response": Color(0.2, 0.8, 0.8), # Cyan
    "limit": Color(0.8, 0.4, 0.2),       # Dark orange
    "collective": Color(0.3, 0.8, 0.7),  # Teal
    "recursion": Color(0.6, 0.3, 0.8)    # Purple
}
```

## Integration with GridInteractablesComponent

The `criticalinfo:` prefix needs to be handled similarly to other artifacts:

```gdscript
# In GridInteractablesComponent._spawn_interactable()
if artifact_name.begins_with("criticalinfo:"):
    var parts = artifact_name.split(":")
    var dialectic_name = parts[1]
    var rotation = float(parts[2]) if parts.size() > 2 else 0.0
    var scale = float(parts[3]) if parts.size() > 3 else 1.0

    _spawn_dialectic_panels(dialectic_name, grid_position, rotation, scale)
    return
```

## BBCode Support for Panel Text

Panels should support BBCode for formatting:

```gdscript
# In panel display
var formatted_text = """
[b]%s[/b]

[i]%s[/i]

%s

[code]%s[/code]

[color=cyan]QFEP: %s[/color]
%s
""" % [title, position, narrative_joined, code_block, qfep_term, qfep_description]

rich_text_label.bbcode_text = formatted_text
```
