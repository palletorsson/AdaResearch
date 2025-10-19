extends Node3D

@export var iterations: int = 4
@export var line_width: float = 0.02
@export var curve_length: float = 6.0

var line_material: StandardMaterial3D

func _ready():
	setup_material()
	generate_koch_curve()

func setup_material():
	line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.WHITE
	line_material.emission_enabled = true
	line_material.emission = Color(0.8, 0.9, 1.0)

func generate_koch_curve():
	var points = get_koch_points(iterations)
	create_3d_lines(points)

func get_koch_points(iter: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	points.append(Vector3(-curve_length/2, 0, 0))
	points.append(Vector3(curve_length/2, 0, 0))
	
	for i in range(iter):
		points = koch_iteration(points)
	
	return points

func koch_iteration(points: Array[Vector3]) -> Array[Vector3]:
	var new_points: Array[Vector3] = []
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		
		# Calculate the four points of the Koch segment
		var segment = p2 - p1
		var third = segment / 3.0
		
		var a = p1
		var b = p1 + third
		var d = p1 + 2.0 * third
		var e = p2
		
		# Calculate the peak point (equilateral triangle)
		var mid = (b + d) / 2.0
		var height_vec = Vector3(-segment.z, 0, segment.x).normalized()
		var height = third.length() * sqrt(3.0) / 2.0
		var c = mid + height_vec * height
		
		new_points.append(a)
		new_points.append(b)
		new_points.append(c)
		new_points.append(d)
	
	new_points.append(points[-1])
	return new_points

func create_3d_lines(points: Array[Vector3]):
	for i in range(points.size() - 1):
		var line_mesh = create_line_segment(points[i], points[i + 1])
		add_child(line_mesh)

func create_line_segment(start: Vector3, end: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	
	# Set cylinder properties
	cylinder_mesh.radial_segments = 8
	cylinder_mesh.rings = 1
	cylinder_mesh.top_radius = line_width
	cylinder_mesh.bottom_radius = line_width
	
	var length = start.distance_to(end)
	cylinder_mesh.height = length
	
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = line_material
	
	# Position and orient the cylinder
	var center = (start + end) / 2.0
	mesh_instance.position = center
	
	# Align cylinder with the line direction
	var direction = (end - start).normalized()
	if direction.length() > 0.001:
		mesh_instance.look_at_from_position(mesh_instance.position, center + direction, Vector3.UP)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)
	
	return mesh_instance
