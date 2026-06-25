extends Node3D
class_name StationBarrier

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the GRID-MODULAR front barrier of a curation station — a length_cells × 1 m (per cell) run of bevelled posts with a low panel or rail between them and a caution-striped kickplate, that marks the front edge of the stage: stand back, look, do not cross. Bolted foot plates, a lit accent groove along the top rail, panel seams per bay, surface-pinned brand text. Origin at the floor centre; faces +Z.
# desire: to draw the line a viewer stops at — to turn an open stage into a presented one with a threshold, the way a museum rope or a lab barrier says "the exhibit begins here". To do it in the Dieter-Rams family hand: a light body that recedes, one warm accent, caution stripes worn just enough to read as real.
# critical_parameter: length_cells + style — how wide the threshold is and whether it reads as a solid panel (lab) or an open rail (gallery rope); finish recolours the whole family in one move.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a solid panel reads "contained, lab"; a rail reads "gallery, look-but"; chevrons + stripes read "official, keep clear"; a tray-low barrier reads "specimen rail"; a monumental run reads "perimeter, secure"; posts on every cell read "modular, built to a grid".
# needs: bevelled posts on every cell boundary + bolted foot plates [present]; a panel or rail spanning each bay [present]; a lit accent groove cap [present]; optional caution kickplate + chevrons + 2D-in-3D brand plate [optional].
# relationships: the threshold sibling of [[station_stage]] (the front edge it guards); shares the HangarKit look with the packaging barrier fence but tiles on the grid; placed at the stage front by [[curation_station]]; the cousin of [[station_plinth]] (same family hand, different job).
# truth: a barrier is the smallest grammar of presentation: it says "this side is yours, that side is the work". To draw the line is to make a thing an exhibit.

@export_group("Grid")
@export var length_cells: int = 4
@export_group("Dimensions")
@export var height: float = 1.0
## Post cross-section width (square). Slimmer = gallery, chunkier = perimeter/lab.
@export var post_w: float = 0.1
@export_group("Style")
## "panel" (solid bays) | "rail" (open horizontal rails).
@export var style: String = "panel"
## Family finish — "rams" (light Braun default) | "terminal" (dark console).
@export var finish: String = "rams"
## Post form — "bevelled" (chamfered cap + slim shaft) | "box" (plain).
@export var post_style: String = "bevelled"
@export var hazard_base: bool = true
## Caution chevron strip across panel bays (keep-clear arrows). Reads "official".
@export var chevrons: bool = true
## Number of horizontal rails when style == "rail".
@export var rail_count: int = 2
## A continuous top rail capping the posts (panel style). Ties the run together.
@export var top_rail: bool = true
## 2D-in-3D brand text across the front (empty = none).
@export var brand_text: String = ""
@export_group("Surface")
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true
## Bolt rows on the foot plates + rail ends.
@export var bolt_rows: bool = true
## Lit accent groove along the top rail / accent caps on posts.
@export var cap_lights: bool = true
## Inset seam panels per bay (panel style) — modular reading at every length.
@export var panel_seams: bool = true
## Faint vertical dust streaks down the panel faces.
@export var dust: bool = true
@export_group("Color")
@export var panel_color: Color = Color(0.81, 0.79, 0.75)
@export var post_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const PANEL_T := 0.05
const FOOT_W := 0.24
const FOOT_H := 0.035
const RAIL_T := 0.045

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
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_post_w"): post_w = float(str(get_meta("config_post_w")))
	if has_meta("config_style"): style = str(get_meta("config_style")).to_lower()
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_post_style"): post_style = str(get_meta("config_post_style")).to_lower()
	if has_meta("config_hazard_base"): hazard_base = _b(get_meta("config_hazard_base"))
	if has_meta("config_chevrons"): chevrons = _b(get_meta("config_chevrons"))
	if has_meta("config_rail_count"): rail_count = int(str(get_meta("config_rail_count")))
	if has_meta("config_top_rail"): top_rail = _b(get_meta("config_top_rail"))
	if has_meta("config_brand_text"): brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_bolt_rows"): bolt_rows = _b(get_meta("config_bolt_rows"))
	if has_meta("config_cap_lights"): cap_lights = _b(get_meta("config_cap_lights"))
	if has_meta("config_panel_seams"): panel_seams = _b(get_meta("config_panel_seams"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_post_color"): post_color = _pc(str(get_meta("config_post_color")), post_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	# Finish recolours the whole family in one move (rams / terminal).
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var body_c: Color = panel_color if finish == "rams" else Color(pal["body"])
	var post_c: Color = post_color if finish == "rams" else Color(pal["panel"])
	var acc_c: Color = accent_color if finish == "rams" else Color(pal["accent"])
	var local_wear: float = wear if finish == "rams" else maxf(wear, float(pal["wear"]))

	var n: int = maxi(length_cells, 1)
	var w: float = float(n) * CELL
	var h: float = maxf(height, 0.4)
	var pw: float = clampf(post_w, 0.05, 0.4)
	var front_z: float = PANEL_T * 0.5     # +Z working surface for dressing

	var post_mat := HangarKit.finish_body(finish, post_c.darkened(0.04), local_wear)
	var post_trim := HangarKit.worn_metal(post_c)
	var foot_mat := HangarKit.worn_metal(post_c.darkened(0.05))
	var bolt_mat := HangarKit.worn_metal(post_c.darkened(0.18))
	var rail_mat := HangarKit.finish_body(finish, post_c.lightened(0.03), local_wear)

	# ── Posts + bolted foot plates on every cell boundary ──
	for i in range(n + 1):
		var x: float = -w * 0.5 + float(i) * CELL
		_build_post(x, h, pw, post_mat, post_trim, acc_c)
		# Foot plate (chamfered: a wider base course + the plate proper).
		add_child(_box(Vector3(x, FOOT_H * 0.35, 0), Vector3(FOOT_W + 0.04, FOOT_H * 0.7, FOOT_W + 0.04), foot_mat))
		add_child(_box(Vector3(x, FOOT_H + 0.012, 0), Vector3(FOOT_W, 0.024, FOOT_W), post_trim))
		if bolt_rows:
			var bz: float = FOOT_W * 0.5 - 0.045
			var by: float = FOOT_H + 0.026
			add_child(HangarKit.bolts(Vector3(x - FOOT_W * 0.5 + 0.045, by, bz), Vector3(x + FOOT_W * 0.5 - 0.045, by, bz), 2, 0.014, bolt_mat))
			add_child(HangarKit.bolts(Vector3(x - FOOT_W * 0.5 + 0.045, by, -bz), Vector3(x + FOOT_W * 0.5 - 0.045, by, -bz), 2, 0.014, bolt_mat))

	# ── Per-bay fill ──
	var pmat := HangarKit.finish_body(finish, body_c, local_wear)
	var seam_mat := HangarKit.worn_metal(body_c.darkened(0.1))
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		if style == "rail":
			_build_rail_bay(cx, h, pw, rail_mat, acc_c)
		else:
			_build_panel_bay(cx, h, pw, pmat, seam_mat, body_c, acc_c)

	# ── Continuous top rail capping the posts (panel runs read as one piece) ──
	if top_rail and style == "panel":
		var ty: float = h - RAIL_T * 0.5 - 0.06
		add_child(_box(Vector3(0, ty, 0), Vector3(w + pw * 0.5, RAIL_T, pw * 0.9), rail_mat))
		# A slim lit accent groove run along the front of the top rail.
		if cap_lights:
			add_child(_box(Vector3(0, ty, pw * 0.45 + 0.006), Vector3(w * 0.985, 0.012, 0.012), _emi(acc_c, 1.3)))
		# Bolt caps at each end of the rail.
		if bolt_rows:
			for s in [-1.0, 1.0]:
				add_child(HangarKit.bolts(Vector3(s * (w * 0.5 - 0.03), ty, pw * 0.45 + 0.004), Vector3(s * (w * 0.5 - 0.03), ty - 0.018, pw * 0.45 + 0.004), 2, 0.011, bolt_mat))

	# ── Caution kickplate (hazard-striped base course) ──
	if hazard_base and style == "panel":
		var kp := HangarKit.striped_mat(Color(0.95, 0.75, 0.05), HangarKit.DISPLAY_DARK if finish == "rams" else Color(0.08, 0.08, 0.10))
		add_child(_box(Vector3(0, 0.105, front_z + 0.006), Vector3(w * 0.985, 0.15, 0.02), kp))
		# Thin trim lip framing the kickplate top.
		add_child(_box(Vector3(0, 0.183, front_z + 0.008), Vector3(w * 0.985, 0.012, 0.022), post_trim))

	# ── Keep-clear chevrons across the mid panel ──
	if chevrons and style == "panel":
		_build_chevrons(w, h, front_z, acc_c)

	# ── Rams three-colour accent bar ──
	if three_bar and style == "panel":
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 1.0), 0.04, [acc_c, HangarKit.DISPLAY_DARK, body_c])
		bar.position = Vector3(0, h * 0.7, front_z + 0.02)
		add_child(bar)

	# ── Restrained wear: settle band + vertical dust streaks ──
	if grime:
		add_child(HangarKit.grime_band(w, 0.05, front_z + 0.004, body_c))
	if dust and style == "panel":
		var ds: Node3D = HangarKit.dust_streaks(w * 0.9, h * 0.55, front_z + 0.005, maxi(2, n))
		ds.position = Vector3(0, h * 0.5, 0)
		add_child(ds)

	# ── Surface-pinned 2D-in-3D brand plate (framed printed label) ──
	if brand_text.strip_edges() != "" and style == "panel":
		var pw_plate: float = minf(w * 0.55, 1.4)
		var plate: MeshInstance3D = BakedText.make_panel_mesh(brand_text.to_upper(), Color(0.10, 0.11, 0.13), Color(0.93, 0.91, 0.86), Vector2(pw_plate, 0.16), 1400, false)
		if plate:
			plate.position = Vector3(0, h * 0.5, front_z + 0.03)
			add_child(plate)
			# A thin worn-metal frame ring pinning the plate to the surface.
			var fr := post_trim
			var fz: float = front_z + 0.026
			var ft := 0.018
			add_child(_box(Vector3(0, h * 0.5 + 0.08 + ft * 0.5, fz), Vector3(pw_plate + ft * 2.0, ft, 0.012), fr))
			add_child(_box(Vector3(0, h * 0.5 - 0.08 - ft * 0.5, fz), Vector3(pw_plate + ft * 2.0, ft, 0.012), fr))
			add_child(_box(Vector3(-pw_plate * 0.5 - ft * 0.5, h * 0.5, fz), Vector3(ft, 0.16, 0.012), fr))
			add_child(_box(Vector3(pw_plate * 0.5 + ft * 0.5, h * 0.5, fz), Vector3(ft, 0.16, 0.012), fr))

func _build_post(x: float, h: float, pw: float, post_mat: Material, trim_mat: Material, acc_c: Color) -> void:
	if post_style == "bevelled":
		# Slim shaft + a wider chamfer collar near the base + a tapered cap block.
		var shaft_h: float = h - 0.06
		add_child(_box(Vector3(x, shaft_h * 0.5 + 0.02, 0), Vector3(pw, shaft_h, pw), post_mat))
		# Base collar (reads as a chamfer where the post meets the foot).
		add_child(_box(Vector3(x, 0.07, 0), Vector3(pw + 0.04, 0.05, pw + 0.04), trim_mat))
		# Recessed seam groove up the front of the shaft.
		add_child(_box(Vector3(x, shaft_h * 0.5 + 0.02, pw * 0.5 + 0.004), Vector3(pw * 0.3, shaft_h * 0.86, 0.008), trim_mat))
		# Tapered cap (narrower top block) + accent.
		add_child(_box(Vector3(x, h - 0.04, 0), Vector3(pw * 0.82, 0.05, pw * 0.82), trim_mat))
		if cap_lights:
			add_child(_box(Vector3(x, h - 0.005, 0), Vector3(pw + 0.03, 0.022, pw + 0.03), _emi(acc_c, 0.7)))
	else:
		add_child(_box(Vector3(x, h * 0.5, 0), Vector3(pw, h, pw), post_mat))
		if cap_lights:
			add_child(_box(Vector3(x, h - 0.03, 0), Vector3(pw + 0.03, 0.05, pw + 0.03), _emi(acc_c, 0.5)))

func _build_panel_bay(cx: float, h: float, pw: float, pmat: Material, seam_mat: Material, body_c: Color, acc_c: Color) -> void:
	var bay_w: float = CELL - pw
	var panel_h: float = h * 0.7
	var panel_cy: float = h * 0.46
	# Main panel slab (slightly recessed so the posts frame it).
	add_child(_box(Vector3(cx, panel_cy, 0), Vector3(bay_w, panel_h, PANEL_T), pmat))
	if panel_seams:
		# A framed inset face: a raised inner panel + a seam border. Negative
		# space framed on purpose — the bay reads as a deliberate field.
		var inset_w: float = bay_w * 0.82
		var inset_h: float = panel_h * 0.74
		var seam_t := 0.012
		add_child(_box(Vector3(cx, panel_cy, PANEL_T * 0.5 + 0.005), Vector3(inset_w, inset_h, 0.012), HangarKit.finish_body(finish, body_c.darkened(0.05), wear)))
		# Border frame (four thin bars proud of the slab).
		var fz: float = PANEL_T * 0.5 + 0.004
		add_child(_box(Vector3(cx, panel_cy + inset_h * 0.5 + seam_t * 0.5, fz), Vector3(inset_w + seam_t * 2.0, seam_t, 0.01), seam_mat))
		add_child(_box(Vector3(cx, panel_cy - inset_h * 0.5 - seam_t * 0.5, fz), Vector3(inset_w + seam_t * 2.0, seam_t, 0.01), seam_mat))
		add_child(_box(Vector3(cx - inset_w * 0.5 - seam_t * 0.5, panel_cy, fz), Vector3(seam_t, inset_h, 0.01), seam_mat))
		add_child(_box(Vector3(cx + inset_w * 0.5 + seam_t * 0.5, panel_cy, fz), Vector3(seam_t, inset_h, 0.01), seam_mat))

func _build_rail_bay(cx: float, h: float, pw: float, rail_mat: Material, acc_c: Color) -> void:
	var rc: int = clampi(rail_count, 1, 5)
	var bay_w: float = CELL - pw
	for j in range(rc):
		# Spread rails between ~0.32h and ~0.92h.
		var fy: float = lerpf(0.34, 0.9, 0.0 if rc <= 1 else float(j) / float(rc - 1))
		add_child(_box(Vector3(cx, h * fy, 0), Vector3(bay_w, RAIL_T, 0.04), rail_mat))
		# Slim lit accent groove on the topmost rail only.
		if cap_lights and j == rc - 1:
			add_child(_box(Vector3(cx, h * fy, 0.022), Vector3(bay_w * 0.92, 0.01, 0.01), _emi(acc_c, 1.1)))

func _build_chevrons(w: float, h: float, front_z: float, acc_c: Color) -> void:
	# A keep-clear chevron strip: short diagonal segments alternating direction,
	# painted as a thin band low on the run. Deterministic, restrained.
	var cy: float = h * 0.30
	var seg: float = 0.13
	var count: int = maxi(int(w / (seg * 1.4)), 3)
	var mat := _emi(acc_c, 0.45)
	for i in range(count):
		var t: float = (float(i) + 0.5) / float(count)
		var x: float = lerpf(-w * 0.46, w * 0.46, t)
		var dirn: float = 1.0 if (i % 2 == 0) else -1.0
		var c := _box(Vector3(x, cy, front_z + 0.012), Vector3(0.02, seg, 0.008), mat)
		c.rotation_degrees = Vector3(0, 0, dirn * 38.0)
		add_child(c)

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
