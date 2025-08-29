# CloudVolumeVR.gd
# A Godot 4 scene that renders a realistic volumetric cloud inside a cube
# using a ray marching shader. This is a port of a classic Three.js demo.
extends Node3D

@export var rotation_speed: float = 0.05

var volume_mesh: MeshInstance3D
var sun_light: DirectionalLight3D
var camera: Camera3D

func _ready():
	# Find the necessary nodes in the scene
	volume_mesh = $VolumeBox
	sun_light = $Sun
	camera = $Camera3D
	
	if not is_instance_valid(volume_mesh) or not is_instance_valid(sun_light) or not is_instance_valid(camera):
		push_error("Scene is missing required nodes: VolumeBox, Sun, or Camera3D.")
		return

func _process(delta):
	if is_instance_valid(volume_mesh):
		# Slowly rotate the volume to showcase its 3D nature
		volume_mesh.rotate_y(rotation_speed * delta)
		
		# Update the shader with the camera's and sun's current position/direction
		var material = volume_mesh.get_active_material(0)
		if material is ShaderMaterial:
			# The sun's direction is the negative of its forward basis vector (-z)
			var sun_direction = -sun_light.global_transform.basis.z
			material.set_shader_parameter("sun_direction", sun_direction)
			material.set_shader_parameter("camera_position", camera.global_position)
