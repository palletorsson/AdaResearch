# basis_vectors_rig.gd
# Interactive basis vectors (i, j, k)
# Shows how any 3D point is a linear combination: P = xi + yj + zk
#
# VR-enabled: grab and rotate the entire basis, or grab individual axes
# QFEP: Basis as "frame of reference" - the order from which we measure
#
# UPGRADED VISUALS - Sleek modern look with glow effects
#
# @identity
# essence: P = x*i + y*j + z*k. Any point is a weighted sum of basis directions.
# desire: To decompose space into understandable parts — grab a point and see its coordinates unfold along three axes.
# critical_parameter: target_point — the Vector3 being decomposed. Moving it rewrites the linear combination in real time.
# triggers: VR handle drag → coordinates update, preset buttons → snap to pure-axis or combined points, rotation presets → tilt/spin the basis itself
# emerges: The realization that coordinates are not absolute — they depend on which basis you choose. Rotating the basis changes the numbers but not the point.
# needs: VR grabbable handles [has], preset buttons [has], keyboard shortcuts [has]. Missing: free-rotation grab on the entire rig.
# relationships: Foundation for vector_addition_demo (addition requires understanding components). Paired with coordinate_system_switcher (same point, different frames).
# truth: Coordinates do not belong to the point. They belong to the relationship between the point and the frame.

extends Node3D

class_name BasisVectorsRig

# --- Extracted constants ---
const LABEL_PIXEL_SIZE_LARGE := 0.003
const LABEL_PIXEL_SIZE_SMALL := 0.002
const COMPONENT_LINE_RADIUS := 0.013   # was 0.008 — a hairline beside the arrows
const GLOW_SPHERE_RADIUS := 0.065
const PANEL_DEPTH := 0.012
const RADIAL_SEGMENTS := 12

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing — cabinet grammar, HORIZONTAL dialect (body = "decomposition table").
## You reach INTO this rig to grab handles, so its plane is a deck you look down
## at, not a face you stand before. The basis arrows are the PHENOMENON: they rise
## from a milled well in the deck (G3 exempts a phenomenon based in the well).
## Before this, the title, the coordinate readout and the eight-button keypad all
## hung in mid-air — the keypad 6 cm off the floor, far under the VR reach band.
@export var table_body: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "BV-08"
## Deck (work surface) height. The well floor sits just below it and the arrows
## stand in the well, so the rig reads at a table you work over.
@export var deck_height: float = 0.95

## Display settings
@export var axis_length: float = 0.6
@export var arrow_thickness: float = 0.01  # Thin like y_oscillation_cube

## Target point to decompose
@export var target_point: Vector3 = Vector3(0.35, 0.45, 0.25):
	set(value):
		target_point = value
		if is_inside_tree():
			_update_visualization()

# Sleek color palette (RGB aligned with XYZ)
var color_i: Color = Color(1.0, 0.3, 0.35)   # Red = X
var color_j: Color = Color(0.35, 1.0, 0.4)   # Green = Y
var color_k: Color = Color(0.35, 0.5, 1.0)   # Blue = Z
var color_point: Color = Color(1.0, 0.85, 0.3)  # Golden yellow = target
var color_component: Color = Color(0.6, 0.6, 0.7, 0.5)  # Gray = decomposition

var _arrow_i: Node3D
var _arrow_j: Node3D
var _arrow_k: Node3D
var _component_mmi: MultiMeshInstance3D
var _component_mm: MultiMesh
var _point_marker: MeshInstance3D
var _point_glow: MeshInstance3D
var _handle_point: Node3D
var _title_panel: Node3D
var _coords_panel: Node3D
var _control_panel: Node3D
var _ground: Node3D
var _cab: Node3D          # the table housing
var _rig: Node3D          # the phenomenon: arrows, point, component lines
var _well_y: float = 0.0  # well floor height, where the rig is based

# Shared material templates
var _arrow_mat_template: StandardMaterial3D
var _glow_mat_template: StandardMaterial3D

# Standard basis (can be transformed)
var _basis: Basis = Basis.IDENTITY

# Animation
var _time: float = 0.0

func _ready():
	_init_material_templates()
	if table_body:
		_create_table()
	_create_ground()
	_create_basis_arrows()
	_create_component_lines()
	_create_point_marker()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

# Base materials shared across arrows and glow shells via .duplicate()
func _init_material_templates():
	_arrow_mat_template = StandardMaterial3D.new()
	_arrow_mat_template.emission_enabled = true
	_arrow_mat_template.emission_energy_multiplier = 0.5
	_arrow_mat_template.metallic = 0.3
	_arrow_mat_template.roughness = 0.4

	_glow_mat_template = StandardMaterial3D.new()
	_glow_mat_template.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat_template.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

## THE TABLE. Horizontal dialect: a broad working rail ring around a milled well,
## on an apron and legs. Every part is the flat translation of a vertical part —
## the back slab becomes the rail, the window backdrop becomes the basin floor the
## arrows read against, the sign band becomes a name inlaid flat in the near rail.
## Nothing in the HOUSING rises more than a hand's width above the deck (G3).
func _create_table() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var legs_mat: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.09, 0.09, 0.105), wear, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), wear)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	var half_field: float = axis_length * 0.95
	var rail_w: float = 0.11
	var half_out: float = half_field + rail_w
	var rail_h: float = 0.05
	var well_depth: float = 0.055
	var deck_y: float = deck_height
	_well_y = deck_y - well_depth

	var cab := Node3D.new()
	cab.name = "TableConsole"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab

	# ── rail ring: four bars framing the field (the back slab, laid flat) ──
	var rail_y: float = deck_y - rail_h * 0.5
	for i in range(4):
		var along_x: bool = i < 2
		var sgn: float = -1.0 if i % 2 == 0 else 1.0
		var ctr: Vector3
		var siz: Vector3
		if along_x:
			ctr = Vector3(0.0, rail_y, sgn * (half_field + rail_w * 0.5))
			siz = Vector3(half_out * 2.0, rail_h, rail_w)
		else:
			ctr = Vector3(sgn * (half_field + rail_w * 0.5), rail_y, 0.0)
			siz = Vector3(rail_w, rail_h, half_field * 2.0)
		cab.add_child(HangarKit.box(ctr, siz, shell))
		# maroon EDGE INLAY — a routed LINE under the rail's top edge, not a band.
		# The vertical dialect's flank is a mass; a mass laid flat becomes a stripe.
		var inl_c: Vector3 = ctr
		var inl_s: Vector3
		if along_x:
			inl_c.z += sgn * (rail_w * 0.5 + 0.001)
			inl_s = Vector3(half_out * 2.0, 0.009, 0.004)
		else:
			inl_c.x += sgn * (rail_w * 0.5 + 0.001)
			inl_s = Vector3(0.004, 0.009, half_field * 2.0)
		inl_c.y = deck_y - 0.012
		cab.add_child(HangarKit.box(inl_c, inl_s, maroon))

	# ── the WELL: a dark basin the phenomenon sits in, below the deck plane ──
	cab.add_child(HangarKit.box(
		Vector3(0, _well_y - 0.008, 0),
		Vector3(half_field * 2.0, 0.016, half_field * 2.0), dark))
	# low inner walls closing the basin up to the deck
	for i in range(4):
		var along_x2: bool = i < 2
		var sgn2: float = -1.0 if i % 2 == 0 else 1.0
		if along_x2:
			cab.add_child(HangarKit.box(
				Vector3(0.0, _well_y + well_depth * 0.5, sgn2 * (half_field - 0.008)),
				Vector3(half_field * 2.0, well_depth, 0.016), dark))
		else:
			cab.add_child(HangarKit.box(
				Vector3(sgn2 * (half_field - 0.008), _well_y + well_depth * 0.5, 0.0),
				Vector3(0.016, well_depth, half_field * 2.0), dark))
	# ember line along the well's near lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, deck_y - 0.004, half_field - 0.014),
		Vector3(half_field * 1.9, 0.005, 0.005), accent))

	# ── apron + legs: the furniture's own footing ──
	var apron_y: float = deck_y - rail_h - 0.055
	for i in range(4):
		var along_x3: bool = i < 2
		var sgn3: float = -1.0 if i % 2 == 0 else 1.0
		if along_x3:
			cab.add_child(HangarKit.box(
				Vector3(0.0, apron_y, sgn3 * (half_out - 0.02)),
				Vector3(half_out * 1.94, 0.075, 0.03), steel))
		else:
			cab.add_child(HangarKit.box(
				Vector3(sgn3 * (half_out - 0.02), apron_y, 0.0),
				Vector3(0.03, 0.075, half_out * 1.94), steel))
	# vents in the APRON, seen from below
	for i in range(5):
		cab.add_child(HangarKit.box(
			Vector3(-0.22 + float(i) * 0.11, apron_y, half_out - 0.004),
			Vector3(0.055, 0.012, 0.006), dark))
	var leg_h: float = apron_y - 0.037
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cab.add_child(HangarKit.box(
				Vector3(sx * (half_out - 0.055), leg_h * 0.5, sz * (half_out - 0.055)),
				Vector3(0.045, leg_h, 0.045), legs_mat))

	# ── name INLAID FLAT in the near rail, read by looking down as you approach ──
	var name_tag: MeshInstance3D = HangarKit.stencil(
		"BASIS VECTORS", Vector2(0.34, 0.030), col_accent.lightened(0.35))
	if name_tag:
		name_tag.position = Vector3(-0.10, deck_y + 0.002, half_field + rail_w * 0.5)
		name_tag.rotation_degrees = Vector3(-90, 0, 0)
		cab.add_child(name_tag)
	var code_tag: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.024), col_accent.lightened(0.20))
	if code_tag:
		code_tag.position = Vector3(half_field - 0.06, deck_y + 0.002, half_field + rail_w * 0.5)
		code_tag.rotation_degrees = Vector3(-90, 0, 0)
		cab.add_child(code_tag)


func _create_ground():
	if table_body:
		return   # the well's basin floor IS the ground the arrows read against
	_ground = VectorVisuals.create_ground(self, axis_length * 3)

## Where the phenomenon lives. On a table the arrows are BASED in the well and
## rise from it; without a table they keep their original origin. Marked
## phenomenon so the grammar's no-orphan-text rule measures the interface and not
## the subject — î, ĵ, k̂ are pinned to the arrows' own geometry, and a basis
## vector's label belongs to the vector.
func _stage() -> Node3D:
	if not table_body:
		return self
	if _rig == null:
		_rig = Node3D.new()
		_rig.name = "BasisRig"
		_rig.set_meta("phenomenon", true)
		_rig.position = Vector3(0, _well_y, 0)
		add_child(_rig)
	return _rig


func _create_basis_arrows():
	_arrow_i = _create_basis_arrow("ArrowI", color_i, "î", "X")
	_arrow_j = _create_basis_arrow("ArrowJ", color_j, "ĵ", "Y")
	_arrow_k = _create_basis_arrow("ArrowK", color_k, "k̂", "Z")

	var stage: Node3D = _stage()
	stage.add_child(_arrow_i)
	stage.add_child(_arrow_j)
	stage.add_child(_arrow_k)

# Assembles a single basis arrow: shaft, head, glow shell, two labels
func _create_basis_arrow(arrow_name: String, color: Color, unit_label: String, axis_label: String) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name

	var mat = _arrow_mat_template.duplicate() as StandardMaterial3D
	mat.albedo_color = color
	mat.emission = color

	_add_arrow_shaft(arrow, mat)
	_add_arrow_head(arrow, mat)
	_add_arrow_glow(arrow, color)
	_add_arrow_labels(arrow, color, unit_label, axis_label)

	return arrow

func _add_arrow_shaft(arrow: Node3D, mat: StandardMaterial3D):
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness
	cylinder.bottom_radius = arrow_thickness
	cylinder.height = axis_length
	cylinder.radial_segments = RADIAL_SEGMENTS
	shaft.mesh = cylinder
	shaft.material_override = mat
	shaft.position = Vector3(0, axis_length / 2, 0)
	arrow.add_child(shaft)

func _add_arrow_head(arrow: Node3D, mat: StandardMaterial3D):
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.8
	cone.height = arrow_thickness * 6
	cone.radial_segments = RADIAL_SEGMENTS
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, axis_length, 0)
	arrow.add_child(head)

func _add_arrow_glow(arrow: Node3D, color: Color):
	var glow = MeshInstance3D.new()
	glow.name = "Glow"
	var glow_cyl = CylinderMesh.new()
	glow_cyl.top_radius = arrow_thickness * 2.0
	glow_cyl.bottom_radius = arrow_thickness * 2.0
	glow_cyl.height = axis_length
	glow.mesh = glow_cyl
	var glow_mat = _glow_mat_template.duplicate() as StandardMaterial3D
	glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.12)
	glow.material_override = glow_mat
	glow.position = Vector3(0, axis_length / 2, 0)
	arrow.add_child(glow)

func _add_arrow_labels(arrow: Node3D, color: Color, unit_label: String, axis_label: String):
	var axis_lbl = Label3D.new()
	axis_lbl.name = "AxisLabel"
	axis_lbl.text = axis_label
	axis_lbl.pixel_size = LABEL_PIXEL_SIZE_LARGE
	axis_lbl.font_size = 24
	axis_lbl.modulate = color
	axis_lbl.outline_size = 10
	axis_lbl.outline_modulate = Color(0, 0, 0, 0.8)
	axis_lbl.position = Vector3(0, axis_length + 0.04, 0.06)
	axis_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(axis_lbl)

	var unit_lbl = Label3D.new()
	unit_lbl.name = "UnitLabel"
	unit_lbl.text = unit_label
	unit_lbl.pixel_size = LABEL_PIXEL_SIZE_SMALL
	unit_lbl.font_size = 16
	unit_lbl.modulate = color * 0.85
	unit_lbl.outline_size = 5
	unit_lbl.outline_modulate = Color(0, 0, 0, 0.6)
	unit_lbl.position = Vector3(0, axis_length - 0.04, 0.05)
	unit_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(unit_lbl)

# MultiMesh for the 3 decomposition lines — single draw call
func _create_component_lines():
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = COMPONENT_LINE_RADIUS
	cylinder.bottom_radius = COMPONENT_LINE_RADIUS
	cylinder.height = 1.0  # Unit height, scaled per instance via transform

	_component_mm = MultiMesh.new()
	_component_mm.transform_format = MultiMesh.TRANSFORM_3D
	_component_mm.use_colors = true
	_component_mm.mesh = cylinder
	_component_mm.instance_count = 3

	var zero_xf := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
	for i in 3:
		_component_mm.set_instance_transform(i, zero_xf)
		_component_mm.set_instance_color(i, Color.TRANSPARENT)

	_component_mmi = MultiMeshInstance3D.new()
	_component_mmi.name = "ComponentLines"
	_component_mmi.multimesh = _component_mm

	# The staircase from origin to point IS the lesson (P = x*i + y*j + z*k), so it
	# has to be the clearest thing here, and each leg has to say WHICH axis it is.
	# It was doing the opposite: a uniform grey emission glowed all three legs the
	# same colour, erasing the axis correspondence at exactly the moment it should
	# read. UNSHADED lets the per-instance vertex colour carry it at full strength
	# regardless of room lighting — the same trick the arrows' own glow uses.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_component_mmi.material_override = mat

	_stage().add_child(_component_mmi)

func _create_point_marker():
	_point_marker = MeshInstance3D.new()
	_point_marker.name = "PointMarker"
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 24
	sphere.rings = 12
	_point_marker.mesh = sphere

	var mat = _arrow_mat_template.duplicate() as StandardMaterial3D
	mat.albedo_color = color_point
	mat.emission = color_point
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.5
	mat.roughness = 0.3
	_point_marker.material_override = mat
	_stage().add_child(_point_marker)

	_point_glow = MeshInstance3D.new()
	_point_glow.name = "PointGlow"
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = GLOW_SPHERE_RADIUS
	glow_sphere.height = GLOW_SPHERE_RADIUS * 2.0
	_point_glow.mesh = glow_sphere

	var glow_mat = _glow_mat_template.duplicate() as StandardMaterial3D
	glow_mat.albedo_color = Color(color_point.r, color_point.g, color_point.b, 0.15)
	_point_glow.material_override = glow_mat
	_stage().add_child(_point_glow)

	_handle_point = VectorVisuals.create_handle(_stage(), "HandlePoint", color_point, 0.05)
	_handle_point.position = target_point

func _create_labels():
	if not table_body:
		_title_panel = VectorVisuals.create_panel(self, "TitlePanel",
			"BASIS VECTORS",
			Vector3(0, axis_length + 0.35, -axis_length - 0.15),
			Vector2(0.38, 0.08), 22)

		_coords_panel = VectorVisuals.create_panel(self, "CoordsPanel", "",
			Vector3(axis_length + 0.2, axis_length * 0.5, 0),
			Vector2(0.48, 0.18), 13, HORIZONTAL_ALIGNMENT_LEFT)
		_coords_panel.rotation_degrees = Vector3(0, -90, 0)
		return

	# The title is already INLAID FLAT in the near rail by _create_table(), so no
	# floating title panel. The coordinate readout is SUNK INTO THE FAR RAIL, 14
	# degrees off the deck plane and tilted toward the reader — the horizontal
	# translation of the vertical dialect's inset screen.
	var deck_y: float = deck_height
	var half_field: float = axis_length * 0.95
	var rail_w: float = 0.11
	var scr_w: float = 0.46
	var scr_h: float = 0.15
	var far_z: float = -(half_field + rail_w * 0.5)
	var tilt: float = -90.0 + 14.0

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(pal["accent"], 2.0)

	# milled pocket, sunk into the rail's top face
	var pocket: MeshInstance3D = HangarKit.box(
		Vector3(0, deck_y - 0.012, far_z),
		Vector3(scr_w + 0.028, 0.016, scr_h + 0.026), dark)
	_cab.add_child(pocket)
	# lit face + the family's canonical glass, both laid at the rail's rake
	var face: MeshInstance3D = HangarKit.box(
		Vector3(0, deck_y - 0.004, far_z),
		Vector3(scr_w, scr_h, 0.005), HangarKit.emissive(pal["screen"], 0.45))
	face.rotation_degrees = Vector3(tilt, 0, 0)
	_cab.add_child(face)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.5
	var glass: MeshInstance3D = HangarKit.box(
		Vector3(0, deck_y - 0.001, far_z), Vector3(scr_w, scr_h, 0.004), glass_mat)
	glass.rotation_degrees = Vector3(tilt, 0, 0)
	_cab.add_child(glass)
	# ember lip along the pocket's far edge
	_cab.add_child(HangarKit.box(
		Vector3(0, deck_y - 0.006, far_z - scr_h * 0.5 - 0.008),
		Vector3(scr_w + 0.028, 0.005, 0.005), accent))

	# the live readout itself, lying in the pocket at the same rake
	_coords_panel = VectorVisuals.create_panel(_cab, "CoordsPanel", "",
		Vector3(0, deck_y + 0.004, far_z),
		Vector2(scr_w * 0.94, scr_h * 0.92), 13, HORIZONTAL_ALIGNMENT_LEFT)
	_coords_panel.rotation_degrees = Vector3(tilt, 0, 0)
	HangarKit.harmonize(_coords_panel, finish)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# Frameless on a table: the milled pocket is the faceplate, and RackTemplates'
	# own cream plate + copper strip would read as a second manufacturer (G4).
	_control_panel = RackTpl.create_panel("" if table_body else "BASIS", [
		[
			{"type": "button", "label": "PURE X"},
			{"type": "button", "label": "PURE Y"},
			{"type": "button", "label": "PURE Z"},
			{"type": "button", "label": "XY"},
			{"type": "button", "label": "XYZ"},
		],
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "TILT"},
			{"type": "button", "label": "SPIN"},
		],
	], table_body)
	if table_body:
		# Keypad recessed FLUSH in a milled pocket in the near rail, face-up and
		# pressed downward — frameless, because on furniture the pocket IS the
		# faceplate. Previously this panel floated at y=0.06, a hand's width off
		# the floor and nowhere near the reach band.
		var deck_y: float = deck_height
		var half_field: float = axis_length * 0.95
		var rail_w: float = 0.11
		var near_z: float = half_field + rail_w * 0.5
		var pad_w: float = float(_control_panel.get_meta("panel_w", 0.34))
		var pad_d: float = float(_control_panel.get_meta("panel_h", 0.16))
		var dark2: StandardMaterial3D = HangarKit.painted_metal(
			Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
		_cab.add_child(HangarKit.box(
			Vector3(0.16, deck_y - 0.014, near_z),
			Vector3(pad_w + 0.030, 0.020, pad_d + 0.026), dark2))
		_control_panel.position = Vector3(0.16, deck_y - 0.002, near_z)
		_control_panel.rotation_degrees = Vector3(-90, 0, 0)
		HangarKit.harmonize(_control_panel, finish)
		_cab.add_child(_control_panel)
	else:
		_control_panel.position = Vector3(0, 0.06, axis_length + 0.35)
		_control_panel.rotation_degrees = Vector3(-30, 0, 0)
		add_child(_control_panel)

	# Point preset buttons (row 0: Btn_0 .. Btn_4)
	var point_presets: Array[Vector3] = [
		Vector3(0.4, 0, 0), Vector3(0, 0.4, 0), Vector3(0, 0, 0.4),
		Vector3(0.3, 0.3, 0), Vector3(0.25, 0.3, 0.2),
	]
	for i in range(point_presets.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		var pt: Vector3 = point_presets[i]
		_connect_button(btn, func(_b): _set_target_point(pt))

	# Rotation preset buttons (row 1: Btn_5 .. Btn_7)
	var rotation_presets: Array[Basis] = [
		Basis.IDENTITY,
		Basis(Vector3.RIGHT, deg_to_rad(30)),
		Basis(Vector3.UP, deg_to_rad(45)),
	]
	for i in range(rotation_presets.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % (i + 5), true, false)
		var b: Basis = rotation_presets[i]
		_connect_button(btn, func(_b): _set_basis(b))


func _connect_button(btn: Node, callback: Callable) -> void:
	if not btn:
		return
	var area: Node = btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(callback)

func _set_target_point(p: Vector3):
	target_point = p
	_handle_point.position = target_point

func _set_basis(b: Basis):
	_basis = b
	_update_visualization()

func _update_visualization():
	_orient_arrow(_arrow_i, _basis.x * axis_length)
	_orient_arrow(_arrow_j, _basis.y * axis_length)
	_orient_arrow(_arrow_k, _basis.z * axis_length)

	_point_marker.position = target_point
	_point_glow.position = target_point
	_handle_point.position = target_point

	var coords = _basis.inverse() * target_point
	_update_component_lines(coords)
	_update_labels(coords)

# Aligns arrow's local Y axis with the given direction vector
func _orient_arrow(arrow: Node3D, direction: Vector3):
	if direction.length() < 0.001:
		return

	arrow.transform = Transform3D.IDENTITY

	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD

	arrow.look_at(arrow.global_position + direction, up)
	arrow.rotate_object_local(Vector3.RIGHT, -PI/2)

func _update_component_lines(coords: Vector3):
	var p0 = Vector3.ZERO
	var p1 = _basis.x * coords.x
	var p2 = p1 + _basis.y * coords.y
	var p3 = p2 + _basis.z * coords.z

	# Full axis hue, slight transparency so the legs read as measurement rather than
	# structure. `color_i * 0.6` scaled the ALPHA channel too, which is why these were
	# both dark and see-through.
	_set_component_line(0, p0, p1, Color(color_i.r, color_i.g, color_i.b, 0.92))
	_set_component_line(1, p1, p2, Color(color_j.r, color_j.g, color_j.b, 0.92))
	_set_component_line(2, p2, p3, Color(color_k.r, color_k.g, color_k.b, 0.92))

# Positions a MultiMesh instance as a cylinder between start and end
func _set_component_line(index: int, start: Vector3, end: Vector3, color: Color):
	var direction = end - start
	var length = direction.length()

	if length < 0.01:
		_component_mm.set_instance_transform(index,
			Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO))
		_component_mm.set_instance_color(index, Color.TRANSPARENT)
		return

	var mid = (start + end) / 2.0
	var dir_n = direction.normalized()

	var up = Vector3.UP
	if abs(dir_n.dot(up)) > 0.99:
		up = Vector3.FORWARD

	# Orient unit cylinder's Y axis along direction, scale Y by length
	var y_axis = dir_n
	var x_axis = up.cross(y_axis).normalized()
	var z_axis = y_axis.cross(x_axis).normalized()
	var b = Basis(x_axis, y_axis, z_axis).scaled(Vector3(1.0, length, 1.0))

	_component_mm.set_instance_transform(index, Transform3D(b, mid))
	_component_mm.set_instance_color(index, color)

func _update_labels(coords: Vector3):
	var label = VectorVisuals.get_panel_label(_coords_panel)
	if label:
		label.text = "P = %.2f·î + %.2f·ĵ + %.2f·k̂\n\n" % [coords.x, coords.y, coords.z]
		label.text += "P = (%.2f, %.2f, %.2f)\n" % [target_point.x, target_point.y, target_point.z]
		label.text += "|P| = %.3f" % target_point.length()

func _process(delta):
	_time += delta

	var pulse = 0.12 + sin(_time * 3.0) * 0.03
	var glow_mat = _point_glow.material_override as StandardMaterial3D
	if glow_mat:
		glow_mat.albedo_color.a = pulse

	VectorVisuals.pulse_handle(_handle_point, delta, _time)

	if _handle_point.position != target_point:
		target_point = _handle_point.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _set_target_point(Vector3(0.4, 0, 0))
			KEY_2: _set_target_point(Vector3(0, 0.4, 0))
			KEY_3: _set_target_point(Vector3(0, 0, 0.4))
			KEY_4: _set_target_point(Vector3(0.3, 0.3, 0))
			KEY_5: _set_target_point(Vector3(0.25, 0.3, 0.2))
			KEY_R: _set_basis(Basis.IDENTITY)
			KEY_T: _set_basis(Basis(Vector3.RIGHT, deg_to_rad(30)))
			KEY_Y: _set_basis(Basis(Vector3.UP, deg_to_rad(45)))

func set_point(p: Vector3):
	target_point = p
	_handle_point.position = target_point

func get_coordinates() -> Vector3:
	return _basis.inverse() * target_point

func rotate_basis(axis: Vector3, angle: float):
	_basis = _basis.rotated(axis.normalized(), angle)
	_update_visualization()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
