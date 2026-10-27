extends "res://commons/artifacts/line_black_box/line_black_box.gd"
## One pair joins the entrance puzzle and the museum's black measuring room.
## Joining opens the threshold; separating the same points measures the line.
signal opened
const Fence = preload("res://commons/void/entry_fence.gd")
const START_A := Vector3(-.3,1.25,.8)
const START_B := Vector3(.3,1.25,.8)
var unlocked := false
var armed := false
var close_time := 0.0
var gate: Node3D
var glow: OmniLight3D
var measure_readout: Label3D

func _ready() -> void:
	super()
	for label in get_children():
		if label is Label3D and label != readout and label.text != "RESET": label.queue_free()
	readout.position = Vector3(0, 2.0, -1.0)
	readout.rotation = Vector3.ZERO
	readout.font_size = 32
	measure_readout = _label("JOIN THE TWO POINTS", Vector3(0,1.83,6.61), 52, Color("f2ece4"))
	_label("TWO POINTS / ONE LINE", Vector3(0,2.20,6.61), 28, Color("c1b8bc"))
	_label("Join to open. Pull apart to measure.", Vector3(0,1.06,6.61), 25, Color("c1b8bc"))
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
	# The original black-box reset now belongs to the shared room, facing in.
	super()
	get_node("ResetCap").position.z = 6.61
	reset_button.position.z = 6.57
	for label in get_children():
		if label is Label3D and label.text == "RESET": label.position.z = 6.60

func _endpoint(title: String, at: Vector3) -> XRToolsPickable:
	var point := super(title, at)
	var handle: MeshInstance3D = point.get_node("Handle")
	var sphere: SphereMesh = handle.mesh
	sphere.radius = .035
	sphere.height = .07
	var finish := _material(Color("08090b"), .16)
	finish.metallic = .35
	handle.material_override = finish
	for child in point.get_children():
		if child is MeshInstance3D and child.mesh is TorusMesh: child.free()
	# Keep the original pickup volume: small visible points remain easy to grab.
	return point

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
	# Black-box lining inside the existing white shell. No second room, pair of
	# handles or ceiling across the drop-in landing; the fence remains the exit.
	var black := _material(Color("101015"), .88)
	for x in [-2.866,2.866]:
		_box("MeasuringLining",Vector3(.018,3.05,7.4),Vector3(x,1.525,2.9),black)
	_box("MeasuringBack",Vector3(5.72,3.05,.018),Vector3(0,1.525,6.665),black)
	_box("ReadoutPlate",Vector3(3.9,1.55,.025),Vector3(0,1.75,6.64),_material(Color("181a21"),.7))
	var study_light := OmniLight3D.new()
	study_light.name = "StudyLight"
	study_light.position = Vector3(0,2.75,2.3)
	study_light.light_color = Color("eee0e1")
	study_light.light_energy = .9
	study_light.omni_range = 6.0
	study_light.shadow_enabled = true
	add_child(study_light)

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
	readout.text = "LINE / %.2f m" % span if unlocked else "BRING THE TWO POINTS CLOSE"
	if measure_readout != null:
		measure_readout.text = "%.2f m" % span if unlocked else "JOIN THE TWO POINTS"

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
