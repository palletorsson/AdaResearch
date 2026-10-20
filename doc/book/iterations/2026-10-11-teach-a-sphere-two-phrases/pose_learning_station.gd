extends Node3D
## Local, opt-in teaching station beside the existing dance. One capture is one
## independent held pose, averaged over a short window, never a cloud of frames.
const Learner := preload("res://commons/artifacts/vogue_timeline/pose_learner.gd")
const Phrase := preload("res://commons/artifacts/vogue_timeline/dance_phrase.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const HeightLesson := preload("res://commons/artifacts/vogue_timeline/height_learning.gd")
const MovementLesson := preload("res://commons/artifacts/vogue_timeline/movement_learning.gd")
const SAVE_PATH := "user://ada_hand_poses_v1.json"
const COLORS := [Color(1.0, 0.24, 0.58), Color(0.15, 0.84, 1.0), Color(1.0, 0.77, 0.25)]
var model := Learner.new()
var lesson := "POSE"
var height_lesson: RefCounted
var movement_lesson: RefCounted
var score_label: Label3D
var host: Node3D
var mode := "TEACH"
var training := false
var aligned := false
var facing := Basis.IDENTITY
var capture_label := -1
var capture_time := 0.0
var sample_time := 0.0
var samples: Array = []
var controls: Node3D
var status: Label3D
var metrics: Label3D
var count_label: Label3D
var response_label: Label3D
var sphere: MeshInstance3D
var sphere_material: StandardMaterial3D
var bars: Array[MeshInstance3D] = []
var chart: Array[MeshInstance3D] = []
var clock := 0.0
var response := -1
var candidate := -1
var dwell := 0.0
var message := "TEACH: press A, B or C. Pose after the countdown."
var reset_until := 0
var last_prediction: Dictionary = {}

func _ready() -> void:
	host = get_parent()
	_build()
	height_lesson=HeightLesson.new(self)
	movement_lesson=MovementLesson.new(self)
	_refresh()

func tracked_here() -> bool:
	return host.tracked() and host.head.global_position.distance_to(global_position) < 3.0

func align() -> void:
	if not tracked_here(): return
	var forward: Vector3 = -host.head.global_basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.01:
		facing = Basis.looking_at(forward.normalized(), Vector3.UP)
		aligned = true

func _process(delta: float) -> void:
	clock += delta
	if lesson=="PHRASE":
		movement_lesson.tick(delta)
		return
	if lesson=="HEIGHT":
		height_lesson.tick(delta)
		return
	if training:
		# Bounded work keeps the museum responsive, including in XR.
		for _batch in 2: model.train_epoch()
		if model.trained:
			training = false
			mode = "TEST"
			message = "TRAINED. TEST: press A/B/C and perform a fresh pose."
		_refresh()
	var valid := tracked_here()
	var x: Array = []
	if valid and aligned:
		var l := Phrase.feature(host.head.global_position, host.left.global_position, facing, 0.65)
		var r := Phrase.feature(host.head.global_position, host.right.global_position, facing, 0.65)
		x = [l.x, l.y, l.z, r.x, r.y, r.z]
	advance_capture(delta, x, valid and aligned)
	if mode == "LIVE" and not training:
		observe(delta, x, valid and aligned)
	else:
		response = -1
	animate_response()

func command(which: String) -> void:
	if which in ["POSE","HEIGHT","PHRASE"]:
		if which==lesson or training or height_lesson.training: return
		capture_label=-1;samples.clear();response=-1;candidate=-1;dwell=0.0;last_prediction.clear()
		if lesson=="HEIGHT": height_lesson.deactivate()
		if lesson=="PHRASE": movement_lesson.deactivate()
		lesson=which
		if lesson=="HEIGHT": height_lesson.activate()
		elif lesson=="PHRASE": movement_lesson.activate()
		else:
			_build_pose_controls()
			mode="TEST" if model.trained else "TEACH"
			message="POSE / choose TEACH, TEST or LIVE. Your examples are kept."
			_refresh();animate_response()
		return
	if lesson=="PHRASE":
		movement_lesson.command(which)
		return
	if lesson=="HEIGHT":
		height_lesson.command(which)
		return
	if training:
		message = "Learning locally / %d of %d updates" % [model.epoch, Learner.EPOCHS]
		_refresh()
		return
	if which in ["A", "B", "C"]:
		begin_capture(["A", "B", "C"].find(which))
		return
	capture_label = -1
	samples.clear()
	response = -1
	candidate = -1
	dwell = 0.0
	last_prediction.clear()
	match which:
		"TEACH":
			mode = "TEACH"
			message = "Press A/B/C. Collect at least 3 separate takes per pose."
		"TEST":
			if model.trained:
				mode = "TEST"
				message = "Press the expected A/B/C; perform a NEW take. Weights stay fixed."
			else: message = "Teach 3 takes each, then TRAIN before testing."
		"LIVE":
			if model.trained:
				if not aligned: align()
				mode = "LIVE"
				message = "Your pose drives the sphere. Low score or distant input: idle."
			else: message = "Teach and TRAIN first. No built-in pose answers."
		"TRAIN":
			if model.can_train():
				model.initialize(417)
				training = true
				mode = "TRAIN"
				message = "Learning 83 parameters from your examples."
			else: message = "Need 3 takes EACH for A, B and C. Change pose between takes."
		"ALIGN":
			align()
			message = "Facing aligned. Keep this direction while teaching and testing." if aligned else "Head and both hands needed to align."
		"SAVE":
			message = "Examples + model saved on this device." if model.save_file(SAVE_PATH) == OK else "Could not save. Your current examples remain here."
		"LOAD":
			if model.load_file(SAVE_PATH):
				aligned = false
				align()
				mode = "TEST" if model.trained else "TEACH"
				message = "Loaded. Evaluation starts fresh; saved weights are retained."
			else: message = "No valid saved session. Current model unchanged."
		"RESET":
			if Time.get_ticks_msec() < reset_until:
				model = Learner.new()
				mode = "TEACH"
				aligned = false
				reset_until = 0
				message = "Session cleared. Saved file remains until you SAVE again."
			else:
				reset_until = Time.get_ticks_msec() + 4000
				message = "Press RESET again within 4 seconds to clear this session."
	_refresh()

func begin_capture(label: int) -> void:
	if label < 0 or label > 2 or training or capture_label >= 0: return
	if mode not in ["TEACH", "TEST"]:
		message = "Choose TEACH or TEST before recording a pose."
	elif not tracked_here():
		message = "Move to the station with head + both controllers tracked."
	elif mode == "TEST" and not model.trained:
		message = "Train first."
	else:
		if not aligned: align()
		if host.playing: host.command("PLAY")
		capture_label = label
		capture_time = -3.0
		sample_time = 0.0
		samples.clear()
	_refresh()

func advance_capture(delta: float, x: Array, valid: bool) -> void:
	if capture_label < 0: return
	if not valid or not Learner.valid_input(x):
		capture_label = -1
		samples.clear()
		message = "Tracking lost / take discarded. Press A/B/C to try again."
		_refresh()
		return
	if delta > 0.20:
		capture_label = -1
		samples.clear()
		message = "Capture interrupted / take discarded. Try again."
		_refresh()
		return
	capture_time += maxf(0.0, delta)
	if capture_time < 0.0:
		message = "%s %s / READY %d / choose your pose" % [mode, ["A","B","C"][capture_label], ceili(-capture_time)]
	else:
		message = "HOLD BOTH HANDS / one take"
		sample_time += delta
		if sample_time >= 0.05:
			sample_time = 0.0
			samples.append(x.duplicate())
		if capture_time >= 0.65:
			_complete_capture()
	_refresh()

func _complete_capture() -> void:
	var label := capture_label
	capture_label = -1
	if samples.size() < 8:
		message = "Too few tracked samples. Try another take."
		return
	var mean := [0.0,0.0,0.0,0.0,0.0,0.0]
	for row: Array in samples:
		for i in 6: mean[i] += float(row[i]) / samples.size()
	var spread := 0.0
	for row: Array in samples:
		for i in 6: spread += pow(float(row[i])-mean[i],2) / (samples.size()*6)
	samples.clear()
	if sqrt(spread) > 0.12:
		message = "This take moved too much. Hold a pose briefly; try again."
		return
	if mode == "TEACH":
		message = "One %s example kept. Change pose, then demonstrate again." % ["A","B","C"][label] if model.add_example(mean,label) else "Maximum 20 takes for this pose."
	else:
		var result := model.test_example(mean,label)
		if not result.is_empty():
			message = "Expected %s / predicted %s / %s / no training" % [["A","B","C"][label], ["A","B","C"][result.predicted], "accepted" if result.accepted else "withheld"]

func observe(delta: float, x: Array, valid: bool) -> void:
	last_prediction = model.predict(x) if valid else {}
	var next := int(last_prediction.label) if not last_prediction.is_empty() and last_prediction.accepted else -1
	if next != candidate:
		candidate = next
		dwell = 0.0
	dwell += clampf(delta, 0.0, 0.10)
	response = candidate if candidate >= 0 and dwell >= 0.25 else -1
	message = "Head + both hands needed / sphere idle" if not valid else "Scores are model outputs, not certainty. Unfamiliar poses may still match."
	_refresh()

func animate_response() -> void:
	sphere.position = Vector3(0, 1.20, 0.12)
	sphere.scale = Vector3.ONE
	sphere.rotation = Vector3.ZERO
	sphere_material.albedo_color = Color(0.85,0.87,0.91) if response < 0 else COLORS[response]
	match response:
		0: sphere.position.y += 0.10 + sin(clock * 2.0) * 0.08
		1: sphere.rotation = Vector3(clock*1.8, clock, 0.3)
		2: sphere.scale = Vector3(1.0, 1.25 + sin(clock * 3.0) * 0.35, 1.0)
	response_label.text = ["A / FLOAT", "B / SPIN", "C / STRETCH"][response] if response >= 0 else "SPHERE / IDLE"

func _refresh() -> void:
	if status == null: return
	status.text = message
	var n := model.counts()
	count_label.text = "YOUR TAKES   A %d   B %d   C %d" % n
	var correct := 0
	var accepted := 0
	for t: Dictionary in model.tests:
		if t.correct: correct += 1
		if t.accepted: accepted += 1
	metrics.text = "%s / 6 -> 8 -> 3 / 83 parameters\n" % mode
	metrics.text += "Updates %d / loss %.3f" % [model.epoch, model.loss()] if model.epoch > 0 else "Teach 3 separate takes per pose, then TRAIN"
	metrics.text += "\nFresh tests: %d / %d correct; %d accepted" % [correct, model.tests.size(), accepted]
	for k in 3:
		var value := float(last_prediction.scores[k]) if not last_prediction.is_empty() else 0.0
		bars[k].scale.x = maxf(0.002, value)
		bars[k].position.x = -0.58 + value * 0.52
	for i in chart.size():
		chart[i].visible = i + 1 < model.history.size()
		if chart[i].visible:
			var scale_loss := maxf(0.001, float(model.history[0]))
			var a := Vector3(-0.56 + i*1.12/30.0, 1.72 + clampf(model.history[i]/scale_loss,0,1.5)*0.12,-0.45)
			var b := Vector3(-0.56 + (i+1)*1.12/30.0, 1.72 + clampf(model.history[i+1]/scale_loss,0,1.5)*0.12,-0.45)
			host._place_rod(chart[i], a, b, 0.004)

func _build() -> void:
	_box(Vector3(0,1.50,-0.5),Vector3(1.48,1.90,0.07),Color(0.025,0.027,0.046))
	_label("TEACH A SPHERE",Vector3(0,2.31,-0.45),38,Color.WHITE,0.002)
	_label("YOUR EXAMPLES / LOCAL LEARNING",Vector3(0,2.20,-0.45),18,COLORS[1],0.002)
	count_label = _label("",Vector3(0,2.08,-0.45),22,Color.WHITE,0.002)
	metrics = _label("",Vector3(0,1.56,-0.44),19,Color.WHITE,0.0019)
	status = _label("",Vector3(0,1.95,-0.44),21,Color.WHITE,0.0018)
	status.width = 690.0
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	response_label = _label("SPHERE / IDLE",Vector3(0,1.05,-0.44),24,COLORS[2],0.002)
	for k in 3:
		bars.append(_box(Vector3(0,0.96-k*0.065,-0.44),Vector3(1.04,0.025,0.025),COLORS[k]))
	score_label=_label("A / B / C  model scores",Vector3(0,0.74,-0.44),17,Color.WHITE,0.002)
	sphere_material = StandardMaterial3D.new()
	sphere_material.metallic = 0.65
	sphere_material.roughness = 0.18
	sphere = host._sphere(0.115,sphere_material,self)
	var band := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.117
	torus.outer_radius = 0.126
	torus.rings = 32
	torus.ring_segments = 6
	band.mesh = torus
	band.material_override = host._mat(Color.WHITE)
	sphere.add_child(band)
	for i in 30: chart.append(host._rod(host._mat(COLORS[2]),self))
	_build_pose_controls()

func _build_pose_controls() -> void:
	var commands := ["A","B","C","TEACH","TEST","LIVE","TRAIN","ALIGN","SAVE","LOAD","RESET","POSE","HEIGHT","PHRASE"]
	var rows: Array = []
	for names in [["A","B","C"],["TEACH","TEST","LIVE"],["TRAIN","ALIGN","SAVE","LOAD","RESET"],["POSE","HEIGHT","PHRASE"]]:
		var row: Array = []
		for word in names: row.append({"type":"button","label":word})
		rows.append(row)
	replace_controls(Rack.create_panel("POSE / CLASSIFIER", rows))
	for i in commands.size():
		var button := controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
		button.button_pressed.connect(func(_area): command(commands[i]))

func replace_controls(panel: Node3D) -> void:
	if is_instance_valid(controls):
		remove_child(controls)
		controls.queue_free()
	controls=panel
	controls.position = Vector3(0,0.87,0.52)
	controls.rotation_degrees.x = -30.0
	controls.scale = Vector3.ONE*1.7
	add_child(controls)

func _box(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = host._mat(color)
	item.position = at
	add_child(item)
	return item

func _label(words: String, at: Vector3, size: int, color: Color, pixels: float) -> Label3D:
	return host._label(words,at,size,color,pixels,self)
