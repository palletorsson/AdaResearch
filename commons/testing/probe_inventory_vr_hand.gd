extends Node3D
## The kit in a real XR Tools hand, on a fake rig (a tracker with a POSE and a grip float, the addon's own
## function_pickup.tscn - see probe_stowed_weapon_regrab.gd for why the pose matters): a standing tower (ground
## ball, a rod up, a ball on top); (A) the hand elects the ground ball as its closest object, which proves the
## harness before anything else is believed; (B) grip pressed: the ball is held, supports nothing, and the top
## ball hangs from it on the joints, unfrozen; (C) the hand moved a metre over and half a metre up: the whole
## tower rides along, the top ball still one unit from the ground ball; (D) the hand lowered and the grip let
## go: the ground ball snaps to its new grid point and the top ball, reached again, snaps to its own and holds.
## Writes ada_run/inventory/{vr_hand.png, vr_hand.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_vr_hand.tscn

const PICKUP := "res://addons/godot-xr-tools/functions/function_pickup.tscn"
const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")

var _tracker: XRControllerTracker
var _pickup: Node

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(10, .1, 10);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(10, .1, 10);fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(1.8, 1.5, 2.6)).looking_at(Vector3(.6, .7, 0));cam.fov = 50;add_child(cam);cam.current = true
	# the rig: one right hand with a pose, the addon's pickup function on it
	_tracker = XRControllerTracker.new();_tracker.name = &"right_hand";_tracker.type = XRServer.TRACKER_CONTROLLER;_tracker.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_hand_at(Vector3(.06, .12, .04));_tracker.set_input(&"grip", 0.0);XRServer.add_tracker(_tracker)
	var origin := XROrigin3D.new();origin.name = "XROrigin3D";origin.current = true;add_child(origin)
	var xcam := XRCamera3D.new();xcam.position = Vector3(0, 1.65, 0);origin.add_child(xcam)
	var ctrl := XRController3D.new();ctrl.name = "RightHand";ctrl.tracker = &"right_hand";ctrl.pose = &"aim";origin.add_child(ctrl)
	_pickup = (load(PICKUP) as PackedScene).instantiate();ctrl.add_child(_pickup)
	var report := {"checks": []}
	# the tower
	var g: RigidBody3D = Ball.instantiate();add_child(g);g.global_position = Vector3(.3, .4, .2)
	await get_tree().physics_frame
	g.settle();var hub: float = g.hub()
	var up: RigidBody3D = Rod.instantiate();add_child(up)
	up.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2), g.socket_global(2) + Vector3(0, up.length / 2.0 + .02, 0))
	await get_tree().physics_frame
	up.settle()
	var t: RigidBody3D = Ball.instantiate();add_child(t);t.global_position = Vector3(0, 1 + hub + .05, 0)
	await get_tree().physics_frame
	t.settle()
	for i in 8:
		await get_tree().process_frame
	_check(report, "A harness: the hand elects the ground ball as its closest object (else nothing below means anything)", _pickup.get("closest_object") == g, {"closest": str(_pickup.get("closest_object"))})
	_check(report, "A tower: the top ball holds at row 1 on the rod", t.supported and t.freeze and t.global_position.is_equal_approx(Vector3(0, 1 + hub, 0)) and up.joints.size() == 2, {"t": _v(t.global_position), "joints": up.joints.size()})
	# B — grip: the ground ball into the hand; the tower hangs from it
	_tracker.set_input(&"grip", 1.0)
	for i in 6:
		await get_tree().physics_frame
	_check(report, "B grip: the ground ball is held, supports nothing; the top ball hangs, unfrozen, still jointed", g.is_picked_up() and g.held and not t.supported and not t.freeze and up.joints.size() == 2, {"held": g.is_picked_up(), "g_held": g.held, "t_supported": t.supported, "t_frozen": t.freeze})
	# C — the hand moves a metre over and half a metre up: the tower rides along
	_hand_at(Vector3(1.06, .62, .04))
	for i in 30:
		await get_tree().physics_frame
	var d: float = t.global_position.distance_to(g.global_position)
	_check(report, "C carry: moved with the hand, the top ball is still one unit from the ground ball (hanging on the joints)", g.global_position.distance_to(Vector3(1.06, .62, .04)) < .25 and d > .85 and d < 1.15, {"g": _v(g.global_position), "t": _v(t.global_position), "apart": d})
	# D — lowered and let go: the ground ball onto its new point, the top ball reached again onto its own
	_hand_at(Vector3(1.06, .12, .04))
	for i in 10:
		await get_tree().physics_frame
	_tracker.set_input(&"grip", 0.0)
	for i in 12:
		await get_tree().physics_frame
	_check(report, "D let go: the ground ball snapped to (1, hub, 0); the top ball snapped to (1, 1 + hub, 0) and holds again", not g.is_picked_up() and g.global_position.is_equal_approx(Vector3(1, hub, 0)) and g.freeze and t.supported and t.freeze and t.global_position.is_equal_approx(Vector3(1, 1 + hub, 0)), {"g": _v(g.global_position), "t": _v(t.global_position), "t_supported": t.supported})
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("vr_hand.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("vr_hand.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_inventory_vr_hand] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## The pose positions the hand: XRNode3D takes its transform from it every frame.
func _hand_at(p: Vector3) -> void:
	_tracker.set_pose(&"aim", Transform3D(Basis(), p), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_inventory_vr_hand] %s  %s" % ["ok  " if ok else "FAIL", what])

func _v(v: Vector3) -> Array:return [snappedf(v.x, .001), snappedf(v.y, .001), snappedf(v.z, .001)]
