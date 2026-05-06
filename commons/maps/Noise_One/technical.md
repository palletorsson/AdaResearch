# Layer frequencies onto a torus until smoothness fractures into coastline

Noise_Columns showed what a single coherent field does to geometry — vertices displaced by one Perlin function, melting columns like Bernini marble under a continuous force. The result was smooth. Too smooth. A single frequency of noise produces undulation, not texture. One sine wave is a hum, not a chord.

The natural world does not hum. Mountains have ridges that have rocks that have grains. Clouds have billows that have wisps that have filaments. Detail nests inside detail at every scale. No single noise frequency can produce this. The technique that bridges the gap between smooth displacement and organic complexity is fractal summation — stacking octaves of noise with increasing frequency and decreasing amplitude until the sum converges toward something that looks grown rather than computed.

This map introduces that technique. The noiselayers artifact decomposes the stack, displaying each octave independently before combining them. The noisetorus wraps the composite field onto a closed surface, testing whether the summation holds across topology changes. Together they make visible the principle that governs procedural terrain, cloud rendering, bark textures, and every natural surface in every game that bothers to fake nature convincingly.

## Coherent Noise as Raw Material

A coherent noise function maps any point in space to a scalar value. "Coherent" means continuous — nearby inputs produce nearby outputs. Sample two points one millimeter apart and get two values that differ by a whisper. Sample two points one meter apart and get values that may diverge significantly. The function is smooth at small scales and varied at large ones.

Godot provides `FastNoiseLite` as its coherent noise primitive. The essential configuration:

```gdscript
var noise := FastNoiseLite.new()
noise.seed = randi()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
noise.frequency = 0.015
```

`frequency` controls spatial density. Low frequency means broad, rolling variation — hills. High frequency means tight, rapid variation — gravel. The seed guarantees reproducibility: same seed, same landscape. Different seed, different landscape, same statistical character. This is the E term in QFEP made operational — entropy is not chaos but structured variation, and the seed is the key that selects which particular variation from an infinite family.

A single noise sample at a position returns one float:

```gdscript
var height: float = noise.get_noise_2d(world_x, world_z)
```

That float ranges roughly from -1 to 1. Multiply by an amplitude to control vertical extent. Map it to a vertex position and the flat grid lifts into terrain. But terrain made from one frequency looks like a sine wave draped over a plane — all features the same size, all curves the same radius. The learner adjusting frequency in the noiselayers artifact discovers this directly: crank frequency up and the surface ripples faster but never develops the nested detail of real ground.

## The Octave Principle

Nature does not operate at one frequency. A mountain range has a wavelength of kilometers. The ridges on those mountains have wavelengths of hundreds of meters. The rocks on those ridges have wavelengths of centimeters. Each scale of detail is roughly half the wavelength and half the intensity of the one above it. This is scale invariance — the statistical property that a coastline photographed from orbit and a coastline photographed from a kayak exhibit the same degree of roughness.

The computational analog: sample the same noise function at progressively doubled frequencies, each time halving the amplitude, and sum the results.

```gdscript
func fbm(position: Vector2, octaves: int, lacunarity: float, persistence: float) -> float:
    var value := 0.0
    var frequency := 1.0
    var amplitude := 1.0
    for i in range(octaves):
        value += amplitude * noise.get_noise_2d(
            position.x * frequency, position.y * frequency
        )
        frequency *= lacunarity
        amplitude *= persistence
    return value
```

Five lines of logic. Three control parameters. The loop is fractal Brownian motion — fBM — and it is the single most important technique in procedural generation. Every subsequent map in the Noise sequence builds on this loop. Every terrain engine, every cloud shader, every procedural bark texture runs some variant of it.

`lacunarity` controls frequency scaling per octave. The canonical value is 2.0 — each octave doubles the frequency. `persistence` controls amplitude decay. The canonical value is 0.5 — each octave halves the amplitude. These defaults produce a 1/f power spectrum, matching the distribution found in mountain profiles, heartbeat intervals, river networks, and economic fluctuations. The F term holds structure; the E term injects variation; the fBM loop negotiates between them at every scale simultaneously.

## Anatomy of Summation

The noiselayers artifact makes the summation visible by rendering each octave as a separate visual layer before compositing. Consider four octaves with standard parameters:

```gdscript
# Octave 0: frequency = 1.0, amplitude = 1.0
# Broad terrain — mountains and valleys
var octave_0 := noise.get_noise_2d(x * 1.0, z * 1.0) * 1.0

# Octave 1: frequency = 2.0, amplitude = 0.5
# Medium features — ridges, slopes
var octave_1 := noise.get_noise_2d(x * 2.0, z * 2.0) * 0.5

# Octave 2: frequency = 4.0, amplitude = 0.25
# Small features — boulders, outcrops
var octave_2 := noise.get_noise_2d(x * 4.0, z * 4.0) * 0.25

# Octave 3: frequency = 8.0, amplitude = 0.125
# Surface texture — pebbles, grain
var octave_3 := noise.get_noise_2d(x * 8.0, z * 8.0) * 0.125

var combined := octave_0 + octave_1 + octave_2 + octave_3
```

Octave 0 dominates. It sets the silhouette — where mountains rise and valleys fall. Octave 1 modulates that silhouette, adding ridges and saddles that the broad stroke missed. Octave 2 adds boulders to the ridges. Octave 3 textures the boulders. Each octave contributes half as much energy as the previous one, so the sum converges. Add a hundred more octaves and the visual difference from four becomes imperceptible — the amplitude is already below a thousandth of the original.

The convergence is fast. The total amplitude across N octaves with persistence 0.5 approaches a geometric sum:

```
total_amplitude = 1.0 + 0.5 + 0.25 + 0.125 + ... = 2.0 (limit)
```

Four octaves capture 1.875 of that 2.0 — 93.75% of the energy. Six octaves capture 98.4%. Beyond eight octaves, the added detail is subpixel. Diminishing returns are built into the mathematics. The octave count parameter is less "how detailed" and more "where to stop bothering."

The noiselayers artifact in this map separates these contributions spatially. The learner sees octave 0 as a gentle rolling surface, octave 1 as a faster ripple overlaid on it, octave 2 as fine corrugation, octave 3 as near-invisible grain. Then the composite view stacks them. The moment of recognition: complexity is not one complicated thing but many simple things at different scales, summed.

## FastNoiseLite and Built-in Fractals

Godot's `FastNoiseLite` handles the fBM loop internally through its fractal settings:

```gdscript
noise.fractal_type = FastNoiseLite.FRACTAL_FBM
noise.fractal_octaves = 6
noise.fractal_lacunarity = 2.0
noise.fractal_gain = 0.5
```

`fractal_gain` is persistence by another name. Setting `fractal_octaves = 6` runs six iterations of the frequency-doubling, amplitude-halving loop inside a single `get_noise_2d()` call. This is convenient but opaque — the learner gets the result without seeing the layers. The noiselayers artifact exists precisely to crack open this black box.

The noiselayers script configures three separate `FastNoiseLite` instances, each representing a frequency band:

```gdscript
@export_group("Low Frequency (Base Terrain)")
@export var low_freq_noise: FastNoiseLite
@export var low_freq_scale: float = 0.015
@export var low_freq_amplitude: float = 12.0
@export var low_freq_octaves: int = 6

@export_group("Medium Frequency (Mid-scale Features)")
@export var med_freq_noise: FastNoiseLite
@export var med_freq_scale: float = 0.04
@export var med_freq_amplitude: float = 6.0
@export var med_freq_octaves: int = 4

@export_group("High Frequency (Surface Detail)")
@export var high_freq_noise: FastNoiseLite
@export var high_freq_scale: float = 0.08
@export var high_freq_amplitude: float = 1.5
@export var high_freq_octaves: int = 3
```

Three bands rather than individual octaves. The low band uses six internal octaves at frequency 0.015 — extremely broad features, the continental shelf of the terrain. The medium band uses four octaves at frequency 0.04 with FRACTAL_RIDGED type, producing ridge-like features that break the smooth undulation. The high band uses three octaves at frequency 0.08 — surface roughness, the pebbled skin of the landscape. Each band is itself an fBM sum. The three bands sum into the final height:

```gdscript
var low := low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
var med := med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
var high := high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
var combined_height := low + med + high
```

This is fBM at two levels — fractals within fractals. The medium band uses `FRACTAL_RIDGED` instead of `FRACTAL_FBM`, which inverts the noise before summation, producing sharp peaks where standard fBM produces smooth hills. Ridged noise is how mountain spines emerge from rolling terrain. The learner adjusting the medium band's amplitude watches ridges carve themselves into an otherwise gentle surface.

## The Torus as Topological Test

The noisetorus wraps the composite noise field onto a torus — a closed surface with no edges. This is not decoration. A flat terrain grid has boundaries. At the edges, the noise field simply stops. The torus eliminates edges entirely: walk in any direction and return to where you started. If the noise tiles correctly, the surface is seamless. If it does not, a visible seam betrays the wrapping.

A torus is parameterized by two angles — one around the major ring, one around the tube:

```gdscript
var torus_mesh := TorusMesh.new()
torus_mesh.inner_radius = 0.3
torus_mesh.outer_radius = 0.5
torus_mesh.rings = 16
torus_mesh.ring_segments = 8
```

Mapping noise onto a torus means sampling the noise function using the torus surface coordinates. The topological question: can a 2D noise function tile seamlessly across both angular dimensions? Perlin and Simplex noise are defined on an infinite plane. Wrapping that plane onto a torus introduces potential discontinuities at the seam where 0 degrees meets 360 degrees. The standard solution maps the two torus angles to four dimensions of noise — a 4D noise function sampled on a circle in each pair of dimensions:

```gdscript
# Map torus angles to 4D noise coordinates for seamless wrapping
var angle_major := float(ring) / rings * TAU
var angle_minor := float(seg) / ring_segments * TAU
var nx := cos(angle_major) * major_radius
var ny := sin(angle_major) * major_radius
var nz := cos(angle_minor) * minor_radius
var nw := sin(angle_minor) * minor_radius
var displacement := noise_4d(nx, ny, nz, nw)
```

The 4D trick works because a circle embedded in 2D has no seam — the point at angle 0 and the point at angle TAU are the same point, and cosine and sine ensure the noise coordinates are identical there. Two circles in 4D space cover both torus dimensions. The learner rotating the torus in the map sees a surface with no visible join. This seamlessness is not free — it costs two extra dimensions of computation. The phi term in QFEP captures this: change (the wrapping) requires energy (the dimensional overhead), and the result is a new equilibrium (a seamless surface) that could not exist in the lower-dimensional representation.

## Persistence and Lacunarity as Creative Controls

The canonical values — lacunarity 2.0, persistence 0.5 — produce the 1/f spectrum. Deviating from these defaults produces distinctly different character.

High persistence (0.7 or above) means high-frequency octaves retain more energy. The surface becomes spikier, more aggressive — every small detail shouts as loud as the broad strokes. The result looks eroded, jagged, lunar. Useful for alien landscapes or corroded metal.

Low persistence (0.3 or below) means high-frequency octaves are nearly silent. The surface is dominated by the base frequency — gentle, rolling, almost sinusoidal. Useful for sand dunes, calm ocean surfaces, soft organic forms.

```gdscript
# High persistence: aggressive, detailed terrain
noise.fractal_gain = 0.7  # High-frequency octaves retain 70% amplitude

# Low persistence: gentle, smooth terrain
noise.fractal_gain = 0.3  # High-frequency octaves retain only 30% amplitude
```

Lacunarity controls the frequency gap between octaves. At 2.0, each octave is exactly double the previous frequency — a clean musical octave. At 3.0, the gaps widen — fewer intermediate frequencies, more jump between scales. The texture becomes more discontinuous, with broad smooth areas punctuated by sudden fine detail. At 1.5, the octaves crowd together — overlapping frequency ranges, a muddier but denser texture.

The noiselayers artifact exposes these parameters as interactive controls. The learner drags persistence and watches the terrain roughen or soften in real time. This is the critical pedagogical moment: "natural-looking" is not a fixed property of noise. It is a tunable output of two scalar parameters. The same noise function, the same seed, the same octave count — change persistence from 0.5 to 0.7 and lush hills become cracked badlands. The E term in QFEP does not prescribe a specific entropy level. It describes the system's capacity for variation, and persistence is the dial.

## Noise Types and Their Fractal Behavior

Not all noise functions respond to octave stacking identically. The noiselayers artifact uses different `FastNoiseLite` types across its three bands:

```gdscript
low_freq_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
med_freq_noise.noise_type = FastNoiseLite.TYPE_PERLIN
high_freq_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
```

Simplex noise is computationally cheaper than Perlin in higher dimensions and suffers fewer directional artifacts — Perlin noise on a regular grid produces faint axis-aligned patterns visible at shallow viewing angles. Simplex uses a simplex grid (triangles in 2D, tetrahedra in 3D) that distributes these artifacts more evenly. For the base terrain layer, where the surface is viewed from many angles, Simplex avoids the subtle grid bias.

The medium band uses Perlin with `FRACTAL_RIDGED`. Ridged noise takes the absolute value of the noise function before summation, folding negative values upward:

```gdscript
# Standard fBM octave contribution:
value += amplitude * noise(position * frequency)

# Ridged octave contribution:
value += amplitude * (1.0 - abs(noise(position * frequency)))
```

The `abs()` creates sharp creases where the original function crossed zero. The `1.0 - abs(...)` inverts those creases into peaks. Stacked across octaves, ridged noise produces mountain-spine topology — sharp ridgelines with valleys that curve smoothly away on both sides. The noisewall artifact in this map's companion scripts uses the same principle applied to a vertical surface, where ridged noise at the medium frequency creates convincing stone-block edges from pure mathematics.

## From Summation to Surface

The generate_height_field function in the noiselayers artifact performs the full pipeline — three noise bands sampled, summed, optionally eroded:

```gdscript
func generate_height_field() -> Array:
    var height_field := []
    for z in range(terrain_size + 1):
        height_field.append([])
        for x in range(terrain_size + 1):
            var world_x := (x - terrain_size * 0.5) * terrain_scale
            var world_z := (z - terrain_size * 0.5) * terrain_scale
            var low := low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
            var med := med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
            var high := high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
            height_field[z].append(low + med + high)
    return height_field
```

The height field is a 2D array of floats. Each entry is the summed contribution of three noise bands at one grid point. The nested loop visits every vertex position, samples three noise functions, and stores the sum. This array then drives vertex displacement in the mesh generation pass — each `height_field[z][x]` becomes the y-component of a vertex position:

```gdscript
vertices[vertex_index] = Vector3(world_x, height_field[z][x] * height_scale, world_z)
```

One scalar per vertex. Three noise evaluations per scalar. The entire terrain surface is encoded in the multiplication of frequency and amplitude across octaves. There is no modeling, no sculpting, no hand placement. The landscape emerges from parameters.

The erosion pass that follows applies a smoothing constraint to steep slopes — a post-process that blends the raw noise output toward physical plausibility:

```gdscript
var slope := sqrt(height_diff_x * height_diff_x + height_diff_z * height_diff_z)
if slope > 0.5:
    var erosion_amount := (slope - 0.5) * erosion_strength * 0.1
    height_field[z][x] -= erosion_amount
```

Steep gradients lose height. Gentle gradients keep it. Over three iterations, the terrain softens its sharpest peaks while preserving the broad topology. This is the F term asserting itself after the E term has spoken — structure (walkable, physically plausible terrain) constraining entropy (the raw noise output) into a form that serves the system's purpose. The balance between these two forces is what Noise_Space_10 will later expose as the full QFEP parameter space. Here, in Noise_One, the learner encounters it as a simple conditional: slopes above a threshold get shaved down.

This is the promise of procedural generation and the reason the Noise sequence exists within Ada Research: the F term defines the structural rules (frequency ratios, amplitude decay), the E term supplies the raw entropy (the noise function seeded by randomness), and their interaction produces form that no one designed but everyone recognizes.

## Possible Artifacts

**octave_audio_synth** — Generates a sine tone for each noise octave, with frequency matching the visual octave frequency and amplitude matching the visual amplitude. Plays each tone in isolation, then the chord of all tones summed. The learner hears that fBM in audio is additive synthesis — the same principle that builds terrain builds timbre. Adjusting persistence changes the harmonic balance from mellow (low persistence, fundamental-dominant) to bright (high persistence, overtone-heavy), connecting visual texture to auditory texture through shared mathematics.

**persistence_landscape** — A split-view artifact showing three identical noise seeds rendered simultaneously at persistence values of 0.3, 0.5, and 0.7. The learner sees the same topological structure — same peaks, same valleys — with radically different surface character. Demonstrates that persistence does not change where features are, only how much small-scale detail they carry. Useful for building intuition about the persistence parameter before Noise_Space_10 opens full parameter exploration.

**seamless_torus_inspector** — Renders the torus with a color-mapped seam indicator: vertices near the wrap boundary glow proportionally to their distance from the seam line. When using naive 2D noise mapping, the seam lights up. Switching to 4D circular embedding, the glow vanishes — no vertex is closer to a "seam" than any other because the seam does not exist. Makes the topological argument for higher-dimensional noise sampling visual and immediate.
