extends Node3D
const Soil = preload("soil.gd")
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "F[+F]F[-F][F]"}
const CAP := 3
const FIELD := Vector3(0, 0, -3)
const CELL := 0.35
const COLORS := [Color("f0b776"), Color("92d5d9")]
var soil = Soil.new()
var grammar = Grammar.new()
var trees: Array[Dictionary] = []
var history: Array[Dictionary] = []
var first := 0
var next := 0
var winter := false
var drawing: Node3D
var readout: Label3D
var point: XRToolsPickable

func _ready() -> void:
	readout = label("", Vector3(0, 1.85, 1.6))
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): act("STEP"))
	label("HELD TRIGGER / ENTER: STEP\nO: ORDER   W: WINTER   R: RESET", Vector3(0, 1.02, 2.3))
	park()
	reset()

func _physics_process(_dt: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 2.3))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: act("STEP")
		KEY_O: act("ORDER")
		KEY_W: act("SEASON")
		KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": attempt(); return
		"ORDER": first = 1 - first
		"SEASON": winter = not winter
		"RESET": first = 0; winter = false
		_: return
	reset()

func reset() -> void:
	soil.reset()
	trees.clear()
	for i in 2:
		trees.append({"sentence": "F", "generation": 0, "last": 0.0, "total": 0.0})
	next = first
	history.clear()
	redraw()

func attempt() -> void:
	var tree: Dictionary = trees[next]
	var event := {"tree": next, "before": soil.cells.duplicate(true), "uptake": 0.0,
		"generation_before": tree.generation, "reason": "generation limit"}
	if tree.generation < CAP:
		var uptake: float = soil.consume(Soil.ROOTS[next])
		event.uptake = uptake
		event.reason = "winter" if winter else "uptake too small"
		if uptake > 0.05 and not winter:
			var result: Dictionary = grammar.rewrite(tree.sentence, RULE)
			if result.accepted:
				tree.sentence = result.text
				tree.generation += 1
				event.reason = "rewrite allowed"
			else: event.reason = "symbol limit"
	tree.last = event.uptake
	tree.total += event.uptake
	event["after"] = soil.cells.duplicate(true)
	event["generation_after"] = tree.generation
	history.append(event)
	if history.size() > 80: history.pop_front()
	next = 1 - next
	redraw()

func redraw() -> void:
	if is_instance_valid(drawing):
		remove_child(drawing)
		drawing.queue_free()
	drawing = Node3D.new()
	add_child(drawing)
	# One mesh for all 400 tiles. Height and colour show the same value.
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in Soil.SIDE:
		for x in Soil.SIDE:
			var value: float = soil.cells[z][x]
			var p := FIELD + Vector3(-3.5 + x * CELL, 0.025 + value * 0.2, -3.5 + z * CELL)
			mesh.surface_set_color(Color("322837").lerp(Color("6daa85"), value / Soil.SUPPLY))
			for offset in [Vector3.ZERO, Vector3(.33, 0, .33), Vector3(.33, 0, 0),
				Vector3.ZERO, Vector3(0, 0, .33), Vector3(.33, 0, .33)]:
				mesh.surface_add_vertex(p + offset)
	mesh.surface_end()
	var field := MeshInstance3D.new()
	field.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	field.material_override = material
	drawing.add_child(field)
	for i in 2:
		var root: Vector2i = Soil.ROOTS[i]
		var centre := FIELD + Vector3(-3.5 + (root.x + .5) * CELL, .18 + i * .025, -3.5 + (root.y + .5) * CELL)
		var half := (2 * Soil.RADIUS + 1) * CELL * .5
		var corners := [Vector3(-half, 0, -half), Vector3(half, 0, -half), Vector3(half, 0, half), Vector3(-half, 0, half)]
		for j in 4: rod(centre + corners[j], centre + corners[(j + 1) % 4], COLORS[i])
		rod(centre, centre + Vector3.UP * .18, COLORS[i])
		# Display position is separate from the soil address. Reader unchanged.
		var origin := Vector3(-2.5 if i == 0 else 2.5, .45, -4.8)
		var reading: Dictionary = grammar.read(trees[i].sentence, 25, false)
		for j in range(0, reading.ends.size(), 2):
			rod(origin + reading.ends[j], origin + reading.ends[j + 1], COLORS[i])
		var caption := label("%s / generation %d\nlast %.3f / total %.3f" % ["A" if i == 0 else "B", trees[i].generation, trees[i].last, trees[i].total], origin + Vector3(0, -.12, .4))
		caption.reparent(drawing)
		caption.modulate = COLORS[i]
	readout.text = "%s / next %s\n%s" % ["WINTER" if winter else "SPRING", "A" if next == 0 else "B", "Same rule. Shared soil." if history.is_empty() else history[-1].reason]

func rod(a: Vector3, b: Vector3, tint: Color) -> void:
	var line = LineSkin.new()
	drawing.add_child(line)
	line.material_override.albedo_color = tint
	line.show_segment(a, b - a, a.distance_to(b))

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 36
	tag.pixel_size = .002
	tag.outline_size = 8
	add_child(tag)
	return tag
