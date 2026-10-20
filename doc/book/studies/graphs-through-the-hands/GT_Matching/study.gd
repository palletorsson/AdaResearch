extends Node3D
const Matching = preload("matching_model.gd")
const PointBody = preload("point_body.gd")
const INITIAL: Array[Vector3] = [
	Vector3(-0.9, 1, -0.65), Vector3(-0.9, 1, 0.65),
	Vector3(0.9, 1, -0.65), Vector3(0.9, 1, 0.65),
]
const NAMES := ["0 / maker A", "1 / maker B", "2 / drill", "3 / saw"]
var model = Matching.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var figures: Array[Node3D] = []
var rods: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption: Label3D
var cancelled: MeshInstance3D
var reverse_order := false
var phase := 0
var history: Array[int] = [0]

class WorkshopButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	box(Vector3(3.2, 0.12, 2.5), Vector3(0, 0.8, 0), Color("435953"))
	for i in range(4):
		var figure := Node3D.new()
		add_child(figure)
		figures.append(figure)
		if i < 2:
			var head := SphereMesh.new()
			head.radius = 0.09
			head.height = 0.18
			body(head, Vector3(0, 0.44, 0), Color("e4b6ca"), figure)
			box(Vector3(0.15, 0.23, 0.12), Vector3(0, 0.23, 0), Color("e4b6ca"), figure)
			for x in [-0.05, 0.05]:
				box(Vector3(0.055, 0.15, 0.07), Vector3(x, 0.065, 0), Color("e4b6ca"), figure)
		else:
			if i == 2:
				box(Vector3(0.1, 0.25, 0.1), Vector3(0, 0.1, 0), Color("dca95d"), figure)
				box(Vector3(0.4, 0.14, 0.12), Vector3(0, 0.24, 0), Color("dca95d"), figure)
				box(Vector3(0.18, 0.025, 0.025), Vector3(0.28, 0.24, 0), Color("cccccc"), figure)
			else:
				box(Vector3(0.45, 0.17, 0.025), Vector3(0.12, 0.2, 0), Color("cccccc"), figure)
				box(Vector3(0.045, 0.23, 0.07), Vector3(-0.25, 0.2, 0), Color("dca95d"), figure)
				for y in [0.1, 0.3]:
					box(Vector3(0.17, 0.04, 0.07), Vector3(-0.17, y, 0), Color("dca95d"), figure)
				for x in [-0.04, 0.04, 0.12, 0.2, 0.28]:
					box(Vector3(0.025, 0.045, 0.025), Vector3(x, 0.1, 0), Color("cccccc"), figure)
		labels.append(label(NAMES[i], Vector3.ZERO, 26))
	for edge in model.links:
		rods.append(new_rod(Color("88aaa9")))
	cancelled = new_rod(Color("ee85ba"))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	box(Vector3(3.1, 0.55, 0.03), Vector3(0, 2.35, -0.34), Color("252b32"))
	caption = label("", Vector3(0, 2.35, -0.3), 26)
	for i in range(3):
		var button := WorkshopButton.new()
		button.position = Vector3(-1 + i, 0.9, 1.4)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.85, 0.18, 0.08)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		box(shape.size, Vector3.ZERO, Color("9f6886"), button)
		var title := label(["NEXT", "ORDER", "RESET"][i], Vector3(0, 0, 0.06), 24)
		title.reparent(button, false)
		button.action = [advance, change_order, reset][i]
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, at: Vector3, colour: Color, parent: Node = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.65
	node.material_override = material
	(parent if parent != null else self).add_child(node)
	return node

func box(size: Vector3, at: Vector3, colour: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return body(mesh, at, colour, parent)

func label(words: String, at: Vector3, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = words
	node.position = at
	node.font_size = size
	node.pixel_size = 0.0025
	add_child(node)
	return node

func new_rod(colour: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.022
	mesh.bottom_radius = 0.022
	return body(mesh, Vector3.ZERO, colour)

func connect_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	node.visible = delta.length() > 0.001
	if node.visible:
		node.mesh.height = delta.length()
		node.position = (a + b) * 0.5
		node.quaternion = Quaternion(Vector3.UP, delta.normalized())

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - Vector3.UP * 0.6
		places[0] = Vector3(local.x, 1, local.z)
	else:
		point.position = places[0] + Vector3.UP * 0.6
	redraw()

func redraw() -> void:
	for i in range(4):
		figures[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.78, 0)
		labels[i].text = NAMES[i] + (" / free" if model.mate[i] == -1 else " / paired %d" % model.mate[i])
	for i in range(model.links.size()):
		var edge: Array = model.links[i]
		connect_rod(rods[i], places[edge[0]], places[edge[1]])
		rods[i].material_override.albedo_color = Color("e6b260") if model.mate[edge[0]] == edge[1] else Color("88aaa9")
	cancelled.hide()
	if not model.removed.is_empty():
		var edge: Array = model.removed[0]
		connect_rod(cancelled, places[edge[0]] + Vector3.UP * 0.25, places[edge[1]] + Vector3.UP * 0.25)
	caption.text = "TWO MAKERS / TWO TOOLS\n%d pairs / %s order" % [model.size(), "reverse" if reverse_order else "listed"]
	caption.text += "\nNext: greedy scan." if phase == 0 else ("\nNo augmenting path remains." if model.done else "\nNext: find and flip an alternating path.")
	caption.text += "\nPair-count history: " + str(history)
	caption.text += "\nTrigger / 1: next. O: order. R: reset after release."

func advance() -> void:
	if phase == 0:
		model.greedy(reverse_order)
		phase = 1
	else:
		model.augment()
	if history.back() != model.size():
		history.append(model.size())
	redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	places = INITIAL.duplicate()
	phase = 0
	history = [0]
	redraw()

func change_order() -> void:
	if point.held():
		return
	reverse_order = not reverse_order
	reset()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_O:
			change_order()
		elif event.keycode == KEY_R:
			reset()
