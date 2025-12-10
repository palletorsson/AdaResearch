@tool
extends MeshInstance3D

@export var u_resolution: int = 30
@export var v_resolution: int = 20
@export var pipe_radius: float = 0.8 # Match BigPipeSystem default
@export var corner_radius: float = 2.0 # Match BigPipeSystem radius/length logic

func _ready():
	generate_surface()

# Setter to trigger regen in editor
func set_pipe_radius(val):
	pipe_radius = val
	if is_inside_tree(): generate_surface()

func set_corner_radius(val):
	corner_radius = val
	if is_inside_tree(): generate_surface()

func generate_surface():
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rows := u_resolution
	var columns := v_resolution
	
	# Curve Function C(u):
	# u from 0 to 1
	# Quarter circle turn to Right.
	# Start (0,0,0) facing +Z.
	# End (R, 0, R) facing +X.
	# Math:
	# z(angle) = R * sin(angle)
	# x(angle) = R * (1 - cos(angle))
	# angle goes 0 to PI/2
	
	for i in range(rows + 1):
		var u_ratio = float(i) / float(rows)
		var angle = u_ratio * (PI / 2.0)
		
		# Define Center Point C(u)
		var cz = corner_radius * sin(angle)
		var cx = corner_radius * (1.0 - cos(angle))
		var cy = 0.0
		var center = Vector3(cx, cy, cz)
		
		# Calculate Derivatives for Tangent
		# z'(a) = R cos(a)
		# x'(a) = R sin(a)
		# Tangent direction (normalized):
		var dz = cos(angle)
		var dx = sin(angle)
		var tangent = Vector3(dx, 0, dz).normalized()
		
		# Calculate Frame (Normal, Binormal)
		# Curve in XZ plane. Binormal (Up) is Y (0,1,0).
		var binormal = Vector3(0, 1, 0)
		var normal = binormal.cross(tangent).normalized()
		
		# Generate Ring
		for j in range(columns + 1):
			var v_ratio = float(j) / float(columns)
			var ring_angle = v_ratio * TAU
			
			var cos_r = cos(ring_angle)
			var sin_r = sin(ring_angle)
			
			# Vertex offset from center
			var offset_vec = (normal * cos_r + binormal * sin_r) * pipe_radius
			var pos = center + offset_vec
			
			# UVs
			var uv = Vector2(u_ratio, v_ratio)
			
			# Normal of vertex
			var vert_norm = offset_vec.normalized()
			
			st.set_normal(vert_norm)
			st.set_uv(uv)
			st.add_vertex(pos)

	# Generate indices
	for i in range(rows):
		for j in range(columns):
			var current = i * (columns + 1) + j
			var next_row = current + (columns + 1)
			
			# Triangle 1
			st.add_index(current)
			st.add_index(next_row)
			st.add_index(current + 1)
			
			# Triangle 2
			st.add_index(current + 1)
			st.add_index(next_row)
			st.add_index(next_row + 1)

	st.generate_tangents()
	var generated_mesh := st.commit()
	mesh = generated_mesh
	
	# Update collision
	if get_node_or_null("StaticBody3D"):
		var sb = get_node("StaticBody3D")
		for child in sb.get_children():
			child.queue_free()
		var col_shape = CollisionShape3D.new()
		col_shape.shape = generated_mesh.create_trimesh_shape()
		sb.add_child(col_shape)
