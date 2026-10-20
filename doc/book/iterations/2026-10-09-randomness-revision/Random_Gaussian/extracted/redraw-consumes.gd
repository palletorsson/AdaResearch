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
    rng.randf()
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
