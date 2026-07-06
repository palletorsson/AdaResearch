# invariants_demo.gd
# Invariants Demo — what properties survive a transformation?
# A triangle with labeled measurements. Apply translate, rotate, scale, shear.
# Preserved properties glow green; changed properties glow red.
#
# @identity
# essence: an invariant is identity-under-motion — the property a transformation cannot touch. What SURVIVES the move tells you what the move truly is; the thing that holds while everything shifts is where the object keeps its name. This is the QFEP core of transformation: identity is not the frozen shape but the pattern that persists across the whole orbit of a transform.
# desire: press a button, watch measurements change or hold, and read which transforms respect which properties; then PROJECT one edge onto another and watch the shadow shrink as the angle opens — see the dot product become the length that survives.
# critical_parameter: shear — the only transform here that changes every measurement (the transform with no invariant, identity fully dissolved); and the angle between two edges — the parameter the PROJECT read makes visible as cos θ.
# triggers: TRANSLATE/ROTATE/SCALE/SHEAR/RESET buttons each apply a fixed transform to the triangle; PROJECT casts edge C's shadow onto edge A and reports |A|·cos θ.
# emerges: translation and rotation preserve everything; uniform scale preserves angles; shear preserves nothing; and projection makes ALIGNMENT legible — the dot product is the projected length, cos θ is how much of one vector points along another, 1.0 when parallel, 0 when perpendicular.
# needs: RackTemplates panel with 6 buttons [has]; CylinderMesh edges [has]; SphereMesh vertices [has]; integrated BakedText tag boards for measurements [has]; projection shadow cylinder + dot-product/cos-angle tag [has]
# relationships: builds on matrix_4x4_viewer (raw numbers); feeds group_theory (invariance as symmetry). DOUBLE-DUTY: this artifact currently also stands in for "the dot product — projection, how aligned" in the transformation chapter; the PROJECT mode is a partial fill, but per doc/book/GAPS.md § C the transformation sequence still lacks a DEDICATED projection artifact — a single two-vector shadow piece is the real gap this one is covering.
# truth: The properties a transformation cannot touch define the transformation more than the properties it changes; and the dot product is that survival made a number — how much of one thing points along another.

extends Node3D

class_name InvariantsDemo

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# ── Constants ────────────────────────────────────────────────────────
const EDGE_RADIUS: float = 0.003
const VERTEX_RADIUS: float = 0.008
const GREEN := Color(0.2, 0.95, 0.3)
const RED := Color(0.95, 0.25, 0.2)
const CYAN := Color(0.3, 0.85, 0.95)
const DIM_WHITE := Color(0.85, 0.85, 0.85)
const AMBER := Color(1.0, 0.75, 0.25)  # projection shadow — the length that survives
const SHADOW_RADIUS: float = 0.006

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
# Integrated 2D-in-3D tag boards (BakedText.make_tag) — rebuilt on update.
var _length_tags: Array[Node3D] = [null, null, null]
var _angle_tags: Array[Node3D] = [null, null, null]
var _area_tag: Node3D
var _title_tag: Node3D
var _title_text: String = "INVARIANTS"
var _title_color: Color = CYAN
var _active_transform: String = "NONE"

# ── Projection / dot-product read (fills the "how aligned" role) ──────
var _projection_active: bool = false
var _shadow_mesh: MeshInstance3D      # edge C's shadow projected onto edge A
var _drop_mesh: MeshInstance3D        # the perpendicular drop line (C's tip → its foot on A)
var _projection_tag: Node3D           # reports dot product and cos θ


func _ready() -> void:
	_current_verts = _orig_verts.duplicate()
	_compute_original_measurements()
	_build_triangle()
	_build_labels()
	_build_projection()
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
	# All floating annotations are integrated 2D-in-3D tag boards
	# (BakedText.make_tag): a framed dark face with a lit accent edge and text
	# baked on, billboarded to the viewer. Dynamic tags (lengths/angles/area/
	# projection) are (re)built in _update_display since make_tag bakes text at
	# creation; the title is (re)built via _set_title_tag on state change.
	_set_title_tag("INVARIANTS", CYAN)


# Build (or rebuild) a billboarded tag board at `pos`. Frees any existing node
# passed in and returns the fresh one. text_color tints the baked glyphs; the
# accent edge is left at the make_tag default (a lit strip) for a "powered board".
func _make_annotation_tag(existing: Node3D, text: String, pos: Vector3,
		text_color: Color, world_h: float) -> Node3D:
	if existing != null and is_instance_valid(existing):
		existing.queue_free()
	var tag: Node3D = BakedText.make_tag(text, text_color, world_h)
	if tag == null:
		return null
	tag.position = pos
	add_child(tag)
	return tag


# Title board — rebuilt only when the title text or colour changes.
func _set_title_tag(text: String, col: Color) -> void:
	if _title_tag != null and is_instance_valid(_title_tag) \
			and _title_text == text and _title_color == col:
		return
	_title_text = text
	_title_color = col
	_title_tag = _make_annotation_tag(_title_tag, text, Vector3(0.0, 0.72, 0.0), col, 0.08)


# ═════════════════════════════════════════════════════════════════════
# PROJECTION (the dot-product read — how aligned is edge C with edge A?)
# ═════════════════════════════════════════════════════════════════════

func _build_projection() -> void:
	# The shadow: how far edge C reaches along edge A. This length IS the dot
	# product |A|·cos θ — the projection made visible.
	_shadow_mesh = MeshInstance3D.new()
	_shadow_mesh.name = "ProjectionShadow"
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = SHADOW_RADIUS
	shadow_cyl.bottom_radius = SHADOW_RADIUS
	shadow_cyl.height = 0.1  # placeholder — set in _update_projection
	_shadow_mesh.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = AMBER
	shadow_mat.emission = AMBER
	shadow_mat.emission_energy_multiplier = 0.7
	_shadow_mesh.material_override = shadow_mat
	_shadow_mesh.visible = false
	add_child(_shadow_mesh)

	# The drop: the perpendicular from edge C's tip down to its foot on edge A.
	# When this is short, the vectors are aligned; when long, they diverge.
	_drop_mesh = MeshInstance3D.new()
	_drop_mesh.name = "ProjectionDrop"
	var drop_cyl := CylinderMesh.new()
	drop_cyl.top_radius = EDGE_RADIUS
	drop_cyl.bottom_radius = EDGE_RADIUS
	drop_cyl.height = 0.1
	_drop_mesh.mesh = drop_cyl
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = DIM_WHITE
	drop_mat.emission = DIM_WHITE
	drop_mat.emission_energy_multiplier = 0.25
	_drop_mesh.material_override = drop_mat
	_drop_mesh.visible = false
	add_child(_drop_mesh)

	# The readout (dot product and cos θ) is an integrated tag board, built on
	# demand in _update_projection and torn down when projection is inactive.


func _update_projection() -> void:
	# Edge A (the "onto" vector) runs vert0 → vert1.
	# Edge C (the projected vector) runs vert0 → vert2 (shares the origin vert0).
	var origin: Vector3 = _current_verts[0]
	var a_vec: Vector3 = _current_verts[1] - origin
	var c_vec: Vector3 = _current_verts[2] - origin

	var a_len: float = a_vec.length()
	var c_len: float = c_vec.length()
	if a_len < 0.0001 or c_len < 0.0001:
		return

	var a_dir: Vector3 = a_vec / a_len
	# Dot product = how much of C points along A = |A|·|C|·cos θ.
	var dot_val: float = c_vec.dot(a_vec)
	var cos_theta: float = c_vec.dot(a_vec) / (a_len * c_len)
	cos_theta = clampf(cos_theta, -1.0, 1.0)
	# Scalar projection: the signed length of C's shadow on A's direction.
	var scalar_proj: float = c_vec.dot(a_dir)
	var foot: Vector3 = origin + a_dir * scalar_proj  # C's tip dropped onto line A

	# Shadow cylinder: from origin to foot (the projected length along A).
	_orient_cylinder_between(_shadow_mesh, origin, foot)

	# Drop cylinder: from C's tip (vert2) down to its foot on A.
	_orient_cylinder_between(_drop_mesh, _current_verts[2], foot)

	# Readout near the foot of the projection (integrated tag board).
	var readout: String = "A·C = %.3f  cos θ = %.2f" % [dot_val, cos_theta]
	_projection_tag = _make_annotation_tag(
		_projection_tag, readout, foot + Vector3(0.0, -0.05, 0.0), AMBER, 0.06)


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
		[{"type": "button", "label": "PROJECT"},
		 {"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0, 0.05, 0.12)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Connect buttons
	var labels := ["TRANSLATE", "ROTATE", "SCALE", "SHEAR", "PROJECT", "RESET"]
	for i in 6:
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
	# PROJECT is a READ, not a transform: it reveals the dot product / cos θ
	# between two edges of whatever triangle is currently shown. It leaves the
	# vertices untouched so you can project the original OR a transformed shape.
	if which == "PROJECT":
		_projection_active = not _projection_active
		_update_display()
		return

	_active_transform = which

	# A new transform clears the projection read; RESET does too.
	_projection_active = false

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

	# Update length tags — position at edge midpoints, offset outward
	for i in 3:
		var a: Vector3 = _current_verts[i]
		var b: Vector3 = _current_verts[(i + 1) % 3]
		var mid: Vector3 = (a + b) / 2.0
		var centroid_l: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
		var outward: Vector3 = (mid - centroid_l).normalized() * 0.04
		_length_tags[i] = _make_annotation_tag(
			_length_tags[i], "%.2f" % cur_lengths[i], mid + outward,
			_invariant_color(cur_lengths[i], _orig_lengths[i]), 0.05)

	# Update angle tags — position at vertices, offset outward
	for i in 3:
		var centroid_a: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
		var outward: Vector3 = (_current_verts[i] - centroid_a).normalized() * 0.05
		_angle_tags[i] = _make_annotation_tag(
			_angle_tags[i], "%.0f°" % cur_angles[i], _current_verts[i] + outward,
			_invariant_color(cur_angles[i], _orig_angles[i]), 0.05)

	# Update area tag at centroid
	var centroid: Vector3 = (_current_verts[0] + _current_verts[1] + _current_verts[2]) / 3.0
	_area_tag = _make_annotation_tag(
		_area_tag, "A=%.3f" % cur_area, centroid,
		_invariant_color(cur_area, _orig_area), 0.055)

	# Update projection read (the dot-product / alignment shadow)
	_shadow_mesh.visible = _projection_active
	_drop_mesh.visible = _projection_active
	if _projection_active:
		_update_projection()
	elif _projection_tag != null and is_instance_valid(_projection_tag):
		_projection_tag.queue_free()
		_projection_tag = null

	# Update title
	if _projection_active:
		_set_title_tag("PROJECT — A·C", AMBER)
	elif _active_transform == "NONE":
		_set_title_tag("INVARIANTS", CYAN)
	else:
		_set_title_tag(_active_transform, Color(1.0, 0.9, 0.4))


# Green when the measurement held (invariant), red when the transform changed it.
func _invariant_color(current_val: float, orig_val: float) -> Color:
	var tolerance: float = 0.01
	return GREEN if abs(current_val - orig_val) < tolerance else RED


# ═════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	pass
