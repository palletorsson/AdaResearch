extends Node3D

# Entropy Visualization: Order → Chaos
# A 10x10x40 grid of points where randomness increases with Z
# Low Z = perfectly ordered grid (zero entropy)
# High Z = maximum chaos (high entropy)

@export var grid_size_x: int = 10
@export var grid_size_y: int = 10
@export var grid_size_z: int = 40
@export var base_spacing: float = 0.2
@export var max_randomness: float = 0.5  # Maximum XY displacement at highest Z
@export var min_randomness: float = 0.0  # No randomness at start (perfect order)

var point_scene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")

func _ready() -> void:
	generate_entropy_grid()

func generate_entropy_grid() -> void:
	for z in range(grid_size_z):
		for y in range(grid_size_y):
			for x in range(grid_size_x):
				# Calculate entropy factor (0.0 at z=0, 1.0 at z=max)
				var entropy_factor = float(z) / float(grid_size_z - 1)

				# Apply exponential curve for more dramatic increase toward the end
				# This makes entropy accelerate (low at start, explosive at end)
				var curved_entropy = pow(entropy_factor, 2.0)

				# Base grid position
				var base_x = (x - grid_size_x / 2.0) * base_spacing
				var base_y = (y - grid_size_y / 2.0) * base_spacing
				var base_z = z * base_spacing

				# Randomness scales from 0 (perfect order) to max (chaos)
				var randomness_amount = lerp(min_randomness, max_randomness, curved_entropy)
				var random_offset_x = randf_range(-randomness_amount, randomness_amount)
				var random_offset_y = randf_range(-randomness_amount, randomness_amount)

				# Final position: perfectly ordered at z=0, chaotic at z=max
				var position = Vector3(
					base_x + random_offset_x,
					base_y + random_offset_y,
					base_z
				)

				# Create point instance
				var point = point_scene.instantiate()
				point.position = position
				add_child(point)

				# IMPORTANT: Make material unique for this instance
				# Without this, all points share the same material!
				var mesh_instance = point.get_node("MeshInstance3D")
				if mesh_instance:
					# Duplicate the material override to make it unique
					if mesh_instance.material_override:
						mesh_instance.material_override = mesh_instance.material_override.duplicate()

					# Set color based on entropy (blue → magenta → red)
					var color = get_entropy_color(curved_entropy)

					# Access the Color node and set color
					var color_node = mesh_instance.get_node("Color")
					if color_node:
						color_node.set_color(color)

func get_entropy_color(entropy_factor: float) -> Color:
	# Color gradient representing entropy increase
	# Low entropy (0.0) = Blue (cold, ordered, low energy)
	# Mid entropy (0.5) = Magenta (transition)
	# High entropy (1.0) = Red (hot, chaotic, high energy)

	# Use HSV: Hue from 240° (blue) through 300° (magenta) to 0° (red)
	var hue = lerp(0.66, 0.0, entropy_factor)  # 0.66 = blue, 0.0 = red
	var saturation = 1.0
	var value = 1.0

	return Color.from_hsv(hue, saturation, value)
