extends Node3D
const TreeModel = preload("tree_model.gd")
const PointBody = preload("point_body.gd")
const FRONT := Vector3(0, 0, 0.14)
const INITIAL: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var model = TreeModel.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var lamps: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var weights: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption := Label3D.new()
var decision := Label3D.new()
var broken := false
var spare := false

class StudyButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	for i in range(places.size()):
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamps.append(body(sphere, Color("65bdd3")))
		labels.append(label(str(i), 26))
	for link in model.links:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.009
		cylinder.bottom_radius = 0.009
		rods.append(body(cylinder, Color("777984")))
		weights.append(label("", 23))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption.position = Vector3(0, 2.9, 0)
	caption.font_size = 28
	caption.pixel_size = 0.002
	add_child(caption)
	decision.position = Vector3(0, 0.65, 0.5)
	decision.font_size = 25
	decision.pixel_size = 0.0018
	add_child(decision)
	var names := ["STEP", "BREAK 0-1", "SPARE 4-5", "RESET"]
	var actions: Array[Callable] = [advance, toggle_break, toggle_spare, reset]
	for i in range(names.size()):
		var button := StudyButton.new()
		button.position = Vector3(-0.9 + i * 0.6, 0.95, 0.5)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.53, 0.16, 0.06)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		var box := BoxMesh.new()
		box.size = shape.size
		body(box, Color("ae647d")).reparent(button, false)
		var nameplate := label(names[i], 24)
		nameplate.reparent(button, false)
		nameplate.position.z = 0.04
		button.action = actions[i]
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.6
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node

func label(text: String, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.0018
	add_child(node)
	return node

func active_links() -> Array[int]:
	var result: Array[int] = model.chosen.duplicate()
	if spare and 6 not in result:
		result.append(6)
	if broken:
		result.erase(0)
	return result

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[4] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[4] + FRONT
	redraw()

func redraw() -> void:
	var reached: Array[int] = model.reachable(active_links(), 0)
	for i in range(places.size()):
		lamps[i].position = places[i]
		lamps[i].material_override.albedo_color = Color("8fe2ba") if i in reached else Color("eaa16d")
		labels[i].position = places[i] + Vector3(0, -0.2 if i >= 3 else 0.2, 0.04)
		labels[i].text = "%d / %s" % [i, "from 0" if i in reached else "apart"]
	for i in range(model.links.size()):
		var link: Dictionary = model.links[i]
		var a: Vector3 = places[link.a]
		var b: Vector3 = places[link.b]
		var direction := b - a
		rods[i].visible = direction.length() > 0.001 and not (broken and i == 0)
		if rods[i].visible:
			rods[i].mesh.height = direction.length()
			rods[i].position = (a + b) * 0.5
			rods[i].quaternion = Quaternion(Vector3.UP, direction.normalized())
		var state := "kept" if i in model.chosen else ("cycle" if i in model.refused else "waiting")
		var colour := Color("8fe2ba") if i in model.chosen else (Color("d87f9d") if i in model.refused else Color("777984"))
		if spare and i == 6 and i not in model.chosen:
			state = "spare"
			colour = Color("e4ab56")
		if broken and i == 0:
			state = "broken"
		rods[i].material_override.albedo_color = colour
		weights[i].position = (a + b) * 0.5 + Vector3(0, -0.065, 0.05)
		weights[i].text = "%.1f\n%s" % [link.cost, state]
	var extra: float = model.links[6].cost if spare and 6 not in model.chosen else 0.0
	caption.text = "%d / %d decisions   chosen cost %.1f + spare %.1f" % [model.cursor, model.order.size(), model.cost(model.chosen), extra]
	caption.text += "\nFrom 0: %d / 7 reachable. Weights stay fixed when moved." % reached.size()
	caption.text += "\nTrigger / 1: step   2: break   3: spare   R: reset (release first)"
	decision.text = "Predict the next edge. Cheapest first; refuse a cycle."
	if model.current >= 0:
		var link: Dictionary = model.links[model.current]
		decision.text = "%d-%d / %.1f / %s" % [link.a, link.b, link.cost, "JOIN" if model.current in model.chosen else "CYCLE: REFUSE"]
	if model.complete():
		decision.text = ("Tree selected." if model.spans() else "Forest: some vertices remain apart.")
		decision.text += "\nBreak 0-1, then add the spare."

func advance() -> void:
	model.step()
	redraw()

func toggle_break() -> void:
	if model.complete():
		broken = not broken
		redraw()

func toggle_spare() -> void:
	if model.complete():
		spare = not spare
		redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	broken = false
	spare = false
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: advance()
			KEY_2: toggle_break()
			KEY_3: toggle_spare()
			KEY_R: reset()
