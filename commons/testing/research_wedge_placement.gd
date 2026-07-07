@tool
extends SceneTree
# Wedge placement gesture — the bracelet's ramp tool.
#
# The wedge stone (warm orange, mode_wedge_placer.gd) places walkable
# PrismMesh ramps on the grid. Same trigger-to-place gesture as voxel
# mode, but the placed shape is a sloped wedge oriented toward the
# player's look direction — the bracelet asks the player's body where
# 'down' is and tilts the prism accordingly.
#
# Three states for this gesture:
#   approach  — hand pointing toward target, ghost wedge preview
#               oriented toward camera
#   placing   — trigger pulled, ghost solidifies, slope-arrow particles
#   placed    — wedge now part of the grid, slope toward player
#
# Output: user://catalyst_runs/wedge_placement/<state>.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

# Wedge mode signature colour (from mode_wedge_placer.gd).
const WEDGE_COLOR := Color(0.85, 0.55, 0.20)
# Cardinal target cell — 2 cells east, same as voxel placement.
const TARGET_POS := Vector3(0.55, 0.5, -1.30)


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/wedge_placement")

	await _capture("approach")
	await _capture("placing")
	await _capture("placed")
	print("[wedge_placement] complete")
	quit()


func _capture(state: String) -> void:
	var root := Node3D.new()
	root.name = "WedgePlacement_%s" % state

	VRCaptureRig.build_environment(root)
	_spawn_existing_floor(root)

	# Left hand wears the bracelet.
	var left_pos := Vector3(-0.18, 1.30, -0.45)
	var left_basis := VRCaptureRig.hand_basis(
		Vector3(0.4, 0, -1), 0.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		left_basis, "Default pose", true)
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.5, -0.1, 0.85)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, WEDGE_COLOR)

	# Right hand — same as voxel placement, but pose has more of a
	# "sweep" feel because wedges have an orientation.
	var right_pos: Vector3
	var right_pose: String
	match state:
		"approach":
			right_pos = Vector3(0.15, 1.20, -0.65)
			right_pose = "Point"
		"placing":
			right_pos = Vector3(0.18, 1.16, -0.78)
			right_pose = "Grip"
		_:
			right_pos = Vector3(0.20, 1.15, -0.50)
			right_pose = "Default pose"

	var aim_dir: Vector3 = (TARGET_POS - right_pos).normalized()
	var right_basis := VRCaptureRig.hand_basis(aim_dir, 0.0, false)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		right_basis, right_pose, false)

	_decorate_for_state(root, state, right_pos, aim_dir)

	var cam := VRCaptureRig.first_person_camera(1.62,
		Vector3(0, 1.10, -0.75), 82.0)
	root.add_child(cam)

	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	for _i in range(40):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[wedge_placement] FAIL %s" % state)
		return
	img.save_png("user://catalyst_runs/wedge_placement/%s.png" % state)
	print("[wedge_placement] saved %s" % state)


func _spawn_existing_floor(root: Node3D) -> void:
	var positions: Array[Vector3] = [
		Vector3(-0.55, 0.0, -1.30),
		Vector3( 0.00, 0.0, -1.30),
		Vector3(-0.55, 0.0, -0.75),
		Vector3( 0.00, 0.0, -0.75),
	]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.38)
	mat.metallic = 0.05
	mat.roughness = 0.85
	for p in positions:
		var cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.50, 0.50, 0.50)
		cube.mesh = box
		cube.material_override = mat
		cube.position = p + Vector3(0, 0.25, 0)
		root.add_child(cube)


func _decorate_for_state(
	root: Node3D, state: String,
	hand_pos: Vector3, aim_dir: Vector3) -> void:
	match state:
		"approach":
			_spawn_aim_ray(root, hand_pos, TARGET_POS, 0.4)
			_spawn_ghost_wedge(root, TARGET_POS, 0.35)
		"placing":
			_spawn_aim_ray(root, hand_pos, TARGET_POS, 0.7)
			_spawn_ghost_wedge(root, TARGET_POS, 0.7)
			_spawn_slope_arrow(root, TARGET_POS)
		_:
			_spawn_solid_wedge(root, TARGET_POS)


func _spawn_aim_ray(root: Node3D, from: Vector3, to: Vector3, alpha: float) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.001:
		return
	var ray := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = length
	ray.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(WEDGE_COLOR.r, WEDGE_COLOR.g, WEDGE_COLOR.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = WEDGE_COLOR
	mat.emission_energy_multiplier = 0.6
	ray.material_override = mat
	var up_dir := dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	ray.transform.basis = Basis(rx, up_dir, rz)
	ray.position = from + dir * 0.5
	root.add_child(ray)


# A PrismMesh wedge oriented so its slope rises away from the player —
# matching what mode_wedge_placer puts on the grid. Ghost form uses
# alpha + emission; the solid form below drops transparency.
func _spawn_ghost_wedge(root: Node3D, pos: Vector3, alpha: float) -> void:
	var wedge := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.50, 0.50, 0.50)
	prism.left_to_right = 0.5
	wedge.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(WEDGE_COLOR.r, WEDGE_COLOR.g, WEDGE_COLOR.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = WEDGE_COLOR
	mat.emission_energy_multiplier = 0.45
	wedge.material_override = mat
	# Slope rises away from player (–Z is forward), so rotate so the high
	# edge points along +Z.
	wedge.position = pos + Vector3(0, 0.25, 0)
	wedge.rotation = Vector3(0, deg_to_rad(180), 0)
	root.add_child(wedge)


func _spawn_solid_wedge(root: Node3D, pos: Vector3) -> void:
	var wedge := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.50, 0.50, 0.50)
	prism.left_to_right = 0.5
	wedge.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WEDGE_COLOR * 0.7
	mat.metallic = 0.05
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = WEDGE_COLOR
	mat.emission_energy_multiplier = 0.20
	wedge.material_override = mat
	wedge.position = pos + Vector3(0, 0.25, 0)
	wedge.rotation = Vector3(0, deg_to_rad(180), 0)
	root.add_child(wedge)


# Slope-direction indicator — a short arrow along the wedge's rise axis
# to show the player which way the ramp will lift them.
func _spawn_slope_arrow(root: Node3D, center: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 1.0

	# Shaft.
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.018
	cyl.bottom_radius = 0.018
	cyl.height = 0.36
	shaft.mesh = cyl
	shaft.material_override = mat
	# Lay along +Z, tilted up to follow the slope (45° rise).
	shaft.transform.basis = Basis(Vector3(1, 0, 0),
		Vector3(0, 0.7071, 0.7071), Vector3(0, -0.7071, 0.7071))
	shaft.position = center + Vector3(0, 0.42, 0.10)
	root.add_child(shaft)

	# Tip.
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.055
	cone.height = 0.12
	tip.mesh = cone
	tip.material_override = mat
	tip.transform.basis = shaft.transform.basis
	tip.position = center + Vector3(0, 0.58, 0.26)
	root.add_child(tip)
