extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const TURNS := [30.0, 60.0, 90.0, 120.0]
const CURVE := {"F": "F+F"}
const CANTOR := {"F": "FfF", "f": "fff"}
var model = Grammar.new()
var rules: Dictionary = CURVE.duplicate()
var sentence := "F"
var angle := 90.0
var generation := 0
var held: Dictionary = {}
var limited := false
var point: XRToolsPickable
var drawing: Node3D
var captions: Array[Label3D] = []
var title: Label3D

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(advance)
	for x in [-0.85, 0.85]:
		captions.append(label("", Vector3(x, 1.08, 0)))
	title = label("", Vector3(0, 3.05, 0))
	label("TRIGGER / ENTER: NEXT     H: HOLD     R: RESET     C: CURVE / CANTOR", Vector3(0, 0.78, 0.5))
	for i in TURNS.size():
		label(str(int(TURNS[i])), Vector3((i - 1.5) * 0.35, 0.99, 0.55))
	keep()
	park()

func advance(_body = null) -> void:
	if generation >= 4:
		return
	var result: Dictionary = model.rewrite(sentence, rules)
	limited = not result.accepted
	if result.accepted:
		sentence = result.text
		generation += 1
	redraw()

func keep() -> void:
	held = {"text": sentence, "angle": angle, "generation": generation}
	redraw()

func reset_live() -> void:
	sentence = "F"
	generation = 0
	limited = false
	redraw()

func choose(index: int) -> void:
	var selected: float = TURNS[clampi(index, 0, TURNS.size() - 1)]
	if angle != selected:
		angle = selected
		redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1.5))
	else:
		park()

func park() -> void:
	var x := (TURNS.find(angle) - 1.5) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.15, 0.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER: advance()
		KEY_H: keep()
		KEY_R: reset_live()
		KEY_C:
			rules = CANTOR.duplicate() if rules == CURVE else CURVE.duplicate()
			reset_live()

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var live := {"text": sentence, "angle": angle, "generation": generation}
	for i in 2:
		var reading: Dictionary = live if i == 0 else held
		var ends: Array[Vector3] = model.read(reading.text, reading.angle)
		draw_reading(ends, Vector3(-0.85 if i == 0 else 0.85, 1.42, 0), Color("78dccc") if i == 0 else Color("f0b3db"))
		var prefix: String = reading.text.substr(0, 40)
		if reading.text.length() > 40:
			prefix += " ... (first 40)"
		captions[i].text = "%s / gen %d / %.0f deg\n%d symbols / %d segments\n%s" % ["LIVE" if i == 0 else "HELD", reading.generation, reading.angle, reading.text.length(), ends.size() / 2, prefix]
	title.text = ("SAME SENTENCE" if sentence == held.text else "DIFFERENT SENTENCES") + "\nEach drawing fitted independently"
	if limited:
		title.text += "\nSYMBOL LIMIT: previous complete generation retained"

func draw_reading(ends: Array[Vector3], origin: Vector3, colour: Color) -> void:
	if ends.is_empty():
		return
	var low := ends[0]
	var high := ends[0]
	for end in ends:
		low = low.min(end)
		high = high.max(end)
	var fit := 1.4 / maxf((high - low).x, (high - low).y)
	var anchor := Vector3((low.x + high.x) * 0.5, low.y, 0)
	for i in range(0, ends.size(), 2):
		var a := origin + (ends[i] - anchor) * fit
		var b := origin + (ends[i + 1] - anchor) * fit
		var rod = LineSkin.new()
		rod.material_override.albedo_color = colour
		drawing.add_child(rod)
		rod.show_segment(a, b - a, a.distance_to(b))

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.0012
	tag.outline_size = 6
	add_child(tag)
	return tag
