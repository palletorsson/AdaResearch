extends "res://commons/artifacts/line_black_box/line_black_box.gd"
## The museum's two endpoints become a threshold. The landing stays open above.
signal opened
const Fence = preload("res://commons/void/entry_fence.gd")
const START_A := Vector3(-.3,1.25,.8)
const START_B := Vector3(.3,1.25,.8)
var unlocked := false
var armed := false
var close_time := 0.0
var gate: Node3D
var glow: OmniLight3D

func _ready() -> void:
	super()
	for label in get_children():
		if label is Label3D and label != readout: label.queue_free()
	readout.position = Vector3(0, 2.0, -1.0)
	readout.rotation = Vector3.ZERO
	readout.font_size = 32
	var instruction := _label("01 / TWO POINTS OPEN A WAY\nHold grip. Bring the points together.", Vector3(0,2.95,-3.25), 34, Color("292830"))
	instruction.rotation = Vector3.ZERO
	glow = OmniLight3D.new()
	glow.name = "LineLight"
	glow.light_color = Color("ffd3df")
	glow.light_energy = 2.0
	glow.omni_range = 4.0
	glow.shadow_enabled = true
	add_child(glow)
	for point in [point_a,point_b]: point.picked_up.connect(func(_point): armed = true)
	reset_line()

func _build_reset() -> void:
	# Retry uses reset_line. There is no reset button behind the enclosure.
	pass

func _build_room() -> void:
	var concrete := _material(Color("f0efeb"),1.0)
	concrete.metallic_specular = 0.0
	# World footprint: x +/-3, z 1..11.2 including the existing south landing.
	_box("West",Vector3(.12,3.2,10.2),Vector3(-2.94,1.6,1.7),concrete,true)
	_box("East",Vector3(.12,3.2,10.2),Vector3(2.94,1.6,1.7),concrete,true)
	_box("South",Vector3(6,3.2,.12),Vector3(0,1.6,6.74),concrete,true)
	for x in [-1.95,1.95]:
		_box("NorthPanel",Vector3(2.1,3.2,.12),Vector3(x,1.6,-3.34),concrete,true)
	_box("Header",Vector3(1.8,.6,.12),Vector3(0,2.9,-3.34),concrete,true)
	gate = Node3D.new()
	gate.name = "GridDoor"
	gate.position = Vector3(0,0,-3.34)
	add_child(gate)
	var fence := Fence.new()
	fence.name = "ConstructionFence"
	gate.add_child(fence)
	var body := StaticBody3D.new()
	body.name = "ClosedDoorCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new();shape.size=Vector3(1.8,2.6,.10)
	collision.shape=shape;collision.position.y=1.3
	body.add_child(collision);gate.add_child(body)
	for x in [-2.85,2.85]:
		_box("LandingEdge",Vector3(.025,.02,9.8),Vector3(x,.03,1.6),_material(Color("c297ac"),.5,.3))

func _process(delta: float) -> void:
	if not is_instance_valid(point_a) or glow == null: return
	var span := point_a.global_position.distance_to(point_b.global_position)
	var held := point_a.is_picked_up() or point_b.is_picked_up()
	if not unlocked:
		close_time = close_time + delta if armed and span <= .24 else 0.0
		if close_time >= .25:
			unlocked = true
			create_tween().tween_property(gate,"position:y",2.8,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			opened.emit()
	var segment: MeshInstance3D = line.get("current_line")
	segment.visible = unlocked and span > .001
	glow.global_position = (point_a.global_position+point_b.global_position)*.5
	glow.visible = held or unlocked
	glow.light_energy = 2.0 if held else 0.65
	readout.text = "A LINE / A WAY THROUGH" if unlocked else "BRING THE TWO POINTS CLOSE"

func reset_line() -> void:
	if point_a.is_picked_up() or point_b.is_picked_up(): return
	for pair in [[point_a,START_A],[point_b,START_B]]:
		var point: XRToolsPickable = pair[0]
		point.global_transform = line.global_transform * Transform3D(Basis.IDENTITY,pair[1])
		PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
		point.linear_velocity = Vector3.ZERO; point.angular_velocity = Vector3.ZERO
	line.update_line_transform(point_a.position,point_b.position)
	if not unlocked: armed=false;close_time=0.0
	_process(0.0)
	# Solving survives a fall and streamed return. Only the held material resets.
