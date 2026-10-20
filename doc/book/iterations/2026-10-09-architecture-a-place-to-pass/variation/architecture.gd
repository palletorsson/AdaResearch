extends Node3D
const Grammar = preload("grammar.gd")
const Footprint = preload("footprint.gd")
const PointBody = preload("point_body.gd")
const RULE := {"F": "F[+FR][-FR]F"}
const WIDTHS := [0.4, 1.4, 2.2]
var records: Dictionary
var floor_model = Footprint.new()
var layout: Dictionary
var width_index := 1
var built := false
var rooms_on := false
var revealed := false
var drawing: Node3D
var point: XRToolsPickable
var title: Label3D
var last_slot := -1

func _ready() -> void:
	var grammar = Grammar.new()
	var result: Dictionary = grammar.rewrite("F", RULE)
	assert(result.accepted)
	records = grammar.read(result.text)
	assert(records.accepted)
	drawing = Node3D.new(); add_child(drawing)
	point = PointBody.new(); add_child(point)
	point.action_pressed.connect(func(_body): act("PLAN" if built else "BUILD"))
	title = label("", Vector3(0, 1.6, 2))
	label("TRIGGER: BUILD / PLAN   W: WIDTH   O: ROOMS   R: RESET", Vector3(0, 0.9, 2.55))
	for i in 3: label(str(WIDTHS[i]), Vector3((i - 1) * 0.35, 1.02, 2.55))
	# Fixed frame marks the occupation check, outside the changing footprint.
	for x in [-5.8, 5.8]: box(self, Vector3(x, 0.01, -4), Vector3(0.025, 0.02, 11.6), Color("bfa875"), false)
	for z in [-9.8, 1.8]: box(self, Vector3(0, 0.01, z), Vector3(11.6, 0.02, 0.025), Color("bfa875"), false)
	rebuild()
	park()

func people_inside() -> bool:
	for group in ["em_walker", "player_body", "player"]:
		for person in get_tree().get_nodes_in_group(group):
			if person is Node3D:
				var p := to_local(person.global_position)
				if absf(p.x) < 5.8 and p.z > -9.8 and p.z < 1.8 and p.y > -1 and p.y < 4: return true
	return false

func act(id: String, selected: int = -1) -> void:
	if people_inside():
		title.text = "Leave the brass frame, then act again."
		return
	match id:
		"PLAN": built = false
		"BUILD": built = true
		"WIDTH": width_index = (width_index + 1) % 3 if selected < 0 else clampi(selected, 0, 2)
		"ROOMS": rooms_on = not rooms_on; revealed = true
		"RESET": width_index = 1; built = false; rooms_on = false; revealed = false
	rebuild()

func _physics_process(_dt: float) -> void:
	if point.held():
		var slot := clampi(roundi(to_local(point.global_position).x / 0.35 + 1), 0, 2)
		if slot != last_slot:
			last_slot = slot # Remember even a refused choice; do not queue it.
			if slot != width_index: act("WIDTH", slot)
	else:
		last_slot = -1
		park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((width_index - 1) * 0.35, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var commands := {KEY_B: "BUILD", KEY_P: "PLAN", KEY_W: "WIDTH", KEY_O: "ROOMS", KEY_R: "RESET"}
	if commands.has(event.keycode): act(commands[event.keycode])

func rebuild() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child); child.queue_free()
	layout = floor_model.make(records, WIDTHS[width_index], rooms_on)
	for rect in layout.floors: slab(rect, 0.04 if built else 0.008, 0.08 if built else 0.016, Color("729d9c"), built)
	for rect in floor_model.rectangles(layout.rooms): slab(rect, 0.085 if built else 0.019, 0.006, Color("c19875"), false)
	if built:
		for wall in layout.walls:
			box(drawing, wall.center, wall.size, Color(0.52, 0.73, 0.76, 0.24), true)
			box(drawing, Vector3(wall.center.x, 0.34, wall.center.z), Vector3(wall.size.x, 0.52, wall.size.z), Color("c6c4ae"), false)
	for ends in records.segments:
		var a: Vector2 = ends[0]; var b: Vector2 = ends[1]; var c := (a + b) / 2
		box(drawing, Vector3(c.x, 0.096, c.y), Vector3(absf(b.x - a.x) + 0.025, 0.015, absf(b.y - a.y) + 0.025), Color("fff0bb"), false)
	title.text = "%s / width %.1f m / rooms %s\n%d moves / %d room records" % ["BUILT" if built else "PLAN", WIDTHS[width_index], "ON" if rooms_on else "OFF", records.segments.size(), records.rooms.size()]
	if revealed: title.text += " / %d addresses" % layout.addresses.size()

func slab(rect: Rect2i, y: float, height: float, colour: Color, solid: bool) -> void:
	var c := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * Footprint.PITCH
	box(drawing, Vector3(c.x, y, c.y), Vector3(rect.size.x * Footprint.PITCH, height, rect.size.y * Footprint.PITCH), colour, solid)

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new(); var skin := BoxMesh.new(); skin.size = size; mesh.mesh = skin
	var material := StandardMaterial3D.new(); material.albedo_color = colour
	if colour.a < 1: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = material; mesh.position = at; parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); body.collision_layer = 1; mesh.add_child(body)
		var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		collision.shape = shape; body.add_child(collision)

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new(); tag.text = text; tag.position = at
	tag.font_size = 32; tag.pixel_size = 0.0012; tag.outline_size = 6; add_child(tag)
	return tag
