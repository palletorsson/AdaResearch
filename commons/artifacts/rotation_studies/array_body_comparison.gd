extends Node3D
## Two widths receive identical forward input on the actual collision geometry.
## This is a bounded physical trial, not a navigation agent or a walkability oracle.
signal pass_finished(width_id: String, observations: Array)
signal comparison_finished(observations: Dictionary)

const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const WIDTHS := [0.44, 1.20]
const WIDTH_IDS := ["NARROW", "WIDE"]
const COLORS := [Color(0.08, 0.78, 0.94), Color(0.96, 0.26, 0.56)]
const HEIGHT := 1.6
const SPEED := 2.0
const GRAVITY := 9.8
const START := Vector3(-1, 0.02, -1.4)
const STALL_SECONDS := 1.0
const SETTLE_SECONDS := 0.3
const HOLD_SECONDS := 7.0

var subject: Node3D
var walkers: Array[Dictionary] = []
var readouts: Array[Label3D] = []
var marks: Array[Node3D] = []
var panel_text: Label3D
var results: Dictionary = {}
var pass_index := -1
var phase := "waiting"
var timer := 2.0
var elapsed := 0.0
var auto_repeat := true
var _restart_requested := false
var _readout_time := 0.0


func setup(array: Node3D) -> void:
	subject = array
	for band: Dictionary in subject.bands:
		var readout := Parts.label(band.node, "", Vector3(0, 0.62, -2.6), 22)
		readout.name = "BodyResults"
		readout.pixel_size = 0.0045
		readouts.append(readout)
	_build_panel()
	_update_readouts()


func restart() -> void:
	# Buttons can fire during a physics callback; mutation waits for our next tick.
	_restart_requested = true


func _physics_process(delta: float) -> void:
	if subject == null: return
	if _restart_requested:
		_restart_requested = false
		_clear_walkers()
		_clear_marks()
		results.clear()
		pass_index = -1
		phase = "waiting"
		timer = 0.35
	if phase == "waiting" or phase == "hold":
		timer -= delta
		if timer <= 0:
			if phase == "waiting": _begin_pass(0)
			elif pass_index == 0: _begin_pass(1)
			elif auto_repeat:
				results.clear()
				_clear_marks()
				_begin_pass(0)
			else: phase = "complete"
	elif phase == "running":
		elapsed += delta
		var all_done := true
		for trial: Dictionary in walkers:
			if trial.done: continue
			_step_trial(trial, delta)
			all_done = all_done and bool(trial.done)
		if all_done:
			var rows: Array = []
			for trial: Dictionary in walkers: rows.append(trial.result)
			results[WIDTH_IDS[pass_index]] = rows
			pass_finished.emit(WIDTH_IDS[pass_index], rows.duplicate(true))
			phase = "hold"
			timer = HOLD_SECONDS
			if pass_index == 1: comparison_finished.emit(results.duplicate(true))
	_readout_time += delta
	if _readout_time >= 0.1:
		_readout_time = 0.0
		_update_readouts()


func _begin_pass(index: int) -> void:
	_clear_walkers()
	pass_index = index
	elapsed = 0.0
	phase = "running"
	var target_distance: float = subject.rows * subject.SPACING + 2.0
	var ignored_bodies: Array[Node] = []
	for other in get_tree().root.find_children("*", "CharacterBody3D", true, false):
		if not other.is_queued_for_deletion() and (other.collision_layer & 1) != 0:
			ignored_bodies.append(other)
	for band: Dictionary in subject.bands:
		var body := CharacterBody3D.new()
		body.name = WIDTH_IDS[index] + "_" + str(band.id)
		# Layer zero makes the visible witnesses ghosts to every other mover.
		body.collision_layer = 0
		body.collision_mask = 1
		body.floor_snap_length = 0.15
		body.floor_max_angle = deg_to_rad(45.0)
		var shape := CapsuleShape3D.new()
		shape.radius = WIDTHS[index] / 2.0
		shape.height = HEIGHT
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position.y = HEIGHT / 2.0
		body.add_child(collider)
		var visible_body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = shape.radius
		capsule.height = HEIGHT
		capsule.radial_segments = 12
		capsule.rings = 4
		visible_body.mesh = capsule
		visible_body.position.y = HEIGHT / 2.0
		var material := StandardMaterial3D.new()
		material.albedo_color = COLORS[index]
		material.roughness = 0.5
		material.emission_enabled = true
		material.emission = COLORS[index]
		material.emission_energy_multiplier = 0.18
		visible_body.material_override = material
		body.add_child(visible_body)
		add_child(body)
		body.global_position = band.node.to_global(START)
		# Desktop walkers may share layer one with the static world. Ignore them,
		# as well as XR bodies, without excluding the actual cube collisions.
		for other in ignored_bodies: body.add_collision_exception_with(other)
		var direction: Vector3 = (band.node.global_basis * Vector3.BACK).normalized()
		walkers.append({"body":body, "band":band, "start":body.global_position,
			"direction":direction, "distance":target_distance, "previous":0.0,
			"stalled":0.0, "lowest":body.global_position.y, "done":false, "result":{}})


func _step_trial(trial: Dictionary, delta: float) -> void:
	var body: CharacterBody3D = trial.body
	# No jump, steering, or step assistance. Sliding comes from the same solver.
	var forward: Vector3 = trial.direction * (SPEED if elapsed > SETTLE_SECONDS else 0.0)
	body.velocity = forward + Vector3.UP * (body.velocity.y - GRAVITY * delta)
	body.move_and_slide()
	var progress: float = (body.global_position - trial.start).dot(trial.direction)
	trial.lowest = minf(float(trial.lowest), body.global_position.y)
	if elapsed <= SETTLE_SECONDS: return
	trial.stalled = float(trial.stalled) + delta if progress - float(trial.previous) < 0.001 else 0.0
	trial.previous = progress
	var reason := ""
	if progress >= float(trial.distance): reason = "ARRIVED"
	elif body.global_position.y < trial.start.y - 3.0: reason = "FELL"
	elif float(trial.stalled) >= STALL_SECONDS: reason = "BLOCKED"
	elif elapsed > float(trial.distance) / SPEED * 3.0 + SETTLE_SECONDS: reason = "TIME LIMIT"
	if reason.is_empty(): return
	trial.done = true
	body.velocity = Vector3.ZERO
	trial.result = {"band":str(trial.band.id), "width":WIDTHS[pass_index],
		"reason":reason, "travel_m":progress, "lowest_y":trial.lowest,
		"height_m":HEIGHT, "speed_m_s":SPEED,
		"position":[body.global_position.x, body.global_position.y, body.global_position.z],
		"elapsed_s":elapsed, "forward_input":true,
		"lateral_m":absf((body.global_position - trial.start).dot(trial.band.node.global_basis.x.normalized()))}
	# A ring retains the first body's endpoint while the wider body tries.
	var mark := MeshInstance3D.new()
	mark.name = "Endpoint_" + WIDTH_IDS[pass_index] + "_" + str(trial.band.id)
	var torus := TorusMesh.new()
	torus.inner_radius = WIDTHS[pass_index] / 2.0 - 0.025
	torus.outer_radius = WIDTHS[pass_index] / 2.0 + 0.025
	torus.rings = 24
	torus.ring_segments = 6
	mark.mesh = torus
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLORS[pass_index]
	mark.material_override = material
	add_child(mark)
	mark.global_position = body.global_position + Vector3.UP * 0.055
	marks.append(mark)


func _clear_walkers() -> void:
	for trial: Dictionary in walkers:
		trial.body.queue_free()
	walkers.clear()


func _clear_marks() -> void:
	for mark in marks: mark.queue_free()
	marks.clear()


func _update_readouts() -> void:
	var status := "NEXT: NARROW"
	if pass_index >= 0:
		status = "%s %.2f m / %s" % [WIDTH_IDS[pass_index], WIDTHS[pass_index], "MOVING" if phase == "running" else "RESULT"]
	panel_text.text = "SAME FORWARD INPUT / TWO WIDTHS\n" + status
	for i in range(readouts.size()):
		var lines: Array[String] = []
		for width_id in WIDTH_IDS:
			if results.has(width_id):
				var record: Dictionary = results[width_id][i]
				lines.append("%s: %s %.1f m / SIDE %.1f m" % [width_id, record.reason, record.travel_m, record.lateral_m])
		if lines.is_empty(): lines.append("0.44 m then 1.20 m / same start")
		readouts[i].text = "\n".join(lines)


func _build_panel() -> void:
	# Central still aisle, outside all four trials and the long side bypasses.
	Parts.box(self, "StudyStand", Vector3(0.55, 0.95, 0.28), Vector3(0, 0.475, -0.25), Color("34404a"))
	var panel := Node3D.new()
	panel.name = "ComparisonPanel"
	panel.position = Vector3(0, 1.1, -0.25)
	panel.rotation_degrees.y = 180
	add_child(panel)
	Parts.box(panel, "Casing", Vector3(1.45, 0.36, 0.06), Vector3.ZERO, Color("172730"), false)
	panel_text = Label3D.new()
	panel_text.position = Vector3(-0.05, 0.065, 0.04)
	panel_text.pixel_size = 0.0013
	panel_text.font_size = 27
	panel_text.outline_size = 0
	panel.add_child(panel_text)
	var button: Node3D = BUTTON.instantiate()
	button.name = "Replay"
	button.position = Vector3(0.56, -0.075, 0.04)
	button.pressed.connect(restart)
	panel.add_child(button)
	var caption := Label3D.new()
	caption.text = "REPLAY   /   no jump, same gravity, 2 m/s"
	caption.position = Vector3(-0.04, -0.075, 0.04)
	caption.pixel_size = 0.0012
	caption.font_size = 24
	caption.outline_size = 0
	panel.add_child(caption)
