extends Node3D
class_name RussellParadoxWorkbench

# @identity
# essence: six set descriptions, with opt-in IN / OUT buttons to test self-membership.
# desire: try both answers to unrestricted Russell comprehension, then restrict the domain.
# critical_parameter: cell 5 is unrestricted; cell 6 filters the existing set U = {0,1,2,3} of von Neumann ordinals.
# triggers: slider selects a definition; physical buttons supply an assumed answer; the readout checks it against the rule.
# emerges: neither Boolean answer satisfies b = not b; restricting the domain changes the equation.
# truth: this finite example computes separation. Its discs and orbit illustrate membership and contradiction; they are not models of a universal set or proof that all self-reference is inconsistent.
# relationships: restored beside russell_set_box in Russell_Paradox; also available in Crisis_Synthesis.

# ── Configuration ─────────────────────────────────────────────────────

@export var membership_controls: bool = false
var _membership_buttons: Node3D
var _attempt: int = -1
var _last_result: Dictionary = {}

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Disc")
## Vertical placement of the set visualization above plate origin.
@export var disc_height: float = 1.45
## Forward distance of the disc in front of plate.
@export var disc_depth: float = -0.20
## Disc base radius (meters, before plate scale).
@export var disc_radius: float = 0.22
## Wavy R-disc amplitude (fraction of base radius).
@export var wavy_amplitude: float = 0.18
## Wavy R-disc lobe count.
@export var wavy_lobes: int = 9

@export_group("Colors")
@export var color_wellformed: Color = Color(0.55, 0.85, 1.0, 0.55)
@export var color_degenerate: Color = Color(1.0, 0.78, 0.35, 0.55)
@export var color_paradox: Color = Color(1.0, 0.22, 0.18, 0.6)
@export var color_lamp_green: Color = Color(0.35, 1.0, 0.4)
@export var color_lamp_amber: Color = Color(1.0, 0.75, 0.2)
@export var color_lamp_red: Color = Color(1.0, 0.18, 0.12)

@export_group("Arrows")
## Radius of the contradiction-arrow orbit (multiplied with disc_radius).
@export var arrow_orbit_factor: float = 1.55
## Radians per second for the arrow rotation.
@export var arrow_orbit_speed: float = 0.9
## Number of segments used to draw each arrow arc.
@export var arrow_segments: int = 24
## Angular span of each arrow arc (radians).
@export var arrow_arc_span: float = 2.2

# ── Internal state ────────────────────────────────────────────────────

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const DisplayMount = preload("res://commons/ui/display_mount.gd")
const CELL_COUNT: int = 6

# Dots are schematic except the four finite ordinals in cell 6.
const CELL_DEFS: Array = [
	{"name":"E", "formal":"E = {x in N : x is even}", "verdict":"A subset of the natural numbers", "lamp":"green", "disc":0, "dot_count":4, "dot_label":"even"},
	{"name":"V", "formal":"V = all sets", "verdict":"A proper class, not a set in ZFC", "lamp":"amber", "disc":1, "dot_count":5, "dot_label":"sets"},
	{"name":"C", "formal":"C = {x in U : x is nonempty}", "verdict":"Filter an existing set U", "lamp":"green", "disc":0, "dot_count":3, "dot_label":"nonempty"},
	{"name":"S", "formal":"S = {x in U : x in x}", "verdict":"Empty under Foundation", "lamp":"amber", "disc":2, "dot_count":0, "dot_label":""},
	{"name":"R", "formal":"R = {x : x not in x}", "verdict":"Does R belong to itself?", "lamp":"amber", "disc":0, "dot_count":0, "dot_label":""},
	{"name":"R_U", "formal":"R_U = {x in U : x not in x}", "verdict":"U = {0,1,2,3} (finite ordinals)", "lamp":"green", "disc":0, "dot_count":4, "dot_label":"ordinal"}
]

var _cell: int = 0  # 0..5 (cell numbers 1..6)

var _plate_root: Node3D
var _display_root: Node3D            # anchor that carries the viz cluster
var _slider: Node
var _plate_readout
var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

var _disc_root: Node3D
var _disc_mesh_inst: MeshInstance3D
var _disc_label: Label3D
var _dot_root: Node3D
var _self_ref_label: Label3D

var _arrow_orbit_root: Node3D
var _arrow_a_root: Node3D
var _arrow_b_root: Node3D
var _arrow_a_label: Label3D
var _arrow_b_label: Label3D
var _arrows_visible: bool = false
var _arrow_phase: float = 0.0

var _readout_root: Node3D
var _readout_formal: Label3D
var _readout_verdict: Label3D
var _readout_proof: Label3D

var _lamp_inst: MeshInstance3D
var _lamp_material: StandardMaterial3D
var _lamp_blink_t: float = 0.0
var _lamp_should_blink: bool = false

var _zfc_card_root: Node3D
var _zfc_card_alpha_t: float = 0.0  # 0..1 target alpha
var _zfc_card_current_alpha: float = 0.0


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_build_plate_and_slider()
	_build_disc_root()
	_build_arrows()
	_build_readout_panel()
	_build_lamp()
	_build_zfc_card()
	if membership_controls: _build_membership_buttons()
	_apply_cell(_cell)
	_mount_display.call_deferred()


## Gather the viz roots onto a composer-placed anchor + floor stand (DisplayMount).
func _mount_display() -> void:
	var center := Vector3(0.0, disc_height, disc_depth)
	_display_root = DisplayMount.make_anchor(self, "russell_paradox_workbench", center, 1.0, 0.0)
	DisplayMount.mount_cluster(_display_root, [_disc_root, _arrow_orbit_root, _readout_root, _zfc_card_root, _lamp_inst, get_node("LampLabel")], center)
	DisplayMount.build_stand(self, _display_root)


func _process(delta: float) -> void:
	# Throttled viz rebuild — keeps the grab loop free while dragging.
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_apply_cell(_cell)
	# Animate contradiction arrows when visible.
	if _arrows_visible and _arrow_orbit_root:
		_arrow_phase += delta * arrow_orbit_speed
		_arrow_orbit_root.rotation.z = _arrow_phase

	# Blink the lamp red when in paradox cells.
	if _lamp_should_blink and _lamp_material:
		_lamp_blink_t += delta * 4.0
		var pulse: float = 0.5 + 0.5 * sin(_lamp_blink_t)
		_lamp_material.emission_energy_multiplier = 0.6 + 1.6 * pulse

	# Fade ZFC card.
	if _zfc_card_root:
		var target: float = _zfc_card_alpha_t
		var cur: float = _zfc_card_current_alpha
		var diff: float = target - cur
		if abs(diff) > 0.001:
			_zfc_card_current_alpha = cur + clampf(diff, -delta * 2.0, delta * 2.0)
			_apply_zfc_alpha(_zfc_card_current_alpha)


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole (workbench principal): cell slider + summary
	# readout. The R-disc / arrow orbit / ZFC card / detail readout stay as world-space
	# viz. Replaces the hand-built plate + jumpy slider_horizontal with slider_smooth.
	_plate_root = InterfacePresets.build("workbench", "Russell's Paradox", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")
	_slider = _plate_root.add_slider("cell — 1..6", "cell")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _normalized_for_cell(_cell))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var frac: float = clampf(float(_slider.call("get_normalized_value")), 0.0, 1.0)
	var new_cell: int = _cell_for_normalized(frac)
	if new_cell == _cell:
		return
	_cell = new_cell
	_viz_dirty = true   # throttled rebuild (merged into the existing _process)


func _normalized_for_cell(cell_idx: int) -> float:
	if CELL_COUNT <= 1:
		return 0.5
	var c: int = clampi(cell_idx, 0, CELL_COUNT - 1)
	return float(c) / float(CELL_COUNT - 1)


func _cell_for_normalized(frac: float) -> int:
	var idx: int = int(roundf(clampf(frac, 0.0, 1.0) * float(CELL_COUNT - 1)))
	return clampi(idx, 0, CELL_COUNT - 1)


# ── Disc root (rebuilt each cell) ─────────────────────────────────────

func _build_disc_root() -> void:
	_disc_root = Node3D.new()
	_disc_root.name = "Disc"
	_disc_root.position = Vector3(0.0, disc_height, disc_depth)
	add_child(_disc_root)

	# Wavy/clean mesh slot.
	_disc_mesh_inst = MeshInstance3D.new()
	_disc_mesh_inst.name = "DiscMesh"
	_disc_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc_root.add_child(_disc_mesh_inst)

	# Set-letter label centered on disc.
	_disc_label = Label3D.new()
	_disc_label.name = "DiscLabel"
	_disc_label.font_size = 64
	_disc_label.outline_size = 6
	_disc_label.pixel_size = 0.001
	_disc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_disc_label.modulate = Color(0.95, 0.97, 1.0)
	_disc_label.position = Vector3(0.0, 0.0, 0.01)
	_disc_root.add_child(_disc_label)

	# Self-reference label (only shown for cell 2).
	_self_ref_label = Label3D.new()
	_self_ref_label.name = "SelfRefLabel"
	_self_ref_label.font_size = 18
	_self_ref_label.outline_size = 3
	_self_ref_label.pixel_size = 0.001
	_self_ref_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_self_ref_label.modulate = Color(1.0, 0.88, 0.5)
	_self_ref_label.text = "class, not another member"
	_self_ref_label.position = Vector3(0.0, -disc_radius * 0.55, 0.01)
	_self_ref_label.visible = false
	_disc_root.add_child(_self_ref_label)

	# Dot root holds example element dots.
	_dot_root = Node3D.new()
	_dot_root.name = "Dots"
	_disc_root.add_child(_dot_root)


func _rebuild_disc(style_id: int) -> void:
	# Clear dots.
	for c in _dot_root.get_children():
		_dot_root.remove_child(c)
		c.queue_free()

	if style_id == 4:
		# Cell 6: no disc at all.
		_disc_mesh_inst.mesh = null
		_disc_label.text = "?"
		_disc_label.modulate = Color(1.0, 0.55, 0.45)
		_self_ref_label.visible = false
		return

	# Disc color by style.
	var col: Color = color_wellformed
	match style_id:
		0:
			col = color_wellformed
		1:
			col = color_degenerate
		2:
			col = color_degenerate
		3:
			col = color_paradox
		_:
			col = color_wellformed

	# Geometry.
	if style_id == 3:
		# Wavy red disc — built procedurally to read distinct from the clean discs.
		_disc_mesh_inst.mesh = _build_wavy_ring_mesh(disc_radius, wavy_amplitude, wavy_lobes)
	else:
		# Clean disc: thin cylinder (acts as a flat puck face on).
		var cyl := CylinderMesh.new()
		var radius: float = disc_radius
		if style_id == 2:
			radius = disc_radius * 0.55  # cell 4 — smaller disc
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = 0.01
		cyl.radial_segments = 48
		_disc_mesh_inst.mesh = cyl
		# Cylinder default axis is Y — rotate so it faces forward (axis along Z).
		_disc_mesh_inst.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)

	# Material.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6
	_disc_mesh_inst.material_override = mat

	# Reset rotation for procedurally-built ring (it is already in XY plane).
	if style_id == 3:
		_disc_mesh_inst.rotation = Vector3.ZERO

	# Cell letter.
	var cell_data: Dictionary = CELL_DEFS[_cell]
	_disc_label.text = str(cell_data["name"])
	if style_id == 3:
		_disc_label.modulate = Color(1.0, 0.9, 0.85)
	elif style_id == 1:
		_disc_label.modulate = Color(0.1, 0.05, 0.0)
	else:
		_disc_label.modulate = Color(0.95, 0.97, 1.0)

	# Self-reference indicator for cell 2 (A = {x : x is a set}).
	_self_ref_label.visible = (style_id == 1)
	_self_ref_label.text = "class, not another member"

	# Example element dots inside the disc.
	var dot_count: int = int(cell_data["dot_count"])
	var dot_label: String = str(cell_data["dot_label"])
	if dot_count > 0:
		var radius_inner: float = (disc_radius if style_id != 2 else disc_radius * 0.55) * 0.55
		if dot_count == 1:
			_spawn_dot(Vector3(0.0, 0.0, 0.012), dot_label, Color(0.95, 0.97, 1.0))
		else:
			for i in range(dot_count):
				var angle: float = float(i) * TAU / float(dot_count) + PI * 0.5
				var pos := Vector3(cos(angle) * radius_inner, sin(angle) * radius_inner, 0.012)
				_spawn_dot(pos, str(i) if _cell == 5 else (dot_label if i == 0 else ""), Color(0.95, 0.97, 1.0))


func _spawn_dot(pos: Vector3, label_text: String, color: Color) -> void:
	var dot := MeshInstance3D.new()
	dot.name = "Dot"
	var sm := SphereMesh.new()
	sm.radius = 0.018
	sm.height = 0.036
	sm.radial_segments = 12
	sm.rings = 6
	dot.mesh = sm
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = color
	dmat.emission_enabled = true
	dmat.emission = color
	dmat.emission_energy_multiplier = 0.9
	dot.material_override = dmat
	dot.position = pos
	_dot_root.add_child(dot)

	if label_text != "":
		var lab := Label3D.new()
		lab.text = label_text
		lab.font_size = 16
		lab.outline_size = 2
		lab.pixel_size = 0.001
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.modulate = Color(0.85, 0.95, 1.0)
		lab.position = pos + Vector3(0.0, 0.04, 0.0)
		_dot_root.add_child(lab)


func _build_wavy_ring_mesh(base_radius: float, amplitude: float, lobes: int) -> ArrayMesh:
	# A filled disc whose outer boundary is sin-modulated. Built as a triangle fan
	# from the center to N points on r(θ) = base_radius + amplitude * sin(lobes*θ).
	var arr := ArrayMesh.new()
	var seg: int = max(48, lobes * 12)
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	verts.resize(seg + 1)
	verts[0] = Vector3.ZERO
	for i in range(seg):
		var theta: float = float(i) * TAU / float(seg)
		var r: float = base_radius + amplitude * sin(float(lobes) * theta)
		verts[i + 1] = Vector3(cos(theta) * r, sin(theta) * r, 0.0)
	idx.resize(seg * 3)
	for i in range(seg):
		var a: int = i + 1
		var b: int = (i + 1) % seg + 1
		idx[i * 3 + 0] = 0
		idx[i * 3 + 1] = a
		idx[i * 3 + 2] = b
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = verts
	data[Mesh.ARRAY_INDEX] = idx
	arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	return arr


# ── Arrows ────────────────────────────────────────────────────────────

func _build_arrows() -> void:
	# Two arrows orbiting the same center, pointing tangentially in
	# OPPOSITE rotational senses so their nose-to-tail join reads as a closed
	# loop. Both children of `_arrow_orbit_root` which spins as one piece.
	_arrow_orbit_root = Node3D.new()
	_arrow_orbit_root.name = "ContradictionLoop"
	_arrow_orbit_root.position = Vector3(0.0, disc_height, disc_depth + 0.02)
	_arrow_orbit_root.visible = false
	add_child(_arrow_orbit_root)

	# Arrow A: top half, sweeping clockwise (R∈R ⇒ R∉R).
	_arrow_a_root = _build_arc_arrow(arrow_arc_span, true, Color(1.0, 0.32, 0.18))
	_arrow_a_root.name = "ArrowA"
	_arrow_orbit_root.add_child(_arrow_a_root)

	# Arrow B: bottom half, sweeping clockwise (R∉R ⇒ R∈R) — same rotational
	# sense so the two arcs chain head-to-tail into one orbit.
	_arrow_b_root = _build_arc_arrow(arrow_arc_span, true, Color(1.0, 0.55, 0.32))
	_arrow_b_root.name = "ArrowB"
	_arrow_b_root.rotation.z = PI  # rotate 180° so its arc occupies the opposite half
	_arrow_orbit_root.add_child(_arrow_b_root)

	# Implication labels — children of the orbit root so they ride with it.
	_arrow_a_label = Label3D.new()
	_arrow_a_label.name = "ArrowALabel"
	_arrow_a_label.text = "R∈R  ⇒  R∉R"
	_arrow_a_label.font_size = 20
	_arrow_a_label.outline_size = 3
	_arrow_a_label.pixel_size = 0.001
	_arrow_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow_a_label.modulate = Color(1.0, 0.85, 0.7)
	_arrow_a_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_arrow_a_label.position = Vector3(0.0, disc_radius * arrow_orbit_factor + 0.06, 0.0)
	_arrow_orbit_root.add_child(_arrow_a_label)

	_arrow_b_label = Label3D.new()
	_arrow_b_label.name = "ArrowBLabel"
	_arrow_b_label.text = "R∉R  ⇒  R∈R"
	_arrow_b_label.font_size = 20
	_arrow_b_label.outline_size = 3
	_arrow_b_label.pixel_size = 0.001
	_arrow_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow_b_label.modulate = Color(1.0, 0.85, 0.7)
	_arrow_b_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_arrow_b_label.position = Vector3(0.0, -(disc_radius * arrow_orbit_factor + 0.06), 0.0)
	_arrow_orbit_root.add_child(_arrow_b_label)


func _build_arc_arrow(arc_span: float, clockwise: bool, color: Color) -> Node3D:
	# Builds an arc with a small triangular arrowhead at the end. The arc center
	# is at the local origin; the arc lies in the XY plane.
	var root := Node3D.new()
	var r: float = disc_radius * arrow_orbit_factor

	# Arc as a thin line strip — built as a series of small box meshes between
	# successive arc points. Cheap, reads as a line.
	var color_mat := StandardMaterial3D.new()
	color_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	color_mat.albedo_color = color
	color_mat.emission_enabled = true
	color_mat.emission = color
	color_mat.emission_energy_multiplier = 1.2

	var seg: int = max(6, arrow_segments)
	var theta_start: float = PI * 0.5 - arc_span * 0.5  # arc symmetric about +Y
	var theta_step: float = arc_span / float(seg)
	if not clockwise:
		theta_step = -theta_step

	var prev: Vector3 = Vector3(cos(theta_start) * r, sin(theta_start) * r, 0.0)
	for i in range(1, seg + 1):
		var theta: float = theta_start + float(i) * theta_step
		var p := Vector3(cos(theta) * r, sin(theta) * r, 0.0)
		var seg_inst := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var length: float = (p - prev).length()
		qm.size = Vector2(length, 0.012)
		seg_inst.mesh = qm
		seg_inst.material_override = color_mat
		# Place midpoint and rotate to align with (p - prev).
		var mid: Vector3 = (p + prev) * 0.5
		seg_inst.position = mid
		var dir: Vector3 = (p - prev).normalized()
		var angle: float = atan2(dir.y, dir.x)
		seg_inst.rotation = Vector3(0.0, 0.0, angle)
		seg_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(seg_inst)
		prev = p

	# Arrowhead at the tail end.
	var head := MeshInstance3D.new()
	var head_arr := ArrayMesh.new()
	var verts := PackedVector3Array([
		Vector3(0.03, 0.0, 0.0),
		Vector3(-0.012, 0.025, 0.0),
		Vector3(-0.012, -0.025, 0.0)
	])
	var idx := PackedInt32Array([0, 1, 2])
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = verts
	data[Mesh.ARRAY_INDEX] = idx
	head_arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	head.mesh = head_arr
	head.material_override = color_mat
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Place at end of arc, oriented along last tangent.
	var theta_end: float = theta_start + float(seg) * theta_step
	var end_pos := Vector3(cos(theta_end) * r, sin(theta_end) * r, 0.0)
	var tangent_angle: float = theta_end + (PI * 0.5 if clockwise else -PI * 0.5)
	head.position = end_pos
	head.rotation = Vector3(0.0, 0.0, tangent_angle)
	root.add_child(head)

	return root


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_readout_root.position = Vector3(disc_radius + 0.18, disc_height, disc_depth)
	add_child(_readout_root)

	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.66, 0.42)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.33, 0.0, -0.005)
	_readout_root.add_child(card)

	_readout_formal = Label3D.new()
	_readout_formal.name = "ReadoutFormal"
	_readout_formal.font_size = 26
	_readout_formal.outline_size = 4
	_readout_formal.pixel_size = 0.001
	_readout_formal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_formal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout_formal.width = 620
	_readout_formal.modulate = Color(0.95, 0.97, 1.0)
	_readout_formal.position = Vector3(0.02, 0.15, 0.0)
	_readout_root.add_child(_readout_formal)

	_readout_verdict = Label3D.new()
	_readout_verdict.name = "ReadoutVerdict"
	_readout_verdict.font_size = 22
	_readout_verdict.outline_size = 3
	_readout_verdict.pixel_size = 0.001
	_readout_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout_verdict.width = 620
	_readout_verdict.modulate = Color(1.0, 0.78, 0.45)
	_readout_verdict.position = Vector3(0.02, 0.05, 0.0)
	_readout_root.add_child(_readout_verdict)

	_readout_proof = Label3D.new()
	_readout_proof.name = "ReadoutProof"
	_readout_proof.font_size = 18
	_readout_proof.outline_size = 3
	_readout_proof.pixel_size = 0.001
	_readout_proof.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_proof.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout_proof.width = 620
	_readout_proof.modulate = Color(0.95, 0.95, 0.75)
	_readout_proof.position = Vector3(0.02, -0.06, 0.0)
	_readout_root.add_child(_readout_proof)


# ── Lamp ──────────────────────────────────────────────────────────────

func _build_lamp() -> void:
	# Small spherical bulb sitting above the disc.
	_lamp_inst = MeshInstance3D.new()
	_lamp_inst.name = "ConsistencyLamp"
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 16
	sm.rings = 8
	_lamp_inst.mesh = sm
	_lamp_material = StandardMaterial3D.new()
	_lamp_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lamp_material.albedo_color = color_lamp_green
	_lamp_material.emission_enabled = true
	_lamp_material.emission = color_lamp_green
	_lamp_material.emission_energy_multiplier = 1.5
	_lamp_inst.material_override = _lamp_material
	_lamp_inst.position = Vector3(-disc_radius - 0.18, disc_height + 0.05, disc_depth)
	add_child(_lamp_inst)

	var lab := Label3D.new()
	lab.name = "LampLabel"
	lab.text = "rule check"
	lab.font_size = 16
	lab.outline_size = 2
	lab.pixel_size = 0.001
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.modulate = Color(0.85, 0.95, 1.0)
	lab.position = Vector3(-disc_radius - 0.18, disc_height - 0.06, disc_depth)
	add_child(lab)


func _set_lamp(lamp_id: String) -> void:
	if _lamp_material == null:
		return
	_lamp_should_blink = false
	_lamp_blink_t = 0.0
	match lamp_id:
		"green":
			_lamp_material.albedo_color = color_lamp_green
			_lamp_material.emission = color_lamp_green
			_lamp_material.emission_energy_multiplier = 1.5
		"amber":
			_lamp_material.albedo_color = color_lamp_amber
			_lamp_material.emission = color_lamp_amber
			_lamp_material.emission_energy_multiplier = 1.3
		"red":
			_lamp_material.albedo_color = color_lamp_red
			_lamp_material.emission = color_lamp_red
			_lamp_material.emission_energy_multiplier = 1.6
			_lamp_should_blink = true
		_:
			_lamp_material.albedo_color = color_lamp_green
			_lamp_material.emission = color_lamp_green


# ── ZFC card ──────────────────────────────────────────────────────────

func _build_zfc_card() -> void:
	_zfc_card_root = Node3D.new()
	_zfc_card_root.name = "ZFCCard"
	_zfc_card_root.position = Vector3(0.0, disc_height - disc_radius - 0.22, disc_depth + 0.02)
	add_child(_zfc_card_root)

	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.95, 0.20)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.04, 0.06, 0.10, 0.0)
	card_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	card.material_override = card_mat
	card.position = Vector3(0.0, 0.0, -0.005)
	_zfc_card_root.add_child(card)

	var lab_title := Label3D.new()
	lab_title.name = "ZFCTitle"
	lab_title.text = "ZFC: axiom of separation"
	lab_title.font_size = 22
	lab_title.outline_size = 3
	lab_title.pixel_size = 0.001
	lab_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab_title.modulate = Color(1.0, 0.85, 0.5, 0.0)
	lab_title.position = Vector3(0.0, 0.06, 0.0)
	_zfc_card_root.add_child(lab_title)

	var lab_body := Label3D.new()
	lab_body.name = "ZFCBody"
	lab_body.text = "Filter within an existing set. The result need not be one of its members.\nHere U = {0,1,2,3}, R_U = U = 4, and 4 is not in U."
	lab_body.font_size = 16
	lab_body.outline_size = 2
	lab_body.pixel_size = 0.001
	lab_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab_body.modulate = Color(0.92, 0.95, 1.0, 0.0)
	lab_body.position = Vector3(0.0, -0.03, 0.0)
	_zfc_card_root.add_child(lab_body)


func _apply_zfc_alpha(a: float) -> void:
	if _zfc_card_root == null:
		return
	var clamped: float = clampf(a, 0.0, 1.0)
	_zfc_card_root.visible = clamped > 0.01
	for child in _zfc_card_root.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = (child as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				var col: Color = mat.albedo_color
				col.a = clamped * 0.78
				mat.albedo_color = col
		elif child is Label3D:
			var lab: Label3D = child as Label3D
			var lc: Color = lab.modulate
			lc.a = clamped
			lab.modulate = lc


# ── Apply cell ────────────────────────────────────────────────────────

func _apply_cell(cell_idx: int) -> void:
	_cell = clampi(cell_idx, 0, CELL_COUNT - 1)
	_attempt = -1
	_last_result = {}
	var data: Dictionary = CELL_DEFS[_cell]
	_rebuild_disc(int(data.disc))
	_set_lamp(str(data.lamp))
	_readout_formal.text = str(data.formal)
	_readout_verdict.text = str(data.verdict)
	_readout_proof.text = ""
	if _cell >= 4:
		_readout_proof.text = "Choose IN or OUT: is the result a member of itself?" if membership_controls else "Cell 5: test both answers. Cell 6: restrict the domain."
		_set_lamp("amber")
	_plate_readout.text = "cell %d / %d\n%s" % [_cell + 1, CELL_COUNT, str(data.verdict)]
	_arrows_visible = false
	_arrow_orbit_root.visible = false
	_zfc_card_alpha_t = 0.0
	_zfc_card_current_alpha = 0.0
	_apply_zfc_alpha(0.0)
	if _membership_buttons: _membership_buttons.visible = _cell >= 4
	# Legacy placements still present the argument without requiring new controls.
	if not membership_controls and _cell >= 4: _test_membership(false)


# A finite separation example: n denotes the set {0,...,n-1}.
# Computing members makes the ambient-domain restriction inspectable.
func restricted_members(ambient_size: int = 4) -> Array[int]:
	var result: Array[int] = []
	for x in ambient_size:
		if not range(x).has(x): result.append(x)
	return result


func evaluate_membership(assumed_in: bool, restricted: bool) -> Dictionary:
	var required: bool = not assumed_in
	var domain_contains_result := true
	if restricted:
		var result: Array[int] = restricted_members()
		# Every ordinal < 4 survives, so the result is ordinal 4 = U.
		domain_contains_result = range(4).has(result.size())
		required = domain_contains_result and not assumed_in
	return {"assumed":assumed_in, "required":required, "agrees":assumed_in == required,
		"restricted":restricted, "domain_contains_result":domain_contains_result}


func _build_membership_buttons() -> void:
	if is_instance_valid(_membership_buttons): return
	_membership_buttons = Node3D.new()
	_membership_buttons.name = "MembershipControls"
	add_child(_membership_buttons)
	for i in 2:
		var button := preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = "IN" if i == 0 else "OUT"
		button.position = Vector3((i - 0.5) * 0.36, 1.03, 0.30)
		_membership_buttons.add_child(button)
		button.pressed.connect(_test_membership.bind(i == 0))
		var label := Label3D.new()
		label.text = button.name
		label.font_size = 24
		label.pixel_size = 0.001
		label.position = button.position + Vector3(0, 0.10, 0)
		_membership_buttons.add_child(label)


func _test_membership(assumed_in: bool) -> void:
	if _cell < 4: return
	_attempt = int(assumed_in)
	_last_result = evaluate_membership(assumed_in, _cell == 5)
	var choice := "IN" if assumed_in else "OUT"
	var required := "IN" if _last_result.required else "OUT"
	_readout_verdict.text = "You chose %s; the rule requires %s." % [choice, required]
	_readout_proof.text = "The same assumption requires its opposite. Try the other answer." if _cell == 4 else "R_U = U = 4. But U contains only 0,1,2,3. R_U is OUT of U and OUT of itself."
	_plate_readout.text = "cell %d / 6\n%s -> %s" % [_cell+1, choice, required]
	_set_lamp("green" if _last_result.agrees else "red")
	_rebuild_disc(3 if _cell == 4 else 0)
	_arrows_visible = _cell == 4
	_arrow_orbit_root.visible = _arrows_visible
	_zfc_card_alpha_t = 1.0 if _cell == 5 else 0.0


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("membership_controls"):
		membership_controls = str(config_data.membership_controls).to_lower() in ["true","on","1"]
		if is_node_ready() and membership_controls: _build_membership_buttons()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data.plate_scale)
		if _plate_root: _plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("initial_cell"):
		_cell = clampi(int(config_data.initial_cell)-1, 0, CELL_COUNT-1)
		if _slider: _slider.set_normalized_value(_normalized_for_cell(_cell))
	if is_node_ready(): _apply_cell(_cell)
