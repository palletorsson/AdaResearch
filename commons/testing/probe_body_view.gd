extends Node3D
## LOOK AT THE BODY. A test torso, posed and photographed.
##
## 2026-08-29, Palle: "the arms are too forward compared with hands and the axel
## could be further back, add another test torso and see if you can control bases
## and the animation and screen shot the body until it works."
##
## probe_ik_arms measures NUMBERS — is the wrist within tolerance of the hand. It
## passed while the arms came at the face end-on, because a number cannot see a
## pose. This one renders. It stands the same rig, drives the hands through a
## cycle, and saves a PNG per pose from two standpoints, so the question "does the
## body look right" is answered by looking rather than by inference.
##
## THE STANDPOINT IS THE WHOLE POINT. The headset view is the one that misled us:
## from inside the head an arm pointing at your eye and an arm lying along your
## side project to nearly the same thing. So every pose is shot from the SIDE and
## from the FRONT — the two views in which a forward-set shoulder is obvious —
## and the head's own view is shot last for comparison.
##
##   godot --path . --xr-mode off --resolution 900x600 \
##       res://commons/testing/probe_body_view.tscn
##
## Writes ada_run/body_shots/<pose>_<view>.png and prints the shoulder, elbow and
## wrist of each arm so a picture that looks wrong has numbers beside it.

const Tartan = preload("res://commons/body/tartan.gd")

const OUT_DIR := "res://ada_run/body_shots"

## Hand poses in XROrigin-local metres: [left, right, label]
const POSES := [
	[Vector3(-0.28, 1.05, -0.30), Vector3(0.28, 1.05, -0.30), "rest"],
	[Vector3(-0.34, 1.40, -0.42), Vector3(0.34, 1.40, -0.42), "reach_out"],
	[Vector3(-0.20, 1.55, -0.18), Vector3(0.20, 1.55, -0.18), "hands_up"],
	[Vector3(-0.45, 0.95, -0.20), Vector3(0.45, 0.95, -0.20), "wide_low"],
	[Vector3(-0.16, 1.25, -0.55), Vector3(0.16, 1.25, -0.55), "forward"],
]

var _origin: XROrigin3D
var _cam_head: XRCamera3D
var _left: XRController3D
var _right: XRController3D
var _body: Node
var _shot_cam: Camera3D
var _marks: Node3D

var _pose := 0
var _phase := 0
var _wait := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.18, 0.19, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.52, 0.58)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 34.0, 0.0)
	sun.light_energy = 1.3
	add_child(sun)

	# the floor, so the body has a ground to be judged against
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6.0, 6.0)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.30, 0.31, 0.34)
	floor_mesh.material_override = fm
	add_child(floor_mesh)

	_origin = XROrigin3D.new()
	_origin.name = "XROrigin3D"
	add_child(_origin)

	_cam_head = XRCamera3D.new()
	_cam_head.name = "XRCamera3D"
	_cam_head.current = false
	_origin.add_child(_cam_head)
	_cam_head.position = Vector3(0.0, 1.65, 0.0)

	_left = XRController3D.new()
	_left.name = "LeftHand"
	_origin.add_child(_left)
	_right = XRController3D.new()
	_right.name = "RightHand"
	_origin.add_child(_right)

	var scene: PackedScene = load("res://commons/body/ik_arms/player_body_ik.tscn")
	_body = scene.instantiate()
	_body.name = "PlayerBodyIK"
	_origin.add_child(_body)

	# THE HANDS, DRAWN. Without something at the controller you cannot tell whether
	# the sleeve ends at the hand or short of it — which is the whole question.
	for c in [_left, _right]:
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.045
		sm.height = 0.09
		ball.mesh = sm
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.95, 0.35, 0.45)
		ball.material_override = mm
		c.add_child(ball)

	# the head, so the standpoint is legible in the shot
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.10
	hm.height = 0.20
	head.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.80, 0.72)
	head.material_override = hmat
	_cam_head.add_child(head)

	_marks = Node3D.new()
	add_child(_marks)

	# THE TORSO IS THE ESTIMATOR'S OWN DEBUG VISUAL. TorsoEstimator already sets its
	# node's global_position to the neck and its basis to the torso facing, so a box
	# parented to it shows exactly what the estimator decided — where the chest is,
	# and which way it thinks the body is turned. Judging the arms without it is
	# judging them against nothing.
	var torso_node: Node = _body.get_node_or_null("TorsoEstimator")
	if torso_node is Node3D:
		var chest := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.34, 0.52, 0.20)
		chest.mesh = bm
		chest.position = Vector3(0.0, -0.30, 0.0)   # hangs from the neck
		chest.material_override = Tartan.material(0.42)
		(torso_node as Node3D).add_child(chest)

		# and a nose, so "which way is the torso facing" is answerable from a still
		var nose := MeshInstance3D.new()
		var nm2 := BoxMesh.new()
		nm2.size = Vector3(0.06, 0.06, 0.14)
		nose.mesh = nm2
		nose.position = Vector3(0.0, -0.30, -0.17)
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = Color(0.95, 0.75, 0.25)
		nose.material_override = nmat
		(torso_node as Node3D).add_child(nose)

	# THE AXLE, MARKED. Palle: "the axel could be further back". You cannot judge
	# where a pivot is from a sleeve that covers it, so each shoulder gets a ball.
	for side in ["LeftArmRig", "RightArmRig"]:
		var arm2: Node = _body.get_node_or_null(side)
		if arm2 is Node3D:
			var pin := MeshInstance3D.new()
			var psm := SphereMesh.new()
			psm.radius = 0.035
			psm.height = 0.07
			pin.mesh = psm
			var pmat := StandardMaterial3D.new()
			pmat.albedo_color = Color(0.25, 0.85, 0.45)
			pin.material_override = pmat
			(arm2 as Node3D).add_child(pin)

	_shot_cam = Camera3D.new()
	_shot_cam.current = true
	add_child(_shot_cam)

	_apply_pose(0)
	print("[body-view] %d poses x 3 views -> %s" % [POSES.size(), OUT_DIR])


func _apply_pose(i: int) -> void:
	_left.position = POSES[i][0]
	_right.position = POSES[i][1]


## front / side / head — the three standpoints
func _place_camera(view: String) -> void:
	match view:
		"front":
			_shot_cam.current = true
			_shot_cam.global_position = Vector3(0.0, 1.35, -2.1)
			_shot_cam.look_at(Vector3(0.0, 1.25, 0.0), Vector3.UP)
		"side":
			_shot_cam.current = true
			_shot_cam.global_position = Vector3(2.1, 1.35, -0.35)
			_shot_cam.look_at(Vector3(0.0, 1.25, -0.35), Vector3.UP)
		"head":
			# WHAT THE WEARER SEES, framed so it shows anything. The first run came
			# back empty grey: the hands sit 0.6 m below the eye at 0.3 m range, which
			# is 63 degrees down, outside a 75 degree cone. Tilted down and widened —
			# an empty photograph is not evidence that nothing is there.
			_shot_cam.current = true
			_shot_cam.global_transform = _cam_head.global_transform
			_shot_cam.rotate_object_local(Vector3.RIGHT, deg_to_rad(-35.0))
			_shot_cam.fov = 90.0


func _physics_process(_delta: float) -> void:
	_wait += 1
	if _wait < 10:
		return
	_wait = 0
	var views := ["front", "side", "head"]
	if _pose >= POSES.size():
		print("[body-view] done — %d shots" % (POSES.size() * views.size()))
		get_tree().quit(0)
		return
	if _phase == 0:
		_apply_pose(_pose)
	if _phase == 1:
		# a frame after the pose, so the numbers are the SOLVED chain. Reporting in
		# the same tick as the move printed the rest pose and made a working arm look
		# frozen — the same mistake the first probe made twice.
		_report(_pose)
	if _phase < views.size():
		_place_camera(views[_phase])
		_shoot(String(POSES[_pose][2]), views[_phase])
		_phase += 1
		if _phase >= views.size():
			_phase = 0
			_pose += 1


func _shoot(pose: String, view: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path := "%s/%s_%s.png" % [OUT_DIR, pose, view]
	img.save_png(ProjectSettings.globalize_path(path))


## The numbers beside the picture: where each joint actually is. A pose that looks
## wrong is much easier to fix when the shoulder's z is on the same line as the
## screenshot that shows it in the wrong place.
func _report(i: int) -> void:
	for side in ["LeftArmRig", "RightArmRig"]:
		var arm: Node = _body.get_node_or_null(side)
		if arm == null:
			continue
		var skel: Skeleton3D = _find_skeleton(arm)
		if skel == null or skel.get_bone_count() < 3:
			continue
		var g := skel.global_transform
		var sh: Vector3 = (g * skel.get_bone_global_pose(0)).origin
		var el: Vector3 = (g * skel.get_bone_global_pose(1)).origin
		var wr: Vector3 = (g * skel.get_bone_global_pose(2)).origin
		var hand: Vector3 = (_left if side.begins_with("Left") else _right).global_position
		print("  %-6s %-9s shoulder(%.2f, %.2f, %.2f)  elbow(%.2f, %.2f, %.2f)  wrist(%.2f, %.2f, %.2f)  hand gap %.3f m"
			% [POSES[i][2], side.replace("ArmRig", ""), sh.x, sh.y, sh.z,
			   el.x, el.y, el.z, wr.x, wr.y, wr.z, wr.distance_to(hand)])


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s != null:
			return s
	return null
