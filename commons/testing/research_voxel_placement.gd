@tool
extends SceneTree
# Voxel placement gesture — the bracelet's first tool mode.
#
# The voxel stone (cyan-blue, mode_voxel_editor.gd) makes the bracelet
# place cubes on the grid. Right-hand trigger adds a cube in a cardinal
# neighbour cell; grip removes one. The controller ray shows a ghost
# cube on the targeted surface before placement.
#
# Three states for this gesture:
#   approach  — hand pointing toward the target cell, ghost cube
#               previewed (semi-transparent), no commitment yet
#   placing   — trigger pulled, ghost solidifies, particles at corners
#   placed    — cube now part of the grid, hand retracted to rest
#
# Output: user://catalyst_runs/voxel_placement/<state>.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

# Voxel mode signature colour (from mode_voxel_editor.gd).
const VOXEL_COLOR := Color(0.3, 0.7, 1.0)
# Cardinal target cell — 2 cells east of where the player stands.
const TARGET_POS := Vector3(0.55, 0.5, -1.30)


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/voxel_placement")

	await _capture("approach")
	await _capture("placing")
	await _capture("placed")
	print("[voxel_placement] complete")
	quit()


func _capture(state: String) -> void:
	var root := Node3D.new()
	root.name = "VoxelPlacement_%s" % state

	VRCaptureRig.build_environment(root)

	# Existing voxel floor cell where the new cube will land beside.
	_spawn_existing_floor(root)

	# Left hand wears the bracelet — held a bit forward, palm in.
	var left_pos := Vector3(-0.18, 1.30, -0.45)
	var left_basis := VRCaptureRig.hand_basis(
		Vector3(0.4, 0, -1), 0.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		left_basis, "Default pose", true)
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.5, -0.1, 0.85)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, VOXEL_COLOR)

	# Right hand — pointing toward the target cell.
	# Position and pose change per state.
	var right_pos: Vector3
	var right_pose: String
	match state:
		"approach":
			# Hand forward, pointing finger toward target. Trigger not pulled.
			right_pos = Vector3(0.15, 1.20, -0.65)
			right_pose = "Point"
		"placing":
			# Hand a bit more committed forward. Trigger pulled (Grip mid).
			right_pos = Vector3(0.18, 1.18, -0.75)
			right_pose = "Grip"
		_:
			# Placed — hand retracted toward rest, fingers relaxing.
			right_pos = Vector3(0.20, 1.15, -0.50)
			right_pose = "Default pose"

	# Aim from hand to target cell.
	var aim_dir: Vector3 = (TARGET_POS - right_pos).normalized()
	var right_basis := VRCaptureRig.hand_basis(aim_dir, 0.0, false)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		right_basis, right_pose, false)

	# State-specific decoration: ghost ray, ghost cube, real cube, sparks.
	_decorate_for_state(root, state, right_pos, aim_dir)

	# FPV camera.
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
		print("[voxel_placement] FAIL %s" % state)
		return
	img.save_png("user://catalyst_runs/voxel_placement/%s.png" % state)
	print("[voxel_placement] saved %s" % state)


# A small patch of existing voxel floor so the placement-target reads as
# "next neighbour cell, not floating in space."
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
			# Cyan ray from hand toward target — ghost preview.
			_spawn_aim_ray(root, hand_pos, TARGET_POS, 0.4)
			_spawn_ghost_cube(root, TARGET_POS, 0.35)
		"placing":
			# Ray more saturated, ghost cube near-solid, corner sparks.
			_spawn_aim_ray(root, hand_pos, TARGET_POS, 0.7)
			_spawn_ghost_cube(root, TARGET_POS, 0.7)
			_spawn_corner_sparks(root, TARGET_POS)
		_:
			# Placed — solid cube, no ray, no ghost.
			_spawn_solid_cube(root, TARGET_POS)


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
	mat.albedo_color = Color(VOXEL_COLOR.r, VOXEL_COLOR.g, VOXEL_COLOR.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = VOXEL_COLOR
	mat.emission_energy_multiplier = 0.6
	ray.material_override = mat

	# Orient along dir.
	var up_dir := dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	ray.transform.basis = Basis(rx, up_dir, rz)
	ray.position = from + dir * 0.5
	root.add_child(ray)


func _spawn_ghost_cube(root: Node3D, pos: Vector3, alpha: float) -> void:
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.50, 0.50, 0.50)
	cube.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(VOXEL_COLOR.r, VOXEL_COLOR.g, VOXEL_COLOR.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = VOXEL_COLOR
	mat.emission_energy_multiplier = 0.45
	cube.material_override = mat
	cube.position = pos + Vector3(0, 0.25, 0)
	root.add_child(cube)


func _spawn_solid_cube(root: Node3D, pos: Vector3) -> void:
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.50, 0.50, 0.50)
	cube.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = VOXEL_COLOR * 0.7
	mat.metallic = 0.1
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = VOXEL_COLOR
	mat.emission_energy_multiplier = 0.25
	cube.material_override = mat
	cube.position = pos + Vector3(0, 0.25, 0)
	root.add_child(cube)


func _spawn_corner_sparks(root: Node3D, center: Vector3) -> void:
	var corners: Array[Vector3] = [
		Vector3( 0.22,  0.22,  0.22),
		Vector3(-0.22,  0.22,  0.22),
		Vector3( 0.22,  0.22, -0.22),
		Vector3(-0.22,  0.22, -0.22),
	]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 1.2
	for c in corners:
		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.022
		sphere.height = 0.044
		s.mesh = sphere
		s.material_override = mat
		s.position = center + Vector3(0, 0.25, 0) + c
		root.add_child(s)
