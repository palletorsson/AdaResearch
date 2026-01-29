# transforming_pattern.gd
# QFEP φ > 0 Visualization - Transforming Pattern
# Queer signature: pattern that embraces change
# Constantly evolving, never the same twice

extends Node3D

class_name QFEPTransformingPattern

## Grid size
@export var grid_size: int = 6

## Cell size
@export var cell_size: float = 0.06

## Transform speed
@export var transform_speed: float = 0.8

## Pattern color (gold - embrace)
@export var pattern_color: Color = Color(1.0, 0.8, 0.2, 1.0)

# Internal
var _cells: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _time: float = 0.0

func _ready() -> void:
	_build_pattern()

func _build_pattern() -> void:
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
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = pattern_color
			mat.emission_enabled = true
			mat.emission = pattern_color
			mat.emission_energy_multiplier = 0.5
			cell.material_override = mat
			
			add_child(cell)
			_cells.append(cell)
			_materials.append(mat)

func _process(delta: float) -> void:
	_time += delta * transform_speed
	
	# Every cell transforms independently
	for i in range(_cells.size()):
		var cell = _cells[i]
		var mat = _materials[i]
		
		var x = i % grid_size
		var z = i / grid_size
		
		# Wave patterns that constantly shift
		var wave1 = sin(_time + x * 0.8 + z * 0.3)
		var wave2 = cos(_time * 1.3 + x * 0.4 - z * 0.7)
		var wave3 = sin(_time * 0.7 - x * 0.5 + z * 0.9)
		
		var combined = (wave1 + wave2 + wave3) / 3.0
		
		# Height transforms
		cell.position.y = combined * cell_size * 0.5
		
		# Scale transforms
		var scale_factor = 0.7 + (combined + 1) * 0.3
		cell.scale = Vector3(scale_factor, 1.0 + combined * 0.5, scale_factor)
		
		# Color transforms - cycling through warm colors
		var hue_shift = sin(_time * 0.5 + i * 0.1) * 0.1
		var color = Color.from_hsv(
			fmod(0.12 + hue_shift, 1.0),  # Gold hue with variation
			0.8,
			0.9 + combined * 0.1
		)
		mat.albedo_color = color
		mat.emission = color
		mat.emission_energy_multiplier = 0.3 + (combined + 1) * 0.3
		
		# Rotation transforms
		cell.rotation.y = _time * 0.3 + combined * 0.5

# The pattern never settles - always becoming
