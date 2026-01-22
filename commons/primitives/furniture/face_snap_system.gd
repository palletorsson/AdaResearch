@tool
extends Node
class_name FaceSnapSystem

## Face Snap System
##
## Detects when cube faces are close and parallel, then snaps positions
## to align on a virtual 0.05m grid. Uses physics joints for rigid attachment.
##
## Usage: Add as child of a scalable cube, or use the static methods.

## Grid cell size (snap resolution)
const GRID_SIZE: float = 0.05

## Distance threshold for face proximity detection
@export var snap_distance: float = 0.15

## Angle tolerance for parallel faces (degrees)
@export var angle_tolerance: float = 30.0

## Show grid overlay when faces are near
@export var show_grid_overlay: bool = true

## Grid line color (approaching)
@export var grid_color: Color = Color(1.0, 0.4, 0.2, 0.8)

## Grid line color when aligned (ready to snap)
@export var snapped_color: Color = Color(0.2, 1.0, 0.4, 0.9)

## Enable face snapping
@export var enable_snapping: bool = true

## Highlight the closest face on other cubes
@export var highlight_other_faces: bool = true

## Signal when snap occurs
signal face_snapped(other_cube: Node3D, my_face: int, other_face: int)

## Signal when snap releases
signal face_unsnapped(other_cube: Node3D)

# Parent cube reference
var _parent_cube: Node3D = null

# Currently snapped to
var _snapped_to: Node3D = null
var _snapped_my_face: int = -1
var _snapped_other_face: int = -1

# Physics joint connecting this cube to another
var _snap_joint: Generic6DOFJoint3D = null

# Grid overlay meshes (one per face, created on demand)
var _grid_overlays: Dictionary = {}  # face_dir -> MeshInstance3D

# Highlight overlay for other cube's face
var _other_face_highlight: MeshInstance3D = null

# Nearby cubes being tracked
var _nearby_cubes: Array[Node3D] = []

# Is parent currently held
var _parent_held: bool = false

# Current best alignment for visual feedback
var _current_alignment: Variant = null


func _ready() -> void:
	# Find parent cube
	_parent_cube = get_parent()
	print("FaceSnapSystem: Initialized, parent=%s" % [_parent_cube.name if _parent_cube else "null"])

	if not Engine.is_editor_hint():
		# Add to group for easy finding
		add_to_group("face_snap_cubes")

		# Connect to parent pickup signals
		_connect_parent_signals()
		print("FaceSnapSystem: Added to group and connected signals")


func _exit_tree() -> void:
	# Clean up the other face highlight since it's parented to scene root
	if _other_face_highlight and is_instance_valid(_other_face_highlight):
		_other_face_highlight.queue_free()
		_other_face_highlight = null


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not enable_snapping:
		return

	# When being grabbed, sync positions of all connected bodies
	# (Joints don't work when the grabbed body is moved via global_transform)
	if _parent_held and _has_connected_bodies():
		_sync_connected_body_positions()

	# Only process snapping visuals when held
	if not _parent_held:
		_hide_all_grids()
		return

	# Find nearby cubes and check for face alignment
	_update_nearby_cubes()
	_check_face_proximity()


## Check if this cube has any joints connecting it to other cubes
func _has_connected_bodies() -> bool:
	# Check joints on this cube
	for child in _parent_cube.get_children():
		if child is Generic6DOFJoint3D:
			return true
	# Check if other cubes have joints to us
	for cube in get_tree().get_nodes_in_group("snappable_cubes"):
		if cube == _parent_cube:
			continue
		for child in cube.get_children():
			if child is Generic6DOFJoint3D:
				var joint = child as Generic6DOFJoint3D
				var node_a = cube.get_node_or_null(joint.node_a)
				var node_b = cube.get_node_or_null(joint.node_b)
				if node_a == _parent_cube or node_b == _parent_cube:
					return true
	return false


## Sync positions of all connected bodies to maintain joint constraints
## This is needed because joints don't work when moving bodies via global_transform
func _sync_connected_body_positions() -> void:
	for cube in _connected_body_offsets.keys():
		if is_instance_valid(cube):
			# Apply the stored relative transform
			var target_global = _parent_cube.global_transform * _connected_body_offsets[cube]
			# Orthonormalize the basis to prevent numerical drift causing invalid quaternions
			target_global.basis = target_global.basis.orthonormalized()
			cube.global_transform = target_global


func _connect_parent_signals() -> void:
	if _parent_cube:
		# XRToolsPickable uses grabbed(pickable, by) and released(pickable, by)
		if _parent_cube.has_signal("grabbed"):
			_parent_cube.grabbed.connect(_on_grabbed)
		if _parent_cube.has_signal("released"):
			_parent_cube.released.connect(_on_released)


## Stores relative transforms of connected bodies when grabbed
var _connected_body_offsets: Dictionary = {}  # cube -> Transform3D (relative to grabbed cube)


func _on_grabbed(_pickable, _by) -> void:
	_parent_held = true

	# Store relative transforms of all connected bodies
	# so we can maintain their positions while dragging
	_capture_connected_body_offsets()


## Capture the relative transform of each connected body
func _capture_connected_body_offsets() -> void:
	_connected_body_offsets.clear()
	var visited: Dictionary = {_parent_cube: true}
	var parent_inv = _parent_cube.global_transform.inverse()

	_capture_offsets_recursive(_parent_cube, parent_inv, visited)


func _capture_offsets_recursive(cube: Node3D, parent_inv: Transform3D, visited: Dictionary) -> void:
	# Find joints on this cube
	for child in cube.get_children():
		if child is Generic6DOFJoint3D:
			var joint = child as Generic6DOFJoint3D
			var node_a = cube.get_node_or_null(joint.node_a)
			var node_b = cube.get_node_or_null(joint.node_b)
			for other in [node_a, node_b]:
				if other and other not in visited and other.is_in_group("snappable_cubes"):
					visited[other] = true
					# Store offset relative to grabbed cube
					_connected_body_offsets[other] = parent_inv * other.global_transform
					# Freeze the connected body
					if other is RigidBody3D:
						(other as RigidBody3D).freeze = true
					# Recurse
					_capture_offsets_recursive(other, parent_inv, visited)

	# Also check if other cubes have joints pointing to this one
	for other_cube in get_tree().get_nodes_in_group("snappable_cubes"):
		if other_cube in visited:
			continue
		for child in other_cube.get_children():
			if child is Generic6DOFJoint3D:
				var joint = child as Generic6DOFJoint3D
				var node_a = other_cube.get_node_or_null(joint.node_a)
				var node_b = other_cube.get_node_or_null(joint.node_b)
				if node_a == cube or node_b == cube:
					visited[other_cube] = true
					_connected_body_offsets[other_cube] = parent_inv * other_cube.global_transform
					if other_cube is RigidBody3D:
						(other_cube as RigidBody3D).freeze = true
					_capture_offsets_recursive(other_cube, parent_inv, visited)
					break


func _on_released(_pickable, _by) -> void:
	_parent_held = false

	# Unfreeze connected bodies
	_release_connected_bodies()

	# Attempt snap on release
	_update_nearby_cubes()

	var best_snap = _find_best_snap()
	if best_snap:
		print("FaceSnapSystem: Snapping %s face %d -> %s face %d" % [_parent_cube.name, best_snap.my_face, best_snap.cube.name, best_snap.other_face])
		_perform_snap(best_snap.cube, best_snap.my_face, best_snap.other_face, best_snap.snap_pos)

	_hide_all_grids()
	_hide_other_face_highlight()


## Release (unfreeze) all connected bodies after dropping
func _release_connected_bodies() -> void:
	for cube in _connected_body_offsets.keys():
		if is_instance_valid(cube) and cube is RigidBody3D:
			var rb = cube as RigidBody3D
			# Only unfreeze if not snapped to something
			# (snapped bodies should stay frozen)
			var snap_system = cube.get_node_or_null("FaceSnapSystem")
			if snap_system and snap_system.has_method("is_snapped") and not snap_system.is_snapped():
				rb.freeze = false
	_connected_body_offsets.clear()


func _update_nearby_cubes() -> void:
	_nearby_cubes.clear()

	# Find all face snap cubes in scene
	var all_snap_systems = get_tree().get_nodes_in_group("face_snap_cubes")

	for node in all_snap_systems:
		if node == self:
			continue
		var cube = node.get_parent()
		if cube and cube != _parent_cube:
			var dist = _parent_cube.global_position.distance_to(cube.global_position)
			# Rough distance check (sum of max possible extents)
			if dist < 2.0:
				_nearby_cubes.append(cube)


func _check_face_proximity() -> void:
	var found_alignment = false
	_current_alignment = null

	for other_cube in _nearby_cubes:
		var alignment = _check_cube_alignment(other_cube)
		if alignment:
			found_alignment = true
			_current_alignment = alignment
			_show_grid_on_face(alignment.my_face, alignment.is_aligned)
			# Also highlight the other cube's face
			if highlight_other_faces:
				_show_other_face_highlight(alignment.other_cube, alignment.other_face, alignment.other_face_center, alignment.is_aligned)
			break

	if not found_alignment:
		_hide_all_grids()
		_hide_other_face_highlight()


func _check_cube_alignment(other_cube: Node3D) -> Variant:
	# Get sizes of both cubes
	var my_size = _get_cube_size(_parent_cube)
	var other_size = _get_cube_size(other_cube)

	# Check each face pair
	for my_face in range(6):
		var my_normal = _get_face_normal(my_face)
		var my_world_normal = _parent_cube.global_transform.basis * my_normal
		var my_face_center = _get_face_center(_parent_cube, my_face, my_size)

		for other_face in range(6):
			var other_normal = _get_face_normal(other_face)
			var other_world_normal = other_cube.global_transform.basis * other_normal
			var other_face_center = _get_face_center(other_cube, other_face, other_size)

			# Check if normals are opposing (faces pointing at each other)
			# For opposing normals, dot should be close to -1
			var dot = my_world_normal.dot(other_world_normal)
			var min_dot = -cos(deg_to_rad(angle_tolerance))  # e.g., -cos(30°) = -0.866
			if dot > min_dot:
				continue

			# Check distance between face centers
			# For larger cubes, we need more snap distance
			var effective_snap_dist = snap_distance + (my_size.length() + other_size.length()) * 0.25
			var face_dist = my_face_center.distance_to(other_face_center)
			if face_dist > effective_snap_dist:
				continue

			# Found a valid alignment!
			print("FaceSnapSystem: ALIGNED! Face %d -> %s face %d (dist=%.3f)" % [my_face, other_cube.name, other_face, face_dist])

			# Check if faces are aligned (projecting one onto other's plane)
			var to_other = other_face_center - my_face_center
			var along_normal = abs(to_other.dot(my_world_normal))

			# Faces are close and parallel
			var is_grid_aligned = _check_grid_alignment(my_face_center, other_face_center, my_world_normal)

			return {
				"my_face": my_face,
				"other_face": other_face,
				"other_cube": other_cube,
				"is_aligned": is_grid_aligned,
				"my_face_center": my_face_center,
				"other_face_center": other_face_center,
				"normal": my_world_normal
			}

	return null


func _check_grid_alignment(my_center: Vector3, other_center: Vector3, normal: Vector3) -> bool:
	# Project both centers onto the plane perpendicular to normal
	# Check if they align on grid
	var tangent1 = normal.cross(Vector3.UP).normalized()
	if tangent1.length_squared() < 0.01:
		tangent1 = normal.cross(Vector3.RIGHT).normalized()
	var tangent2 = normal.cross(tangent1).normalized()

	var my_u = my_center.dot(tangent1)
	var my_v = my_center.dot(tangent2)
	var other_u = other_center.dot(tangent1)
	var other_v = other_center.dot(tangent2)

	# Check if difference is close to grid multiple
	var du = fmod(abs(my_u - other_u), GRID_SIZE)
	var dv = fmod(abs(my_v - other_v), GRID_SIZE)

	# Allow some tolerance
	var tolerance = GRID_SIZE * 0.2
	var u_aligned = du < tolerance or du > (GRID_SIZE - tolerance)
	var v_aligned = dv < tolerance or dv > (GRID_SIZE - tolerance)

	return u_aligned and v_aligned


func _find_best_snap() -> Variant:
	for other_cube in _nearby_cubes:
		var alignment = _check_cube_alignment(other_cube)
		if alignment:
			# Calculate snapped position
			var snap_pos = _calculate_snap_position(
				alignment.my_face_center,
				alignment.other_face_center,
				alignment.normal,
				alignment.my_face,
				alignment.other_face,
				other_cube
			)

			return {
				"cube": other_cube,
				"my_face": alignment.my_face,
				"other_face": alignment.other_face,
				"snap_pos": snap_pos
			}

	return null


func _calculate_snap_position(my_center: Vector3, other_center: Vector3, normal: Vector3, my_face: int, other_face: int, other_cube: Node3D) -> Vector3:
	# The goal: position my cube so that my_face touches other_face
	#
	# Strategy:
	# 1. My face should be positioned so its center is directly adjacent to other face center
	# 2. The distance between cube centers along the normal should equal the sum of half-extents

	var my_size = _get_cube_size(_parent_cube)
	var other_size = _get_cube_size(other_cube)

	# Get half-extents along the face normals
	var my_half = _get_face_extent(my_face, my_size)
	var other_half = _get_face_extent(other_face, other_size)

	# The other cube's face center in world space
	var other_face_world = other_center

	# My cube center should be positioned so my face touches the other face
	# My face center = my cube center + (face normal * half extent)
	# For faces to touch: my_face_center = other_face_center
	# But we're the one moving, so: my_cube_center = other_face_center - (my_face_normal * my_half)

	# Get my face normal in world space
	var my_normal_world = _parent_cube.global_transform.basis * _get_face_normal(my_face)

	# Target position: other face center, then back off by my half-extent
	var target_center = other_face_world - my_normal_world * my_half

	# Optional: snap to grid on the tangent plane (for alignment)
	var tangent1 = my_normal_world.cross(Vector3.UP).normalized()
	if tangent1.length_squared() < 0.01:
		tangent1 = my_normal_world.cross(Vector3.RIGHT).normalized()
	var tangent2 = my_normal_world.cross(tangent1).normalized()

	# Project target onto grid
	var u = target_center.dot(tangent1)
	var v = target_center.dot(tangent2)
	var snapped_u = round(u / GRID_SIZE) * GRID_SIZE
	var snapped_v = round(v / GRID_SIZE) * GRID_SIZE

	# Apply grid snapping to tangent components only
	var along_normal = target_center.dot(my_normal_world)
	var snapped_pos = tangent1 * snapped_u + tangent2 * snapped_v + my_normal_world * along_normal

	print("FaceSnapSystem: Snap calc - my_half=%.3f, other_half=%.3f, target=%s" % [my_half, other_half, snapped_pos])

	return snapped_pos


func _perform_snap(other_cube: Node3D, my_face: int, other_face: int, snap_pos: Vector3) -> void:
	_snapped_to = other_cube
	_snapped_my_face = my_face
	_snapped_other_face = other_face

	# Move to snapped position first
	_parent_cube.global_position = snap_pos

	# Stop any motion
	if _parent_cube is RigidBody3D:
		var rb = _parent_cube as RigidBody3D
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO

	# Create a rigid physics joint to connect the cubes
	_create_snap_joint(other_cube)

	face_snapped.emit(other_cube, my_face, other_face)
	print("FaceSnapSystem: Snapped %s to %s using physics joint" % [_parent_cube.name, other_cube.name])


## Create a locked physics joint between this cube and another
func _create_snap_joint(other_cube: Node3D) -> void:
	# Remove any existing joint
	if _snap_joint and is_instance_valid(_snap_joint):
		_snap_joint.queue_free()
		_snap_joint = null

	# Both must be RigidBody3D for joint to work
	if not (_parent_cube is RigidBody3D and other_cube is RigidBody3D):
		print("FaceSnapSystem: Cannot create joint - both objects must be RigidBody3D")
		return

	# Create a Generic6DOFJoint3D with all axes locked
	_snap_joint = Generic6DOFJoint3D.new()
	_snap_joint.name = "SnapJoint_%s_to_%s" % [_parent_cube.name, other_cube.name]

	# Set the two bodies to connect
	_snap_joint.node_a = other_cube.get_path()
	_snap_joint.node_b = _parent_cube.get_path()

	# Lock all linear axes (no sliding)
	_snap_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	_snap_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	_snap_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)

	# Lock all angular axes (no rotation)
	_snap_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	_snap_joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	_snap_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	_snap_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)

	# Add to scene tree FIRST (required before setting global_position)
	_parent_cube.add_child(_snap_joint)

	# Now set position (midpoint between cube centers)
	_snap_joint.global_position = (_parent_cube.global_position + other_cube.global_position) / 2.0

	print("FaceSnapSystem: Created physics joint between %s and %s" % [_parent_cube.name, other_cube.name])


func _break_snap() -> void:
	if _snapped_to:
		# Remove the physics joint
		if _snap_joint and is_instance_valid(_snap_joint):
			_snap_joint.queue_free()
			_snap_joint = null
			print("FaceSnapSystem: Removed physics joint from %s" % _parent_cube.name)

		face_unsnapped.emit(_snapped_to)
		_snapped_to = null
		_snapped_my_face = -1
		_snapped_other_face = -1


func _show_grid_on_face(face_dir: int, is_aligned: bool) -> void:
	if not show_grid_overlay:
		return

	# Create grid overlay if needed
	if not _grid_overlays.has(face_dir):
		_create_grid_overlay(face_dir)

	var overlay = _grid_overlays[face_dir]
	overlay.visible = true

	# Update color based on alignment
	var mat = overlay.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = snapped_color if is_aligned else grid_color
		mat.emission = snapped_color if is_aligned else grid_color


func _hide_all_grids() -> void:
	for overlay in _grid_overlays.values():
		if is_instance_valid(overlay):
			overlay.visible = false


func _show_other_face_highlight(other_cube: Node3D, face_dir: int, face_center: Vector3, is_aligned: bool) -> void:
	# Create highlight if needed
	if not _other_face_highlight:
		_other_face_highlight = MeshInstance3D.new()
		_other_face_highlight.name = "OtherFaceHighlight"

		var mesh = PlaneMesh.new()
		mesh.size = Vector2(0.2, 0.2)
		_other_face_highlight.mesh = mesh

		var mat = StandardMaterial3D.new()
		mat.albedo_color = grid_color
		mat.emission_enabled = true
		mat.emission = grid_color
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.no_depth_test = true  # Always visible
		_other_face_highlight.material_override = mat

		# Add to scene root so it's not affected by cube transforms
		get_tree().root.add_child(_other_face_highlight)

	# Update position and orientation
	var other_size = _get_cube_size(other_cube)
	var normal = _get_face_normal(face_dir)
	var world_normal = other_cube.global_transform.basis * normal

	# Position at face center, slightly offset outward
	_other_face_highlight.global_position = face_center + world_normal * 0.005

	# Orient to face outward (look_at the point behind the face)
	var look_target = face_center + world_normal
	if world_normal.abs() != Vector3.UP:
		_other_face_highlight.look_at(look_target, Vector3.UP)
	else:
		_other_face_highlight.look_at(look_target, Vector3.FORWARD)
	# Rotate 90 degrees since PlaneMesh faces +Y by default
	_other_face_highlight.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

	# Update size to match face
	var face_size = _get_face_size(face_dir, other_size)
	if _other_face_highlight.mesh is PlaneMesh:
		_other_face_highlight.mesh.size = Vector2(face_size.x * 1.05, face_size.y * 1.05)  # Slightly larger

	# Update color based on alignment
	var mat = _other_face_highlight.material_override as StandardMaterial3D
	if mat:
		var color = snapped_color if is_aligned else grid_color
		mat.albedo_color = color
		mat.emission = Color(color.r, color.g, color.b, 1.0)

	_other_face_highlight.visible = true


func _hide_other_face_highlight() -> void:
	if _other_face_highlight:
		_other_face_highlight.visible = false


func _create_grid_overlay(face_dir: int) -> void:
	var overlay = MeshInstance3D.new()
	overlay.name = "GridOverlay_%d" % face_dir

	# Create a simple quad mesh for the face
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(0.1, 0.1)  # Will be updated based on cube size
	overlay.mesh = mesh

	# Material with bright, visible appearance
	var mat = StandardMaterial3D.new()
	mat.albedo_color = grid_color
	mat.emission_enabled = true
	mat.emission = Color(grid_color.r, grid_color.g, grid_color.b, 1.0)
	mat.emission_energy_multiplier = 2.0  # Brighter glow
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true  # Always visible through geometry
	overlay.material_override = mat

	# Position on face
	_update_grid_overlay_transform(overlay, face_dir)

	overlay.visible = false
	add_child(overlay)
	_grid_overlays[face_dir] = overlay


func _update_grid_overlay_transform(overlay: MeshInstance3D, face_dir: int) -> void:
	var size = _get_cube_size(_parent_cube)
	var normal = _get_face_normal(face_dir)

	# Position at face center
	var face_offset = Vector3(
		normal.x * size.x * 0.5,
		normal.y * size.y * 0.5,
		normal.z * size.z * 0.5
	)
	overlay.position = face_offset + normal * 0.001  # Slight offset to avoid z-fighting

	# Rotate to face outward
	match face_dir:
		0: overlay.rotation_degrees = Vector3(0, 0, -90)   # +X
		1: overlay.rotation_degrees = Vector3(0, 0, 90)    # -X
		2: overlay.rotation_degrees = Vector3(0, 0, 0)     # +Y (default plane orientation)
		3: overlay.rotation_degrees = Vector3(180, 0, 0)   # -Y
		4: overlay.rotation_degrees = Vector3(90, 0, 0)    # +Z
		5: overlay.rotation_degrees = Vector3(-90, 0, 0)   # -Z

	# Update mesh size to match face
	var face_size = _get_face_size(face_dir, size)
	if overlay.mesh is PlaneMesh:
		overlay.mesh.size = Vector2(face_size.x, face_size.y)


## Static helper: Get face normal for a direction
static func _get_face_normal(face_dir: int) -> Vector3:
	match face_dir:
		0: return Vector3(1, 0, 0)   # +X (right)
		1: return Vector3(-1, 0, 0)  # -X (left)
		2: return Vector3(0, 1, 0)   # +Y (up)
		3: return Vector3(0, -1, 0)  # -Y (down)
		4: return Vector3(0, 0, 1)   # +Z (back in Godot's convention)
		5: return Vector3(0, 0, -1)  # -Z (forward in Godot's convention)
	return Vector3(0, 1, 0)


## Get cube size from mesh or collision shape
## For scalable cubes, the mesh/collision size IS the actual size (not using node.scale)
static func _get_cube_size(cube: Node3D) -> Vector3:
	# First try the get_scale_vector method (for our scalable cubes)
	if cube.has_method("get_scale_vector"):
		var scale_vec = cube.get_scale_vector()
		# Our scalable cubes use 0.1 as base size
		return scale_vec * 0.1

	# Try to get from mesh (this should have the actual scaled size)
	var mesh_instance = cube.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		return mesh_instance.mesh.size

	# Try collision shape
	var collision = cube.get_node_or_null("CollisionShape3D")
	if collision and collision.shape is BoxShape3D:
		return collision.shape.size

	# Default
	return Vector3(0.1, 0.1, 0.1)


## Get face center in world space
static func _get_face_center(cube: Node3D, face_dir: int, size: Vector3) -> Vector3:
	var normal = _get_face_normal(face_dir)
	var local_offset = Vector3(
		normal.x * size.x * 0.5,
		normal.y * size.y * 0.5,
		normal.z * size.z * 0.5
	)
	return cube.global_transform * local_offset


## Get face extent (half-size along normal)
static func _get_face_extent(face_dir: int, size: Vector3) -> float:
	match face_dir:
		0, 1: return size.x * 0.5
		2, 3: return size.y * 0.5
		4, 5: return size.z * 0.5
	return 0.05


## Get face size (2D dimensions of the face)
static func _get_face_size(face_dir: int, size: Vector3) -> Vector2:
	match face_dir:
		0, 1: return Vector2(size.z, size.y)  # X faces: Z width, Y height
		2, 3: return Vector2(size.x, size.z)  # Y faces: X width, Z height
		4, 5: return Vector2(size.x, size.y)  # Z faces: X width, Y height
	return Vector2(0.1, 0.1)


## Check if currently snapped
func is_snapped() -> bool:
	return _snapped_to != null


## Get snapped cube
func get_snapped_cube() -> Node3D:
	return _snapped_to
