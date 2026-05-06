@tool
extends Node3D
class_name FoldingCube

# @identity
# essence: 6 square faces arranged in a cross net rotate around hinge axes — fold_progress (0→1) interpolates each face from its flat position to its final cube orientation; on complete, optionally drops as a RigidBody3D and spawns a fresh net
# desire: to make the learner feel the moment when a flat shape becomes a volume — when 2D possibility collapses into 3D fact and you watch the final edge close
# critical_parameter: fold_duration (2.0s) — controls the pace of the fold; too fast and the hinge animation is illegible; the spawn_new_on_complete flag creates an infinite folding stack
# triggers: animate_fold() sets state FOLDING and runs a Tween; fold_progress setter drives _apply_fold() each step; on completion, face converts to RigidBody3D and drops by drop_height
# emerges: the stack of dropped cubes accumulates as evidence of all previous folds — the floor becomes a record of learning, each cube identical in shape but distinct in its moment of closure
# needs: VR trigger to start fold animation [has via auto_fold]; fold_progress slider [has in editor via @export_range]; audio on fold-complete [missing]; VR grab of completed cube [has via RigidBody3D conversion]
# relationships: used in Point_Animatedcube alongside animatedcubebuilder; pairs with polyhedron_nets_cube (shows net layout) and grab_trihedron (corner assembly); contrasts with instant-geometry primitives
# truth: a net is a cube that hasn't decided yet — fold_progress is the variable that transforms possibility into fact, and that transformation is irreversible

## Folding Cube - Animates from flat net to 3D cube
## Shows how 6 squares with hinges become a volume
## Interactive or automatic folding

signal fold_started
signal fold_completed
signal fold_progress_changed(progress: float)

enum FoldState { FLAT, FOLDING, FOLDED, UNFOLDING }

@export var face_size: float = 0.35:  # Smaller for stacking
	set(v):
		face_size = v
		_rebuild()

@export var face_thickness: float = 0.02:
	set(v):
		face_thickness = v
		_rebuild()

@export var face_gap: float = 0.01:
	set(v):
		face_gap = v
		_rebuild()

@export var face_color: Color = Color(0.9, 0.85, 0.8, 1.0):
	set(v):
		face_color = v
		_update_materials()

@export var hinge_color: Color = Color(0.3, 0.3, 0.35, 1.0):
	set(v):
		hinge_color = v
		_update_materials()

@export var fold_duration: float = 2.0

@export_range(0.0, 1.0) var fold_progress: float = 0.0:
	set(v):
		fold_progress = clamp(v, 0.0, 1.0)
		_apply_fold()
		fold_progress_changed.emit(fold_progress)

@export var auto_fold: bool = false:
	set(v):
		auto_fold = v
		if auto_fold and _state == FoldState.FLAT:
			animate_fold()

@export var convert_to_rigidbody: bool = true  # Convert to physics object after folding
@export var spawn_new_on_complete: bool = true  # Spawn a new folding cube for stacking
@export var drop_height: float = 0.3  # How high above the fold position to drop from

var _state: FoldState = FoldState.FLAT
var _spawned_cubes: Array[RigidBody3D] = []  # Track spawned rigid cubes
var _faces: Dictionary = {}  # name -> MeshInstance3D
var _hinges: Dictionary = {}  # name -> Node3D (pivot point)
var _material: StandardMaterial3D
var _tween: Tween

# Face arrangement (cross net):
#        [top]
# [left][front][right][back]
#       [bottom]

const FACE_NAMES = ["front", "back", "left", "right", "top", "bottom"]

func _ready() -> void:
	_create_material()
	_rebuild()
	if auto_fold:
		animate_fold()

func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = face_color

func _update_materials() -> void:
	if _material:
		_material.albedo_color = face_color
	for face in _faces.values():
		if face and face.material_override:
			face.material_override.albedo_color = face_color

func _rebuild() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	_faces.clear()
	_hinges.clear()
	
	# Create the net structure with hinge pivots
	_create_net()

func _create_net() -> void:
	var half = face_size / 2.0
	var full = face_size + face_gap
	
	# Front face - the center/base (no hinge, stays flat)
	_faces["front"] = _create_face("front", Vector3(0, face_thickness/2, 0))
	add_child(_faces["front"])
	
	# Create hinged faces
	# Each hinge is a pivot point at the edge where faces connect
	
	# TOP - hinges at front's +Z edge
	var top_hinge = Node3D.new()
	top_hinge.name = "TopHinge"
	top_hinge.position = Vector3(0, face_thickness/2, half)
	add_child(top_hinge)
	_hinges["top"] = top_hinge
	
	var top_face = _create_face("top", Vector3(0, 0, half + face_gap/2))
	top_hinge.add_child(top_face)
	_faces["top"] = top_face
	
	# BOTTOM - hinges at front's -Z edge
	var bottom_hinge = Node3D.new()
	bottom_hinge.name = "BottomHinge"
	bottom_hinge.position = Vector3(0, face_thickness/2, -half)
	add_child(bottom_hinge)
	_hinges["bottom"] = bottom_hinge
	
	var bottom_face = _create_face("bottom", Vector3(0, 0, -half - face_gap/2))
	bottom_hinge.add_child(bottom_face)
	_faces["bottom"] = bottom_face
	
	# LEFT - hinges at front's -X edge
	var left_hinge = Node3D.new()
	left_hinge.name = "LeftHinge"
	left_hinge.position = Vector3(-half, face_thickness/2, 0)
	add_child(left_hinge)
	_hinges["left"] = left_hinge
	
	var left_face = _create_face("left", Vector3(-half - face_gap/2, 0, 0))
	left_hinge.add_child(left_face)
	_faces["left"] = left_face
	
	# RIGHT - hinges at front's +X edge
	var right_hinge = Node3D.new()
	right_hinge.name = "RightHinge"
	right_hinge.position = Vector3(half, face_thickness/2, 0)
	add_child(right_hinge)
	_hinges["right"] = right_hinge
	
	var right_face = _create_face("right", Vector3(half + face_gap/2, 0, 0))
	right_hinge.add_child(right_face)
	_faces["right"] = right_face
	
	# BACK - hinges at right's +X edge (folds from right side)
	# Back is special - it's connected to right, not front
	var back_hinge = Node3D.new()
	back_hinge.name = "BackHinge"
	back_hinge.position = Vector3(half + face_gap/2, 0, 0)  # At right edge of right face
	right_face.add_child(back_hinge)
	_hinges["back"] = back_hinge
	
	var back_face = _create_face("back", Vector3(half + face_gap/2, 0, 0))
	back_hinge.add_child(back_face)
	_faces["back"] = back_face

func _create_face(face_name: String, local_pos: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = face_name.capitalize() + "Face"
	
	var box = BoxMesh.new()
	box.size = Vector3(face_size, face_thickness, face_size)
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = face_color
	mesh_instance.material_override = mat
	
	mesh_instance.position = local_pos
	
	return mesh_instance

func _apply_fold() -> void:
	if _hinges.is_empty():
		return
	
	var angle = fold_progress * PI / 2.0  # 0 to 90 degrees
	
	# Top folds up (rotate around X axis, negative direction)
	if _hinges.has("top"):
		_hinges["top"].rotation.x = -angle
	
	# Bottom folds up (rotate around X axis, positive direction)
	if _hinges.has("bottom"):
		_hinges["bottom"].rotation.x = angle
	
	# Left folds up (rotate around Z axis, positive direction)
	if _hinges.has("left"):
		_hinges["left"].rotation.z = angle
	
	# Right folds up (rotate around Z axis, negative direction)
	if _hinges.has("right"):
		_hinges["right"].rotation.z = -angle
	
	# Back folds from right - needs to tuck UNDER to complete the cube
	# Back is a child of right, so it inherits right's 90° rotation
	# Back then needs its OWN additional 90° rotation to close the cube
	# The back hinge rotates around Z-axis (same direction as right)
	if _hinges.has("back"):
		# Ease the back fold to start slightly after right begins folding
		# This creates the "tucking under" effect
		var back_progress = clamp((fold_progress - 0.2) / 0.8, 0.0, 1.0)
		var back_angle = back_progress * PI / 2.0
		_hinges["back"].rotation.z = -back_angle  # Tucks under as the cube closes

# Public API

func animate_fold(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fold_duration
	
	if _tween:
		_tween.kill()
	
	_state = FoldState.FOLDING
	fold_started.emit()
	
	_tween = create_tween()
	_tween.tween_property(self, "fold_progress", 1.0, duration)
	_tween.tween_callback(_on_fold_complete)

func animate_unfold(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fold_duration
	
	if _tween:
		_tween.kill()
	
	_state = FoldState.UNFOLDING
	
	_tween = create_tween()
	_tween.tween_property(self, "fold_progress", 0.0, duration)
	_tween.tween_callback(_on_unfold_complete)

func toggle_fold() -> void:
	match _state:
		FoldState.FLAT:
			animate_fold()
		FoldState.FOLDED:
			animate_unfold()
		FoldState.FOLDING:
			animate_unfold()
		FoldState.UNFOLDING:
			animate_fold()

func set_fold_instant(folded: bool) -> void:
	fold_progress = 1.0 if folded else 0.0
	_state = FoldState.FOLDED if folded else FoldState.FLAT

func _on_fold_complete() -> void:
	_state = FoldState.FOLDED
	fold_completed.emit()
	
	if convert_to_rigidbody:
		_convert_to_physics_cube()

func _on_unfold_complete() -> void:
	_state = FoldState.FLAT

func _convert_to_physics_cube() -> void:
	# Create a rigid body cube to replace the folded net
	var rigid_cube = RigidBody3D.new()
	rigid_cube.name = "FoldedCube_%d" % _spawned_cubes.size()
	
	# Create the cube mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(face_size, face_size, face_size)
	mesh_instance.mesh = box
	
	# Apply material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = face_color
	mesh_instance.material_override = mat
	rigid_cube.add_child(mesh_instance)
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(face_size, face_size, face_size)
	collision.shape = shape
	rigid_cube.add_child(collision)
	
	# Position the rigid cube at the folded location, slightly above
	var spawn_pos = global_position + Vector3(0, face_size/2 + drop_height, 0)
	rigid_cube.global_position = spawn_pos
	
	# Add to scene
	get_parent().add_child(rigid_cube)
	_spawned_cubes.append(rigid_cube)
	
	# Hide the folded net faces
	for face in _faces.values():
		if is_instance_valid(face):
			face.visible = false
	
	# Spawn a new folding cube if enabled
	if spawn_new_on_complete:
		await get_tree().create_timer(0.5).timeout
		_reset_for_next_fold()

func get_state() -> FoldState:
	return _state

func is_folded() -> bool:
	return _state == FoldState.FOLDED

func is_flat() -> bool:
	return _state == FoldState.FLAT

func _reset_for_next_fold() -> void:
	# Reset the folding cube for another fold cycle
	fold_progress = 0.0
	_state = FoldState.FLAT
	
	# Show faces again
	for face in _faces.values():
		if is_instance_valid(face):
			face.visible = true
	
	# Auto-start the next fold if enabled
	if auto_fold:
		await get_tree().create_timer(0.3).timeout
		animate_fold()

func get_spawned_cubes() -> Array[RigidBody3D]:
	return _spawned_cubes

func clear_spawned_cubes() -> void:
	for cube in _spawned_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	_spawned_cubes.clear()
