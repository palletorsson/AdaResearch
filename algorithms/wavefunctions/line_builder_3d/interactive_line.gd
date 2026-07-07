# interactive_line.gd - a line as a tube threaded through grabbable points
#
# @identity
# essence: a line rendered as a tube through a chain of grabbable point-spheres, rebuilt every frame from their positions
# desire: learner feels that a line is not a stroke but a sequence of points — move a point and the line follows
# critical_parameter: the point positions (point_count and their live global_position) — the line is nothing but the points it threads
# triggers: spawns point_count spheres with random jitter, then rebuilds a tube mesh through them every _process via SurfaceTool
# emerges: the insight that a curve is an interpolation over samples — continuity is manufactured between discrete handles
# needs: [live tube rebuilt from grabbable points [has], missing a control to add or remove points at runtime]
# relationships: the movable cousin of the static line primitive; a bridge from point to curve
# truth: a line is a decision to connect points — the points are given, the connection is authored
extends Node3D

@export var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var point_count: int = 8
@export var point_spacing: float = 0.5
@export var line_thickness: float = 0.02
@export var tube_sides: int = 8  # Number of sides for the tube

var points: Array[Node3D] = []
var mesh_instance: MeshInstance3D

func _ready() -> void:
	randomize()
	mesh_instance = $LineMesh
	_spawn_points()
	_update_line()

func _process(_delta):
	_update_line()

func _spawn_points() -> void:
	var parent = $Points
	points.clear()
	
	for i in range(point_count):
		var p = point_scene.instantiate()
		
		# Random jitter for organic layout
		var y = randf_range(-1.0, 1.0)
		var z = randf_range(-0.5, 0.5)
		
		p.position = Vector3(i * point_spacing, y, z)
		parent.add_child(p)
		points.append(p)

func _update_line() -> void:
	if points.size() < 2:
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create a new material instance for this line
	var mat := _create_line_material()
	st.set_material(mat)

	# Build a tube connecting all points
	for i in range(points.size() - 1):
		var p1 = to_local(points[i].global_position)
		var p2 = to_local(points[i + 1].global_position)
		var segment_dir = (p2 - p1).normalized()

		# Find perpendicular vectors for tube cross-section
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(points.size() - 1)
		var uv_x2 = float(i + 1) / float(points.size() - 1)

		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * line_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * line_thickness

			# Create quad (2 triangles) for this tube segment face
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

func _create_line_material() -> ShaderMaterial:
	# Make a *copy* of the exported ShaderMaterial, otherwise each update overwrites one shared resource
	var mat := line_material.duplicate() as ShaderMaterial
	
	mat.set_shader_parameter("time_offset", randf_range(0.0, 10.0))
	mat.set_shader_parameter("flow_speed", 0.0)
	mat.set_shader_parameter("glow_intensity", randf_range(1.5, 2.0))
	mat.set_shader_parameter("thickness_variation", 0.0)
	mat.set_shader_parameter("pulse_frequency", 0.0)
	
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
