extends Node3D

@export var follow_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var height_offset: float = 0.0
@export var distance: float = 2.0

var _target_position: Vector3
var _target_rotation: float

func _ready() -> void:
	print("MenuFollower: Ready, parent is ", get_parent().name)

func _process(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		# Try to find XRCamera3D explicitly if get_camera_3d fails (common in some VR setups)
		camera = get_tree().root.find_child("XRCamera3D", true, false)
		if not camera:
			return
	
	var parent = get_parent()
	if not parent:
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
