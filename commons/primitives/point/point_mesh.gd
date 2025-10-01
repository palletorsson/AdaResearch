# PointMesh.gd - Standalone sphere mesh configuration
extends Node

# Target mesh instance
var target_mesh: MeshInstance3D = null

# Sphere settings
@export var radius: float = 0.02

func _ready():
	# Try to find target mesh in parent if not set
	if not target_mesh:
		if get_parent() is MeshInstance3D:
			target_mesh = get_parent()
		else:
			# Search for MeshInstance3D in parent's children
			for child in get_parent().get_children():
				if child is MeshInstance3D:
					target_mesh = child
					break

	# Apply sphere mesh if target exists
	if target_mesh:
		create_sphere()

# Set the target mesh instance
func set_target_mesh(mesh: MeshInstance3D):
	target_mesh = mesh
	if target_mesh:
		create_sphere()

# Create sphere mesh
func create_sphere():
	if not target_mesh:
		return

	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	target_mesh.mesh = sphere

# Update radius
func set_radius(new_radius: float):
	radius = new_radius
	create_sphere()
