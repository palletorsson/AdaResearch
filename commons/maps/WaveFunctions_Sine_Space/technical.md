# A corridor of frozen sine waves where oscillation becomes floor, wall, and architecture the learner walks through

The Pendulum map ended with a promise: the oscillation that swings in time extends into space. The pendulum bob traces displacement as a function of t — a single variable, a single axis, a single curve scrolling across a seismograph. Sine Space fulfills that promise by taking the same sin(t) and replacing the temporal variable with spatial coordinates. The wave no longer swings.

It stands. Amplitude is height. Frequency is compression. Phase is shift. The function that produced motion now produces geometry — terrain you can walk, walls you can touch, surfaces whose every vertex is calculable from its position.

This is not metaphor. The sine_space artifact generates a 25x25 grid of spheres whose y-positions are determined entirely by `sin(f*x) * sin(f*z)`. The sine_wall_corridor constructs mesh walls whose x-displacement follows `A*sin(f*z + phi)` summed across multiple frequency layers. The learner stands inside the equation. The abstract curve from the Intro — `x = A*sin(wt + phi)` — has become the shape of the room.

## From Time to Space: The Variable Swap

A pendulum's displacement is a function of time:

```
x(t) = A * sin(omega * t + phi)
```

One input (t), one output (x). The graph is a curve on paper, scrolling rightward as time advances. Now replace t with a spatial coordinate. Instead of evaluating `sin` at each moment, evaluate it at each position:

```
y(x) = A * sin(f * x + phi)
```

Same function. Different domain. The output y is now a height at position x — a static shape. Every point along the x-axis has a predetermined height. No time is involved. The wave exists all at once, frozen in space.

The sine_space artifact extends this to two dimensions:

```gdscript
# SineSpace.gd — the core height calculation
var height = amplitude * sin(frequency * x_normalized * PI + phase) * sin(frequency * z_normalized * PI + phase * 0.7)
```

Two spatial variables, x and z, each feeding its own sine call. The product of two sine waves creates a surface — peaks where both sines are positive, troughs where both are negative, saddle points where they disagree. The result is an egg-carton topography, a landscape whose every hill and valley is a direct consequence of the function's parameters.

The height formula `A * sin(f*x) * sin(f*z)` is a separable function — the x-contribution and z-contribution multiply independently. Change x and the entire row of z-values scales uniformly. Change z and the column responds in kind. No coupling between axes. The terrain is the Cartesian product of two one-dimensional waves.

## Amplitude as Architecture

Amplitude determines how far the wave displaces from zero. In the pendulum, amplitude was the arc of the swing — how far the bob traveled from center. In sine space, amplitude is vertical extent — the height of the hills, the depth of the valleys.

```gdscript
@export var amplitude: float = 1.5

# In update_flat_sine_surface:
var height = amplitude * sin(frequency * x_normalized * PI + phase) * sin(frequency * z_normalized * PI + phase * 0.7)
```

At `amplitude = 0`, the surface is flat. Every y-value equals zero. The sine function still evaluates — it returns values between -1 and 1 — but the multiplier collapses those values to nothing. The wave exists mathematically but produces no geometry. Zero amplitude is silence made spatial.

At `amplitude = 1.5`, peaks reach 1.5 units above the origin and troughs sink 1.5 units below. The total vertical range is `2 * amplitude` — three units from floor to ceiling of the wave. The sine_space artifact modulates amplitude over time:

```gdscript
amplitude = 1.5 + cos(time * 0.2) * 0.8
```

A cosine function varying amplitude itself. The hills breathe — swelling and shrinking as the cosine cycles. Amplitude modulation: a wave controlling the intensity of another wave. The outer cosine has its own frequency (0.2 radians per second) and its own amplitude (0.8), producing a terrain that pulses between gentleness and extremity.

## Frequency as Compression

Frequency determines how many oscillations fit within a given spatial interval. Low frequency means wide, rolling hills. High frequency means tight, compressed ripples. The sine_space artifact modulates frequency alongside amplitude:

```gdscript
frequency = 1.0 + sin(time * 0.3) * 0.5
```

Frequency oscillates between 0.5 and 1.5. At the low end, the terrain smooths out — fewer hills, broader curves, an expanse of gentle undulations. At the high end, the surface crumples — more hills packed into the same area, each narrower and steeper. The grid_size remains 25x25. The resolution does not change. Only the mathematical compression does. Frequency is zoom applied to the wave, not to the viewport.

The relationship between frequency and spatial wavelength is inverse:

```
wavelength = 2 * PI / frequency
```

Double the frequency, halve the wavelength. The hills crowd together. Halve the frequency, double the wavelength. The hills spread apart. This inverse relationship is the same one that governs sound (pitch vs. wavelength), light (color vs. wavelength), and every other wave phenomenon. The sine_space artifact makes it walkable.

## Phase as Displacement

Phase shifts the entire wave along its axis without changing its shape. In the Pendulum map, the PendulumWave demonstrated phase through length differences — pendulums of different periods drifting apart over time. In sine space, phase is a direct offset in the function argument:

```gdscript
phase = time * 2.0
```

Phase advances at 2.0 radians per second. The terrain slides. Every point on the surface maintains its sinusoidal relationship to its neighbors, but the whole pattern translates continuously. Hills that stood at x=0 now stand at x=delta. The wave propagates.

The sine_wall_corridor uses phase offsets between its two walls:

```gdscript
@export var phase_offset_between_walls: float = 0.6
```

Left wall and right wall share the same base frequency and amplitude but differ by 0.6 radians in phase. The result is walls that breathe asymmetrically — when the left wall bulges inward, the right wall has not yet reached its maximum displacement. The corridor narrows and widens irregularly, not because the walls use different functions but because the same function is evaluated at different phase offsets.

This is the spatial analog of what the PendulumWave showed temporally. Phase differences between identical oscillators produce apparent patterns — waves, pulses, breathing — from constituents that are individually identical. The corridor walls are two instances of the same equation, shifted in phase. The learner walks through the interference.

## Superposition: Layered Waves

A single sine wave is smooth. Predictable. Walk it once and the rhythm is obvious. The sine_wall_corridor breaks this predictability by summing multiple sine waves at different frequencies:

```gdscript
@export var wave_layers: Array = [
    {"freq_mul": 1.0, "amp_mul": 1.0, "phase_shift": 0.0},
    {"freq_mul": 1.8, "amp_mul": 0.35, "phase_shift": 0.85},
    {"freq_mul": 2.6, "amp_mul": 0.18, "phase_shift": -0.35}
]
```

Three layers. The first is the fundamental — base frequency, full amplitude. The second oscillates 1.8 times faster at 35% amplitude. The third oscillates 2.6 times faster at 18% amplitude. Each layer adds detail to the wall shape:

```gdscript
func _wave_displacement(z_ratio: float, phase_shift: float, freq_multiplier: float, amp_multiplier: float) -> float:
    var z_norm: float = z_ratio * 2.0 - 1.0
    var offset: float = 0.0
    for layer in wave_layers:
        var freq_mul: float = float(layer.get("freq_mul", 1.0))
        var amp_mul: float = float(layer.get("amp_mul", 1.0))
        var phase_layer: float = float(layer.get("phase_shift", 0.0))
        offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase + phase_shift + phase_layer)
    return offset
```

The loop iterates over wave layers, accumulating displacement. Each layer contributes independently. The sum of sines produces a waveform more complex than any individual component — bulges with subsidiary ripples, curves that almost repeat but never quite do. This is additive synthesis. The same principle governs sound timbre, Fourier series, and the harmonic content of any periodic signal.

The key insight: complexity emerges from superposition. No individual sine wave is complex. The complexity lives in the sum. The phi*Delta_E(S,t) dynamics in QFEP mirror this layering — the state function S evolves under the influence of multiple field contributions, each operating at its own scale and phase, their superposition defining the trajectory through state space. The corridor's wall shape is a geometric analog of that superposed evolution.

## Topology: The Same Wave on Different Surfaces

The sine_space artifact cycles through five topologies — flat, cylindrical, spherical, toroidal, and Mobius — applying the same sine modulation to each:

```gdscript
enum TopologyMode {
    FLAT_SINE,
    CYLINDRICAL,
    SPHERICAL,
    TOROIDAL,
    MOBIUS_STRIP
}
```

The flat surface maps `sin(f*x) * sin(f*z)` to the y-axis of a plane. The cylindrical surface wraps one axis into a circle and applies sine modulation to the radius:

```gdscript
func update_cylindrical_surface():
    for x in range(grid_size):
        for z in range(grid_size):
            var u = (x / float(grid_size)) * 2.0 * PI
            var v = (z - grid_size / 2.0) / (grid_size / 2.0) * 3.0
            var radius = 3.0 + amplitude * sin(frequency * u + phase) * sin(frequency * v * 0.5 + phase)
            var pos = Vector3(radius * cos(u), v, radius * sin(u))
```

The parametric variable u wraps from 0 to 2*PI — one full revolution. The radius oscillates around a base value of 3.0, modulated by the sine product. The cylinder bulges and contracts as the wave sweeps around its circumference. The same formula that made hills on a flat plane now makes bulges on a tube.

The toroidal surface wraps both axes:

```gdscript
var major_radius = 3.0
var minor_radius = 1.0 + amplitude * sin(frequency * u + phase) * sin(frequency * v + phase * 0.6)
var pos = Vector3(
    (major_radius + minor_radius * cos(v)) * cos(u),
    minor_radius * sin(v),
    (major_radius + minor_radius * cos(v)) * sin(u)
)
```

A torus with sine-modulated tube thickness. The minor radius breathes according to the wave, producing a donut whose cross-section varies continuously. The mathematics is unchanged — sin multiplied by sin — but the coordinate system's topology alters the visual result entirely. Flat becomes cylindrical becomes spherical becomes toroidal. The wave function persists. The manifold it lives on transforms.

This progression demonstrates that a wave is not its visualization. The equation `A * sin(f*u) * sin(f*v)` exists independently of how u and v map to spatial coordinates. Topology is the container. The wave is the content.

## Color as Height Encoding

Both sine_space and sine_wall_corridor map displacement to color. The sine_space artifact uses a three-stop gradient:

```gdscript
func height_to_color(height_value: float) -> Color:
    var t = (height_value + amplitude) / (2.0 * amplitude)
    t = clamp(t, 0.0, 1.0)
    if t < 0.5:
        var s = t * 2.0
        color = Color(0.1, 0.2 + 0.6 * s, 0.9 - 0.1 * s)
    else:
        var s = (t - 0.5) * 2.0
        color = Color(0.1 + 0.9 * s, 0.8 - 0.3 * s, 0.8 - 0.7 * s)
```

The normalization `(height_value + amplitude) / (2.0 * amplitude)` maps the full height range `[-amplitude, +amplitude]` to `[0, 1]`. The lowest points are blue. Mid-height is cyan. Peaks are orange. The gradient provides a second channel of information — the eye reads height and color simultaneously, reinforcing the spatial wave pattern with chromatic structure.

The sine_wall_corridor performs a similar mapping through `_evaluate_color`, blending between `bottom_color`, `mid_color`, and `top_color` based on displacement intensity. The corridor walls glow brighter where they bulge most, dimmer where they recede. Color becomes a proxy for the sine function's current value at each vertex — a visual readout of the mathematics baked into the geometry.

This double encoding — geometry plus color — is the same principle as the seismograph from the Pendulum map. There, displacement was written as a trace on paper. Here, displacement is written as color on mesh. The wave tells its own story twice, in two languages.

## Procedural Mesh Construction

The sine_wall_corridor builds its geometry procedurally using SurfaceTool — Godot's vertex-by-vertex mesh construction API:

```gdscript
func _create_wall_mesh(side: int, half_length: float, half_width: float, half_height: float, phase_shift: float, freq_multiplier: float, amp_multiplier: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for col in range(columns):
        var z_ratio: float = col / float(columns - 1)
        var z_pos: float = lerp(-half_length, half_length, z_ratio)
        var displacement: float = _wave_displacement(z_ratio, phase_shift, freq_multiplier, amp_multiplier)

        for row in range(rows):
            var y_ratio: float = row / float(rows - 1)
            var y_pos: float = lerp(-half_height, half_height, y_ratio)
            var base_x: float = side * half_width
            var x_pos: float = base_x - side * displacement
```

Two hundred columns by sixty-four rows. Each column samples the wave displacement at its z-position. Each row within that column generates a vertex at the appropriate height. The x-position of every vertex is `base_x - side * displacement` — the wall's neutral position offset by the sine-driven displacement. The `side` variable is -1 for the left wall and +1 for the right, flipping the displacement direction so both walls bulge inward.

The sine_space artifact uses MultiMesh instead of SurfaceTool. A 25x25 grid of sphere instances, each positioned by setting its Transform3D:

```gdscript
multi_mesh.set_instance_transform(idx, Transform3D(Basis(), Vector3(x_pos, height, z_pos)))
multi_mesh.set_instance_color(idx, height_to_color(height))
```

MultiMesh handles 625 instances in a single draw call. SurfaceTool builds a continuous mesh from thousands of triangles. Two different rendering strategies for the same mathematical content. The choice depends on visual intent — discrete spheres reveal the sampling grid, continuous mesh hides it behind smooth surfaces.

## The Walkable Wave

The sine_wall_corridor is not a visualization. It is architecture. The `enable_collision` flag generates collision shapes from the wall meshes:

```gdscript
func _update_wall_collision(mesh_instance: MeshInstance3D, shape_node: CollisionShape3D) -> void:
    if not enable_collision:
        shape_node.shape = null
        return
    var mesh := mesh_instance.mesh
    if mesh:
        shape_node.shape = mesh.create_trimesh_shape()
```

`create_trimesh_shape()` converts the visual mesh into a physics collision surface. The learner collides with the sine wave. The body cannot pass through the function. This is the strongest form of embodied mathematics available in a game engine — the equation is not displayed or animated, it is the boundary condition of the player's motion. Walk forward and the walls push back. The pushback is `A * sin(f*z + phi)`. The body learns the wave before the mind names it.

The QFEP framework describes state evolution as movement through an energy landscape shaped by field interactions. The sine_wall_corridor literalizes this — the learner's trajectory through the corridor is constrained by a landscape that is, precisely, a wave function applied to geometry. The phi*Delta_E(S,t) dynamics describe how the state variable S navigates the potential surface. In this map, the learner is S. The corridor is the potential. The navigation is the physics.

## The Explanation Artifacts

Two explanation artifacts flank the corridor — sine_space_explanation on the east wall, sine_wall_explanation on the west. Each constructs a miniature demonstration of its respective formula.

The sine_space_explanation builds a surface mesh with wireframe overlay:

```gdscript
func _get_height(x: float, z: float, phase: float) -> float:
    return amplitude * sin(frequency * x * TAU / display_size + phase) * cos(frequency * z * TAU / display_size + phase * 0.7)
```

A small, annotated version of the main sine_space formula. Labels mark the x, z, and height axes. The title reads "Sine Space Topology." The formula `y = sin(x)*cos(z)` is displayed as a Label3D. The wireframe rides atop the surface mesh, revealing the triangulation grid — the discrete approximation underlying the smooth appearance.

The sine_wall_explanation displays value markers along its surface:

```gdscript
func _update_value_markers(phase: float):
    for i in range(VALUE_POINTS):
        var t = float(i) / (VALUE_POINTS - 1)
        var sine_value = sin(frequency * TAU * t + phase)
        _value_labels[i].text = "%.2f" % sine_value
```

Five points along the wall, each showing the current sine value at that position. The numbers update as phase advances — positive values where the wall bulges, negative where it recedes, zero at the crossings. The learner reads the function's output directly from the geometry it produced. Number and shape are the same thing seen from different angles.

## Possible Artifacts

**frequency_comparison_terrain** — Three sine_space surfaces side by side at frequencies 0.5, 1.5, and 4.0, sharing amplitude and phase. The learner walks between them and observes the same vertical range compressed into progressively tighter spatial intervals. A readout on each surface displays the current wavelength `2*PI/f` alongside the frequency value. Bridges the inverse relationship between frequency and wavelength that the single cycling sine_space artifact implies but does not isolate.

**superposition_builder** — An interactive artifact with three sine-wave sliders (frequency, amplitude, phase for each). Each slider controls one wave layer. A surface mesh shows the sum in real time. The learner starts with a single sine wave, adds a second at a different frequency, watches the surface complexify, adds a third. A "reset to fundamental" button strips back to one layer. Demonstrates additive synthesis — how the corridor's layered walls are constructed from simple components — and connects to Fourier decomposition in later maps.

**phase_propagation_row** — A line of vertical bars, each evaluating `A * sin(f*x + phi)` where x is the bar's position and phi advances with time. The bars oscillate up and down independently, but the phase offset between neighbors creates the visual illusion of a traveling wave. No bar moves horizontally. The wave propagates purely through coordinated phase — the spatial version of the PendulumWave from the previous map, made explicit and controllable with a speed slider.
