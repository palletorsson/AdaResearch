extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var baseline: Array[float] = [1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]
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
