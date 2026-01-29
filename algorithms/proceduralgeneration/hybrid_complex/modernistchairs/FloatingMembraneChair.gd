# FloatingMembraneChair.gd
# Procedural generation of suspended membrane chairs
extends Node3D
class_name FloatingMembraneChair

@export var membrane_width: float = 0.7
@export var membrane_depth: float = 0.5
@export var suspension_height: float = 0.6
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	# Create suspension points
	var suspension_points = [
		Vector3(-membrane_width/2, suspension_height, -membrane_depth/2),
		Vector3(membrane_width/2, suspension_height, -membrane_depth/2),
		Vector3(-membrane_width/2, suspension_height, membrane_depth/2),
		Vector3(membrane_width/2, suspension_height, membrane_depth/2)
	]
	
	# Create thin suspension cables
	for point in suspension_points:
		var cable = MeshInstance3D.new()
		cable.mesh = CylinderMesh.new()
		cable.mesh.radial_segments = 4
		cable.mesh.top_radius = 0.002
		cable.mesh.bottom_radius = 0.002
		cable.mesh.height = suspension_height
		cable.position = Vector3(point.x, point.y/2, point.z)
		cable.material_override = materials.get_material("black_steel")
		add_child(cable)
	
	# Create membrane surface
	var membrane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(membrane_width, membrane_depth)
	plane_mesh.subdivide_width = 15
	plane_mesh.subdivide_depth = 15
	membrane.mesh = plane_mesh
	membrane.position = Vector3(0, 0.3, 0)
	membrane.material_override = materials.get_material("canvas")
	add_child(membrane)

func regenerate_with_parameters(params: Dictionary):
	for child in get_children():
		if child != materials:
			child.queue_free()
	generate_chair()

