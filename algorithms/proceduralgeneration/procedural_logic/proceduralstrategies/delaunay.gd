# delaunay.gd - Create mesh from random points using Delaunay
extends Node3D

@export var num_points: int = 50
@export var spread: float = 10.0
@export var extrude_height: float = 2.0

var points: PackedVector2Array = []
var mesh_instance: MeshInstance3D

func _ready():
	generate_mesh()

func generate_mesh():
	generate_points()
	var mesh = create_delaunay_mesh()
	
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.9, 0.4)
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func generate_points():
	points.clear()
	for i in range(num_points):
		points.append(Vector2(
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		))

func create_delaunay_mesh() -> ArrayMesh:
	# Use Godot's built-in Delaunay triangulation
	var delaunay_points = Geometry2D.triangulate_delaunay(points)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create 3D mesh from 2D triangulation with extrusion
	for i in range(0, delaunay_points.size(), 3):
		var i0 = delaunay_points[i]
		var i1 = delaunay_points[i + 1]
		var i2 = delaunay_points[i + 2]
		
		var p0 = Vector3(points[i0].x, 0, points[i0].y)
		var p1 = Vector3(points[i1].x, 0, points[i1].y)
		var p2 = Vector3(points[i2].x, 0, points[i2].y)
		
		# Bottom face
		st.add_vertex(p0)
		st.add_vertex(p1)
		st.add_vertex(p2)
		
		# Top face
		st.add_vertex(p0 + Vector3.UP * extrude_height)
		st.add_vertex(p2 + Vector3.UP * extrude_height)
		st.add_vertex(p1 + Vector3.UP * extrude_height)
		
		# Side faces
		add_side_face(st, p0, p1, extrude_height)
		add_side_face(st, p1, p2, extrude_height)
		add_side_face(st, p2, p0, extrude_height)
	
	st.generate_normals()
	return st.commit()

func add_side_face(st: SurfaceTool, p0: Vector3, p1: Vector3, height: float):
	var p0_top = p0 + Vector3.UP * height
	var p1_top = p1 + Vector3.UP * height
	
	st.add_vertex(p0)
	st.add_vertex(p1)
	st.add_vertex(p1_top)
	
	st.add_vertex(p0)
	st.add_vertex(p1_top)
	st.add_vertex(p0_top)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		generate_mesh()
