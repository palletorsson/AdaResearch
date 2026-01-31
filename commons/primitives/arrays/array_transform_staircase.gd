@tool
extends Node3D
class_name ArrayTransformStaircase

## Array + Transform = Staircase
## The minimal demonstration: repetition with cumulative offset
## No extras. Just the core insight.

@export_range(2, 24) var step_count: int = 8:
	set(v):
		step_count = v
		_rebuild()

@export var step_size: Vector3 = Vector3(0.5, 0.1, 0.3):
	set(v):
		step_size = v
		_rebuild()

@export var rise: float = 0.15:
	set(v):
		rise = v
		_rebuild()

@export var run: float = 0.4:
	set(v):
		run = v
		_rebuild()

@export var step_color: Color = Color(0.7, 0.7, 0.75, 1.0):
	set(v):
		step_color = v
		_update_material()

var _steps: Array[MeshInstance3D] = []
var _material: StandardMaterial3D

func _ready() -> void:
	_create_material()
	_rebuild()

func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = step_color

func _update_material() -> void:
	if _material:
		_material.albedo_color = step_color

func _rebuild() -> void:
	# Clear
	for step in _steps:
		if is_instance_valid(step):
			step.queue_free()
	_steps.clear()
	
	# Build
	var box = BoxMesh.new()
	box.size = step_size
	
	for i in range(step_count):
		var step = MeshInstance3D.new()
		step.name = "Step_%d" % i
		step.mesh = box
		step.material_override = _material
		
		# THE CORE INSIGHT:
		# position[i] = i * (run, rise, 0)
		step.position = Vector3(
			i * run,
			i * rise,
			0
		)
		
		add_child(step)
		_steps.append(step)

## Get transform for step at index
func get_step_position(index: int) -> Vector3:
	return Vector3(index * run, index * rise, 0)

## The formula, exposed
func get_transform_formula() -> String:
	return "position[i] = i × (%.2f, %.2f, 0)" % [run, rise]
