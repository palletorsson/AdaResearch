extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Glitch Aesthetics[/b][/font_size][/center]
[center][i]Error as Art[/i][/center]

**Glitches reveal the machine.** Corruption becomes texture. Failure becomes feature.

**Digital materiality - the beauty of broken code.**

[hr]

[b]What Is a Glitch?[/b]

**Glitch = unintended behavior made visible:**

- **Visual:** Scrambled pixels, wrong colors, geometry spikes
- **Spatial:** Objects in wrong positions, clipping through walls
- **Temporal:** Stuttering, frame skips, animation breaks
- **Data:** Corrupted values, overflow, underflow

**Glitch art embraces these "errors" as aesthetic choices.**

[hr]

[b]Chromatic Aberration[/b]

**Color channels misaligned - like broken optics:**

[color=yellow][b]Shader: RGB Split[/b][/color]
[code]
shader_type canvas_item;

uniform float aberration_strength = 0.01;

void fragment() {
    vec2 uv = UV;

    // Sample each color channel at slightly different positions
    float r = texture(TEXTURE, uv + vec2(aberration_strength, 0)).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, uv - vec2(aberration_strength, 0)).b;

    COLOR = vec4(r, g, b, 1.0);
}

# Result: Red/blue fringing at edges
# Like cheap camera lens or VHS artifact
[/code]

**Chromatic aberration = color refraction failure** - digital "lens" defect.

[hr]

[b]Scanline Artifacts[/b]

**CRT display emulation - horizontal lines:**

[color=yellow][b]Shader: Scanlines[/b][/color]
[code]
shader_type canvas_item;

uniform float scanline_count = 200.0;
uniform float scanline_strength = 0.3;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Create horizontal bands
    float scanline = sin(UV.y * scanline_count * 3.14159 * 2.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanline_strength);

    COLOR = color * vec4(vec3(scanline), 1.0);
}

# Result: Retro CRT look
# Horizontal brightness variation
[/code]

[hr]

[b]Pixel Sorting (Asdf glitch)[/b]

**Sort pixels by luminance - creates streaking:**

[color=yellow][b]Code: Horizontal Pixel Sort[/b][/color]
[code]
func glitch_pixel_sort(image: Image):
    var width = image.get_width()
    var height = image.get_height()

    for y in range(height):
        if randf() < 0.1:  # Only glitch 10% of rows
            var row_pixels = []

            # Extract row
            for x in range(width):
                var color = image.get_pixel(x, y)
                row_pixels.append({"color": color, "luma": color.get_luminance()})

            # Sort by luminance
            row_pixels.sort_custom(func(a, b): return a.luma < b.luma)

            # Write back
            for x in range(width):
                image.set_pixel(x, y, row_pixels[x].color)

    return image

# Result: Streaky horizontal bands
# Aesthetic popularized by Kim Asendorf
[/code]

**Pixel sorting reveals hidden structure** - chaos organized by brightness.

[hr]

[b]Datamosh (Motion Corruption)[/b]

**Video compression artifacts - I-frames vs P-frames:**

[color=yellow][b]Concept: Frame Blending[/b][/color]
[code]
# Simplified datamosh: blend frames incorrectly
var previous_frame: Image = null

func datamosh_effect(current_frame: Image) -> Image:
    if previous_frame == null:
        previous_frame = current_frame.duplicate()
        return current_frame

    var result = current_frame.duplicate()

    # Randomly blend with previous frame
    for y in range(current_frame.get_height()):
        for x in range(current_frame.get_width()):
            if randf() < 0.3:  # 30% of pixels use old frame
                var old_color = previous_frame.get_pixel(x, y)
                result.set_pixel(x, y, old_color)

    previous_frame = current_frame.duplicate()
    return result

# Result: Motion blur + temporal artifacts
# Moving objects leave smeared trails
[/code]

**Datamoshing = video compression failure as art.**

[hr]

[b]Geometry Spike Glitch[/b]

**Vertices explode randomly - mesh corruption:**

[color=yellow][b]Code: Random Vertex Displacement[/b][/color]
[code]
func glitch_mesh_spikes(mesh_instance: MeshInstance3D, glitch_chance: float):
    var mesh = mesh_instance.mesh
    var arrays = mesh.surface_get_arrays(0)
    var vertices = arrays[Mesh.ARRAY_VERTEX]

    for i in range(vertices.size()):
        if randf() < glitch_chance:  # Randomly spike vertices
            var direction = Vector3(
                randf_range(-1, 1),
                randf_range(-1, 1),
                randf_range(-1, 1)
            ).normalized()

            var spike_length = randf_range(5, 20)
            vertices[i] += direction * spike_length

    arrays[Mesh.ARRAY_VERTEX] = vertices

    var new_mesh = ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh_instance.mesh = new_mesh

# Result: Mesh with random spikes
# Like corrupted 3D model buffer
[/code]

**Geometry spikes = buffer overflow made visible.**

[hr]

[b]UV Scramble[/b]

**Texture coordinates randomized - broken mapping:**

[color=yellow][b]Shader: UV Chaos[/b][/color]
[code]
shader_type spatial;

uniform sampler2D texture_albedo;
uniform float glitch_amount = 0.5;

float hash(vec2 p) {
    return fmod(sin(dot(p, vec2(127.1, 311.7, 1.0))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Randomly offset UVs based on grid cell
    vec2 cell = floor(uv * 10.0);
    float random = hash(cell);

    if (random < glitch_amount) {
        // Scramble this cell's UVs
        uv += vec2(hash(cell + vec2(1.0, 0.0)), hash(cell + vec2(0.0, 1.0))) * 0.5;
    }

    ALBEDO = texture(texture_albedo, uv).rgb;
}

# Result: Texture appears scrambled in patches
# Like corrupted image file
[/code]

[hr]

[b]Color Quantization (Bit Crush)[/b]

**Reduce color depth - posterization:**

[color=yellow][b]Shader: Bit Reduction[/b][/color]
[code]
shader_type canvas_item;

uniform int color_depth = 4;  // Bits per channel

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    float levels = pow(2.0, float(color_depth));

    // Quantize each channel
    color.r = floor(color.r * levels) / levels;
    color.g = floor(color.g * levels) / levels;
    color.b = floor(color.b * levels) / levels;

    COLOR = color;
}

# Result: Posterized, low-bit color
# Like 16-color EGA graphics
[/code]

**Bit crushing = intentional data loss.**

[hr]

[b]Random Displacement[/b]

**Pixels/blocks shifted randomly:**

[color=yellow][b]Shader: Block Displacement[/b][/color]
[code]
shader_type canvas_item;

uniform float block_size = 0.05;
uniform float displacement_strength = 0.1;

float hash(vec2 p) {
    return fmod(sin(dot(p, vec2(127.1, 311.7, 1.0))) * 43758.5453);
}

void fragment() {
    vec2 block_coord = floor(UV / block_size);
    vec2 random_offset = vec2(
        hash(block_coord),
        hash(block_coord + vec2(1.0, 0.0))
    ) * 2.0 - 1.0;

    vec2 displaced_uv = UV + random_offset * displacement_strength;
    COLOR = texture(TEXTURE, displaced_uv);
}

# Result: Image broken into shifted blocks
# Like transmission error
[/code]

[hr]

[b]Temporal Glitch (Frame Skip)[/b]

**Randomly freeze or stutter:**

[color=yellow][b]Code: Frame Hold[/b][/color]
[code]
var held_frame: Image = null
var hold_timer: float = 0

func _process(delta):
    hold_timer -= delta

    if hold_timer <= 0:
        # Randomly decide to hold next frame
        if randf() < 0.05:  # 5% chance per frame
            hold_timer = randf_range(0.1, 0.5)  # Hold for 0.1-0.5 seconds
            held_frame = get_current_frame()

    if hold_timer > 0 and held_frame:
        display_frame(held_frame)  # Show frozen frame
    else:
        display_frame(get_current_frame())  # Normal playback

# Result: Random stuttering
# Like network packet loss or disk read error
[/code]

[hr]

[b]Analog Noise (VHS Tracking)[/b]

**Simulate magnetic tape degradation:**

[color=yellow][b]Shader: VHS Distortion[/b][/color]
[code]
shader_type canvas_item;

uniform float time;

float noise(vec2 p) {
    return fmod(sin(dot(p, vec2(12.9898, 78.233, 1.0))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Horizontal tracking errors
    float tracking_error = noise(vec2(uv.y * 10.0, time * 0.5)) * 0.02;
    uv.x += tracking_error;

    // Random dropout lines
    float dropout = step(0.99, noise(vec2(uv.y * 100.0, time)));
    vec4 color = texture(TEXTURE, uv);

    if (dropout > 0.5) {
        color = vec4(0.0);  # Black dropout line
    }

    COLOR = color;
}

# Result: Wobbly, glitchy VHS playback
[/code]

[hr]

[b]Corrupt Data Visualization[/b]

**Treat random bytes as visual data:**

[color=yellow][b]Code: Raw Data as Image[/b][/color]
[code]
# Read arbitrary binary file, interpret as pixels
func corrupt_data_texture(file_path: String) -> ImageTexture:
    var file = FileAccess.open(file_path, FileAccess.READ)
    var bytes = file.get_buffer(256 * 256 * 3)  # Read enough for 256×256 RGB
    file.close()

    var image = Image.create(256, 256, false, Image.FORMAT_RGB8)

    for y in range(256):
        for x in range(256):
            var index = (y * 256 + x) * 3
            if index + 2 < bytes.size():
                var color = Color8(bytes[index], bytes[index + 1], bytes[index + 2])
                image.set_pixel(x, y, color)

    return ImageTexture.create_from_image(image)

# Result: Noise pattern from file contents
# Exe files, config files as visual texture
[/code]

**Data corruption as aesthetic** - treat everything as pixels.

[hr]

[b]Intentional Overflow[/b]

**Push values beyond limits:**

[color=yellow][b]Code: Value Explosion[/b][/color]
[code]
# Multiply values until overflow
func glitch_overflow_color(color: Color, iterations: int) -> Color:
    for i in range(iterations):
        color.r *= 1.5
        color.g *= 1.5
        color.b *= 1.5

    # Values > 1.0 clamp or wrap depending on context
    return color

# HDR mode: Super bright bloom
# LDR mode: Wraps to dark (modulo 1.0)

# Result: Extreme brightness or color cycling
[/code]

[hr]

[b]Glitch Trigger Conditions[/b]

**When to glitch:**

[color=yellow][b]Code: Context-Aware Glitching[/b][/color]
[code]
func should_glitch() -> bool:
    # 1. Random chance (ambient)
    if randf() < 0.001:  # 0.1% per frame
        return true

    # 2. Low health (damage visualization)
    if player.health < 20:
        if randf() < 0.05:
            return true

    # 3. Specific events (narrative)
    if narrative_event == "reality_breakdown":
        return true

    # 4. Proximity to glitch sources
    var distance_to_anomaly = player.global_position.distance_to(anomaly_position)
    if distance_to_anomaly < 10:
        var glitch_chance = 1.0 - (distance_to_anomaly / 10.0)
        if randf() < glitch_chance:
            return true

    return false

# Apply glitch if triggered
if should_glitch():
    apply_random_glitch_effect()

# Result: Contextual glitching
# Narrative/mechanical integration
[/code]

[hr]

[b]The Politics of Glitch[/b]

**Glitch art reveals digital materiality:**

1. **Exposes the machine** - Breaks illusion of seamless digital
2. **Embraces failure** - Error as creative tool, not bug
3. **Questions perfection** - Imperfection is interesting
4. **Reveals hidden structure** - Compression, buffers, data visible
5. **Resists control** - Randomness breaks designer intent

**Glitch is queer** - refuses binary (working/broken), exists in liminal state, makes visible what should be hidden.

**The glitch says: "I am a computer. I fail. That's beautiful."**

[hr]

[b]What Glitch Aesthetics Reveal[/b]

Glitch aesthetics show us:

1. **Error is texture** - Corruption as visual material
2. **Digital has materiality** - Pixels, buffers, compression visible
3. **Failure is feature** - Embrace the broken
4. **Randomness creates chaos** - Controlled unpredictability
5. **Context matters** - When/why glitch affects meaning
6. **Perfect is boring** - Imperfection is interest
7. **Machine is visible** - Break the illusion

**Glitches are digital scars** - traces of process, marks of materiality.

**Smooth rendering hides the computer. Glitch reveals it.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Glitch aesthetics embrace error as art. Chromatic aberration (RGB split), scanlines (CRT emulation), pixel sorting (luminance-based streaking), datamoshing (frame blending artifacts), geometry spikes (vertex explosion), UV scrambling (texture coordinate chaos), bit crushing (color quantization), block displacement, temporal stuttering (frame hold), VHS distortion. Context-aware triggering (health, narrative, proximity). Glitch reveals digital materiality, embraces failure, resists perfection. Digital scars as beauty.

[hr]

[color=orange][b]Next:[/b] Pheromone Trails[/color]
If glitches are broken signals, pheromones are accumulated signals - trails left behind, stigmergic communication, ant colony algorithms. Indirect coordination through environment.

'''
