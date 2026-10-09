extends Node3D
## @identity
## essence: a six becomes permission; the rule, not the die, continues
## desire: another throw can build a taller body from the same six faces
## truth: read settled physical orientation; worked example is separate from live evidence
const Tray = preload("res://commons/artifacts/paired_dice_column/paired_die.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const MAX_THROWS := 5
const UNIT_HEIGHT := 0.09
const INK := Color(0.075,0.10,0.13)
const PINK := Color(0.96,0.40,0.61)
const BLUE := Color(0.25,0.76,0.89)
const EXAMPLE := [6,6,3]
signal chain_changed(state: Dictionary)
var tray: Node3D
var chain: Array[int] = []
var total := 0
var armed := false
var closed := false
var capped := false
var live_column: Node3D
var example_column: Node3D
var status: Label3D
var equation: Label3D
var record: Label3D
var gate: Node3D

func _ready() -> void:
	_box(self,"LiveBase",Vector3(0.20,0.07,-0.32),Vector3(0.56,0.14,0.56),INK,true)
	_box(self,"ExampleBase",Vector3(0.92,0.07,-0.76),Vector3(0.52,0.14,0.52),INK,true)
	live_column = Node3D.new()
	live_column.name = "LiveColumn"
	live_column.position = Vector3(0.20,0.14,-0.32)
	add_child(live_column)
	example_column = Node3D.new()
	example_column.name = "WorkedExample"
	example_column.position = Vector3(0.92,0.14,-0.76)
	add_child(example_column)
	_build_column(example_column,EXAMPLE,false)
	_box(self,"ExampleCaption",Vector3(0.92,1.82,-0.73),Vector3(0.65,0.54,0.025),INK,false)
	_label(self,"WORKED EXAMPLE\n6 + 6 + 3 = 15\nNOT LIVE THROWS",Vector3(0.92,1.82,-0.71),0.033)
	for x in [-1.22,-0.17]:
		_box(self,"CaptionPost",Vector3(x,0.82,-0.19),Vector3(0.025,1.64,0.035),INK,false)
	_box(self,"LedgerCase",Vector3(-0.70,1.47,-0.17),Vector3(1.12,0.56,0.07),INK,true)
	_label(self,"SIX / THROW AGAIN",Vector3(-0.70,1.67,-0.13),0.048)
	record = _label(self,"",Vector3(-0.70,1.53,-0.13),0.028)
	equation = _label(self,"",Vector3(-0.70,1.40,-0.13),0.052)
	status = _label(self,"",Vector3(-0.70,1.28,-0.13),0.029)
	# A visible open/closed arm answers the continuation rule; it is not a die gate.
	gate = Node3D.new()
	gate.name = "PermissionFlag"
	gate.position = Vector3(-0.16,1.77,-0.14)
	add_child(gate)
	_box(gate,"Arm",Vector3(0,0.12,0),Vector3(0.025,0.24,0.025),PINK,false)
	_box(gate,"Flag",Vector3(0.09,0.20,0),Vector3(0.18,0.09,0.025),PINK,false)
	tray = Tray.new()
	tray.name = "LiveDie"
	tray.position = Vector3(-0.70,0,0.30)
	tray.dice_color = Color(0.95,0.85,0.90)
	tray.felt_color = Color(0.24,0.075,0.13)
	tray.lifted.connect(_on_lifted)
	tray.released.connect(_on_released)
	tray.landed.connect(_on_landed)
	tray.returned.connect(_on_returned)
	add_child(tray)
	var panel := Rack.create_panel("",[[{"type":"button","label":"RETURN DIE"},{"type":"button","label":"NEW CHAIN"}]],true)
	panel.position = Vector3(-0.70,0.97,0.76)
	panel.rotation_degrees.x = -65
	panel.scale = Vector3.ONE*1.75
	add_child(panel)
	_box(self,"ControlShelf",Vector3(-0.70,0.86,0.73),Vector3(0.70,0.10,0.28),INK,true)
	panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): tray.return_to_tray())
	panel.find_child("Btn_1",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): new_chain())
	_label(self,"LIVE CHAIN",Vector3(0.20,0.08,-0.029),0.038)
	# This visible height limit is a budget, not a completed chain of sixes.
	for y in [0.68,1.22,1.76,2.30,2.84]:
		_box(self,"SixHeight",Vector3(0.51,y,-0.53),Vector3(0.08,0.014,0.014),INK,false)
	_box(self,"LimitPost",Vector3(0.55,1.49,-0.53),Vector3(0.02,2.70,0.02),INK,false)
	_box(self,"LimitCap",Vector3(0.20,2.86,-0.32),Vector3(0.56,0.025,0.56),Color(0.94,0.68,0.23,0.35),false)
	_box(self,"LimitCaption",Vector3(0.20,2.96,-0.04),Vector3(0.78,0.16,0.035),INK,false)
	_label(self,"5-THROW DISPLAY LIMIT",Vector3(0.20,2.96,-0.020),0.036)
	_refresh()

func _on_lifted() -> void:
	armed = false

func _on_released() -> void:
	armed = not closed and not capped

func _on_returned() -> void:
	armed = false # Recovery is not a fresh throw.

func _on_landed(face: int) -> void:
	if not armed or closed or capped or face < 1 or face > 6: return
	armed = false
	chain.append(face)
	total += face
	closed = face != 6
	capped = not closed and chain.size() >= MAX_THROWS
	_build_column(live_column,chain,true)
	_refresh()
	chain_changed.emit(get_state())

func new_chain() -> void:
	armed = false
	chain.clear()
	total = 0
	closed = false
	capped = false
	# If held, keep ownership with the hand; its next release starts the new chain.
	tray._is_rolling = false
	tray._settle_timer = 0.0
	tray._still_armed = false
	tray.return_to_tray()
	_build_column(live_column,chain,true)
	_refresh()
	chain_changed.emit(get_state())

func _refresh() -> void:
	var terms := PackedStringArray()
	for value in chain: terms.append(str(value))
	record.text = "%d / %d THROWS" % [chain.size(),MAX_THROWS]
	equation.text = "?" if chain.is_empty() else " + ".join(terms)+" = "+str(total)
	if chain.is_empty(): status.text = "Throw into the tray"
	elif capped: status.text = "LIMIT / CHAIN UNFINISHED"
	elif closed: status.text = "CLOSED / NEW CHAIN to begin"
	else: status.text = "SIX / THROW AGAIN"
	gate.rotation_degrees.z = -90 if closed or capped else 0

func _build_column(host: Node3D, values: Array, solid: bool) -> void:
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	var height := 0.0
	for i in range(values.size()):
		var value: int = values[i]
		var segment := Node3D.new()
		segment.name = "Throw_%d" % (i+1)
		segment.position.y = height
		host.add_child(segment)
		var colour := PINK if value == 6 else BLUE
		for unit in range(value):
			_box(segment,"Unit",Vector3(0,(unit+0.5)*UNIT_HEIGHT,0),Vector3(0.36,UNIT_HEIGHT-0.004,0.36),colour,false)
		_box(segment,"Join",Vector3(0,0.004,0),Vector3(0.375,0.008,0.375),Color(0.96,0.94,0.87),false)
		_label(segment,"+%d"%value,Vector3(0,value*UNIT_HEIGHT*0.5,0.185),0.050,INK)
		height += value*UNIT_HEIGHT
	if solid and height > 0:
		var body := StaticBody3D.new()
		body.name = "ColumnSupport"
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.36,height,0.36)
		collision.shape = shape
		collision.position.y = height*0.5
		body.add_child(collision)
		host.add_child(body)

func get_state() -> Dictionary:
	return {"chain":chain.duplicate(),"total":total,"armed":armed,"closed":closed,"capped":capped,"max_throws":MAX_THROWS,"height":total*UNIT_HEIGHT,"worked_example":EXAMPLE.duplicate()}
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
