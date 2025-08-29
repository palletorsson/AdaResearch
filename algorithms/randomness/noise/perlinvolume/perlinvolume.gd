# PerlinVolumeVR.gd
# A Godot 4 scene that renders volumetric, animated Perlin noise inside a cube
# using a ray marching shader. This is a port of a classic Three.js demo.
extends Node3D

@export var rotation_speed: float = 0.1

var volume_mesh: MeshInstance3D

func _ready():
	# The entire effect is driven by the shader. This script just sets up
	# the mesh and provides a basic rotation.
	setup_scene()

func setup_scene():
	# Find the MeshInstance3D in the scene
	volume_mesh = $VolumeBox
	if not volume_mesh:
		push_error("Could not find 'VolumeBox' MeshInstance3D node.")
		return

	# The material is already set in the .tscn file, so we don't need
	# to create it here. We just need to ensure the shader can receive
	# updates if necessary (like the TIME uniform, which is built-in).

func _process(delta):
	if is_instance_valid(volume_mesh):
		# Slowly rotate the volume to showcase the 3D nature of the noise.
		volume_mesh.rotate_y(rotation_speed * delta)
		volume_mesh.rotate_x(rotation_speed * delta * 0.5)
