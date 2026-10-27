extends Node3D

@export var follow_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var height_offset: float = 0.0
@export var distance: float = 2.0

var _target_position: Vector3
var _target_rotation: float
var _was_visible := false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var parent := get_parent() as Node3D
	if parent == null or not parent.is_visible_in_tree():
		_was_visible = false
		return
	var camera = get_viewport().get_camera_3d()
	if not camera:
		# Try to find XRCamera3D explicitly if get_camera_3d fails (common in some VR setups)
		camera = get_tree().root.find_child("XRCamera3D", true, false)
		if not camera:
			return
	
	# Calculate target position in front of camera, but keep y relatively stable
	var camera_forward = -camera.global_transform.basis.z
	camera_forward.y = 0 # Keep it horizontal
	if camera_forward.length_squared() < 0.01:
		camera_forward = Vector3.FORWARD
	else:
		camera_forward = camera_forward.normalized()
	
	var target_pos = camera.global_position + camera_forward * distance
	target_pos.y = camera.global_position.y + height_offset
	# A hidden menu must not follow a player hundreds of metres down the tower.
	# On return, place the labels AND colliders in front of the menu camera in
	# one frame so they do not slide away between mouse-down and the ray query.
	if not _was_visible:
		parent.global_position = target_pos
		var look_away: Vector3 = target_pos + camera_forward
		parent.global_transform = parent.global_transform.looking_at(look_away, Vector3.UP)
		_was_visible = true
		return
	
	# Smoothly interpolate position
	parent.global_position = parent.global_position.lerp(target_pos, delta * follow_speed)
	
	# Smoothly look at camera
	var look_target = camera.global_position
	look_target.y = parent.global_position.y # Keep look horizontal
	
	if parent.global_position.distance_to(look_target) > 0.1:
		# Look away from camera so +Z (UI front) faces camera
		var look_away_target = 2 * parent.global_position - look_target
		var target_transform = parent.global_transform.looking_at(look_away_target, Vector3.UP)
		parent.global_transform = parent.global_transform.interpolate_with(target_transform, delta * rotation_speed)
