extends Node3D
## Three bare lines. Contact moves one virtual hand, never the body or camera.
const Motion = preload("motion_record.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Point = preload("res://commons/artifacts/random_return/ride_point.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const HandFollower = preload("hand_follower.gd")
const HOMES := [Vector3(0,1.25,2), Vector3(0,1.25,0), Vector3(0,1.25,-2)]
const NAMES := ["1 / X", "2 / X — FASTER", "3 / X + Y"]
const RETURN_SPEED := 0.8
var record := Motion.make_record()
var kept: Dictionary = {}
var times: Array = [0.0,0.0,0.0]
var offsets: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var returning: Array = [false,false,false]
var blocked: Array[bool] = [false,false,false]
var paused := false
var points: Array = []
var areas: Array[Area3D] = []
var lines: Array[MeshInstance3D] = []
var readout: Label3D
var active_lane := -1
var follower: Node3D
var active_controller: XRController3D
var held_motion := false
var save_path := "user://random-touch-lines-001.json"
var message := ""

func _ready() -> void:
	if HallSeed.enabled(self): record = Motion.make_record(HallSeed.current(self))
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-1.3,0,-2.3),Vector3(2.6,2.9,5.4)))
	process_physics_priority = -100 # Set the target before XR collision/visual hands.
	follower = HandFollower.new()
	follower.name = "HandMotionTarget"
	add_child(follower)
	_label("TOUCH / BE MOVED",Vector3(0,2.65,0),30)
	for lane in 3:
		var line := Stage.box(self,HOMES[lane],Vector3(2.0,0.012,0.012),Color("6ba4a8"))
		line.name = "Line%d" % lane
		lines.append(line)
		_label(NAMES[lane],HOMES[lane]+Vector3(-0.65,-0.24,0),20)
		var point = Point.new()
		point.name = "TouchSphere%d" % lane
		point.position = HOMES[lane]
		add_child(point)
		points.append(point)
		var touch := Area3D.new()
		touch.collision_layer = 0
		touch.collision_mask = 393216
		var boundary := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.24
		boundary.shape = shape
		touch.add_child(boundary)
		point.add_child(touch)
		areas.append(touch)
	var board = Rack.create_panel("THREE HAND PATHS", [[{"type":"button","label":"REPLAY","shape":"rect"},{"type":"button","label":"PAUSE","shape":"rect"},{"type":"button","label":"KEEP","shape":"rect"},{"type":"button","label":"LOAD","shape":"rect"}]])
	board.position = Vector3(0,0.78,2.8)
	board.rotation_degrees.x = -25
	add_child(board)
	for i in 4: board.find_child("Btn_%d" % i,true,false).pressed.connect(act.bind(i))
	readout = _label("",Vector3(0,0.48,2.8),18)
	_label("Touch: the virtual hand follows. Withdraw to release.\nDesktop: right-click to run / release the sphere.",Vector3(0,2.4,2),20)
	_update_pose()
	HallSeed.bind(self)

func can_apply_hall_seed() -> bool:
	return not _busy()

func _apply_hall_seed(value: int, _receipt: Dictionary) -> void:
	record = Motion.make_record(value)
	times = [0.0,0.0,0.0]
	offsets.assign([Vector3.ZERO,Vector3.ZERO,Vector3.ZERO])
	returning = [false,false,false]
	paused = false
	_update_pose()

func _label(words: String, at: Vector3, size: int) -> Label3D:
	var l := Stage.label(self,words,at)
	l.font_size = size
	l.pixel_size = 0.0018
	l.outline_size = 0
	return l

func _physics_process(delta: float) -> void:
	_sync_hand()
	advance(delta)

func _contacts(lane: int) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for body in areas[lane].get_overlapping_bodies():
		if _controller(body) != null: found.append(body)
	return found

func _controller(body: Node) -> XRController3D:
	var node := body
	while node != null:
		if node is XRController3D: return node
		node = node.get_parent()
	return null

func _sync_hand() -> void:
	if active_lane >= 0:
		var point = points[active_lane]
		if paused or (held_motion and not point.held()):
			stop_motion()
		elif is_instance_valid(active_controller):
			if follower.withdrawn(): stop_motion()
		elif follower.installed or not point.held():
			stop_motion()
	for lane in 3:
		var hands := _contacts(lane)
		if not points[lane].held() and hands.is_empty(): blocked[lane] = false
		if active_lane >= 0 or paused or blocked[lane] or returning[lane]: continue
		if points[lane].held():
			begin_motion(lane, points[lane].get_picked_up_by_controller())
		else:
			for hand in hands:
				if begin_motion(lane, _controller(hand)): break

func begin_motion(lane: int, controller: XRController3D = null) -> bool:
	if lane < 0 or lane >= 3 or active_lane >= 0 or paused: return false
	if returning[lane] or blocked[lane]: return false
	if controller != null:
		if not follower.begin(controller, points[lane]): return false
	elif not points[lane].held():
		return false
	active_lane = lane
	active_controller = controller
	held_motion = points[lane].held()
	if controller != null and controller.get_is_active():
		controller.trigger_haptic_pulse("haptic",0.0,0.16,0.035,0.0)
	return true

func stop_motion() -> void:
	if active_lane < 0: return
	var lane := active_lane
	active_lane = -1
	follower.stop()
	active_controller = null
	held_motion = false
	returning[lane] = true
	blocked[lane] = true
	points[lane].release_rider()

func advance(delta: float) -> void:
	if not paused:
		for lane in 3:
			if lane == active_lane:
				times[lane] += maxf(delta,0.0)
				offsets[lane] = Motion.offset(record,lane,times[lane])
			elif returning[lane]:
				offsets[lane] = offsets[lane].move_toward(Vector3.ZERO,RETURN_SPEED*maxf(delta,0.0))
				if offsets[lane].is_zero_approx():
					offsets[lane] = Vector3.ZERO
					times[lane] = 0.0
					returning[lane] = false
	_update_pose()
	follower.update_target()

func _update_pose() -> void:
	for lane in points.size():
		points[lane].position = HOMES[lane] + offsets[lane]
		points[lane].freeze = true
		PhysicsServer3D.body_set_state(points[lane].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,points[lane].global_transform)
		points[lane].force_update_transform()
	readout.text = "SEED %d / %s%s\n%s" % [int(record.seed),"PAUSED" if paused else ("HAND %d" % (active_lane+1) if active_lane >= 0 else "WAITING FOR TOUCH")," / KEPT" if not kept.is_empty() else "",message]

func capture() -> Dictionary:
	var value := record.duplicate(true)
	if HallSeed.enabled(self): value["hall_receipt"] = HallSeed.state(self).receipt.duplicate(true)
	value.seconds = times.duplicate()
	value.returning = returning.duplicate()
	value.offsets = []
	for offset in offsets: value.offsets.append([offset.x,offset.y])
	return value

func _busy() -> bool:
	if active_lane >= 0: return true
	for point in points:
		if point.held(): return true
	return false

func restore(value: Dictionary) -> bool:
	if _busy() or not Motion.valid(value): return false
	if HallSeed.enabled(self) and not HallSeed.choose(self, int(value.seed), value.get("hall_receipt",{"provider":"saved_record","label":"Kept hand path","seed":int(value.seed)}), true): return false
	record = value.duplicate(true)
	times = record.seconds.duplicate()
	returning = record.returning.duplicate()
	for lane in 3: offsets[lane] = Vector3(record.offsets[lane][0],record.offsets[lane][1],0)
	paused = true
	_update_pose()
	return true

func act(index: int) -> void:
	message = ""
	if index in [0,3] and _busy():
		message = "Let go before replaying or loading."
		_update_pose()
		return
	match index:
		0:
			times = [0.0,0.0,0.0]
			offsets.assign([Vector3.ZERO,Vector3.ZERO,Vector3.ZERO])
			returning = [false,false,false]
			paused = false
		1:
			paused = not paused
			if paused: stop_motion()
		2:
			var value := capture()
			var file := FileAccess.open(save_path,FileAccess.WRITE)
			if file == null:
				message = "Could not save. Current path remains available."
			else:
				file.store_string(JSON.stringify(value))
				kept = value
		3:
			if not FileAccess.file_exists(save_path):
				message = "KEEP a comparison first."
			else:
				var value = JSON.parse_string(FileAccess.get_file_as_string(save_path))
				if not value is Dictionary or not restore(value):
					message = "Invalid recording; current path retained."
				else: kept = value.duplicate(true)
	_update_pose()

func _exit_tree() -> void:
	stop_motion()
