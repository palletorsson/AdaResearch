extends Node3D
## BellCurveAlley.gd
## Builds an alley (corridor) of cubes along Z, widening outwards in X using a bell curve.

@export var grid_x: int = 30
@export var grid_z: int = 60
@export var cube_spacing: float = 1.0
@export var spread: float = 4.0           # how wide the bell curve spreads
@export var height_y: float = 0.0         # cube Y position (ground level)
@export var cube_scene: PackedScene = preload("res://commons/primitives/cubes/cube_scene.tscn")

func _ready() -> void:
	create_bellcurve_alley()

func create_bellcurve_alley() -> void:
	var mid_z := grid_z / 2.0
	var mid_x := 0.0
	
	for z in range(grid_z):
		var z_offset := float(z) - mid_z

		# Compute bell curve value (0..1)
		# Higher near edges, smaller near center
		var width_factor := exp(-pow(z_offset, 2) / (2.0 * pow(spread, 2)))
		var max_half_width := int(grid_x / 2)
		
		# Determine how many cubes to place in X on this z-row
		# The alley center (middle 3 z) only has one cube (narrow path)
		var row_width := int(lerp(1, max_half_width, 1.0 - width_factor))

		for x in range(-row_width, row_width + 1):
			# Skip the center x=0 in the middle 3 rows to form the "alley"
			if abs(z - mid_z) < 2 and abs(x) > 0:
				continue

			# Random chance to skip some cubes near edges for irregularity
			if abs(x) > 0 and randf() > 0.8:
				continue

			# Create cube instance
			var cube := cube_scene.instantiate()
			cube.position = Vector3(x * cube_spacing, height_y, z * cube_spacing)
			add_child(cube)

func apply_grid_config(config: Dictionary) -> void:
	pass
