# Trace the grid lines inside gradient noise until the geometry of the lattice becomes the geometry of the output

Noise_One introduced coherent noise as raw material — a function that maps spatial coordinates to smooth, continuous values. Seven maps later, the learner has layered octaves, warped domains, navigated ten-dimensional parameter space. Through all of it, the noise function itself remained a black box. `FastNoiseLite.TYPE_SIMPLEX` or `FastNoiseLite.TYPE_PERLIN` — a dropdown choice, a configuration flag, apparently interchangeable.

This map opens the box. Inside are two algorithms separated by eighteen years of refinement, built on different geometric scaffolding, leaving different fingerprints on every surface they generate. The comparison is not academic. The artifacts of each algorithm propagate through every octave, every terrain, every texture the sequence has produced. Understanding the lattice is understanding the grain of the world.

## The Gradient Noise Principle

Both Perlin and Simplex noise share a core mechanism: assign random gradient vectors to points on a lattice, then interpolate between them. The word "gradient" here means direction — a unit vector at each lattice point that defines which way the noise function slopes at that location. The output at any arbitrary point in space is computed by measuring how that point relates to the surrounding lattice gradients.

The algorithm, stripped to its skeleton:

1. Determine which lattice cell contains the input point.
2. Compute the distance vector from each cell corner to the input point.
3. Dot each distance vector with the gradient vector assigned to that corner.
4. Interpolate the dot products to produce a single scalar output.

```gdscript
# Conceptual gradient noise in 2D — the shared principle
func gradient_noise_2d(x: float, y: float) -> float:
    # Step 1: Find the lattice cell
    var x0 := int(floor(x))
    var y0 := int(floor(y))

    # Step 2: Fractional position within the cell
    var dx := x - x0
    var dy := y - y0

    # Step 3: Gradient dot products at each corner
    var g00 := dot(gradient_at(x0, y0), Vector2(dx, dy))
    var g10 := dot(gradient_at(x0 + 1, y0), Vector2(dx - 1.0, dy))
    var g01 := dot(gradient_at(x0, y0 + 1), Vector2(dx, dy - 1.0))
    var g11 := dot(gradient_at(x0 + 1, y0 + 1), Vector2(dx - 1.0, dy - 1.0))

    # Step 4: Interpolate
    var sx := smoothstep_fade(dx)
    var sy := smoothstep_fade(dy)
    var nx0 := lerp(g00, g10, sx)
    var nx1 := lerp(g01, g11, sx)
    return lerp(nx0, nx1, sy)
```

The gradient vectors come from a hash function applied to the lattice coordinates — deterministic, repeatable, pseudo-random. Same coordinates always produce the same gradient. The dot product measures alignment: when the distance vector points the same direction as the gradient, the result is positive; perpendicular yields zero; opposing yields negative. This creates smooth variation that crosses zero near the lattice points and peaks between them. The interpolation blends these contributions into a continuous field.

Every noise map in the sequence has relied on this mechanism. The difference between Perlin and Simplex is not the principle.

It is the lattice.

## Perlin Noise: The Hypercubic Grid

Ken Perlin's original algorithm (1983, developed for Tron) uses a rectangular grid — squares in 2D, cubes in 3D, hypercubes in higher dimensions. The input point falls inside one grid cell, and the algorithm evaluates gradient dot products at every corner of that cell.

In two dimensions, a square has four corners. Four gradient lookups, four dot products, two interpolation passes (one along x, one along y). In three dimensions, a cube has eight corners. Eight lookups, eight dot products, three interpolation passes.

In N dimensions: 2^N corners. The cost grows exponentially with dimensionality.

The `perlin_noise` display is placed in this room as `perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front`. Its field (`NoiseVisualizer.gd`) is configured at build:

```gdscript
noise_generator = FastNoiseLite.new()
current_seed = seed_value if seed_value >= 0 else randi()
noise_generator.seed = current_seed
noise_generator.noise_type = _noise_type_for(generator)
noise_generator.fractal_octaves = octaves
noise_generator.frequency = 0.05
noise_generator.fractal_gain = persistence
```

Four octaves, gain 0.5, base frequency 0.05 multiplied by the panel's frequency, seed 20260910: an 8×8 field of half-metre cubes each lifted to its sample (`readout=relief`), not a flat plane and not a single octave. The basis comes from `_noise_type_for`, whose default branch is simplex — which is why, until 2026-09-10, this display drew simplex noise under the Perlin name: no placement had ever passed `generator:perlin`. Viewed at a shallow angle, faint directional bias may become visible in the Perlin field: features aligning with the x and z axes.

Not a grid of squares — Perlin is more sophisticated than that — but a statistical preference for horizontal and vertical orientations. Ridges run slightly more often along axes than along diagonals.

This bias is the cubic lattice leaking through the interpolation. The smoothstep function — Perlin's original used 3t^2 - 2t^3, later improved to 6t^5 - 15t^4 + 10t^3 — blends the corner contributions along each axis independently. The axes are special directions in the algorithm's geometry.

No amount of interpolation smoothness can fully erase the fact that the underlying structure has preferred directions.

```gdscript
# Perlin's improved fade function (2002 revision)
func improved_fade(t: float) -> float:
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
```

The improved fade curve has zero first and second derivatives at 0 and 1, eliminating the visible grid lines that plagued the original 1983 implementation. But it still interpolates along axis-aligned directions. The geometry of the cube is baked into the algorithm's structure, and the fade function can smooth its edges without changing its fundamental shape.

The `perlin_noise_terrain` artifact behind the pair renders the same kind of sampling as a walkable height field; it is secondary here. The 100-metre `noise_terrain` that used to fill this room's basin was removed from the hall on 2026-09-10 when the basin was floored, and no claim about a terrain-versus-terrain comparison is made in this room any more.

## Simplex Noise: The Triangular Grid

Eighteen years after Perlin noise, Ken Perlin published Simplex noise (2001). The core algorithm is the same — gradient vectors at lattice points, dot products with distance vectors, smooth interpolation. The lattice is different. Instead of hypercubes, Simplex noise uses simplices: the simplest possible polygon in each dimension. A triangle in 2D. A tetrahedron in 3D. An N-simplex in N dimensions.

A triangle has three corners. A tetrahedron has four. An N-simplex has N+1 vertices.

Compare: a square has 4 corners (versus 3), a cube has 8 (versus 4), a 4D hypercube has 16 (versus 5). The computational savings grow with dimensionality. In 2D, Simplex evaluates 3 gradient contributions instead of 4. In 3D, 4 instead of 8. In 4D — relevant for the seamless torus wrapping technique from Noise_One — 5 instead of 16.

The `simplex_noise` display is placed as `simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front`. Its field (`SimplexVisualizer.gd`) is configured the same way, with the basis fixed:

```gdscript
noise_generator = FastNoiseLite.new()
current_seed = seed_value if seed_value >= 0 else randi()
noise_generator.seed = current_seed
noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
noise_generator.fractal_octaves = octaves
noise_generator.frequency = 0.05  # Equivalent to period = 20.0
noise_generator.fractal_gain = persistence
```

Same seed. Same base frequency, octaves and gain. Same field size and the same shared colour ramp. Different noise type — and that is the only declared difference between the two displays.

The expected visual difference: in the simplex field the directional bias is gone. Features distribute their orientations evenly, because the simplicial lattice has no axis-aligned edges; the triangle grid in 2D has edges at 0, 60 and 120 degrees — three equally spaced orientations rather than two perpendicular ones. Whether the difference is visible at four octaves and half-metre cubes is a question for the dials, not a promise.

The skewing transform is the key operation. Regular triangles do not tile Cartesian space conveniently, but skewed squares — compressed along one diagonal until each square splits into two right triangles — do. Simplex noise skews input coordinates to locate which simplex cell the point falls in, then unskews to compute distance vectors:

```gdscript
# 2D skewing transform (conceptual)
var SKEW_2D := (sqrt(3.0) - 1.0) / 2.0  # ≈ 0.366
var UNSKEW_2D := (3.0 - sqrt(3.0)) / 6.0  # ≈ 0.211

# Skew input space to find simplex cell
var s := (x + y) * SKEW_2D
var i := floor(x + s)
var j := floor(y + s)

# Unskew cell origin back to (x, y) space
var t := (i + j) * UNSKEW_2D
var x0 := x - (i - t)
var y0 := y - (j - t)
```

The skew constant for 2D is (sqrt(3) - 1) / 2 — derived from the geometry of equilateral triangles. In 3D it changes. In 4D it changes again. Each dimension has its own skew factor determined by the simplex geometry of that dimension. The unskew reverses the transform to compute distances in the original coordinate space.

The F term in QFEP is the lattice geometry itself — fixed, structural, determining the pattern of evaluation points. The E term is the gradient assignment — random, entropic, different for every seed. The algorithm's output lives at the intersection of structure and randomness.

## The Cost of Corners

The exponential growth of 2^N corners in Perlin noise is not merely a performance concern. Each corner contributes to the interpolation, and the interpolation happens along N axes sequentially. This introduces subtle dependencies between dimensions that manifest as axis-aligned artifacts.

Simplex noise's N+1 corners per cell mean the contribution function changes shape. Instead of bilinear or trilinear interpolation along axes, Simplex uses a radial falloff kernel per corner:

```gdscript
# Simplex contribution from one corner (conceptual)
func corner_contribution(dist: Vector2, gradient: Vector2) -> float:
    var t := 0.5 - dist.x * dist.x - dist.y * dist.y
    if t < 0.0:
        return 0.0
    t *= t
    return t * t * dist.dot(gradient)
```

The kernel `(0.5 - |d|^2)^4` is radially symmetric. It drops to zero at a fixed radius from the corner, meaning each corner only influences a circular (or spherical) region around it. No axis-aligned interpolation. No sequential blending along x then y then z. Each corner's contribution is independent, isotropic, and local.

The sum of three such contributions in 2D (or four in 3D) produces the final value.

This locality is why Simplex noise has no directional artifacts. The influence of each gradient is a smooth bump centered on the lattice point, circular in shape, with no preferred direction. The learner examining the `simplex_noise` artifact and rotating the view finds no angle from which a hidden grid reveals itself.

The lattice exists — it must, because the gradients need anchor points — but the output erases it.

## Comparing the Fields

The map places `simplex_noise` at (3,7) and `perlin_noise` at (8,7), either side of a one-metre aisle, configured identically except for the basis. The comparison is the pedagogical core of the map. Both fields sample their generator with the same line, at the same coordinates, half a metre apart:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

(The Perlin visualizer's version adds `animation_offset` to both coordinates; it is zero unless the animation is running, and the panel does not start it.) Each cube's colour comes from the shared ramp, and each cube's height from the sample; nothing about the sampling, the spacing, the height or the colour belongs to either basis.

Each display carries a panel in front of it — FREQ and OCTAVES sliders, REGEN and REPLAY — and a readout above the panel that prints the basis **read back from the generator** (`basis_name()` matches on `noise_generator.noise_type`, not on the scene's name), the seed, the octaves, the frequency, the gain, and the field's value at (0, 0) and (2.5, 2.5). REGEN chooses a new seed and records it; REPLAY restores the declared one. The two readouts differ in their first word and their two values and in nothing else, and that sentence is what the visitor is asked to check.

The same seed in two bases is not the same field twice: the integer puts each generator into a repeatable state, but the states are unrelated, so no feature on one side has a partner on the other. What can be compared is character. The lattice signature is clearest with a single octave; with six octaves the detail buries it, which is why both OCTAVES sliders exist.

The Q term operates here: quality is the degree to which the output serves its purpose. If the purpose is terrain that looks natural from any viewing angle, Simplex noise has higher Q — fewer artifacts, less visible machinery. If the purpose is terrain that tiles along axis-aligned boundaries, Perlin noise may have higher Q — its grid alignment makes seamless tiling along axes more straightforward.

The algorithm is not neutral. Its internal geometry shapes its fitness for different applications.

## Historical Context as Design Lesson

Perlin noise earned Ken Perlin a Technical Achievement Academy Award in 1997 — recognition for the technique behind the visual effects of Tron (1982), which became the foundation of procedural texture generation for two decades. Simplex noise arrived in 2001 as Perlin's own refinement.

The evolution teaches something that raw performance comparisons miss. Perlin noise was not wrong. It was a solution shaped by the constraints of 1983. The cubic grid is the simplest lattice to implement on hardware that thinks in rectangular arrays. The axis-aligned interpolation maps directly to the sequential computation model of early processors.

The artifacts are not bugs — they are consequences of a design that prioritized implementability on the hardware of its era.

Simplex noise introduces geometric sophistication — the skewing transform, the simplicial decomposition, the radial kernel — to eliminate those consequences. The cost is implementation complexity and (historically) patent restrictions that limited adoption until 2022.

The `configurable_portal` artifact connects to other sequences as a crossroads, positioning this comparison as the moment where the learner recognizes that procedural generation is not one technique but a lineage of refinements, each carrying the marks of its historical moment.

The `dark_sphere` persists through the comparison, algorithm-agnostic, the same in both halves of the map. It is the constant. The noise terrains are the variables. The sphere does not care which algorithm generated the ground beneath it. The learner walks the ground and discovers the difference by observation — the same method by which Perlin himself identified the artifacts that motivated Simplex.

## Dimensionality and the Scaling Argument

The performance difference between the two algorithms grows with dimensionality. In 2D the difference is modest: 3 corner evaluations versus 4, a 25% reduction. In 3D: 4 versus 8, a 50% reduction. In 4D: 5 versus 16, a 69% reduction.

```gdscript
# Corner evaluations per dimension
# Dim | Perlin (2^N) | Simplex (N+1) | Reduction
#  2  |      4       |       3       |   25%
#  3  |      8       |       4       |   50%
#  4  |     16       |       5       |   69%
#  5  |     32       |       6       |   81%
```

The 4D case matters practically. The seamless torus wrapping technique from Noise_One — mapping two angular dimensions to four noise dimensions — runs 4D noise at every surface vertex. Simplex evaluates 5 corners per sample; Perlin evaluates 16. On a torus mesh with 10,000 vertices regenerated per frame, the difference is 50,000 versus 160,000 gradient evaluations.

The phi term in QFEP quantifies this: the same change (seamless wrapping) requires different energy expenditure depending on which algorithm provides the substrate. Simplex spends less energy for the same topological result.

Domain warping, which Noise_Inside_Noise introduced, compounds the difference further. Warping evaluates a noise function at coordinates that are themselves noise outputs — multiplying the evaluation count per output pixel. When the base noise is Simplex, each evaluation is cheaper, and the total cost of a three-layer warp cascade compounds that savings across every layer.

## Artifacts as Diagnostic Tools

The axis-aligned artifacts in Perlin noise are usually treated as defects. A different perspective: they are diagnostic.

If a terrain shows faint grid alignment, the noise source is Perlin. If a texture shows directional bias at 45-degree diagonals, that pattern points to a specific implementation detail — the gradient set. If no directional pattern is visible at any angle, the source is likely Simplex or a derivative like OpenSimplex.

```gdscript
# Diagnostic: render noise with extreme contrast to reveal artifacts
func render_diagnostic(noise_source: FastNoiseLite, resolution: int) -> Image:
    var img := Image.create(resolution, resolution, false, Image.FORMAT_L8)
    for y in range(resolution):
        for x in range(resolution):
            var val := noise_source.get_noise_2d(
                float(x) * 0.01, float(y) * 0.01
            )
            # High contrast mapping — amplifies subtle patterns
            val = clamp((val + 0.1) * 5.0, 0.0, 1.0)
            img.set_pixel(x, y, Color(val, val, val))
    return img
```

The diagnostic rendering maps a narrow slice of the noise range to the full brightness range, amplifying features invisible at normal contrast. The room's two displays do not amplify contrast; what they do is hold seed, sampling, octaves, gain, size and colour equal and let the visitor set OCTAVES to one, where a single scale of the lattice is easiest to read. That is a fair comparison rather than a maximally visible one.

The learner walking between them sees what the algorithm leaves behind — and what it erases — under conditions they can read off the two readouts.

Every algorithm has a geometry. That geometry imprints on the output like a watermark. Good algorithms minimize the watermark. Great algorithms make it invisible. Neither produces true randomness — both produce deterministic, structured fields that look random at the scales where the structure is too fine to perceive.

The difference is where the structure becomes perceptible, and which directions it favors when it does.

## Possible Artifacts

**lattice_overlay** — Renders both the hypercubic lattice (for Perlin) and the simplicial lattice (for Simplex) as wireframes overlaid on their respective noise outputs. Gradient vectors at each lattice point display as colored arrows. The learner sees the scaffolding that produces the noise — integer grid points, gradient assignments, cell boundaries. Toggling between the two lattice types makes the geometric argument concrete: cubes have axis-aligned edges, simplices do not. Directly addresses the gap identified in the intent — making the geometric reason for different artifacts visible rather than inferred.

**dimension_cost_visualizer** — An interactive artifact that lets the learner select a dimensionality (2D through 5D) and displays both algorithms evaluating a single noise sample in slow motion. Each corner evaluation appears as a pulse from the lattice point to the sample point, with a running counter. At 2D the difference is minor. At 4D and 5D the Perlin side floods with pulses while the Simplex side completes with a handful. The exponential-versus-linear cost becomes visceral rather than tabular.

**artifact_amplifier** — Takes any noise configuration and renders it through an extreme contrast filter mapping a 10% slice of the value range to full brightness, sweepable across the range. At normal contrast both algorithms produce indistinguishable output. Under amplification, the Perlin lattice emerges as faint axis-aligned striations while Simplex output remains isotropic. The learner drags the contrast window and watches the ghost of the cubic grid materialize and dissolve — artifacts are always present, only their visibility changes with viewing conditions.
