# TentacleTest.gd
# Standalone test: ONE FABRIK3D tentacle sitting in place on a floor.
# Follows the spine_demo / beast_demo pattern exactly:
#   - 6 bones, 1.0 spacing in +Y
#   - Skin with cumulative inverse bind poses (0, -1, -2, -3, -4, -5)
#   - ArrayMesh tapered cylinder with per-vertex bone weights
#   - FABRIK3D targets a Marker3D that tracks toward the player/camera
#
# Run this scene standalone (F6) to test IK in isolation.
extends Node3D

const BONE_COUNT: int = 6
const BONE_SPACING: float = 1.0  # Same as spine_demo (1 unit per bone)
const BASE_RADIUS: float = 0.15  # Thicker at root
const TIP_RADIUS: float = 0.04   # Thin at tip
const RADIAL_SEGMENTS: int = 8

@export var target_speed: float = 3.0  ## How fast the target moves toward player
@export var attract_radius: float = 8.0  ## How far the tentacle can "sense"

var _target: Marker3D = null
var _skeleton: Skeleton3D = null
var _camera: Camera3D = null
var _camera_yaw: float = 0.0
var _camera_pitch: float = -0.3
var _camera_pos: Vector3 = Vector3(0, 3.0, 6.0)
var _mouse_captured: bool = false

func _ready() -> void:
	# Build floor + environment
	_build_floor()
	_build_lighting()

	# Get references from the .tscn
	_skeleton = $Armature/Skeleton3D
	_target = $Target

	# Add skinned mesh to skeleton at runtime
	_add_skinned_mesh()

	# Add small sphere to visualize target
	_add_target_vis()

	# Setup camera
	_setup_camera()

	print("[TentacleTest] Ready — %d bones, %.1f spacing, chain length %.1f" % [
		BONE_COUNT, BONE_SPACING, BONE_SPACING * (BONE_COUNT - 1)])
	print("[TentacleTest] Target at %s" % _target.global_position)

# ═══════════════════════════════════════════════════════════════════════════
# SKINNED MESH CREATION — follows spine_demo / beast_demo Skin pattern
# ═══════════════════════════════════════════════════════════════════════════

func _add_skinned_mesh() -> void:
	var skin: Skin = _create_skin()
	var mesh: ArrayMesh = _create_tentacle_mesh()
	var mat: StandardMaterial3D = _create_tentacle_material()

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "TentacleMesh"
	mesh_inst.mesh = mesh
	mesh_inst.skin = skin
	mesh_inst.skeleton = NodePath("..")  # parent = Skeleton3D
	mesh_inst.material_override = mat

	_skeleton.add_child(mesh_inst)
	print("[TentacleTest] Skinned mesh added — %d verts, skin bind_count=%d" % [
		mesh.get_aabb().size.length(), skin.get_bind_count()])

func _create_skin() -> Skin:
	## Spine_demo pattern: bind_bone = -1 (name-based), bind_pose = cumulative inverse.
	## Bone 0 at Y=0 → bind (0, 0, 0)
	## Bone 1 at Y=1 → bind (0, -1, 0)
	## Bone 2 at Y=2 → bind (0, -2, 0)
	## etc.
	var skin := Skin.new()
	skin.set_bind_count(BONE_COUNT)
	for i in range(BONE_COUNT):
		var bone_name: String = "Bone" if i == 0 else "Bone.%03d" % i
		skin.set_bind_name(i, bone_name)
		skin.set_bind_bone(i, -1)  # Resolve by name (spine_demo pattern)
		var cumulative_y: float = -BONE_SPACING * float(i)
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, cumulative_y, 0)))
	return skin

func _create_tentacle_mesh() -> ArrayMesh:
	## Tapered cylinder — one ring of vertices per bone, each ring 100% weighted to its bone.
	## This is the same concept as the spine_demo Blender mesh, just procedural.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var bones_arr := PackedInt32Array()   # 4 bone indices per vertex
	var weights_arr := PackedFloat32Array()  # 4 weights per vertex

	# Generate vertices: one ring per bone
	for ring in range(BONE_COUNT):
		var y: float = BONE_SPACING * float(ring)
		var t: float = float(ring) / float(BONE_COUNT - 1)
		var radius: float = lerp(BASE_RADIUS, TIP_RADIUS, t)

		for seg in range(RADIAL_SEGMENTS):
			var angle: float = TAU * float(seg) / float(RADIAL_SEGMENTS)
			verts.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
			normals.append(Vector3(cos(angle), 0, sin(angle)).normalized())
			# 100% weight to this ring's bone
			bones_arr.append(ring)
			bones_arr.append(0)
			bones_arr.append(0)
			bones_arr.append(0)
			weights_arr.append(1.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)

	# Generate triangle indices between adjacent rings
	var indices := PackedInt32Array()
	for ring in range(BONE_COUNT - 1):
		for seg in range(RADIAL_SEGMENTS):
			var curr: int = ring * RADIAL_SEGMENTS + seg
			var next_s: int = ring * RADIAL_SEGMENTS + (seg + 1) % RADIAL_SEGMENTS
			var above: int = (ring + 1) * RADIAL_SEGMENTS + seg
			var above_next: int = (ring + 1) * RADIAL_SEGMENTS + (seg + 1) % RADIAL_SEGMENTS
			indices.append(curr)
			indices.append(above)
			indices.append(next_s)
			indices.append(next_s)
			indices.append(above)
			indices.append(above_next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_BONES] = bones_arr
	arrays[Mesh.ARRAY_WEIGHTS] = weights_arr
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_tentacle_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.25, 0.35)  # Dark pink/tentacle color
	mat.roughness = 0.6
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided like spine_demo
	return mat

# ═══════════════════════════════════════════════════════════════════════════
# ENVIRONMENT SETUP
# ═══════════════════════════════════════════════════════════════════════════

func _build_floor() -> void:
	# Use the existing Floor node from .tscn
	var floor_node: StaticBody3D = $Floor
	# Add mesh to FloorMesh
	var floor_mesh: MeshInstance3D = $Floor/FloorMesh
	var box := BoxMesh.new()
	box.size = Vector3(20.0, 0.1, 20.0)
	floor_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.38)
	mat.roughness = 0.85
	floor_mesh.material_override = mat
	# Collision
	var col: CollisionShape3D = $Floor/FloorCol
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(20.0, 0.1, 20.0)
	col.shape = box_shape

func _build_lighting() -> void:
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _add_target_vis() -> void:
	var vis: MeshInstance3D = $Target/TargetVis
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	vis.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	vis.material_override = mat

# ═══════════════════════════════════════════════════════════════════════════
# TARGET TRACKING — tentacle tip follows the player/camera
# ═══════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if not _target:
		return

	# Determine where the "player" is
	var player_pos: Vector3
	if _camera:
		player_pos = _camera.global_position
		# Clamp Y so tentacle can reach it
		player_pos.y = clamp(player_pos.y, 0.0, 5.0)
	else:
		var player: Node3D = _find_player()
		if player:
			player_pos = player.global_position
		else:
			# Auto-oscillate for testing
			var t: float = Time.get_ticks_msec() / 1000.0
			player_pos = Vector3(sin(t * 0.5) * 2.0, 3.0 + sin(t * 0.8), cos(t * 0.3) * 2.0)

	var dist: float = global_position.distance_to(player_pos)
	if dist < attract_radius:
		_target.global_position = _target.global_position.lerp(player_pos, target_speed * delta)
	else:
		# Return to rest (straight up)
		var rest_pos: Vector3 = global_position + Vector3(0, 4.5, 0)
		_target.global_position = _target.global_position.lerp(rest_pos, target_speed * 0.5 * delta)

func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player is Node3D:
		return player as Node3D
	var root: Node = tree.current_scene
	if root:
		var xr: Node = root.find_child("XROrigin3D", true, false)
		if xr is Node3D:
			return xr as Node3D
	return null

# ═══════════════════════════════════════════════════════════════════════════
# DESKTOP CAMERA (for standalone testing)
# ═══════════════════════════════════════════════════════════════════════════

func _setup_camera() -> void:
	if get_viewport().get_camera_3d() != null:
		return
	_camera = Camera3D.new()
	_camera.name = "TestCamera"
	_camera.position = _camera_pos
	_camera.fov = 70.0
	_camera.current = true
	add_child(_camera)
	_update_camera()
	print("[TentacleTest] Desktop camera — click to capture mouse, WASD move, ESC release")

func _input(event: InputEvent) -> void:
	if _camera == null:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.keycode == KEY_ESCAPE and key.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
	if event is InputEventMouseMotion and _mouse_captured:
		var motion: InputEventMouseMotion = event
		_camera_yaw -= motion.relative.x * 0.003
		_camera_pitch -= motion.relative.y * 0.003
		_camera_pitch = clamp(_camera_pitch, -PI * 0.45, PI * 0.45)
		_update_camera()

func _process(delta: float) -> void:
	if _camera == null:
		return
	var move_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): move_dir.z += 1.0
	if Input.is_key_pressed(KEY_A): move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): move_dir.x += 1.0
	if Input.is_key_pressed(KEY_SPACE): move_dir.y += 1.0
	if Input.is_key_pressed(KEY_SHIFT): move_dir.y -= 1.0
	if move_dir.length_squared() > 0.0:
		var yaw_basis := Basis(Vector3.UP, _camera_yaw)
		_camera_pos += yaw_basis * move_dir.normalized() * 4.0 * delta
		_camera.position = _camera_pos

func _update_camera() -> void:
	if _camera:
		_camera.rotation = Vector3(_camera_pitch, _camera_yaw, 0)
		_camera.position = _camera_pos
