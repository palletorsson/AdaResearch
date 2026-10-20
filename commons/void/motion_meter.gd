# motion_meter.gd
# Bounded, opt-in telemetry for the same rig in a quiet room and the tower.
extends Node

var game: Node3D
var label: Label3D
var location := "room"
var samples: Array[Dictionary] = []
var frame_ms: Array[float] = []
var elapsed := 0.0
var startup := 0.0
var physics_count := 0
var stalled := 0
var moving := 0
var previous_position := Vector3.ZERO
var previous_usec := 0
var latest: Dictionary = {}
var report_directory := "user://"
var raw_min := Vector2(INF,INF)
var raw_max := Vector2(-INF,-INF)
var raw_right_min := Vector2(INF,INF)
var raw_right_max := Vector2(-INF,-INF)
var contacts: Dictionary = {}
var last_obstacle := "none"
var obstacle_until_msec := 0

func configure(host: Node3D, where: String, display: Label3D = null) -> void:
	game = host
	location = where
	process_physics_priority = 200
	previous_position = game.body.global_position
	previous_usec = Time.get_ticks_usec()
	label = display
	if label == null:
		label = Label3D.new()
		label.position = Vector3(0, 0.18, -0.85)
		label.pixel_size = 0.00045
		label.font_size = 24
		label.no_depth_test = true
		game.camera.add_child(label)
	label.text = "MOVEMENT TEST / settling..."

func _physics_process(_delta: float) -> void:
	if game == null: return
	physics_count += 1
	var raw := raw_stick()
	raw_min = raw_min.min(raw)
	raw_max = raw_max.max(raw)
	var raw_right := raw_stick("RightHand")
	raw_right_min = raw_right_min.min(raw_right)
	raw_right_max = raw_right_max.max(raw_right)
	var input := (adjusted_stick()+Vector2(0,adjusted_stick("RightHand").y)).limit_length(1.0)
	var step: Vector3 = game.body.global_position - previous_position
	# Only report a stopped step when a substantial input should be walking.
	# Contact with a wall also counts; this is evidence, not a diagnosis.
	if input.length() > 0.25 and game.body.is_on_floor():
		moving += 1
		if Vector2(step.x, step.z).length() < 0.0001: stalled += 1
	previous_position = game.body.global_position
	_record_contacts(input)

func _record_contacts(input: Vector2) -> void:
	# Observe the body's existing collision results; do not change locomotion.
	var player := game.body as CharacterBody3D
	for index in range(player.get_slide_collision_count()):
		var collision := player.get_slide_collision(index)
		for hit in range(collision.get_collision_count()):
			var collider := collision.get_collider(hit) as Node3D
			if not is_instance_valid(collider): continue
			var normal := collision.get_normal(hit)
			var key := str(collider.get_path())
			if not contacts.has(key) and contacts.size() >= 32: continue
			var entry: Dictionary = contacts.get(key, {"path":key,"hits":0})
			entry["hits"] += 1
			entry["visible"] = collider.is_visible_in_tree()
			entry["normal"] = [normal.x,normal.y,normal.z]
			entry["layer"] = collider.collision_layer if collider is CollisionObject3D else 0
			contacts[key] = entry
			# Ignore floor support. Retain a wall/edge contact briefly so it can be read.
			if input.length()>0.25 and normal.y<0.65:
				last_obstacle = str(collider.name) + (" (hidden)" if not entry.visible else "")
				obstacle_until_msec = Time.get_ticks_msec()+2500

func raw_stick(hand: String = "LeftHand") -> Vector2:
	if not game.vr: return Vector2.ZERO
	return game.get_node("XROrigin3D/"+hand).get_vector2("primary")

func adjusted_stick(hand: String = "LeftHand") -> Vector2:
	if not game.vr: return Vector2.ZERO
	return XRToolsUserSettings.get_adjusted_vector2(game.get_node("XROrigin3D/"+hand), "primary")

func _process(delta: float) -> void:
	if game == null: return
	var now := Time.get_ticks_usec()
	var wall_ms := float(now - previous_usec) / 1000.0
	previous_usec = now
	startup += delta
	if startup < 3.0: return # Loading is reported separately by tower streaming.
	frame_ms.append(wall_ms)
	if frame_ms.size() > 600: frame_ms.pop_front()
	elapsed += delta
	if elapsed < 1.0: return
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var raw := raw_stick()
	var adjusted := adjusted_stick()
	var raw_right := raw_stick("RightHand")
	var adjusted_right := adjusted_stick("RightHand")
	var interface := XRServer.primary_interface
	var hz: float = interface.get_display_refresh_rate() if interface != null and interface.is_initialized() else 0.0
	latest = {"location": location, "headset_hz": hz, "physics_hz": Engine.physics_ticks_per_second,
		"frame_p95_ms": sorted[int((sorted.size()-1)*0.95)], "frame_max_ms": sorted.back(),
		"raw_left": [raw.x,raw.y], "adjusted_left": [adjusted.x,adjusted.y],
		"raw_right": [raw_right.x,raw_right.y], "adjusted_right": [adjusted_right.x,adjusted_right.y],
		"raw_right_min": [raw_right_min.x,raw_right_min.y], "raw_right_max": [raw_right_max.x,raw_right_max.y],
		"raw_min": [raw_min.x,raw_min.y], "raw_max": [raw_max.x,raw_max.y],
		"deadzone": [XRToolsUserSettings.x_axis_dead_zone, XRToolsUserSettings.y_axis_dead_zone],
		"stick_rest_offsets": XRToolsUserSettings.stick_rest_offsets.duplicate(),
		"snap_turn_deadzone": XRTools.get_snap_turning_deadzone(),
		"speed_m_s": Vector2(game.body.velocity.x,game.body.velocity.z).length(),
		"body_position": [game.body.global_position.x,game.body.global_position.y,game.body.global_position.z],
		"contacts": contacts.values().duplicate(true),
		"last_obstacle": last_obstacle if Time.get_ticks_msec()<obstacle_until_msec else "none",
		"physics_steps": physics_count, "walking_steps": moving, "stopped_walking_steps": stalled,
		"process_cpu_ms": Performance.get_monitor(Performance.TIME_PROCESS)*1000,
		"physics_cpu_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000}
	if game.floor_stream != null:
		latest["pending_artifacts"] = game.building.content.pending.size()
		latest["largest_artifact_build_ms"] = game.building.content.max_build_ms
	samples.append(latest.duplicate(true))
	if samples.size() > 300: samples.pop_front()
	label.text = "%s / STICKS: RAW -> ADJUSTED\nL %+.2f %+.2f -> %+.2f %+.2f\nR %+.2f %+.2f -> %+.2f %+.2f\nDeadzone X %.2f / Y %.2f  |  %.2f m/s\nphysics %d Hz  headset %.0f Hz  p95 %.1f ms\nContact: %s\nX: menu   B: reset   Y: %s" % [location.to_upper(),raw.x,raw.y,adjusted.x,adjusted.y,raw_right.x,raw_right.y,adjusted_right.x,adjusted_right.y,latest.deadzone[0],latest.deadzone[1],latest.speed_m_s,Engine.physics_ticks_per_second,hz,latest.frame_p95_ms,latest.last_obstacle,"compare tower" if location=="room" else "roof"]
	elapsed = 0
	physics_count = 0
	moving = 0
	stalled = 0
	raw_min = Vector2(INF,INF)
	raw_max = Vector2(-INF,-INF)
	raw_right_min = Vector2(INF,INF)
	raw_right_max = Vector2(-INF,-INF)
	contacts.clear()

func save_report() -> void:
	if samples.is_empty(): return
	var file := FileAccess.open(report_directory.path_join("void-motion-%s.json" % location), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope":"Engine frames, both sticks and movement contacts; not compositor or headset comfort measurements", "samples":samples}, "\t"))

func _exit_tree() -> void:
	save_report()
