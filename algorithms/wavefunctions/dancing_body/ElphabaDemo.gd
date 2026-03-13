# ElphabaDemo - Demo scene combining rigged player with parametric wave dress
# Shows the dancing body with Elphaba's mathematical flowing gown

extends Node3D

@export var show_body: bool = true
@export var animate_bones: bool = true
@export var animation_speed: float = 1.0

@export_group("Dance Animation")
@export var arm_amplitude: float = 0.3
@export var body_sway: float = 0.1
@export var frequency: float = 1.0

var _player_model: Node3D
var _skeleton: Skeleton3D
var _dress: Node3D
var _time: float = 0.0

# Bone indices
var _bone_indices: Dictionary = {}

func _ready() -> void:
	_load_player_model()
	_setup_dress()

func _load_player_model() -> void:
	var player_scene = load("res://algorithms/wavefunctions/dancing_body/player.glb")
	if player_scene:
		_player_model = player_scene.instantiate()
		add_child(_player_model)
		print("ElphabaDemo: Player model loaded")

		# Find skeleton
		_skeleton = _find_skeleton(_player_model)

		if _skeleton:
			# Print ALL bone names so we know what's available
			print("ElphabaDemo: Skeleton found with %d bones:" % _skeleton.get_bone_count())
			for i in range(_skeleton.get_bone_count()):
				var bone_name = _skeleton.get_bone_name(i)
				print("  Bone %d: '%s'" % [i, bone_name])
				# Store all bones with lowercase key
				_bone_indices[bone_name.to_lower()] = i

			print("ElphabaDemo: Cached bone indices: ", _bone_indices.keys())
		else:
			print("ElphabaDemo: WARNING - No skeleton found in player model!")

		_update_body_visibility()
	else:
		print("ElphabaDemo: ERROR - Could not load player.glb!")

func _setup_dress() -> void:
	# Find the dress node that was instanced in the scene
	_dress = get_node_or_null("ElphabaDress")

	if _dress:
		print("ElphabaDemo: Dress node found at %s" % _dress.global_position)

		# IMPORTANT: Disable the dress's own skeleton following - we handle it here
		_dress.follow_skeleton = false
		print("ElphabaDemo: Disabled dress's internal skeleton following")

		if _skeleton:
			# Try to find hip-like bone for attachment
			var hip_bone_idx = _find_hip_bone()
			print("ElphabaDemo: Dress attached, hip bone index: %d" % hip_bone_idx)

			# Reparent dress to the skeleton so it moves with the player
			var old_global_pos = _dress.global_position
			_dress.get_parent().remove_child(_dress)
			_skeleton.add_child(_dress)

			# Position dress at hip bone using BoneAttachment3D-like positioning
			if hip_bone_idx >= 0:
				# Get hip bone position in skeleton local space
				var bone_pose = _skeleton.get_bone_global_pose(hip_bone_idx)
				_dress.transform = Transform3D(Basis.IDENTITY, bone_pose.origin)
				print("ElphabaDemo: Dress parented to skeleton at hip: %s" % bone_pose.origin)
			else:
				# Fallback - position at skeleton origin with offset
				_dress.position = Vector3(0, 1.0, 0)
				print("ElphabaDemo: Dress parented to skeleton at fallback position")
		else:
			# No skeleton - parent to player model
			if _player_model:
				_dress.get_parent().remove_child(_dress)
				_player_model.add_child(_dress)
				_dress.position = Vector3(0, 1.0, 0)
			print("ElphabaDemo: No skeleton, parented to player model")
	else:
		print("ElphabaDemo: WARNING - No ElphabaDress node found in scene!")

func _find_hip_bone() -> int:
	# Try various common hip bone names
	var hip_names = ["hips", "pelvis", "hip", "root", "spine", "spine.001", "mixamorig:hips"]
	for hip_name in hip_names:
		var idx = _bone_indices.get(hip_name.to_lower(), -1)
		if idx >= 0:
			print("ElphabaDemo: Using '%s' as hip bone" % hip_name)
			return idx
	return -1

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _update_body_visibility() -> void:
	if _player_model:
		# Find mesh instances and toggle visibility
		_set_mesh_visibility(_player_model, show_body)

func _set_mesh_visibility(node: Node, visible: bool) -> void:
	if node is MeshInstance3D:
		node.visible = visible
	for child in node.get_children():
		_set_mesh_visibility(child, visible)

func _process(delta: float) -> void:
	_time += delta * animation_speed

	if animate_bones and _skeleton:
		_apply_dance_animation()

	if _dress and _skeleton:
		_update_dress_position()

func _apply_dance_animation() -> void:
	# Animate arms in a flowing dance motion
	# Try multiple bone name variations

	# Left arm
	var l_arm_idx = _find_bone_by_names(["l-arm", "leftarm", "arm.l", "mixamorig:leftarm", "upper_arm.l"])
	if l_arm_idx >= 0:
		var pose = _skeleton.get_bone_pose(l_arm_idx)
		var sine_offset = sin(_time * frequency) * arm_amplitude
		pose.origin.y = sine_offset
		pose.origin.x = cos(_time * frequency) * arm_amplitude * 0.5
		_skeleton.set_bone_pose(l_arm_idx, pose)

	# Right arm (offset phase)
	var r_arm_idx = _find_bone_by_names(["r-arm", "rightarm", "arm.r", "mixamorig:rightarm", "upper_arm.r"])
	if r_arm_idx >= 0:
		var pose = _skeleton.get_bone_pose(r_arm_idx)
		var cosine_offset = cos(_time * frequency) * arm_amplitude
		pose.origin.y = cosine_offset
		pose.origin.x = -sin(_time * frequency) * arm_amplitude * 0.5
		_skeleton.set_bone_pose(r_arm_idx, pose)

	# Forearms
	var l_fore_idx = _find_bone_by_names(["l-forearm", "leftforearm", "forearm.l", "mixamorig:leftforearm", "lower_arm.l"])
	if l_fore_idx >= 0:
		var pose = _skeleton.get_bone_pose(l_fore_idx)
		pose.origin.z = sin(_time * frequency * 1.5) * arm_amplitude * 0.4
		_skeleton.set_bone_pose(l_fore_idx, pose)

	var r_fore_idx = _find_bone_by_names(["r-forearm", "rightforearm", "forearm.r", "mixamorig:rightforearm", "lower_arm.r"])
	if r_fore_idx >= 0:
		var pose = _skeleton.get_bone_pose(r_fore_idx)
		pose.origin.z = cos(_time * frequency * 1.5) * arm_amplitude * 0.4
		_skeleton.set_bone_pose(r_fore_idx, pose)

	# Body sway (hips/spine)
	var spine_idx = _find_bone_by_names(["spine", "spine.001", "mixamorig:spine", "torso"])
	if spine_idx >= 0:
		var pose = _skeleton.get_bone_pose(spine_idx)
		pose.origin.x = sin(_time * frequency * 0.5) * body_sway
		_skeleton.set_bone_pose(spine_idx, pose)

func _find_bone_by_names(names: Array) -> int:
	for bone_name in names:
		var idx = _bone_indices.get(bone_name.to_lower(), -1)
		if idx >= 0:
			return idx
	return -1

func _update_dress_position() -> void:
	# Dress is now parented to skeleton, so we just update local position to follow hip bone
	if not _dress or not _skeleton:
		return

	var hip_idx = _find_hip_bone()
	if hip_idx >= 0:
		var bone_pose = _skeleton.get_bone_global_pose(hip_idx)
		_dress.transform = Transform3D(Basis.IDENTITY, bone_pose.origin)

# Public API
func set_body_visible(visible: bool) -> void:
	show_body = visible
	_update_body_visibility()

func set_animation_speed(speed: float) -> void:
	animation_speed = speed

func set_arm_amplitude(amplitude: float) -> void:
	arm_amplitude = amplitude
