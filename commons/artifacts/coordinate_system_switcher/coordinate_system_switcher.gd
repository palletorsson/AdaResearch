extends Node3D
class_name CoordinateSystemSwitcher

## Coordinate System Switcher — shows the same 3D point in Cartesian, Cylindrical,
## and Spherical coordinates simultaneously. ImmediateMesh axes/arcs, SphereMesh point,
## Label3D readouts. Color-coded: Cartesian=RGB, Cylindrical=yellow, Spherical=magenta.

# --- Configuration ---

@export var point_cartesian: Vector3 = Vector3(0.25, 0.3, 0.2)
@export var axis_length: float = 0.45
@export var axis_thickness: float = 0.003
@export var arc_segments: int = 32

# --- Colors ---

var color_x: Color = Color(1.0, 0.3, 0.3)       # Red
var color_y: Color = Color(0.3, 1.0, 0.3)        # Green
var color_z: Color = Color(0.3, 0.5, 1.0)        # Blue
var color_cyl: Color = Color(1.0, 0.9, 0.2)      # Yellow — cylindrical
var color_sph: Color = Color(0.9, 0.3, 0.9)      # Magenta — spherical
var color_proj: Color = Color(0.5, 0.5, 0.5, 0.5) # Gray — projection lines
var color_point: Color = Color(1.0, 1.0, 1.0)
var color_panel: Color = Color(0.06, 0.06, 0.1)

# --- Internal ---

var _axes_mesh: MeshInstance3D
var _proj_mesh: MeshInstance3D
var _arcs_mesh: MeshInstance3D
var _point_sphere: MeshInstance3D
var _cart_label: Label3D
var _cyl_label: Label3D
var _sph_label: Label3D
var _title_label: Label3D


func _ready() -> void:
	_build_axes()
	_build_point()
	_build_projections()
	_build_arcs()
	_build_labels()


# --- Axes: X (red), Y (green), Z (blue) with arrowheads and letter labels ---

func _build_axes() -> void:
	_axes_mesh = MeshInstance3D.new()
	_axes_mesh.name = "AxesMesh"

	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw each axis with a small arrowhead
	_draw_axis_line(mesh, Vector3.ZERO, Vector3(axis_length, 0, 0), color_x)
	_draw_axis_line(mesh, Vector3.ZERO, Vector3(0, axis_length, 0), color_y)
	_draw_axis_line(mesh, Vector3.ZERO, Vector3(0, 0, axis_length), color_z)

	# Arrowheads
	_draw_arrowhead(mesh, Vector3(axis_length, 0, 0), Vector3.RIGHT, color_x)
	_draw_arrowhead(mesh, Vector3(0, axis_length, 0), Vector3.UP, color_y)
	_draw_arrowhead(mesh, Vector3(0, 0, axis_length), Vector3.BACK, color_z)

	# Grid lines on XZ plane (faint)
	var grid_color = Color(0.25, 0.25, 0.3, 0.3)
	var grid_step = 0.1
	var grid_count = int(axis_length / grid_step)
	for i in range(1, grid_count + 1):
		var v = i * grid_step
		# Lines parallel to X
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(0, 0, v))
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(axis_length, 0, v))
		# Lines parallel to Z
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(v, 0, 0))
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(v, 0, axis_length))

	mesh.surface_end()
	_axes_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_axes_mesh.material_override = mat
	add_child(_axes_mesh)

	# Axis letter labels
	_add_axis_label("X", Vector3(axis_length + 0.03, 0, 0), color_x)
	_add_axis_label("Y", Vector3(0, axis_length + 0.03, 0), color_y)
	_add_axis_label("Z", Vector3(0, 0, axis_length + 0.03), color_z)


func _draw_axis_line(mesh: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(to)


func _draw_arrowhead(mesh: ImmediateMesh, tip: Vector3, dir: Vector3, color: Color) -> void:
	var head_len = 0.025
	var head_width = 0.012
	var perp = Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.95:
		perp = Vector3.RIGHT
	var side = dir.cross(perp).normalized()

	var base = tip - dir * head_len
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(base + side * head_width)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(base - side * head_width)


func _add_axis_label(text: String, pos: Vector3, color: Color) -> void:
	var lbl = Label3D.new()
	lbl.name = "Axis_%s" % text
	lbl.text = text
	lbl.font_size = 22
	lbl.pixel_size = 0.001
	lbl.position = pos
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0, 0, 0, 0.6)
	add_child(lbl)


# --- The point itself ---

func _build_point() -> void:
	_point_sphere = MeshInstance3D.new()
	_point_sphere.name = "Point"
	var sphere = SphereMesh.new()
	sphere.radius = 0.018
	sphere.height = 0.036
	_point_sphere.mesh = sphere
	_point_sphere.position = point_cartesian

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_point
	mat.emission_enabled = true
	mat.emission = color_point
	mat.emission_energy_multiplier = 1.2
	_point_sphere.material_override = mat
	add_child(_point_sphere)


# --- Projection lines: show how each system maps to the point ---

func _build_projections() -> void:
	_proj_mesh = MeshInstance3D.new()
	_proj_mesh.name = "ProjectionLines"

	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var p = point_cartesian

	# Cartesian projection: dashed lines from point to each axis plane
	# Drop to XZ plane (project y)
	var p_xz = Vector3(p.x, 0, p.z)
	_draw_dashed_line(mesh, p, p_xz, color_proj, 6)
	# From XZ projection to X axis
	_draw_dashed_line(mesh, p_xz, Vector3(p.x, 0, 0), color_proj, 4)
	# From XZ projection to Z axis
	_draw_dashed_line(mesh, p_xz, Vector3(0, 0, p.z), color_proj, 4)
	# Vertical from origin to Y
	_draw_dashed_line(mesh, Vector3(0, 0, 0), Vector3(0, p.y, 0), color_y * Color(1, 1, 1, 0.5), 4)
	# From Y axis to point
	_draw_dashed_line(mesh, Vector3(0, p.y, 0), p, color_proj, 5)

	# Cylindrical: r on XZ plane, then vertical to y
	var r_cyl = Vector2(p.x, p.z).length()
	# Radial line from origin to XZ projection (cylindrical r)
	mesh.surface_set_color(color_cyl)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_set_color(color_cyl)
	mesh.surface_add_vertex(p_xz)
	# Vertical from XZ projection up to point (cylindrical z)
	mesh.surface_set_color(color_cyl)
	mesh.surface_add_vertex(p_xz)
	mesh.surface_set_color(color_cyl)
	mesh.surface_add_vertex(p)

	# Spherical: rho from origin to point
	mesh.surface_set_color(color_sph)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_set_color(color_sph)
	mesh.surface_add_vertex(p)

	mesh.surface_end()
	_proj_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_proj_mesh.material_override = mat
	add_child(_proj_mesh)


func _draw_dashed_line(mesh: ImmediateMesh, from: Vector3, to: Vector3, color: Color, segments: int) -> void:
	var dir = to - from
	for i in range(0, segments, 2):
		var t0 = float(i) / segments
		var t1 = float(i + 1) / segments
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(from + dir * t0)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(from + dir * t1)


# --- Arcs: theta (cylindrical/spherical) and phi (spherical) ---

func _build_arcs() -> void:
	_arcs_mesh = MeshInstance3D.new()
	_arcs_mesh.name = "ArcsMesh"

	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var p = point_cartesian
	var r_cyl = Vector2(p.x, p.z).length()
	var rho = p.length()

	# Cylindrical theta arc (yellow) — angle from +X axis in XZ plane
	var theta = atan2(p.z, p.x)
	if theta < 0:
		theta += TAU
	var arc_r = minf(r_cyl * 0.4, 0.1)
	_draw_arc_xz(mesh, arc_r, 0.0, theta, color_cyl)

	# Spherical phi arc (magenta) — polar angle from +Y axis down
	var phi = acos(clampf(p.y / rho, -1.0, 1.0)) if rho > 0.001 else 0.0
	var sph_arc_r = minf(rho * 0.35, 0.1)
	_draw_arc_polar(mesh, sph_arc_r, theta, phi, color_sph)

	# Spherical theta arc (same as cylindrical but drawn slightly offset in magenta)
	var sph_theta_r = arc_r * 1.15
	_draw_arc_xz(mesh, sph_theta_r, 0.0, theta, color_sph * Color(1, 1, 1, 0.6))

	mesh.surface_end()
	_arcs_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_arcs_mesh.material_override = mat
	add_child(_arcs_mesh)


func _draw_arc_xz(mesh: ImmediateMesh, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	# Arc in the XZ plane at y=0
	var steps = arc_segments
	var angle_span = end_angle - start_angle
	for i in range(steps):
		var a0 = start_angle + angle_span * float(i) / steps
		var a1 = start_angle + angle_span * float(i + 1) / steps
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(cos(a0) * radius, 0, sin(a0) * radius))
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(cos(a1) * radius, 0, sin(a1) * radius))


func _draw_arc_polar(mesh: ImmediateMesh, radius: float, azimuth: float, polar_angle: float, color: Color) -> void:
	# Arc from +Y axis down toward the XZ plane, in the vertical plane defined by azimuth
	var steps = arc_segments
	var dx = cos(azimuth)
	var dz = sin(azimuth)
	for i in range(steps):
		var a0 = polar_angle * float(i) / steps
		var a1 = polar_angle * float(i + 1) / steps
		# Parametric: start at +Y (a=0), sweep toward XZ (a=phi)
		var p0 = Vector3(sin(a0) * dx, cos(a0), sin(a0) * dz) * radius
		var p1 = Vector3(sin(a1) * dx, cos(a1), sin(a1) * dz) * radius
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(p0)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(p1)


# --- Labels: coordinate readouts and title ---

func _build_labels() -> void:
	var p = point_cartesian
	var r_cyl = Vector2(p.x, p.z).length()
	var theta = atan2(p.z, p.x)
	if theta < 0:
		theta += TAU
	var theta_deg = rad_to_deg(theta)
	var rho = p.length()
	var phi = acos(clampf(p.y / rho, -1.0, 1.0)) if rho > 0.001 else 0.0
	var phi_deg = rad_to_deg(phi)

	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "COORDINATE SYSTEMS"
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(axis_length * 0.5, axis_length + 0.08, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 5
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)

	# Cartesian readout — positioned near the point
	_cart_label = Label3D.new()
	_cart_label.name = "CartesianLabel"
	_cart_label.text = "Cartesian\n(x, y, z) = (%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
	_cart_label.font_size = 16
	_cart_label.pixel_size = 0.001
	_cart_label.position = p + Vector3(0.06, 0.06, 0)
	_cart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cart_label.modulate = Color(0.9, 0.9, 0.95)
	_cart_label.outline_size = 3
	_cart_label.outline_modulate = Color(0, 0, 0, 0.5)
	_cart_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_cart_label)

	# Cylindrical readout — near XZ projection
	_cyl_label = Label3D.new()
	_cyl_label.name = "CylindricalLabel"
	_cyl_label.text = "Cylindrical\n(r, \u03b8, z) = (%.2f, %.0f\u00b0, %.2f)" % [r_cyl, theta_deg, p.y]
	_cyl_label.font_size = 16
	_cyl_label.pixel_size = 0.001
	_cyl_label.position = Vector3(p.x * 0.5, -0.06, p.z * 0.5 + 0.04)
	_cyl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cyl_label.modulate = color_cyl
	_cyl_label.outline_size = 3
	_cyl_label.outline_modulate = Color(0, 0, 0, 0.5)
	_cyl_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_cyl_label)

	# Spherical readout — near origin along the rho line
	_sph_label = Label3D.new()
	_sph_label.name = "SphericalLabel"
	_sph_label.text = "Spherical\n(\u03c1, \u03b8, \u03c6) = (%.2f, %.0f\u00b0, %.0f\u00b0)" % [rho, theta_deg, phi_deg]
	_sph_label.font_size = 16
	_sph_label.pixel_size = 0.001
	_sph_label.position = Vector3(-0.06, axis_length * 0.5, -0.04)
	_sph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_sph_label.modulate = color_sph
	_sph_label.outline_size = 3
	_sph_label.outline_modulate = Color(0, 0, 0, 0.5)
	_sph_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_sph_label)

	# Conversion formula reference
	var formula_label = Label3D.new()
	formula_label.name = "FormulaLabel"
	formula_label.text = "x=r cos\u03b8  y=y  z=r sin\u03b8\nx=\u03c1 sin\u03c6 cos\u03b8  y=\u03c1 cos\u03c6  z=\u03c1 sin\u03c6 sin\u03b8"
	formula_label.font_size = 12
	formula_label.pixel_size = 0.001
	formula_label.position = Vector3(axis_length * 0.5, -0.1, 0)
	formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_label.modulate = Color(0.65, 0.7, 0.8, 0.85)
	formula_label.outline_size = 2
	formula_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(formula_label)

	# Legend — color key
	var legend = Label3D.new()
	legend.name = "LegendLabel"
	legend.text = "XYZ = RGB | Cylindrical = Yellow | Spherical = Magenta"
	legend.font_size = 11
	legend.pixel_size = 0.001
	legend.position = Vector3(axis_length * 0.5, -0.14, 0)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.modulate = Color(0.55, 0.55, 0.6, 0.7)
	legend.outline_size = 2
	legend.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(legend)


# --- Public: update point and rebuild ---

func set_point(new_point: Vector3) -> void:
	point_cartesian = new_point
	_rebuild()


func _rebuild() -> void:
	# Remove old children and rebuild
	for child in get_children():
		child.queue_free()

	_build_axes()
	_build_point()
	_build_projections()
	_build_arcs()
	_build_labels()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed = false
	if config_data.has("point_x"):
		point_cartesian.x = float(config_data["point_x"])
		changed = true
	if config_data.has("point_y"):
		point_cartesian.y = float(config_data["point_y"])
		changed = true
	if config_data.has("point_z"):
		point_cartesian.z = float(config_data["point_z"])
		changed = true
	if config_data.has("axis_length"):
		axis_length = float(config_data["axis_length"])
		changed = true
	if changed:
		_rebuild()
