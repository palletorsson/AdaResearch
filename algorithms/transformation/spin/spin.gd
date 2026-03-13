@tool
extends Node3D

@export var copy_count_phase1: int = 10
@export var translation_step: float = 0.14
@export var rotation_count: int = 12
@export var z_rotation_degrees: float = 15.0
@export var copy_count_phase3: int = 10
@export var source_mesh: Mesh = null
@export_group("Materials")
@export var alternating_colors: bool = true
@export var color_a: Color = Color.BLACK
@export var color_b: Color = Color.WHITE
@export var regenerate: bool = false: set = _set_regenerate

@onready var mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()

func _ready() -> void:
	generate_copies()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_copies()
		regenerate = false

func generate_copies() -> void:
	# Clear existing multimesh instance
	if mm_inst.get_parent():
		mm_inst.get_parent().remove_child(mm_inst)

	add_child(mm_inst)
	if Engine.is_editor_hint():
		mm_inst.owner = get_tree().edited_scene_root

	var original = get_node_or_null("copyandrotate")
	if not original:
		push_error("spin.gd: 'copyandrotate' node not found")
		return

	# Get mesh from original if available
	var mesh_to_use = source_mesh
	if mesh_to_use == null and original is MeshInstance3D:
		mesh_to_use = original.mesh

	if mesh_to_use == null:
		push_error("spin.gd: No mesh available for MultiMesh")
		return

	var mm := MultiMesh.new()
	mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = alternating_colors
	mm.mesh = mesh_to_use

	# Calculate total instance count (original + all phases)
	var total := 1 + copy_count_phase1 + rotation_count + copy_count_phase3
	mm.instance_count = total

	var current_transform = original.transform
	var k := 0

	# Add original
	mm.set_instance_transform(k, current_transform)
	if alternating_colors:
		mm.set_instance_color(k, color_a if k % 2 == 0 else color_b)
	k += 1

	# Phase 1: Copy with +x translation
	for i in range(copy_count_phase1):
		current_transform.origin.x += translation_step
		mm.set_instance_transform(k, current_transform)
		if alternating_colors:
			mm.set_instance_color(k, color_a if k % 2 == 0 else color_b)
		k += 1

	# Phase 2: Copy and rotate with continued translation
	for i in range(rotation_count):
		current_transform.origin.x += translation_step
		current_transform = current_transform.rotated_local(Vector3.BACK, deg_to_rad(z_rotation_degrees))
		mm.set_instance_transform(k, current_transform)
		if alternating_colors:
			mm.set_instance_color(k, color_a if k % 2 == 0 else color_b)
		k += 1

	# Phase 3: Copy with +x translation
	for i in range(copy_count_phase3):
		current_transform.origin.x += translation_step
		mm.set_instance_transform(k, current_transform)
		if alternating_colors:
			mm.set_instance_color(k, color_a if k % 2 == 0 else color_b)
		k += 1

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

