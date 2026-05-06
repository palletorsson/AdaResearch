@tool
extends MeshInstance3D
## Parametric vertical elbow — swept 90° bend in the YZ plane.
## direction = +1 → bends upward (exit faces +Y)
## direction = -1 → bends downward (exit faces -Y)

@export var u_resolution: int = 30
@export var v_resolution: int = 20
@export var pipe_radius: float = 0.8
@export var corner_radius: float = 2.0
@export_enum("Up:1", "Down:-1") var direction: int = 1

func _ready() -> void:
	generate_surface()

func set_pipe_radius(val) -> void:
	pipe_radius = val
	if is_inside_tree(): generate_surface()

func set_corner_radius(val) -> void:
	corner_radius = val
	if is_inside_tree(): generate_surface()

func generate_surface() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rows := u_resolution
	var columns := v_resolution

	# Quarter circle (90°) in YZ plane.
	# Start at (0,0,0) facing +Z.
	#
	# direction = +1 (UP):
	#   Curve bends upward. Center of bend circle at (0, +R, 0).
	#   C(u): y = R - R*cos(angle), z = R*sin(angle)
	#   At angle=0: (0,0,0) facing +Z. At angle=PI/2: (0,R,R) facing +Y.
	#   Tangent: dy = R*sin(a), dz = R*cos(a) → (0, sin(a), cos(a))
	#
	# direction = -1 (DOWN):
	#   Curve bends downward. Center of bend circle at (0, -R, 0).
	#   C(u): y = -(R - R*cos(angle)), z = R*sin(angle)
	#   At angle=0: (0,0,0) facing +Z. At angle=PI/2: (0,-R,R) facing -Y.
	#   Tangent: dy = -R*sin(a), dz = R*cos(a) → (0, -sin(a), cos(a))

	var dir_sign := float(direction)

	for i in range(rows + 1):
		var u_ratio := float(i) / float(rows)
		var angle := u_ratio * (PI / 2.0)

		# Center point of the curve
		var cy := dir_sign * corner_radius * (1.0 - cos(angle))
		var cz := corner_radius * sin(angle)
		var center := Vector3(0, cy, cz)

		# Tangent along the curve
		var dy := dir_sign * sin(angle)
		var dz := cos(angle)
		var tangent := Vector3(0, dy, dz).normalized()

		# Frame: curve is in YZ plane, so binormal is X
		var binormal := Vector3(1, 0, 0)
		var normal := binormal.cross(tangent).normalized()

		# Generate ring vertices
		for j in range(columns + 1):
			var v_ratio := float(j) / float(columns)
			var ring_angle := v_ratio * TAU

			var offset_vec := (normal * cos(ring_angle) + binormal * sin(ring_angle)) * pipe_radius
			var pos := center + offset_vec

			var uv := Vector2(u_ratio, v_ratio)
			var vert_norm := offset_vec.normalized()

			st.set_normal(vert_norm)
			st.set_uv(uv)
			st.add_vertex(pos)

	# Generate indices
	for i in range(rows):
		for j in range(columns):
			var current := i * (columns + 1) + j
			var next_row := current + (columns + 1)

			st.add_index(current)
			st.add_index(next_row)
			st.add_index(current + 1)

			st.add_index(current + 1)
			st.add_index(next_row)
			st.add_index(next_row + 1)

	st.generate_tangents()
	var generated_mesh := st.commit()
	mesh = generated_mesh

	# Update collision
	if get_node_or_null("StaticBody3D"):
		var sb := get_node("StaticBody3D")
		for child in sb.get_children():
			child.queue_free()
		var col_shape := CollisionShape3D.new()
		col_shape.shape = generated_mesh.create_trimesh_shape()
		sb.add_child(col_shape)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
