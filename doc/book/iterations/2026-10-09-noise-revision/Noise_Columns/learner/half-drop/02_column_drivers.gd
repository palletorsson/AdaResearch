extends Node3D

const Shaft = preload("shaft.gd")
const PointBody = preload("point_body.gd")
const KINDS := ["held", "periodic", "field"]
@export var top_drop := 0.35
var time := 0.0
var playing := true
var next_update := 0.0
var phases: Array[float] = []
var shafts: Array[MeshInstance3D] = []
var noise := FastNoiseLite.new()
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    noise.seed = 31415
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise.frequency = 0.35
    noise.fractal_type = FastNoiseLite.FRACTAL_NONE
    for i in range(KINDS.size()):
        var shaft := Shaft.new()
        shaft.position.x = (i - 1) * 1.1
        add_child(shaft)
        shafts.append(shaft)
    control = PointBody.new()
    control.position = Vector3(0, 1.0, 1.0)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(toggle_clock)
    label.position = Vector3(0, 2.9, 0)
    label.font_size = 28
    label.pixel_size = 0.0025
    add_child(label)
    draw_values()
    next_update = 1.0 / 12.0

func driver(kind: String, seconds: float) -> float:
    match kind:
        "periodic":
            return sin(seconds * 0.9) * 0.5 + 0.5
        "field":
            return clampf(noise.get_noise_2d(seconds * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
        _:
            return 0.10

func _process(delta: float) -> void:
    if not playing:
        return
    time += delta
    if time >= next_update:
        draw_values()
        next_update = time + 1.0 / 12.0

func draw_values() -> void:
    phases.clear()
    for i in range(shafts.size()):
        var value := driver(KINDS[i], time)
        phases.append(value)
        shafts[i].receive(value, top_drop)
    draw_label()

func draw_label() -> void:
    label.text = "HELD %.2f / SINE %.2f / FIELD %.2f\nLOCAL %.2f s / %s / GRIP + TRIGGER: pause" % [phases[0], phases[1], phases[2], time, "RUN" if playing else "HELD"]

func toggle_clock(_held: Variant) -> void:
    playing = not playing
    # Update the status without replacing the shape held between mesh updates.
    draw_label()
