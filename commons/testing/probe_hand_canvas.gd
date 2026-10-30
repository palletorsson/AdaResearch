extends Node3D
## THE HAND CANVAS under the real hands: the museum rig on fake trackers (its hand meshes carry the fingertip
## skeletons, animated by grip and trigger as XR Tools does), a canvas facing the player. (A) the canvas finds
## two hands with five tips each; (B) the right hand POINTING (grip closed, trigger open: only the index out)
## is brought to the glass until its index tip is on the face - one indicator touches; (C) swept 60 cm along
## the glass it paints a thin line (painted pixels counted); (D) the OPEN hand (grip and trigger released) laid
## flat on the glass: five or six indicators touch; (E) swept the same way it paints far more - the wash;
## (F) clear() empties it. Writes ada_run/inventory/hand_canvas.png + hand_canvas.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_hand_canvas.tscn

const Rig = preload("res://commons/player/museum_rig.tscn")
const Canvas = preload("res://commons/artifacts/hand_canvas/hand_canvas.tscn")

var _left: XRControllerTracker
var _right: XRControllerTracker
var rig: XROrigin3D
var canvas: Node3D

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(0.6, 1.6, 2.2)).looking_at(Vector3(0, 1.1, -0.6));cam.fov = 55;add_child(cam)
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_pose(_left, Transform3D(Basis(), Vector3(-0.3, 1.0, 0.2)));_pose(_right, Transform3D(Basis(), Vector3(0.3, 1.0, 0.2)))
	_left.set_input(&"grip", 0.0);_left.set_input(&"trigger", 0.0);_right.set_input(&"grip", 0.0);_right.set_input(&"trigger", 0.0)
	XRServer.add_tracker(_left);XRServer.add_tracker(_right)
	rig = Rig.instantiate();add_child(rig);rig.current = true
	cam.current = true
	# the canvas 0.6 m ahead, facing the player (+Z toward +Z: the player stands at z > 0 looking down -Z)
	canvas = Canvas.instantiate();add_child(canvas);canvas.global_transform = Transform3D(Basis(), Vector3(0, 0, -0.6))
	for i in 40:
		await get_tree().process_frame
	var report := {"checks": []}
	canvas._scan_hands()
	var hands: Array = canvas._hands
	var tips_ok: bool = hands.size() == 2 and hands.all(func(h):return (h.tips as Array).size() == 5 and h.knuckle >= 0)
	_check(report, "A hands: the canvas finds two tracked hands, five fingertips and a knuckle each", tips_ok, {"hands": hands.size(), "tips": hands.map(func(h):return (h.tips as Array).size())})
	# B - pointing: grip closed, trigger open; the index tip brought onto the face
	_right.set_input(&"grip", 1.0);_right.set_input(&"trigger", 0.0)
	for i in 30:
		await get_tree().process_frame
	var tip_ok := await _bring_tip_to_glass("Index_Tip_R", Vector3(-0.3, 1.2, 0))
	for i in 6:
		await get_tree().physics_frame
	var one: int = canvas.touching.get("R", 0)
	_check(report, "B one finger: the pointing hand's index tip on the glass - one indicator touches", tip_ok and one == 1, {"tip_on_glass": tip_ok, "touching": canvas.touching})
	# C - swept 60 cm along the glass: a thin line
	var before_c: int = _painted()
	await _sweep(0.6)
	var line_px: int = _painted() - before_c
	_check(report, "C thin line: 60 cm swept with one finger paints a line (pixels)", line_px > 200, {"pixels": line_px, "marks": canvas.marks})
	# D - the open hand flat on the glass: five or six indicators
	_right.set_input(&"grip", 0.0);_right.set_input(&"trigger", 0.0)
	for i in 30:
		await get_tree().process_frame
	var many: int = await _lay_flat(Vector3(0.6, 1.0, 0))
	var palm_ok: bool = many > 0
	_check(report, "D whole hand: the open hand flat on the glass - at least four indicators touch", palm_ok and many >= 4, {"palm_on_glass": palm_ok, "touching": canvas.touching})
	# E - swept the same way: the wash, far wider than the line
	var before_e: int = _painted()
	await _sweep(0.6)
	var wash_px: int = _painted() - before_e
	_check(report, "E the wash: the same sweep with the whole hand paints several times the pixels of the line", wash_px > line_px * 3, {"line": line_px, "wash": wash_px})
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("hand_canvas.png"))
	canvas.image().save_png(out_dir.path_join("hand_canvas_paint.png"))
	# F - the hand lifted off, then cleared
	_pose(_right, rig.global_transform.affine_inverse() * Transform3D(Basis(), Vector3(0.6, 1.0, 0.6)))
	for i in 40:
		await get_tree().physics_frame   # the collision hand follows the controller at its own speed
	var lifted: bool = canvas.touching.get("R", 0) == 0
	await canvas.clear()
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var px_f: int = _painted()
	_check(report, "F clear: the hand lifted off, the paint is gone", lifted and px_f < 50, {"lifted": lifted, "pixels": px_f})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("hand_canvas.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_hand_canvas] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _pose(t: XRControllerTracker, xf: Transform3D) -> void:
	t.set_pose(&"aim", xf, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

## Move the right controller until the named bone lies on the glass face at `want` (world), by iteration: the
## bone's offset from the controller is whatever the animated hand makes it.
func _bring_tip_to_glass(bone: String, want: Vector3, flat := false) -> bool:
	var face_z: float = canvas.global_position.z + canvas.SURFACE_THICKNESS
	var target := Vector3(want.x, want.y, face_z)
	# pointing: the hand aims into the glass; flat: the right palm (the aim frame's -X) turned to face the glass (-Z)
	var ctrl_xf := Transform3D(Basis(Vector3.UP, -PI / 2) if flat else Basis(Vector3.RIGHT, -PI / 2.2), Vector3(target.x, target.y, target.z + 0.25))
	for k in 8:
		_pose(_right, rig.global_transform.affine_inverse() * ctrl_xf)
		for i in 10:
			await get_tree().physics_frame
		var p := _bone_global(bone)
		if p == Vector3.INF:return false
		var err := target - p
		if err.length() < 0.004:return true
		ctrl_xf.origin += err
	return (_bone_global(bone) - target).length() < 0.01

## The open hand laid FLAT on the glass: the palm plane is read from the hand's own bones (wrist, index knuckle,
## little knuckle), the controller turned so that plane faces the glass, both ways, and the knuckle brought to the
## face; the way that touches more wins. Returns how many indicators touch.
func _lay_flat(want: Vector3) -> int:
	var face_z: float = canvas.global_position.z + canvas.SURFACE_THICKNESS
	var target := Vector3(want.x, want.y, face_z)
	var best := 0
	for sign in [1.0, -1.0]:
		# a neutral pose, then the palm normal in the controller's frame
		var ctrl_xf := Transform3D(Basis(), Vector3(target.x, target.y, target.z + 0.3))
		_pose(_right, rig.global_transform.affine_inverse() * ctrl_xf)
		for i in 10:
			await get_tree().physics_frame
		var w := _bone_global("Wrist_R");var ik := _bone_global("Index_Proximal_R");var lk := _bone_global("Little_Proximal_R")
		if w == Vector3.INF or ik == Vector3.INF or lk == Vector3.INF:return 0
		var n: Vector3 = ((ik - w).cross(lk - w)).normalized() * sign
		var ctrl: Node3D = rig.get_node("RightHand");var n_local: Vector3 = ctrl.global_basis.inverse() * n
		# the controller turned so the palm normal points into the glass (-Z)
		var turn := Quaternion(n_local.normalized(), Vector3.FORWARD)
		ctrl_xf = Transform3D(Basis(turn), ctrl_xf.origin)
		for k in 8:
			_pose(_right, rig.global_transform.affine_inverse() * ctrl_xf)
			for i in 10:
				await get_tree().physics_frame
			var p := _bone_global("Middle_Proximal_R")
			var err := target - p
			if err.length() < 0.004:break
			ctrl_xf.origin += err
		for i in 6:
			await get_tree().physics_frame
		var n_touch: int = canvas.touching.get("R", 0)
		var depths: Array = []
		for b in ["Thumb_Tip_R", "Index_Tip_R", "Middle_Tip_R", "Ring_Tip_R", "Little_Tip_R", "Middle_Proximal_R", "Wrist_R"]:
			var g := _bone_global(b);depths.append("%s %.3f" % [b.trim_suffix("_R"), canvas.to_local(g).z - canvas.SURFACE_THICKNESS])
		print("[probe_hand_canvas] flat sign %+.0f: touching %d  depths %s" % [sign, n_touch, str(depths)])
		if n_touch > best:best = n_touch
		if n_touch >= 4:break
	return best

func _bone_global(bone: String) -> Vector3:
	for sk in rig.find_children("*", "Skeleton3D", true, false):
		var s := sk as Skeleton3D;var i := s.find_bone(bone)
		if i >= 0:return s.global_transform * s.get_bone_global_pose(i).origin
	return Vector3.INF

## Slide the right controller `dx` along +X over half a second, keeping its depth.
func _sweep(dx: float) -> void:
	var start: Transform3D = rig.global_transform * Transform3D(Basis(), Vector3.ZERO)   # placeholder, replaced below
	var pose: Transform3D = rig.get_node("RightHand").global_transform
	var steps := 30
	for i in steps:
		var xf := pose.translated(Vector3(dx * float(i + 1) / steps, 0, 0))
		_pose(_right, rig.global_transform.affine_inverse() * xf)
		await get_tree().physics_frame
	start = start

func _painted() -> int:
	var img: Image = canvas.image();var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			if img.get_pixel(x, y).a > .2:n += 1
	return n * 4

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_hand_canvas] %s  %s" % ["ok  " if ok else "FAIL", what])
