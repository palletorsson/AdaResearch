extends Node3D
## @identity
## essence: a draw changes its future only if the selected member leaves the set
## desire: find a repeated number, then try to get it again from the emptying set
## truth: the code selects; the mechanism animates that selection rather than measuring physical mixing
const LeverScene = preload("res://commons/interactables/lever_zero.tscn")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const COUNT := 8
const MEMORY := 12
const SEED := 79
const INK := Color(0.075,0.10,0.13)
const BLUE := Color(0.25,0.76,0.89)
const PINK := Color(0.96,0.40,0.61)
signal draw_finished(side: int, number: int)
var pools: Array = [[],[]]
var histories: Array = [[],[]]
var totals: Array[int] = [0,0]
var busy: Array[bool] = [false,false]
var armed: Array[bool] = [true,true]
var generators: Array = []
var blocks: Array = [[],[]]
var levers: Array = []
var records: Array = []
var statuses: Array = []
var motions: Array = [null,null]
var resetting := false

func _ready() -> void:
	for side in range(2):
		generators.append(RandomNumberGenerator.new())
		_make_station(side)
	var panel := Rack.create_panel("", [[{"type":"button","label":"REPLAY BOTH"}]],true)
	panel.position = Vector3(0,0.94,1.03)
	panel.rotation_degrees.x = -65
	panel.scale = Vector3.ONE * 1.7
	add_child(panel)
	_box(self,"ReplayStand",Vector3(0,0.44,0.99),Vector3(0.30,0.88,0.25),INK,true)
	var button := panel.find_child("Btn_0",true,false)
	if button != null:
		button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): replay())
	replay()

func _centre(side: int) -> float:
	return -0.86 if side == 0 else 0.86

func _slot(side: int, id: int) -> Vector3:
	return Vector3(_centre(side)-0.375+float((id-1)%4)*0.25,1.28+float((id-1)/4)*0.30,-0.02)

func _record_slot(side: int, i: int) -> Vector3:
	return Vector3(_centre(side)-0.475+float(i%6)*0.19,0.87,0.66+float(i/6)*0.18)

func _make_station(side: int) -> void:
	var x := _centre(side)
	_box(self,"HopperBase",Vector3(x,1.03,-0.02),Vector3(1.20,0.10,0.68),INK,true)
	for dx in [-0.49,0.49]:
		_box(self,"Leg",Vector3(x+dx,0.51,0),Vector3(0.065,1.02,0.38),INK,true)
		for z in [-0.33,0.29]:
			_box(self,"Corner",Vector3(x+dx,1.51,z),Vector3(0.026,0.89,0.026),INK,false)
	_box(self,"TopFrame",Vector3(x,1.99,-0.02),Vector3(1.20,0.08,0.68),INK,false)
	var glass := Color(0.58,0.80,0.86,0.10)
	_box(self,"FrontGlass",Vector3(x,1.51,0.30),Vector3(1.18,0.87,0.012),glass,false)
	_box(self,"BackGlass",Vector3(x,1.51,-0.34),Vector3(1.18,0.87,0.012),glass,false)
	for dx in [-0.60,0.60]:
		_box(self,"SideGlass",Vector3(x+dx,1.51,-0.02),Vector3(0.012,0.87,0.64),glass,false)
	_label(self,"RETURNS" if side == 0 else "STAYS OUT",Vector3(x,2.00,0.33),0.065)
	_label(self,"WITH REPLACEMENT" if side == 0 else "WITHOUT REPLACEMENT",Vector3(x,2.14,0.07),0.028)
	for id in range(1,COUNT+1):
		var pos := _slot(side,id)
		_box(self,"SlotPlate",pos+Vector3(0,0,-0.14),Vector3(0.223,0.223,0.023),INK,false)
		_label(self,str(id),pos+Vector3(0,0,-0.126),0.048)
		var block := _numbered_block(id)
		block.name = "Source_%d_%d" % [side,id]
		block.position = pos
		add_child(block)
		blocks[side].append(block)
	_box(self,"RecordShelf",Vector3(x,0.77,0.76),Vector3(1.23,0.055,0.46),INK,true)
	_label(self,"DRAW RECORD / LAST 12" if side == 0 else "DRAW RECORD / UP TO 8",Vector3(x,0.74,1.005),0.026)
	var record := Node3D.new()
	record.name = "Record%d" % side
	add_child(record)
	records.append(record)
	statuses.append(_label(self,"",Vector3(x,1.05,0.345),0.035))
	var lever: Node3D = LeverScene.instantiate()
	lever.name = "DrawLever%d" % side
	lever.position = Vector3(x + (-0.64 if side == 0 else 0.64),1.05,0.78)
	lever.scale = Vector3.ONE * 1.35
	add_child(lever)
	lever.set_caption("PULL / DRAW")
	lever.set_readout_visible(false)
	lever.hinge_moved.connect(_lever_moved.bind(side))
	levers.append(lever)
	_box(self,"LeverStand",Vector3(x + (-0.64 if side == 0 else 0.64),0.48,0.76),Vector3(0.21,0.96,0.15),INK,true)

func _lever_moved(angle: float, side: int) -> void:
	if resetting: return
	if angle < 8.0: armed[side] = true
	if angle >= 28.0 and armed[side]:
		armed[side] = false
		draw(side)

func draw(side: int) -> bool:
	if side < 0 or side > 1 or resetting or busy[side] or pools[side].is_empty(): return false
	busy[side] = true
	var index: int = generators[side].randi_range(0,pools[side].size()-1)
	var id: int = pools[side][index]
	if side == 1: pools[side].remove_at(index)
	var block: Node3D = blocks[side][id-1]
	var out := Vector3(_centre(side),1.20,0.51)
	var tween := create_tween()
	motions[side] = tween
	# This is an exposed animation of a PRNG choice, not a gravity sorter.
	tween.tween_property(block,"position",out,0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.28)
	tween.tween_callback(_remember.bind(side,id))
	if side == 0:
		tween.tween_property(block,"position",Vector3(_centre(side)+0.69,1.20,0.51),0.22)
		tween.tween_property(block,"position",Vector3(_centre(side)+0.69,2.24,0),0.38)
		tween.tween_property(block,"position",_slot(side,id)+Vector3(0,0.30,0),0.28)
		tween.tween_property(block,"position",_slot(side,id),0.20)
	else:
		tween.set_parallel(true)
		tween.tween_property(block,"position",_record_slot(side,totals[side]),0.36)
		tween.tween_property(block,"scale",Vector3.ONE*0.82,0.36)
		tween.set_parallel(false)
	tween.tween_callback(_finish.bind(side,id))
	_update_status(side)
	return true

func _remember(side: int, id: int) -> void:
	histories[side].append(id)
	totals[side] += 1
	if histories[side].size() > MEMORY: histories[side].pop_front()
	if side == 0:
		for child in records[side].get_children():
			records[side].remove_child(child)
			child.queue_free()
		for i in range(histories[side].size()):
			var copy := _numbered_block(histories[side][i])
			copy.position = _record_slot(side,i)
			copy.scale = Vector3.ONE * 0.82
			records[side].add_child(copy)

func _finish(side: int, id: int) -> void:
	busy[side] = false
	motions[side] = null
	_update_status(side)
	draw_finished.emit(side,id)

func _update_status(side: int) -> void:
	var description := " / moving" if busy[side] else ""
	if pools[side].is_empty() and not busy[side]: description = " / empty"
	statuses[side].text = "%d available / %d draws%s" % [pools[side].size(),totals[side],description]

func replay() -> void:
	resetting = true
	for side in range(2):
		if motions[side] != null: motions[side].kill()
		motions[side] = null
		generators[side].seed = SEED
		pools[side] = range(1,COUNT+1)
		histories[side] = []
		totals[side] = 0
		busy[side] = false
		armed[side] = true
		for i in range(COUNT):
			var block: Node3D = blocks[side][i]
			block.position = _slot(side,i+1)
			block.scale = Vector3.ONE
		for child in records[side].get_children():
			records[side].remove_child(child)
			child.queue_free()
		levers[side].set_angle_degrees(0)
		_update_status(side)
	resetting = false

func get_state() -> Dictionary:
	return {"pools":pools.duplicate(true),"histories":histories.duplicate(true),"totals":totals.duplicate(),"busy":busy.duplicate(),"seed":SEED,"memory":MEMORY}

func _numbered_block(id: int) -> Node3D:
	var node := Node3D.new()
	_box(node,"Block",Vector3.ZERO,Vector3.ONE*0.155,BLUE if id <= 4 else PINK,false)
	_label(node,str(id),Vector3(0,0,0.079),0.07,INK)
	return node

func _label(host: Node3D, text: String, pos: Vector3, height: float, colour: Color = Color(0.93,0.95,0.92)) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 48
	label.pixel_size = height / 48.0
	label.modulate = colour
	label.outline_size = 0 if colour == INK else 4
	host.add_child(label)
	return label

func _box(host: Node3D, title: String, pos: Vector3, size: Vector3, colour: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.position = pos
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.35
	if colour.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.no_depth_test = false
	mesh.material_override = mat
	host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collision.shape = box
		body.add_child(collision)
		host.add_child(body)
