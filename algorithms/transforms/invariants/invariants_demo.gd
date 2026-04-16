# invariants_demo.gd
# Invariants Demo — what properties survive a transformation?
# A triangle with labeled measurements. Apply translate, rotate, scale, shear.
# Preserved properties glow green; changed properties glow red.
#
# @identity
# essence: invariants are the fingerprint of a transformation — what survives tells you what the transform truly is
# desire: press a button, watch measurements change or hold, learn which transforms respect which properties
# critical_parameter: shear — the only transform here that changes every measurement
# triggers: TRANSLATE/ROTATE/SCALE/SHEAR/RESET buttons each apply a fixed transform to the triangle
# emerges: translation and rotation preserve everything; uniform scale preserves angles; shear preserves nothing
# needs: RackTemplates panel with 5 buttons [has]; CylinderMesh edges [has]; SphereMesh vertices [has]; Label3D measurements [has]
# relationships: builds on matrix_4x4_viewer (raw numbers); feeds group_theory (invariance as symmetry)
# truth: The properties a transformation cannot touch define the transformation more than the properties it changes.

extends Node3D

class_name InvariantsDemo

# ── Constants ────────────────────────────────────────────────────────
const EDGE_RADIUS: float = 0.003
const VERTEX_RADIUS: float = 0.008
const GREEN := Color(0.2, 0.95, 0.3)
const RED := Color(0.95, 0.25, 0.2)
const CYAN := Color(0.3, 0.85, 0.95)
const DIM_WHITE := Color(0.85, 0.85, 0.85)

# ── Original triangle (equilateral, ~0.3m side) ─────────────────────
var _orig_verts: Array[Vector3] = [
	Vector3(-0.15, 0.35, 0.0),
	Vector3(0.15, 0.35, 0.0),
	Vector3(0.0, 0.35 + 0.15 * sqrt(3.0), 0.0),
]

var _current_verts: Array[Vector3] = []
var _orig_lengths: Array[float] = []
var _orig_angles: Array[float] = []
var _orig_area: float = 0.0

# ── Scene refs ───────────────────────────────────────────────────────
var _tri_root: Node3D
var _edge_meshes: Array[MeshInstance3D] = []
var _vertex_meshes: Array[MeshInstance3D] = []
var _length_labels: Array[Label3D] = []
var _angle_labels: Array[Label3D] = []
var _area_label: Label3D
var _title_label: Label3D
var _active_transform: String = "NONE"


func _ready() -> void:
	_current_verts = _orig_verts.duplicate()
	_compute_original_measurements()
	_build_triangle()
	_build_labels()
	_build_panel()
	_update_display()


# ═════════════════════════════════════════════════════════════════════
# MEASUREMENTS
# ═════════════════════════════════════════════════════════════════════

func _compute_original_measurements() -> void:
	_orig_lengths.clear()
	_orig_angles.clear()
	for i in 3:
		var a: Vector3 = _orig_verts[i]
		var b: Vector3 = _orig_verts[(i + 1) % 3]
		_orig_lengths.append(a.distance_to(b))
	for i in 3:
		_orig_angles.append(_angle_at_vertex(i, _orig_verts))
	_orig_area = _triangle_area(_orig_verts)


func _angle_at_vertex(idx: int, verts: Array[Vector3]) -> float:
	var a: Vector3 = verts[(idx + 2) % 3] - verts[idx]
	var b: Vector3 = verts[(idx + 1) % 3] - verts[idx]
	var dot_val: float = a.normalized().dot(b.normalized())
	return rad_to_deg(acos(clampf(dot_val, -1.0, 1.0)))


func _triangle_area(verts: Array[Vector3]) -> float:
	var ab: Vector3 = verts[1] - verts[0]
	var ac: Vector3 = verts[2] - verts[0]
	return ab.cross(ac).length() * 0.5


# ═════════════════════════════════════════════════════════════════════
# TRIANGLE GEOMETRY
# ═════════════════════════════════════════════════════════════════════

func _build_triangle() -> void:
	_tri_root = Node3D.new()
	_tri_root.name = "TriangleRoot"
	add_child(_tri_root)

	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = CYAN
	edge_mat.emission = CYAN
	edge_mat.emission_energy_multiplier = 0.5

	var vert_mat := StandardMaterial3D.new()
	vert_mat.albedo_color = CYAN
	vert_mat.emission = CYAN
	vert_mat.emission_energy_multiplier = 0.6

	# 3 edges (cylinders)
	for i in 3:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = EDGE_RADIUS
		cyl.bottom_radius = EDGE_RADIUS
		cyl.height = 0.3  # placeholder — updated in _update_display
		mi.mesh = cyl
		mi.material_override = edge_mat.duplicate()
		_tri_root.add_child(mi)
		_edge_meshes.append(mi)

	# 3 vertices (spheres)
	for i in 3:
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = VERTEX_RADIUS
		sph.height = VERTEX_RADIUS * 2.0
		mi.mesh = sph
		mi.material_override = vert_mat.duplicate()
		_tri_root.add_child(mi)
		_vertex_meshes.append(mi)


func _orient_cylinder_between(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var dist: float = a.distance_to(b)
	var cyl: CylinderMesh = mi.mesh as CylinderMesh
	if cyl:
		cyl.height = dist
	mi.position = (a + b) / 2.0
	var dir: Vector3 = (b - a).normalized()
	if dir.is_equal_approx(Vector3.UP):
		mi.transform.basis = Basis.IDENTITY
	elif dir.is_equal_approx(Vector3.DOWN):
		mi.transform.basis = Basis(Vector3.RIGHT, PI)
	else:
		var axis: Vector3 = Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			axis = axis.normalized()
			var angle: float = acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
			mi.transform.basis = Basis(axis, angle)
			mi.position = (a + b) / 2.0


# ═════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════

func _build_labels() -> void:
	# Edge length labels
	for i in 3:
		var lbl := Label3D.new()
		lbl.name = "LengthLabel_%d" % i
		lbl.text = "0.00"
		lbl.pixel_size = 0.0015
		lbl.font_size = 18
		lbl.modulate = DIM_WHITE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)
		_length_labels.append(lbl)

	# Angle labels at vertices
	for i in 3:
		var lbl := Label3D.new()
		lbl.name = "AngleLabel_%d" % i
		lbl.text = "0°"
		lbl.pixel_size = 0.0015
		lbl.font_size = 16
		lbl.modulate = DIM_WHITE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)
		_angle_labels.append(lbl)

	# Area label at centroid
	_area_label = Label3D.new()
	_area_label.name = "AreaLabel"
	_area_label.text = "A=0.00"
	_area_label.pixel_size = 0.0015
	_area_label.font_size = 18
	_area_label.modulate = DIM_WHITE
	_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_area_label)

	# Title label
	_title_label = Label3D.new()
	_title_label.name = "TransformTitle"
	_title_label.text = "INVARIANTS"
	_title_label.pixel_size = 0.002
	_title_label.font_size = 20
	_title_label.modulate = CYAN
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0.0, 0.72, 0.0)
	add_child(_title_label)


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("INVARIANTS", [
		[{"type": "button", "label": "TRANSLATE"},
		 {"type": "button", "label": "ROTATE"}],
		[{"type": "button", "label": "SCALE"},
		 {"type": "button", "label": "SHEAR"}],
		[{"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0, 0.05, 0.12)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Connect buttons
	var labels := ["TRANSLATE", "ROTATE", "SCALE", "SHEAR", "RESET"]
	for i in 5:
		var btn = panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var label_name: String = labels[i]
				area.button_pressed.connect(func(_b): _apply_transform(label_name))


# ═════════════════════════════════════════════════════════════════════
# TRANSFORMS
# ═════════════════════════════════════════════════════════════════════

func _apply_transform(which: String) -> void:
	_active_transform = which

	# Always start from original
	_current_verts = _orig_verts.duplicate()

	match which:
		"TRANSLATE":
			# Shift all vertices by (0.1, 0.05, 0)
			for i in 3:
				_current_verts[i] += Vector3(0.1, 0.05, 0.0)
		"ROTATE":
			# Rotate 45 degrees around centroid
			var centroid := (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
			var angle := deg_to_rad(45.0)
			for i in 3:
				var offset: Vector3 = _current_verts[i] - centroid
				var rotated := Vector3(
					offset.x * cos(angle) - offset.y * sin(angle),
					offset.x * sin(angle) + offset.y * cos(angle),
					offset.z
				)
				_current_verts[i] = centroid + rotated
		"SCALE":
			# Uniform scale 1.5x from centroid
			var centroid := (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
			for i in 3:
				_current_verts[i] = centroid + (_current_verts[i] - centroid) * 1.5
		"SHEAR":
			# Shear: x += 0.4 * y (relative to bottom)
			var base_y: float = _current_verts[0].y
			for i in 3:
				var dy: float = _current_verts[i].y - base_y
				_current_verts[i].x += 0.4 * dy
		"RESET":
			_active_transform = "NONE"
			# _current_verts already reset above

	_update_display()


# ═════════════════════════════════════════════════════════════════════
# UPDATE DISPLAY
# ═════════════════════════════════════════════════════════════════════

func _update_display() -> void:
	# Position vertices
	for i in 3:
		_vertex_meshes[i].position = _current_verts[i]

	# Position and orient edges
	for i in 3:
		var a: Vector3 = _current_verts[i]
		var b: Vector3 = _current_verts[(i + 1) % 3]
		_orient_cylinder_between(_edge_meshes[i], a, b)

	# Compute current measurements
	var cur_lengths: Array[float] = []
	for i in 3:
		cur_lengths.append(_current_verts[i].distance_to(_current_verts[(i + 1) % 3]))

	var cur_angles: Array[float] = []
	for i in 3:
		cur_angles.append(_angle_at_vertex(i, _current_verts))

	var cur_area: float = _triangle_area(_current_verts)

	# Update length labels — position at edge midpoints, offset outward
	for i in 3:
		var a: Vector3 = _current_verts[i]
		var b: Vector3 = _current_verts[(i + 1) % 3]
		var mid: Vector3 = (a + b) / 2.0
		var centroid: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
		var outward: Vector3 = (mid - centroid).normalized() * 0.03
		_length_labels[i].position = mid + outward
		_length_labels[i].text = "%.2f" % cur_lengths[i]
		_color_label(_length_labels[i], cur_lengths[i], _orig_lengths[i])

	# Update angle labels — position at vertices, offset outward
	for i in 3:
		var centroid: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
		var outward: Vector3 = (_current_verts[i] - centroid).normalized() * 0.04
		_angle_labels[i].position = _current_verts[i] + outward
		_angle_labels[i].text = "%.0f°" % cur_angles[i]
		_color_label(_angle_labels[i], cur_angles[i], _orig_angles[i])

	# Update area label at centroid
	var centroid: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
	_area_label.position = centroid
	_area_label.text = "A=%.3f" % cur_area
	_color_label(_area_label, cur_area, _orig_area)

	# Update title
	if _active_transform == "NONE":
		_title_label.text = "INVARIANTS"
		_title_label.modulate = CYAN
	else:
		_title_label.text = _active_transform
		_title_label.modulate = Color(1.0, 0.9, 0.4)


func _color_label(lbl: Label3D, current_val: float, orig_val: float) -> void:
	var tolerance: float = 0.01
	if abs(current_val - orig_val) < tolerance:
		lbl.modulate = GREEN
	else:
		lbl.modulate = RED


# ═════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	pass
