extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "FF+[+F-F-F]-[-F+F+F]"}
const ANGLES := [25.0, 45.0, 90.0]
const COLOURS := [Color("8bcda4"), Color("efbb68"), Color("92bfe4")]
var model = Grammar.new()
var sentence := ""
var generation := 1
var cursor := 1
var angle := 25.0
var sideways := false
var readings: Array[Dictionary] = []
var point: XRToolsPickable
var drawing: Node3D
var title: Label3D
var captions: Array[Label3D] = []

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(exchange)
	title = label("", Vector3(0, 1.65, 0.3))
	for i in 3:
		captions.append(label("", Vector3((i - 1) * 4.5, 0.7, 0.3)))
	label("TRIGGER / SPACE: READ F   ENTER: STEP   T: TREE   R: RESET", Vector3(0, 0.9, 2.55))
	for i in ANGLES.size():
		label(str(int(ANGLES[i])), Vector3((i - 1) * 0.35, 1.02, 2.55))
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
	if not model.read(next, 25, false).accepted:
		title.text = "Unmatched bracket: previous reading retained."
		return
	sentence = next
	generation = clampi(depth, 1, 2)
	cursor = sentence.length()
	reinterpret()

func reinterpret() -> void:
	readings = [model.read(sentence, 25, false), model.read(sentence, angle, false), model.read(sentence, 25, sideways)]
	redraw()

func exchange(_body = null) -> void:
	sideways = not sideways
	reinterpret()

func choose(index: int) -> void:
	var selected: float = ANGLES[clampi(index, 0, 2)]
	if is_equal_approx(selected, angle): return
	angle = selected
	reinterpret()

func step() -> void:
	cursor = (cursor + 1) % (sentence.length() + 1)
	redraw()

func reset() -> void:
	angle = 25
	sideways = false
	set_tree(1)
	cursor = 1
	redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1))
	else:
		park()

func park() -> void:
	var x := (ANGLES.find(angle) - 1) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: step()
		KEY_SPACE: exchange()
		KEY_T: set_tree(2 if generation == 1 else 1)
		KEY_R: reset()

func redraw() -> void:
	if readings.is_empty(): return
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	for i in 3:
		var frame: Dictionary = readings[i].frames[cursor]
		var origin := Vector3((i - 1) * 4.5, 2.2, 0)
		for j in range(0, frame.segments * 2, 2):
			rod(origin + readings[i].ends[j], origin + readings[i].ends[j + 1], COLOURS[i])
		var tip: Vector3 = origin + frame.pos
		var marker := MeshInstance3D.new()
		var skin := SphereMesh.new()
		skin.radius = 0.05
		skin.height = 0.1
		marker.mesh = skin
		marker.position = tip
		drawing.add_child(marker)
		# Two short rods share a tip but have distinct Z offsets for visibility.
		var gold := tip + Vector3(0, 0, 0.05)
		var white := tip + Vector3(0, 0, 0.10)
		rod(gold, gold + frame.heading * 0.24, Color("ffc967"))
		rod(white, white + frame.direction * 0.32, Color.WHITE)
		var name: String = ["REFERENCE / 25", "TURN / %.0f" % angle, "READ F / " + ("exchange x,y" if sideways else "forward")][i]
		captions[i].text = name + "\n%d segments / 0.32 m each" % frame.segments
	var current: Dictionary = readings[0].frames[cursor]
	var start := 0 if sentence.length() <= 20 else maxi(0, cursor - 10)
	title.text = ("..." if start > 0 else "") + sentence.substr(start, 20) + ("..." if start + 20 < sentence.length() else "")
	title.text += "\ngen %d / symbol %d of %d: %s / stack %d\ngold: heading / white: next drawing direction" % [generation, cursor, sentence.length(), current.symbol, current.stack_depth]

func rod(a: Vector3, b: Vector3, colour: Color) -> void:
	var line = LineSkin.new()
	line.material_override.albedo_color = colour
	drawing.add_child(line)
	line.show_segment(a, b - a, a.distance_to(b))

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.0012
	tag.outline_size = 6
	add_child(tag)
	return tag
