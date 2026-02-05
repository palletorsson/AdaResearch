extends "res://algorithms/vectors/shared/vector_scene_base.gd"

## Vector Workbench - Universal vector operation visualizer
## Two draggable vectors with live computed outputs for all major operations

# Input vectors (draggable)
var vector_a: Node3D
var vector_b: Node3D

# Result vectors (computed, not grabbable)
var result_add: Node3D       # A + B
var result_sub: Node3D       # A - B  
var result_cross: Node3D     # A × B
var result_proj: Node3D      # proj_B(A) - projection of A onto B

# Visual elements
var angle_arc: MeshInstance3D
var parallelogram: MeshInstance3D
var info_label: Label3D

# Display modes
enum Mode { ALL, ADDITION, DOT_PRODUCT, CROSS_PRODUCT, PROJECTION }
var current_mode: Mode = Mode.ALL

# Cached nodes for performance
var _cache_a: Dictionary = {}
var _cache_b: Dictionary = {}
var _cache_add: Dictionary = {}
var _cache_sub: Dictionary = {}
var _cache_cross: Dictionary = {}
var _cache_proj: Dictionary = {}

# Colors
const COLOR_A := Color(0.95, 0.4, 0.3)      # Red-orange
const COLOR_B := Color(0.3, 0.7, 0.95)      # Blue
const COLOR_ADD := Color(0.95, 0.85, 0.2)   # Yellow (resultant)
const COLOR_SUB := Color(0.7, 0.5, 0.9)     # Purple
const COLOR_CROSS := Color(0.3, 0.95, 0.5)  # Green (perpendicular)
const COLOR_PROJ := Color(0.95, 0.6, 0.8)   # Pink

func _ready():
	super._ready()
	create_axes(2.0)
	create_floor(4.0)
	
	# Create input vectors - positioned for easy grabbing
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.2, 0.8, 0.3), COLOR_A, "Vector A")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.5, 0.3, 1.0), COLOR_B, "Vector B")
	
	# Create result vectors (not grabbable)
	result_add = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_ADD, "A + B", false)
	result_sub = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_SUB, "A - B", false)
	result_cross = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_CROSS, "A × B", false)
	result_proj = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_PROJ, "proj", false)
	
	# Create visual elements
	_create_angle_arc()
	_create_parallelogram()
	
	# Info panel
	info_label = create_info_panel("Vector Workbench", Vector3(1.8, 1.0, 0.0), Vector2(2.2, 1.4))
	
	# Cache nodes
	_cache_vector_nodes(vector_a, _cache_a)
	_cache_vector_nodes(vector_b, _cache_b)
	_cache_vector_nodes(result_add, _cache_add)
	_cache_vector_nodes(result_sub, _cache_sub)
	_cache_vector_nodes(result_cross, _cache_cross)
	_cache_vector_nodes(result_proj, _cache_proj)

func _process(_delta):
	var a = _get_vector_fast(vector_a, _cache_a)
	var b = _get_vector_fast(vector_b, _cache_b)
	
	_update_addition(a, b)
	_update_subtraction(a, b)
	_update_dot_product(a, b)
	_update_cross_product(a, b)
	_update_projection(a, b)
	_update_info(a, b)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				current_mode = Mode.ALL
				_update_visibility()
			KEY_2:
				current_mode = Mode.ADDITION
				_update_visibility()
			KEY_3:
				current_mode = Mode.DOT_PRODUCT
				_update_visibility()
			KEY_4:
				current_mode = Mode.CROSS_PRODUCT
				_update_visibility()
			KEY_5:
				current_mode = Mode.PROJECTION
				_update_visibility()
			KEY_R:
				_reset_vectors()

func _update_visibility():
	# Show/hide result vectors based on mode
	var show_all = current_mode == Mode.ALL
	
	result_add.visible = show_all or current_mode == Mode.ADDITION
	result_sub.visible = show_all or current_mode == Mode.ADDITION
	angle_arc.visible = show_all or current_mode == Mode.DOT_PRODUCT
	result_cross.visible = show_all or current_mode == Mode.CROSS_PRODUCT
	parallelogram.visible = show_all or current_mode == Mode.CROSS_PRODUCT
	result_proj.visible = show_all or current_mode == Mode.PROJECTION

func _reset_vectors():
	_update_vector_fast(vector_a, Vector3(1.2, 0.8, 0.3), _cache_a)
	_update_vector_fast(vector_b, Vector3(0.5, 0.3, 1.0), _cache_b)

# === VECTOR OPERATIONS ===

func _update_addition(a: Vector3, b: Vector3):
	var sum = a + b
	var diff = a - b
	
	# A + B: tip-to-tail visualization
	# Position B at the tip of A, result goes from origin to tip of B
	_update_vector_fast(result_add, sum, _cache_add)
	_update_vector_fast(result_sub, diff, _cache_sub)

func _update_subtraction(a: Vector3, b: Vector3):
	# Already handled in _update_addition
	pass

func _update_dot_product(a: Vector3, b: Vector3):
	# Update angle arc visualization
	var mag_a = a.length()
	var mag_b = b.length()
	
	if mag_a < 0.001 or mag_b < 0.001:
		angle_arc.visible = false
		return
	
	angle_arc.visible = current_mode == Mode.ALL or current_mode == Mode.DOT_PRODUCT
	
	var angle = a.angle_to(b)
	var arc_radius = min(mag_a, mag_b) * 0.3 * SCENE_SCALE
	
	# Create arc mesh between vectors
	_update_angle_arc_mesh(a.normalized(), b.normalized(), arc_radius, angle)

func _update_cross_product(a: Vector3, b: Vector3):
	var cross = a.cross(b)
	_update_vector_fast(result_cross, cross, _cache_cross)
	
	# Update parallelogram
	_update_parallelogram_mesh(a, b)

func _update_projection(a: Vector3, b: Vector3):
	var mag_b_sq = b.length_squared()
	if mag_b_sq < 0.0001:
		_update_vector_fast(result_proj, Vector3.ZERO, _cache_proj)
		return
	
	# proj_B(A) = (A · B / |B|²) * B
	var proj = (a.dot(b) / mag_b_sq) * b
	_update_vector_fast(result_proj, proj, _cache_proj)

# === VISUAL HELPERS ===

func _create_angle_arc():
	angle_arc = MeshInstance3D.new()
	angle_arc.name = "AngleArc"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.5, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	angle_arc.material_override = mat
	add_child(angle_arc)

func _create_parallelogram():
	parallelogram = MeshInstance3D.new()
	parallelogram.name = "Parallelogram"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.5, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	parallelogram.material_override = mat
	add_child(parallelogram)

func _update_angle_arc_mesh(dir_a: Vector3, dir_b: Vector3, radius: float, angle: float):
	if angle < 0.01:
		angle_arc.mesh = null
		return
	
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Build arc as triangle fan manually (center + arc segments)
	var segments = 16
	var center = Vector3.ZERO
	
	for i in range(segments):
		var t0 = float(i) / float(segments)
		var t1 = float(i + 1) / float(segments)
		var p0 = dir_a.slerp(dir_b, t0) * radius
		var p1 = dir_a.slerp(dir_b, t1) * radius
		
		# Triangle: center, p0, p1
		im.surface_add_vertex(center)
		im.surface_add_vertex(p0)
		im.surface_add_vertex(p1)
	
	im.surface_end()
	angle_arc.mesh = im

func _update_parallelogram_mesh(a: Vector3, b: Vector3):
	if a.length() < 0.001 or b.length() < 0.001:
		parallelogram.mesh = null
		return
	
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# Parallelogram corners: O, A, A+B, B
	var scaled_a = a * SCENE_SCALE
	var scaled_b = b * SCENE_SCALE
	
	im.surface_add_vertex(Vector3.ZERO)
	im.surface_add_vertex(scaled_a)
	im.surface_add_vertex(scaled_b)
	im.surface_add_vertex(scaled_a + scaled_b)
	
	im.surface_end()
	parallelogram.mesh = im

func _update_info(a: Vector3, b: Vector3):
	var mag_a = a.length()
	var mag_b = b.length()
	var dot = a.dot(b)
	var cross = a.cross(b)
	var angle_rad = a.angle_to(b) if mag_a > 0.001 and mag_b > 0.001 else 0.0
	var angle_deg = rad_to_deg(angle_rad)
	
	# Projection
	var proj = Vector3.ZERO
	if mag_b > 0.001:
		proj = (dot / (mag_b * mag_b)) * b
	
	var lines := []
	lines.append("A = (%.2f, %.2f, %.2f)  |A| = %.2f" % [a.x, a.y, a.z, mag_a])
	lines.append("B = (%.2f, %.2f, %.2f)  |B| = %.2f" % [b.x, b.y, b.z, mag_b])
	lines.append("─────────────────────────────")
	lines.append("A + B = (%.2f, %.2f, %.2f)" % [(a+b).x, (a+b).y, (a+b).z])
	lines.append("A - B = (%.2f, %.2f, %.2f)" % [(a-b).x, (a-b).y, (a-b).z])
	lines.append("─────────────────────────────")
	lines.append("A · B = %.2f   θ = %.1f°" % [dot, angle_deg])
	lines.append("A × B = (%.2f, %.2f, %.2f)  |A×B| = %.2f" % [cross.x, cross.y, cross.z, cross.length()])
	lines.append("─────────────────────────────")
	lines.append("proj_B(A) = (%.2f, %.2f, %.2f)" % [proj.x, proj.y, proj.z])
	lines.append("")
	lines.append("[1] All  [2] Add  [3] Dot  [4] Cross  [5] Proj  [R] Reset")
	
	info_label.text = "\n".join(lines)

# === CACHING (local copy for independence) ===

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return (end.global_position - start.global_position) / SCENE_SCALE
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
