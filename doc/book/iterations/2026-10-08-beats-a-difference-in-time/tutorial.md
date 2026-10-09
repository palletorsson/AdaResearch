# A difference in time

## Learning elements

- Adding two signed signals
- Frequency difference and beat period
- A shared start and changing relative phase
- Keeping raw values separate from display gain

At the beat display, bring the two frequency controls close together. A and B move quickly. Their sum grows and shrinks more slowly. At a quiet moment in the lower row, the sources above it can still be moving.

Air Music kept two voices and their playback ages. Here we isolate their relationship: two unit-amplitude sines, started together, at slightly different frequencies. The black PointBody chooses B; the familiar LineSkin draws A, B and their sum. Sky Stairs gave samples solid support. These samples make a visual comparison again. They do not form a floor or produce sound.

## Continue inside the museum

Use the prepared Endless Museum project, with its player, XR pickup, lighting and camera. Save the three scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `11_two_cycles.gd` to an empty Node3D in this hall's learner bay: **hall-local (23, 0, 12), Y rotation 180 degrees, unit scale**. Run the museum scene as before. The program creates its own point, lines and labels; no named scene children are required.

Grab the black point. Its local height previews B between 0.5 Hz below and 0.5 Hz above A. At 1.2 metres, B equals A. Press the held object's established trigger action to apply the preview and restart both waves together. Moving the point alone leaves the current pair running. This keeps the chosen frequency fixed during each observation.

## Two sources, one sum

`values_at()` returns three signed values: A, B and their raw sum. Negative values matter. A positive value and an equal negative value cancel; neither source has disappeared. With unit-amplitude inputs, the raw sum lies between −2 and +2.

<!-- student-code:11_two_cycles.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var frequency_a := 4.0
var frequency_b := 4.5
var elapsed := 0.0
var segments := 64
var width := 3.2
var height_gain := 0.22
var row_heights := [2.35, 1.75, 1.15]
var rows: Array = []
var point: RigidBody3D
var label: Label3D
var values_label: Label3D

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(-2.1, 1.7, 0.5)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(on_action)
    label = text_at("", Vector3(0, 2.95, 0), 26)
    values_label = text_at("", Vector3(0, 0.7, 0), 21)
    text_at("Raise point to choose B. Trigger starts both together.", Vector3(0, 0.43, 0), 21)
    var colours := [Color(0.55, 0.7, 1), Color(0.82, 0.88, 0.8), Color(0.98, 0.7, 0.82)]
    var names := ["A", "B", "(A+B) / 2"]
    for row in range(3):
        var lines: Array = []
        var finish := StandardMaterial3D.new()
        finish.albedo_color = colours[row]
        for i in range(segments):
            var line := LineSkin.new()
            line.material_override = finish
            add_child(line)
            lines.append(line)
        rows.append(lines)
        text_at(names[row], Vector3(-2.0, row_heights[row], 0), 20)
    restart_pair()

func candidate_frequency() -> float:
    return frequency_a + clampf(point.position.y - 1.2, -0.5, 0.5)

func on_action(_held: Variant) -> void:
    restart_pair()

func restart_pair() -> void:
    frequency_b = candidate_frequency()
    elapsed = 0.0
    draw_state()

func values_at(time: float, phase: float) -> Vector3:
    var a := sin(TAU * frequency_a * time + phase)
    var b := sin(TAU * frequency_b * time + phase)
    return Vector3(a, b, a + b)

func plot_position(row: int, u: float) -> Vector3:
    var values := values_at(elapsed, u * TAU * 2.0)
    var value: float = values[row]
    if row == 2:
        value *= 0.5
    return Vector3(-width * 0.5 + u * width, row_heights[row] + height_gain * value, 0)

func _process(delta: float) -> void:
    elapsed += delta
    draw_state()

func draw_state() -> void:
    for row in range(3):
        var previous := plot_position(row, 0.0)
        for i in range(segments):
            var next := plot_position(row, float(i + 1) / segments)
            var displacement := next - previous
            rows[row][i].show_segment(previous, displacement, displacement.length())
            previous = next
    var difference := absf(frequency_a - frequency_b)
    var beat_text := "equal frequencies: no drifting envelope"
    if difference > 0.00001:
        beat_text = "beat %.2f Hz | repeats every %.2f s" % [difference, 1.0 / difference]
    label.text = "A %.2f Hz | B %.2f Hz\n%s\nB preview %.2f Hz | trigger to apply" % [frequency_a, frequency_b, beat_text, candidate_frequency()]
    var values := values_at(elapsed, PI * 0.5)
    values_label.text = "At phase PI/2: A %+.2f | B %+.2f | raw sum %+.2f\nBottom row drawn at half the raw sum" % [values.x, values.y, values.z]
```


Both waves use the same elapsed time and the same added phase at each horizontal position. Two turns of that shared phase fill each row. This is a set of phase-shifted copies of the same comparison, not a simulation of a wave travelling through material. Follow one fixed horizontal position to compare the fast oscillation with its slower envelope.

`plot_position()` applies half gain only when drawing the bottom row. `values_at()` and the numeric readout retain the raw sum. If the bottom row reaches the same height as A, that does not mean their raw amplitudes are equal: the drawing scales differ. The label says `(A+B) / 2` for this reason.

The PointBody signal passes the held object to `on_action()`. We do not need that argument here; the callback simply starts a new comparison. Restarting resets the common clock as well as applying B. Equal frequencies therefore begin aligned in this study. Two equal-frequency sources started with different phases would retain that difference; equal frequency alone does not guarantee reinforcement.

## What changes slowly?

Begin with A = 4 Hz and B = 4.5 Hz. Their phase difference grows by half a turn each second. One second after the shared start, they oppose one another throughout the rows. After two seconds they align again. The large changes in amplitude repeat every two seconds: **0.5 beats per second**.

In general, the beat rate is `abs(A − B)` and the period is its reciprocal. The equal-frequency case needs a separate branch: there is no finite beat period to calculate. In the sum identity, a signed cosine factor changes sign; the visible amplitude follows its absolute size. Count successive loud-looking envelopes, not only positive peaks of that factor.

The existing museum exhibit updates its frequencies continuously as you move its sliders. Our trigger commits a pair and resets its start, making the predicted one-second cancellation easy to repeat. Both displays are visual. A later audible experiment would need an audio source; moving a visible sphere does not create sound.

## The carried pieces

These are the same grabbable sphere and finite-cylinder line renderer. Their full files are included so the reconstruction is complete. The main script applies the black finish and the three row colours.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Predict, change, return

1. Start the default pair. Follow one horizontal position through narrowing and widening. At the narrow moment, inspect both inputs and the raw sum readout.
2. Hold the point at local height 1.45 metres: B previews 4.25 Hz. Trigger. Predict the new period before watching: four seconds, with opposition after two.
3. Move the point to 0.95 metres and trigger. B is now 3.75 Hz. The absolute difference is still 0.25 Hz. The beat period stays four seconds although the faster source has changed.
4. Set the point to 1.2 metres and trigger. Both frequencies are 4 Hz. The sum keeps twice either source's raw value; half gain makes the lower row's excursion match the upper ones.

For an independent variation, set `frequency_a` to `5.0` and the point's initial Y to `1.45`. Before running, predict B = 5.25 Hz and the same four-second envelope period despite the faster sources. The complete `11_faster_pair.gd` variation is included; attach it instead of the original.

Native assertions run the exact printed files. They test the PointBody action callback, local-height mapping in a moved and rotated host, values at known phases, cancellation and reinforcement, the four-second variation, equal frequencies and display gain. Deliberate sign, gain and restart faults must fail. This verifies the program's behaviour, not a reader's understanding or headset comfort.

The red-and-blue paths remain a different comparison: sine and cosine distributed through finite circulating rows. The Lissajous figure gives separate coordinates to oscillations instead of adding them on one axis. Keep these constructions distinct. In Synthesis Lab, we will retain the signed sum and change how much several harmonic components contribute.
