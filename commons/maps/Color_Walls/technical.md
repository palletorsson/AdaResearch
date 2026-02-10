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

```glsl
shader_type spatial;

uniform float hallway_length = 20.0;
uniform float saturation = 1.0;
uniform float value = 1.0;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 hsv_to_rgb(float h, float s, float v) {
    vec3 c = vec3(h, s, v);
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
    // Use Z position for hue
    float hue = world_position.z / hallway_length;
    hue = fract(hue);  // Repeat if longer than one cycle

    vec3 color = hsv_to_rgb(hue * 0.8, saturation, value);

    ALBEDO = color;
    EMISSION = color * 0.5;
}
```

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

```gdscript
# Define specific color stops along the hallway
var color_stops = [
    {"position": 0.0, "color": Color.RED},
    {"position": 0.15, "color": Color.ORANGE},
    {"position": 0.3, "color": Color.YELLOW},
    {"position": 0.45, "color": Color.GREEN},
    {"position": 0.6, "color": Color.CYAN},
    {"position": 0.75, "color": Color.BLUE},
    {"position": 0.9, "color": Color.PURPLE},
    {"position": 1.0, "color": Color.MAGENTA}
]

func get_gradient_color(t: float) -> Color:
    # Find which segment we're in
    for i in range(color_stops.size() - 1):
        var start = color_stops[i]
        var end = color_stops[i + 1]

        if t >= start.position and t <= end.position:
            # Interpolate within segment
            var segment_t = (t - start.position) / (end.position - start.position)
            return start.color.lerp(end.color, segment_t)

    return color_stops[-1].color
```

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

```gdscript
# Lights along hallway that change color with position
extends Node3D

var lights: Array[OmniLight3D] = []

func create_gradient_lights(count: int):
    for i in range(count):
        var light = OmniLight3D.new()
        light.position.z = (float(i) / count) * hallway_length

        # Color from position
        var t = float(i) / count
        light.light_color = Color.from_hsv(t * 0.8, 1.0, 1.0)
        light.light_energy = 1.5
        light.omni_range = hallway_length / count * 2.0  # Overlap for smoothness

        lights.append(light)
        add_child(light)

# Many overlapping colored lights approximate continuous gradient
# More lights = smoother transition
```

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
