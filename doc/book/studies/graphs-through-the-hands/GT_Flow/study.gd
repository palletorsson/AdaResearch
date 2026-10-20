extends Node3D
const Flow = preload("flow_model.gd")
const PointBody = preload("point_body.gd")
# Same IDs, now arranged as a miniature harbour plan.
const INITIAL: Array[Vector3] = [
	Vector3(-1.35, 1, 0), Vector3(-0.7, 1, -0.65),
	Vector3(-0.7, 1, 0.65), Vector3(0, 1, -0.65),
	Vector3(0, 1, 0.65), Vector3(0.7, 1, 0), Vector3(1.35, 1, 0),
]
const NAMES := ["0 / stock", "1 / depot A", "2 / depot B", "3 / yard C", "4 / yard D", "5 / dock", "6 / destination"]
var model = Flow.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var houses: Array[MeshInstance3D] = []
var rods: Array[MeshInstance3D] = []
var arrows: Array[MeshInstance3D] = []
var crates: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var weights: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption: Label3D
var cancelled: MeshInstance3D

class PlanButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	box(Vector3(3.4, 0.12, 2.1), Vector3(0, 0.8, 0), Color("344957"))
	for i in range(places.size()):
		houses.append(box(Vector3(0.28, 0.22, 0.25), places[i], Color("dcddd3")))
		labels.append(label(NAMES[i], Vector3.ZERO, 20))
	for link in model.links:
		var rod := CylinderMesh.new()
		rod.top_radius = 0.025
		rod.bottom_radius = 0.025
		rods.append(body(rod, Color("689299")))
		var arrow := CylinderMesh.new()
		arrow.top_radius = 0
		arrow.bottom_radius = 0.07
		arrow.height = 0.13
		arrows.append(body(arrow, Color("a7c7cd")))
		crates.append(box(Vector3(0.12, 0.12, 0.12), Vector3.ZERO, Color("eab668")))
		weights.append(label("", Vector3.ZERO, 22))
	var undo_shape := CylinderMesh.new()
	undo_shape.top_radius = 0.015
	undo_shape.bottom_radius = 0.015
	cancelled = body(undo_shape, Color("e382aa"))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption = label("", Vector3(0, 2.15, -0.35), 23)
	for i in range(2):
		var button := PlanButton.new()
		button.position = Vector3(-0.45 + i * 0.9, 0.9, 1.15)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.7, 0.18, 0.08)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		box(shape.size, Vector3.ZERO, Color("a16984")).reparent(button, false)
		var title := label("PLAN NEXT" if i == 0 else "RESET", Vector3(0, 0, 0.05), 23)
		title.reparent(button, false)
		button.action = advance if i == 0 else reset
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	node.material_override = material
	add_child(node)
	return node

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := body(mesh, colour)
	node.position = at
	return node

func label(words: String, at: Vector3, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = words
	node.position = at
	node.font_size = size
	node.pixel_size = 0.002
	add_child(node)
	return node

func connect_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var direction := b - a
	node.visible = direction.length() > 0.001
	if node.visible:
		node.mesh.height = direction.length()
		node.position = (a + b) * 0.5
		node.quaternion = Quaternion(Vector3.UP, direction.normalized())

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - Vector3.UP * 0.24
		places[4] = Vector3(local.x, 1, local.z)
	else:
		point.position = places[4] + Vector3.UP * 0.24
	redraw()

func redraw() -> void:
	for i in range(places.size()):
		houses[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.42, 0)
	for i in range(model.links.size()):
		var link: Dictionary = model.links[i]
		var a: Vector3 = places[link.a]
		var b: Vector3 = places[link.b]
		var assigned: int = model.flow[link.a][link.b]
		connect_rod(rods[i], a, b)
		arrows[i].visible = rods[i].visible
		if rods[i].visible:
			arrows[i].position = a.lerp(b, 0.7)
			arrows[i].quaternion = rods[i].quaternion
		crates[i].visible = assigned > 0
		crates[i].position = a.lerp(b, 0.4) + Vector3.UP * 0.08
		weights[i].position = a.lerp(b, 0.5) + Vector3.UP * 0.2
		weights[i].text = "%d / %d" % [assigned, link.cap]
		rods[i].material_override.albedo_color = Color("eab668") if assigned > 0 else Color("689299")
	cancelled.hide()
	var revision := ""
	for change in model.changes:
		if change.undo:
			connect_rod(cancelled, places[change.a] + Vector3.UP * 0.28, places[change.b] + Vector3.UP * 0.28)
			revision = "\nPink: cancel %d slot on %d -> %d." % [change.amount, change.b, change.a]
	caption.text = "HARBOUR / %d crate slots allocated\nLabels: assigned / capacity. One planning interval." % model.total
	caption.text += revision
	caption.text += "\nNo more residual routes." if model.done else "\nTrigger / 1: plan next. R: reset after release."
	caption.text += "\nPlanning markers, not crates travelling back in time."

func advance() -> void:
	model.step()
	redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_R:
			reset()
