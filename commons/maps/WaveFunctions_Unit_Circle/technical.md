# An amphitheater sunk into the void where a spinning point on a circle casts its shadow as the sine wave the learner already knows

Sine Space froze the wave in architecture — amplitude as height, frequency as compression, phase as shift. The learner walked through the equation's output. But the equation itself remained unexplained. Where does sine come from? Why does it oscillate? Why that particular shape and no other?

The Unit Circle map answers by rewinding to the origin: a point traveling at constant speed around a circle. Watch it from the side and the vertical position traces a sine wave. Watch from above and the horizontal position traces cosine. The wave is not a fundamental shape. It is a shadow — the projection of uniform circular motion onto a line. Every oscillation the learner encountered in previous maps reduces to this: something spinning, seen from a constrained angle.

The amphitheater layout encodes the revelation spatially. Elevated ramparts ring a central void. The unit_circle_advanced artifact floats in that void, rotating its point, drawing its projections. Below, at the base, SimpleOscillatingBridge artifacts make the resulting wave physical — platforms rising and falling under the learner's feet. The architecture descends from observation to embodiment: see the circle, then stand on its consequence.

## The Unit Circle: Coordinates from Rotation

A circle of radius 1 centered at the origin defines the unit circle. A point on its circumference at angle theta from the positive x-axis sits at coordinates `(cos(theta), sin(theta))`. This is the definition of cosine and sine — not a formula derived from triangles, not a Taylor series, not an equation on a blackboard. Cosine is the x-coordinate of a point on the unit circle. Sine is the y-coordinate. The circle is primary. The functions are projections.

The UnitCircle artifact constructs this directly:

```gdscript
var angle: float = 0.0

func _process(delta: float) -> void:
    angle += rotation_speed * delta

    var x: float = cos(angle) * radius
    var y: float = sin(angle) * radius
    var p: Vector3 = Vector3(x, y, 0)
    rotating_point.position = p
```

Each frame, `angle` advances by `rotation_speed * delta`. The position `p` is computed from `cos(angle)` and `sin(angle)`, scaled by `radius`. The point moves along the circle at constant angular velocity. No explicit path is stored. No waypoints are defined. The circle emerges entirely from evaluating two trigonometric functions at the same angle and assigning the results to x and y. The parametric equation `(cos(theta), sin(theta))` is the circle.

When `radius` equals 1.0, the point traces the unit circle exactly. The x-coordinate oscillates between -1 and 1. The y-coordinate oscillates between -1 and 1. At `angle = 0`, the point sits at `(1, 0)` — rightmost.

At `angle = PI/2`, it reaches `(0, 1)` — topmost. At `angle = PI`, it arrives at `(-1, 0)` — leftmost. At `angle = 3*PI/2`, it drops to `(0, -1)` — bottommost. One full revolution — `2*PI` radians, or `TAU` — returns it to the start. The journey is periodic because the circle is closed.

## Projection: From Circle to Wave

The unit circle lives in two dimensions. A sine wave lives in one. The connection is projection — collapsing one axis and watching what remains.

The UnitCircle artifact draws this projection as colored lines:

```gdscript
func _create_projection_lines() -> void:
    sine_line = _make_line_node(Vector3.ZERO, Vector3.ZERO, sine_color, line_thickness)
    cosine_line = _make_line_node(Vector3.ZERO, Vector3.ZERO, cosine_color, line_thickness)

func _update_rotator_and_indicators() -> void:
    var x: float = cos(angle) * radius
    var y: float = sin(angle) * radius
    var p: Vector3 = Vector3(x, y, 0)

    _update_line_node(sine_line, Vector3(x, 0, 0), p, line_thickness)
    _update_line_node(cosine_line, Vector3(0, y, 0), p, line_thickness)
```

The `sine_line` connects the point `p` to its projection on the x-axis: `Vector3(x, 0, 0)`. This vertical segment has length `|y|` — the absolute value of `sin(angle) * radius`. The `cosine_line` connects `p` to its projection on the y-axis: `Vector3(0, y, 0)`. This horizontal segment has length `|x|` — the absolute value of `cos(angle) * radius`.

As the point rotates, the sine line stretches and contracts vertically. It reaches maximum length when the point is at the top or bottom of the circle (angle = PI/2 or 3*PI/2), and collapses to zero when the point crosses the x-axis (angle = 0 or PI). That stretching and contracting, plotted over time, is the sine wave. The projection line is the wave drawn one sample at a time.

The cosine line does the same horizontally. It reaches maximum at angle = 0 and PI, collapses at PI/2 and 3*PI/2. Cosine leads sine by a quarter cycle — PI/2 radians. The two functions are identical in shape, displaced in phase. The unit circle makes this visible: the horizontal shadow and the vertical shadow perform the same dance, offset by 90 degrees.

## The Dotted Circle: Discretization of Continuity

The circle outline is not drawn as a continuous curve. It is constructed from discrete dots:

```gdscript
func _create_unit_circle_outline() -> void:
    var res: int = 64
    mm.instance_count = res

    for i in range(res):
        var th: float = float(i) / float(res) * TAU
        var p: Vector3 = Vector3(cos(th) * radius, sin(th) * radius, 0)
        mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
```

Sixty-four sphere instances, each placed at `(cos(th), sin(th))` for evenly spaced values of `th`. The MultiMesh renders all 64 in a single draw call. The circle appears continuous to the eye, but the code knows it is sampled. This is the fundamental tension of digital simulation: continuous mathematics approximated by discrete steps.

The `res` variable controls fidelity. At 64, the dots merge into a ring. At 8, the circle becomes an octagon. The underlying equation does not change. The sampling resolution does.

The color wheel option maps each dot's hue to its angular position:

```gdscript
func _get_wheel_color(theta: float, value: float) -> Color:
    var hue = fposmod(theta / TAU, 1.0)
    return Color.from_hsv(hue, wheel_saturation, value)
```

`fposmod(theta / TAU, 1.0)` normalizes the angle from `[0, TAU]` to `[0, 1]` — the hue range in HSV color space. At theta = 0, hue = 0 (red). At theta = TAU/3, hue = 0.333 (green). At theta = 2*TAU/3, hue = 0.667 (blue). The full revolution maps to the full color spectrum. This is not decoration. It encodes angle as color, providing a second perceptual channel. When the bridge platforms inherit these colors, the learner reads the wave's phase position chromatically — red at the start, green at one-third, blue at two-thirds, red again at the close.

## The Bridge: Wave as Walkable Structure

The UnitCircle artifact does not merely display the circle. It builds a physical bridge from the projection. As the point rotates, platform segments materialize along the x-axis at heights determined by `sin(angle)`:

```gdscript
func _create_bridge_step(step_angle: float, idx: int) -> void:
    var t: float = float(idx) / float(max(samples_per_cycle - 1, 1))
    var x: float = start_x + t * wave_length
    var y: float = sin(step_angle) * radius

    var node := Node3D.new()
    node.position = Vector3(x, y, 0)

    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = platform_size
    mi.mesh = bm
```

Each platform is a box mesh positioned at `(x, y, 0)`. The x-position advances linearly along the bridge length. The y-position is `sin(step_angle) * radius` — the sine of the current angle, scaled by the circle's radius. The bridge unfurls in real time as the point rotates, one platform per angular step. The learner watches the circle spin and the bridge grow simultaneously. The connection between rotation and oscillation is not explained — it is constructed, plank by plank, in front of the learner's eyes.

The `num_cycles` parameter extends the bridge across multiple revolutions:

```gdscript
@export var num_cycles: int = 2

var total_angle := TAU * num_cycles
if angle > total_angle:
    angle = total_angle
```

Two full rotations produce two complete sine waves along the bridge. The periodicity is visible: the bridge's shape repeats exactly after one wavelength. The platforms at angle = 0 and angle = TAU sit at the same height. The bridge pattern tiles because the circle is closed.

Collision bodies accompany each platform:

```gdscript
if enable_collision:
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = platform_size
    shape.shape = box
    body.add_child(shape)
    node.add_child(body)
```

The sine wave becomes a surface the learner stands on. The physics engine enforces the function's boundary — feet cannot pass through `sin(theta)`. The embodiment that Sine Space introduced through frozen terrain now extends to a wave that the learner watches being born from circular motion.

## The Oscillating Bridge: Phase-Shifted Platforms in Motion

The SimpleOscillatingBridge operates on a different principle from the UnitCircle's static bridge. Its platforms move continuously:

```gdscript
func update_platform_positions():
    for platform in platforms:
        var phase = platform.get_meta("phase_offset", 0.0)
        var oscillation_angle = time + phase

        var x_offset = cos(oscillation_angle) * oscillation_amplitude_x
        var y_offset = sin(oscillation_angle) * oscillation_amplitude_y

        platform.position = Vector3(x_offset, y_offset, base_z)
```

Each platform stores a phase offset set at creation: `index * phase_offset_per_platform`. The oscillation angle for each platform is `time + phase`. Cosine drives horizontal displacement. Sine drives vertical displacement. Each platform traces an ellipse in the x-y plane — the same circular motion the unit circle demonstrates, stretched by independent amplitude parameters.

The phase offset between platforms creates a traveling wave. No platform moves along the z-axis. Each one oscillates in place. But because neighboring platforms are phase-shifted, the peaks and troughs propagate spatially.

The learner standing on platform 5 sees platform 6 begin its ascent a fraction of a second later, then platform 7, then 8. The wave appears to travel down the bridge. It does not. The motion is local. The pattern is emergent.

This is the spatial consequence of phase that Sine Space introduced through wall offsets. The corridor walls differed by a fixed phase and breathed asymmetrically. The oscillating bridge distributes phase incrementally across twenty platforms, producing wave propagation from individual oscillation. The phi term in QFEP's state evolution operates similarly — phase relationships between field contributions create coherent patterns from independently oscillating components. The bridge is a mechanical demonstration of constructive interference along a single spatial axis.

## Angular Velocity and TAU

The UnitCircle artifact advances its angle by `rotation_speed * delta` each frame. The quantity `rotation_speed` is angular velocity — radians per second. One full revolution equals `TAU` radians (approximately 6.2832). At `rotation_speed = 0.8`, the point completes one cycle in `TAU / 0.8` seconds — roughly 7.85 seconds.

```gdscript
@export var rotation_speed: float = 0.8

angle += rotation_speed * delta
```

The angular velocity is constant. The point moves at the same rate everywhere on the circle. This is uniform circular motion — the simplest possible rotation. The sine and cosine that result are pure, undistorted oscillations. Vary the angular velocity and the wave's frequency changes proportionally. Double `rotation_speed` and the point completes two cycles in the time it previously completed one. The bridge compresses. The wave frequency doubles.

Godot provides `TAU` as a built-in constant — the full circle in radians. It appears throughout the artifact:

```gdscript
var total_angle := TAU * num_cycles

for i in range(res):
    var th: float = float(i) / float(res) * TAU
```

TAU is the natural unit of angular measurement. One TAU is one revolution. Half TAU is a semicircle. Quarter TAU is a right angle. The decision to use TAU rather than `2 * PI` is a clarity choice — it maps one-to-one with the concept of "one full turn." The unit circle completes in TAU. The sine function repeats every TAU. The color wheel cycles through all hues in TAU. The constant unifies rotation, oscillation, and periodicity under a single value.

## The Radius Line: Connecting Origin to Circumference

A thin rod stretches from the circle's center to the rotating point:

```gdscript
radius_line = _make_line_node(Vector3.ZERO, Vector3(radius, 0, 0), point_color, line_thickness)

func _update_rotator_and_indicators() -> void:
    _update_line_node(radius_line, Vector3.ZERO, p, line_thickness)
```

The line rotates with the point, sweeping around the origin like a clock hand. Its length equals the radius — constant, unchanging. The sine and cosine projection lines vary; the radius does not. This visual contrast encodes the decomposition: the radius is the hypotenuse of a right triangle whose legs are `cos(angle) * radius` (horizontal) and `sin(angle) * radius` (vertical). The Pythagorean identity holds at every frame:

```
cos(angle)^2 + sin(angle)^2 = 1
```

The radius has length 1 (for a unit circle). The horizontal projection squared plus the vertical projection squared always equals the radius squared. The learner sees three lines — radius, sine projection, cosine projection — forming a right triangle that rotates smoothly. The triangle's shape changes as the angle sweeps, but its hypotenuse never stretches or shrinks. The identity is geometric before it is algebraic.

## The OscillationCurve: Time Made Visible

Flanking the amphitheater, the OscillationCurve artifact draws the wave as a trailing line:

```gdscript
func _process(delta):
    time += delta
    var signal_value = sin(time * frequency)
    var y_pos = signal_value * amplitude

    driver_ball.position.y = y_pos

    points.push_front(Vector3(0, y_pos, 0))
    for i in range(points.size()):
        points[i].x += speed * delta

    if points.size() > max_points:
        points.pop_back()
```

A ball oscillates vertically — pure sine motion. Each frame, the ball's current position is pushed to the front of a point array. All existing points shift rightward by `speed * delta`. The result is an oscilloscope trace: the ball writes its own history as a curve extending into space. New values appear at the ball's position and scroll away.

The `ImmediateMesh` renders the trace as a line strip:

```gdscript
func _draw_trail():
    trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for p in points:
        trail_mesh.surface_add_vertex(p)
    trail_mesh.surface_end()
```

Every frame, the mesh is cleared and rebuilt from the current point array. This is brute-force rendering — no retained geometry, no optimization. For 200 points, the cost is negligible. The result is a live sine wave unspooling from the oscillating ball. The learner sees the unit circle's projection (via the rotating point) and the OscillationCurve's trace (via the scrolling line) and recognizes them as the same shape. Two artifacts, two rendering strategies, one function.

## Color as Phase Encoding

The UnitCircle artifact maps angular position to the HSV color wheel. The bridge platforms inherit this mapping:

```gdscript
if color_platforms_from_wheel and use_color_wheel:
    var wheel_color = _get_wheel_color(step_angle, platform_wheel_value)
    m.albedo_color = wheel_color
    m.emission_enabled = true
    m.emission = wheel_color * 0.35
```

A platform at `step_angle = 0` is red. At `step_angle = TAU/3`, green. At `step_angle = 2*TAU/3`, blue. The color repeats every TAU — one full cycle, one full spectrum. The bridge becomes a chromatic record of the circle's rotation. Walking along it, the learner traverses the color wheel linearly. The hue gradient reinforces periodicity: when the colors repeat, the wave has completed a cycle.

The emission component — `wheel_color * 0.35` — provides self-illumination proportional to color intensity. The bridge glows. In VR, this glow ensures legibility in low-ambient environments. The `platform_wheel_value` parameter controls brightness independently of hue, allowing the bridge to read distinctly from the brighter circle outline (which uses `wheel_value` at a higher setting).

The colorballs artifact scattered through the amphitheater adds perceptual punctuation — physics-driven spheres in palette colors that bounce and roll, marking spatial positions without mathematical significance. Their randomness contrasts with the precision of the circle and bridge. Order and chaos coexist in the same space. The learner distinguishes signal from noise by observing which elements follow the sine curve and which do not.

## Possible Artifacts

**projection_unwinder** — An interactive artifact that lets the learner grab the rotating point and drag it around the circle manually. As the point moves, the sine and cosine projection lines update in real time, and a trace extends along the bridge axis showing the wave being drawn. A pause button freezes the point at any angle, displaying the exact values of sin(theta) and cos(theta) alongside the right triangle formed by the radius and projections. Converts passive observation into active exploration of the rotation-to-oscillation mapping.

**frequency_dial** — A physical dial artifact mounted on the amphitheater wall that controls the UnitCircle's `rotation_speed`. Turning the dial clockwise increases angular velocity; the point spins faster, the bridge platforms compress, the OscillationCurve trace tightens. Turning counterclockwise slows everything. A readout displays the current frequency in hertz (cycles per second) and the corresponding period in seconds. Connects the abstract concept of frequency to a tangible control and its visible consequence on wave shape.

**dual_circle_phase_comparator** — Two unit circles side by side, rotating at the same speed but offset by a configurable phase angle. Each circle projects its own sine wave onto a shared bridge. The two waves overlap, and their sum is drawn as a third curve. At zero phase offset, the waves reinforce perfectly — double amplitude. At PI offset, they cancel — flat line. At intermediate offsets, the interference pattern varies continuously. Demonstrates superposition and phase interference using the same circular-motion foundation, bridging directly into the wave propagation concepts of the next map.

**pythagorean_identity_visualizer** — An artifact that displays three bars alongside the unit circle: one representing cos(theta) squared, one representing sin(theta) squared, and one representing their sum. As the point rotates, the first two bars fluctuate inversely — when cosine squared grows, sine squared shrinks — but the third bar remains fixed at exactly 1.0. A numerical readout confirms the identity at every angle. Makes the Pythagorean relationship tactile: the learner sees that the two projections always trade magnitude while their squared sum stays constant.
