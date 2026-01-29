# convex_hull.gd - Create convex hull around points
extends Node3D

@export var num_points: int = 30
@export var spread: float = 5.0
@export var show_points: bool = true

var points: PackedVector3Array = []
var mesh_instance: MeshInstance3D
var point_instances: Array = []

func _ready():
	generate_mesh()

func generate_mesh():
	clear_points()
	generate_points()
	var mesh = create_convex_hull()
	
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.7, 0.9, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	if show_points:
		visualize_points()

func generate_points():
	points.clear()
	for i in range(num_points):
		points.append(Vector3(
			randf_range(-spread, spread),
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		))

func create_convex_hull() -> ArrayMesh:
	# Use Godot's ConvexPolygonShape3D to generate hull
	var shape = ConvexPolygonShape3D.new()
	shape.points = points
	
	# Extract faces from convex shape
	var faces = shape.get_faces()
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0, faces.size(), 3):
		st.add_vertex(faces[i])
		st.add_vertex(faces[i + 1])
		st.add_vertex(faces[i + 2])
	
	st.generate_normals()
	return st.commit()

func visualize_points():
	for point in points:
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1
		sphere_mesh.height = 0.2
		sphere.mesh = sphere_mesh
		sphere.position = point
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		material.emission_enabled = true
		material.emission = Color.RED
		sphere.material_override = material
		
		add_child(sphere)
		point_instances.append(sphere)

func clear_points():
	for inst in point_instances:
		inst.queue_free()
	point_instances.clear()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			generate_mesh()
		elif event.keycode == KEY_P:
			show_points = !show_points
			if show_points:
				visualize_points()
			else:
				clear_points()
