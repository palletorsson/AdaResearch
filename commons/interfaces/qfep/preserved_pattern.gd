# preserved_pattern.gd  
# QFEP φ < 0 Visualization - Preserved Pattern
# Conservative: the pattern that resists change
# Frozen, static, immutable

extends Node3D

class_name QFEPPreservedPattern

## Grid size
@export var grid_size: int = 6

## Cell size
@export var cell_size: float = 0.06

## Pattern color (purple - conservative)
@export var pattern_color: Color = Color(0.6, 0.3, 0.7, 1.0)

func _ready() -> void:
	_build_pattern()

func _build_pattern() -> void:
	# Create a fixed, unchanging pattern
	# Classic checkerboard - stable, predictable, preserved
	
	var mat_on = StandardMaterial3D.new()
	mat_on.albedo_color = pattern_color
	mat_on.emission_enabled = true
	mat_on.emission = pattern_color
	mat_on.emission_energy_multiplier = 0.5
	
	var mat_off = StandardMaterial3D.new()
	mat_off.albedo_color = Color(0.15, 0.1, 0.2, 0.8)
	mat_off.emission_enabled = true
	mat_off.emission = Color(0.15, 0.1, 0.2)
	mat_off.emission_energy_multiplier = 0.1
	
	var offset = -grid_size * cell_size / 2.0
	
	for x in range(grid_size):
		for z in range(grid_size):
			var cell = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, cell_size * 0.3, cell_size * 0.9)
			cell.mesh = box
			
			cell.position = Vector3(
				x * cell_size + offset,
				0,
				z * cell_size + offset
			)
			
			# Checkerboard pattern - preserved forever
			var is_on = (x + z) % 2 == 0
			cell.material_override = mat_on if is_on else mat_off
			
			# Slightly raised if on
			if is_on:
				cell.position.y = cell_size * 0.15
			
			add_child(cell)

# No _process - this pattern doesn't change
# That's the whole point: φ < 0 resists change
