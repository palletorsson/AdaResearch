# Keep the values, change the bins

## Learning elements

- Uniform and Gaussian sampling rules.
- Mean and standard deviation as parameters.
- Retaining a sample before displaying it.
- Clipping a value and assigning a bin.
- Recounting without drawing again.

Find the distribution cabinet. Press PAUSE, let the airborne beads land, then CLEAR. Press BATCH three times. You have three hundred values. Press BINS: the bars change, but the total does not. Return to the original number of bins. What returned with it?

Random Walk kept positions in their order of arrival. Here we keep a list of numbers and group them into intervals. Entropy supplied counts; Arrays supplied the list and loop. The familiar PointBody returns as the control you hold. The new work is the relation between **drawing, keeping and counting**.

## Rebuild a small comparison

Work in your copy of Endless Museum. Attach `08_values_and_bins.gd` to an empty `Node3D` under Random Gaussian; keep the unchanged `point_body.gd` beside it. Day Zero already supplies the player, camera, lighting and XR Tools. This script builds its own display and labels. Its boxes are display meshes, not colliders.

The tested temporary station sits at hall-local `(3, 0, 7)`, turned 90° about Y. Leave room on its local positive-Z side to approach. The installed distribution cabinet remains in the hall.

Use the point as in Random Rotate: hold it over a labelled position and press the trigger. Moving it alone changes nothing. From left to right:

- **REPLAY** regenerates the present number of values from the seed, under the same law and parameters. It keeps the current bins.
- **+100** adds up to one hundred values, stopping at the run's limit of three hundred.
- **BINS** switches between ten and twenty intervals using the stored values.
- **LAW** switches GAUSS / UNIFORM and clears the sample. Press +100 three times to compare at equal count.

The display starts empty. There is no falling animation or automatic timer in this reconstruction: all samples count immediately. Start by reading `sample_value()`, `batch()` and `rebin()`; the remaining code constructs the display and connects the inherited action.

<!-- student-code:08_values_and_bins.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const WIDTH := 2.2
const BOTTOM := 1.3
@export var seed_value := 42
@export var gaussian := true
@export_range(0.0, 1.0) var mean := 0.5
@export_range(0.01, 0.5) var deviation := 0.15
@export_range(1, 1000) var sample_limit := 300
var rng := RandomNumberGenerator.new()
var values: Array[float] = []
var counts: Array[int] = []
var bin_count := 10
var clipped := 0
var bars := Node3D.new()
var status: Label3D
var peak_label: Label3D
var point: XRToolsPickable

func _ready() -> void:
    box(self, Vector3(0, 0.5, 0), Vector3(1, 1, 0.6), Color(0.88, 0.86, 0.82))
    box(self, Vector3(0, 1.93, -0.08), Vector3(2.65, 1.75, 0.08), Color(0.88, 0.86, 0.82))
    box(self, Vector3(0, 0.9, 0.6), Vector3(2.5, 0.06, 0.55), Color(0.88, 0.86, 0.82))
    add_child(bars)
    status = label("", Vector3(0, 2.62, 0))
    peak_label = label("", Vector3(-0.8, 2.39, 0))
    for i in range(3):
        label(str(i * 0.5), Vector3((i * 0.5 - 0.5) * WIDTH, 1.17, 0))
    var names := ["REPLAY", "+100", "BINS", "LAW"]
    for i in range(4):
        label(names[i], Vector3(-0.9 + i * 0.6, 0.8, 0.9))
    point = PointBody.new()
    point.position = Vector3(-0.3, 1.1, 0.6)
    add_child(point)
    point.action_pressed.connect(point_action)
    clear()

func sample_value() -> float:
    if not gaussian:
        return rng.randf()
    var u1 := maxf(rng.randf(), 0.0001)
    var u2 := rng.randf()
    var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
    return mean + deviation * z

func batch(n: int = 100) -> void:
    for i in range(clampi(n, 0, sample_limit - values.size())):
        values.append(sample_value())
    rebin(bin_count)

func rebin(n: int) -> void:
    bin_count = clampi(n, 2, 60)
    counts.resize(bin_count)
    counts.fill(0)
    clipped = 0
    for raw in values:
        if raw < 0.0 or raw > 1.0:
            clipped += 1
        var value := clampf(raw, 0.0, 1.0)
        var index := mini(int(value * bin_count), bin_count - 1)
        counts[index] += 1
    redraw()

func clear() -> void:
    rng.seed = seed_value
    values.clear()
    rebin(bin_count)

func replay() -> void:
    var amount := values.size()
    clear()
    batch(amount)

func switch_law() -> void:
    gaussian = not gaussian
    clear()

func cycle_bins() -> void:
    rebin(20 if bin_count == 10 else 10)

func point_action(_body: XRToolsPickable) -> void:
    var x := to_local(point.global_position).x
    if x < -0.6:
        replay()
    elif x < 0.0:
        batch()
    elif x < 0.6:
        cycle_bins()
    else:
        switch_law()

func redraw() -> void:
    for bar in bars.get_children():
        bars.remove_child(bar)
        bar.queue_free()
    var peak := 0
    for count in counts:
        peak = maxi(peak, count)
    var width := WIDTH / bin_count
    var colour := Color(0.98, 0.55, 0.72) if gaussian else Color(0.18, 0.18, 0.18)
    for i in range(bin_count):
        if counts[i] == 0:
            continue
        var height := float(counts[i]) / maxi(1, peak)
        box(bars, Vector3(-WIDTH / 2 + (i + 0.5) * width, BOTTOM + height / 2, 0.04), Vector3(width * 0.85, height, 0.08), colour)
    var law := "GAUSS" if gaussian else "UNIFORM"
    status.text = "%s | seed %d | N %d / %d\n%d bins | %d values clipped for display" % [law, seed_value, values.size(), sample_limit, bin_count, clipped]
    peak_label.text = "TOP = %d COUNTS" % peak

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    body.material_override = material
    body.position = at
    parent.add_child(body)

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
```

## Give a draw a law

UNIFORM returns one `randf()` value in the interval from zero to one. GAUSS transforms two such draws. It uses the same guarded Box–Muller recipe as the installed cabinet. The logarithm and square root set a radius; the cosine takes one component. We use that recipe here without deriving it or adding a second sampler implementation.

The intermediate `z` approximates a normal variable centred at zero with standard deviation one. `mean + deviation * z` moves its centre and changes its spread. With our defaults, the mean parameter is 0.5 and the standard-deviation parameter is 0.15. Those describe the generating rule; this particular finite sample need not have exactly that mean or deviation.

`log(0)` is outside the recipe's domain. `maxf(..., 0.0001)` supplies a lower guard without shifting every valid draw. Together with the finite generator it makes an approximation, not a source of arbitrarily distant tails. The computed `z` cannot exceed about 4.29 in magnitude. More UNIFORM draws do not turn their law into GAUSS.

The two laws also spend the seeded stream differently: one draw per uniform sample, two per Gaussian sample. Equal seeds do not mean the two lists contain paired observations of the same value.

## Keep first, count second

`batch()` appends each raw result to `values`. The loop stops at the remaining capacity. Its job is sampling. `rebin()` makes a fresh list of zero counts, then reads the saved values. Its job is grouping. There is no random call inside it.

For ten bins, 0.23 belongs to index 2: multiply by ten, then take the integer part. Internal boundaries belong to the bin on their right. One needs special treatment: multiplying 1.0 by ten gives ten, but the last valid index is nine. `mini()` keeps that endpoint in the final bin.

Values outside zero to one are counted at the nearest display edge. This is clipping, not the reflection from Random Walk. The `clipped` counter records how many raw values crossed those edges. The first and last bins also contain values already inside the interval, so their total is not the clipped count.

Our `values` list keeps the **raw** number. Only the temporary `value` used for indexing is clamped. That makes the lost distance beyond an edge available to inspect. The installed cabinet keeps the already-clamped landed values and a separate clipped counter. This small reconstruction deliberately keeps more of the sample; the difference is part of the lesson.

After BINS, every raw value, its order, the clipped total and the generator state remain. The counts change because the partition changes. Returning to ten bins restores their earlier counts. No new observation was needed.

## Read the height carefully

The bars are made from the cube mesh you already know, changing only size and position. Zero counts have no bar. Each positive count is divided by the highest count, making the tallest bar one metre high. The label names that changing top count.

A single observation can therefore make a full-height bar. N tells you how much evidence is present; height alone does not. Unlike the cabinet, this study has no theoretical curve or expected-count bars. It shows the sample's counts, not a guarantee about what the next sample should look like.

## The point you already have

The point's pickup, release and trigger signal come from the same class. Converting its global position into the station's local frame keeps the four action zones attached to the station if it turns. Release does not make a new draw.

<details>
<summary>Complete unchanged PointBody dependency</summary>

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

</details>

## Make a change you can explain

1. Keep GAUSS and the seed. Change `deviation` from `0.15` to `0.30`, then restart the scene and collect the same number of values. Each raw distance from 0.5 doubles. The displayed histogram need not double its width: the screen still clips at zero and one. Check both the raw record and the clipped count.
2. Change `sample_limit` from `300` to `150`. The first +100 adds one hundred; the next adds fifty; further presses draw nothing. The first hundred values remain the prefix of the same seeded run. A taller-looking picture is not necessarily a larger sample.
3. In `cycle_bins()`, change twenty to forty. Keep the saved values and compare ten with forty bins. The number of bins changes, not the generator or the number of observations.

For an independent check, set `values` to `[-0.2, 0.0, 0.05, 0.49, 0.5, 0.99, 1.0, 1.3]`, then call `rebin(2)`. Predict both counts and the clipped total before running it. Two bins should each contain four values; only two values were outside the screen. Rebin to ten and explain each occupied interval. This uses deliberately supplied data, not another random run.

To repeat a sampled run, preserve the seed, law, parameters, amount and draw order in the same engine version. REPLAY regenerates that many values; BINS simply rereads the existing ones. They are different kinds of return.

## Return to the cabinet

The installed BINS cycles 30 → 60 → 10 → 30. PAUSE stops issuing new samples, while existing beads can still land. BATCH counts immediately, reserving capacity for those in flight. CLEAR empties both and resets the named generator while preserving paused/running state. WIDTH changes the Gaussian deviation and clears the sample; it is not a way to stretch the same stored values.

Blue and pale model bars share a count scale there. The orange line has a separate shape scale. Leave Poisson, exponential and their additional mathematics as comparisons for now. At the paint-splatter plate, a central region rejects some drawn positions altogether: another rule intervenes between sampling and what you see.

In Random Mushrooms the retained number becomes a parameter of a body. Keep this distinction with you: choose a value, decide what it may change, then construct the form.
