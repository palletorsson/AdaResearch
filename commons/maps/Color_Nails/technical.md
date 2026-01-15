# Color_Nails - Technical Tutorial

## Color Selection Systems

### The Color Class in Godot

```gdscript
# Color is stored as RGBA (Red, Green, Blue, Alpha)
var color = Color(0.8, 0.3, 0.5, 1.0)

# Access individual channels
var red = color.r      # 0.0 to 1.0
var green = color.g
var blue = color.b
var alpha = color.a    # Transparency

# Alternative constructors
var from_html = Color.html("#FF5733")
var from_hsv = Color.from_hsv(0.5, 0.8, 1.0)  # Hue, Saturation, Value
```

### RGB: Three Numbers, Millions of Colors

```gdscript
# Every pixel stores three values
var red_intensity = 0.8    # How much red light (0.0 to 1.0)
var green_intensity = 0.3  # How much green light
var blue_intensity = 0.1   # How much blue light

var color = Color(red_intensity, green_intensity, blue_intensity)

# Three numbers create millions of perceived hues
# But the screen only emits three wavelengths
# The rest is perceptual construction
```

### Nail Color Controller Implementation

```gdscript
extends Node3D

signal color_selected(color: Color)

@export var current_color: Color = Color.WHITE

var hue_slider: float = 0.0
var saturation_slider: float = 1.0
var value_slider: float = 1.0

func _on_hue_changed(value: float):
    hue_slider = value
    update_color()

func _on_saturation_changed(value: float):
    saturation_slider = value
    update_color()

func update_color():
    current_color = Color.from_hsv(hue_slider, saturation_slider, value_slider)
    emit_signal("color_selected", current_color)
    update_preview()

func update_preview():
    $PreviewMesh.material_override.albedo_color = current_color
```

### HSV vs RGB Color Models

```gdscript
# RGB - additive primaries (how screens work)
var rgb_red = Color(1, 0, 0)
var rgb_yellow = Color(1, 1, 0)  # Red + Green = Yellow

# HSV - perceptual model (how we think about color)
# Hue: 0.0-1.0 = color wheel position (red→yellow→green→cyan→blue→magenta)
# Saturation: 0.0 = gray, 1.0 = vivid
# Value: 0.0 = black, 1.0 = bright

var hsv_red = Color.from_hsv(0.0, 1.0, 1.0)      # Hue 0 = red
var hsv_yellow = Color.from_hsv(0.167, 1.0, 1.0) # Hue 1/6 = yellow
var hsv_gray = Color.from_hsv(0.0, 0.0, 0.5)     # Any hue, zero saturation

# HSV is more intuitive for color selection
# "Make it more blue" = increase hue toward 0.67
# "Make it less saturated" = decrease S
```

### Applying Color to Materials

```gdscript
# The hand model receives color from controller
extends MeshInstance3D

func apply_nail_color(color: Color):
    # Create unique material instance
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color

    # Optional: add glossy nail effect
    mat.metallic = 0.3
    mat.roughness = 0.2
    mat.clearcoat = 1.0
    mat.clearcoat_roughness = 0.1

    material_override = mat
```

### Color Balls as Grabbable Samples

```gdscript
extends RigidBody3D

@export var sample_color: Color = Color.RED

func _ready():
    # Set visual color
    $MeshInstance3D.material_override.albedo_color = sample_color

func get_color() -> Color:
    return sample_color

# When grabbed and used with scanner
func _on_scanned():
    # Return this ball's color to the scanning system
    return sample_color
```

### The Grab Stick Scanner

```gdscript
extends XRToolsPickable

signal color_sampled(color: Color)

func sample_color_from(target: Node3D):
    if target.has_method("get_color"):
        var sampled = target.get_color()
        emit_signal("color_sampled", sampled)
    elif target is MeshInstance3D:
        # Sample from material
        var mat = target.get_active_material(0)
        if mat is StandardMaterial3D:
            emit_signal("color_sampled", mat.albedo_color)
```

### Color Interpolation

```gdscript
# Smooth color transitions
func blend_colors(from: Color, to: Color, t: float) -> Color:
    return from.lerp(to, t)

# Animated color change
var target_color: Color
var current_color: Color
var blend_speed: float = 2.0

func _process(delta):
    current_color = current_color.lerp(target_color, delta * blend_speed)
    apply_color(current_color)
```

## Key Takeaway

Color selection interfaces translate between **perceptual models** (HSV - how we think about color) and **computational models** (RGB - how screens display color). The nail salon metaphor makes color personal: not just a property to observe, but a choice to wear. Three sliders control millions of possible hues - the dimensionality of color compressed into simple interaction.
