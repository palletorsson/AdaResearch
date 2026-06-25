extends Node3D
class_name StationCabinet

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR storage / display cabinet of a curation station — a width_cells × 1 m (per cell) painted-metal case with a tinted glass front, lit internal shelves, glowing back-wall specimens, and a frame, so cabinets line up cell-to-cell as a glowing back wall of stored specimens. Origin at the floor centre; the case faces +Z. Light matte Dieter-Rams body that recedes, ONE warm accent groove, a kick-recess toe at the base, chamfered corner posts, bolted mullions, and a surface-pinned caption plate — so the housing is calm and the lit shelves are the expressive thing.
# desire: to give a set a context of MANY — shelves of related things behind the few on plinths, so the curated items read as chosen from a collection, lit and kept; the glowing display case the reference renders are built around.
# critical_parameter: width_cells + shelf_count — how much grid the storage claims and how densely it reads; the composer flanks the stage with these. front_style chooses the read (glass=display/kept, solid=stored/sealed).
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: glass front + lit shelves + back-wall specimen glow reads "display, kept, valuable"; solid doors read "stored, sealed"; a top readout reads "monitored"; the accent groove + caption plate read "labelled, part of the set". Per-cell chamfered mullions read "modular, built to a grid".
# needs: a case body + back [present]; per-cell chamfered mullion frame [present]; lit shelves + back-wall glow [present]; a tinted glass front w/ mullion divider [present]; base kick-recess + top cap [present]; bolt rows + accent groove + grime [present]; optional readout + three-bar + caption plate [optional].
# relationships: the storage sibling of [[station_wall]] (a wall you can see into); flanks the [[station_stage]]; shares the HangarKit look with the packaging cabinet cluster but tiles on the grid; placed by [[curation_station]].
# truth: to store behind glass is to say "these are kept, and there are more". The plinths show the argument; the cabinet shows the archive it was drawn from.

@export_group("Grid")
@export var width_cells: int = 2
@export_group("Dimensions")
@export var height: float = 1.9
@export var depth: float = 0.5
@export var shelf_count: int = 4
## Recessed toe-kick depth at the base (0 = flush). Lifts the case off the floor visually.
@export var toe_kick: float = 0.05
@export_group("Style")
## "glass" (tinted front + lit shelves) | "solid" (panelled doors).
@export var front_style: String = "glass"
## Family finish routed through HangarKit: "rams" (light Braun default) | "terminal" (dark console).
@export var finish: String = "rams"
## Soft interior glow colour for the lit shelves (display light).
@export var glow_color: Color = Color(0.62, 0.82, 0.92)
## Glow the back wall behind the shelves so stored specimens read as "kept, lit".
@export var back_glow: bool = true
@export var top_readout: bool = false
## A vertical mullion splitting each cell's glass into a left/right pane (more "cabinet", less "vitrine").
@export var glass_divider: bool = true
@export_group("Surface")
@export var stencil_text: String = ""
## Caption pinned to the base rail as a framed 2D-in-3D label (curation rule: text on a surface).
@export var caption_text: String = ""
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true
## A row of bolts along each corner post (the bolted-panel detail).
@export var bolts: bool = true
## A lit accent groove running across the top rail (the "one warm groove").
@export var accent_groove: bool = true
## Chamfered (bevelled) corner posts instead of plain square mullions.
@export var chamfer_posts: bool = true
@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const FRAME_T := 0.06
const BASE_H := 0.12

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_metadata_overrides() -> void:
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_depth"): depth = float(str(get_meta("config_depth")))
	if has_meta("config_shelf_count"): shelf_count = int(str(get_meta("config_shelf_count")))
	if has_meta("config_toe_kick"): toe_kick = float(str(get_meta("config_toe_kick")))
	if has_meta("config_front_style"): front_style = str(get_meta("config_front_style")).to_lower()
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_glow_color"): glow_color = _pc(str(get_meta("config_glow_color")), glow_color)
	if has_meta("config_back_glow"): back_glow = _b(get_meta("config_back_glow"))
	if has_meta("config_top_readout"): top_readout = _b(get_meta("config_top_readout"))
	if has_meta("config_glass_divider"): glass_divider = _b(get_meta("config_glass_divider"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_caption_text"): caption_text = str(get_meta("config_caption_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_accent_groove"): accent_groove = _b(get_meta("config_accent_groove"))
	if has_meta("config_chamfer_posts"): chamfer_posts = _b(get_meta("config_chamfer_posts"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	var n: int = maxi(width_cells, 1)
	var w: float = float(n) * CELL
	var h: float = maxf(height, 0.6)
	var d: float = maxf(depth, 0.25)
	var fz: float = d * 0.5   # +Z face

	# Resolve the family finish so terminal vs rams reads as one set.
	var is_terminal: bool = finish == "terminal"
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"] if is_terminal else body_color
	var col_panel: Color = pal["panel"] if is_terminal else panel_color
	var col_accent: Color = pal["accent"] if is_terminal else accent_color
	var ew: float = float(pal["wear"]) if is_terminal else wear
	var body_mat := HangarKit.finish_body(finish, col_body, ew)
	var trim_mat := HangarKit.worn_metal(col_panel)
	var bolt_mat := HangarKit.worn_metal(col_panel.darkened(0.1))

	var tk: float = clampf(toe_kick, 0.0, 0.12)
	var base_top: float = BASE_H

	# ── Base: a recessed toe-kick plinth (case sits proud of a darker, inset toe). ──
	if tk > 0.001:
		# inset dark toe
		add_child(_box(Vector3(0, tk * 0.5, 0), Vector3(w - 0.08, tk, d - 0.06), HangarKit.worn_metal(col_panel.darkened(0.25))))
		# the case base sits on top of the toe
		add_child(_box(Vector3(0, tk + (base_top - tk) * 0.5, 0), Vector3(w, base_top - tk, d), _mat(col_panel.darkened(0.04), ew)))
	else:
		add_child(_box(Vector3(0, base_top * 0.5, 0), Vector3(w, base_top, d), _mat(col_panel.darkened(0.04), ew)))

	# ── Top cap (a slightly proud lid) + back panel. ──
	add_child(_box(Vector3(0, h - FRAME_T * 0.5, 0), Vector3(w + 0.03, FRAME_T, d + 0.02), _mat(col_body.lightened(0.04), ew)))
	add_child(_box(Vector3(0, h * 0.5, -d * 0.5 + 0.02), Vector3(w, h, 0.04), _mat(col_panel, ew)))

	# ── Side posts + per-cell mullions (the grid frame), chamfered when asked. ──
	for i in range(n + 1):
		var x: float = -w * 0.5 + float(i) * CELL
		if chamfer_posts:
			_add_chamfer_post(x, h, fz, body_mat, col_body)
		else:
			add_child(_box(Vector3(x, h * 0.5, fz - FRAME_T * 0.5), Vector3(FRAME_T, h, FRAME_T), body_mat))
		# bolt row down each post
		if bolts:
			var a := Vector3(x, base_top + 0.12, fz + 0.005)
			var b := Vector3(x, h - FRAME_T - 0.12, fz + 0.005)
			add_child(HangarKit.bolts(a, b, maxi(int(h * 3.0), 4), 0.012, bolt_mat))

	# ── Lit shelves per cell + back-wall specimen glow. ──
	var inner_lo: float = base_top + 0.06
	var inner_hi: float = h - FRAME_T - 0.06
	var sc: int = maxi(shelf_count, 1)
	var shelf_mat := _mat(col_panel.lightened(0.05), ew)
	var glow := _emi(glow_color, 0.9 if not is_terminal else 0.7)
	if back_glow:
		var bg := _emi(glow_color.darkened(0.35), 0.45)
		add_child(_box(Vector3(0, (inner_lo + inner_hi) * 0.5, -d * 0.5 + 0.06),
			Vector3(w - FRAME_T * 1.4, inner_hi - inner_lo, 0.012), bg))
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for s in range(sc):
			var sy: float = lerpf(inner_lo, inner_hi, float(s) / float(maxi(sc - 1, 1)))
			add_child(_box(Vector3(cx, sy, 0), Vector3(CELL - FRAME_T * 1.6, 0.02, d - 0.1), shelf_mat))
			# under-shelf glow strip
			add_child(_box(Vector3(cx, sy - 0.025, fz - 0.06), Vector3(CELL - FRAME_T * 2.2, 0.012, 0.02), glow))

	# ── Front: tinted glass (w/ optional mullion divider) or panelled doors. ──
	if front_style == "solid":
		for i in range(n):
			var cx2: float = -w * 0.5 + (float(i) + 0.5) * CELL
			add_child(_box(Vector3(cx2, (inner_lo + inner_hi) * 0.5, fz - 0.02),
				Vector3(CELL - FRAME_T * 1.4, inner_hi - inner_lo, 0.03), _mat(col_panel, ew)))
			# door pull
			add_child(_box(Vector3(cx2 + 0.28, (inner_lo + inner_hi) * 0.5, fz + 0.005), Vector3(0.02, 0.12, 0.02), trim_mat))
	else:
		var glass := _glass_mat()
		add_child(_box(Vector3(0, (inner_lo + inner_hi) * 0.5, fz - 0.015),
			Vector3(w - FRAME_T * 0.5, inner_hi - inner_lo, 0.02), glass))
		if glass_divider:
			for i in range(n):
				var dx: float = -w * 0.5 + (float(i) + 0.5) * CELL
				add_child(_box(Vector3(dx, (inner_lo + inner_hi) * 0.5, fz - 0.012),
					Vector3(FRAME_T * 0.6, inner_hi - inner_lo, FRAME_T * 0.7), body_mat))

	# ── Top readout (optional monitored read). ──
	if top_readout:
		var ro: Node3D = HangarKit.readout("ARCHIVE", ["%d UNITS" % (n * sc), "SEALED"], Vector2(minf(w * 0.5, 0.7), 0.3))
		if ro:
			ro.position = Vector3(0, h - 0.02, fz - 0.04)
			add_child(ro)

	# ── The one warm accent: a lit groove across the top rail (the Rams "single warm element"). ──
	if accent_groove:
		add_child(_box(Vector3(0, h - FRAME_T - 0.02, fz + 0.005),
			Vector3(w - FRAME_T * 1.2, 0.018, 0.012), _emi(col_accent, 1.4)))

	# ── Three-colour bar (the calm Rams triad). ──
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 0.9), 0.04, [col_accent, HangarKit.DISPLAY_DARK, col_panel])
		bar.position = Vector3(0, h - FRAME_T - 0.085, fz + 0.012)
		add_child(bar)

	# ── Restrained wear + dust streaks below the top seam. ──
	if grime:
		add_child(HangarKit.grime_band(w, 0.06, fz - 0.02, col_body))
		add_child(HangarKit.dust_streaks(w - FRAME_T * 2.0, inner_hi - inner_lo, fz + 0.002, maxi(n * 2, 4)))

	# ── Stencil ID printed onto the base (painted-on, takes light). ──
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.3, 0.5), 0.09))
		if q:
			q.position = Vector3(-w * 0.5 + 0.35, base_top + 0.12, fz + 0.012)
			add_child(q)

	# ── Caption: a framed 2D-in-3D label pinned to the base rail (curation rule: text on a surface). ──
	if caption_text.strip_edges() != "":
		_add_caption(caption_text, w, base_top, fz, col_panel)


# A chamfered corner post: a square core with two thin 45° bevel strips on the +Z front edges.
func _add_chamfer_post(x: float, h: float, fz: float, body_mat: Material, col_body: Color) -> void:
	var cy: float = h * 0.5
	add_child(_box(Vector3(x, cy, fz - FRAME_T * 0.5), Vector3(FRAME_T, h, FRAME_T), body_mat))
	var bev_mat := _mat(col_body.lightened(0.06), wear)
	for sgn in [1.0, -1.0]:
		# Thin full-height facet, yawed 45° about Y so it presents a diagonal
		# corner bevel. Keep the long axis VERTICAL (height stays h) — never
		# rotate the tall box about Z, which would swing its 1.9 m length out
		# diagonally and overshoot the cabinet as giant "X" beams.
		var strip := _box(Vector3(x + sgn * FRAME_T * 0.45, cy, fz - FRAME_T * 0.15),
			Vector3(FRAME_T * 0.45, h, FRAME_T * 0.12), bev_mat)
		strip.rotation_degrees = Vector3(0, 45.0 * sgn, 0)
		add_child(strip)


# Framed surface-pinned caption: a small matte black-on-off-white plate + a short connector tab to the rail.
func _add_caption(text: String, w: float, base_top: float, fz: float, col_panel: Color) -> void:
	var cap_w: float = clampf(w * 0.5, 0.34, 0.7)
	var cap_h: float = 0.12
	var plate: Node3D = HangarKit.readout("", [text], Vector2(cap_w, cap_h),
		Color(0.88, 0.86, 0.80), Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	if plate == null:
		return
	# connector tab joining the plate to the cabinet base rail
	add_child(_box(Vector3(0, base_top + 0.02, fz + 0.01), Vector3(0.03, 0.04, 0.02), HangarKit.worn_metal(col_panel)))
	plate.position = Vector3(0, base_top + 0.14, fz + 0.03)
	add_child(plate)


func _glass_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.82, 0.88, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.2
	m.roughness = 0.08
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _mat(c: Color, w: float = -1.0) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, wear if w < 0.0 else w)

func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)

func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi

func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]

func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
