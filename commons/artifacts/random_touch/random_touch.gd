extends Node3D
## A compact five-row abacus. Contact moves one virtual hand, never the body.
const Motion = preload("motion_record.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Point = preload("res://commons/artifacts/random_return/ride_point.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const HandFollower = preload("hand_follower.gd")
const InkWall = preload("ink_wall.gd")
const HOMES := [Vector3(0,1.73,0), Vector3(0,1.59,0), Vector3(0,1.45,0), Vector3(0,1.31,0), Vector3(0,1.03,0)]
const NAMES := ["1 / X / ½×", "2 / X / 1×", "3 / X / 2×", "4 / X / 4×", "5 / X + Y / 1×"]
const BEAD_RADIUS := 0.05
const TOUCH_RADIUS := 0.065
const REPLAY_HEIGHT := 0.72
const RETURN_SPEED := 0.4
var record := Motion.make_record()
var kept: Dictionary = {}
var times: Array = [0.0,0.0,0.0,0.0,0.0]
var offsets: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var returning: Array = [false,false,false,false,false]
var blocked: Array[bool] = [false,false,false,false,false]
var paused := false
var points: Array = []
var areas: Array[Area3D] = []
var lines: Array[MeshInstance3D] = []
var readout: Label3D
var source_label: Label3D
var ink_labels: Array[Label3D] = []
var ink: Node3D
var active_lane := -1
var follower: Node3D
var active_controller: XRController3D
var held_motion := false
var save_path := "user://random-touch-ink-001.json"
var message := ""

func _ready() -> void:
	if HallSeed.enabled(self): record = Motion.make_record(HallSeed.current(self),record.distribution)
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-0.65,0,-0.25),Vector3(1.3,2.15,0.55)))
	process_physics_priority = -100 # Set the target before XR collision/visual hands.
	follower = HandFollower.new()
	follower.name = "HandMotionTarget"
	add_child(follower)
	ink = InkWall.new()
	ink.name = "RecordingWall"
	add_child(ink)
	ink.build(HOMES)
	# Pale recording paper, thin charcoal case, warm metal rods.
	var paper := Stage.box(self,Vector3(0,1.405,-0.145),Vector3(1.12,1.11,0.05),Color("eeeade"))
	paper.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Stage.box(self,Vector3(0,2.035,-0.08),Vector3(1.20,0.14,0.12),Color("213138")).set_meta("book_capture_omit",true)
	var title := _label("RANDOM / TOUCH",Vector3(0,2.04,0.005),28)
	title.modulate = Color("eeeade")
	for x in [-0.56,0.56]:
		Stage.box(self,Vector3(x,0.99,-0.10),Vector3(0.035,1.98,0.10),Color("213138")).set_meta("book_capture_omit",true)
		Stage.box(self,Vector3(x,0.025,0),Vector3(0.14,0.05,0.48),Color("213138")).set_meta("book_capture_omit",true)
	for y in [0.85,1.94]: Stage.box(self,Vector3(0,y,-0.10),Vector3(1.15,0.025,0.10),Color("213138")).set_meta("book_capture_omit",true)
	for lane in Motion.LANES:
		var line := Stage.box(self,HOMES[lane],Vector3(1.0,0.006,0.006),Color("b59c63"))
		line.name = "Line%d" % lane
		lines.append(line)
		_label(NAMES[lane],HOMES[lane]+Vector3(-0.30,0.20 if lane == 4 else 0.07,0.018),15)
		ink_labels.append(_label("0 marks",HOMES[lane]+Vector3(0.37,0.20 if lane==4 else 0.07,-0.07),12))
		for x in [-0.5,0.5]: Stage.box(self,HOMES[lane]+Vector3(x,0,-0.01),Vector3(0.018,0.026,0.035),Color("b59c63"))
		if lane == 4: Stage.box(self,HOMES[lane]+Vector3(0,0,-0.095),Vector3(0.002,Motion.Y_RANGE*2,0.002),Color("b6c0bb"))
		var point = Point.new()
		point.name = "TouchSphere%d" % lane
		point.position = HOMES[lane]
		add_child(point)
		point.sphere.radius = BEAD_RADIUS
		point.sphere.height = BEAD_RADIUS*2.0
		point.get_child(1).shape.radius = BEAD_RADIUS
		points.append(point)
		var touch := Area3D.new()
		touch.collision_layer = 0
		touch.collision_mask = 393216
		var boundary := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = TOUCH_RADIUS
		boundary.shape = shape
		touch.add_child(boundary)
		point.add_child(touch)
		areas.append(touch)
	var control_face := Stage.box(self,Vector3(0,0.67,-0.08),Vector3(1.12,0.34,0.10),Color("d7d7c9"))
	control_face.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var replay = load("res://commons/interactables/push_button.tscn").instantiate()
	replay.name = "ReplayButton"
	Rack.make_button_rectangular(replay)
	replay.rotation.x = PI/2
	replay.position = Vector3(0,REPLAY_HEIGHT,-0.025)
	replay.released_color = Color("263b41")
	replay.pressed_color = Color("c4a970")
	replay.get_node("ButtonBase/BaseMesh").visible = false
	replay.get_node("Button/ButtonMesh").mesh.size = Vector3(0.76,0.024,0.20)
	replay.get_node("AccentRing").mesh.size = Vector3(0.80,0.014,0.24)
	replay.get_node("Button/CollisionShape3D").shape.size = Vector3(0.76,0.028,0.20)
	replay.get_node("InteractableAreaButton/CollisionShape3D").shape.size = Vector3(0.80,0.06,0.24)
	add_child(replay)
	var caption := _label("REPLAY",Vector3.ZERO,52)
	caption.reparent(replay.get_node("Button"),false)
	caption.position = Vector3(0,0.015,0)
	caption.rotation.x = -PI/2
	caption.modulate = Color("eeeade")
	replay.pressed.connect(act.bind(0))
	readout = _label("",Vector3(0,0.53,-0.015),14)
	source_label = _label("",Vector3(0,1.89,-0.07),15)
	_update_pose()
	HallSeed.bind(self)

func can_apply_hall_seed() -> bool:
	return not _busy()

func _apply_hall_seed(value: int, _receipt: Dictionary) -> void:
	record = Motion.make_record(value,record.distribution)
	_reset_paths()
	paused = false
	_update_pose()

func _reset_paths() -> void:
	times.fill(0.0)
	offsets.fill(Vector3.ZERO)
	returning.fill(false)
	ink.clear()

func _label(words: String, at: Vector3, size: int) -> Label3D:
	var l := Stage.label(self,words,at)
	l.font_size = size
	l.pixel_size = 0.0018
	l.outline_size = 0
	l.modulate = Color("24363b")
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
	var candidates: Array = []
	for lane in Motion.LANES:
		var hands := _contacts(lane)
		if not points[lane].held() and hands.is_empty(): blocked[lane] = false
		if active_lane >= 0 or paused or blocked[lane] or returning[lane]: continue
		if points[lane].held():
			begin_motion(lane, points[lane].get_picked_up_by_controller())
		else:
			for hand in hands:
				candidates.append({"lane":lane,"hand":hand,"distance":hand.global_position.distance_squared_to(points[lane].global_position)})
	# A palm can overlap adjacent compact rows; choose the nearest bead.
	candidates.sort_custom(func(a,b): return a.distance < b.distance)
	for candidate in candidates:
		if active_lane >= 0: break
		if begin_motion(candidate.lane,_controller(candidate.hand)): break

func begin_motion(lane: int, controller: XRController3D = null) -> bool:
	if lane < 0 or lane >= Motion.LANES or active_lane >= 0 or paused: return false
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
		for lane in Motion.LANES:
			if lane == active_lane:
				var before: float = times[lane]
				times[lane] += maxf(delta,0.0)
				offsets[lane] = Motion.offset(record,lane,times[lane])
				ink.record_span(record,lane,before,times[lane])
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
		ink_labels[lane].text = "%d / %d marks" % [ink.marks[lane].size(),Motion.INK_LIMIT]
	source_label.text = "%s  ·  12 marks / step" % ("UNIFORM TARGETS" if record.distribution=="uniform" else "GAUSSIAN TARGETS / BOUNDED")
	readout.text = "SEED %d / %s%s\n%s" % [int(record.seed),"PAUSED" if paused else ("HAND %d" % (active_lane+1) if active_lane >= 0 else "WAITING FOR TOUCH")," / KEPT" if not kept.is_empty() else "",message]

func capture() -> Dictionary:
	var value := record.duplicate(true)
	if HallSeed.enabled(self): value["hall_receipt"] = HallSeed.state(self).receipt.duplicate(true)
	value.seconds = times.duplicate()
	value.returning = returning.duplicate()
	value.offsets = []
	value.ink = ink.marks.duplicate(true)
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
	for lane in Motion.LANES: offsets[lane] = Vector3(record.offsets[lane][0],record.offsets[lane][1],0)
	ink.restore(record.ink)
	paused = true
	_update_pose()
	return true

func act(index: int) -> void:
	message = ""
	if index in [0,3,4] and _busy():
		message = "Let go before changing the path."
		_update_pose()
		return
	match index:
		0:
			_reset_paths()
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
				file.store_string(JSON.stringify(value,"",true,true))
				kept = value
		3:
			if not FileAccess.file_exists(save_path):
				message = "KEEP a comparison first."
			else:
				var value = JSON.parse_string(FileAccess.get_file_as_string(save_path))
				if not value is Dictionary or not restore(value):
					message = "Invalid recording; current path retained."
				else: kept = value.duplicate(true)
		4:
			var distribution := "gaussian_bounded" if record.distribution=="uniform" else "uniform"
			record = Motion.make_record(int(record.seed),distribution)
			_reset_paths()
			paused = false
			message = "Same seed; new target distribution. Touch to compare."
		5:
			ink.clear()
			message = "Paper cleared; path and pace unchanged."
	_update_pose()

func _exit_tree() -> void:
	stop_motion()
