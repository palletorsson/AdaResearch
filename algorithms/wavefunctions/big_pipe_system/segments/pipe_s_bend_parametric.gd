@tool
extends MeshInstance3D

@export var u_resolution: int = 30
@export var v_resolution: int = 20
@export var pipe_radius: float = 0.4:
	set(val):
		pipe_radius = val
		if is_inside_tree(): generate_surface()
@export var length: float = 2.0:
	set(val):
		length = val
		if is_inside_tree(): generate_surface()
@export var offset: float = 1.0:
	set(val):
		offset = val
		if is_inside_tree(): generate_surface()

func _ready() -> void:
	generate_surface()

func generate_surface() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rows := u_resolution
	var columns := v_resolution
	
	# Curve Function C(u):
	# u from 0 to 1
	# z(u) = length * u
	# x(u) = offset * (1 - cos(u * PI)) / 2   (Ease-in-out / Cosine interp)
	# y(u) = 0
	
	for i in range(rows + 1):
		var u_ratio = float(i) / float(rows)
		
		# Define Center Point C(u)
		var cz = length * u_ratio
		var cx = offset * (1.0 - cos(u_ratio * PI)) * 0.5
		var cy = 0.0
		var center = Vector3(cx, cy, cz)
		
		# Calculate Derivatives for Tangent
		# z'(u) = length
		# x'(u) = offset * 0.5 * sin(u * PI) * PI
		var dx = offset * 0.5 * sin(u_ratio * PI) * PI
		var dz = length
		var tangent = Vector3(dx, 0, dz).normalized()
		
		# Calculate Frame (Normal, Binormal)
		# Since curve is in XZ plane, Binormal (Up) is Y (0,1,0)
		var binormal = Vector3(0, 1, 0)
		var normal = binormal.cross(tangent).normalized()
		
		# Generate Ring
		for j in range(columns + 1):
			var v_ratio = float(j) / float(columns)
			var angle = v_ratio * TAU
			
			var cos_a = cos(angle)
			var sin_a = sin(angle)
			
			# Vertex offset from center
			var offset_vec = (normal * cos_a + binormal * sin_a) * pipe_radius
			var pos = center + offset_vec
			
			# UVs
			var uv = Vector2(u_ratio, v_ratio)
			
			# Normal of vertex (same as offset direction, usually)
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
	
	# Create collision shape if needed (Simplified as convex hull or multiple capsules?
	# For now, just visual is parametric. Collision is tricky for parametric.
	# The user asked for solid, so maybe TriMesh collision?
	if get_node_or_null("StaticBody3D"):
		var sb = get_node("StaticBody3D")
		# Clear old shapes?
		for child in sb.get_children():
			child.queue_free()
		
		var col_shape = CollisionShape3D.new()
		col_shape.shape = generated_mesh.create_trimesh_shape()
		sb.add_child(col_shape)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

