extends Node3D

## Triangle Circle Trace — 3D VR version
## An equilateral triangle rolls around a circle, a trace point on the triangle
## draws an epitrochoid pattern.

@export var circle_radius: float = 0.2  # Radius of the base circle
@export var triangle_side: float = 0.1  # Side length of the rolling triangle
@export var angular_speed: float = 0.5  # Speed of the triangle rolling around the circle
@export var trace_speed: float = 3.0  # How fast the trace point moves along the triangle edges
@export var max_trail_points: int = 2000
@export var trace_color: Color = Color(0.0, 1.0, 0.0, 1.0)
@export var triangle_color: Color = Color(0.3, 0.3, 1.0)
@export var circle_color: Color = Color(0.5, 0.5, 0.5)
@export var point_color: Color = Color(1.0, 0.0, 0.0)

var angle: float = 0.0  # Current rotation angle around the circle
var trace_step: float = 0.0  # Progress along current edge [0, 1)
var edge_index: int = 0  # Which edge the trace point is on

var triangle_vertices: Array[Vector3] = []  # Local triangle vertices (XZ plane)
var trail_points: Array[Vector3] = []  # World positions of the trace trail
var trail_ages: Array[float] = []  # Age of each trail point for color fading

# Mesh instances
var _circle_mesh_instance: MeshInstance3D
var _triangle_mesh_instance: MeshInstance3D
var _trail_mesh_instance: MeshInstance3D
var _trace_point_instance: MeshInstance3D
var _label: Label3D

var _elapsed: float = 0.0


func _ready() -> void:
	_calculate_triangle_vertices()
	_create_circle()
	_create_triangle()
	_create_trail()
	_create_trace_point()
	_create_label()


func _process(delta: float) -> void:
	_elapsed += delta

	# Rotate triangle around the circle
	angle += angular_speed * delta
	if angle >= TAU:
		angle -= TAU

	# Move trace point along triangle edges
	_update_trace_step(delta)

	# Compute world position of trace point
	var local_pos := _get_trace_local_position()
	var world_pos := _transform_to_world(local_pos)

	# Add to trail
	trail_points.append(world_pos)
	trail_ages.append(_elapsed)
	while trail_points.size() > max_trail_points:
		trail_points.pop_front()
		trail_ages.pop_front()

	# Update visuals
	_update_triangle()
	_update_trail()
	_trace_point_instance.position = world_pos


func _calculate_triangle_vertices() -> void:
	var half_base := triangle_side / 2.0
	var h := triangle_side * sqrt(3.0) / 2.0
	# Triangle in local XZ plane, centered at origin
	triangle_vertices = [
		Vector3(-half_base, 0.0, 0.0),
		Vector3(half_base, 0.0, 0.0),
		Vector3(0.0, 0.0, -h)
	]


func _transform_to_world(local_pos: Vector3) -> Vector3:
	# Place on the circle in XZ plane at y=0
	var center_on_circle := Vector3(
		circle_radius * cos(angle),
		0.0,
		circle_radius * sin(angle)
	)
	# Rotate local position by the rolling angle
	var rotated := Vector3(
		local_pos.x * cos(angle) - local_pos.z * sin(angle),
		local_pos.y,
		local_pos.x * sin(angle) + local_pos.z * cos(angle)
	)
	return center_on_circle + rotated


func _get_trace_local_position() -> Vector3:
	var v0 := triangle_vertices[edge_index]
	var v1 := triangle_vertices[(edge_index + 1) % triangle_vertices.size()]
	return v0.lerp(v1, trace_step)


func _update_trace_step(delta: float) -> void:
	trace_step += trace_speed * delta
	while trace_step >= 1.0:
		trace_step -= 1.0
		edge_index = (edge_index + 1) % triangle_vertices.size()


func _create_label() -> void:
	_label = Label3D.new()
	_label.text = "Triangle Circle Trace"
	_label.font_size = 32
	_label.position = Vector3(0.0, -0.3, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 1.0, 1.0)
	add_child(_label)


func _create_circle() -> void:
	_circle_mesh_instance = MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	_circle_mesh_instance.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = circle_color
	_circle_mesh_instance.material_override = mat

	# Draw circle in XZ plane at y=0
	var segments := 64
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		mesh.surface_set_color(circle_color)
		mesh.surface_add_vertex(Vector3(circle_radius * cos(a0), 0.0, circle_radius * sin(a0)))
		mesh.surface_set_color(circle_color)
		mesh.surface_add_vertex(Vector3(circle_radius * cos(a1), 0.0, circle_radius * sin(a1)))
	mesh.surface_end()

	add_child(_circle_mesh_instance)


func _create_triangle() -> void:
	_triangle_mesh_instance = MeshInstance3D.new()
	_triangle_mesh_instance.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = triangle_color
	_triangle_mesh_instance.material_override = mat

	add_child(_triangle_mesh_instance)


func _update_triangle() -> void:
	var mesh: ImmediateMesh = _triangle_mesh_instance.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Transform each vertex to world and draw edges
	var world_verts: Array[Vector3] = []
	for v in triangle_vertices:
		world_verts.append(_transform_to_world(v))

	for i in range(world_verts.size()):
		var j := (i + 1) % world_verts.size()
		mesh.surface_set_color(triangle_color)
		mesh.surface_add_vertex(world_verts[i])
		mesh.surface_set_color(triangle_color)
		mesh.surface_add_vertex(world_verts[j])

	mesh.surface_end()


func _create_trail() -> void:
	_trail_mesh_instance = MeshInstance3D.new()
	_trail_mesh_instance.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = trace_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh_instance.material_override = mat

	add_child(_trail_mesh_instance)


func _update_trail() -> void:
	var mesh: ImmediateMesh = _trail_mesh_instance.mesh
	mesh.clear_surfaces()

	if trail_points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var oldest_age := trail_ages[0]
	var newest_age := trail_ages[trail_ages.size() - 1]
	var age_range := newest_age - oldest_age
	if age_range < 0.001:
		age_range = 1.0

	for i in range(trail_points.size() - 1):
		var t := (trail_ages[i] - oldest_age) / age_range  # 0 = oldest, 1 = newest
		var alpha := t  # Fade: old = transparent, new = opaque
		var c := Color(trace_color.r, trace_color.g, trace_color.b, alpha * trace_color.a)
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(trail_points[i])
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(trail_points[i + 1])

	mesh.surface_end()


func _create_trace_point() -> void:
	_trace_point_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	sphere.radial_segments = 10
	sphere.rings = 5
	_trace_point_instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = point_color
	mat.emission_enabled = true
	mat.emission = point_color
	_trace_point_instance.material_override = mat

	add_child(_trace_point_instance)


func _exit_tree() -> void:
	for child in get_children():
		child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
