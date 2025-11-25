extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Shader Noise[/b][/font_size][/center]
[center][i]GPU Randomness and Hash Functions[/i][/center]

**CPU noise is slow.** GPU noise is parallel - thousands of samples per frame.

**Shader noise = procedural generation on the graphics card.**

[hr]

[b]Why GPU Noise?[/b]

**Advantages:**
- **Massively parallel** - Every pixel computed simultaneously
- **Real-time** - Procedural textures without RAM storage
- **Infinite resolution** - No texture memory limits
- **Dynamic** - Animate noise with time parameter

**Challenges:**
- **No random()** - GPUs are deterministic
- **Hash functions** - Pseudo-random from coordinates
- **Limited precision** - Floating-point artifacts

[hr]

[b]Hash Function (Deterministic "Random")[/b]

**Core technique - fake randomness from position:**

[color=yellow][b]Shader: Basic Hash[/b][/color]
[code]
shader_type canvas_item;

// Hash function: vec2 → float [0, 1]
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV * 10.0;  // Scale up for visibility
    float noise = hash(floor(uv));  // Hash grid cell

    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Random-looking grayscale per grid cell
// Same cell = same value (deterministic)
// Different cells = different values (appears random)
[/code]

**Hash function properties:**
- **Deterministic** - Same input always gives same output
- **Chaotic** - Small input change → large output change
- **Uniform** - Output evenly distributed [0, 1]

[hr]

[b]Better Hash Functions[/b]

**Simple hash has artifacts - better versions exist:**

[color=yellow][b]Shader: High-Quality Hash[/b][/color]
[code]
// Integer hash (faster, fewer artifacts)
float hash_int(ivec2 p) {
    int n = p.x * 3 + p.y * 113;
    n = (n << 13) ^ n;
    int m = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return float(m) / 2147483647.0;
}

// Or: PCG hash (permuted congruential generator)
float hash_pcg(vec2 p) {
    uvec2 v = uvec2(p);
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    return float(v.x) / float(0xffffffffu);
}

# Result: Less correlation, better randomness quality
[/code]

[hr]

[b]Value Noise in Shader[/b]

**Grid-based interpolation (see value_noise_axioms.gd):**

[color=yellow][b]Shader: 2D Value Noise[/b][/color]
[code]
shader_type canvas_item;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 uv) {
    vec2 i = floor(uv);  // Integer part
    vec2 f = fract(uv);  // Fractional part

    // Smoothstep interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Sample four corners
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    float noise = value_noise(UV * 10.0);
    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Smooth gradient noise
[/code]

[hr]

[b]Perlin Noise in Shader[/b]

**Gradient-based (better quality than value noise):**

[color=yellow][b]Shader: Simplified Perlin[/b][/color]
[code]
shader_type canvas_item;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return vec2(
        hash(p),
        hash(p + vec2(0.1, 0.1))
    ) * 2.0 - 1.0;  // Map to [-1, 1]
}

float perlin_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Smoothstep
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Gradient vectors at corners
    vec2 ga = hash2(i + vec2(0.0, 0.0));
    vec2 gb = hash2(i + vec2(1.0, 0.0));
    vec2 gc = hash2(i + vec2(0.0, 1.0));
    vec2 gd = hash2(i + vec2(1.0, 1.0));

    // Dot products with offset vectors
    float va = dot(ga, f - vec2(0.0, 0.0));
    float vb = dot(gb, f - vec2(1.0, 0.0));
    float vc = dot(gc, f - vec2(0.0, 1.0));
    float vd = dot(gd, f - vec2(1.0, 1.0));

    // Interpolate
    return mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y);
}

void fragment() {
    float noise = perlin_noise(UV * 10.0) * 0.5 + 0.5;  // Remap to [0, 1]
    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Smoother than value noise, less artifacts
[/code]

[hr]

[b]Fractal Brownian Motion (fBm) in Shader[/b]

**Layered octaves for detail:**

[color=yellow][b]Shader: fBm[/b][/color]
[code]
shader_type canvas_item;

// ... (include perlin_noise function from above)

float fbm(vec2 uv, int octaves) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float max_value = 0.0;

    for (int i = 0; i < octaves; i++) {
        value += perlin_noise(uv * frequency) * amplitude;
        max_value += amplitude;
        amplitude *= 0.5;  // Persistence
        frequency *= 2.0;  // Lacunarity
    }

    return value / max_value;
}

void fragment() {
    float noise = fbm(UV * 5.0, 6) * 0.5 + 0.5;
    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Rich, detailed noise texture
// Multiple scales of variation
[/code]

[hr]

[b]Simplex Noise (GPU-Optimized)[/b]

**Fewer samples than Perlin, faster on GPU:**

[color=yellow][b]Concept: 2D Simplex[/b][/color]
[code]
// Simplex uses triangular grid instead of square
// 3 samples per point instead of 4 (25% faster)

// Full implementation complex, but standard in noise libraries
// See: Inigo Quilez's Shadertoy implementations

// Key advantage: Scales better to 3D/4D
// Perlin 3D needs 8 samples, Simplex needs 4
// Perlin 4D needs 16 samples, Simplex needs 5
[/code]

[hr]

[b]Worley/Voronoi Noise in Shader[/b]

**Cellular patterns (see worley_noise_axioms.gd):**

[color=yellow][b]Shader: Worley Noise[/b][/color]
[code]
shader_type canvas_item;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return vec2(hash(p), hash(p + vec2(0.1, 0.1)));
}

float worley_noise(vec2 uv) {
    vec2 cell = floor(uv);
    vec2 fract_pos = fract(uv);

    float min_dist = 1.0;

    // Check 3×3 grid of cells
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(cell + neighbor);  // Random point in neighbor cell

            vec2 diff = neighbor + point - fract_pos;
            float dist = length(diff);

            min_dist = min(min_dist, dist);
        }
    }

    return min_dist;
}

void fragment() {
    float noise = worley_noise(UV * 10.0);
    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Cellular/bubble pattern
[/code]

[hr]

[b]Domain Warping[/b]

**Use noise to distort noise coordinates:**

[color=yellow][b]Shader: Domain Warping[/b][/color]
[code]
shader_type canvas_item;

// ... (include fbm function)

void fragment() {
    vec2 uv = UV * 5.0;

    // First layer of noise to warp coordinates
    vec2 warp = vec2(
        fbm(uv + vec2(0.0, 0.0), 4),
        fbm(uv + vec2(5.2, 1.3), 4)
    ) * 2.0;

    // Second layer using warped coordinates
    float noise = fbm(uv + warp, 6) * 0.5 + 0.5;

    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Swirling, organic patterns
// Much more complex than straight fBm
[/code]

[hr]

[b]Animated Noise (Time Parameter)[/b]

**Noise that evolves over time:**

[color=yellow][b]Shader: Time-Based Animation[/b][/color]
[code]
shader_type canvas_item;

uniform float time;

// ... (include fbm function)

void fragment() {
    vec2 uv = UV * 5.0;

    // Option 1: Sample 3D noise using (x, y, time)
    // float noise = fbm_3d(vec3(uv, time * 0.1), 6);

    // Option 2: Offset coordinates by time
    vec2 animated_uv = uv + vec2(time * 0.1, time * 0.05);
    float noise = fbm(animated_uv, 6) * 0.5 + 0.5;

    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Flowing noise, like clouds drifting
[/code]

[hr]

[b]Tileable Noise[/b]

**Seamlessly repeating noise:**

[color=yellow][b]Shader: Tiling Noise[/b][/color]
[code]
shader_type canvas_item;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise_tile(vec2 uv, float tile_size) {
    // Wrap coordinates at tile boundary
    vec2 i = mod(floor(uv), tile_size);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Sample with wrapping
    float a = hash(mod(i + vec2(0.0, 0.0), tile_size));
    float b = hash(mod(i + vec2(1.0, 0.0), tile_size));
    float c = hash(mod(i + vec2(0.0, 1.0), tile_size));
    float d = hash(mod(i + vec2(1.0, 1.0), tile_size));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    float noise = value_noise_tile(UV * 50.0, 10.0);
    COLOR = vec4(vec3(noise), 1.0);
}

// Result: Noise that repeats seamlessly
// Good for terrain textures, materials
[/code]

[hr]

[b]Noise-Based Material Effects[/b]

[color=yellow][b]1. Clouds[/b][/color]
[code]
void fragment() {
    float cloud_density = fbm(UV * 3.0 + vec2(TIME * 0.1, 0), 6);
    cloud_density = smoothstep(0.4, 0.6, cloud_density);

    vec3 cloud_color = vec3(1.0);
    vec3 sky_color = vec3(0.5, 0.7, 1.0);

    COLOR.rgb = mix(sky_color, cloud_color, cloud_density);
}
[/code]

[color=yellow][b]2. Fire[/b][/color]
[code]
void fragment() {
    vec2 uv = UV;
    uv.y -= TIME * 0.5;  // Rise upward

    float fire_noise = fbm(uv * vec2(3.0, 6.0), 6);
    fire_noise = pow(fire_noise * 0.5 + 0.5, 2.0);

    // Map to fire colors (yellow → orange → red → black)
    vec3 fire_color = mix(
        vec3(1.0, 0.0, 0.0),  // Red
        vec3(1.0, 1.0, 0.0),  // Yellow
        fire_noise
    );

    COLOR.rgb = fire_color * fire_noise;
}
[/code]

[color=yellow][b]3. Marble[/b][/color]
[code]
void fragment() {
    vec2 uv = UV * 5.0;

    // Turbulence function (absolute value)
    float turbulence = abs(fbm(uv, 6));

    // Create veins with sine wave + turbulence
    float marble = sin(uv.x + turbulence * 5.0) * 0.5 + 0.5;

    // Color gradient
    vec3 color = mix(
        vec3(0.8, 0.8, 0.8),  // Light gray
        vec3(0.2, 0.2, 0.2),  // Dark gray
        marble
    );

    COLOR.rgb = color;
}
[/code]

[hr]

[b]Performance Considerations[/b]

**GPU noise is fast, but not free:**

[color=yellow][b]Optimization Tips:[/b][/color]
[code]
# 1. Reduce octaves
# - 6 octaves for quality, 3-4 for performance
# - Each octave doubles cost

# 2. Lower resolution
# - Compute noise at half resolution, upscale
# - Barely noticeable for smooth noise

# 3. Bake to texture
# - Pre-compute noise, store in texture
# - Sample texture instead of computing
# - Trade memory for speed

# 4. Use cheaper hash
# - Integer hash faster than float
# - PCG hash high quality, good speed

# 5. LOD (Level of Detail)
# - Fewer octaves for distant objects
# - Full quality only for close-up

# 6. Avoid branching
# - No if/else in inner loops
# - Use mix() and step() instead
[/code]

[hr]

[b]What Shader Noise Reveals[/b]

Shader noise shows us:

1. **Parallel is powerful** - Thousands of pixels computed simultaneously
2. **Hash = fake random** - Deterministic chaos from coordinates
3. **No state needed** - Stateless noise generation
4. **Infinite resolution** - Procedural textures scale arbitrarily
5. **Real-time generation** - Dynamic materials without storage
6. **GPU constraints** - No real RNG, limited precision, avoid branching
7. **Octaves trade quality/speed** - Balance detail and performance

**Shader noise is mathematical texture** - no images, just equations creating complexity.

**The GPU is a massively parallel noise machine** - exploit it.

[hr]

[color=cyan][b]Summary:[/b][/color]
Shader noise generates randomness on GPU via hash functions (deterministic pseudo-random from coordinates). Hash converts vec2 → float [0,1]. Value noise (grid interpolation), Perlin noise (gradient-based), Simplex (triangular grid, faster), Worley (cellular). fBm layers octaves for detail. Domain warping (noise distorts noise). Time parameter animates. Tileable noise for seamless repetition. Applications: clouds, fire, marble, procedural materials. Performance: reduce octaves, lower resolution, bake textures, use cheap hashes, LOD.

[hr]

[color=orange][b]Next:[/b] Voxel Noise - 3D Terrain Generation[/color]
Shader noise works in 2D/3D. Voxel noise generates volumetric worlds - caves, overhangs, mountains, all from 3D noise functions. Minecraft-like procedural generation.

'''
