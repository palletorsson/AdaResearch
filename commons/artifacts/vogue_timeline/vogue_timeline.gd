extends Node3D
## Vogue-inspired hand phrase inside Endless Museum. Original guide, not a
## reconstruction of ballroom technique. Session-local demonstration recording.
const Phrase := preload("res://commons/artifacts/vogue_timeline/dance_phrase.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const PINK := Color(1.0, 0.14, 0.57)
const CYAN := Color(0.12, 0.85, 1.0)
const INK := Color(0.018, 0.019, 0.036)
const GOLD := Color(1.0, 0.75, 0.32)
const PATH_SAMPLES := 128
const TRAIL_POINTS := 36
const LOOKAHEAD_BEATS := 8.0
const AUDIO_BEATS := 8.0
var phrase := Phrase.new()
var playing := false
var reach := 0.65
var facing := Basis.IDENTITY
var head: XRCamera3D
var left: XRController3D
var right: XRController3D
var audio: AudioStreamPlayer3D
var status: Label3D
var detail: Label3D
var guide: Node3D
var live: Node3D
var cards: Array[Node3D] = []
var beads: Array[MeshInstance3D] = []
var hand_space: Node3D
var path_root: Node3D
var trail_root: Node3D
var path_rods: Array[MeshInstance3D] = []
var path_start := 0.0
var trail_rods: Array[MeshInstance3D] = []
var hand_targets: Array[MeshInstance3D] = []
var direction_arrows: Array[MeshInstance3D] = []
var hand_labels: Array[Label3D] = []
var trails: Array = [[], []]
var controls: Node3D
var guide_clock := 0.0
var discover_clock := 0.0
var trace_clock := 0.0
var audio_clock := 0.0
var muted := false
var cue_flash := 0.0
var preview_only := true
var last_valid := false
var message := "Press PLAY facing the stage"
var learning_position := Vector3(-1.65, 0, 0.10)
var learning_yaw := 12.0
var separate_learning_bay := false

func _ready() -> void:
	add_to_group("vogue_timeline")
	facing = global_basis.orthonormalized()
	_build()
	_resolve_rig()
	var learning := Node3D.new()
	learning.set_script(preload("res://commons/artifacts/vogue_timeline/pose_learning_station.gd"))
	learning.name = "PoseLearningStation"
	learning.position = learning_position
	learning.rotation_degrees.y = learning_yaw
	add_child(learning)
	_dress_learning_bay()

func apply_grid_config(config: Dictionary) -> void:
	# A map can give the same learner a separate bay, without recreating its data.
	learning_position = Vector3(float(config.get("learning_x", learning_position.x)),
		float(config.get("learning_y", learning_position.y)), float(config.get("learning_z", learning_position.z)))
	learning_yaw = float(config.get("learning_yaw", learning_yaw))
	separate_learning_bay = str(config.get("learning_bay", "1" if separate_learning_bay else "0")) == "1"
	var station := get_node_or_null("PoseLearningStation") as Node3D
	if station != null:
		station.position = learning_position
		station.rotation_degrees.y = learning_yaw
		_dress_learning_bay()

func _dress_learning_bay() -> void:
	var station := get_node_or_null("PoseLearningStation") as Node3D
	if station == null: return
	var old := station.get_node_or_null("LearningBay")
	if old != null:
		station.remove_child(old)
		old.queue_free()
	if not separate_learning_bay: return
	var bay := Node3D.new()
	bay.name = "LearningBay"
	station.add_child(bay)
	# Flat visual inlay: the real map supplies the continuous collision floor.
	var inlay := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(4.0, 0.012, 4.8)
	inlay.mesh = slab
	inlay.position = Vector3(0.3, 0.007, 0.7)
	inlay.material_override = _mat(Color(0.08,0.10,0.13), false)
	bay.add_child(inlay)
	for x in [-1.68, 2.28]:
		var edge := _rod(_mat(GOLD), bay)
		_place_rod(edge, Vector3(x,0.018,-1.68), Vector3(x,0.018,3.08), 0.008)
	_label("TEACH / TEST / REVISE", Vector3(0.3,2.85,-0.65), 36, GOLD, 0.0025, bay)
	_label("One sphere. Your examples.", Vector3(0.3,2.68,-0.65), 23, Color.WHITE, 0.002, bay)

func _resolve_rig() -> void:
	for n in get_tree().root.find_children("*", "XRCamera3D", true, false):
		if n.is_inside_tree():
			head = n
			break
	for n in get_tree().root.find_children("*", "XRController3D", true, false):
		if n.tracker == &"left_hand": left = n
		if n.tracker == &"right_hand": right = n

func tracked() -> bool:
	if not is_instance_valid(head) or not is_instance_valid(left) or not is_instance_valid(right): return false
	var tracker := XRServer.get_tracker(&"head") as XRPositionalTracker
	if tracker == null: return false
	var pose := tracker.get_pose(&"default")
	return pose != null and pose.has_tracking_data and left.get_has_tracking_data() and right.get_has_tracking_data() and left.get_is_active() and right.get_is_active()

func _near() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(global_position) < 5.0

func _process(delta: float) -> void:
	discover_clock -= delta
	if discover_clock <= 0.0:
		discover_clock = 2.0
		_resolve_rig()
	guide_clock += delta * phrase.bpm / 60.0
	var valid := tracked() and _near()
	last_valid = valid
	if playing:
		if valid:
			var l := Phrase.feature(head.global_position, left.global_position, facing, reach)
			var r := Phrase.feature(head.global_position, right.global_position, facing, reach)
			submit_sample(delta, l, r, true)
		else:
			phrase.advance(delta, Vector3.ZERO, Vector3.ZERO, false)
			message = "Waiting for head + both hands / phrase paused"
		_sync_audio(valid)
	else:
		audio.stop()
	preview_only = not playing or not valid
	render_pose(guide_clock if preview_only else phrase.beat)
	for i in hand_targets.size():
		hand_targets[i].visible = playing and valid and not phrase.recording
		if hand_targets[i].visible:
			var target: Vector3 = phrase.target(maxf(0.0, phrase.beat))[i]
			hand_targets[i].global_transform = Transform3D(facing * Basis(Vector3.RIGHT, PI * 0.5), head.global_position + facing * (target * reach))
	_refresh_feedback(valid)
	cue_flash = maxf(0.0, cue_flash - delta)
	status.modulate = GOLD if cue_flash > 0.0 else Color.WHITE
	if playing and valid:
		if phrase.beat < 0.0:
			status.text = "READY  %d" % ceili(-phrase.beat)
		elif phrase.recording:
			status.text = "YOUR PHRASE  /  recording %d of %d" % [int(phrase.beat) + 1, int(Phrase.LENGTH)]
		else:
			status.text = "%s / %02d of %d\n%s" % [phrase.section_name(phrase.beat), int(fposmod(phrase.beat, Phrase.LENGTH)) + 1, int(Phrase.LENGTH), phrase.cue_name(phrase.beat)]
			message = "%d poses met  /  flow %d%%  /  %d BPM" % [phrase.hits, int(100.0 * phrase.flow_sum / maxf(0.01, phrase.flow_time)), int(phrase.bpm)]
	else:
		status.text = "GUIDE PREVIEW / no recognition" if not playing else "TRACKING PAUSED"
	detail.text = message + "\nReach %.2f m  /  tolerance %.2f m" % [reach, reach * phrase.tolerance]

func submit_sample(delta: float, l: Vector3, r: Vector3, valid: bool) -> void:
	phrase.advance(delta, l, r, valid)
	if not valid: return
	_draw_figure(live, l, r, false)
	trace_clock += delta
	if trace_clock >= 0.04:
		trace_clock = 0.0
		trails[0].append(l)
		trails[1].append(r)
		for trail in trails:
			if trail.size() > TRAIL_POINTS: trail.pop_front()
		_update_trails()
	if phrase.just_hit:
		cue_flash = 0.25
		for ctrl in [left, right]:
			if is_instance_valid(ctrl) and ctrl.get_has_tracking_data():
				ctrl.trigger_haptic_pulse("haptic", 0.0, 0.25, 0.035, 0.0)
	if phrase.just_recorded:
		_refresh_paths()
		message = "Your %d beats are kept / now dance them back" % int(Phrase.LENGTH)
		audio.stop()
		audio_clock = 0.0

func _refresh_feedback(valid: bool) -> void:
	var following := playing and valid and not phrase.recording and phrase.beat >= 0.0
	for hand in 2:
		var base := PINK if hand == 0 else CYAN
		var inside := following and phrase.hand_errors[hand] <= phrase.tolerance
		var material := hand_targets[hand].material_override as StandardMaterial3D
		material.albedo_color = base.lightened(0.72) if inside else base
		var state := "IN PLACE" if inside else "FOLLOW"
		if not playing: state = "PREVIEW"
		elif not valid: state = "PAUSED"
		elif phrase.beat < 0.0: state = "READY"
		elif phrase.recording: state = "RECORDING"
		hand_labels[hand].text = ("LEFT / " if hand == 0 else "RIGHT / ") + state

func command(which: String) -> void:
	match which:
		"PLAY":
			if playing:
				playing = false
				phrase.cancel_recording()
				message = "Paused / PLAY starts a new count-in"
			else:
				_begin(false)
		"RECORD": _begin(true)
		"MINE":
			if phrase.recorded.is_empty():
				message = "Record your %d beats first" % int(Phrase.LENGTH)
			else:
				phrase.use_recorded = true
				_begin(false)
		"GUIDE":
			phrase.use_recorded = false
			phrase.cancel_recording()
			_begin(false)
		"REACH": reach = 0.45 if reach > 0.80 else reach + 0.20
		"EASE": phrase.tolerance = 0.24 if phrase.tolerance > 0.45 else phrase.tolerance + 0.12
		"TEMPO":
			phrase.bpm = 96.0 if phrase.bpm >= 128.0 else phrase.bpm + 16.0
			audio.pitch_scale = phrase.bpm / 112.0
			# Restart count-in so beat and music stay together after a tempo change.
			phrase.cancel_recording()
			phrase.reset()
			audio.stop()
			audio_clock = 0.0
		"SOUND": muted = not muted
		"CLEAR":
			phrase.recorded.clear()
			phrase.use_recorded = false
			phrase.cancel_recording()
			playing = false
			trails = [[], []]
			_update_trails()
			message = "Your recording cleared / guide retained"
	_refresh_paths(maxf(0.0, guide_clock if preview_only else phrase.beat))

func _begin(record: bool) -> void:
	if not tracked():
		message = "Head + two tracked controllers needed / preview remains available"
		return
	# Fix yaw for the phrase: turning the head is not silently reinterpreted as hand motion.
	var forward := -head.global_basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.01:
		facing = Basis.looking_at(forward.normalized(), Vector3.UP)
	phrase.reset()
	if record: phrase.start_recording()
	else: phrase.cancel_recording()
	playing = true
	trails = [[], []]
	_update_trails()
	audio.stop()
	audio_clock = 0.0

func _sync_audio(valid: bool) -> void:
	if not valid:
		# A 3D player's start is deferred to the next physics frame. stop() also
		# cancels that pending start; stream_paused alone can miss it.
		audio.stop()
		return
	var expected := audio_phase(phrase.beat, phrase.bpm)
	if not audio.playing:
		audio.play(expected * audio.pitch_scale)
		audio_clock = 0.0
	audio.stream_paused = false
	audio.volume_db = -80.0 if muted else -13.0
	# Correct drift against the same eight-beat PCM loop, never score audio latency
	# as a tracking failure. Count-in begins at loop phase zero; dance starts at 4.
	var actual := audio.get_playback_position() / audio.pitch_scale
	if absf(actual - expected) > 0.12 and absf(actual - expected) < 7.5 * 60.0 / phrase.bpm:
		audio.seek(expected * audio.pitch_scale)

static func audio_phase(at: float, bpm: float) -> float:
	# The eight-beat PCM accompaniment repeats four times per dance phrase.
	return fposmod(at + 4.0, AUDIO_BEATS) * 60.0 / bpm

func _unhandled_key_input(event: InputEvent) -> void:
	if not _near() or not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: command("PLAY")
		KEY_R: command("RECORD")
		KEY_G: command("GUIDE")
		KEY_M: command("MINE")

func render_pose(at: float) -> void:
	var time := maxf(0.0, at)
	var goal := phrase.target(time)
	_draw_figure(guide, goal[0], goal[1], true)
	live.visible = not preview_only and not phrase.recording
	for i in cards.size():
		var future := ceilf(time / Phrase.CUE_BEATS) * Phrase.CUE_BEATS + float(i) * Phrase.CUE_BEATS
		var pair := phrase.target(future)
		_draw_figure(cards[i], pair[0], pair[1], true)
		cards[i].get_node("Caption").text = ("%d" % (int(future) % int(Phrase.LENGTH) + 1)) + " / " + phrase.cue_name(future)
	# The paths, moving beads and measured trails share the target rings' frame.
	# Keep x, y AND z: time travels along the curve, not across the floor.
	if not preview_only and is_instance_valid(head):
		hand_space.global_transform = Transform3D(facing.scaled(Vector3.ONE * reach), head.global_position)
	else:
		hand_space.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * reach), Vector3(0, 1.65, 0))
	path_root.visible = not phrase.recording
	trail_root.visible = not preview_only
	if path_root.visible:
		_refresh_paths(time)
	var pulse := 1.0 + 0.5 * pow(1.0 - fposmod(time, 1.0), 4.0)
	for hand in 2:
		for i in 8:
			# The leading bead travels continuously; smaller beads mark upcoming
			# integer beats. Meet each marker when the large bead reaches it.
			var marker_time := time if i == 0 else floorf(time) + float(i)
			beads[hand * 8 + i].position = phrase.target(marker_time)[hand]
			beads[hand * 8 + i].scale = Vector3.ONE * (pulse if i == 0 else 1.0)
		for i in 3:
			var at_arrow := floorf(time) + 1.5 + float(i) * 2.0
			var tip: Vector3 = phrase.target(at_arrow)[hand]
			var tangent: Vector3 = phrase.target(at_arrow + 0.04)[hand] - phrase.target(at_arrow - 0.04)[hand]
			var arrow := direction_arrows[hand * 3 + i]
			arrow.visible = tangent.length_squared() > 0.00000001
			if arrow.visible:
				arrow.position = tip
				arrow.basis = Basis(Quaternion(Vector3.UP, tangent.normalized()))

func _build() -> void:
	_box(Vector3(0, 0.012, -0.7), Vector3(5.2, 0.024, 4.7), _mat(INK, false))
	_box(Vector3(0, 1.5, -3.0), Vector3(5.2, 2.95, 0.12), _mat(INK, false))
	for x in [-2.58, 2.58]:
		_box(Vector3(x, 1.45, -2.9), Vector3(0.018, 2.8, 0.025), _mat(PINK if x < 0 else CYAN))
		_box(Vector3(x, 0.035, -0.7), Vector3(0.024, 0.025, 4.6), _mat(PINK if x < 0 else CYAN))
	_label("VOGUE / A PHRASE OF YOUR OWN", Vector3(0, 2.72, -2.9), 70, Color.WHITE, 0.0022)
	_label("32 BEATS  /  FRAME  /  SWEEP  /  WEAVE  /  RETURN", Vector3(0, 2.48, -2.9), 27, GOLD, 0.0025)
	_label("ENDLESS MUSEUM", Vector3(0, 0.31, -2.9), 27, Color.WHITE, 0.002)
	_label("always another room", Vector3(0, 0.20, -2.9), 19, Color(0.65,0.67,0.75), 0.002)
	guide = _figure(Vector3(-1.35, 1.85, -2.72), 0.95)
	live = _figure(Vector3(-1.35, 1.85, -2.58), 0.95)
	for i in 4:
		var p := Vector3(0.40 + float(i % 2) * 1.2, 2.02 - float(i / 2) * 0.92, -2.72)
		var figure := _figure(p, 0.45)
		cards.append(figure)
		var caption := _label("", Vector3(0, -1.18, 0.04), 22, GOLD, 0.003, figure)
		caption.name = "Caption"
	status = _label("GUIDE PREVIEW", Vector3(-1.30, 0.73, -2.54), 26, Color.WHITE, 0.003)
	detail = _label("", Vector3(0, 0.49, -2.54), 22, Color(0.75,0.80,0.86), 0.0025)
	hand_space = Node3D.new()
	hand_space.name = "AirborneHandSpace"
	add_child(hand_space)
	path_root = Node3D.new()
	path_root.name = "ReferencePaths"
	hand_space.add_child(path_root)
	trail_root = Node3D.new()
	trail_root.name = "MeasuredTrails"
	hand_space.add_child(trail_root)
	for hand in 2:
		var color := PINK if hand == 0 else CYAN
		var path_material := _mat(color.darkened(0.35))
		var trail_material := _mat(color.lightened(0.25))
		for i in PATH_SAMPLES:
			path_rods.append(_rod(path_material, path_root))
		for i in TRAIL_POINTS - 1:
			var line := _rod(trail_material, trail_root)
			line.visible = false
			trail_rods.append(line)
		for i in 8:
			var bead := _sphere(0.042 if i == 0 else 0.022, _mat(color), path_root)
			beads.append(bead)
		for i in 3:
			var arrow := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.032
			cone.height = 0.10
			cone.radial_segments = 8
			arrow.mesh = cone
			arrow.material_override = _mat(color.lightened(0.2))
			path_root.add_child(arrow)
			direction_arrows.append(arrow)
	_refresh_paths()
	controls = Rack.create_panel("DANCE", [[{"type":"button","label":"PLAY"},{"type":"button","label":"RECORD"},{"type":"button","label":"MINE"},{"type":"button","label":"GUIDE"}], [{"type":"button","label":"REACH"},{"type":"button","label":"EASE"},{"type":"button","label":"TEMPO"},{"type":"button","label":"SOUND"},{"type":"button","label":"CLEAR"}]])
	controls.name = "DanceControls"
	controls.position = Vector3(0, 1.00, 1.15)
	controls.rotation_degrees.x = -30.0
	controls.scale = Vector3.ONE * 2.0
	add_child(controls)
	var commands := ["PLAY","RECORD","MINE","GUIDE","REACH","EASE","TEMPO","SOUND","CLEAR"]
	for i in commands.size():
		var area := controls.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
		area.button_pressed.connect(func(_button): command(commands[i]))
	_box(Vector3(0,1.32,1.08),Vector3(1.36,0.16,0.025),_mat(INK))
	for hand in 2:
		var words := "LEFT / PREVIEW" if hand == 0 else "RIGHT / PREVIEW"
		hand_labels.append(_label(words,Vector3(-0.34 if hand == 0 else 0.34,1.32,1.10),22,PINK if hand == 0 else CYAN,0.0018))
	_box(Vector3(1.75,0.9,0.6),Vector3(1.15,0.40,0.025),_mat(INK))
	_label("Follow the arrows.\nBright ring: hand in place.\nRECORD your own 32 beats.", Vector3(1.75,0.9,0.63), 20, Color.WHITE, 0.0018)
	for color in [PINK,CYAN]:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.070
		mesh.outer_radius = 0.082
		mesh.rings = 24
		mesh.ring_segments = 6
		ring.mesh = mesh
		ring.material_override = _mat(color)
		ring.visible = false
		add_child(ring)
		hand_targets.append(ring)
	audio = AudioStreamPlayer3D.new()
	var wav := AudioStreamWAV.load_from_file("res://commons/artifacts/vogue_timeline/phrase_112.wav")
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = wav.data.size() / 2
	audio.stream = wav
	audio.max_distance = 8.0
	audio.position = Vector3(0,1.3,-1.0)
	add_child(audio)

func _refresh_paths(at: float = 0.0) -> void:
	path_start = at
	var a := phrase.target(at)
	for i in PATH_SAMPLES:
		var b := phrase.target(at + float(i + 1) * LOOKAHEAD_BEATS / PATH_SAMPLES)
		for hand in 2:
			_place_rod(path_rods[hand * PATH_SAMPLES + i], a[hand], b[hand], 0.009)
		a = b

func _figure(at: Vector3, size: float) -> Node3D:
	var f := Node3D.new()
	f.position = at
	f.scale = Vector3.ONE * size
	add_child(f)
	var head_mesh := _sphere(0.105, _mat(Color(0.85,0.90,0.95)), f)
	head_mesh.name = "Head"
	for i in 9:
		var rod := _rod(_mat(PINK if i < 2 else (CYAN if i < 4 else Color(0.33,0.36,0.46))), f)
		rod.name = "Limb%d" % i
	for i in 2:
		var ball := _sphere(0.072, _mat(PINK if i == 0 else CYAN), f)
		ball.name = "Hand%d" % i
	return f

func _draw_figure(f: Node3D, l: Vector3, r: Vector3, skeleton: bool) -> void:
	# A front-facing diagram: x remains screen-left/right. Depth appears as a
	# shallow relief; the recognizer still uses all three measured coordinates.
	var lh := Vector3(l.x, l.y, -l.z * 0.25)
	var rh := Vector3(r.x, r.y, -r.z * 0.25)
	var ls := Vector3(-0.22,-0.22,0)
	var rs := Vector3(0.22,-0.22,0)
	var le := ls.lerp(lh,0.55) + Vector3(-0.08,-0.12,0)
	var re := rs.lerp(rh,0.55) + Vector3(0.08,-0.12,0)
	var hips := Vector3(0,-0.65,0)
	var ends := [[ls,le],[le,lh],[rs,re],[re,rh],[ls,rs],[Vector3(0,-0.22,0),hips],[hips,Vector3(-0.18,-1.03,0)],[hips,Vector3(0.18,-1.03,0)],[Vector3(0,-0.1,0),Vector3(0,-0.22,0)]]
	for i in ends.size():
		var rod: MeshInstance3D = f.get_node("Limb%d" % i)
		rod.visible = skeleton
		_place_rod(rod, ends[i][0], ends[i][1], 0.016)
	f.get_node("Head").visible = skeleton
	f.get_node("Hand0").position = lh
	f.get_node("Hand1").position = rh

func _update_trails() -> void:
	for hand in 2:
		for i in TRAIL_POINTS - 1:
			var line := trail_rods[hand * (TRAIL_POINTS - 1) + i]
			line.visible = i + 1 < trails[hand].size()
			if line.visible:
				_place_rod(line, trails[hand][i], trails[hand][i + 1], 0.013)

func _mat(color: Color, glow: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.26
	if glow: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box(at: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)

func _sphere(radius: float, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _rod(material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 8
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _place_rod(rod: MeshInstance3D, a: Vector3, b: Vector3, radius: float) -> void:
	var offset := b - a
	rod.position = (a+b) * 0.5
	# A held pose has no segment. Avoid a zero-direction quaternion.
	if offset.length_squared() < 0.00000001:
		rod.basis = Basis.IDENTITY
		rod.scale = Vector3.ZERO
		return
	rod.basis = Basis(Quaternion(Vector3.UP, offset.normalized()))
	rod.scale = Vector3(radius, maxf(offset.length(),0.001), radius)

func _label(words: String, at: Vector3, size: int, color: Color, pixels: float, parent: Node3D = self) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = pixels
	label.modulate = color
	label.position = at
	label.no_depth_test = false
	label.outline_size = 2
	parent.add_child(label)
	return label
