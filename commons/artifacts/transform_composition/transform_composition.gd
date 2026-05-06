extends Node3D
class_name TransformComposition

## Transform composition demonstrator — chain Rotate then Translate vs Translate
## then Rotate on a simple house shape. The results land in DIFFERENT places,
## showing that matrix multiplication is non-commutative: R·T ≠ T·R.
## VR sliders control rotation angle and translation distance.
## Buttons toggle which result is visible. Animated step-through.

# --- Configuration ---

@export var rotation_angle: float = 45.0   # degrees around Y
@export var translate_dist: float = 0.3    # along +X

# --- Colors ---

var color_original: Color = Color(0.85, 0.85, 0.9)   # White-ish
var color_order_a: Color = Color(0.35, 0.55, 1.0)     # Blue (R then T)
var color_order_b: Color = Color(1.0, 0.35, 0.3)      # Red  (T then R)
var color_ghost: Color = Color(0.5, 0.5, 0.55, 0.3)   # Faint ghost for intermediate

# --- Display state ---

var _show_a: bool = true
var _show_b: bool = true
var _anim_t: float = 1.0     # 0..1 animation progress (1 = fully composed)
var _animating: bool = false
var _anim_speed: float = 0.8

# --- House shape vertices (2D in XY plane, centered) ---

var _house_verts: Array[Vector3] = [
	Vector3(-0.06, 0.0,  0.0),   # bottom-left
	Vector3( 0.06, 0.0,  0.0),   # bottom-right
	Vector3( 0.06, 0.08, 0.0),   # top-right wall
	Vector3(-0.06, 0.08, 0.0),   # top-left wall
	Vector3( 0.0,  0.13, 0.0),   # roof peak
]

# Edge list: pairs of indices
var _house_edges: Array[int] = [
	0, 1,  1, 2,  2, 3,  3, 0,  # walls
	3, 4,  4, 2,                  # roof
]

# --- Nodes ---

var _shapes_mesh: MeshInstance3D         # ImmediateMesh for all shapes
var _shapes_mat: StandardMaterial3D
var _axes_mesh: MeshInstance3D           # grid axes reference
var _title_label: Label3D
var _neq_label: Label3D
var _matrix_a_label: Label3D
var _matrix_b_label: Label3D
var _legend_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D

# Sliders
var _rot_slider: Node
var _dist_slider: Node

# Buttons
var _btn_a: Node
var _btn_b: Node
var _btn_both: Node
var _btn_anim: Node

var _rack_panel: Node3D


func _ready() -> void:
	_build_axes()
	_build_shapes_mesh()
	_build_labels()
	_build_vr_controls()
	_redraw()


# ------------------------------------------------------------------
# Reference axes — faint X/Y lines so the viewer has context
# ------------------------------------------------------------------

func _build_axes() -> void:
	_axes_mesh = MeshInstance3D.new()
	_axes_mesh.name = "RefAxes"
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var axis_len = 0.5
	var axis_alpha = 0.25

	# X axis (red)
	im.surface_set_color(Color(1.0, 0.3, 0.3, axis_alpha))
	im.surface_add_vertex(Vector3(-axis_len, 0, 0))
	im.surface_set_color(Color(1.0, 0.3, 0.3, axis_alpha))
	im.surface_add_vertex(Vector3(axis_len, 0, 0))

	# Y axis (green)
	im.surface_set_color(Color(0.3, 1.0, 0.4, axis_alpha))
	im.surface_add_vertex(Vector3(0, -0.05, 0))
	im.surface_set_color(Color(0.3, 1.0, 0.4, axis_alpha))
	im.surface_add_vertex(Vector3(0, axis_len, 0))

	# Origin dot (small cross)
	var d = 0.008
	im.surface_set_color(Color(1.0, 1.0, 1.0, 0.4))
	im.surface_add_vertex(Vector3(-d, 0, 0))
	im.surface_set_color(Color(1.0, 1.0, 1.0, 0.4))
	im.surface_add_vertex(Vector3(d, 0, 0))
	im.surface_set_color(Color(1.0, 1.0, 1.0, 0.4))
	im.surface_add_vertex(Vector3(0, -d, 0))
	im.surface_set_color(Color(1.0, 1.0, 1.0, 0.4))
	im.surface_add_vertex(Vector3(0, d, 0))

	im.surface_end()
	_axes_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_axes_mesh.material_override = mat
	_axes_mesh.position = Vector3(0, 0.25, 0)
	add_child(_axes_mesh)


# ------------------------------------------------------------------
# Shapes mesh — rebuilt on parameter change
# ------------------------------------------------------------------

func _build_shapes_mesh() -> void:
	_shapes_mesh = MeshInstance3D.new()
	_shapes_mesh.name = "ShapesMesh"
	_shapes_mat = StandardMaterial3D.new()
	_shapes_mat.vertex_color_use_as_albedo = true
	_shapes_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shapes_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shapes_mesh.material_override = _shapes_mat
	_shapes_mesh.position = Vector3(0, 0.25, 0)
	add_child(_shapes_mesh)


func _redraw() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var rad = deg_to_rad(rotation_angle * _anim_t)
	var tx = translate_dist * _anim_t

	# --- Original house (white, always visible) ---
	_draw_house(im, _house_verts, color_original, 1.0)

	# --- Order A: Rotate first, then Translate ---
	if _show_a:
		var verts_a = _transform_verts(_house_verts, _make_rotate_y(rad))
		# Ghost of intermediate step (rotated only)
		_draw_house(im, verts_a, color_order_a, 0.25)
		# Final: translate the rotated result
		var verts_a_final = _transform_verts(verts_a, _make_translate(Vector3(tx, 0, 0)))
		_draw_house(im, verts_a_final, color_order_a, 0.9)

	# --- Order B: Translate first, then Rotate ---
	if _show_b:
		var verts_b = _transform_verts(_house_verts, _make_translate(Vector3(tx, 0, 0)))
		# Ghost of intermediate step (translated only)
		_draw_house(im, verts_b, color_order_b, 0.25)
		# Final: rotate the translated result
		var verts_b_final = _transform_verts(verts_b, _make_rotate_y(rad))
		_draw_house(im, verts_b_final, color_order_b, 0.9)

	im.surface_end()
	_shapes_mesh.mesh = im

	_update_matrix_labels()


func _draw_house(im: ImmediateMesh, verts: Array, col: Color, alpha: float) -> void:
	var c = Color(col.r, col.g, col.b, alpha)
	for i in range(0, _house_edges.size(), 2):
		im.surface_set_color(c)
		im.surface_add_vertex(verts[_house_edges[i]])
		im.surface_set_color(c)
		im.surface_add_vertex(verts[_house_edges[i + 1]])


# ------------------------------------------------------------------
# Transform helpers (manual 4x4 math for display clarity)
# ------------------------------------------------------------------

func _make_rotate_y(rad: float) -> Transform3D:
	var c = cos(rad)
	var s = sin(rad)
	return Transform3D(
		Basis(Vector3(c, 0, s), Vector3(0, 1, 0), Vector3(-s, 0, c)),
		Vector3.ZERO
	)


func _make_translate(offset: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, offset)


func _transform_verts(verts: Array, xform: Transform3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for v in verts:
		out.append(xform * v)
	return out


# Compose two transforms into a 4x4 matrix array for label display
func _compose_matrix(first: Transform3D, second: Transform3D) -> Transform3D:
	return second * first


func _format_matrix(xf: Transform3D) -> String:
	# Display as 4x4 homogeneous matrix
	var b = xf.basis
	var o = xf.origin
	return "|%5.2f %5.2f %5.2f %5.2f|\n|%5.2f %5.2f %5.2f %5.2f|\n|%5.2f %5.2f %5.2f %5.2f|\n|%5.2f %5.2f %5.2f %5.2f|" % [
		b.x.x, b.y.x, b.z.x, o.x,
		b.x.y, b.y.y, b.z.y, o.y,
		b.x.z, b.y.z, b.z.z, o.z,
		0.0,   0.0,   0.0,   1.0,
	]


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _build_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "TRANSFORM COMPOSITION"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.72, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	# Big "R·T ≠ T·R" — the key insight
	_neq_label = Label3D.new()
	_neq_label.name = "NeqLabel"
	_neq_label.text = "R\u00b7T \u2260 T\u00b7R"
	_neq_label.font_size = 36
	_neq_label.pixel_size = 0.001
	_neq_label.position = Vector3(0, 0.66, 0)
	_neq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_neq_label.modulate = Color(1.0, 0.9, 0.3)
	_neq_label.outline_size = 6
	_neq_label.outline_modulate = Color(0, 0, 0, 0.7)
	_neq_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_neq_label)

	# Subtitle
	var subtitle = Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Order matters in matrix multiplication"
	subtitle.font_size = 13
	subtitle.pixel_size = 0.001
	subtitle.position = Vector3(0, 0.62, 0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.75, 0.85, 0.9)
	subtitle.outline_size = 2
	subtitle.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(subtitle)

	# Matrix A label (blue — Rotate then Translate)
	_matrix_a_label = Label3D.new()
	_matrix_a_label.name = "MatrixALabel"
	_matrix_a_label.font_size = 12
	_matrix_a_label.pixel_size = 0.001
	_matrix_a_label.position = Vector3(-0.32, 0.52, 0)
	_matrix_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_matrix_a_label.modulate = color_order_a
	_matrix_a_label.outline_size = 2
	_matrix_a_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_matrix_a_label)

	# Matrix B label (red — Translate then Rotate)
	_matrix_b_label = Label3D.new()
	_matrix_b_label.name = "MatrixBLabel"
	_matrix_b_label.font_size = 12
	_matrix_b_label.pixel_size = 0.001
	_matrix_b_label.position = Vector3(0.12, 0.52, 0)
	_matrix_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_matrix_b_label.modulate = color_order_b
	_matrix_b_label.outline_size = 2
	_matrix_b_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_matrix_b_label)

	# Legend
	_legend_label = Label3D.new()
	_legend_label.name = "LegendLabel"
	_legend_label.text = "White = Original | Blue = R then T | Red = T then R"
	_legend_label.font_size = 11
	_legend_label.pixel_size = 0.001
	_legend_label.position = Vector3(0, 0.15, 0)
	_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend_label.modulate = Color(0.6, 0.6, 0.65, 0.8)
	_legend_label.outline_size = 2
	_legend_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_legend_label)

	# Info label (current params)
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 13
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, 0.11, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.85)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


func _update_matrix_labels() -> void:
	var rad = deg_to_rad(rotation_angle * _anim_t)
	var tx = translate_dist * _anim_t
	var rot = _make_rotate_y(rad)
	var trans = _make_translate(Vector3(tx, 0, 0))

	# Order A: Rotate first, then Translate => T * R
	var composed_a = _compose_matrix(rot, trans)
	if _matrix_a_label:
		_matrix_a_label.text = "T\u00b7R (Rotate then Translate):\n" + _format_matrix(composed_a)

	# Order B: Translate first, then Rotate => R * T
	var composed_b = _compose_matrix(trans, rot)
	if _matrix_b_label:
		_matrix_b_label.text = "R\u00b7T (Translate then Rotate):\n" + _format_matrix(composed_b)


func _update_info() -> void:
	if _info_label:
		_info_label.text = "Rotation: %.0f\u00b0 (Y-axis)   Translation: %.2f (X-axis)" % [
			rotation_angle, translate_dist
		]


# ------------------------------------------------------------------
# VR Controls — 2 sliders + 4 buttons
# ------------------------------------------------------------------

func _build_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_rack_panel = RackTpl.create_panel("TRANSFORMS", [
		[
			{"type": "slider_h", "label": "ROT", "default": -1.0},
			{"type": "slider_h", "label": "DIST", "default": -1.0},
		],
		[
			{"type": "button", "label": "A"},
			{"type": "button", "label": "B"},
			{"type": "button", "label": "A+B"},
			{"type": "button", "label": "PLAY"},
		],
	])
	_rack_panel.position = Vector3(0, -0.02, 0.35)
	_rack_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_rack_panel)
	_control_panel = _rack_panel

	# Extract slider references
	_rot_slider = _rack_panel.find_child("Param_0", true, false)
	_dist_slider = _rack_panel.find_child("Param_1", true, false)

	# Connect slider signals
	if _rot_slider and _rot_slider.has_signal("slider_moved"):
		_rot_slider.slider_moved.connect(_on_rot_slider)
	if _dist_slider and _dist_slider.has_signal("slider_moved"):
		_dist_slider.slider_moved.connect(_on_dist_slider)

	# Extract and connect button references
	_btn_a = _rack_panel.find_child("Btn_0", true, false)
	if _btn_a:
		var area = _btn_a.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _set_display(true, false))

	_btn_b = _rack_panel.find_child("Btn_1", true, false)
	if _btn_b:
		var area = _btn_b.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _set_display(false, true))

	_btn_both = _rack_panel.find_child("Btn_2", true, false)
	if _btn_both:
		var area = _btn_both.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _set_display(true, true))

	_btn_anim = _rack_panel.find_child("Btn_3", true, false)
	if _btn_anim:
		var area = _btn_anim.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _start_animation())

	call_deferred("_sync_all_sliders")


func _sync_slider(slider: Node, normalized: float) -> void:
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(clampf(normalized, 0.0, 1.0))


func _sync_all_sliders() -> void:
	_sync_slider(_rot_slider, rotation_angle / 180.0)
	_sync_slider(_dist_slider, translate_dist / 0.6)


# --- Slider callbacks ---

func _on_rot_slider(_pos) -> void:
	if _rot_slider and _rot_slider.has_method("get_normalized_value"):
		rotation_angle = _rot_slider.get_normalized_value() * 180.0
		_anim_t = 1.0
		_animating = false
		_update_info()
		_redraw()


func _on_dist_slider(_pos) -> void:
	if _dist_slider and _dist_slider.has_method("get_normalized_value"):
		translate_dist = _dist_slider.get_normalized_value() * 0.6
		_anim_t = 1.0
		_animating = false
		_update_info()
		_redraw()


# --- Button actions ---

func _set_display(a: bool, b: bool) -> void:
	_show_a = a
	_show_b = b
	_redraw()


func _start_animation() -> void:
	_anim_t = 0.0
	_animating = true


# ------------------------------------------------------------------
# Animation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _animating:
		return

	_anim_t += delta * _anim_speed
	if _anim_t >= 1.0:
		_anim_t = 1.0
		_animating = false

	_redraw()


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("rotation_angle"):
		rotation_angle = float(config_data["rotation_angle"])
	if config_data.has("translate_dist"):
		translate_dist = float(config_data["translate_dist"])
	_sync_all_sliders()
	_anim_t = 1.0
	_animating = false
	_update_info()
	_redraw()
