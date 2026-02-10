extends CharacterBody3D
class_name TentacleCube
## Stationary machine cube that unfolds mechanical tentacles when player approaches.
## Uses Godot 4.6 IK for tentacle tracking. Dormant cube â†’ unfolds â†’ tracks player.

signal enemy_destroyed(enemy: Node3D)
signal tentacle_strike(position: Vector3)

enum State { DORMANT, UNFOLDING, ACTIVE, RETRACTING, DEAD }

@export_group("Geometry")
@export var cube_size: float = 0.4
@export var tentacle_count: int = 4
@export var segments_per_tentacle: int = 4
@export var segment_length: float = 0.15
@export var segment_radius: float = 0.025
@export var joint_radius: float = 0.035

@export_group("Combat")
@export var max_health: float = 100.0
@export var detection_radius: float = 4.0
@export var retract_radius: float = 6.0
@export var strike_damage: float = 15.0
@export var strike_range: float = 1.2

@export_group("Timing")
@export var unfold_duration: float = 1.2
@export var retract_duration: float = 0.8
@export var idle_sway_speed: float = 1.5
@export var track_speed: float = 4.0

@export_group("Appearance")
@export var cube_color: Color = Color(0.12, 0.12, 0.15, 1.0)
@export var segment_color: Color = Color(0.2, 0.2, 0.25, 1.0)
@export var joint_color: Color = Color(0.08, 0.08, 0.1, 1.0)
@export var emission_color: Color = Color(1.0, 0.4, 0.15, 1.0)
@export var emission_intensity: float = 2.0

# State
var _health: float = 0.0
var _state: State = State.DORMANT
var _state_time: float = 0.0
var _unfold_progress: float = 0.0  # 0 = folded, 1 = unfolded
var _player_node: Node3D = null

# Geometry
var _cube_mesh: MeshInstance3D = null
var _skeleton: Skeleton3D = null
var _tentacle_meshes: Array[Array] = []  # [tentacle_idx][segment_idx]
var _joint_meshes: Array[Array] = []
var _ik_targets: Array[Marker3D] = []
var _tip_positions: Array[Vector3] = []  # Current tip world positions

# Bone indices per tentacle
var _bone_indices: Array[Array] = []  # [tentacle_idx][segment_idx] = bone_idx

# Materials
var _cube_material: StandardMaterial3D
var _segment_material: StandardMaterial3D
var _joint_material: StandardMaterial3D

# Fold data - where each tentacle folds to on the cube
var _fold_directions: Array[Vector3] = []
var _fold_rotations: Array[Basis] = []


func _ready() -> void:
	_health = max_health
	_create_materials()
	_calculate_fold_positions()
	_build_collision()
	_build_cube()
	_build_skeleton()
	_build_tentacle_meshes()
	_apply_fold_pose()
	_find_player()
	add_to_group("enemy")
	add_to_group("tentacle_enemy")
	print("TentacleCube: READY at %s with %d tentacles" % [global_position, tentacle_count])


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.DORMANT:
			_process_dormant(delta)
		State.UNFOLDING:
			_process_unfolding(delta)
		State.ACTIVE:
			_process_active(delta)
		State.RETRACTING:
			_process_retracting(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_tentacle_visuals()


# === STATE PROCESSORS ===

func _process_dormant(_delta: float) -> void:
	var dist := _get_player_distance()
	if dist <= detection_radius and dist > 0:
		_set_state(State.UNFOLDING)


func _process_unfolding(_delta: float) -> void:
	var t: float = clampf(_state_time / unfold_duration, 0.0, 1.0)
	
	# Elastic ease out for dramatic unfold
	_unfold_progress = _ease_out_elastic(t)
	
	_apply_unfold_pose(_unfold_progress)
	
	if t >= 1.0:
		_set_state(State.ACTIVE)


func _process_active(delta: float) -> void:
	var dist := _get_player_distance()
	
	# Check if player left
	if dist > retract_radius or dist <= 0:
		_set_state(State.RETRACTING)
		return
	
	# Track player with tentacles
	_track_player(delta)
	
	# Idle sway on top of tracking
	_apply_idle_sway(delta)
	
	# Check for strike range
	if dist <= strike_range:
		_attempt_strike()


func _process_retracting(_delta: float) -> void:
	var t: float = clampf(_state_time / retract_duration, 0.0, 1.0)
	
	# Smooth retract
	_unfold_progress = lerpf(1.0, 0.0, ease(t, 0.3))
	
	_apply_unfold_pose(_unfold_progress)
	
	if t >= 1.0:
		_set_state(State.DORMANT)


func _process_dead(_delta: float) -> void:
	# Collapse animation
	if _state_time < 2.0:
		_unfold_progress = lerp(_unfold_progress, 0.0, 0.1)
		_apply_unfold_pose(_unfold_progress)
		
		# Fade emission
		if _joint_material:
			_joint_material.emission_energy_multiplier = lerp(
				emission_intensity, 0.0, _state_time / 2.0
			)


func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	
	var old_state := _state
	_state = new_state
	_state_time = 0.0
	
	match new_state:
		State.UNFOLDING:
			# Play unfold sound
			_play_servo_sound()
		State.ACTIVE:
			# Enable glow
			if _joint_material:
				_joint_material.emission_energy_multiplier = emission_intensity
		State.RETRACTING:
			_play_servo_sound()
		State.DEAD:
			emit_signal("enemy_destroyed", self)
	
	print("TentacleCube: %s â†’ %s" % [State.keys()[old_state], State.keys()[new_state]])


# === GEOMETRY BUILDING ===

func _create_materials() -> void:
	# Cube body - dark metallic
	_cube_material = StandardMaterial3D.new()
	_cube_material.albedo_color = cube_color
	_cube_material.metallic = 0.85
	_cube_material.roughness = 0.25
	
	# Tentacle segments - slightly lighter
	_segment_material = StandardMaterial3D.new()
	_segment_material.albedo_color = segment_color
	_segment_material.metallic = 0.9
	_segment_material.roughness = 0.2
	
	# Joints - emissive
	_joint_material = StandardMaterial3D.new()
	_joint_material.albedo_color = joint_color
	_joint_material.metallic = 0.95
	_joint_material.roughness = 0.15
	_joint_material.emission_enabled = true
	_joint_material.emission = emission_color
	_joint_material.emission_energy_multiplier = 0.0  # Off when dormant


func _calculate_fold_positions() -> void:
	# Each tentacle folds onto a different face of the cube
	# Distribute around the top/sides
	_fold_directions.clear()
	_fold_rotations.clear()
	
	for i in range(tentacle_count):
		var angle := TAU * i / tentacle_count
		var dir := Vector3(cos(angle), 0.3, sin(angle)).normalized()
		_fold_directions.append(dir)
		
		# Rotation to fold flat against cube face
		var fold_basis := Basis.looking_at(-dir, Vector3.UP)
		_fold_rotations.append(fold_basis)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * cube_size
	collision.shape = shape
	add_child(collision)


func _build_cube() -> void:
	_cube_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * cube_size
	_cube_mesh.mesh = box
	_cube_mesh.material_override = _cube_material
	add_child(_cube_mesh)


func _build_skeleton() -> void:
	_skeleton = Skeleton3D.new()
	_skeleton.name = "TentacleSkeleton"
	add_child(_skeleton)
	
	_bone_indices.clear()
	
	for t in range(tentacle_count):
		var tentacle_bones: Array[int] = []
		var parent_idx := -1
		
		# Root bone at cube surface
		var root_pos := _fold_directions[t] * (cube_size * 0.5)
		var root_name := "tentacle_%d_root" % t
		var root_idx := _skeleton.get_bone_count()
		_skeleton.add_bone(root_name)
		_skeleton.set_bone_parent(root_idx, parent_idx)
		_skeleton.set_bone_rest(root_idx, Transform3D(Basis.IDENTITY, root_pos))
		tentacle_bones.append(root_idx)
		parent_idx = root_idx
		
		# Segment bones
		for s in range(segments_per_tentacle):
			var seg_name := "tentacle_%d_seg_%d" % [t, s]
			var seg_idx := _skeleton.get_bone_count()
			_skeleton.add_bone(seg_name)
			_skeleton.set_bone_parent(seg_idx, parent_idx)
			# Each segment extends outward
			var seg_transform := Transform3D(Basis.IDENTITY, Vector3(0, segment_length, 0))
			_skeleton.set_bone_rest(seg_idx, seg_transform)
			tentacle_bones.append(seg_idx)
			parent_idx = seg_idx
		
		_bone_indices.append(tentacle_bones)
	
	_skeleton.reset_bone_poses()


func _build_tentacle_meshes() -> void:
	_tentacle_meshes.clear()
	_joint_meshes.clear()
	_tip_positions.clear()
	
	for t in range(tentacle_count):
		var seg_meshes: Array[MeshInstance3D] = []
		var jnt_meshes: Array[MeshInstance3D] = []
		
		for s in range(segments_per_tentacle):
			# Segment cylinder
			var seg_mesh := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = segment_radius
			cyl.bottom_radius = segment_radius * 1.1  # Slight taper
			cyl.height = segment_length
			seg_mesh.mesh = cyl
			seg_mesh.material_override = _segment_material
			_skeleton.add_child(seg_mesh)
			seg_meshes.append(seg_mesh)
			
			# Joint sphere
			var jnt_mesh := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = joint_radius
			sphere.height = joint_radius * 2
			jnt_mesh.mesh = sphere
			jnt_mesh.material_override = _joint_material
			_skeleton.add_child(jnt_mesh)
			jnt_meshes.append(jnt_mesh)
		
		_tentacle_meshes.append(seg_meshes)
		_joint_meshes.append(jnt_meshes)
		_tip_positions.append(Vector3.ZERO)


func _apply_fold_pose() -> void:
	_apply_unfold_pose(0.0)


func _apply_unfold_pose(progress: float) -> void:
	# Progress: 0 = fully folded, 1 = fully extended
	for t in range(tentacle_count):
		var bones = _bone_indices[t]  # Array of bone indices
		var fold_dir: Vector3 = _fold_directions[t]
		
		for s in range(bones.size()):
			var bone_idx: int = bones[s]
			var rest := _skeleton.get_bone_rest(bone_idx)
			var pose := rest
			
			if s == 0:
				# Root bone - rotate from folded to upward
				var folded_basis: Basis = _fold_rotations[t]
				var upward_basis: Basis = Basis.looking_at(Vector3.UP, -fold_dir)
				pose.basis = folded_basis.slerp(upward_basis, progress)
			else:
				# Segment bones - unfold from 180Â° to straight
				var fold_angle := PI * (1.0 - progress)
				pose.basis = Basis(Vector3.RIGHT, fold_angle)
			
			_skeleton.set_bone_pose(bone_idx, pose)


func _update_tentacle_visuals() -> void:
	# Position meshes to match skeleton bones
	for t in range(tentacle_count):
		var bones = _bone_indices[t]  # Array of bone indices
		
		for s in range(segments_per_tentacle):
			var bone_idx: int = bones[s + 1]  # Skip root
			var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_idx)
			
			# Segment mesh
			var seg_mesh: MeshInstance3D = _tentacle_meshes[t][s]
			seg_mesh.global_transform = bone_global
			# Offset to center the cylinder on the bone
			seg_mesh.position -= seg_mesh.basis.y * (segment_length * 0.5)
			
			# Joint mesh at bone origin
			var jnt_mesh: MeshInstance3D = _joint_meshes[t][s]
			jnt_mesh.global_transform.origin = bone_global.origin
		
		# Track tip position
		var tip_bone: int = bones[-1]
		var tip_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(tip_bone)
		_tip_positions[t] = tip_global.origin + tip_global.basis.y * segment_length


# === BEHAVIOR ===

func _track_player(delta: float) -> void:
	if not is_instance_valid(_player_node):
		return
	
	var player_pos := _player_node.global_position
	
	for t in range(tentacle_count):
		var bones = _bone_indices[t]  # Array of bone indices
		var tip_pos: Vector3 = _tip_positions[t]
		
		# Direction from tip to player
		var to_player := (player_pos - tip_pos).normalized()
		
		# Rotate the last segment toward player
		var tip_bone: int = bones[-1]
		var current_pose := _skeleton.get_bone_pose(tip_bone)
		
		# Calculate desired rotation
		var current_dir := current_pose.basis.y
		var rotation_axis := current_dir.cross(to_player).normalized()
		if rotation_axis.length() > 0.01:
			var angle := current_dir.angle_to(to_player)
			var max_rotate := track_speed * delta
			angle = clamp(angle, -max_rotate, max_rotate)
			var delta_basis := Basis(rotation_axis, angle)
			current_pose.basis = delta_basis * current_pose.basis
			_skeleton.set_bone_pose(tip_bone, current_pose)


func _apply_idle_sway(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001 * idle_sway_speed
	
	for t in range(tentacle_count):
		var bones = _bone_indices[t]  # Array of bone indices
		
		# Apply subtle sway to middle segments
		for s in range(1, bones.size() - 1):
			var bone_idx: int = bones[s]
			var pose := _skeleton.get_bone_pose(bone_idx)
			
			var sway_x := sin(time + t * 1.3 + s * 0.7) * 0.08
			var sway_z := cos(time * 0.8 + t * 2.1 + s * 0.5) * 0.06
			
			var sway_basis := Basis(Vector3.RIGHT, sway_x) * Basis(Vector3.FORWARD, sway_z)
			pose.basis = sway_basis * pose.basis
			_skeleton.set_bone_pose(bone_idx, pose)


func _attempt_strike() -> void:
	# TODO: Implement strike attack
	# For now just emit signal
	if randf() < 0.01:  # Rate limit
		var closest_tip := _tip_positions[0]
		emit_signal("tentacle_strike", closest_tip)


# === DAMAGE ===

func take_damage(amount: float, _from_position: Vector3 = Vector3.ZERO) -> void:
	if _state == State.DEAD:
		return
	
	_health -= amount
	
	# Flash emission on damage
	if _joint_material:
		_joint_material.emission_energy_multiplier = emission_intensity * 2.0
		var tween := create_tween()
		tween.tween_property(_joint_material, "emission_energy_multiplier", 
			emission_intensity, 0.3)
	
	if _health <= 0:
		_set_state(State.DEAD)


# === UTILITIES ===

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_node = players[0]
	else:
		# Try XR camera
		var cameras := get_tree().get_nodes_in_group("xr_camera")
		if cameras.size() > 0:
			_player_node = cameras[0]


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return -1.0
	return global_position.distance_to(_player_node.global_position)


func _ease_out_elastic(t: float) -> float:
	if t <= 0:
		return 0.0
	if t >= 1:
		return 1.0
	var p := 0.4
	return pow(2, -10 * t) * sin((t - p / 4) * TAU / p) + 1.0


func _play_servo_sound() -> void:
	# TODO: Add AudioStreamPlayer3D with servo whir
	pass
