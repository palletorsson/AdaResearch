extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var frequency_a := 5.0
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
    point.position = Vector3(-2.1, 1.45, 0.5)
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
