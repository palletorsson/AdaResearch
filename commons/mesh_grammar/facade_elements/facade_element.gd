class_name FacadeElement
extends Node3D

## Procedural facade element — builds geometry from element_type at runtime.
## Supports columns, openings, bands, surfaces, crowns, and zone panels.
## Driven by the 41 element definitions in facade_elements.json.

@export var element_type: String = "plain_wall"
@export var element_width: float = 1.0
@export var element_height: float = 1.0
@export var element_depth: float = 0.2
@export var primary_color: Color = Color(0.85, 0.82, 0.75)

# Additional parameters that can be set via config
var _taper: float = 0.85
var _inset: float = 0.03
var _frame_width: float = 0.1
var _profile: String = "cyma_recta"
var _rows: int = 4
var _cols: int = 1
var _count: int = 6
var _broken: bool = false
var _pediment_height: float = 0.3
var _scale_factor: float = 1.0
var _zone_template: String = "plinth"
var _order: String = "ionic"


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("element_type"):
		element_type = config_data["element_type"]
	if config_data.has("element_width"):
		element_width = config_data["element_width"]
	if config_data.has("element_height"):
		element_height = config_data["element_height"]
	if config_data.has("element_depth"):
		element_depth = config_data["element_depth"]
	if config_data.has("primary_color"):
		if config_data["primary_color"] is Color:
			primary_color = config_data["primary_color"]
		elif config_data["primary_color"] is String:
			primary_color = Color(config_data["primary_color"])
	if config_data.has("taper"):
		_taper = config_data["taper"]
	if config_data.has("inset"):
		_inset = config_data["inset"]
	if config_data.has("frame_width"):
		_frame_width = config_data["frame_width"]
	if config_data.has("profile"):
		_profile = config_data["profile"]
	if config_data.has("rows"):
		_rows = config_data["rows"]
	if config_data.has("cols"):
		_cols = config_data["cols"]
	if config_data.has("count"):
		_count = config_data["count"]
	if config_data.has("broken"):
		_broken = config_data["broken"]
	if config_data.has("pediment_height"):
		_pediment_height = config_data["pediment_height"]
	if config_data.has("height"):
		_pediment_height = config_data["height"]
	if config_data.has("scale"):
		_scale_factor = config_data["scale"]
	if config_data.has("template"):
		_zone_template = config_data["template"]
	if config_data.has("order"):
		_order = config_data["order"]
	if config_data.has("depth"):
		element_depth = config_data["depth"]

	# Rebuild if already in tree
	if is_inside_tree():
		_clear_children()
		_build_mesh()


func _ready() -> void:
	_build_mesh()


func _build_mesh() -> void:
	match element_type:
		# --- Columns ---
		"tuscan", "column_tuscan":
			_build_column(7.0, 0.4, 0.8)
		"doric", "column_doric":
			_build_column(8.0, 0.5, 0.83)
		"ionic", "column_ionic":
			_build_column(9.0, 0.6, 0.85)
		"corinthian", "column_corinthian":
			_build_column(10.0, 0.7, 0.87)
		"pilaster":
			_build_pilaster()
		# --- Openings ---
		"rect_window", "opening_rectangular", "window_rect", "window_rect_small":
			_build_rectangular_opening()
		"arched_window", "opening_arched", "window_arched":
			_build_arched_opening()
		"door", "door_rect":
			_build_rectangular_opening()
		"door_arched":
			_build_arched_opening()
		"arcade_arch":
			_build_arched_opening()
		# --- Bands ---
		"cyma_recta", "cornice_cyma_recta":
			_profile = "cyma_recta"
			_build_horizontal_band()
		"cyma_reversa", "cornice_cyma_reversa":
			_profile = "cyma_reversa"
			_build_horizontal_band()
		"ovolo", "cornice_ovolo":
			_profile = "ovolo"
			_build_horizontal_band()
		"dentil", "cornice_dentil":
			_build_dentil_band()
		"stepped", "cornice_stepped":
			_build_stepped_band()
		"string_course":
			_build_string_course()
		"horizontal_band":
			_build_horizontal_band()
		"fascia", "fascia_band":
			_profile = "fascia"
			_build_horizontal_band()
		# --- Surfaces ---
		"rusticated_block", "rustication", "rustication_block", "rustication_wide":
			_build_rusticated_block()
		"balustrade":
			_build_balustrade()
		"plain_wall", "plain", "wall_plain":
			_build_plain_wall()
		# --- Crowns ---
		"triangular_pediment", "pediment_triangular", "pediment":
			_build_triangular_pediment()
		"broken_pediment", "pediment_broken":
			_broken = true
			_build_triangular_pediment()
		"art_deco_crown":
			_build_stepped_band()
		# --- Zone panels ---
		"zone", "zone_plinth", "plinth":
			_zone_template = "plinth" if element_type in ["zone_plinth", "plinth"] else _zone_template
			_build_zone_panel()
		"zone_base", "rusticated_base":
			_zone_template = "base"
			_build_zone_panel()
		"zone_piano_nobile", "piano_nobile":
			_zone_template = "piano_nobile"
			_build_zone_panel()
		"zone_upper_story", "upper_story":
			_zone_template = "upper_story"
			_build_zone_panel()
		"zone_entablature", "entablature":
			_zone_template = "entablature"
			_build_zone_panel()
		"zone_arcade", "arcade":
			_zone_template = "arcade"
			_build_zone_panel()
		_:
			push_warning("FacadeElement: Unknown element_type '%s', building plain wall." % element_type)
			_build_plain_wall()


# =============================================================================
# HELPER METHODS
# =============================================================================

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _create_material(color: Color = primary_color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	return mat


func _add_mesh_instance(mesh: Mesh, offset: Vector3 = Vector3.ZERO, color: Color = primary_color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _create_material(color)
	mi.position = offset
	add_child(mi)
	return mi


## Build a box mesh via SurfaceTool at given position and size.
func _add_box(pos: Vector3, size: Vector3, color: Color = primary_color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5

	# 8 corners
	var corners := [
		Vector3(-hx, -hy, -hz), Vector3( hx, -hy, -hz),
		Vector3( hx,  hy, -hz), Vector3(-hx,  hy, -hz),
		Vector3(-hx, -hy,  hz), Vector3( hx, -hy,  hz),
		Vector3( hx,  hy,  hz), Vector3(-hx,  hy,  hz),
	]

	# 6 faces (quads as 2 tris each): [indices, normal]
	var faces := [
		[[0,1,2,3], Vector3( 0, 0,-1)],  # back
		[[5,4,7,6], Vector3( 0, 0, 1)],  # front
		[[4,0,3,7], Vector3(-1, 0, 0)],  # left
		[[1,5,6,2], Vector3( 1, 0, 0)],  # right
		[[3,2,6,7], Vector3( 0, 1, 0)],  # top
		[[4,5,1,0], Vector3( 0,-1, 0)],  # bottom
	]

	for face_data in faces:
		var idx: Array = face_data[0]
		var normal: Vector3 = face_data[1]
		var v0: Vector3 = corners[idx[0]]
		var v1: Vector3 = corners[idx[1]]
		var v2: Vector3 = corners[idx[2]]
		var v3: Vector3 = corners[idx[3]]
		# Tri 1
		st.set_normal(normal)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(v0)
		st.set_normal(normal)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(v1)
		st.set_normal(normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v2)
		# Tri 2
		st.set_normal(normal)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(v0)
		st.set_normal(normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v2)
		st.set_normal(normal)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v3)

	st.generate_tangents()
	var mesh := st.commit()
	return _add_mesh_instance(mesh, pos, color)


## Build a cylinder mesh via SurfaceTool.
func _add_cylinder(pos: Vector3, radius_bottom: float, radius_top: float, height: float, segments: int = 16, color: Color = primary_color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_h := height * 0.5

	# Build side faces
	for i in range(segments):
		var angle0 := TAU * float(i) / float(segments)
		var angle1 := TAU * float(i + 1) / float(segments)
		var cos0 := cos(angle0)
		var sin0 := sin(angle0)
		var cos1 := cos(angle1)
		var sin1 := sin(angle1)

		var b0 := Vector3(cos0 * radius_bottom, -half_h, sin0 * radius_bottom)
		var b1 := Vector3(cos1 * radius_bottom, -half_h, sin1 * radius_bottom)
		var t0 := Vector3(cos0 * radius_top, half_h, sin0 * radius_top)
		var t1 := Vector3(cos1 * radius_top, half_h, sin1 * radius_top)

		var n0 := Vector3(cos0, 0, sin0).normalized()
		var n1 := Vector3(cos1, 0, sin1).normalized()

		# Tri 1
		st.set_normal(n0)
		st.set_uv(Vector2(float(i) / segments, 1))
		st.add_vertex(b0)
		st.set_normal(n1)
		st.set_uv(Vector2(float(i + 1) / segments, 1))
		st.add_vertex(b1)
		st.set_normal(n1)
		st.set_uv(Vector2(float(i + 1) / segments, 0))
		st.add_vertex(t1)

		# Tri 2
		st.set_normal(n0)
		st.set_uv(Vector2(float(i) / segments, 1))
		st.add_vertex(b0)
		st.set_normal(n1)
		st.set_uv(Vector2(float(i + 1) / segments, 0))
		st.add_vertex(t1)
		st.set_normal(n0)
		st.set_uv(Vector2(float(i) / segments, 0))
		st.add_vertex(t0)

	# Top cap
	for i in range(segments):
		var angle0 := TAU * float(i) / float(segments)
		var angle1 := TAU * float(i + 1) / float(segments)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3(0, half_h, 0))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5 + cos(angle0) * 0.5, 0.5 + sin(angle0) * 0.5))
		st.add_vertex(Vector3(cos(angle0) * radius_top, half_h, sin(angle0) * radius_top))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5 + cos(angle1) * 0.5, 0.5 + sin(angle1) * 0.5))
		st.add_vertex(Vector3(cos(angle1) * radius_top, half_h, sin(angle1) * radius_top))

	# Bottom cap
	for i in range(segments):
		var angle0 := TAU * float(i) / float(segments)
		var angle1 := TAU * float(i + 1) / float(segments)
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3(0, -half_h, 0))
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2(0.5 + cos(angle1) * 0.5, 0.5 + sin(angle1) * 0.5))
		st.add_vertex(Vector3(cos(angle1) * radius_bottom, -half_h, sin(angle1) * radius_bottom))
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2(0.5 + cos(angle0) * 0.5, 0.5 + sin(angle0) * 0.5))
		st.add_vertex(Vector3(cos(angle0) * radius_bottom, -half_h, sin(angle0) * radius_bottom))

	st.generate_tangents()
	var mesh := st.commit()
	return _add_mesh_instance(mesh, pos, color)


## Build an arch profile (semicircular opening frame) via SurfaceTool.
func _add_arch_profile(pos: Vector3, width: float, height: float, depth: float, frame_w: float, arch_segments: int = 12, color: Color = primary_color) -> void:
	var hw := width * 0.5
	var arch_radius := hw

	# Straight sides (two vertical boxes for the jambs)
	var jamb_height := height - arch_radius
	if jamb_height > 0.0:
		_add_box(pos + Vector3(-hw + frame_w * 0.5, jamb_height * 0.5 - height * 0.5, 0),
			Vector3(frame_w, jamb_height, depth), color)
		_add_box(pos + Vector3( hw - frame_w * 0.5, jamb_height * 0.5 - height * 0.5, 0),
			Vector3(frame_w, jamb_height, depth), color)

	# Arch voussoirs
	var arch_center_y := pos.y + jamb_height - height * 0.5
	var inner_r := arch_radius - frame_w
	var outer_r := arch_radius

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_d := depth * 0.5

	for i in range(arch_segments):
		var a0 := PI * float(i) / float(arch_segments)
		var a1 := PI * float(i + 1) / float(arch_segments)

		var inner0 := Vector3(cos(a0) * inner_r, sin(a0) * inner_r, 0)
		var inner1 := Vector3(cos(a1) * inner_r, sin(a1) * inner_r, 0)
		var outer0 := Vector3(cos(a0) * outer_r, sin(a0) * outer_r, 0)
		var outer1 := Vector3(cos(a1) * outer_r, sin(a1) * outer_r, 0)

		# Front face quad
		var n := Vector3(0, 0, 1)
		_st_quad(st, n,
			pos + Vector3(inner0.x, arch_center_y + inner0.y, half_d),
			pos + Vector3(outer0.x, arch_center_y + outer0.y, half_d),
			pos + Vector3(outer1.x, arch_center_y + outer1.y, half_d),
			pos + Vector3(inner1.x, arch_center_y + inner1.y, half_d))

		# Back face quad
		n = Vector3(0, 0, -1)
		_st_quad(st, n,
			pos + Vector3(inner1.x, arch_center_y + inner1.y, -half_d),
			pos + Vector3(outer1.x, arch_center_y + outer1.y, -half_d),
			pos + Vector3(outer0.x, arch_center_y + outer0.y, -half_d),
			pos + Vector3(inner0.x, arch_center_y + inner0.y, -half_d))

	st.generate_tangents()
	var mesh := st.commit()
	_add_mesh_instance(mesh, Vector3.ZERO, color)


## Build a column with capital using the appropriate order style.
func _add_column_with_capital(pos: Vector3, col_width: float, col_height: float, taper: float, order: String, depth_ratio: float = 1.0, color: Color = primary_color) -> void:
	var radius_bottom := col_width * 0.5 * depth_ratio
	var radius_top := radius_bottom * taper

	# Base plinth
	var base_h := col_width * 0.4
	_add_box(pos + Vector3(0, base_h * 0.5, 0),
		Vector3(col_width * 1.2 * depth_ratio, base_h, col_width * 1.2 * depth_ratio), color)

	# Capital dimensions vary by order
	var capital_h := col_width * 0.5
	match order:
		"tuscan":
			capital_h = col_width * 0.4
		"doric":
			capital_h = col_width * 0.5
		"ionic":
			capital_h = col_width * 0.6
		"corinthian":
			capital_h = col_width * 0.7

	# Shaft
	var shaft_height := col_height - base_h - capital_h
	if shaft_height < 0.1:
		shaft_height = col_height * 0.7
		base_h = col_height * 0.1
		capital_h = col_height * 0.2

	_add_cylinder(pos + Vector3(0, base_h + shaft_height * 0.5, 0),
		radius_bottom, radius_top, shaft_height, 16, color)

	# Capital
	var cap_y := pos.y + base_h + shaft_height
	match order:
		"tuscan":
			# Simple square abacus + round echinus
			_add_box(Vector3(pos.x, cap_y + capital_h * 0.7, pos.z),
				Vector3(col_width * 1.3 * depth_ratio, capital_h * 0.3, col_width * 1.3 * depth_ratio), color)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.35, pos.z),
				radius_top, radius_top * 1.3, capital_h * 0.7, 16, color)
		"doric":
			# Wider abacus + echinus
			_add_box(Vector3(pos.x, cap_y + capital_h * 0.7, pos.z),
				Vector3(col_width * 1.4 * depth_ratio, capital_h * 0.3, col_width * 1.4 * depth_ratio), color)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.35, pos.z),
				radius_top, radius_top * 1.4, capital_h * 0.7, 16, color)
		"ionic":
			# Abacus + volute approximation (wider rectangular block)
			_add_box(Vector3(pos.x, cap_y + capital_h * 0.75, pos.z),
				Vector3(col_width * 1.5 * depth_ratio, capital_h * 0.25, col_width * 1.3 * depth_ratio), color)
			# Volute scroll (represented as wider flared cylinder)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.35, pos.z),
				radius_top, radius_top * 1.5, capital_h * 0.5, 16, color)
			# Side scrolls (small boxes for volute indication)
			_add_box(Vector3(pos.x - col_width * 0.7, cap_y + capital_h * 0.5, pos.z),
				Vector3(col_width * 0.3, capital_h * 0.4, col_width * 0.3), color)
			_add_box(Vector3(pos.x + col_width * 0.7, cap_y + capital_h * 0.5, pos.z),
				Vector3(col_width * 0.3, capital_h * 0.4, col_width * 0.3), color)
		"corinthian":
			# Abacus
			_add_box(Vector3(pos.x, cap_y + capital_h * 0.85, pos.z),
				Vector3(col_width * 1.5 * depth_ratio, capital_h * 0.15, col_width * 1.5 * depth_ratio), color)
			# Bell shape (flared cylinder)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.4, pos.z),
				radius_top, radius_top * 1.5, capital_h * 0.7, 16, color)
			# Acanthus leaf tiers (stacked rings)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.15, pos.z),
				radius_top * 1.1, radius_top * 1.2, capital_h * 0.2, 16, color)
			_add_cylinder(Vector3(pos.x, cap_y + capital_h * 0.35, pos.z),
				radius_top * 1.2, radius_top * 1.35, capital_h * 0.2, 16, color)
		_:
			# Fallback: simple box capital
			_add_box(Vector3(pos.x, cap_y + capital_h * 0.5, pos.z),
				Vector3(col_width * 1.3, capital_h, col_width * 1.3), color)


## Add a quad to a SurfaceTool (two triangles).
func _st_quad(st: SurfaceTool, normal: Vector3, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	st.set_normal(normal)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(v0)
	st.set_normal(normal)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(v1)
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v2)

	st.set_normal(normal)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(v0)
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v2)
	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(v3)


# =============================================================================
# BUILD METHODS
# =============================================================================

func _build_column(ratio: float, capital_fraction: float, taper: float) -> void:
	var col_width := element_width
	var col_height := element_height
	var actual_taper: float = _taper if _taper != 0.85 else taper
	_add_column_with_capital(Vector3(0, 0, 0), col_width, col_height, actual_taper, _order, 1.0, primary_color)


func _build_pilaster() -> void:
	var depth: float = element_depth if element_depth != 0.2 else 0.08
	var pilaster_taper: float = _taper if _taper != 0.85 else 0.95
	_add_column_with_capital(Vector3(0, 0, 0), element_width, element_height, pilaster_taper, _order, depth / (element_width * 0.5), primary_color)


func _build_rectangular_opening() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth
	var fw := _frame_width

	# Outer wall panel
	_add_box(Vector3.ZERO, Vector3(w, h, d), primary_color)

	# Cut void (inset, darker color to simulate depth)
	var void_w := w - fw * 2.0
	var void_h := h - fw * 2.0
	var void_color := primary_color.darkened(0.4)
	_add_box(Vector3(0, 0, _inset), Vector3(void_w, void_h, d + 0.01), void_color)

	# Frame surround (slightly proud of wall)
	var frame_depth := d + 0.02
	# Top
	_add_box(Vector3(0, (h - fw) * 0.5, 0.01), Vector3(w, fw, frame_depth), primary_color.lightened(0.05))
	# Bottom
	_add_box(Vector3(0, -(h - fw) * 0.5, 0.01), Vector3(w, fw, frame_depth), primary_color.lightened(0.05))
	# Left
	_add_box(Vector3(-(w - fw) * 0.5, 0, 0.01), Vector3(fw, h - fw * 2.0, frame_depth), primary_color.lightened(0.05))
	# Right
	_add_box(Vector3( (w - fw) * 0.5, 0, 0.01), Vector3(fw, h - fw * 2.0, frame_depth), primary_color.lightened(0.05))


func _build_arched_opening() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth
	var fw := _frame_width

	# Back wall
	_add_box(Vector3.ZERO, Vector3(w, h, d * 0.5), primary_color)

	# Arch frame
	_add_arch_profile(Vector3(0, 0, d * 0.3), w, h, d, fw, 16, primary_color.lightened(0.08))

	# Void (dark recessed area)
	var void_color := primary_color.darkened(0.5)
	var void_w := w - fw * 2.0
	var void_h := h - w * 0.5  # rectangular part below arch
	if void_h > 0.0:
		_add_box(Vector3(0, -h * 0.5 + void_h * 0.5, _inset),
			Vector3(void_w, void_h, d + 0.01), void_color)


func _build_horizontal_band() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth

	match _profile:
		"cyma_recta":
			# S-curve profile: main band + slight overhang
			_add_box(Vector3.ZERO, Vector3(w, h * 0.6, d), primary_color)
			_add_box(Vector3(0, h * 0.2, d * 0.3), Vector3(w, h * 0.4, d * 0.6), primary_color.lightened(0.05))
			_add_box(Vector3(0, -h * 0.3, d * 0.15), Vector3(w, h * 0.2, d * 0.3), primary_color.darkened(0.05))
		"cyma_reversa":
			# Reverse S-curve
			_add_box(Vector3.ZERO, Vector3(w, h * 0.6, d), primary_color)
			_add_box(Vector3(0, -h * 0.2, d * 0.3), Vector3(w, h * 0.4, d * 0.6), primary_color.lightened(0.05))
			_add_box(Vector3(0, h * 0.3, d * 0.15), Vector3(w, h * 0.2, d * 0.3), primary_color.darkened(0.05))
		"ovolo":
			# Quarter-round convex
			_add_box(Vector3.ZERO, Vector3(w, h * 0.7, d), primary_color)
			_add_box(Vector3(0, h * 0.15, d * 0.25), Vector3(w, h * 0.5, d * 0.5), primary_color.lightened(0.05))
		"fascia":
			# Flat projecting band
			_add_box(Vector3(0, 0, d * 0.25), Vector3(w, h, d * 0.5), primary_color)
			_add_box(Vector3.ZERO, Vector3(w, h * 0.8, d * 0.3), primary_color.darkened(0.03))
		"art_deco_stepped":
			_build_stepped_band()
		_:
			# Default: simple projecting band
			_add_box(Vector3(0, 0, d * 0.2), Vector3(w, h, d), primary_color)


func _build_dentil_band() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth

	# Base band
	_add_box(Vector3.ZERO, Vector3(w, h * 0.4, d * 0.5), primary_color)

	# Dentils (repeating teeth)
	var tooth_count := int(w / (h * 0.3)) + 1
	if tooth_count < 3:
		tooth_count = 3
	var tooth_w := w / float(tooth_count * 2)
	var lighter := primary_color.lightened(0.08)

	for i in range(tooth_count):
		var x_pos := -w * 0.5 + tooth_w * 0.5 + float(i) * (w / float(tooth_count))
		_add_box(Vector3(x_pos, h * 0.1, d * 0.3),
			Vector3(tooth_w, h * 0.6, d * 0.6), lighter)


func _build_stepped_band() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth
	var steps := 3

	for i in range(steps):
		var frac := float(i) / float(steps)
		var step_w := w * (1.0 - frac * 0.15)
		var step_h := h / float(steps)
		var step_d := d * (1.0 - frac * 0.3)
		var y_off := -h * 0.5 + step_h * (float(i) + 0.5)
		var z_off := d * frac * 0.2
		var step_color := primary_color.lightened(frac * 0.1)
		_add_box(Vector3(0, y_off, z_off), Vector3(step_w, step_h, step_d), step_color)


func _build_string_course() -> void:
	var w := element_width
	var h := element_height
	var d := maxf(element_depth, 0.02)
	_add_box(Vector3(0, 0, d * 0.5), Vector3(w, h, d), primary_color.lightened(0.03))


func _build_rusticated_block() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth
	var gap := 0.005

	var block_w := (w - gap * float(_cols + 1)) / float(_cols)
	var block_h := (h - gap * float(_rows + 1)) / float(_rows)

	for row in range(_rows):
		for col in range(_cols):
			var x := -w * 0.5 + gap + block_w * 0.5 + float(col) * (block_w + gap)
			var y := -h * 0.5 + gap + block_h * 0.5 + float(row) * (block_h + gap)
			# Alternate extrusion depth for rustication effect
			var offset_z: float = d * 0.5 if (row + col) % 2 == 0 else d * 0.3
			var block_color: Color = primary_color if (row + col) % 2 == 0 else primary_color.darkened(0.05)
			_add_box(Vector3(x, y, offset_z), Vector3(block_w, block_h, d), block_color)


func _build_balustrade() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth

	# Top and bottom rails
	var rail_h := h * 0.12
	_add_box(Vector3(0, h * 0.5 - rail_h * 0.5, 0), Vector3(w, rail_h, d), primary_color)
	_add_box(Vector3(0, -h * 0.5 + rail_h * 0.5, 0), Vector3(w, rail_h, d), primary_color)

	# Balusters
	var baluster_w := w / float(_count * 2)
	var baluster_h := h - rail_h * 2.0
	var spacing := w / float(_count)

	for i in range(_count):
		var x := -w * 0.5 + spacing * (float(i) + 0.5)
		_add_cylinder(Vector3(x, 0, 0), baluster_w * 0.5, baluster_w * 0.4, baluster_h, 8, primary_color.lightened(0.03))


func _build_plain_wall() -> void:
	_add_box(Vector3.ZERO, Vector3(element_width, element_height, maxf(element_depth, 0.02)), primary_color)


func _build_triangular_pediment() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth
	var peak_h := _pediment_height * w

	# Base entablature strip
	var base_h := h - peak_h
	if base_h < 0.05:
		base_h = h * 0.3
		peak_h = h * 0.7
	_add_box(Vector3(0, -h * 0.5 + base_h * 0.5, 0), Vector3(w, base_h, d), primary_color)

	# Pediment triangle via SurfaceTool
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w := w * 0.5
	var half_d := d * 0.5
	var base_y := -h * 0.5 + base_h
	var peak_y := base_y + peak_h

	# If broken pediment, leave gap at apex
	var gap_w: float = w * 0.15 if _broken else 0.0

	if _broken:
		# Left slope - front
		_st_quad(st, Vector3(0, 0, 1),
			Vector3(-half_w, base_y, half_d),
			Vector3(-gap_w, peak_y, half_d),
			Vector3(-gap_w, base_y, half_d),
			Vector3(-half_w, base_y, half_d))
		# Right slope - front
		_st_quad(st, Vector3(0, 0, 1),
			Vector3(gap_w, base_y, half_d),
			Vector3(gap_w, peak_y, half_d),
			Vector3(half_w, base_y, half_d),
			Vector3(gap_w, base_y, half_d))
		# Left slope - back
		_st_quad(st, Vector3(0, 0, -1),
			Vector3(-gap_w, base_y, -half_d),
			Vector3(-gap_w, peak_y, -half_d),
			Vector3(-half_w, base_y, -half_d),
			Vector3(-half_w, base_y, -half_d))
		# Right slope - back
		_st_quad(st, Vector3(0, 0, -1),
			Vector3(half_w, base_y, -half_d),
			Vector3(gap_w, peak_y, -half_d),
			Vector3(gap_w, base_y, -half_d),
			Vector3(gap_w, base_y, -half_d))
	else:
		# Full triangle - front face
		var n_front := Vector3(0, 0, 1)
		st.set_normal(n_front)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(Vector3(-half_w, base_y, half_d))
		st.set_normal(n_front)
		st.set_uv(Vector2(0.5, 0))
		st.add_vertex(Vector3(0, peak_y, half_d))
		st.set_normal(n_front)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(Vector3(half_w, base_y, half_d))

		# Full triangle - back face
		var n_back := Vector3(0, 0, -1)
		st.set_normal(n_back)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(Vector3(half_w, base_y, -half_d))
		st.set_normal(n_back)
		st.set_uv(Vector2(0.5, 0))
		st.add_vertex(Vector3(0, peak_y, -half_d))
		st.set_normal(n_back)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(Vector3(-half_w, base_y, -half_d))

	# Left slope side
	var slope_n_l := Vector3(-peak_h, half_w, 0).normalized()
	_st_quad(st, slope_n_l,
		Vector3(-half_w, base_y, -half_d),
		Vector3(-half_w, base_y, half_d) if not _broken else Vector3(-half_w, base_y, half_d),
		Vector3(-gap_w if _broken else 0, peak_y, half_d),
		Vector3(-gap_w if _broken else 0, peak_y, -half_d))

	# Right slope side
	var slope_n_r := Vector3(peak_h, half_w, 0).normalized()
	_st_quad(st, slope_n_r,
		Vector3(half_w, base_y, half_d),
		Vector3(half_w, base_y, -half_d),
		Vector3(gap_w if _broken else 0, peak_y, -half_d),
		Vector3(gap_w if _broken else 0, peak_y, half_d))

	st.generate_tangents()
	var mesh := st.commit()
	_add_mesh_instance(mesh, Vector3.ZERO, primary_color.lightened(0.05))


func _build_zone_panel() -> void:
	var w := element_width
	var h := element_height
	var d := element_depth

	match _zone_template:
		"plinth":
			# Heavy base block with subtle step
			_add_box(Vector3.ZERO, Vector3(w, h, d), primary_color.darkened(0.1))
			_add_box(Vector3(0, h * 0.2, d * 0.3), Vector3(w, h * 0.1, d * 0.3), primary_color)
		"base":
			# Rusticated base zone
			_rows = 3
			_cols = max(_cols, int(w / (h / 3.0)))
			if _cols < 1:
				_cols = 2
			_build_rusticated_block()
		"piano_nobile":
			# Principal story: wall + central arched opening + flanking pilasters
			_add_box(Vector3.ZERO, Vector3(w, h, d * 0.5), primary_color)
			# Central opening
			var opening_w := w * 0.35
			var opening_h := h * 0.75
			var void_color := primary_color.darkened(0.4)
			_add_box(Vector3(0, -h * 0.1, d * 0.1), Vector3(opening_w, opening_h, d + 0.01), void_color)
			# Flanking pilasters
			var pil_w := w * 0.08
			_add_box(Vector3(-w * 0.3, 0, d * 0.3), Vector3(pil_w, h * 0.9, d * 0.15), primary_color.lightened(0.05))
			_add_box(Vector3( w * 0.3, 0, d * 0.3), Vector3(pil_w, h * 0.9, d * 0.15), primary_color.lightened(0.05))
		"upper_story":
			# Simpler story with rectangular windows
			_add_box(Vector3.ZERO, Vector3(w, h, d * 0.5), primary_color)
			var win_w := w * 0.25
			var win_h := h * 0.55
			var void_color := primary_color.darkened(0.35)
			_add_box(Vector3(-w * 0.25, h * 0.05, d * 0.1), Vector3(win_w, win_h, d + 0.01), void_color)
			_add_box(Vector3( w * 0.25, h * 0.05, d * 0.1), Vector3(win_w, win_h, d + 0.01), void_color)
		"entablature":
			# Entablature: architrave + frieze + cornice
			var third := h / 3.0
			_add_box(Vector3(0, -h * 0.5 + third * 0.5, 0), Vector3(w, third, d), primary_color)
			_add_box(Vector3(0, -h * 0.5 + third * 1.5, d * 0.1), Vector3(w, third, d * 0.8), primary_color.lightened(0.03))
			_add_box(Vector3(0, -h * 0.5 + third * 2.5, d * 0.3), Vector3(w * 1.02, third, d * 0.6), primary_color.lightened(0.06))
		"arcade":
			# Arcade: series of arches with columns
			_add_box(Vector3.ZERO, Vector3(w, h, d * 0.3), primary_color)
			var arch_count := 3
			var arch_w := w / float(arch_count)
			var void_color := primary_color.darkened(0.45)
			for i in range(arch_count):
				var x := -w * 0.5 + arch_w * (float(i) + 0.5)
				var void_w := arch_w * 0.6
				var void_h := h * 0.75
				_add_box(Vector3(x, -h * 0.12, d * 0.1), Vector3(void_w, void_h, d + 0.01), void_color)
			# Column piers between arches
			var pier_w := arch_w * 0.2
			for i in range(arch_count + 1):
				var x := -w * 0.5 + arch_w * float(i)
				_add_box(Vector3(x, -h * 0.05, d * 0.25), Vector3(pier_w, h * 0.85, d * 0.25), primary_color.lightened(0.05))
		_:
			# Fallback: plain zone
			_build_plain_wall()
