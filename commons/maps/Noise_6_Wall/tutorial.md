# Noise 6-Wall

Six octaves of noise rendered per-pixel in a shader.

Write a fragment shader.

```gdscript
const SHADER_CODE: String = """
shader_type canvas_item;

uniform float time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smoothstep_val(float t) {
    return t * t * (3.0 - 2.0 * t);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = vec2(smoothstep_val(f.x), smoothstep_val(f.y));
    return mix(
        mix(hash(i), hash(i + vec2(1, 0)), f.x),
        mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        total += value_noise(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void fragment() {
    vec2 p = UV * 8.0 + vec2(time * 0.1, 0.0);
    float n = fbm(p);
    COLOR = vec4(n, n, n, 1.0);
}
"""
```

Six octaves stacked in a for loop. Each octave doubles the frequency and halves the amplitude.

Attach the shader.

```gdscript
func create_shader_material() -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = SHADER_CODE
    var material := ShaderMaterial.new()
    material.shader = shader
    return material
```

Standard pipeline: create Shader, wrap in ShaderMaterial, apply to a node.

Apply to a wall.

```gdscript
func setup_wall() -> void:
    var wall := MeshInstance3D.new()
    wall.mesh = QuadMesh.new()
    wall.mesh.size = Vector2(6, 3)
    wall.material_override = create_shader_material()
    add_child(wall)
```

A flat quad takes the shader's output as its albedo. The wall flickers with noise.

Pass time as a uniform.

```gdscript
var wall_material: ShaderMaterial

func _process(_delta: float) -> void:
    wall_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
```

The shader reads the time; the noise scrolls accordingly.

Render as 3D fog.

```gdscript
const VOLUMETRIC_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;

uniform float density_scale = 1.0;

float fbm(vec3 p) {
    // same pattern as 2D but with 3D hash
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        total += value_noise_3d(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void fragment() {
    float density = fbm(VERTEX * density_scale);
    ALPHA = density * 0.3;
    ALBEDO = vec3(1.0);
}
"""
```

A 3D noise shader on a transparent volume. The cloud appears as drifting fog.

Tune the frequencies.

```gdscript
@export_range(0.5, 4.0) var base_frequency: float = 1.0

func update_frequency() -> void:
    wall_material.set_shader_parameter("frequency", base_frequency)
```

Lower values produce broad patterns; higher values produce fine detail.

You can now write a fBm fragment shader, apply it to walls, scroll it over time, and extend to volumetric 3D rendering. Noise_Inside_Noise extends into domain warping.
