extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "F[+F]F[-F]F"}
const RATIOS := [0.45, 0.72, 1.0, 1.15]
var model = Grammar.new()
var sentence := ""
var ratio := 0.72
var generation := 1
var cursor := 1
var reading: Dictionary = {}
var held: Dictionary = {}
var point: XRToolsPickable
var drawing: Node3D
var title: Label3D
var captions: Array[Label3D] = []

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(step)
	title = label("", Vector3(0, 2.2, 0))
	for x in [-3.0, 3.0]:
		captions.append(label("", Vector3(x, 0.18, 0.25)))
	label("TRIGGER / ENTER: STEP   H: HOLD   T: TREE   R: RESET", Vector3(0, 0.9, 2.55))
	for i in RATIOS.size():
		label("%.2f" % RATIOS[i], Vector3((i - 1.5) * 0.35, 1.02, 2.55))
	reset()
	park()

func set_tree(depth: int) -> void:
	var next := "F"
	for i in clampi(depth, 1, 2):
		var result: Dictionary = model.rewrite(next, RULE)
		if not result.accepted:
			title.text = "Symbol limit: previous reading retained."
			return
		next = result.text
	var candidate: Dictionary = model.read(next, ratio)
	if not candidate.accepted:
		title.text = candidate.error
		return
	sentence = next
	generation = clampi(depth, 1, 2)
	reading = candidate
	cursor = sentence.length()
	redraw()

func step(_body = null) -> void:
	cursor = mini(cursor + 1, sentence.length())
	redraw()

func snapshot() -> Dictionary:
	var frame: Dictionary = reading.frames[cursor]
	return {"frame": frame.duplicate(true),
		"ends": reading.ends.slice(0, frame.segments * 2).duplicate(),
		"ratio": ratio, "text": sentence, "cursor": cursor, "generation": generation}

func keep() -> void:
	held = snapshot()
	redraw()

func reset() -> void:
	ratio = 0.72
	set_tree(1)
	if reading.is_empty(): return
	cursor = 1
	keep()

func choose(index: int) -> void:
	var selected: float = RATIOS[clampi(index, 0, RATIOS.size() - 1)]
	if is_equal_approx(selected, ratio): return
	ratio = selected
	reading = model.read(sentence, ratio)
	redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1.5))
	else:
		park()

func park() -> void:
	var x := (RATIOS.find(ratio) - 1.5) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: step()
		KEY_H: keep()
		KEY_T: set_tree(2 if generation == 1 else 1)
		KEY_R: reset()

func redraw() -> void:
	if reading.is_empty(): return
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var live := snapshot()
	for i in 2:
		var view: Dictionary = live if i == 0 else held
		if view.is_empty(): continue
		var origin := Vector3(-3 if i == 0 else 3, 0.35, 0)
		for j in range(0, view.ends.size(), 2):
			var a: Vector3 = origin + view.ends[j]
			var b: Vector3 = origin + view.ends[j + 1]
			var rod = LineSkin.new()
			rod.material_override.albedo_color = Color("70d5c2") if i == 0 else Color("edafd3")
			drawing.add_child(rod)
			rod.show_segment(a, b - a, a.distance_to(b))
		var marker := MeshInstance3D.new()
		var skin := SphereMesh.new()
		skin.radius = 0.065
		skin.height = 0.13
		marker.mesh = skin
		marker.position = origin + view.frame.pos
		drawing.add_child(marker)
		captions[i].text = "%s / ratio %.2f / %d segments" % ["LIVE" if i == 0 else "HELD", view.ratio, view.frame.segments]
	var frame: Dictionary = live.frame
	var start := maxi(0, cursor - 6)
	var window := sentence.substr(start, 11)
	title.text = "gen %d / symbol %d of %d: %s\nlength %.3f m / stack %d\n" % [generation, cursor, sentence.length(), frame.symbol, frame.length, frame.stack_depth]
	title.text += ("..." if start > 0 else "") + window + ("..." if start + 11 < sentence.length() else "")

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.0012
	tag.outline_size = 6
	add_child(tag)
	return tag
