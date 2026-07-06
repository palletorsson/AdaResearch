extends Node3D
class_name QFEPBalanceWorkbench

# @identity
# essence: a four-knob console for the QFEP formula — F, E(S), λ, φ sliders side-by-side on a tilted plate. As you turn them, QFE = F − λ·E(S) + φ·ΔE(S,t) recomputes live; a four-axis radar chart re-draws the knob quadrilateral; the dominant timeline phase is detected and its canonical color tints the readout panel, the radar fill, and an emissive halo behind the whole instrument. The project's organizing frame made into a console you operate.
# desire: learner reads the QFEP formula not as theory but as a balance — the four knobs are not parameters of "a system," they are the four parameters of "the project's own thinking-shape," and the seven phases are the seven characteristic ways those knobs can settle
# critical_parameter: the (F, E, λ, φ) tuple — drives QFE numerically, picks the dominant phase by Manhattan distance against the gallery's 7 phase signatures, swaps the accent color, repaints the radar
# triggers: _ready() builds plate + 4 sliders + radar + readout + halo + phase bar; _process polls all four sliders each frame, recomputes QFE, rebuilds the radar polygon, retints panels to the current phase color
# emerges: the four-knob radar makes the formula's STATE legible at a glance — F top, E right, λ bottom, φ left, polygon shape tells you which phase the system is in before you read the readout; QFE sign tells you whether order or entropy wins; the halo color says where on the spine you are
# needs: slider_horizontal × 4 [present]; Label3D for readouts [present]; ImmediateMesh for radar [present]; the seven PHASE_COLORS dict from timeline page.tsx [hard-coded here]; the gallery's 7 knob signatures from capture_qfep_balance_gallery.gd [hard-coded here]
# relationships: paired with /qfep-balance-gallery (web cells of this instrument frozen at the 7 phases); sibling to shannon_workbench (one knob → 2D hill) and riemann_sum_workbench (one knob → polygon-chasing-curve); contrast: this is a CONSOLE not a slider-with-plot. The console framing matters — there's no single "the answer is QFE = X" reading; the knobs sit BETWEEN regions, never inside one of them. You operate the formula
# truth: the QFEP formula is not a description of a system; it is a navigable balance. F − λ·E(S) + φ·ΔE has seven characteristic settlings (phases). The console makes those settlings hand-cranked.

## A four-knob console for the QFEP formula QFE = F − λ·E(S) + φ·ΔE(S,t).
##
## Four sliders drive (F, E(S), λ, φ) ∈ [0, 1]⁴. As you move them:
##   • the numeric QFE = F − λ·E(S) + φ·ΔE is recomputed (ΔE held at a small
##     constant 0.3 — the rate term is what φ scales, not a thing the player
##     directly turns; the φ knob IS the queer signature)
##   • a four-axis radar polygon (F up, E right, λ down, φ left) re-draws
##     in the dominant phase's color
##   • the dominant phase is detected by Manhattan distance against the
##     gallery's 7 canonical knob signatures (F_order, oscillation,
##     E_entropy, lambda_edge, integration, relation, synthesis)
##   • the readout panel, the phase bar, and a backdrop halo all retint to
##     that phase's color
##
## The frame the project organizes itself around becomes a console you operate.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
## Tilt of the slider plate toward the player.
@export var plate_tilt_deg: float = -25.0
## Plate height above the artifact origin.
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Radar")
## Where the radar floats relative to artifact origin.
@export var radar_offset: Vector3 = Vector3(0.0, 1.55, -0.20)
## Maximum half-extent of the radar (in radar-local meters, before scale).
@export var radar_max: float = 0.42
## Sample resolution of the radar guide rings (4 = diamond, 24 = ~circle).
@export var radar_ring_sides: int = 4

@export_group("Readout panel")
## Where the readout sits relative to artifact origin.
@export var readout_offset: Vector3 = Vector3(0.75, 1.05, 0.05)

@export_group("Phase bar")
## Where the tall phase color bar sits relative to artifact origin.
@export var phase_bar_offset: Vector3 = Vector3(-0.7, 1.1, 0.05)
@export var phase_bar_size: Vector2 = Vector2(0.10, 0.85)

@export_group("Halo")
## Halo radius (the backdrop emissive panel).
@export var halo_size: Vector2 = Vector2(2.2, 1.7)
## Halo Z offset behind everything else.
@export var halo_offset: Vector3 = Vector3(0.0, 1.1, -0.4)

@export_group("Defaults")
## Default starting knob values — lambda_edge (the project's organizing phase).
@export var default_F: float = 0.55
@export var default_E: float = 0.58
@export var default_lambda: float = 0.4
@export var default_phi: float = 0.35
## The ΔE(S, t) constant the φ knob multiplies. Holding this fixed is honest:
## the player doesn't independently scrub a rate; the rate exists, and φ tunes
## how sensitive the formula is to it. ΔE = 0.3 sits in the middle of the
## "things are changing, moderately" band.
@export var rate_delta_e: float = 0.30

# ── Phase data (mirrors capture_qfep_balance_gallery.gd PHASES) ───────
# Each phase: id, display name, color (timeline PHASE_COLORS), F/E/λ/φ
# signature, dominant letter, formula readout, caption.

const PHASE_DATA: Array = [
	{
		"id": "F_order",
		"display": "F — Order",
		"color": Color(0.227, 0.482, 1.0),     # #3A7BFF
		"F": 0.95, "E": 0.05, "lambda": 0.05, "phi": 0.0,
		"letter": "F",
		"formula": "QFE ≈ F",
	},
	{
		"id": "oscillation",
		"display": "F ↔ E — Oscillation",
		"color": Color(0.490, 1.0, 0.659),     # #7DFFA8
		"F": 0.65, "E": 0.55, "lambda": 0.4, "phi": 0.3,
		"letter": "ω",
		"formula": "QFE = F − 0.4·E(S) + 0.3·ΔE",
	},
	{
		"id": "E_entropy",
		"display": "λE(S) — Entropy",
		"color": Color(0.957, 0.635, 0.380),   # #F4A261
		"F": 0.35, "E": 0.92, "lambda": 0.95, "phi": 0.15,
		"letter": "E",
		"formula": "QFE = F − 0.95·E(S)",
	},
	{
		"id": "lambda_edge",
		"display": "λ ≈ 0.4 — Edge of Chaos",
		"color": Color(0.902, 0.224, 0.275),   # #E63946
		"F": 0.55, "E": 0.58, "lambda": 0.4, "phi": 0.35,
		"letter": "λ",
		"formula": "QFE = F − 0.4·E(S) + 0.35·ΔE",
	},
	{
		"id": "integration",
		"display": "φΔE — Integration",
		"color": Color(0.608, 0.365, 0.898),   # #9B5DE5
		"F": 0.55, "E": 0.62, "lambda": 0.55, "phi": 0.85,
		"letter": "φ",
		"formula": "QFE = F − 0.55·E(S) + 0.85·ΔE",
	},
	{
		"id": "relation",
		"display": "(•—•) — Relation",
		"color": Color(0.984, 0.890, 0.541),   # #FBE38A
		"F": 0.6, "E": 0.4, "lambda": 0.4, "phi": 0.55,
		"letter": "G",
		"formula": "QFE on a graph",
	},
	{
		"id": "synthesis",
		"display": "QFE — Synthesis",
		"color": Color(1.0, 1.0, 1.0),         # #FFFFFF
		"F": 0.7, "E": 0.65, "lambda": 0.5, "phi": 0.7,
		"letter": "Q",
		"formula": "QFE = F − λE(S) + φΔE(S,t)",
	},
]

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const DisplayMount = preload("res://commons/ui/display_mount.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# Knob labels (top → right → bottom → left)
const KNOB_NAMES: Array = ["F", "E(S)", "λ", "φ"]

# ── Internal state ────────────────────────────────────────────────────

var _F: float = 0.55
var _E: float = 0.58
var _lambda: float = 0.4
var _phi: float = 0.35
var _qfe: float = 0.0
var _phase_index: int = 3  # lambda_edge default

var _plate_root: Node3D
var _display_root: Node3D            # anchor that carries the viz cluster
var _halo_inst: MeshInstance3D       # background glow, mounted with the cluster
var _sliders: Array = []  # 4 slider instances, in order [F, E, λ, φ]
var _plate_readout
var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

var _radar_root: Node3D
var _radar_polygon_mesh: ImmediateMesh
var _radar_polygon_mesh_inst: MeshInstance3D
var _radar_polygon_material: StandardMaterial3D
var _radar_outline_mesh: ImmediateMesh
var _radar_outline_mesh_inst: MeshInstance3D
var _radar_outline_material: StandardMaterial3D
var _radar_knob_dots: Array = []  # 4 MeshInstance3Ds + their materials
var _radar_knob_materials: Array = []
var _radar_hub_material: StandardMaterial3D
var _radar_letter_label: Label3D

var _readout_root: Node3D
var _readout_card_material: StandardMaterial3D
var _readout_border_material: StandardMaterial3D
var _readout_block: Node3D            # one consolidated multi-line baked-text board
const READOUT_BLOCK_WIDTH := 0.60     # meters, inside the 0.66-wide card
const READOUT_LINE_H := 0.045         # per-line height in meters

var _phase_bar_root: Node3D
var _phase_bar_material: StandardMaterial3D
var _phase_bar_label_top: Label3D
var _phase_bar_label_letter: Label3D

var _halo_material: StandardMaterial3D


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_F = clampf(default_F, 0.0, 1.0)
	_E = clampf(default_E, 0.0, 1.0)
	_lambda = clampf(default_lambda, 0.0, 1.0)
	_phi = clampf(default_phi, 0.0, 1.0)

	_build_halo()
	_build_plate_and_sliders()
	_build_radar()
	_build_readout_panel()
	_build_phase_bar()
	_refresh_all()
	_mount_display.call_deferred()


## Gather the viz roots onto a composer-placed anchor + floor stand (DisplayMount).
func _mount_display() -> void:
	var center := radar_offset
	_display_root = DisplayMount.make_anchor(self, "qfep_balance_workbench", center, 1.0, 0.0)
	DisplayMount.mount_cluster(_display_root, [_radar_root, _readout_root, _phase_bar_root, _halo_inst], center)
	DisplayMount.build_stand(self, _display_root)


func _process(_delta: float) -> void:
	# Poll all 4 sliders each frame. Cheaper than signal connections in a
	# 4-knob setup and avoids dependency on slider_moved emit timing.
	var changed: bool = false
	if _sliders.size() == 4:
		var new_F: float = _read_slider(0, _F)
		var new_E: float = _read_slider(1, _E)
		var new_L: float = _read_slider(2, _lambda)
		var new_P: float = _read_slider(3, _phi)
		if not is_equal_approx(new_F, _F) or not is_equal_approx(new_E, _E) \
				or not is_equal_approx(new_L, _lambda) or not is_equal_approx(new_P, _phi):
			_F = new_F
			_E = new_E
			_lambda = new_L
			_phi = new_P
			changed = true
	if changed:
		_viz_dirty = true
	# Throttled rebuild — values update every frame, but the radar/readout rebuild
	# runs at most every VIZ_REFRESH_INTERVAL so it never fights the grab.
	if _viz_cooldown > 0.0:
		_viz_cooldown -= _delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


func _read_slider(idx: int, default: float) -> float:
	var s = _sliders[idx]
	if s != null and s.has_method("get_normalized_value"):
		return clampf(float(s.call("get_normalized_value")), 0.0, 1.0)
	return default


# ── QFE computation + phase detection ─────────────────────────────────

func _compute_qfe() -> float:
	# QFE = F − λ·E(S) + φ·ΔE(S, t)
	return _F - _lambda * _E + _phi * rate_delta_e


func _detect_phase() -> int:
	# Manhattan distance against the 7 phase signatures. Smallest wins.
	var best_idx: int = 0
	var best_d: float = 1.0e9
	for i in range(PHASE_DATA.size()):
		var p: Dictionary = PHASE_DATA[i]
		var d: float = abs(_F - float(p.F)) + abs(_E - float(p.E)) \
				+ abs(_lambda - float(p.lambda)) + abs(_phi - float(p.phi))
		if d < best_d:
			best_d = d
			best_idx = i
	return best_idx


# ── Halo (emissive backdrop) ──────────────────────────────────────────

func _build_halo() -> void:
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var qm := QuadMesh.new()
	qm.size = halo_size
	halo.mesh = qm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = halo_offset

	_halo_material = StandardMaterial3D.new()
	_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_material.albedo_color = Color(0.05, 0.06, 0.10, 0.0)
	_halo_material.emission_enabled = true
	_halo_material.emission = Color(0.5, 0.5, 0.5)
	_halo_material.emission_energy_multiplier = 0.6
	_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = _halo_material
	add_child(halo)
	_halo_inst = halo


# ── Plate + 4 sliders ─────────────────────────────────────────────────

func _build_plate_and_sliders() -> void:
	# Canonical desktop ControlConsole (workbench principal): the 4 QFEP knobs
	# (F · E · λ · φ) as a slider row + a summary readout. The radar / phase bar /
	# detail readout stay as world-space viz. Replaces the hand-built plate + jumpy
	# slider_horizontal with the canonical slider_smooth row.
	_plate_root = InterfacePresets.build("workbench", "QFEP Balance", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")
	var defaults: Array = [_F, _E, _lambda, _phi]
	_sliders.clear()
	for i in range(4):
		var s = _plate_root.add_slider(KNOB_NAMES[i], KNOB_NAMES[i])
		if s and s.has_method("set_normalized_value"):
			s.call("set_normalized_value", float(defaults[i]))
		_sliders.append(s)


# ── Radar (4-axis, F top / E right / λ down / φ left) ─────────────────

func _build_radar() -> void:
	_radar_root = Node3D.new()
	_radar_root.name = "Radar"
	_radar_root.position = radar_offset
	add_child(_radar_root)

	# Backplate — a tinted square behind the radar
	var back := MeshInstance3D.new()
	back.name = "RadarBackplate"
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(radar_max * 2.4, radar_max * 2.4)
	back.mesh = back_mesh
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.03, 0.05)
	back_mat.roughness = 0.95
	back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	back.material_override = back_mat
	back.position = Vector3(0.0, 0.0, -0.01)
	_radar_root.add_child(back)

	# Guide rings (concentric diamonds at 0.25, 0.5, 0.75, 1.0).
	for r_frac in [0.25, 0.5, 0.75, 1.0]:
		var r: float = radar_max * float(r_frac)
		var ring_color := Color(0.32, 0.34, 0.42, 0.55)
		if r_frac == 1.0:
			ring_color = Color(0.46, 0.50, 0.60, 0.85)
		_radar_root.add_child(_make_diamond_outline(r, ring_color, 0.0, 0.005))

	# Axes (4 spokes from center)
	var axis_color := Color(0.42, 0.46, 0.56, 0.75)
	_radar_root.add_child(_make_line(Vector2.ZERO, Vector2(0, radar_max), axis_color, 0.005, 0.005))
	_radar_root.add_child(_make_line(Vector2.ZERO, Vector2(radar_max, 0), axis_color, 0.005, 0.005))
	_radar_root.add_child(_make_line(Vector2.ZERO, Vector2(0, -radar_max), axis_color, 0.005, 0.005))
	_radar_root.add_child(_make_line(Vector2.ZERO, Vector2(-radar_max, 0), axis_color, 0.005, 0.005))

	# Axis labels at the tips — integrated 2D-in-3D TAG boards, one per axis, pushed
	# clear of the radar rim and each other (top/right/bottom/left, no overlap).
	var tag_h: float = 0.075
	var tag_gap: float = 0.12    # distance from the ring tip to the board center
	_radar_root.add_child(_mk_axis_tag("F",    Color(0.227, 0.482, 1.0),   Vector3(0.0,  radar_max + tag_gap, 0.02), tag_h))
	_radar_root.add_child(_mk_axis_tag("E(S)", Color(0.957, 0.635, 0.380), Vector3(radar_max + tag_gap + 0.06, 0.0, 0.02), tag_h))
	_radar_root.add_child(_mk_axis_tag("λ",    Color(0.902, 0.224, 0.275), Vector3(0.0, -radar_max - tag_gap, 0.02), tag_h))
	_radar_root.add_child(_mk_axis_tag("φ",    Color(0.608, 0.365, 0.898), Vector3(-radar_max - tag_gap - 0.06, 0.0, 0.02), tag_h))

	# Polygon fill — translucent, gets retinted per phase
	_radar_polygon_mesh = ImmediateMesh.new()
	_radar_polygon_mesh_inst = MeshInstance3D.new()
	_radar_polygon_mesh_inst.name = "RadarPolygon"
	_radar_polygon_mesh_inst.mesh = _radar_polygon_mesh
	_radar_polygon_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_radar_polygon_material = StandardMaterial3D.new()
	_radar_polygon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_radar_polygon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_radar_polygon_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_radar_polygon_material.albedo_color = Color(0.902, 0.224, 0.275, 0.45)
	_radar_polygon_mesh_inst.material_override = _radar_polygon_material
	_radar_root.add_child(_radar_polygon_mesh_inst)

	# Polygon outline — opaque, brighter
	_radar_outline_mesh = ImmediateMesh.new()
	_radar_outline_mesh_inst = MeshInstance3D.new()
	_radar_outline_mesh_inst.name = "RadarOutline"
	_radar_outline_mesh_inst.mesh = _radar_outline_mesh
	_radar_outline_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_radar_outline_material = StandardMaterial3D.new()
	_radar_outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_radar_outline_material.emission_enabled = true
	_radar_outline_material.emission = Color(0.902, 0.224, 0.275)
	_radar_outline_material.emission_energy_multiplier = 1.8
	_radar_outline_material.albedo_color = Color(0.902, 0.224, 0.275)
	_radar_outline_mesh_inst.material_override = _radar_outline_material
	_radar_root.add_child(_radar_outline_mesh_inst)

	# Knob dots at each vertex (F, E, λ, φ)
	_radar_knob_dots.clear()
	_radar_knob_materials.clear()
	for i in range(4):
		var dot := MeshInstance3D.new()
		dot.name = "KnobDot_%s" % KNOB_NAMES[i]
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		sphere.radial_segments = 12
		sphere.rings = 6
		dot.mesh = sphere
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dot_mat := StandardMaterial3D.new()
		dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dot_mat.emission_enabled = true
		dot_mat.emission = Color(0.902, 0.224, 0.275)
		dot_mat.emission_energy_multiplier = 2.0
		dot_mat.albedo_color = Color(0.902, 0.224, 0.275)
		dot.material_override = dot_mat
		_radar_root.add_child(dot)
		_radar_knob_dots.append(dot)
		_radar_knob_materials.append(dot_mat)

	# Center hub — solid dark circle with the dominant phase letter
	var hub := MeshInstance3D.new()
	hub.name = "Hub"
	var hub_sphere := SphereMesh.new()
	hub_sphere.radius = 0.05
	hub_sphere.height = 0.1
	hub_sphere.radial_segments = 24
	hub_sphere.rings = 12
	hub.mesh = hub_sphere
	hub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_radar_hub_material = StandardMaterial3D.new()
	_radar_hub_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_radar_hub_material.albedo_color = Color(0.10, 0.12, 0.16, 1.0)
	_radar_hub_material.emission_enabled = true
	_radar_hub_material.emission = Color(0.902, 0.224, 0.275)
	_radar_hub_material.emission_energy_multiplier = 0.6
	hub.material_override = _radar_hub_material
	hub.position = Vector3(0, 0, 0.005)
	_radar_root.add_child(hub)

	# Letter at center
	_radar_letter_label = Label3D.new()
	_radar_letter_label.name = "RadarLetter"
	_radar_letter_label.text = "λ"
	_radar_letter_label.font_size = 48
	_radar_letter_label.outline_size = 4
	_radar_letter_label.pixel_size = 0.001
	_radar_letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radar_letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_radar_letter_label.modulate = Color(0.902, 0.224, 0.275)
	_radar_letter_label.position = Vector3(0, 0, 0.06)
	_radar_root.add_child(_radar_letter_label)


func _refresh_radar() -> void:
	if _radar_polygon_mesh == null:
		return
	# Vertex positions in radar-local 2D, with the 4 knobs at the 4 axes.
	var top := Vector2(0.0, radar_max * _F)
	var right := Vector2(radar_max * _E, 0.0)
	var bottom := Vector2(0.0, -radar_max * _lambda)
	var left := Vector2(-radar_max * _phi, 0.0)
	var z: float = 0.01
	var outline_z: float = 0.02

	# Polygon fill
	_radar_polygon_mesh.clear_surfaces()
	_radar_polygon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_radar_polygon_mesh.surface_add_vertex(Vector3(top.x, top.y, z))
	_radar_polygon_mesh.surface_add_vertex(Vector3(right.x, right.y, z))
	_radar_polygon_mesh.surface_add_vertex(Vector3(bottom.x, bottom.y, z))
	_radar_polygon_mesh.surface_add_vertex(Vector3(top.x, top.y, z))
	_radar_polygon_mesh.surface_add_vertex(Vector3(bottom.x, bottom.y, z))
	_radar_polygon_mesh.surface_add_vertex(Vector3(left.x, left.y, z))
	_radar_polygon_mesh.surface_end()

	# Polygon outline as 4 quads (thick lines)
	_radar_outline_mesh.clear_surfaces()
	_radar_outline_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_thick_line(_radar_outline_mesh, top, right, outline_z, 0.008)
	_append_thick_line(_radar_outline_mesh, right, bottom, outline_z, 0.008)
	_append_thick_line(_radar_outline_mesh, bottom, left, outline_z, 0.008)
	_append_thick_line(_radar_outline_mesh, left, top, outline_z, 0.008)
	_radar_outline_mesh.surface_end()

	# Move knob dots to the vertices
	if _radar_knob_dots.size() == 4:
		(_radar_knob_dots[0] as MeshInstance3D).position = Vector3(top.x, top.y, outline_z + 0.005)
		(_radar_knob_dots[1] as MeshInstance3D).position = Vector3(right.x, right.y, outline_z + 0.005)
		(_radar_knob_dots[2] as MeshInstance3D).position = Vector3(bottom.x, bottom.y, outline_z + 0.005)
		(_radar_knob_dots[3] as MeshInstance3D).position = Vector3(left.x, left.y, outline_z + 0.005)


func _append_thick_line(im: ImmediateMesh, a: Vector2, b: Vector2, z: float, thickness: float) -> void:
	# Adds two triangles forming a thick line segment from a → b.
	var d := (b - a)
	if d.length() < 0.0001:
		return
	d = d.normalized()
	var p := Vector2(-d.y, d.x) * (thickness * 0.5)
	var v1 := a + p
	var v2 := a - p
	var v3 := b - p
	var v4 := b + p
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v2.x, v2.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v4.x, v4.y, z))


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_readout_root.position = readout_offset
	add_child(_readout_root)

	# Dark backing card
	var card := MeshInstance3D.new()
	card.name = "Card"
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.66, 0.62)
	card.mesh = card_mesh
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_readout_card_material = StandardMaterial3D.new()
	_readout_card_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_readout_card_material.albedo_color = Color(0.03, 0.05, 0.08)
	card.material_override = _readout_card_material
	card.position = Vector3(0.0, 0.0, -0.005)
	_readout_root.add_child(card)

	# Phase-color border (a slightly larger card behind, gets retinted)
	var border := MeshInstance3D.new()
	border.name = "Border"
	var border_mesh := QuadMesh.new()
	border_mesh.size = Vector2(0.69, 0.65)
	border.mesh = border_mesh
	border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_readout_border_material = StandardMaterial3D.new()
	_readout_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_readout_border_material.albedo_color = Color(0.902, 0.224, 0.275)
	_readout_border_material.emission_enabled = true
	_readout_border_material.emission = Color(0.902, 0.224, 0.275)
	_readout_border_material.emission_energy_multiplier = 0.8
	border.material_override = _readout_border_material
	border.position = Vector3(0.0, 0.0, -0.012)
	_readout_root.add_child(border)

	# The readout body is ONE consolidated multi-line baked-text board (built in
	# _refresh_readout so the values stay live). No stack of floating Label3Ds.
	_readout_block = null


func _refresh_readout() -> void:
	var phase: Dictionary = PHASE_DATA[_phase_index]
	var phase_color: Color = phase.color

	# Numeric expansion of the whole formula, on ONE panel:
	#   QFE = F − λ·E(S) + φ·ΔE
	#   = 0.55 − 0.40·0.58 + 0.35·0.30 = 0.42
	#   dominant phase: lambda_edge   color: #E63946
	#   Q = the recursive maker-modifier / the formula recognizing itself
	var sign_str: String = "" if _qfe >= 0.0 else "−"
	var lines: Array = [
		"QFE = F − λ·E(S) + φ·ΔE",
		"= %.2f − %.2f·%.2f + %.2f·%.2f = %s%.2f" % [
			_F, _lambda, _E, _phi, rate_delta_e, sign_str, abs(_qfe)],
		"dominant phase: %s" % phase.id,
		"color: %s" % _color_to_hex(phase_color),
		"Q = the recursive maker-modifier",
		"the formula recognizing itself",
	]

	# Rebuild the consolidated board in the phase color. Rebuild-on-change is
	# fine — _refresh_readout only runs on the throttled viz tick, not per frame.
	if _readout_block != null and is_instance_valid(_readout_block):
		_readout_block.queue_free()
	_readout_block = BakedText.make_text_block(
		lines, phase_color, READOUT_LINE_H, READOUT_BLOCK_WIDTH, READOUT_LINE_H * 0.35, true)
	if _readout_block != null:
		_readout_block.name = "ReadoutBlock"
		_readout_block.position = Vector3(0.0, 0.0, 0.002)
		_readout_root.add_child(_readout_block)

	# Retint the border to the phase color
	_readout_border_material.albedo_color = phase_color
	_readout_border_material.emission = phase_color


# ── Phase bar (tall colored bar to the side) ──────────────────────────

func _build_phase_bar() -> void:
	_phase_bar_root = Node3D.new()
	_phase_bar_root.name = "PhaseBar"
	_phase_bar_root.position = phase_bar_offset
	add_child(_phase_bar_root)

	# The tall bar
	var bar := MeshInstance3D.new()
	bar.name = "Bar"
	var bar_mesh := QuadMesh.new()
	bar_mesh.size = phase_bar_size
	bar.mesh = bar_mesh
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_phase_bar_material = StandardMaterial3D.new()
	_phase_bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_phase_bar_material.albedo_color = Color(0.902, 0.224, 0.275)
	_phase_bar_material.emission_enabled = true
	_phase_bar_material.emission = Color(0.902, 0.224, 0.275)
	_phase_bar_material.emission_energy_multiplier = 1.4
	bar.material_override = _phase_bar_material
	_phase_bar_root.add_child(bar)

	# Label above (phase name)
	_phase_bar_label_top = Label3D.new()
	_phase_bar_label_top.name = "PhaseDisplay"
	_phase_bar_label_top.font_size = 22
	_phase_bar_label_top.outline_size = 4
	_phase_bar_label_top.pixel_size = 0.001
	_phase_bar_label_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_bar_label_top.modulate = Color(0.902, 0.224, 0.275)
	_phase_bar_label_top.position = Vector3(0.0, phase_bar_size.y * 0.5 + 0.06, 0.01)
	_phase_bar_root.add_child(_phase_bar_label_top)

	# Letter on the bar (large)
	_phase_bar_label_letter = Label3D.new()
	_phase_bar_label_letter.name = "PhaseLetter"
	_phase_bar_label_letter.font_size = 80
	_phase_bar_label_letter.outline_size = 6
	_phase_bar_label_letter.pixel_size = 0.001
	_phase_bar_label_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_bar_label_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase_bar_label_letter.modulate = Color(1.0, 1.0, 1.0)
	_phase_bar_label_letter.position = Vector3(0.0, 0.0, 0.012)
	_phase_bar_root.add_child(_phase_bar_label_letter)


func _refresh_phase_bar() -> void:
	var phase: Dictionary = PHASE_DATA[_phase_index]
	var c: Color = phase.color
	_phase_bar_material.albedo_color = c
	_phase_bar_material.emission = c
	_phase_bar_label_top.text = str(phase.display)
	_phase_bar_label_top.modulate = c
	_phase_bar_label_letter.text = str(phase.letter)
	# Pure white phase (synthesis): use a darker letter for legibility
	if phase.id == "synthesis":
		_phase_bar_label_letter.modulate = Color(0.1, 0.1, 0.13)
	else:
		_phase_bar_label_letter.modulate = Color(1.0, 1.0, 1.0)


# ── Halo refresh ──────────────────────────────────────────────────────

func _refresh_halo() -> void:
	if _halo_material == null:
		return
	var phase: Dictionary = PHASE_DATA[_phase_index]
	var c: Color = phase.color
	_halo_material.emission = c
	# Hold the halo gentle so it tints the backdrop rather than dominating
	_halo_material.emission_energy_multiplier = 0.55
	# Faint translucent tint of the albedo too, for any non-emissive viewport
	var faint: Color = c
	faint.a = 0.08
	_halo_material.albedo_color = faint


# ── Radar tint refresh ────────────────────────────────────────────────

func _refresh_radar_tint() -> void:
	var phase: Dictionary = PHASE_DATA[_phase_index]
	var c: Color = phase.color
	# Fill
	var fill: Color = c
	fill.a = 0.45
	# Synthesis is pure white — keep it readable
	if phase.id == "synthesis":
		fill = Color(0.9, 0.9, 0.9, 0.4)
	_radar_polygon_material.albedo_color = fill
	# Outline
	var outline: Color = c
	if phase.id == "synthesis":
		outline = Color(0.95, 0.95, 0.95, 1.0)
	_radar_outline_material.albedo_color = outline
	_radar_outline_material.emission = outline
	# Knob dots
	for i in range(_radar_knob_materials.size()):
		var m: StandardMaterial3D = _radar_knob_materials[i]
		m.albedo_color = outline
		m.emission = outline
	# Hub
	_radar_hub_material.emission = outline
	# Center letter
	_radar_letter_label.text = str(phase.letter)
	if phase.id == "synthesis":
		_radar_letter_label.modulate = Color(0.95, 0.95, 0.95)
	else:
		_radar_letter_label.modulate = outline


# ── Refresh-all ───────────────────────────────────────────────────────

func _refresh_all() -> void:
	_qfe = _compute_qfe()
	_phase_index = _detect_phase()
	if _plate_readout:
		var pid: String = str(PHASE_DATA[_phase_index].get("id", "")) if _phase_index < PHASE_DATA.size() else ""
		_plate_readout.text = "%s\nQFE = %+.2f" % [pid, _qfe]
	_refresh_radar()
	_refresh_radar_tint()
	_refresh_readout()
	_refresh_phase_bar()
	_refresh_halo()


# ── Primitive builders ────────────────────────────────────────────────

func _make_diamond_outline(r: float, color: Color, z: float, thickness: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Diamond"
	var top := Vector2(0, r)
	var right := Vector2(r, 0)
	var bottom := Vector2(0, -r)
	var left := Vector2(-r, 0)
	holder.add_child(_make_line(top, right, color, z, thickness))
	holder.add_child(_make_line(right, bottom, color, z, thickness))
	holder.add_child(_make_line(bottom, left, color, z, thickness))
	holder.add_child(_make_line(left, top, color, z, thickness))
	return holder


func _make_line(a: Vector2, b: Vector2, color: Color, z: float, thickness: float) -> MeshInstance3D:
	var d := (b - a).normalized()
	var p := Vector2(-d.y, d.x) * (thickness * 0.5)
	var v1 := a + p
	var v2 := a - p
	var v3 := b - p
	var v4 := b + p
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v2.x, v2.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v4.x, v4.y, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _mk_axis_tag(s: String, c: Color, pos: Vector3, world_h: float) -> Node3D:
	# An integrated 2D-in-3D display board (dark face + lit accent edge + baked text)
	# in the axis color, replacing a bare floating Label3D at the radar tip.
	var tag: Node3D = BakedText.make_tag(s, c, world_h, Color(0.06, 0.07, 0.10), false, c)
	if tag == null:
		# Defensive fallback (e.g. no font) so the radar always builds.
		tag = Node3D.new()
	tag.name = "AxisTag_%s" % s
	tag.position = pos
	return tag


func _color_to_hex(c: Color) -> String:
	return "#%02X%02X%02X" % [
		int(round(c.r * 255.0)),
		int(round(c.g * 255.0)),
		int(round(c.b * 255.0)),
	]


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("rate_delta_e"):
		rate_delta_e = clampf(float(config_data["rate_delta_e"]), 0.0, 1.0)
		_refresh_all()
	if config_data.has("initial_F"):
		_F = clampf(float(config_data["initial_F"]), 0.0, 1.0)
		if _sliders.size() > 0 and _sliders[0].has_method("set_normalized_value"):
			_sliders[0].call("set_normalized_value", _F)
	if config_data.has("initial_E"):
		_E = clampf(float(config_data["initial_E"]), 0.0, 1.0)
		if _sliders.size() > 1 and _sliders[1].has_method("set_normalized_value"):
			_sliders[1].call("set_normalized_value", _E)
	if config_data.has("initial_lambda"):
		_lambda = clampf(float(config_data["initial_lambda"]), 0.0, 1.0)
		if _sliders.size() > 2 and _sliders[2].has_method("set_normalized_value"):
			_sliders[2].call("set_normalized_value", _lambda)
	if config_data.has("initial_phi"):
		_phi = clampf(float(config_data["initial_phi"]), 0.0, 1.0)
		if _sliders.size() > 3 and _sliders[3].has_method("set_normalized_value"):
			_sliders[3].call("set_normalized_value", _phi)
	_refresh_all()
