extends Node3D

@export var cube_scene: PackedScene = preload("res://algorithms/primitives/booleans/booleanHollowCube.tscn")
@export var num_segments: int = 12
@export var spacing: float = 3.0
@export var rotation_per_segment: float = 10.0  # degrees
@export var cube_height: float = 4.0  # height of the cube for pivot compensation

func _ready():
	generate_tunnel()

func generate_tunnel():
	# Clear existing children
	for child in get_children():
		child.queue_free()

	for i in range(num_segments):
		var cube_instance = cube_scene.instantiate()
		add_child(cube_instance)

		# Calculate rotation angle in radians
		var angle_deg = i * rotation_per_segment
		var angle_rad = deg_to_rad(angle_deg)

		# Position along z-axis
		var z_pos = i * spacing

		# Compensate for bottom pivot rotation
		# When rotating around Z-axis with pivot at bottom, the center moves
		# We need to offset X and Y to keep the tunnel aligned
		var half_height = cube_height / 2.0
		var x_offset = half_height * sin(angle_rad)
		var y_offset = half_height * (1.0 - cos(angle_rad))

		# Create transform with rotation around Z-axis
		var transform_3d = Transform3D()
		transform_3d = transform_3d.rotated(Vector3(0, 0, 1), angle_rad)

		# Apply position with compensation
		transform_3d.origin = Vector3(x_offset, y_offset, z_pos)

		cube_instance.transform = transform_3d
		cube_instance.name = "Cube" + str(i)
