extends Node3D
class_name VectorFieldArrow

var arrow_mesh: MeshInstance3D
var direction: Vector3 = Vector3.UP
var magnitude: float = 1.0

func _ready():
	create_arrow()

func create_arrow():
	# Create a box mesh for the arrow head (cone-like when scaled)
	var cone_mesh = BoxMesh.new()
	cone_mesh.size = Vector3(0.1, 0.2, 0.1)
	
	# Create a cylinder for the arrow shaft
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.8
	cylinder.radial_segments = 6
	
	# Create materials
	var cone_material = StandardMaterial3D.new()
	cone_material.albedo_color = Color.RED
	cone_material.emission_enabled = true
	cone_material.emission = Color.RED * 0.3
	
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color.RED
	cylinder_material.emission_enabled = true
	cylinder_material.emission = Color.RED * 0.2
	
	# Create arrow head
	var arrow_head = MeshInstance3D.new()
	arrow_head.mesh = cone_mesh
	arrow_head.material_override = cone_material
	arrow_head.position = Vector3(0, 0.5, 0)
	arrow_head.scale = Vector3(1, 1, 1)  # Scale to make it more cone-like
	add_child(arrow_head)
	
	# Create arrow shaft
	var arrow_shaft = MeshInstance3D.new()
	arrow_shaft.mesh = cylinder
	arrow_shaft.material_override = cylinder_material
	arrow_shaft.position = Vector3(0, 0.1, 0)
	add_child(arrow_shaft)
	
	# Store reference to the arrow
	arrow_mesh = arrow_head

func set_direction(new_direction: Vector3):
	direction = new_direction.normalized()
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func set_magnitude(new_magnitude: float):
	magnitude = new_magnitude
	# Scale based on magnitude
	var scale_factor = clamp(magnitude / 2.0, 0.1, 2.0)
	scale = Vector3.ONE * scale_factor
	
	# Adjust color based on magnitude
	var intensity = clamp(magnitude / 4.0, 0.1, 1.0)
	var color = Color(intensity, 0, 0, 1)
	
	for child in get_children():
		if child is MeshInstance3D and child.material_override:
			child.material_override.albedo_color = color
			child.material_override.emission = color * 0.3
