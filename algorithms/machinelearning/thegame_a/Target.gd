extends Node3D
class_name Target

# The Axiom Garden - Iteration 5: The Objective
# Represents a point in space the plant must reach.

signal target_reached

@export var radius: float = 0.5

func _ready() -> void:
	# Visual Debug
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = radius
	mesh.mesh.height = radius * 2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.CYAN
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	mesh.material_override = mat
	add_child(mesh)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

