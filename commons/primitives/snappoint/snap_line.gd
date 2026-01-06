extends Node3D
class_name SnapLine

## Dynamic line that connects two snap points
## Updates geometry in real-time as points move

@export var line_thickness: float = 0.01
@export var line_color: Color = Color(0.8, 0.5, 1.0, 1.0)  # Purple-ish
@export var emission_strength: float = 1.5

# The two snap points this line connects
var point_a: Node3D = null
var point_b: Node3D = null

# Visual components
var _mesh_instance: MeshInstance3D
var _cylinder_mesh: CylinderMesh

func _ready() -> void:
	_create_line_mesh()

func _create_line_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LineMesh"
	add_child(_mesh_instance)
	
	_cylinder_mesh = CylinderMesh.new()
	_cylinder_mesh.top_radius = line_thickness
	_cylinder_mesh.bottom_radius = line_thickness
	_cylinder_mesh.height = 1.0
	_cylinder_mesh.radial_segments = 8
	_cylinder_mesh.rings = 0
	
	_mesh_instance.mesh = _cylinder_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.6
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = line_color
	material.emission_energy_multiplier = emission_strength
	
	_mesh_instance.material_override = material

func set_endpoints(p_a: Node3D, p_b: Node3D) -> void:
	point_a = p_a
	point_b = p_b
	
	# Initial update
	if is_inside_tree():
		_update_line_geometry()

func _process(_delta: float) -> void:
	if point_a and point_b and is_instance_valid(point_a) and is_instance_valid(point_b):
		_update_line_geometry()
	else:
		# If either point is invalid, destroy this line
		queue_free()

func _update_line_geometry() -> void:
	if not _mesh_instance or not _cylinder_mesh:
		return
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	
	# Calculate center point
	var center = (pos_a + pos_b) / 2.0
	global_position = center
	
	# Calculate distance (cylinder height)
	var distance = pos_a.distance_to(pos_b)
	_cylinder_mesh.height = distance
	
	# Calculate direction and orient the cylinder
	var direction = (pos_b - pos_a).normalized()
	
	if direction.length() > 0.001:
		# Create proper orientation for the cylinder
		# Cylinders point along Y axis by default
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		
		if right.length() < 0.001:  # Direction is parallel to UP
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		
		# Set transform with direction as the Y axis (cylinder's natural orientation)
		_mesh_instance.global_transform.basis = Basis(right, direction, up)

func set_line_color(color: Color) -> void:
	line_color = color
	if _mesh_instance and _mesh_instance.material_override:
		var mat = _mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = color
			mat.emission = color

func set_line_thickness(thickness: float) -> void:
	line_thickness = thickness
	if _cylinder_mesh:
		_cylinder_mesh.top_radius = thickness
		_cylinder_mesh.bottom_radius = thickness

func get_length() -> float:
	if point_a and point_b and is_instance_valid(point_a) and is_instance_valid(point_b):
		return point_a.global_position.distance_to(point_b.global_position)
	return 0.0

