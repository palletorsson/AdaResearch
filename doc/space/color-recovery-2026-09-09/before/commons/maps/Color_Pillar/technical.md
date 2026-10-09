# Color_Pillar - Technical Tutorial

## Additive Color Mixing

### Light Adds to Light

```gdscript
# Additive mixing: overlapping lights combine
func additive_mix(colors: Array[Color]) -> Color:
    var result = Color.BLACK

    for color in colors:
        result.r = min(result.r + color.r, 1.0)
        result.g = min(result.g + color.g, 1.0)
        result.b = min(result.b + color.b, 1.0)

    return result

# Red + Green = Yellow (not brown like paint!)
var yellow = additive_mix([Color.RED, Color.GREEN])
# Result: Color(1, 1, 0)

# Red + Green + Blue = White
var white = additive_mix([Color.RED, Color.GREEN, Color.BLUE])
# Result: Color(1, 1, 1)
```

### Visual Color Mixing Implementation

### Flashlight Demo: Revealing Color

```gdscript
extends SpotLight3D

@export var demo_colors: Array[Color] = [
    Color.RED, Color.GREEN, Color.BLUE, Color.WHITE
]
var current_index: int = 0

func _on_trigger_pressed():
    # Cycle through colors
    current_index = (current_index + 1) % demo_colors.size()
    light_color = demo_colors[current_index]

# The flashlight shows:
# - White light reveals all surface colors
# - Red light makes red objects visible, blue objects dark
# - Object color = which wavelengths the surface reflects
```

### Why Colored Light Changes Object Appearance

### Grabbable Color Collection

```gdscript
extends XRToolsPickable

@export var collection_color: Color = Color.RED

signal color_collected(color: Color)

func _ready():
    # Visual representation
    $MeshInstance3D.material_override.albedo_color = collection_color
    $MeshInstance3D.material_override.emission = collection_color
    $MeshInstance3D.material_override.emission_energy_multiplier = 1.5

func _on_picked_up(pickable):
    emit_signal("color_collected", collection_color)

func get_color() -> Color:
    return collection_color
```

### Pillar Color Collection

### Spectrum Visualizer

```gdscript
extends Node3D

@export var bar_count: int = 32
@export var bar_height: float = 2.0
@export var bar_width: float = 0.2

func _ready():
    create_spectrum_bars()

func create_spectrum_bars():
    for i in range(bar_count):
        var bar = MeshInstance3D.new()
        var mesh = BoxMesh.new()
        mesh.size = Vector3(bar_width, bar_height, bar_width)
        bar.mesh = mesh

        # Position across X axis
        bar.position.x = i * bar_width * 1.2

        # Color from spectrum position
        var t = float(i) / bar_count
        var color = Color.from_hsv(t * 0.8, 1.0, 1.0)  # 0.8 to avoid magenta

        var mat = StandardMaterial3D.new()
        mat.albedo_color = color
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 0.5
        bar.material_override = mat

        add_child(bar)
```

## Key Takeaway

Color_Pillar teaches **additive color mixing** - how light combines. Red + Green = Yellow (surprising if you learned paint mixing). The flashlight demo reveals that object color depends on both surface properties AND illumination. Colored light can make objects appear to change color, disappear into darkness, or reveal hidden patterns.

## Implementation Notes and Complexity

The pillar artifact renders a vertical stack of coloured cylinders, each tinted by a distinct material. The stack's height maps to a palette dimension, and the pillar as a whole reads as a legible sample of the palette's gradient. Constructing the pillar requires N MeshInstance3D nodes for a stack of height N, and N material instances because each cylinder's albedo is unique. The per-instance cost is O(1); the full pillar setup is O(N).

Rendering the pillar at runtime is dominated by the draw-call count. Godot batches instances of the same mesh with the same material automatically; the pillar defeats this optimisation because every cylinder has a unique material. A pillar of height 32 produces 32 draw calls. Modern hardware handles this comfortably at 60 frames per second, but dense scenes with many pillars can become CPU-bound on draw submission. The conventional optimisation is to bake the pillar's colour variation into a single texture and render the pillar as a single cylinder with that texture, collapsing 32 draw calls to one.

The pillar's material properties extend beyond albedo. Each cylinder can carry its own metallic, roughness, and emission values, and the stack can be used as a live material sampler: a learner picks a height and the corresponding cylinder's full material assignment becomes the active paint. The sampler is not free — reading the material properties requires a node lookup — but the cost is O(1) per sample and runs at interactive rates.

Within the sequence, Color_Pillar is the vertical counterpart to the horizontal palette. The stack's height dimension gives the palette a third axis of legibility: the learner can see the whole gradient at once, from eye level down, rather than having to scan a horizontal strip. The pillar's architecture makes the palette a standing object rather than a tablet, and the embodied vertical reading is the map's small contribution to the colour vocabulary the sequence is building.
