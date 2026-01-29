# curve_extrusion.gd - Extrude shape along path
extends Node3D

@export var path_points: int = 50
@export var path_radius: float = 5.0
@export var tube_radius: float = 0.5
@export var tube_segments: int = 8

var mesh_instance: MeshInstance3D
var curve: Curve3D

func _ready():
	generate_mesh()

func generate_mesh():
	create_path()
	var mesh = extrude_along_path()
	
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.5, 0.2)
	material.metallic = 0.7
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func create_path():
	curve = Curve3D.new()
	
	# Create spiral path
	for i in range(path_points):
		var t = float(i) / float(path_points - 1)
		var angle = t * TAU * 3
		var height = t * 10.0 - 5.0
		var point = Vector3(
			cos(angle) * path_radius,
			height,
			sin(angle) * path_radius
		)
		curve.add_point(point)

func extrude_along_path() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var path_length = curve.get_baked_length()
	var samples = 100
	
	# Create tube profile (circle)
	var profile = []
	for i in range(tube_segments):
		var angle = float(i) / float(tube_segments) * TAU
		profile.append(Vector2(cos(angle), sin(angle)) * tube_radius)
	
	# Extrude profile along path
	for i in range(samples):
		var offset = (float(i) / float(samples - 1)) * path_length
		var pos = curve.sample_baked(offset)
		
		var next_offset = min(offset + path_length / samples, path_length)
		var next_pos = curve.sample_baked(next_offset)
		var forward = (next_pos - pos).normalized()
		
		# Calculate orientation
		var up = Vector3.UP
		if abs(forward.dot(up)) > 0.99:
			up = Vector3.RIGHT
		var right = forward.cross(up).normalized()
		up = right.cross(forward).normalized()
		
		# Create ring vertices
		if i < samples - 1:
			for j in range(tube_segments):
				var j_next = (j + 1) % tube_segments
				
				# Current ring
				var p0 = pos + right * profile[j].x + up * profile[j].y
				var p1 = pos + right * profile[j_next].x + up * profile[j_next].y
				
				# Next ring
				var next_offset2 = min(offset + path_length / samples, path_length)
				var next_pos2 = curve.sample_baked(next_offset2)
				var next_forward = (next_pos2 - next_pos).normalized()
				
				var next_right = next_forward.cross(up).normalized()
				var next_up = next_right.cross(next_forward).normalized()
				
				var p2 = next_pos + next_right * profile[j_next].x + next_up * profile[j_next].y
				var p3 = next_pos + next_right * profile[j].x + next_up * profile[j].y
				
				# Add quad as two triangles
				st.add_vertex(p0)
				st.add_vertex(p1)
				st.add_vertex(p2)
				
				st.add_vertex(p0)
				st.add_vertex(p2)
				st.add_vertex(p3)
	
	st.generate_normals()
	return st.commit()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		generate_mesh()
