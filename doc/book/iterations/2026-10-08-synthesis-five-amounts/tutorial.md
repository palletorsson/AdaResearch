# Five amounts, one shape

## Learning elements

- Harmonic number and coefficient
- A weighted sum from a list and loop
- Holding phase while comparing recipes
- Copying a baseline without resetting the clock
- The limits of a finite representation

Find the dark synthesis bench in the museum. Press HOLD. Lower H2 through H5 one by one. The pale curve changes until only a sine remains. None of the five smooth component rows has the slope you first saw; the slope belonged to their sum.

In Beats, two nearby frequencies drifted in and out of alignment. Here the frequencies stay in integer ratios: one, two, three, four and five times a fundamental. We change their amounts. The unchanged PointBody returns five times as a hand control; LineSkin draws the five contributions and their sum. Arrays supplies the list, and Trace supplies the loop through stored entries.

## Build beside the existing bench

Use the prepared Endless Museum, with its player, XR Tools, camera and lighting. Save the three scripts below together. Attach `12_five_amounts.gd` to an empty Node3D at **hall-local (16, 0, 11), Y rotation 180 degrees, unit scale**. The script creates all five points, six rows and labels. Keep `point_body.gd` and `line_skin.gd` unchanged.

Raise a point to increase its harmonic's amount. Local Y = 0.8 metres means zero; 1.6 metres means one. Release it to keep that height. Horizontal movement does not change its coefficient. Each point keeps its harmonic identity even if you move it past another.

The display starts held. The **H1 point's trigger toggles HOLD/RUN**. The **H5 point's trigger restores BASELINE**, releasing any held controls and returning their heights. It preserves the phase and held state. These are the established PointBody actions; we are giving them new jobs.

## Multiply a contribution, then add it

`amounts[h]` is a coefficient. `h + 1` is the harmonic number because array indices begin at zero. The coefficient changes the amount; the harmonic number changes how many cycles fit in one fundamental cycle. A nonnegative coefficient can still contribute a negative value when its sine is below zero.

<!-- student-code:12_five_amounts.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var baseline: Array[float] = [1.0, 0.5, 1.0 / 3.0, 0.25, 0.2]
var amounts: Array[float] = []
var points: Array = []
var rows: Array = []
var phase := 0.0
var held := true
var segments := 64
var width := 3.2
var gain := 0.16
var label: Label3D

func text_at(words: String, at: Vector3, size: int = 22) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    amounts = baseline.duplicate()
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    for h in range(amounts.size()):
        var point := PointBody.new()
        point.position = Vector3(-1.4 + h * 0.7, 0.8 + amounts[h] * 0.8, 0.75)
        point.get_child(0).material_override = ink
        add_child(point)
        points.append(point)
        text_at("H%d" % (h + 1), Vector3(point.position.x, 0.6, 0.75))
    points[0].action_pressed.connect(toggle_hold)
    points[4].action_pressed.connect(restore_baseline)
    label = text_at("", Vector3(0, 3.55, 0), 23)
    text_at("Raise each point: amount 0 to 1\nH1 trigger: HOLD / RUN     H5 trigger: BASELINE", Vector3(0, 0.34, 0.75), 20)
    for row in range(6):
        var lines: Array = []
        var finish := StandardMaterial3D.new()
        finish.albedo_color = Color(0.98, 0.7, 0.82) if row == 5 else Color.from_hsv(float(row) / 5.0, 0.4, 0.95)
        for i in range(segments):
            var line := LineSkin.new()
            line.material_override = finish
            add_child(line)
            lines.append(line)
        rows.append(lines)
        text_at("SUM" if row == 5 else "H%d" % (row + 1), Vector3(-1.9, row_height(row), 0), 20)
    draw_state()

func read_amounts() -> void:
    for h in range(points.size()):
        amounts[h] = clampf((points[h].position.y - 0.8) / 0.8, 0.0, 1.0)

func contribution(h: int, angle: float) -> float:
    return amounts[h] * sin((h + 1) * angle)

func sum_at(angle: float) -> float:
    var total := 0.0
    for h in range(amounts.size()):
        total += contribution(h, angle)
    return total

func row_height(row: int) -> float:
    return 2.95 if row == 5 else 2.4 - row * 0.29

func plot_position(row: int, u: float) -> Vector3:
    var angle := u * TAU + phase
    var value := sum_at(angle) if row == 5 else contribution(row, angle)
    return Vector3((u - 0.5) * width, row_height(row) + gain * value, 0)

func toggle_hold(_point: Variant = null) -> void:
    held = not held
    draw_state()

func restore_baseline(_point: Variant = null) -> void:
    amounts = baseline.duplicate()
    for h in range(points.size()):
        points[h].drop()
        points[h].position.y = 0.8 + amounts[h] * 0.8
    draw_state()

func _process(delta: float) -> void:
    read_amounts()
    if not held:
        phase = fposmod(phase + TAU * 0.2 * delta, TAU)
    draw_state()

func draw_state() -> void:
    for row in range(rows.size()):
        var previous := plot_position(row, 0.0)
        for i in range(segments):
            var next := plot_position(row, float(i + 1) / segments)
            var displacement := next - previous
            rows[row][i].show_segment(previous, displacement, displacement.length())
            previous = next
    var values := PackedStringArray()
    for h in range(amounts.size()):
        values.append("H%d %.3f" % [h + 1, amounts[h]])
    label.text = "%s | phase %.2f rad\n%s\nAll rows: %.2f m per signal unit" % ["HOLD" if held else "RUN", phase, "   ".join(values), gain]
```


`sum_at()` starts a new total for each angle. It does not add yesterday's curve to today's. Each pass through the loop adds one signed contribution at the same angle. This is the familiar sum extended from two named values to a list.

The baseline is copied with `duplicate()`. Editing the working list must not edit the recipe we hope to restore. `restore_baseline()` copies it again, moves the handles and leaves `phase` alone. The inherited `drop()` releases a held control before repositioning it; otherwise the hand would continue commanding its position.

## Hold one thing still

While held, move a point and inspect the resulting change at one fixed horizontal position. Only when RUN is selected does `_process()` advance the common phase, at 0.2 fundamental cycles per second. Multiplying that shared angle by each harmonic number keeps the ratios intact.

At phase zero, a quarter of the way across the rows is angle PI/2. H1 contributes +1; H3 contributes −1/3; H5 contributes +1/5. H2 and H4 are zero there. Predict the total: about 0.867. Now remove H3. The sum rises to 1.2 at that place. Removing something can increase the result because what you removed was negative.

All six rows use the **same gain: 0.16 metres per signal unit**. Their baselines are vertically separated, so add displacements from those baselines, not absolute screen heights. Unlike the last lesson, the sum has no extra half gain. It can extend farther than any component. The display does not normalize it when you change the recipe.

The program draws one fundamental cycle as 64 cylinder segments. Five harmonics do not make an exact sawtooth jump. The finite sum is smooth; the displayed polyline is a further sampling of it. These are two separate limits. This construction also supplies no negative coefficient, independent phase or constant offset. It does not express every periodic shape, and it produces no sound.

## The carried pieces

These are the earlier grabbable point and finite-cylinder renderer. Their complete files remain here so the example can be reconstructed.

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


## Make a change you can explain

1. With the display held, remove H3. Predict the change at the quarter-cycle position, then inspect it. Restore BASELINE with H5's trigger.
2. Lower H2 through H5. Compare the sum with H1. Their displacement should agree because they use the same gain. Lower H1 too: all rows become flat.
3. Run the phase, then hold it. Change several amounts and restore BASELINE. The old shape returns at the held phase. Repeat while running: the recipe returns, but time keeps moving.
4. Build a second recipe: `[1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]`. Before running it, predict what the second half of a cycle will do. With only odd harmonics, it is the negative of the first half. The complete `12_odd_recipe.gd` variation is included in the code download.

The museum bench uses the same weighted-sine principle with sliders, four visible cycles and finer sampling. Its component rows and sum have different drawing gains; its H3 baseline is rounded to 0.333. It hides component ribbons below 0.01 and assigns recipe names within a tolerance. Our reduced study keeps every component line and does not classify recipes. Those extra display decisions are useful to investigate in the exhibit without rebuilding them here.

Native checks execute the exact printed files, known signed contributions, both PointBody actions, baseline independence, phase preservation, displayed geometry and the odd-harmonic variation. Deliberately wrong indexing, unsigned contributions and a shared baseline must fail. Passing these checks establishes code behaviour; it does not establish a reader's understanding or headset comfort.

## What travels onward

In the separate Room Memory encounter, each filtered recording becomes the next input. This tutorial recalculates a curve from a recipe instead. Keep that difference. To recover the same curve at the same instant, we need both its amounts and its phase. Random Definition will ask what else must be retained when the next result is chosen rather than prescribed by this cycle.
