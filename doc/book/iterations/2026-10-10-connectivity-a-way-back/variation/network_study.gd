extends Node3D
const Ledger = preload("ledger.gd")
const PointBody = preload("point_body.gd")
const FILTERS := ["all", "payment", "report"]
const FRONT := Vector3(0, 0, 0.14)
const INITIAL: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var ledger = Ledger.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var lamps: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var controls: Array[StaticBody3D] = []
var caption := Label3D.new()
var source_label := Label3D.new()
var filter_index := 0
var circular := false

class RecordButton extends StaticBody3D:
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
		var label := Label3D.new()
		label.font_size = 26
		label.pixel_size = 0.0018
		add_child(label)
		labels.append(label)
	for record in ledger.records:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.008
		cylinder.bottom_radius = 0.008
		rods.append(body(cylinder, Color("797984")))
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.03
		cone.height = 0.08
		tips.append(body(cone, Color("e4ab56")))
	add_child(point)
	point.action_pressed.connect(func(_source): cycle_filter())
	caption.position = Vector3(0, 2.9, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	source_label.position = Vector3(0, 1.1, 0.7)
	source_label.font_size = 26
	source_label.pixel_size = 0.0018
	add_child(source_label)
	var names := ["FILTER", "OMIT P04", "LAYOUT", "RESET"]
	var actions: Array[Callable] = [cycle_filter, toggle_record, switch_layout, reset]
	for i in range(names.size()):
		var button := RecordButton.new()
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
		var mesh := body(box, Color("ae647d"))
		mesh.reparent(button, false)
		var nameplate := Label3D.new()
		nameplate.text = names[i]
		nameplate.font_size = 24
		nameplate.pixel_size = 0.0015
		nameplate.position.z = 0.04
		button.add_child(nameplate)
		button.action = actions[i]
		add_child(button)
		controls.append(button)
	redraw()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.6
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[4] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[4] + FRONT
	redraw()

func redraw() -> void:
	var active: Array[int] = ledger.active_records()
	for i in range(places.size()):
		lamps[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.2, 0.04)
		var count: Vector2i = ledger.counts(i)
		labels[i].text = "%d\nin %d / out %d" % [i, count.x, count.y]
	for i in range(ledger.records.size()):
		var record: Dictionary = ledger.records[i]
		var a: Vector3 = places[record.from]
		var b: Vector3 = places[record.to]
		var direction := b - a
		var drawn: bool = i in active and direction.length() > 0.001
		rods[i].visible = drawn
		tips[i].visible = drawn
		if drawn:
			rods[i].mesh.height = direction.length()
			rods[i].position = (a + b) * 0.5
			rods[i].quaternion = Quaternion(Vector3.UP, direction.normalized())
			tips[i].position = a.lerp(b, 0.72)
			tips[i].quaternion = rods[i].quaternion
	caption.text = "FICTIONAL RECORDS / %s / %d active" % [ledger.filter_kind, active.size()]
	caption.text += "\nHold 4: move drawing. Trigger / 1: filter."
	caption.text += "\n2: omit P04   3: layout   R: reset (release first)"
	source_label.text = ledger.records[-1].source
	source_label.text += "\n" + ("omitted" if 6 in ledger.omitted else "kept")
	source_label.text += " / " + ("counted" if 6 in active else "not counted in this view")

func cycle_filter() -> void:
	filter_index = (filter_index + 1) % FILTERS.size()
	ledger.filter_kind = FILTERS[filter_index]
	redraw()

func toggle_record() -> void:
	if 6 in ledger.omitted:
		ledger.omitted.erase(6)
	else:
		ledger.omitted.append(6)
	redraw()

func switch_layout() -> void:
	if point.held():
		return
	circular = not circular
	places = INITIAL.duplicate()
	if circular:
		for i in range(places.size()):
			var angle := TAU * float(i) / places.size()
			places[i] = Vector3(cos(angle), 1.9 + sin(angle) * 0.65, 0)
	redraw()

func reset() -> void:
	if point.held():
		return
	filter_index = 0
	ledger.filter_kind = "all"
	ledger.omitted.clear()
	circular = false
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: cycle_filter()
			KEY_2: toggle_record()
			KEY_3: switch_layout()
			KEY_R: reset()
