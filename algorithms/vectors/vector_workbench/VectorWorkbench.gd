# @identity
# essence: a universal vector workbench — two draggable 3D vectors with live computed outputs for addition, subtraction, dot product, cross product, and projection
# desire: to make linear algebra touchable — the player grabs Vector A and Vector B in VR, moves them through space, and watches the dot product change as the angle between them changes; the formula is not read, it is felt
# critical_parameter: current_mode (Mode enum) — switches the display to highlight one operation at a time; ALL shows every result vector simultaneously, focused modes hide the others so the learner sees one relationship clearly
# triggers: _ready() spawns two draggable vectors + four result vectors + sliders + buttons; _process() reads current vector positions every frame and updates all five operations; slider_moved signals drive VR input path
# emerges: the parallelogram — when cross product mode is active, a filled parallelogram appears between A and B showing the magnitude of A×B as an area; the geometric interpretation of the cross product becomes visible space
# needs: apply_grid_config [has — stub]; VR slider controls [has — 6 component sliders]; mode buttons [has — 5 mode buttons]; keyboard mode switching [has — keys 1-5]; grab interaction [has via vector_scene_base]
# relationships: vectors sequence companion to vector_magnitude_demo; extends vector_scene_base (shared spawning, axes, floor); placed in Vectors_Intro map
# truth: a vector is not a number — it is a direction with commitment; VectorWorkbench proves this by making the commitment graspable and showing what two directions do to each other

extends "res://algorithms/vectors/shared/vector_scene_base.gd"

## Vector Workbench - Universal vector operation visualizer
## Two draggable vectors with live computed outputs for all major operations
## VR-compatible with interactable sliders and buttons

# Input vectors (draggable)
var vector_a: Node3D
var vector_b: Node3D

# Interactable controls (VR sliders and buttons)
var _slider_a_x: Node
var _slider_a_y: Node
var _slider_a_z: Node
var _slider_b_x: Node
var _slider_b_y: Node
var _slider_b_z: Node
var _btn_all: Node
var _btn_add: Node
var _btn_dot: Node
var _btn_cross: Node
var _btn_proj: Node
var _btn_reset: Node
var _use_sliders: bool = false  # True when sliders are controlling vectors

# Result vectors (computed, not grabbable)
var result_add: Node3D       # A + B
var result_sub: Node3D       # A - B  
var result_cross: Node3D     # A Ã— B
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

func _ready() -> void:
	super._ready()
	create_axes(2.0)
	create_floor(4.0)
	
	# Create input vectors - positioned for easy grabbing
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.2, 0.8, 0.3), COLOR_A, "Vector A")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.5, 0.3, 1.0), COLOR_B, "Vector B")
	
	# Create result vectors (not grabbable)
	result_add = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_ADD, "A + B", false)
	result_sub = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_SUB, "A - B", false)
	result_cross = spawn_vector(Vector3.ZERO, Vector3.ZERO, COLOR_CROSS, "A Ã— B", false)
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
	
	# Connect interactable controls (if present)
	_setup_interactables()

func _process(_delta):
	var a = _get_vector_fast(vector_a, _cache_a)
	var b = _get_vector_fast(vector_b, _cache_b)
	
	_update_addition(a, b)
	_update_subtraction(a, b)
	_update_dot_product(a, b)
	_update_cross_product(a, b)
	_update_projection(a, b)
	_update_info(a, b)

func _input(event: InputEvent) -> void:
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

func _update_visibility() -> void:
	# Show/hide result vectors based on mode
	var show_all = current_mode == Mode.ALL
	
	result_add.visible = show_all or current_mode == Mode.ADDITION
	result_sub.visible = show_all or current_mode == Mode.ADDITION
	angle_arc.visible = show_all or current_mode == Mode.DOT_PRODUCT
	result_cross.visible = show_all or current_mode == Mode.CROSS_PRODUCT
	parallelogram.visible = show_all or current_mode == Mode.CROSS_PRODUCT
	result_proj.visible = show_all or current_mode == Mode.PROJECTION

func _reset_vectors() -> void:
	_update_vector_fast(vector_a, Vector3(1.2, 0.8, 0.3), _cache_a)
	_update_vector_fast(vector_b, Vector3(0.5, 0.3, 1.0), _cache_b)

# === VECTOR OPERATIONS ===

func _update_addition(a: Vector3, b: Vector3) -> void:
	var sum = a + b
	var diff = a - b
	
	# A + B: tip-to-tail visualization
	# Position B at the tip of A, result goes from origin to tip of B
	_update_vector_fast(result_add, sum, _cache_add)
	_update_vector_fast(result_sub, diff, _cache_sub)

func _update_subtraction(_a: Vector3, b: Vector3) -> void:
	# Already handled in _update_addition
	pass

func _update_dot_product(a: Vector3, b: Vector3) -> void:
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

func _update_cross_product(a: Vector3, b: Vector3) -> void:
	var cross = a.cross(b)
	_update_vector_fast(result_cross, cross, _cache_cross)
	
	# Update parallelogram
	_update_parallelogram_mesh(a, b)

func _update_projection(a: Vector3, b: Vector3) -> void:
	var mag_b_sq = b.length_squared()
	if mag_b_sq < 0.0001:
		_update_vector_fast(result_proj, Vector3.ZERO, _cache_proj)
		return
	
	# proj_B(A) = (A Â· B / |B|Â²) * B
	var proj = (a.dot(b) / mag_b_sq) * b
	_update_vector_fast(result_proj, proj, _cache_proj)

# === VISUAL HELPERS ===

func _create_angle_arc() -> void:
	angle_arc = MeshInstance3D.new()
	angle_arc.name = "AngleArc"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.5, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	angle_arc.material_override = mat
	add_child(angle_arc)

func _create_parallelogram() -> void:
	parallelogram = MeshInstance3D.new()
	parallelogram.name = "Parallelogram"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.5, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	parallelogram.material_override = mat
	add_child(parallelogram)

func _update_angle_arc_mesh(dir_a: Vector3, dir_b: Vector3, radius: float, angle: float) -> void:
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

func _update_parallelogram_mesh(a: Vector3, b: Vector3) -> void:
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

func _update_info(a: Vector3, b: Vector3) -> void:
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
	lines.append("â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€")
	lines.append("A + B = (%.2f, %.2f, %.2f)" % [(a+b).x, (a+b).y, (a+b).z])
	lines.append("A - B = (%.2f, %.2f, %.2f)" % [(a-b).x, (a-b).y, (a-b).z])
	lines.append("â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€")
	lines.append("A Â· B = %.2f   Î¸ = %.1fÂ°" % [dot, angle_deg])
	lines.append("A Ã— B = (%.2f, %.2f, %.2f)  |AÃ—B| = %.2f" % [cross.x, cross.y, cross.z, cross.length()])
	lines.append("â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€")
	lines.append("proj_B(A) = (%.2f, %.2f, %.2f)" % [proj.x, proj.y, proj.z])
	lines.append("")
	lines.append("[1] All  [2] Add  [3] Dot  [4] Cross  [5] Proj  [R] Reset")
	
	info_label.text = "\n".join(lines)

# === CACHING (local copy for independence) ===

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
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

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

# === INTERACTABLES INTEGRATION ===

func _setup_interactables() -> void:
	"""Connect to interactable sliders and buttons for VR control"""
	# Find control panel
	var panel = get_node_or_null("ControlPanel")
	if not panel:
		print("VectorWorkbench: No ControlPanel found, using keyboard controls only")
		return
	
	# Vector A sliders
	_slider_a_x = panel.get_node_or_null("SliderA_X")
	_slider_a_y = panel.get_node_or_null("SliderA_Y")
	_slider_a_z = panel.get_node_or_null("SliderA_Z")
	
	# Vector B sliders
	_slider_b_x = panel.get_node_or_null("SliderB_X")
	_slider_b_y = panel.get_node_or_null("SliderB_Y")
	_slider_b_z = panel.get_node_or_null("SliderB_Z")
	
	# Mode buttons
	var btn_container = panel.get_node_or_null("ModeButtons")
	if btn_container:
		_btn_all = btn_container.get_node_or_null("BtnAll")
		_btn_add = btn_container.get_node_or_null("BtnAdd")
		_btn_dot = btn_container.get_node_or_null("BtnDot")
		_btn_cross = btn_container.get_node_or_null("BtnCross")
		_btn_proj = btn_container.get_node_or_null("BtnProj")
		_btn_reset = btn_container.get_node_or_null("BtnReset")
	
	# Connect slider signals
	_connect_slider(_slider_a_x, "_on_slider_a_x", -2.0, 2.0, "A.x")
	_connect_slider(_slider_a_y, "_on_slider_a_y", -2.0, 2.0, "A.y")
	_connect_slider(_slider_a_z, "_on_slider_a_z", -2.0, 2.0, "A.z")
	_connect_slider(_slider_b_x, "_on_slider_b_x", -2.0, 2.0, "B.x")
	_connect_slider(_slider_b_y, "_on_slider_b_y", -2.0, 2.0, "B.y")
	_connect_slider(_slider_b_z, "_on_slider_b_z", -2.0, 2.0, "B.z")
	
	# Connect button signals
	_connect_button(_btn_all, "_on_btn_all")
	_connect_button(_btn_add, "_on_btn_add")
	_connect_button(_btn_dot, "_on_btn_dot")
	_connect_button(_btn_cross, "_on_btn_cross")
	_connect_button(_btn_proj, "_on_btn_proj")
	_connect_button(_btn_reset, "_on_btn_reset")
	
	# Initialize slider positions to match initial vectors
	call_deferred("_sync_sliders_to_vectors")
	
	print("VectorWorkbench: Interactables connected for VR control")

func _connect_slider(slider: Node, callback: String, range_min: float, range_max: float, label: String) -> void:
	if not slider:
		return
	if slider.has_method("set_range"):
		slider.set_range(range_min, range_max)
	if slider.has_method("set_param_name"):
		slider.set_param_name(label)
	if slider.has_signal("slider_moved"):
		slider.slider_moved.connect(Callable(self, callback))

func _connect_button(btn: Node, callback: String) -> void:
	if not btn:
		return
	if btn.has_signal("pressed"):
		btn.pressed.connect(Callable(self, callback))

func _sync_sliders_to_vectors() -> void:
	"""Sync slider positions to current vector values"""
	var a = _get_vector_fast(vector_a, _cache_a)
	var b = _get_vector_fast(vector_b, _cache_b)
	
	_set_slider_value(_slider_a_x, a.x, -2.0, 2.0)
	_set_slider_value(_slider_a_y, a.y, -2.0, 2.0)
	_set_slider_value(_slider_a_z, a.z, -2.0, 2.0)
	_set_slider_value(_slider_b_x, b.x, -2.0, 2.0)
	_set_slider_value(_slider_b_y, b.y, -2.0, 2.0)
	_set_slider_value(_slider_b_z, b.z, -2.0, 2.0)

func _set_slider_value(slider: Node, value: float, range_min: float, range_max: float) -> void:
	if not slider or not slider.has_method("set_normalized_value"):
		return
	var norm = remap(value, range_min, range_max, 0.0, 1.0)
	slider.set_normalized_value(clamp(norm, 0.0, 1.0))

# Slider callbacks
func _on_slider_a_x(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_a_x, pos, -2.0, 2.0)
	var a = _get_vector_fast(vector_a, _cache_a)
	_update_vector_fast(vector_a, Vector3(val, a.y, a.z), _cache_a)

func _on_slider_a_y(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_a_y, pos, -2.0, 2.0)
	var a = _get_vector_fast(vector_a, _cache_a)
	_update_vector_fast(vector_a, Vector3(a.x, val, a.z), _cache_a)

func _on_slider_a_z(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_a_z, pos, -2.0, 2.0)
	var a = _get_vector_fast(vector_a, _cache_a)
	_update_vector_fast(vector_a, Vector3(a.x, a.y, val), _cache_a)

func _on_slider_b_x(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_b_x, pos, -2.0, 2.0)
	var b = _get_vector_fast(vector_b, _cache_b)
	_update_vector_fast(vector_b, Vector3(val, b.y, b.z), _cache_b)

func _on_slider_b_y(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_b_y, pos, -2.0, 2.0)
	var b = _get_vector_fast(vector_b, _cache_b)
	_update_vector_fast(vector_b, Vector3(b.x, val, b.z), _cache_b)

func _on_slider_b_z(pos) -> void:
	_use_sliders = true
	var val = _slider_to_value(_slider_b_z, pos, -2.0, 2.0)
	var b = _get_vector_fast(vector_b, _cache_b)
	_update_vector_fast(vector_b, Vector3(b.x, b.y, val), _cache_b)

func _slider_to_value(slider: Node, pos, range_min: float, range_max: float) -> float:
	if not slider or not slider.has_method("get_normalized_value"):
		return 0.0
	var norm = slider.get_normalized_value()
	return lerp(range_min, range_max, norm)

# Button callbacks
func _on_btn_all() -> void:
	current_mode = Mode.ALL
	_update_visibility()

func _on_btn_add() -> void:
	current_mode = Mode.ADDITION
	_update_visibility()

func _on_btn_dot() -> void:
	current_mode = Mode.DOT_PRODUCT
	_update_visibility()

func _on_btn_cross() -> void:
	current_mode = Mode.CROSS_PRODUCT
	_update_visibility()

func _on_btn_proj() -> void:
	current_mode = Mode.PROJECTION
	_update_visibility()

func _on_btn_reset() -> void:
	_reset_vectors()
	_sync_sliders_to_vectors()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
