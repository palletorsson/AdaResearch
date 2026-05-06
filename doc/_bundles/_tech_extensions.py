import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

additions = {}

additions['Trans_Scale'] = """

## Implementation Notes and Complexity

Scaling a Node3D in Godot is O(1) — the operation writes three floats into the transform basis. The cost of the operation is not in the scale itself but in the downstream propagation: every child's world transform must be recomputed when the parent's scale changes. For a tree of N nodes, a single scale on the root triggers O(N) transform updates on the next frame.

Non-uniform scale is where the practical complexity arrives. A uniform scale commutes with rotation; a non-uniform scale does not. The basis matrix that would represent rotation followed by non-uniform scale cannot generally be decomposed back into clean rotation and scale components — the decomposition produces shear. Code that intermixes the two operations often ends up with nodes whose children inherit unintended skew, and the skew is not easy to remove after the fact because it was encoded in the basis when the scale was applied.

Collision shapes follow the parent's scale automatically in Godot, but physics properties do not. A rigid body with its scale doubled will still have its original mass unless the author adjusts it explicitly. The scale_with_collision routine above shows the cubic law applied to mass; real applications frequently forget to apply it and end up with rigid bodies that punch through walls because their inertia is wrong for their new size.

Within the sequence, Trans_Scale sits between translation and rotation as the third of three fundamental geometric transformations. The scale_me artifact lets the learner control the operation directly with their hands, so the cubic volume law becomes a body-level experience rather than an equation. The prism blocks provide scale reference because their angular geometry is unambiguous at every size, and human perception automatically compares angles across scales even when it cannot compare lengths reliably.
"""

additions['Color_Nails'] = """

## Implementation Notes and Complexity

The color_nails artifact renders an array of small spike meshes, each with a material whose albedo is driven by an index into a palette. Instantiating N nails produces N MeshInstance3D nodes and N material assignments; the cost is O(N) on setup and effectively zero at runtime once the nails are placed. The per-frame cost is one draw call per nail unless the engine batches them automatically, in which case the cost collapses to the number of unique materials.

The palette is the organising data structure. A small JSON file maps palette indices to RGB triples, and the nails reference the palette by index rather than by colour directly. This indirection is deliberate: changing the palette at runtime retones every nail simultaneously without touching the per-nail data. The indirection also enables palette swaps — a common technique in retro graphics where a single asset is reused under different colour schemes.

Colour space matters more than it usually does in procedural graphics. Godot's default colour space is linear sRGB for shaders and gamma sRGB for the output framebuffer. Mixing the two produces the wrong result: a linear-space interpolation between two gamma-space colours lands on a different point than the gamma-space interpolation between the same two colours. The nail palette is defined in gamma space, and the shader converts to linear on read, which is the convention Godot's built-in materials follow.

Within the sequence, Color_Nails is an early exploration of colour-as-data. The palette indirection argues that colour is not a property of the object but an assignment of one of several possible tones, and the assignment can change. Later maps in the sequence will extend this: Color_Flashlight detaches colour from the object entirely, and Color_Grid_Pallet makes the palette itself a grid the learner can edit.
"""

additions['Color_Grid_Pallet'] = """

## Implementation Notes and Complexity

The palette grid is a 2D array of colour cells whose contents can be edited in place. Each cell holds an RGBA quadruple. The grid's dimensions are fixed at load, but the cell values are mutable, so the whole palette can be retoned without reallocating. The edit operation is O(1) per cell; a full-palette retone is O(W times H) where W and H are the grid's dimensions.

The grid is backed by an ImageTexture in Godot. Editing a cell writes to the underlying Image, and the Image must be pushed back to the texture for the GPU to see the change. This push is not free: it triggers a texture upload, which in the worst case stalls the render thread briefly. For interactive editing at palette scale (16 by 16 or smaller), the stall is imperceptible. For larger grids, batching multiple cell edits between pushes is necessary to maintain frame rate.

The palette's content is referenced by other nodes via palette-index lookups. When the palette changes, those nodes do not automatically redraw; they have to be notified and re-render. Godot's signal system is the conventional plumbing. The palette emits a palette_changed signal, and interested nodes connect to it. The signal is cheap — a few function calls — but the downstream redraw can be expensive depending on how many nodes are listening and how much geometry each has to refresh.

Within the sequence, Color_Grid_Pallet introduces the palette as a first-class artifact the learner can edit. Previous maps treated colour as assignment; this map treats it as collection. The grid's cells can be rearranged, retoned, or replaced wholesale, and the changes propagate to whatever art is referencing them. The sequence's later maps extend this with interactive palette composition and wavelength-based response.
"""

additions['Color_Rainbow'] = """

## Implementation Notes and Complexity

The rainbow gradient is conventionally implemented as a 1D linear interpolation through a sequence of hue stops: red, orange, yellow, green, blue, indigo, violet. Interpolating in RGB space between red and yellow produces a smooth orange; interpolating between green and blue produces a reasonable cyan. Interpolating between violet and red — the gap the wheel closes across — produces a muddy brown in RGB. The map avoids the muddy result by interpolating in HSV space instead.

HSV interpolation keeps hue on a circle. Moving from red to violet through the short arc sweeps across the visible spectrum; moving the long arc produces the same brown the RGB path would. The map's gradient routine computes the shortest angular distance between two hue stops and interpolates along that arc, then converts back to RGB for rendering. The conversion is three multiplications, a conditional branch on the hue sector, and another three multiplications — O(1) per sample.

Rendering the gradient on a surface is a shader operation. The rainbow is a strip or a disc whose UV coordinates map to a hue angle. The shader reads the UV, converts to RGB, and writes the pixel. The cost is trivial on modern hardware, and the gradient redraws at full frame rate even at high resolution. Caching the gradient as a small lookup texture is an optimisation that pays off only when the hue stops are themselves animated, which rarely happens.

Within the sequence, Color_Rainbow connects the algorithmic composition of hues to the physical phenomenon the word rainbow usually names. The prismatic decomposition of white light is a physical process; the algorithmic rainbow is a computational simulation of it. Keeping the two registers distinct — physical versus computational — is one of the sequence's recurring concerns, and this map is where the distinction becomes explicit.
"""

additions['Color_Pillar'] = """

## Implementation Notes and Complexity

The pillar artifact renders a vertical stack of coloured cylinders, each tinted by a distinct material. The stack's height maps to a palette dimension, and the pillar as a whole reads as a legible sample of the palette's gradient. Constructing the pillar requires N MeshInstance3D nodes for a stack of height N, and N material instances because each cylinder's albedo is unique. The per-instance cost is O(1); the full pillar setup is O(N).

Rendering the pillar at runtime is dominated by the draw-call count. Godot batches instances of the same mesh with the same material automatically; the pillar defeats this optimisation because every cylinder has a unique material. A pillar of height 32 produces 32 draw calls. Modern hardware handles this comfortably at 60 frames per second, but dense scenes with many pillars can become CPU-bound on draw submission. The conventional optimisation is to bake the pillar's colour variation into a single texture and render the pillar as a single cylinder with that texture, collapsing 32 draw calls to one.

The pillar's material properties extend beyond albedo. Each cylinder can carry its own metallic, roughness, and emission values, and the stack can be used as a live material sampler: a learner picks a height and the corresponding cylinder's full material assignment becomes the active paint. The sampler is not free — reading the material properties requires a node lookup — but the cost is O(1) per sample and runs at interactive rates.

Within the sequence, Color_Pillar is the vertical counterpart to the horizontal palette. The stack's height dimension gives the palette a third axis of legibility: the learner can see the whole gradient at once, from eye level down, rather than having to scan a horizontal strip. The pillar's architecture makes the palette a standing object rather than a tablet, and the embodied vertical reading is the map's small contribution to the colour vocabulary the sequence is building.
"""

additions['Color_Paint'] = """

## Implementation Notes and Complexity

Painting on a surface requires a writable texture. Godot's ImageTexture supports per-pixel updates: the learner's brush writes RGBA values into the Image, and the Image is pushed to the GPU at the end of each stroke. Per-pixel writes are O(1), but the texture upload has a fixed per-frame cost that dominates for small strokes. Batching writes within a frame — accumulating brush samples into a dirty rectangle and uploading only that region — is the standard optimisation.

The brush itself is a small convolution kernel. A soft brush is a Gaussian bump whose centre sits at the cursor position and whose extent falls off smoothly. Each brush sample writes several pixels with weighted contributions, so the cost of a stroke scales with brush area rather than with stroke length. A brush of radius R writes O(R squared) pixels per sample, and the stroke's total cost is the sample count times the per-sample cost.

Blending modes matter for paint-over semantics. Alpha blending with a fresh colour produces a weighted average of new and existing pigment, which is the conventional paint behaviour. Additive blending produces a colour that can exceed full saturation, which is closer to stage-light behaviour than to paint. The map exposes the blending mode as a parameter so the learner can compare the two; switching between them reveals that painting is not a single operation but a family of related ones with different mathematical signatures.

Within the sequence, Color_Paint is where the learner's hand becomes the colour input. Previous maps presented colour as pre-assigned; this map lets the learner author colour into a surface. The painting operation is the first place in the sequence where colour is a choice made by the learner rather than by the authoring system, and the shift carries the sequence forward into the interactive-palette territory the later maps explore.
"""

additions['Color_Walls'] = """

## Implementation Notes and Complexity

The wall artifacts are flat panels with an albedo set per instance. Rendering a wall is a single draw call per unique material; walls sharing a material are batched automatically by Godot's renderer. A gallery of N walls with N unique colours produces N draw calls, and the cost scales linearly with the wall count until GPU-side batching limits are reached.

The wall's reflective properties are controlled by the material's roughness and metallic parameters. A roughness of 0 produces a mirror; a roughness of 1 produces a matte diffuse surface. Between these extremes, the wall reflects with a Gaussian specular lobe whose width is controlled by the roughness value. Real-time reflection on arbitrary geometry requires either a reflection probe (a cubemap captured from a representative point in the scene) or a screen-space approximation. Godot's default pipeline uses both: a scene-wide probe for coarse reflections and screen-space reflections for fine detail when the ray stays on-screen.

Lighting interacts with colour in ways that are easy to get wrong. A red wall under blue light appears dark because the red pigment absorbs blue wavelengths. The naive multiplication of light colour by material albedo produces this correctly. Lighting shaders that use summed colour components instead of multiplied ones produce unrealistic results where a red wall glows under blue light. Godot's physically-based shader uses the multiplicative convention by default.

Within the sequence, Color_Walls makes colour architectural. The walls are not just tinted backdrops; they are first-class artifacts whose albedo, roughness, and metallic properties interact with the scene's lighting to produce a room with a specific character. The map argues that colour is not a property of objects in isolation but a property of their interaction with the lighting environment, and the learner walks through the argument by moving between differently-lit regions of the room.
"""

additions['Randomness_Examples_of_Randomness'] = """

## Implementation Notes and Complexity

Each example in the gallery is a small standalone demonstration that samples Godot's randf, randi, or randf_range and uses the samples to drive a visible behaviour. The underlying pseudo-random number generator is a Mersenne Twister with a 2 to the 19937 minus 1 period, which is effectively infinite for any realistic number of samples. Samples are O(1) to draw, and the cost of each demonstration is dominated by the rendering rather than by the random generation.

Seeding is the operation that makes a random sequence reproducible. Calling seed(value) resets the PRNG's state; subsequent calls to the sampling functions produce a deterministic sequence conditional on the seed. The map's gallery exposes a seed control so the learner can save a configuration and replay it. Without seeding, each run of the game produces a different gallery, which is often the desired behaviour; with seeding, the gallery becomes a fixed artifact for a given seed.

Distribution shape is the next concern. randf samples uniformly from zero to one; randf_range samples uniformly from an interval. Neither produces Gaussian samples; Gaussian requires either the Box-Muller transform applied to two uniform samples or a rejection-sampling approach, both of which the map demonstrates. The Box-Muller approach is O(1) per sample but involves a logarithm and a sine, which are expensive compared to a uniform draw.

Within the sequence, Examples_of_Randomness is the orientation map. It introduces the sampling primitives the rest of the Randomness sequence will use, and it demonstrates that the primitives are themselves composed of implementation decisions — seed, distribution, range. The map's gallery is a catalogue of primitives, and the catalogue is the vocabulary the sequence will exercise.
"""

additions['Fractal_CantorSet'] = """

## Implementation Notes and Complexity

The Cantor set is constructed by repeated middle-third removal. Starting from the unit interval, each step removes the open middle third of every remaining interval. After N steps, the remaining structure consists of 2 to the N intervals, each of length 3 to the minus N. The total length tends to zero; the total number of endpoints tends to infinity; the fractal dimension is log(2) over log(3), approximately 0.631.

The recursive construction has straightforward time and space complexity. Each step multiplies the interval count by 2, so generating N steps requires O(2 to the N) storage for the interval list. Naive implementations allocate a new list at each step; a more efficient implementation stores only the endpoints and reconstructs intervals on demand, giving O(N) memory for the recursion depth plus O(2 to the N) time to enumerate the intervals.

Rendering the Cantor set is limited by what can actually be displayed. At eight iterations the structure has 256 intervals, each too narrow to be distinct on a normal display. Beyond ten iterations the visualisation collapses visually, even though the mathematical construction continues. The map caps visible depth at a threshold that produces legible geometry, and a side panel tracks the mathematical depth separately.

The Cantor dust — the 2D analogue — is constructed similarly but with 8 of 9 squares retained instead of 2 of 3 intervals. The fractal dimension is log(8) over log(3), approximately 1.893. The Cantor carpet uses 8 of 9 squares as well but colours them differently; Sierpinski's carpet removes the centre of each square instead, producing dimension log(8) over log(3), the same value.

Within the sequence, Cantor is the one-dimensional entry point to the fractals sequence. Sierpinski, Koch, and Menger all generalise Cantor's subtractive logic to higher dimensions, and the dimensional ladder from Cantor to Menger runs through this map's construction.
"""

additions['Fractal_MengerSponge'] = """

## Implementation Notes and Complexity

The Menger sponge is constructed by recursive subdivision and selective removal. Start with a unit cube. Divide it into 27 sub-cubes. Remove the centre sub-cube and the six face-centre sub-cubes, leaving 20 sub-cubes. Apply the same procedure to each remaining sub-cube. After N iterations, the structure has 20 to the N sub-cubes, and the fractal dimension is log(20) over log(3), approximately 2.727.

The recursion's time complexity is O(20 to the N), and memory scales identically unless the structure is computed on demand rather than stored. A naive implementation that materialises every sub-cube as a scene tree node runs out of memory at around N equals 5 on consumer hardware. The map caps rendering depth at N equals 4 and uses instanced rendering: a single small cube mesh is drawn many times with different transforms, avoiding per-sub-cube allocation.

Face culling becomes important at high iteration depths. Many of the sub-cubes are partially or fully occluded by their neighbours, and rendering them wastes GPU time. Godot's occlusion culling helps, but the sponge's characteristic self-similarity means that many sub-cubes are geometrically distinct at sub-pixel scale and cannot be collapsed. The rendering cost becomes the dominant constraint at high depths, not the recursion.

The Menger sponge has the universal curve property: every compact one-dimensional curve is homeomorphic to a subset of the Menger sponge. This is a surprising theoretical result with direct pedagogical consequences: the sponge is, in a formal sense, a library of all possible one-dimensional curves. The side panel in the map notes this without attempting to demonstrate it, since a demonstration would require searching a high-dimensional embedding space.

Within the sequence, Menger is the three-dimensional climax of the deletion arc. Cantor, Sierpinski, and Menger climb the dimensional ladder by the same recursive mechanism, and Menger is the top rung.
"""

additions['Fractal_MandelbrotSet'] = """

## Implementation Notes and Complexity

The Mandelbrot set is defined as the set of complex numbers c for which the iteration z_new equals z_squared plus c, starting from z equals zero, does not diverge to infinity. Membership is tested by iterating and checking whether the magnitude of z exceeds a bailout threshold (typically 2) within a maximum iteration count. The output is a per-pixel classification: either in the set (never escaped within the iteration budget) or escaped at iteration N (which gives a colour for visualisation).

The time complexity is O(W times H times I) where W and H are the image dimensions and I is the maximum iteration count. Each pixel iterates independently, which makes the Mandelbrot an embarrassingly parallel problem — perfect for GPU evaluation. A shader implementation computes one pixel per thread, and modern GPUs process millions of pixels per frame. CPU implementations can reach interactive rates using SIMD and cache-friendly memory layouts, but GPU is the conventional choice.

Rendering precision matters at deep zoom levels. At zoom depths beyond about 10 to the 14, double-precision floating-point begins to produce visible artifacts — adjacent pixels sample positions that differ by less than a ULP, and the iteration's convergence test becomes unreliable. Deep zoom renderers use arbitrary-precision arithmetic or perturbation theory, both of which cost substantially more per pixel.

Colouring is where aesthetic decisions enter. The escape iteration count is an integer, and mapping it to a colour gradient is a designer's choice. Smooth colouring applies a continuous correction based on the magnitude of z at escape, producing gradient transitions that avoid the banding that pure integer counts produce. The map exposes a gradient selector so the learner can compare colouring strategies.

Within the sequence, Mandelbrot is the complex-dynamics chapter. Previous maps used iterated substitution on real numbers (Cantor) or on geometric figures (Koch, Sierpinski). Mandelbrot uses iterated substitution on complex numbers, and the resulting set lives in a plane where the iteration's behaviour produces the characteristic self-similar boundary.
"""

additions['Fractal_Synthesis'] = """

## Implementation Notes and Complexity

The synthesis map assembles the sequence's fractal techniques into a single composable system. Each fractal — Cantor subtraction, Koch addition, Mandelbrot iteration, Sierpinski removal — is represented as a generator whose output can be composed with the outputs of the others. The composition graph is a small DAG; nodes are generators, edges carry geometry or colour data.

Generators are O(1) to instantiate and O(structure size) to evaluate. A Koch snowflake at depth 5 produces 3 times 4 to the 5 equals 3072 line segments; a Sierpinski triangle at depth 5 produces 3 to the 5 equals 243 filled triangles. The composition cost depends on how outputs are combined: overlaying is O(sum of sizes), intersecting requires spatial data structures and is O(N log N) for N combined elements.

The map's combinator set is deliberately small. Overlay, intersect, mask, and scale-offset are the four operations. Each operation has a clear geometric interpretation, and the small vocabulary means that the learner can compose complex structures without a combinatorial explosion of options. Larger combinator vocabularies tend to produce more expressive systems but harder-to-predict results, and the map prioritises predictability.

Memory management matters at deep composition. A tree with multiple generators at depth 5 or higher can produce tens of thousands of geometric primitives. Godot's scene-tree representation becomes a bottleneck at this scale; the map uses MultiMeshInstance3D for repeated primitives and batches draws aggressively.

Within the sequence, Synthesis closes the fractals arc. Previous maps introduced individual fractals; this map treats them as primitives in a compositional algebra. The algebra's expressive power is the sequence's closing argument: fractals are not only individually beautiful but compositionally productive, and the combinations produce structures that no single fractal could have generated alone.
"""

additions['Fractal_CrossSequence'] = """

## Implementation Notes and Complexity

CrossSequence pulls together the fractal arc's connections to earlier sequences in the curriculum. Noise, cellular automata, L-systems, and recursive geometry all share a common substrate: rules applied repeatedly to produce self-similar or scale-invariant outputs. The map stages this commonality as a gallery where equivalent structures from different sequences are displayed side by side.

The rendering cost is dominated by the sheer number of comparison artifacts the map displays. Each comparison pair requires two independent generators running at matched parameter values, and the gallery holds a dozen such pairs. The per-pair cost is O(1) at spawn and O(render size) at display; the aggregate is manageable because each individual artifact is modest.

The matching problem — which noise parameter corresponds to which L-system parameter when the outputs look similar — is not a solved problem in the abstract. The map's approach is pragmatic: matched pairs are hand-tuned by the authoring system, and the learner compares the pairs visually rather than algorithmically. A different approach would use statistical signatures such as power spectra or correlation functions to match outputs automatically, but the hand-tuned matching preserves the authoring intent the sequence's pedagogy depends on.

The cross-sequence connections the map demonstrates are structural rather than merely visual. Both fractals and noise produce structures with fractal dimension between integers; both L-systems and cellular automata produce structures through repeated local rewriting; both noise and cellular automata operate on grids. The map's side panels name the structural connections explicitly, so the visual comparisons are grounded in shared mathematics rather than in surface resemblance.

Within the sequence, CrossSequence is the bridge. It situates the fractals arc within the broader curriculum and prepares the learner to recognise the fractal logic in later sequences. The map's argument is that self-similarity is a widely shared property, and the recognition is part of the curriculum's synthesis work.
"""

additions['ProceduralGeneration_Reaction_Diffusion_Systems'] = """

## Implementation Notes and Complexity

The Gray-Scott reaction-diffusion model simulates two coupled chemicals on a 2D grid. The update rule for each cell consults its own concentration and the concentrations of its four or eight neighbours, computes the Laplacian (a discrete second derivative), and integrates the two coupled partial differential equations forward by a small time step. The per-cell cost is O(1); the per-step cost for a W times H grid is O(W times H).

Real-time simulation at visible resolution requires careful attention to numerical stability. The time step must satisfy a CFL-style condition: time step less than spatial step squared divided by four times the larger diffusion coefficient. Violating this condition produces instability where the concentrations diverge to infinity within a few frames. The map uses a fixed time step chosen to be safe for the full parameter range the learner can set, at the cost of slower apparent dynamics.

The feed rate f and kill rate k parameters define a phase space. Different regions produce different pattern types: spots, stripes, labyrinths, and mitosis-like cell division. The parameter map is continuous — small changes produce small changes in output — but the boundaries between regions are sharp, so a slider that crosses a boundary shows a visible shift in behaviour.

GPU evaluation is the conventional implementation. A compute shader loads the current concentration grid, computes the update, and writes to a second grid; the two grids swap each frame. The cost on a modern GPU is a fraction of a millisecond for a 512 by 512 grid, leaving plenty of frame budget for interactive parameter tuning.

Within the sequence, Reaction_Diffusion is the chemistry chapter of the procedural generation arc. Previous maps produced structure through geometric operations (branching, subdivision); this map produces structure through chemical dynamics. The map argues that procedural generation is not tied to any single computational paradigm, and chemistry is a legitimate primary substrate.
"""

for m, add in additions.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    if add.strip()[:80] not in t:
        p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(additions))
