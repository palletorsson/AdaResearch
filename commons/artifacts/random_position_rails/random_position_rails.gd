extends Node3D
## @identity
## essence: a new position discards the old one; a step needs somewhere to start
## desire: put your marker where the next carriage might arrive
## truth: shared PRNG input; targets are sampled before a matched-duration motor animation
const LeverScene = preload("res://commons/interactables/lever_zero.tscn")
const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const LIMIT := 2.2
const STEP := 0.4
const SEED := 79
const MEMORY := 12
const REVEAL_SECONDS := 0.65
const MOVE_SECONDS := 1.0
const INK := Color(0.075,0.10,0.13)
const BLUE := Color(0.25,0.76,0.89)
const PINK := Color(0.96,0.40,0.61)
signal move_finished(index: int)
var generator := RandomNumberGenerator.new()
var committed := Vector2.ZERO
var targets := Vector2.ZERO
var start_positions := Vector2.ZERO
var sample := 0.0
var raw_step_target := 0.0
var tick := 0
var busy := false
var running := false
var armed := true
var resetting := false
var history: Array = []
var carriages: Array[Node3D] = []
var target_marks: Array[Node3D] = []
var lever: Node3D
var prediction: Node3D
var record: Node3D
var status: Label3D
var mode_label: Label3D
var fold_label: Label3D
var timer: Timer
var motion: Tween

func _ready() -> void:
	_make_frame()
	_make_prediction()
	_make_controls()
	timer = Timer.new()
	timer.wait_time = 2.8
	timer.timeout.connect(func(): advance())
	add_child(timer)
	replay()

func _make_frame() -> void:
	for x in [-2.46,2.46]:
		_box(self,"Foot",Vector3(x,0.06,0),Vector3(0.28,0.12,0.80),INK,true)
		_box(self,"Post",Vector3(x,1.25,0),Vector3(0.08,2.50,0.10),INK,true)
	_box(self,"Top",Vector3(0,2.48,0),Vector3(5.0,0.20,0.12),INK,true)
	_box(self,"RailBacking",Vector3(0,1.64,-0.105),Vector3(4.80,1.42,0.035),Color(0.91,0.91,0.83),false)
	_label(self,"WHERE NEXT?",Vector3(0,2.48,0.065),0.085)
	_label(self,"One new number. Two ways to use it.",Vector3(0,2.29,0.07),0.043,INK)
	for side in range(2):
		var y := _height(side)
		var colour := BLUE if side == 0 else PINK
		_box(self,"Rail",Vector3(0,y,-0.01),Vector3(4.6,0.035,0.035),INK,false)
		for x in [-LIMIT,0.0,LIMIT]:
			_box(self,"RailTick",Vector3(x,y,0),Vector3(0.013,0.16,0.025),INK,false)
		var block := Node3D.new()
		block.name = "Carriage%d" % side
		block.position = Vector3(0,y,0.09)
		add_child(block)
		_box(block,"Body",Vector3.ZERO,Vector3(0.24,0.24,0.18),colour,false)
		_label(block,"NEW" if side == 0 else "+",Vector3(0,0,0.093),0.05,INK)
		carriages.append(block)
		var target := Node3D.new()
		target.name = "Target%d" % side
		target.position = Vector3(0,y,0.20)
		add_child(target)
		for dx in [-0.155,0.155]:
			_box(target,"Side",Vector3(dx,0,0),Vector3(0.015,0.325,0.015),colour,false)
		for dy in [-0.155,0.155]:
			_box(target,"Edge",Vector3(0,dy,0),Vector3(0.325,0.015,0.015),colour,false)
		target_marks.append(target)
		_label(self,"FRESH POSITION" if side == 0 else "ADD A STEP",Vector3(-1.55,y+0.245,0.07),0.058,INK)
		_label(self,"anywhere on this rail" if side == 0 else "up to 40 cm from here / fold at the ends",Vector3(0.80,y+0.245,0.07),0.032,INK)
	_box(self,"RecordBack",Vector3(0,0.48,-0.09),Vector3(4.58,0.80,0.055),INK,false)
	for i in range(MEMORY):
		_box(self,"RecordRow",Vector3(0,0.77-i*0.05,-0.053),Vector3(4.4,0.004,0.006),Color(0.19,0.23,0.25),false)
	record = Node3D.new()
	record.name = "LastTwelveLandings"
	add_child(record)
	_label(self,"LAST 12 LANDINGS / NEWEST AT THE TOP",Vector3(0,0.12,-0.045),0.028)
	status = _label(self,"",Vector3(0,1.12,0.05),0.035,INK)
	fold_label = _label(self,"",Vector3(1.0,1.01,0.05),0.027,INK)

func _height(side: int) -> float:
	return 1.96 if side == 0 else 1.43

func _make_prediction() -> void:
	prediction = SliderScene.instantiate()
	prediction.name = "PredictionMarker"
	prediction.position = Vector3(0,0.92,0.51)
	prediction.get_node("SliderOrigin").position.x = -LIMIT
	var driver: Node3D = prediction.get_node("SliderOrigin/InteractableSlider")
	driver.set("slider_limit_max",2.0*LIMIT)
	driver.set("slider_position",LIMIT)
	driver.set("default_position",LIMIT)
	driver.set("default_on_release",false)
	_resize_mesh(prediction.get_node("Frame/BaseMesh"),Vector3(4.60,0.12,0.025))
	_resize_mesh(prediction.get_node("Frame/TrackMesh"),Vector3(4.40,0.012,0.008))
	_resize_shape(prediction.get_node("Frame/CollisionShape3D"),Vector3(4.60,0.12,0.045))
	prediction.get_node("Frame/LabelName").hide()
	prediction.get_node("Frame/Label3DValue").hide()
	_resize_mesh(driver.get_node("SliderBody/AccentMesh"),Vector3(0.14,0.15,0.10))
	_resize_shape(driver.get_node("SliderBody/HandleCollision"),Vector3(0.15,0.16,0.11))
	_resize_shape(driver.get_node("HandleOrigin/InteractableHandle/CollisionShape3D"),Vector3(0.17,0.18,0.12))
	driver.get_node("SliderBody/ShadowMesh").hide()
	_box(driver,"PredictionNeedle",Vector3(0,0.68,0.06),Vector3(0.012,1.30,0.012),Color.WHITE,false)
	_label(driver,"?",Vector3(0,1.37,0.06),0.085,INK)
	add_child(prediction)
	prediction.set_range(-LIMIT,LIMIT)
	_label(self,"DRAG A GUESS",Vector3(0,0.87,0.545),0.028,INK)
	for x in [-2.30,2.30]:
		_box(self,"MarkerSupport",Vector3(x,0.45,0.48),Vector3(0.05,0.90,0.08),INK,true)

func _resize_mesh(node: MeshInstance3D, size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh

func _resize_shape(node: CollisionShape3D, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	node.shape = shape

func _make_controls() -> void:
	lever = LeverScene.instantiate()
	lever.name = "NextLever"
	lever.position = Vector3(-2.70,1.10,0.55)
	lever.scale = Vector3.ONE*1.5
	add_child(lever)
	lever.set_caption("NEXT")
	lever.set_readout_visible(false)
	lever.hinge_moved.connect(_lever_moved)
	_box(self,"LeverStand",Vector3(-2.70,0.5,0.53),Vector3(0.22,1.0,0.20),INK,true)
	var panel := Rack.create_panel("",[[{"type":"button","label":"RUN / HOLD"},{"type":"button","label":"REPLAY"}]],true)
	panel.name = "RunReplay"
	panel.position = Vector3(2.73,1.02,0.55)
	panel.rotation_degrees.x = -65
	panel.scale = Vector3.ONE*1.7
	add_child(panel)
	panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): set_running(not running))
	panel.find_child("Btn_1",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): replay())
	_box(self,"ButtonStand",Vector3(2.73,0.46,0.53),Vector3(0.32,0.92,0.22),INK,true)
	mode_label = _label(self,"HOLD",Vector3(2.73,1.23,0.57),0.034,INK)

func _lever_moved(angle: float) -> void:
	if resetting: return
	if angle < 8.0: armed = true
	if angle >= 28.0 and armed:
		armed = false
		advance()

func advance() -> bool:
	if busy or resetting: return false
	busy = true
	start_positions = committed
	sample = generator.randf_range(-1.0,1.0)
	raw_step_target = committed.y + sample*STEP
	targets = Vector2(sample*LIMIT,reflect_position(raw_step_target))
	for side in range(2):
		target_marks[side].position.x = targets[side]
		target_marks[side].show()
	status.text = "NEXT TARGETS / the motor has not moved yet"
	fold_label.text = "STEP FOLDED AT THE END" if not is_equal_approx(raw_step_target,targets.y) else ""
	motion = create_tween()
	motion.tween_interval(REVEAL_SECONDS)
	motion.tween_callback(func(): status.text = "ONE SECOND / same easing, different distances")
	motion.tween_method(_travel,0.0,1.0,MOVE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(_finish)
	return true

static func reflect_position(value: float) -> float:
	# Triangular folding also handles overshoots larger than this exhibit allows.
	var along := fposmod(value+LIMIT,4.0*LIMIT)
	return -LIMIT+along if along <= 2.0*LIMIT else 3.0*LIMIT-along

func _travel(weight: float) -> void:
	for side in range(2):
		carriages[side].position.x = lerpf(start_positions[side],targets[side],weight)

func _finish() -> void:
	committed = targets
	tick += 1
	history.append([committed.x,committed.y])
	if history.size() > MEMORY: history.pop_front()
	_refresh_record()
	busy = false
	motion = null
	status.text = "%d MOVES / blue chooses a place; pink adds to its place" % tick
	move_finished.emit(tick)

func _refresh_record() -> void:
	for child in record.get_children():
		record.remove_child(child)
		child.queue_free()
	for i in range(history.size()):
		var pair: Array = history[history.size()-1-i]
		for side in range(2):
			_box(record,"Landing",Vector3(float(pair[side]),0.77-i*0.05,-0.025+side*0.012),Vector3(0.045,0.038,0.02),BLUE if side == 0 else PINK,false)

func set_running(value: bool) -> void:
	running = value
	mode_label.text = "RUN" if running else "HOLD"
	if running:
		timer.start()
		advance()
	else:
		timer.stop() # A move already revealed finishes; HOLD stops future draws.

func replay() -> void:
	resetting = true
	if motion != null: motion.kill()
	motion = null
	set_running(false)
	generator.seed = SEED
	committed = Vector2.ZERO
	targets = Vector2.ZERO
	start_positions = Vector2.ZERO
	sample = 0.0
	raw_step_target = 0.0
	tick = 0
	busy = false
	armed = true
	history.clear()
	_refresh_record()
	for side in range(2):
		carriages[side].position.x = 0.0
		target_marks[side].hide()
	prediction.set_normalized_value(0.5)
	lever.set_angle_degrees(0.0)
	status.text = "Put your marker where the next carriage might land. Pull NEXT."
	fold_label.text = ""
	resetting = false

func get_state() -> Dictionary:
	return {"tick":tick,"busy":busy,"running":running,"seed":SEED,"sample":sample,
		"from":[start_positions.x,start_positions.y],"targets":[targets.x,targets.y],
		"committed":[committed.x,committed.y],"raw_step_target":raw_step_target,
		"carriages":[carriages[0].position.x,carriages[1].position.x],
		"prediction":lerpf(-LIMIT,LIMIT,prediction.get_normalized_value()),
		"history":history.duplicate(true),"limit":LIMIT,"step":STEP,"memory":MEMORY}
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
