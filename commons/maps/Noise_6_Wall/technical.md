# Six octaves converge on a wall where every pixel computes its own noise from coordinates and arithmetic alone

Noise_Voxel discretized the continuous field into blocks — a threshold per cell, a boolean per voxel, the entire terrain reduced to solid or void at lattice intervals. The computation was sequential: three nested loops, one noise evaluation per cell, the CPU walking the grid point by point.

A 32x64x32 chunk required 65,536 evaluations in series. Double the resolution along each axis and the time scales cubically. The CPU treats each sample as a task in a queue. It finishes one, begins the next, remembers where it left off.

```gdscript
# CPU noise: sequential, stateful, one evaluation at a time
for x in range(grid_size):
    for y in range(grid_size):
        for z in range(grid_size):
            var n = noise.get_noise_3d(x, y, z)
            _voxels[x][y][z] = n > threshold
```

Noise generation on the CPU is a conversation between the processor and memory — fetch coordinates, compute gradient, interpolate, store result, advance. The loop variable remembers where the processor left off. The array remembers what it found.

This map abandons that model. The shader_noise_space artifact generates a procedural texture on a flat wall surface where every fragment — every pixel — evaluates six octaves of fractal Brownian motion simultaneously. No pre-computed data. No gradient lookup tables stored in texture memory. No sequential loop through cells.

The GPU receives a fragment coordinate, runs a hash function to derive pseudo-random gradients, interpolates, layers six octaves with decreasing amplitude and increasing frequency, and outputs a color. Thousands of fragments computed in parallel, every frame, from nothing but position and math.

The shift from CPU to GPU is not optimization. It is a change in what noise is. CPU noise is a value you request at a point. GPU noise is a field that exists everywhere at once.

## Hash Functions Replace Gradient Tables

Classical Perlin noise stores a table of pre-computed gradient vectors. To evaluate noise at a point, the algorithm identifies the surrounding grid cell, looks up the gradients at each corner, computes dot products, and interpolates. The table lives in memory. The gradient exists before the noise function runs.

Shader-based noise eliminates the table. A hash function takes integer grid coordinates as input and produces a pseudo-random output deterministically:

```gdscript
# Conceptual hash — integer coordinates to pseudo-random float
func hash_2d(ix: int, iy: int) -> float:
    var h = ix * 374761393 + iy * 668265263
    h = (h ^ (h >> 13)) * 1274126177
    h = h ^ (h >> 16)
    return float(h & 0x7fffffff) / float(0x7fffffff)
```

Multiply, XOR, shift, multiply, XOR, shift. Bitwise arithmetic on integers. No memory access. No stored state. The same input always produces the same output — determinism without storage.

The hash function is a compression of the gradient table into an algorithm. Instead of recording every gradient and retrieving it by index, the hash computes what the gradient would have been, on demand, from coordinates alone. The magic numbers — 374761393, 668265263, 1274126177 — are large primes chosen to spread the output uniformly. Different primes produce different noise. The statistical character stays the same.

On the GPU, this matters profoundly. Texture memory lookups have latency — the fragment processor must wait for data to arrive from VRAM. Arithmetic has no such bottleneck. The ALU on a modern GPU can execute integer operations in a single cycle.

Hash-based noise trades memory bandwidth for compute throughput. On hardware designed to maximize parallel arithmetic, this is the correct trade.

The shader_noise_space artifact implements this directly. The fragment shader receives UV coordinates from the wall mesh, scales them into noise space, and hashes the integer grid corners surrounding each fragment position. No texture is sampled. No uniform buffer stores gradients. The noise emerges from arithmetic applied to coordinates — stateless, reproducible, infinite in extent.

## From Hash to Gradient: Constructing Noise Per Fragment

A hash value alone is not noise. Noise requires smooth interpolation between grid points. The per-fragment construction follows a precise sequence:

```gdscript
# GPU noise evaluation structure (expressed as GDScript for clarity)
func gpu_noise_2d(position: Vector2) -> float:
    var cell := Vector2(floor(position.x), floor(position.y))
    var frac := position - cell

    # Hash each corner to get a gradient direction
    var g00 := hash_to_gradient(cell + Vector2(0, 0))
    var g10 := hash_to_gradient(cell + Vector2(1, 0))
    var g01 := hash_to_gradient(cell + Vector2(0, 1))
    var g11 := hash_to_gradient(cell + Vector2(1, 1))

    # Dot product: gradient at corner dotted with vector from corner to position
    var d00 := g00.dot(frac - Vector2(0, 0))
    var d10 := g10.dot(frac - Vector2(1, 0))
    var d01 := g01.dot(frac - Vector2(0, 1))
    var d11 := g11.dot(frac - Vector2(1, 1))

    # Smoothstep interpolation
    var u := frac * frac * (Vector2(3.0, 3.0) - 2.0 * frac)
    var x0 := lerpf(d00, d10, u.x)
    var x1 := lerpf(d01, d11, u.x)
    return lerpf(x0, x1, u.y)
```

Four corners. Four hashes. Four gradients. Four dot products. Two interpolations along x, one along y. The smoothstep curve — `t * t * (3 - 2t)` — ensures the interpolation has zero derivative at the grid boundaries, so the transition between cells is seamless. No visible grid lines. The lattice that produced the gradients vanishes into continuity.

Each GPU thread executes this sequence independently. Fragment at pixel (400, 300) does not wait for fragment at pixel (401, 300). They share no state, read no common buffer, synchronize at no barrier. The computation at each point is self-contained. The function needs only its own coordinate and the hash algorithm. Everything else is derived.

The `hash_to_gradient` step converts the raw hash integer into a unit-length direction vector. Common approaches select from a small set of canonical directions — the twelve edge midpoints of a cube in 3D, or four diagonal directions in 2D — based on the hash value modulo the set size. Directions must be distributed uniformly to avoid directional bias in the output.

Fewer directions means faster selection but higher risk of visible patterns at grid scale. More directions means more isotropy at the cost of a slightly larger computation. The gradient set is a design parameter, and different implementations make different choices.

## Fractal Brownian Motion: Six Octaves in One Pass

A single noise evaluation produces smooth undulation. One frequency, one amplitude, one scale of variation. Fractal Brownian motion layers multiple evaluations at different scales into a composite:

```gdscript
func fbm(position: Vector2, octaves: int) -> float:
    var value := 0.0
    var amplitude := 0.5
    var frequency := 1.0
    var lacunarity := 2.0
    var persistence := 0.5

    for i in range(octaves):
        value += amplitude * gpu_noise_2d(position * frequency)
        frequency *= lacunarity
        amplitude *= persistence

    return value
```

Six iterations. Each octave doubles the frequency and halves the amplitude. The first octave contributes broad shapes at half amplitude. The second adds medium detail at quarter amplitude. The third adds finer structure at eighth amplitude.

By the sixth octave, the frequency is 32 times the base and the amplitude is 1/64th — tiny ripples at high spatial density, barely visible individually but collectively responsible for the texture that separates "procedural" from "organic."

The progression across octaves:

```
Octave 1: frequency 1x,  amplitude 0.5
Octave 2: frequency 2x,  amplitude 0.25
Octave 3: frequency 4x,  amplitude 0.125
Octave 4: frequency 8x,  amplitude 0.0625
Octave 5: frequency 16x, amplitude 0.03125
Octave 6: frequency 32x, amplitude 0.015625
```

The sum converges. Each octave contributes half what the previous one did, so the series approaches a finite limit:

```
0.5 + 0.25 + 0.125 + 0.0625 + 0.03125 + 0.015625 = 0.984375
```

The total amplitude stays bounded regardless of octave count. The visual consequence: fBM output occupies roughly the same value range whether one octave or six, but the character of the output changes dramatically. One octave is a smooth hill. Three octaves are a weathered ridge. Six octaves are granite.

The wall displays the six-octave sum as a real-time procedural texture. The fragment shader runs the entire fBM loop per pixel. Six noise evaluations per fragment, each involving four hash computations, four dot products, and three interpolations.

The arithmetic per pixel: approximately 72 hash operations, 72 dot products, and 18 interpolations. At 1920x1080, that is roughly 150 million hash operations per frame. The GPU handles this without hesitation because the operations execute in parallel across thousands of shader cores.

Persistence and lacunarity control the character of fBM independently. Persistence determines how quickly amplitude decays. At 0.5, each octave is half the previous — standard 1/f noise, the frequency spectrum found in coastlines, mountain profiles, and Brownian motion. Raise persistence to 0.7 and high-frequency detail dominates: rough, aggressive, eroded. Lower it to 0.3 and high octaves vanish: smooth, broad, almost featureless.

Lacunarity determines the frequency gap between octaves. At 2.0, each octave doubles — the standard geometric progression. Raise lacunarity to 3.0 and octaves space further apart, leaving gaps in the frequency spectrum. Lower it to 1.5 and octaves crowd together, producing muddier layering. The two parameters span a plane of possible textures. The wall is one point in that plane.

## Parallel Computation: Why the GPU Changes Everything

The CPU processes noise sequentially. One point at a time. State accumulates — loop counters increment, memory pointers advance, branch predictions fire. The GPU processes noise simultaneously. Every fragment shader instance is a thread, and a modern GPU dispatches thousands of threads per clock cycle across its shader multiprocessors.

The wall mesh provides UV coordinates that map each fragment to a position in noise space. The vertex shader passes these through. The fragment shader receives them and begins computation:

```gdscript
shader_type spatial;

uniform float noise_scale = 8.0;

varying vec2 noise_uv;

void vertex() {
    noise_uv = UV * noise_scale;
}

void fragment() {
    float n = fbm(noise_uv, 6);
    float mapped = n * 0.5 + 0.5;
    ALBEDO = vec3(mapped);
}
```

No fragment depends on any other fragment's result. No synchronization is required. No shared mutable state exists. The computation is embarrassingly parallel — independent subproblems with zero communication overhead.

The vertex shader scales UV coordinates by a uniform parameter, establishing the spatial density of the noise pattern on the wall surface. The `noise_scale` uniform controls how much of the noise field is visible. Higher values compress more noise variation into the same wall area. Lower values zoom into a smaller region with more visible detail per pixel.

The fragment shader evaluates fBM at the scaled coordinate and maps the result to a grayscale value. Bright areas where the six octaves sum to high values. Dark areas where they sum low. The texture is the noise field made visible — a density map of structured randomness painted across a flat surface.

The remapping `n * 0.5 + 0.5` is the same sine-to-normalized transformation from previous maps:

```
noise range:  [-1.0 ... 0.0 ... +1.0]
             * 0.5
scaled:       [-0.5 ... 0.0 ... +0.5]
             + 0.5
color range:  [ 0.0 ... 0.5 ... +1.0]
```

Noise returns values centered around zero. The color pipeline expects values between 0 and 1. The affine transform bridges the domains. Without it, negative noise values clamp to black and half the field's variation vanishes.

## Resolution Independence

CPU-side voxel noise was resolution-dependent. The grid dictated how many points got sampled. Double the grid along each axis and the computation cost octupled. The output was fixed — a specific set of voxels at specific positions, stored in a boolean array, unchanged until explicitly regenerated.

GPU noise on the wall is resolution-independent in a different sense. The noise function does not know the screen resolution. It receives a UV coordinate — a position in texture space — and computes.

If the window is 1920x1080, that is 2,073,600 evaluations. If the window is 3840x2160, that is 8,294,400 evaluations. The cost scales with pixel count, but the function itself does not change. The noise field is continuous and infinite. The screen is a viewport into that field.

Zoom in and more detail appears because higher octaves produce variation at every scale. The noise never runs out of resolution. It is defined everywhere, at every magnification.

This is the fundamental advantage of procedural generation over stored textures. A 1024x1024 texture contains exactly 1,048,576 pixels of information. Zoom in and it blurs. The information is finite, allocated at authoring time.

A procedural noise function contains zero stored pixels and infinite potential detail. The information is generated at render time, at whatever resolution the viewport demands. Texture lookups are cheap — one memory read. Procedural evaluation is expensive — dozens of arithmetic operations per pixel. But the GPU was built for expensive arithmetic, and six octaves of fBM remain well within its budget.

The wall artifact demonstrates this directly. Approach the wall and the texture does not pixelate. The octaves continue producing variation at finer and finer scales because the UV coordinates fed to the shader grow more precise as the camera nears the surface.

The sixth octave — invisible at a distance — becomes the dominant visual feature at close range. Scale invariance is not a theoretical property. It is visible behavior.

## The Wall as Display Surface

The map's structure places the shader_noise_space artifact on a wall — a flat vertical surface flanked by corridors. The choice is deliberate.

A wall is the simplest possible geometry: a quad, two triangles, a flat plane in screen space. No curvature to confuse the reading. No topology to distort the UV mapping. The noise pattern on the wall is the noise function itself, presented without geometric interference.

Previous maps wrapped noise around tori, applied it to column displacements, carved it into voxel volumes. Each application added geometric complexity that obscured the underlying field. The wall strips all of that away. The learner sees noise — not noise applied to something.

The six octaves are legible on the flat surface: broad light-dark variation from the first octave, medium-scale texture from the middle octaves, fine grain from the last two. The wall is a spectrogram of structured randomness, read not in frequency bands but in spatial scales nested within spatial scales.

The dark_sphere persists in this map, positioned apart from the wall. Its surface is opaque geometry rendered through the standard material pipeline — `StandardMaterial3D`, albedo, emission, roughness:

```gdscript
_sphere_material = StandardMaterial3D.new()
_sphere_material.albedo_color = Color(albedo_color.r, albedo_color.g, albedo_color.b, 0.85)
_sphere_material.metallic = 0.6
_sphere_material.roughness = 0.25
_sphere_material.emission_enabled = true
_sphere_material.emission = emission_color
```

No procedural shader. No per-pixel computation. The material is configured once and stored. The properties describe what the surface should look like. The renderer executes that description without per-pixel variation.

The contrast marks the boundary between stored appearance and computed appearance. The sphere looks like something because its properties were assigned. The wall is something — a function made visible, computed fresh every frame from nothing but coordinates and arithmetic.

## From Stored State to Pure Function

The progression across the Noise sequence traces a disappearing act. Noise_One used `FastNoiseLite` — a CPU-side library with internal state, pre-configured noise types, cached computations:

```gdscript
# CPU noise: library manages state, caches configuration
var noise := FastNoiseLite.new()
noise.seed = randi()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
noise.frequency = 0.015
var value := noise.get_noise_2d(x, z)
```

Noise_Voxel stored the results in a three-dimensional boolean array — `_voxels[x][y][z]` — that persisted between frames. The noise was evaluated once and remembered. The voxel grid was a cache.

This map eliminates both. The hash function has no internal state. The fragment shader stores no results between frames. Every frame, every pixel recomputes its noise value from scratch. The output is identical each time because the hash is deterministic — same input, same output — but no memory preserves the result.

The computation is pure in the functional programming sense: no side effects, no mutation, no dependence on anything outside the function signature.

Input: coordinate. Output: color. Nothing else.

This is the E in QFEP made algorithmic — entropy not as disorder but as structured variation without stored state. The noise field does not exist between frames. It does not occupy memory. It is conjured from position and arithmetic at the moment of rendering and vanishes the instant the pixel is drawn.

The wall's texture has no persistence — only the appearance of persistence, because the function that generates it is deterministic.

Noise_Inside_Noise takes this further, using the output of one stateless function as the coordinate input to another, folding pure computation into recursive self-reference. The wall is the prerequisite: proof that noise can exist without memory, that randomness can be stateless, that a field can fill space without occupying it.

## Possible Artifacts

**octave_isolator** — A wall surface with six vertical strips, each displaying a single octave of the fBM stack in isolation. The first strip shows the base frequency at full amplitude. The second shows double frequency at half amplitude. Through to the sixth at 32x frequency and 1/64th amplitude. A seventh strip displays the sum. The learner sees each contribution before it merges, making the spectral decomposition of fBM spatial rather than abstract. Hovering over any strip highlights its frequency and amplitude values.

**hash_visualizer** — A grid overlay on the wall showing integer cell boundaries with the raw hash output at each corner rendered as a colored dot. The interpolated noise field fills the cells between dots. Makes the lattice structure visible beneath the smooth noise — the hidden scaffolding that the interpolation conceals. Toggling between different hash functions (polynomial, bitwise, sine-based) shows how the choice of hash affects the character of the output while preserving its statistical properties.

**gpu_vs_cpu_timer** — A split-screen wall where the left half renders noise via the fragment shader and the right half renders identical noise via CPU computation uploaded as a texture. A frame-time counter above each half displays the cost difference. At low resolutions the gap is negligible. As resolution increases, the GPU side holds steady while the CPU side degrades. The artifact does not argue that GPU noise is better — it demonstrates where and why the performance curves diverge, making the architectural advantage of parallel computation measurable rather than asserted.
