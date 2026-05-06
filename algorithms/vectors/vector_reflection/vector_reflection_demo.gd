# vector_reflection_demo.gd
# Vector Reflection Demo — incoming vector reflects off a rotatable surface
#
# Shows the reflection formula: r = v - 2(v·n)n
# A surface quad rotates via slider; an incoming vector angle is adjustable.
# The reflected vector is computed and drawn in real time.
#
# @identity
# essence: r = v - 2(v·n)n — the mirror law as pure linear algebra
# desire: rotate the surface, swing the incoming ray, watch the reflection obey the formula
# critical_parameter: surface_angle and vector_angle sliders — together they set the geometry
# triggers: slider_moved on either slider recalculates the entire reflection diagram
# emerges: equal angles of incidence and reflection — a consequence of the dot product
# needs: RackTemplates panel with two sliders [has]; Label3D formula display [has]
# relationships: builds on dot_product; feeds ray_tracing, billiard simulations, optics
# truth: Reflection is the simplest thing a vector can do to a surface — and it explains mirrors, echoes, and billiards.

extends Node3D

class_name VectorReflectionDemo

# ── Parameters ───────────────────────────────────────────────────────────
@export var surface_half_width: float = 0.15
@export var vector_length: float = 0.25
@export var shaft_radius: float = 0.004
@export var tip_radius: float = 0.012
@export var tip_height: float = 0.025

@export var color_surface: Color = Color(0.7, 0.7, 0.75)
@export var color_incoming: Color = Color(0.2, 0.5, 0.95)
@export var color_normal: Color = Color(0.2, 0.85, 0.3)
@export var color_reflected: Color = Color(0.95, 0.25, 0.2)

# ── State ────────────────────────────────────────────────────────────────
var _surface_angle_deg: float = 90.0   # 0-180, 90 = horizontal surface
var _vector_angle_deg: float = 135.0   # 0-180, angle of incoming vector

var _surface_pivot: Node3D
var _surface_mesh: MeshInstance3D
var _normal_group: Node3D
var _incoming_group: Node3D
var _reflected_group: Node3D
var _formula_label: Label3D
var _angle_label: Label3D
var _origin_marker: MeshInstance3D


func _ready() -> void:
	_create_origin_marker()
	_create_surface()
	_create_vector_groups()
	_create_formula_label()
	_create_controls()
	_update_diagram()


# ═════════════════════════════════════════════════════════════════════════
# GEOMETRY
# ═════════════════════════════════════════════════════════════════════════

func _create_origin_marker() -> void:
	_origin_marker = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	_origin_marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.95)
	mat.emission_energy_multiplier = 0.3
	_origin_marker.material_override = mat
	_origin_marker.position = Vector3(0, 0.9, 0)
	add_child(_origin_marker)


func _create_surface() -> void:
	_surface_pivot = Node3D.new()
	_surface_pivot.name = "SurfacePivot"
	_surface_pivot.position = Vector3(0, 0.9, 0)
	add_child(_surface_pivot)

	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "SurfaceQuad"
	var quad := BoxMesh.new()
	quad.size = Vector3(surface_half_width * 2.0, 0.003, 0.04)
	_surface_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_surface
	mat.metallic = 0.4
	mat.roughness = 0.3
	_surface_mesh.material_override = mat
	_surface_pivot.add_child(_surface_mesh)


func _create_vector_groups() -> void:
	_incoming_group = Node3D.new()
	_incoming_group.name = "IncomingVector"
	_incoming_group.position = Vector3(0, 0.9, 0)
	add_child(_incoming_group)

	_normal_group = Node3D.new()
	_normal_group.name = "NormalVector"
	_normal_group.position = Vector3(0, 0.9, 0)
	add_child(_normal_group)

	_reflected_group = Node3D.new()
	_reflected_group.name = "ReflectedVector"
	_reflected_group.position = Vector3(0, 0.9, 0)
	add_child(_reflected_group)

	# Build arrow parts for each group
	_build_arrow(_incoming_group, color_incoming)
	_build_arrow(_normal_group, color_normal)
	_build_arrow(_reflected_group, color_reflected)


func _build_arrow(group: Node3D, color: Color) -> void:
	# Shaft — cylinder along +Y, origin at base
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cyl := CylinderMesh.new()
	cyl.top_radius = shaft_radius
	cyl.bottom_radius = shaft_radius
	cyl.height = 1.0  # will be scaled per update
	cyl.radial_segments = 8
	shaft.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	shaft.material_override = mat
	group.add_child(shaft)

	# Cone tip
	var tip := MeshInstance3D.new()
	tip.name = "Tip"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = tip_radius
	cone.height = tip_height
	cone.radial_segments = 8
	tip.mesh = cone
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = color
	tip_mat.emission_enabled = true
	tip_mat.emission = color
	tip_mat.emission_energy_multiplier = 0.3
	tip.material_override = tip_mat
	group.add_child(tip)


func _set_arrow(group: Node3D, direction: Vector3, length: float) -> void:
	var shaft: MeshInstance3D = group.get_node("Shaft")
	var tip: MeshInstance3D = group.get_node("Tip")

	# Shaft: scale height, position at midpoint along direction
	shaft.mesh = shaft.mesh.duplicate()
	(shaft.mesh as CylinderMesh).height = length
	shaft.position = direction * (length / 2.0)

	# Tip: at the end of the shaft
	tip.position = direction * length

	# Orient both to point along direction
	# CylinderMesh extends along local +Y, so we need basis that maps +Y to direction
	var up := direction.normalized()
	var basis := _basis_from_y(up)
	shaft.basis = basis
	tip.basis = basis


func _basis_from_y(up: Vector3) -> Basis:
	if up.length_squared() < 0.0001:
		return Basis.IDENTITY
	up = up.normalized()
	var right: Vector3
	if abs(up.dot(Vector3.FORWARD)) < 0.99:
		right = up.cross(Vector3.FORWARD).normalized()
	else:
		right = up.cross(Vector3.RIGHT).normalized()
	var forward := right.cross(up).normalized()
	return Basis(right, up, forward)


# ═════════════════════════════════════════════════════════════════════════
# FORMULA LABEL
# ═════════════════════════════════════════════════════════════════════════

func _create_formula_label() -> void:
	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.text = "r = v - 2(v·n)n"
	_formula_label.pixel_size = 0.0015
	_formula_label.font_size = 16
	_formula_label.modulate = Color(0.85, 0.85, 0.9)
	_formula_label.position = Vector3(0, 1.35, 0)
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_formula_label)

	_angle_label = Label3D.new()
	_angle_label.name = "AngleLabel"
	_angle_label.text = ""
	_angle_label.pixel_size = 0.001
	_angle_label.font_size = 14
	_angle_label.modulate = Color(0.7, 0.7, 0.75)
	_angle_label.position = Vector3(0, 1.28, 0)
	_angle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_angle_label)


# ═════════════════════════════════════════════════════════════════════════
# CONTROLS
# ═════════════════════════════════════════════════════════════════════════

func _create_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("VECTOR REFLECTION", [
		[
			{"type": "slider_h", "label": "SURFACE", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "VECTOR", "default": 0.75},
		],
	])
	panel.position = Vector3(0.25, 0.85, 0.1)
	panel.rotation_degrees = Vector3(-15, -20, 0)
	add_child(panel)

	# Surface Angle slider (Param_0)
	var surface_slider: Node = panel.find_child("Param_0", true, false)
	if surface_slider and surface_slider.has_signal("slider_moved"):
		surface_slider.slider_moved.connect(func(_name: String, val: float):
			_surface_angle_deg = val * 180.0
			_update_diagram()
		)

	# Vector Angle slider (Param_1)
	var vector_slider: Node = panel.find_child("Param_1", true, false)
	if vector_slider and vector_slider.has_signal("slider_moved"):
		vector_slider.slider_moved.connect(func(_name: String, val: float):
			_vector_angle_deg = val * 180.0
			_update_diagram()
		)


# ═════════════════════════════════════════════════════════════════════════
# UPDATE
# ═════════════════════════════════════════════════════════════════════════

func _update_diagram() -> void:
	# Surface orientation — rotate around Z axis in the XY plane
	var surface_rad := deg_to_rad(_surface_angle_deg)
	_surface_pivot.rotation = Vector3(0, 0, surface_rad - PI / 2.0)

	# Surface normal: perpendicular to the surface, pointing "up" from the surface
	# Surface lies along the rotated X axis; normal is rotated Y axis
	var n := Vector3(-sin(surface_rad), cos(surface_rad), 0).normalized()

	# Incoming vector direction (pointing toward the origin)
	var v_angle_rad := deg_to_rad(_vector_angle_deg)
	var v_dir := Vector3(cos(v_angle_rad), sin(v_angle_rad), 0).normalized()

	# Draw incoming vector pointing TOWARD origin (arrow comes from outside)
	_set_arrow(_incoming_group, -v_dir, vector_length)

	# Normal vector (from origin outward along n)
	_set_arrow(_normal_group, n, vector_length * 0.6)

	# Reflected vector: r = v - 2(v·n)n
	# v is the incoming direction (pointing toward surface), so use v_dir
	var dot_vn := v_dir.dot(n)
	var r_dir := (v_dir - 2.0 * dot_vn * n).normalized()
	_set_arrow(_reflected_group, r_dir, vector_length)

	# Compute angles of incidence and reflection
	var angle_incidence := rad_to_deg(acos(clampf(abs((-v_dir).dot(n)), 0.0, 1.0)))
	var angle_reflection := rad_to_deg(acos(clampf(abs(r_dir.dot(n)), 0.0, 1.0)))
	_angle_label.text = "incidence: %.1f°  reflection: %.1f°" % [angle_incidence, angle_reflection]


func apply_grid_config(config: Dictionary) -> void:
	pass
