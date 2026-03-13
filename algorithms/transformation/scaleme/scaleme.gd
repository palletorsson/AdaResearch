@tool
extends Node3D

@export var start_size: float = 0.2
@export var scale_factor: float = 2.0
@export var count: int = 8
@export_group("Materials")
@export var alternating_colors: bool = true
@export var color_a: Color = Color.RED
@export var color_b: Color = Color.BLUE
@export var regenerate: bool = false: set = _set_regenerate

var _generated_cubes: Array[MeshInstance3D] = []

func _ready() -> void:
	generate_cubes()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_cubes()
		regenerate = false

func generate_cubes() -> void:
	_clear_cubes()

	var size: float = start_size
	var y_offset: float = 0.0

	for i in range(count):
		# Create MeshInstance3D
		var cube := MeshInstance3D.new()
		cube.name = "Cube_%d" % i

		# Create BoxMesh
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3.ONE

		# Create material
		var mat := StandardMaterial3D.new()
		if alternating_colors:
			mat.albedo_color = color_a if i % 2 == 0 else color_b
		box_mesh.material = mat

		cube.mesh = box_mesh

		# Scale and position
		cube.scale = Vector3.ONE * size
		cube.position = Vector3(0, y_offset + size / 2.0, 0)  # Center at y_offset + half size

		add_child(cube)
		if Engine.is_editor_hint():
			cube.owner = get_tree().edited_scene_root

		_generated_cubes.append(cube)

		# Update for next iteration
		y_offset += size       # Raise by current size
		size *= scale_factor   # Next cube is scaled up

func _clear_cubes() -> void:
	for cube in _generated_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	_generated_cubes.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

