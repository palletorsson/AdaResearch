extends SceneTree
## Regression probe using the actual XRTools body and real physics ticks.
## Run headless with --xr-mode off --audio-driver Dummy --script this file.
## This verifies rig/platform motion, not tracked-headset comfort or controller input.

const CUBE_PATH := "res://commons/scenes/mapobjects/transport_cube.tscn"
const BODY_PATH := "res://addons/godot-xr-tools/player/player_body.tscn"
const REPORT_PATH := "res://ada_run/transport-cube-vr-checks.json"
const POSITION_TOLERANCE := 0.035

class DesktopWalker extends CharacterBody3D:
	func _physics_process(delta: float) -> void:
		velocity.y -= 9.8 * delta
		move_and_slide()

var checks: Array = []
var cases: Array = []
var failures: Array[String] = []
var cube_scene: PackedScene
var body_scene: PackedScene


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name": name, "passed": passed, "detail": detail})
	if not passed:
		failures.append(name)
		push_error("TRANSPORT VR CHECK: " + name + " " + str(detail))


func _tick() -> void:
	await physics_frame
	await process_frame


func _xyz(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _spawn(direction: Vector3, distance: float, offset := Vector3.ZERO,
		yaw := 0.0, turn := 0.0, desktop := false) -> Dictionary:
	var fixture := Node3D.new()
	fixture.name = "TransportFixture"
	root.add_child(fixture)
	var cube = cube_scene.instantiate()
	cube.position = Vector3(12.0, 5.0, 160.0)
	cube.move_direction = direction
	cube.move_distance = distance
	cube.move_speed = 2.0
	cube.start_delay = 0.08
	cube.return_delay = 0.2
	cube.ride_rotation_degrees = turn
	# Board through the real handler after settling, without an early Area signal.
	cube.get_node("CubeBaseStaticBody3D/DetectionArea").monitoring = false
	fixture.add_child(cube)
	var feet: Vector3 = cube.global_position + Vector3(0.0, 0.505, 0.0)
	var rig: Node3D
	var eye: Camera3D
	var body: CharacterBody3D
	if desktop:
		var walker := DesktopWalker.new()
		walker.name = "Walker"
		walker.add_to_group("em_walker")
		walker.collision_layer = 1
		walker.collision_mask = 1
		walker.position = feet
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.2
		capsule.height = 1.8
		shape.shape = capsule
		shape.position.y = 0.9
		walker.add_child(shape)
		eye = Camera3D.new()
		eye.position = Vector3(0.0, 1.7, 0.0)
		walker.add_child(eye)
		fixture.add_child(walker)
		body = walker
		rig = walker
	else:
		var origin := XROrigin3D.new()
		origin.name = "XROrigin3D"
		origin.rotation.y = yaw
		origin.position = feet - origin.basis * Vector3(offset.x, 0.0, offset.z)
		var xr_eye := XRCamera3D.new()
		# XRHelpers recognizes the conventional Camera name without scene ownership.
		xr_eye.name = "Camera"
		xr_eye.position = Vector3(offset.x, 1.7, offset.z)
		origin.add_child(xr_eye)
		body = body_scene.instantiate()
		body.set("player_calibrate_height", false)
		body.set("eye_forward_offset", 0.0)
		origin.add_child(body)
		fixture.add_child(origin)
		rig = origin
		eye = xr_eye
	for i in 45:
		await _tick()
	return {"fixture": fixture, "cube": cube, "rig": rig, "eye": eye,
		"body": body, "desktop": desktop}


func _dispose(state: Dictionary) -> void:
	state.fixture.queue_free()
	await _tick()
	await _tick()


func _ride(name: String, direction: Vector3, distance := 1.2,
		offset := Vector3.ZERO, yaw := 0.0, turn := 0.0, desktop := false) -> void:
	var state := await _spawn(direction, distance, offset, yaw, turn, desktop)
	var cube = state.cube
	var body: CharacterBody3D = state.body
	var eye: Camera3D = state.eye
	var cube_start: Transform3D = cube.global_transform
	var body_start := body.global_position
	var eye_start := eye.global_transform
	var local_eye := eye.transform
	_check(name + ": starts supported", absf(body_start.y - cube_start.origin.y - 0.5) < 0.04,
		_xyz(body_start - cube_start.origin))
	cube._on_detection_area_body_entered(body)
	_check(name + ": boards actual body", cube.carried_player == body)
	var rows: Array = []
	var outbound := false
	var returned := false
	var max_body_error := 0.0
	var max_eye_error := 0.0
	var max_eye_height_error := 0.0
	var max_local_eye_error := 0.0
	var max_step_excess := 0.0
	var max_eye_step_excess := 0.0
	var previous_cube: Vector3 = cube.global_position
	var previous_eye := eye.global_position
	var previous_tick := Engine.get_physics_frames()
	for i in 400:
		await _tick()
		var rigid_delta: Transform3D = cube.global_transform * cube_start.affine_inverse()
		var expected_body: Vector3 = rigid_delta * body_start
		var expected_eye: Vector3 = rigid_delta * eye_start.origin
		max_body_error = maxf(max_body_error, body.global_position.distance_to(expected_body))
		max_eye_error = maxf(max_eye_error, eye.global_position.distance_to(expected_eye))
		max_eye_height_error = maxf(max_eye_height_error,
			absf((eye.global_position.y - body.global_position.y) - (eye_start.origin.y - body_start.y)))
		max_local_eye_error = maxf(max_local_eye_error, eye.position.distance_to(local_eye.origin))
		var tick := Engine.get_physics_frames()
		var allowed_step: float = cube.move_speed * float(tick - previous_tick) / float(Engine.physics_ticks_per_second)
		max_step_excess = maxf(max_step_excess, cube.global_position.distance_to(previous_cube) - allowed_step)
		max_eye_step_excess = maxf(max_eye_step_excess, eye.global_position.distance_to(previous_eye) - allowed_step)
		previous_cube = cube.global_position
		previous_eye = eye.global_position
		previous_tick = tick
		rows.append({"tick": tick, "cube": _xyz(cube.global_position),
			"body": _xyz(body.global_position), "eye": _xyz(eye.global_position),
			"velocity": _xyz(body.velocity),
			"ground_velocity": _xyz(body.get("ground_velocity")) if not desktop else null,
			"eye_height_m": eye.global_position.y - body.global_position.y,
			"body_error_m": body.global_position.distance_to(expected_body),
			"eye_error_m": eye.global_position.distance_to(expected_eye),
			"carried": cube.carried_player == body})
		if cube.global_position.distance_to(cube.target_position) < 0.01 and not cube.is_moving:
			outbound = true
		if outbound and cube.global_position.distance_to(cube.initial_position) < 0.01 and not cube.is_moving:
			returned = true
			break
	_check(name + ": reaches destination", outbound)
	_check(name + ": returns to start", returned)
	_check(name + ": body follows exactly once", max_body_error <= POSITION_TOLERANCE, max_body_error)
	_check(name + ": eye follows exactly once", max_eye_error <= POSITION_TOLERANCE, max_eye_error)
	_check(name + ": keeps eye height", max_eye_height_error <= 0.015, max_eye_height_error)
	_check(name + ": keeps tracked local pose", max_local_eye_error <= 0.00001, max_local_eye_error)
	_check(name + ": no cube jump", max_step_excess < 0.012, max_step_excess)
	# Turning adds an arc around the platform pivot; translation-only rides have
	# a direct speed bound that catches an instantaneous eye/rig relocation.
	if is_zero_approx(turn):
		_check(name + ": no eye jump", max_eye_step_excess < 0.012, max_eye_step_excess)
	_check(name + ": stays aboard", cube.carried_player == body)
	cases.append({"name": name, "direction": _xyz(direction), "distance": distance,
		"roomscale_offset": _xyz(offset), "yaw": yaw, "turn_degrees": turn,
		"desktop": desktop, "rows": rows})
	await _dispose(state)


func _natural_boarding() -> void:
	var state := await _spawn(Vector3.RIGHT, 4.0)
	var cube = state.cube
	var body = state.body
	var eye: Camera3D = state.eye
	var area: Area3D = cube.get_node("CubeBaseStaticBody3D/DetectionArea")
	var start: Vector3 = cube.global_position
	var eye_start := eye.global_position
	var saw_area_contact := false
	var boarded := false
	_check("natural boarding: actual XR layer", body.collision_layer == 524288, body.collision_layer)
	# Physics discovers the existing overlap. Do not invoke the boarding handler.
	area.monitoring = true
	for i in 25:
		await _tick()
		saw_area_contact = saw_area_contact or area.overlaps_body(body)
		boarded = boarded or cube.carried_player == body
	_check("natural boarding: Area detects XR body", saw_area_contact)
	_check("natural boarding: boards without manual callback", boarded and cube.carried_player == body)
	_check("natural boarding: ride starts", cube.global_position.distance_to(start) > 0.2)
	_check("natural boarding: eye follows platform", (eye.global_position - eye_start).distance_to(cube.global_position - start) <= POSITION_TOLERANCE)
	var target: Transform3D = body.global_transform
	target.origin.z += 2.0
	body.teleport(target)
	for i in 12:
		await _tick()
	_check("natural boarding: exits Area", not area.overlaps_body(body))
	_check("natural boarding: exits ride", cube.carried_player != body)
	await _dispose(state)


func _departure(name: String, jump: bool) -> void:
	var state := await _spawn(Vector3.RIGHT, 4.0)
	var cube = state.cube
	var body = state.body
	cube.return_delay = 100.0
	cube._on_detection_area_body_entered(body)
	for i in 20:
		await _tick()
	_check(name + ": initially aboard", cube.carried_player == body)
	var start_y: float = body.global_position.y
	if jump:
		body.request_jump()
	else:
		var target: Transform3D = body.global_transform
		target.origin.z += 2.0
		body.teleport(target)
	var release_position: Vector3 = body.global_position
	var cube_release: Vector3 = cube.global_position
	var rose := false
	for i in 12:
		await _tick()
		rose = rose or body.global_position.y > start_y + 0.04
	_check(name + ": releases rider", cube.carried_player != body)
	if jump:
		_check(name + ": real jump rises", rose)
	else:
		_check(name + ": cube continues independently", cube.global_position.distance_to(cube_release) > 0.2)
		_check(name + ": departing body not dragged", absf(body.global_position.x - release_position.x) < 0.06,
			body.global_position.x - release_position.x)
	await _dispose(state)


func _invalid_boarding(name: String, displacement: Vector3) -> void:
	var state := await _spawn(Vector3.RIGHT, 1.2)
	var cube = state.cube
	var body = state.body
	# Reposition the real body/rig together and present the broad area's event.
	# No floor support from the cube exists at either test location.
	var target: Transform3D = body.global_transform
	target.origin += displacement
	body.teleport(target)
	cube._on_detection_area_body_entered(body)
	_check(name + ": does not board", cube.carried_player != body)
	var start: Vector3 = cube.global_position
	for i in 8:
		await _tick()
	_check(name + ": does not start ride", cube.global_position.distance_to(start) < 0.001)
	await _dispose(state)


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	XRServer.world_scale = 1.0
	# Deferred loading lets project autoloads initialize before XRTools resolves them.
	cube_scene = load(CUBE_PATH)
	body_scene = load(BODY_PATH)
	if cube_scene == null or body_scene == null:
		_check("production scenes load", false)
		_finish()
		return
	for entry in [["positive-x", Vector3.RIGHT], ["negative-x", Vector3.LEFT],
		["positive-z", Vector3.BACK], ["negative-z", Vector3.FORWARD], ["up", Vector3.UP]]:
		await _ride(entry[0], entry[1])
	# Exact distance/direction used by the combined translation hall's escalator.
	await _ride("down-forward-escalator", Vector3(0.0, -3.0, 2.0), 3.6055513)
	await _ride("offset-rotated-rig", Vector3.BACK, 1.2, Vector3(0.18, 0.0, -0.12), 0.65)
	await _ride("turning-rig", Vector3.BACK, 1.2, Vector3(0.18, 0.0, -0.12), 0.65, 90.0)
	await _ride("desktop", Vector3.RIGHT, 1.2, Vector3.ZERO, 0.0, 0.0, true)
	await _natural_boarding()
	await _departure("jump-off", true)
	await _departure("step-off", false)
	await _invalid_boarding("beside-platform", Vector3(0.8, 0.0, 0.0))
	await _invalid_boarding("below-platform", Vector3(0.0, -1.5, 0.0))
	_finish()


func _finish() -> void:
	var report := {"checks": checks, "failures": failures, "cases": cases,
		"engine": Engine.get_version_info(), "physics_hz": Engine.physics_ticks_per_second,
		"production_script_sha256": FileAccess.get_sha256("res://commons/scenes/mapobjects/transport_cube.gd"),
		"probe_sha256": FileAccess.get_sha256("res://commons/testing/probe_transport_cube_vr.gd"),
		"real_physics": true, "real_xr_tools_body": true, "tracked_headset": false,
		"note": "Rides use deterministic boarding after real physics settling; natural boarding separately uses Area overlap detection. No tracked headset or live controller input."}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("TRANSPORT CUBE VR: ", checks.size() - failures.size(), "/", checks.size(),
		" passed; report ", REPORT_PATH)
	quit(0 if failures.is_empty() else 1)
