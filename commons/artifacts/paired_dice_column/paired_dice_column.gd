extends Node3D
## @identity
## essence: two physically read faces become a sum; coloured units retain the ingredients
## desire: the same height returns by another pair of throws
## truth: equal face probabilities are a model to test, not a property promised by the engine
## needs: XR and desktop release [has], pair transaction [has], bounded record [has]
const Tray = preload("res://commons/artifacts/paired_dice_column/paired_die.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const A := Color(0.26, 0.77, 0.88)
const B := Color(0.96, 0.39, 0.62)
const DARK := Color(0.075, 0.09, 0.115)
const HISTORY_LIMIT := 12
const UNIT_HEIGHT := 0.18
signal pair_recorded(a: int, b: int)
var trays: Array[Node3D] = []
var pending: Array[int] = [0, 0]
var armed: Array[bool] = [false, false]
var committed := false
var total_pairs := 0
var history: Array[Vector2i] = []
var last_pair := Vector2i.ZERO
var _column: Node3D
var _record: Node3D
var _status: Label3D
var _equation: Label3D
var _history_label: Label3D

func _ready() -> void:
	_box(self, "Base", Vector3(0.0,0.10,-0.55), Vector3(0.62,0.20,0.62), DARK, true)
	_box(self, "Shelf", Vector3(0,0.88,-1.08), Vector3(3.05,0.09,0.52), DARK, true)
	for x in [-1.4, 1.4]:
		_box(self,"ShelfLeg",Vector3(x,0.42,-1.08),Vector3(0.055,0.84,0.055),DARK,false)
	_column = Node3D.new()
	_column.name = "SumColumn"
	add_child(_column)
	_record = Node3D.new()
	_record.name = "RecentPairs"
	add_child(_record)
	for i in range(2):
		var tray := Tray.new()
		tray.name = "DieA" if i == 0 else "DieB"
		tray.position = Vector3(-0.70 if i == 0 else 0.70, 0, 0.18)
		tray.dice_color = A if i == 0 else B
		tray.felt_color = Color(0.06,0.19,0.22) if i == 0 else Color(0.23,0.075,0.13)
		tray.lifted.connect(_on_lifted.bind(i))
		tray.released.connect(_on_released.bind(i))
		tray.landed.connect(_on_landed.bind(i))
		tray.returned.connect(_on_returned.bind(i))
		trays.append(tray)
		add_child(tray)
	_label("TWO THROWS / ONE HEIGHT", Vector3(0,2.67,-1.10), 0.052)
	_status = _label("Throw both dice into their trays", Vector3(0,1.25,0.67),0.024)
	_box(self,"ReadoutCase",Vector3(0,1.20,0.64),Vector3(0.62,0.25,0.04),DARK,false)
	_equation = _label("? + ?",Vector3(0,1.14,0.67),0.042)
	_history_label = _label("RECENT PAIRS / empty",Vector3(0,1.66,-1.10),0.029)
	_label("Each colour keeps its contribution",Vector3(0,1.80,-1.10),0.025)
	var panel := Rack.create_panel("", [[{"type":"button","label":"RETURN DICE"},{"type":"button","label":"CLEAR RECORD"}]],true)
	panel.position = Vector3(0,0.96,0.66)
	panel.rotation_degrees.x = -65
	panel.scale = Vector3.ONE * 1.75
	add_child(panel)
	_box(self,"ControlShelf",Vector3(0,0.85,0.61),Vector3(0.61,0.10,0.29),DARK,true)
	for i in range(2):
		var button := panel.find_child("Btn_%d" % i,true,false)
		if button != null:
			var area := button.get_node_or_null("InteractableAreaButton")
			if area != null:
				if i == 0: area.button_pressed.connect(func(_b): return_dice())
				else: area.button_pressed.connect(func(_b): clear_record())

func _on_lifted(index: int) -> void:
	if committed:
		pending = [0, 0]
		armed = [false, false]
		committed = false
	pending[index] = 0
	armed[index] = false
	_update_pending()

func _on_released(index: int) -> void:
	# Handles direct desktop drops as well as the XR pickup/release pair.
	if committed:
		pending = [0,0]
		armed = [false,false]
		committed = false
	pending[index] = 0
	armed[index] = true
	_update_pending()

func _on_returned(index: int) -> void:
	armed[index] = false
	pending[index] = 0
	_update_pending()

func _on_landed(value: int, index: int) -> void:
	if committed or not armed[index] or value < 1 or value > 6: return
	pending[index] = value
	armed[index] = false
	if pending[0] > 0 and pending[1] > 0:
		committed = true
		last_pair = Vector2i(pending[0],pending[1])
		total_pairs += 1
		history.append(last_pair)
		if history.size() > HISTORY_LIMIT: history.pop_front()
		_rebuild_column()
		_rebuild_record()
		pair_recorded.emit(last_pair.x,last_pair.y)
	_update_pending()

func _update_pending() -> void:
	if _status == null: return
	if committed:
		_status.text = "Pair %d / lift both for another pair" % total_pairs
		_equation.text = "%d + %d = %d" % [last_pair.x,last_pair.y,last_pair.x+last_pair.y]
	else:
		_status.text = "Throw both / previous column stays" if total_pairs > 0 else "Throw both dice into their trays"
		_equation.text = "%s + %s" % [str(pending[0]) if pending[0] else "?",str(pending[1]) if pending[1] else "?"]

func return_dice() -> void:
	for tray in trays: tray.return_to_tray()
	pending = [0,0]
	armed = [false,false]
	committed = false
	_update_pending()

func clear_record() -> void:
	# Cancel in-flight results: both dice must be released again after clearing.
	return_dice()
	total_pairs = 0
	last_pair = Vector2i.ZERO
	history.clear()
	_clear_children(_column)
	_clear_children(_record)
	_history_label.text = "RECENT PAIRS / empty"
	_update_pending()

func _rebuild_column() -> void:
	_clear_children(_column)
	var total := last_pair.x + last_pair.y
	for j in range(total):
		_box(_column,"Unit_%02d" % j,Vector3(0,0.20+(j+0.5)*UNIT_HEIGHT,-0.55),Vector3(0.40,UNIT_HEIGHT-0.008,0.40),A if j < last_pair.x else B,false)
	var support := StaticBody3D.new()
	support.name = "ColumnSupport"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.40,total*UNIT_HEIGHT,0.40)
	shape.shape = box
	shape.position = Vector3(0,0.20+total*UNIT_HEIGHT*0.5,-0.55)
	support.add_child(shape)
	_column.add_child(support)

func _rebuild_record() -> void:
	_clear_children(_record)
	# Two bounded draw calls for all miniature coloured units.
	for side in range(2):
		var transforms: Array[Transform3D] = []
		for i in range(history.size()):
			var pair: Vector2i = history[i]
			var count := pair.x if side == 0 else pair.y
			var first := 0 if side == 0 else pair.x
			for j in range(count):
				transforms.append(Transform3D(Basis.IDENTITY,Vector3(-1.375+i*0.25,0.935+(first+j+0.5)*0.04,-1.08)))
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12,0.036,0.12)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()
		for i in range(transforms.size()): mm.set_instance_transform(i,transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = _material(A if side == 0 else B)
		_record.add_child(instance)
	for i in range(history.size()):
		var pair: Vector2i = history[i]
		var label := _label("%d+%d" % [pair.x,pair.y],Vector3(-1.375+i*0.25,0.85,-0.80),0.023)
		remove_child(label)
		_record.add_child(label)
	_history_label.text = "LAST %d PAIRS / %d TOTAL" % [history.size(),total_pairs]

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.36
	mat.metallic = 0.12
	return mat

func _box(host: Node3D, title: String, pos: Vector3, size: Vector3, colour: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = pos
	host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.position = pos
		body.add_child(shape)
		host.add_child(body)

func _label(text: String, pos: Vector3, height: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = height / 40.0
	label.position = pos
	label.modulate = Color(0.90,0.91,0.88)
	label.outline_size = 5
	add_child(label)
	return label

func get_state() -> Dictionary:
	var rows: Array = []
	for pair in history: rows.append([pair.x,pair.y])
	return {"pending":pending.duplicate(),"armed":armed.duplicate(),"committed":committed,"pairs":total_pairs,"last":[last_pair.x,last_pair.y],"history":rows,"unit_height":UNIT_HEIGHT}
