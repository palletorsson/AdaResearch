# Space folds when noise samples itself and the coordinate grid forgets where it started

In Noise_One, octaves stacked by amplitude — frequency doubled, amplitude halved, the sum converging toward organic complexity. In Noise_Columns, a Perlin field displaced vertices along normals. In Noise_Voxel, continuous fields hardened into discrete geometry through thresholding. In Noise_6_Wall, computation moved to the GPU. Every one of those maps treated noise as an endpoint: evaluate at a position, use the result. This map inverts that relationship. The result of one noise evaluation becomes the input position of the next. Noise feeds noise. The coordinate system itself warps, and what emerges is qualitatively different from anything summation can produce.

Domain warping is the technique. The name is precise: the domain — the input space, the coordinate grid — gets warped by a noise function before the final noise evaluation occurs. Simple noise maps a position to a value. Domain-warped noise maps a position to a distorted position, then maps that distorted position to a value. The distortion is the entire point.

## The Core Operation

The fundamental expression fits one line:

```gdscript
var value = noise.get_noise_2d(p.x + noise.get_noise_2d(p.x, p.y), p.y + noise.get_noise_2d(p.x, p.y))
```

Read it from the inside out. The inner `get_noise_2d(p.x, p.y)` evaluates noise at the original position. That value — a float, typically in the range [-1, 1] — offsets the coordinates fed to the outer noise call. The outer evaluation samples noise not at `p` but at `p + offset`, where the offset itself is noise-derived.

The noisePlanet2 shader on the noisesphere artifact performs this in GLSL on the GPU:

```glsl
vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale);
float time_offset = wrapped_time * noise_speed;
noise_input += vec2(time_offset, time_offset);
float noise_value = noise(noise_input);
vec3 displacement = NORMAL * noise_value * height_multiplier;
VERTEX = object_pos + displacement;
```

The shader's `noise_input` is a 2D coordinate derived from the 3D vertex position. The time offset slides this coordinate through the noise field, producing animation. The noise value displaces the vertex along its normal. This is a single-pass warp — noise modifies geometry — but the principle extends. Replace the time offset with a second noise evaluation and the coordinates themselves become noisy before the displacement fires.

A more explicit domain warp in GDScript separates the two layers:

```gdscript
var warp_noise := FastNoiseLite.new()
warp_noise.seed = 42
warp_noise.frequency = 0.01

var base_noise := FastNoiseLite.new()
base_noise.seed = 137
base_noise.frequency = 0.02

func domain_warp(p: Vector2, warp_strength: float) -> float:
    var offset_x = warp_noise.get_noise_2d(p.x, p.y) * warp_strength
    var offset_y = warp_noise.get_noise_2d(p.x + 100.0, p.y + 100.0) * warp_strength
    return base_noise.get_noise_2d(p.x + offset_x, p.y + offset_y)
```

Two separate noise instances. The warp noise generates offsets. The base noise consumes the warped coordinates. The `+ 100.0` shift on the second offset evaluation prevents x and y from receiving identical warps — without it, the distortion collapses onto a diagonal. Two different noise samples, two different coordinate offsets, one final evaluation.

The `warp_strength` parameter controls how far the coordinates drift. At zero, the result is plain base noise — the warp contributes nothing. At high values, the coordinate grid tears apart and the output becomes turbulent. Between those extremes lies the useful range: enough distortion to break the noise's self-similarity, not so much that the output becomes featureless chaos.

## Why Two Noise Instances

A question worth pausing on: why not reuse a single noise function for both the warp and the evaluation? The answer is correlation. If the same function warps the coordinates and then evaluates the result, the warp and the base are perfectly correlated — peaks in the warp correspond to peaks in the base, because both are the same function evaluated at the same (or nearby) coordinates. The output retains too much of the original structure. It swirls but does not surprise.

Separate seeds, separate frequencies. The warp noise operates at a different scale than the base noise, and their patterns share no structural relationship. This decorrelation produces the organic quality. Marble has veins because mineral deposits warp through geological pressure fields unrelated to the deposition pattern. Clouds fold because wind shear operates at scales independent of moisture condensation. Domain warping models this: two independent processes, one distorting the other's coordinate space.

```gdscript
# Correlated warp — same noise, muted result
func warp_correlated(p: Vector2, strength: float) -> float:
    var n := base_noise.get_noise_2d(p.x, p.y)
    return base_noise.get_noise_2d(p.x + n * strength, p.y + n * strength)

# Decorrelated warp — independent noise, organic result
func warp_decorrelated(p: Vector2, strength: float) -> float:
    var wx := warp_noise.get_noise_2d(p.x, p.y) * strength
    var wy := warp_noise.get_noise_2d(p.x + 100.0, p.y + 100.0) * strength
    return base_noise.get_noise_2d(p.x + wx, p.y + wy)
```

The correlated version produces smeared noise — recognizably the same field, pushed sideways. The decorrelated version produces turbulence. The visual difference is immediate. Decorrelation destroys the phase relationship between warp and base, so local maxima in the warp can coincide with any value in the base. The result is a pattern that no single noise pass can generate.

## Recursive Warping

One warp layer distorts. Two warp layers produce something that looks alive. The technique chains naturally:

```gdscript
func recursive_warp(p: Vector2, strength: float, iterations: int) -> float:
    var warped := p
    for i in iterations:
        var ox = warp_noise.get_noise_2d(warped.x + float(i) * 73.1, warped.y) * strength
        var oy = warp_noise.get_noise_2d(warped.x, warped.y + float(i) * 73.1) * strength
        warped = Vector2(warped.x + ox, warped.y + oy)
    return base_noise.get_noise_2d(warped.x, warped.y)
```

Each iteration offsets `warped` further from the original `p`. The first pass bends the grid. The second pass bends the bent grid. The third pass bends the bend of the bend. Each layer introduces folding at a new scale.

At one iteration, the output shows gentle swirls. At two, deep organic turbulence — the kind that appears in marble, in satellite images of Jupiter, in pour paintings. At three, the pattern becomes dense, high-frequency detail emerging from the compounding distortions. Beyond four iterations, returns diminish and computational cost doubles per pass.

The critical insight: additive octaves (fBM) combine noise values. Recursive warping composes noise functions. The distinction between addition and composition is the distinction between layering paint and folding dough. Paint layers accumulate — the tenth sits atop the ninth, each contributing independently. Folded dough generates structure through deformation — each fold creates new adjacencies that the next fold exploits. Two iterations do not produce twice the distortion of one. They produce the distortion of the distortion, and the resulting complexity grows faster than linearly.

The `float(i) * 73.1` offset in the loop deserves attention. Without distinct offsets, every iteration samples the same warp field at the same coordinates, producing the same displacement vector. The warp reinforces itself linearly — doubling strength, nothing more. The offset forces each iteration into a different neighborhood of the warp noise, so each pass contributes a structurally different deformation. The number 73.1 is arbitrary. Any sufficiently large, non-integer value works. The point is decorrelation between iterations, not the specific constant.

## The Noisesphere: Warping on Curved Surfaces

The noisesphere artifact wraps domain-warped noise onto a spherical mesh. The shader evaluates noise per-vertex using the object-space position as input:

```glsl
vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale);
float noise_value = noise(noise_input);
vec3 displacement = NORMAL * noise_value * height_multiplier;
VERTEX = object_pos + displacement;
```

The vertex displacement operates along normals. On a sphere, normals point radially outward — every displacement pushes the surface away from or toward the center. Where noise is positive, the surface bulges. Where negative, it dimples. The sphere remembers its topology while the surface forgets smoothness.

Curvature compounds the warp. On a flat plane, domain warping distorts a rectangular grid into swirls. On a sphere, the same warp interacts with surface curvature — distortions near the poles compress differently than at the equator because the mapping from 3D position to 2D noise input is nonlinear. The `noise_scale` of 48.39 produces fine-grained turbulence across the entire sphere. The `height_multiplier` of 0.2 keeps displacements subtle enough that the sphere remains recognizable. Increase it and the sphere tears into a sea urchin. Decrease it and the surface smooths toward its original geometry.

The sphere mesh uses high subdivision — 128 radial segments, 64 rings. This density matters. Domain warping displaces vertices, and the visual quality depends on having enough vertices to capture the noise field's detail. A low-poly sphere would alias the noise — displacement jumps between vertices with no intermediate surface, producing facets where the noise intended curves. High subdivision lets the displaced surface approximate the continuous field closely enough that the result reads as organic.

The `flip_faces = true` property in the noisesphere scene inverts the normals. The camera sits outside looking in, but the mesh was originally oriented for interior viewing — a common pattern for skybox spheres. The flip corrects the rendering so the displaced surface faces outward.

The dark_sphere sits alongside in the map layout, deliberately unwarped. Same topology — sphere. Same material class — emission-driven. No displacement. The contrast makes domain warping legible: one sphere pulses quietly in its original geometry while the other writhes under noise-driven deformation. The before and after, coexisting in the same space.

## Warp Strength as Expressive Parameter

The `warp_strength` multiplier controls the character of the output more than any other single parameter:

```gdscript
# Subtle warp — organic texture, gentle flow
var subtle = domain_warp(p, 20.0)

# Moderate warp — marble veins, cloud formations
var moderate = domain_warp(p, 80.0)

# Extreme warp — fully turbulent, structure dissolves
var extreme = domain_warp(p, 200.0)
```

At low strength, the base noise is barely displaced — the result looks like standard noise with a slight directional bias. At moderate strength, the coordinate grid bends enough that previously distant noise values become neighbors. Veins appear. Flow lines emerge. At extreme strength, the coordinate mapping becomes effectively random — any position might sample any part of the base noise, and the output resembles turbulence with no structure beyond local continuity.

The sweet spot depends on the ratio between warp strength and noise frequency. The ratio, not the absolute values, determines the visual character:

```gdscript
# Fine veins: high base frequency, moderate warp
base_noise.frequency = 0.05
var fine = domain_warp(p, 50.0)

# Broad swirls: low base frequency, moderate warp
base_noise.frequency = 0.005
var broad = domain_warp(p, 50.0)
```

Same warp strength. Different frequencies. Completely different textures. The warp bends the coordinate grid by the same physical amount in both cases, but high-frequency noise changes faster across that bent distance, producing tighter detail.

## Combining Domain Warping with Octaves

Domain warping and fractal Brownian motion are not mutually exclusive. The most expressive procedural textures layer both:

```gdscript
func warped_fbm(p: Vector2, warp_strength: float, octaves: int) -> float:
    # First: warp the coordinates
    var wx = warp_noise.get_noise_2d(p.x, p.y) * warp_strength
    var wy = warp_noise.get_noise_2d(p.x + 100.0, p.y + 100.0) * warp_strength
    var warped_p = Vector2(p.x + wx, p.y + wy)

    # Then: evaluate fBM at the warped position
    var value := 0.0
    var amplitude := 1.0
    var frequency := 1.0
    var freq_base := base_noise.frequency
    for i in octaves:
        base_noise.frequency = freq_base * frequency
        value += amplitude * base_noise.get_noise_2d(warped_p.x, warped_p.y)
        frequency *= 2.0
        amplitude *= 0.5
    base_noise.frequency = freq_base
    return value
```

The warp operates once on the coordinates. The fBM then layers multiple frequencies at the warped position. This produces organic textures with detail at multiple scales — the warp provides the large-scale flow while the octaves add fine-grained complexity within that flow. Lava, bark, weathered stone. The combination is what separates "procedural noise" from "procedural material."

Note the frequency management. The function saves `base_noise.frequency`, modifies it per octave, then restores it. Godot's `FastNoiseLite` stores frequency as an object property, not a per-call parameter. Mutating and restoring is fragile but necessary.

The alternative — warping each octave independently — is more expensive and produces a different result:

```gdscript
func warped_per_octave(p: Vector2, warp_strength: float, octaves: int) -> float:
    var value := 0.0
    var amplitude := 1.0
    var frequency := 1.0
    for i in octaves:
        var scaled_p = p * frequency
        var wx = warp_noise.get_noise_2d(scaled_p.x, scaled_p.y) * warp_strength
        var wy = warp_noise.get_noise_2d(scaled_p.x + 100.0, scaled_p.y + 100.0) * warp_strength
        var warped = Vector2(scaled_p.x + wx, scaled_p.y + wy)
        value += amplitude * base_noise.get_noise_2d(warped.x, warped.y)
        frequency *= 2.0
        amplitude *= 0.5
    return value
```

Each octave warps at its own scale. The interactions between warp layers and frequency layers compound. The visual is denser, almost chaotic. Sometimes that density is the goal. Usually the single-warp-then-fBM approach provides enough control for expressive texturing.

## Irreversibility and Information

Domain warping is a deterministic function. Given the same seeds, frequencies, and coordinates, the output is identical every time. The function is reproducible. It is not, however, practically invertible. Given a domain-warped noise value at position `p`, recovering `p` from the output requires solving a nonlinear system — which noise seed produced which offset, which offset led to which sample, which sample produced this value. The forward pass is trivial. The inverse is computationally intractable.

This irreversibility is structural, not incidental. The warp scatters coordinate information across the noise field. Adjacent input points can map to distant sample points if the warp pushes them apart. Distant input points can map to nearby sample points if the warp pushes them together. The local gradient of the warped field depends on both the base noise gradient and the warp noise gradient and their interaction — a chain rule that compounds uncertainty at every evaluation.

The information is not destroyed — determinism guarantees it exists — but it is scattered beyond practical recovery. Looking at the output reveals nothing about the input coordinates that produced it.

Nature operates on the same principle. Wood grain records growth under environmental stress — a domain warp of the radial growth field by wind, gravity, and soil moisture. The pattern is deterministic (given identical conditions, identical grain). The pattern is also illegible — given the grain, the conditions cannot be recovered. Domain warping models this: structured transformation whose history is embedded in the output but unreadable from it.

The noisesphere embodies this. Its surface displacement is entirely determined by the shader's noise function, seed, scale, and the vertex positions. Every frame, the same function produces the same distorted surface (modulo the time animation). Yet looking at the sphere, the coordinate grid that produced the displacement is invisible. The sphere shows the result of warping. The warp itself is gone.

## From Coordinates to Textures

The practical output of domain warping is texture generation. The noisesphere uses the technique for vertex displacement, but the same mathematics drives color:

```glsl
float hue_shift = mod(TIME * hue_shift_speed, 1.0);
vec3 hsv_color = vec3(hue_shift, 1.0, 1.0);
vec3 rainbow_color = hsv2rgb(hsv_color);
ALBEDO = rainbow_color * noise_value;
EMISSION = rainbow_color * noise_value * 0.5;
```

The `noise_value` modulates both albedo and emission. Where noise is high, the surface is bright. Where low, dark. The hue rotates with time, sliding the color spectrum across the surface. Noise-modulated brightness creates visual turbulence — not through color variation but through light intensity shaped by the warped field.

In GDScript, domain-warped noise maps to material properties the same way:

```gdscript
func generate_texture(width: int, height: int, warp_strength: float) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    for y in height:
        for x in width:
            var p = Vector2(float(x), float(y))
            var value = domain_warp(p, warp_strength)
            var mapped = (value + 1.0) * 0.5  # Remap [-1,1] to [0,1]
            var color = Color(mapped, mapped, mapped, 1.0)
            img.set_pixel(x, y, color)
    return img
```

The `(value + 1.0) * 0.5` remap is the same technique used in Noise_6_Wall for mapping noise output to displayable range. Noise returns values centered around zero. Pixels expect values between zero and one. The shift-and-scale operation bridges the two conventions.

A CPU-side texture generator like this runs per-pixel in a double loop — sequential, slow for large resolutions. The noisesphere shader performs the equivalent operation in parallel across all fragments. The mathematical content is identical. The execution model is inverted: CPU noise iterates one pixel at a time, GPU noise evaluates all pixels simultaneously.

For real-time applications — animated materials, moving geometry — the shader path is the only viable approach. For offline baking, the CPU path works and avoids shader complexity. Domain warping does not care which processor runs it.

This map sits at the boundary between CPU noise (Noise_Columns, Noise_Voxel) and GPU noise (Noise_6_Wall). Domain warping works on both, but the technique reaches its expressive potential on the GPU, where recursive warp passes execute at interactive framerates across millions of fragments. The noisesphere demonstrates this: real-time vertex displacement, animating continuously, the hash-based noise function from Noise_6_Wall providing the underlying field. Noise_Space_10 carries this further — full parameter exploration where every control surfaces domain warp behavior in real time.

## Possible Artifacts

**warp_grid_visualizer** — Renders a visible coordinate grid, then applies one pass of domain warping to displace the grid intersections, and optionally a second pass. The learner sees the grid go from rectilinear to gently curved to deeply folded. The gap identified in the intent: the step-by-step coordinate distortion that makes recursive warping legible rather than magical. Each pass draws in a different color so the progression from ordered to turbulent is traceable. Toggle between one, two, and three iterations to see compounding distortion.

**warp_strength_slider** — A planar surface textured by domain-warped noise with a real-time adjustable warp strength parameter. The learner drags the strength from zero (plain noise) through moderate (marble) to extreme (turbulence) and watches the texture transition continuously. A frequency slider alongside exposes the ratio between warp strength and noise frequency as the key expressive control.

**split_sphere_comparison** — A sphere divided into hemispheres: one side shows standard fBM displacement, the other shows domain-warped noise displacement with identical base parameters. The seam between them makes the qualitative difference between additive layering and coordinate composition visible on a single surface. Rotates slowly so the learner can observe both hemispheres and the transition at the boundary.
