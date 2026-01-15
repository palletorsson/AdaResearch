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

```gdscript
extends Node3D

@export var light_colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]

var lights: Array[SpotLight3D] = []
var overlap_area: MeshInstance3D

func _ready():
    setup_lights()
    setup_overlap_detector()

func setup_lights():
    for i in range(light_colors.size()):
        var light = SpotLight3D.new()
        light.light_color = light_colors[i]
        light.light_energy = 2.0
        light.spot_angle = 30.0
        # Position lights to overlap at center
        light.position = Vector3(cos(i * TAU/3) * 2, 3, sin(i * TAU/3) * 2)
        light.look_at(Vector3.ZERO)
        lights.append(light)
        add_child(light)

func _process(delta):
    # Calculate mixed color at overlap point
    var mixed = calculate_overlap_color()
    update_overlap_display(mixed)

func calculate_overlap_color() -> Color:
    # Where all three lights hit: white
    # Where two hit: secondary color
    # Actual calculation depends on light falloff
    return additive_mix(get_active_lights())
```

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

```gdscript
# Surface color = reflected wavelengths
# If light doesn't contain those wavelengths, surface appears dark

func calculate_surface_appearance(
    surface_color: Color,
    light_color: Color
) -> Color:
    # Surface can only reflect what light provides
    return Color(
        surface_color.r * light_color.r,
        surface_color.g * light_color.g,
        surface_color.b * light_color.b
    )

# Blue ball under red light:
var blue_surface = Color(0, 0, 1)
var red_light = Color(1, 0, 0)
var appearance = calculate_surface_appearance(blue_surface, red_light)
# Result: Color(0, 0, 0) - appears black!
# No blue wavelengths in red light to reflect
```

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

```gdscript
extends Node3D

@export var pillar_height: float = 3.0
@export var color_segments: int = 6

var collected_colors: Array[Color] = []

func _ready():
    create_color_segments()

func create_color_segments():
    var segment_height = pillar_height / color_segments

    for i in range(color_segments):
        var segment = MeshInstance3D.new()
        var mesh = CylinderMesh.new()
        mesh.height = segment_height
        mesh.top_radius = 0.3
        mesh.bottom_radius = 0.3
        segment.mesh = mesh

        # Each segment gets spectrum color
        var hue = float(i) / color_segments
        var color = Color.from_hsv(hue, 1.0, 1.0)

        var mat = StandardMaterial3D.new()
        mat.albedo_color = color
        mat.emission_enabled = true
        mat.emission = color
        segment.material_override = mat

        segment.position.y = i * segment_height + segment_height / 2
        add_child(segment)

func collect_segment(index: int):
    var color = Color.from_hsv(float(index) / color_segments, 1.0, 1.0)
    collected_colors.append(color)
```

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
