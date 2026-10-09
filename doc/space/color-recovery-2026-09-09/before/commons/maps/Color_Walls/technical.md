# Color_Gradiant - Technical Tutorial

## Continuous Color Gradients

### Linear Interpolation Along Path

```gdscript
# Color changes smoothly based on position in hallway
extends Node3D

@export var hallway_length: float = 20.0
@export var start_color: Color = Color.RED
@export var end_color: Color = Color.MAGENTA

func get_color_at_position(z_position: float) -> Color:
    # Normalize position to 0-1
    var t = clamp(z_position / hallway_length, 0.0, 1.0)

    # Linear interpolation
    return start_color.lerp(end_color, t)

# For full spectrum, interpolate through HSV
func get_spectrum_color_at_position(z_position: float) -> Color:
    var t = clamp(z_position / hallway_length, 0.0, 1.0)

    # t maps to hue (0 = red, 0.33 = green, 0.67 = blue)
    return Color.from_hsv(t * 0.8, 1.0, 1.0)  # 0.8 to avoid magenta loop
```

### Rainbow Hallway Shader

### Emissive Gradient Walls

```gdscript
extends MeshInstance3D

func create_gradient_material():
    var mat = ShaderMaterial.new()
    mat.shader = preload("res://shaders/rainbow_gradient.gdshader")
    mat.set_shader_parameter("hallway_length", 20.0)
    mat.set_shader_parameter("saturation", 1.0)
    mat.set_shader_parameter("value", 1.0)
    material_override = mat
```

### Multi-Stop Gradient

### The Gradient Class (Godot Resource)

```gdscript
# Godot provides a Gradient resource for this
var gradient = Gradient.new()

func setup_rainbow_gradient():
    gradient.colors = PackedColorArray([
        Color.RED,
        Color.ORANGE,
        Color.YELLOW,
        Color.GREEN,
        Color.CYAN,
        Color.BLUE,
        Color.PURPLE
    ])

    # Automatic even spacing, or custom offsets
    gradient.offsets = PackedFloat32Array([
        0.0, 0.167, 0.333, 0.5, 0.667, 0.833, 1.0
    ])

func sample_gradient(t: float) -> Color:
    return gradient.sample(t)
```

### Dynamic Lighting Gradient

### Perceptual vs. Linear Interpolation

```gdscript
# Linear RGB interpolation can produce unexpected results
var red = Color(1, 0, 0)
var cyan = Color(0, 1, 1)
var midpoint_rgb = red.lerp(cyan, 0.5)
# Result: (0.5, 0.5, 0.5) - gray!

# HSV interpolation preserves saturation
func hsv_lerp(a: Color, b: Color, t: float) -> Color:
    var h_a = a.h
    var h_b = b.h
    var s_a = a.s
    var s_b = b.s
    var v_a = a.v
    var v_b = b.v

    # Handle hue wrap-around
    if abs(h_b - h_a) > 0.5:
        if h_a < h_b:
            h_a += 1.0
        else:
            h_b += 1.0

    var h = lerp(h_a, h_b, t)
    var s = lerp(s_a, s_b, t)
    var v = lerp(v_a, v_b, t)

    return Color.from_hsv(fmod(h, 1.0), s, v)
```

## Key Takeaway

The gradient hallway reveals that **color is continuous**. The discrete color names (red, orange, yellow) are arbitrary divisions imposed on smooth transition. By walking through unbroken chromatic change, you experience the spectrum as it actually is: a seamless flow where one hue becomes another without boundary. The categories we use to name colors are linguistic convenience, not perceptual reality.

## Implementation Notes and Complexity

The wall artifacts are flat panels with an albedo set per instance. Rendering a wall is a single draw call per unique material; walls sharing a material are batched automatically by Godot's renderer. A gallery of N walls with N unique colours produces N draw calls, and the cost scales linearly with the wall count until GPU-side batching limits are reached.

The wall's reflective properties are controlled by the material's roughness and metallic parameters. A roughness of 0 produces a mirror; a roughness of 1 produces a matte diffuse surface. Between these extremes, the wall reflects with a Gaussian specular lobe whose width is controlled by the roughness value. Real-time reflection on arbitrary geometry requires either a reflection probe (a cubemap captured from a representative point in the scene) or a screen-space approximation. Godot's default pipeline uses both: a scene-wide probe for coarse reflections and screen-space reflections for fine detail when the ray stays on-screen.

Lighting interacts with colour in ways that are easy to get wrong. A red wall under blue light appears dark because the red pigment absorbs blue wavelengths. The naive multiplication of light colour by material albedo produces this correctly. Lighting shaders that use summed colour components instead of multiplied ones produce unrealistic results where a red wall glows under blue light. Godot's physically-based shader uses the multiplicative convention by default.

Within the sequence, Color_Walls makes colour architectural. The walls are not just tinted backdrops; they are first-class artifacts whose albedo, roughness, and metallic properties interact with the scene's lighting to produce a room with a specific character. The map argues that colour is not a property of objects in isolation but a property of their interaction with the lighting environment, and the learner walks through the argument by moving between differently-lit regions of the room.
