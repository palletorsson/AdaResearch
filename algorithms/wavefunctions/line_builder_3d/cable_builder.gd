extends Node3D

@export var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var control_point_count: int = 4  # Number of control points
@export var cable_length: float = 4.0  # Total length/spacing
@export var cable_thickness: float = 0.02
@export var tube_sides: int = 8
@export var spline_resolution: int = 20  # Points per segment for smooth curve
@export var gravity_sag: float = 0.5  # How much the cable sags

var control_points: Array[Node3D] = []
var curve: Curve3D
var mesh_instance: MeshInstance3D

func _ready() -> void:
	curve = Curve3D.new()
	mesh_instance = $CableMesh
	_spawn_control_points()
	_update_cable()

func _process(_delta):
	_update_cable()

func _spawn_control_points() -> void:
	var parent = $ControlPoints
	control_points.clear()

	# Create control points distributed along cable length
	for i in range(control_point_count):
		var point = point_scene.instantiate()
		var t = float(i) / float(control_point_count - 1) if control_point_count > 1 else 0.5
		var x = (t - 0.5) * cable_length
		point.position = Vector3(x, 1, 0)
		parent.add_child(point)
		control_points.append(point)

func _update_cable() -> void:
	if control_points.size() < 2:
		return

	# Clear and rebuild curve
	curve.clear_points()

	# Add control points with catenary (sag) simulation
	for i in range(control_points.size()):
		var pos = to_local(control_points[i].global_position)
		curve.add_point(pos)

	# Apply sag between control points using Bezier handles
	for i in range(control_points.size() - 1):
		var p1 = to_local(control_points[i].global_position)
		var p2 = to_local(control_points[i + 1].global_position)
		var distance = p1.distance_to(p2)
		var midpoint = (p1 + p2) / 2.0
		var sag_offset = Vector3(0, -gravity_sag * distance * 0.25, 0)

		# Set Bezier handles for natural cable sag
		var handle_length = distance * 0.3
		curve.set_point_out(i, Vector3(handle_length, -gravity_sag * distance * 0.5, 0))
		if i + 1 < control_points.size():
			curve.set_point_in(i + 1, Vector3(-handle_length, -gravity_sag * distance * 0.5, 0))

	# Generate tube mesh from curve
	_generate_tube_from_curve()

func _generate_tube_from_curve() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat := _create_cable_material()
	st.set_material(mat)

	# Sample curve at high resolution
	var total_length = curve.get_baked_length()
	if total_length < 0.001:
		return

	var sample_count = maxi(2, int(total_length * spline_resolution))
	var positions: Array[Vector3] = []

	for i in range(sample_count):
		var t = float(i) / float(sample_count - 1)
		var offset = t * total_length
		var pos = curve.sample_baked(offset)
		positions.append(pos)

	# Build tube along curve
	for i in range(positions.size() - 1):
		var p1 = positions[i]
		var p2 = positions[i + 1]
		var segment_dir = (p2 - p1).normalized()

		# Find perpendicular vectors for tube cross-section
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(positions.size() - 1)
		var uv_x2 = float(i + 1) / float(positions.size() - 1)

		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * cable_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * cable_thickness

			# Triangle 1
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / tube_sides))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)

			# Triangle 2
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / tube_sides))
			st.add_vertex(p1 + offset2)

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat

func _create_cable_material() -> ShaderMaterial:
	var mat := line_material.duplicate() as ShaderMaterial

	mat.set_shader_parameter("time_offset", 0.0)
	mat.set_shader_parameter("flow_speed", 0.0)
	mat.set_shader_parameter("glow_intensity", 1.0)
	mat.set_shader_parameter("thickness_variation", 0.0)
	mat.set_shader_parameter("pulse_frequency", 0.0)

	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

