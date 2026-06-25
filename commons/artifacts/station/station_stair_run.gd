extends Node3D
class_name StationStairRun

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the GRID-MODULAR stair that dresses a height change between bays — a painted-metal flight that climbs rise_cells metres over a run, treads carried on panelled (closed) or open stringers, a caution-striped nosing on every step, a reused station_barrier-style handrail on one or both sides, a bolted foot plate at the bottom and a flush landing lip at the top. The grid does the heights; this gives the cliff a way up. Origin at the floor centre of the BOTTOM step, climbing toward +Z and rising in +Y; 1 cell = 1 m.
# desire: to refuse the cliff — to take a bare level change (a void edge, a stacked floor, a stage lip) and make it walkable and read as built, so a multi-bay layout flows as one continuous space instead of a stack of disconnected platforms. To do it in the Dieter-Rams family hand: a light body that recedes, one warm accent on the nosings and rail groove, hazard stripes worn just enough to read as real plant.
# critical_parameter: rise_cells + width_cells — how tall the climb is (step_count derives from rise so every step lands near a comfortable 0.18 m) and how wide the flight reads (a single-file service stair vs. a generous public run); stringer_style flips the side from a solid panelled cheek (contained, lab) to an open zig-zag (light, gallery), and with_handrail picks which edges get the guard.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new rise / width / style / rail side.
# emerges: a panelled stringer reads "contained, finished, lab"; an open stringer reads "light service stair, you can see through it"; striped nosings read "mind the step, this is plant"; a both-sides rail reads "public, safe, generous"; a single rail reads "service, hug the wall"; a tall rise reads "this connects two real floors", a short one "a stage step".
# needs: treads on every step + a stringer cheek on each side [present]; a bolted foot plate at the base + a landing lip at the top [present]; a caution-striped nosing per tread [present]; a station_barrier-style handrail (posts + top rail + lit groove) on the chosen side(s) [present]; an optional Rams accent bar + stencil/signage on the outer cheek [optional].
# relationships: the vertical-circulation sibling of [[station_wall]] (it dresses the SECTION the wall dresses in plan); reuses the [[station_barrier]] post+rail+groove grammar as its guard; lands a player onto a [[station_stage]] or a stacked bay; placed across a height seam by [[curation_station]]; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look with the whole station kit.
# truth: a stair is the proof that two heights are one place. Where the grid only stacks floors, the stair admits a body between them — and how it meets each level (bolted at the foot, flush at the landing, striped on every nosing) is the proof the transition was meant, not left as a cliff.

@export_group("Rise")
## Total height climbed in 1 m cells (Y). Clamped 0.5..6. step_count derives from this.
@export var rise_cells: float = 2.0
## Number of steps. 0 = AUTO (derived from rise so each step is ~0.18 m). Clamped 1..40 when set.
@export var step_count: int = 0
## Horizontal depth (going) of each tread in metres. The run length = step_count * going.
@export var going: float = 0.30

@export_group("Width")
## Flight width in 1 m cells (X). Clamped 1..6. 1 = single-file service, 3+ = a generous public run.
@export var width_cells: float = 1.0

@export_group("Style")
## "panelled" (solid closed stringer cheeks, lab) | "open" (zig-zag open stringers, gallery).
@export var stringer_style: String = "panelled"
## Which sides get a guard rail: "both" | "left" | "right" | "none".
@export var with_handrail: String = "both"
## Family finish — "rams" (light Braun default) | "terminal" (dark console).
@export var finish: String = "rams"

@export_group("Surface")
## Caution-striped nosing strip on the front lip of every tread.
@export var striped_nosing: bool = true
## A bolted foot plate where the flight meets the lower floor.
@export var foot_plate: bool = true
## A flush landing lip slab at the top, level with the upper floor.
@export var landing_lip: bool = true
## A Dieter-Rams three-colour accent bar on the outer stringer cheek.
@export var three_bar: bool = true
## Bolt rows on the stringer + foot plate + rail posts.
@export var bolts: bool = true
## Lit accent groove along each handrail top rail.
@export var rail_lights: bool = true
## Faint settle/grime band along the stringer base.
@export var grime: bool = true
## Stencil text painted on the outer stringer cheek (panelled only). Empty = none.
@export var stencil_text: String = ""
## Surface-pinned 2D-in-3D signage line on the outer cheek (panelled only). Empty = none.
@export var signage_text: String = ""
@export var wear: float = 0.08

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const TREAD_T := 0.05        # tread slab thickness
const STRINGER_T := 0.06     # open-stringer cheek thickness
const FOOT_H := 0.05         # foot plate thickness
const RAIL_H := 1.0          # guard height above the nosing line
const POST_W := 0.07         # rail post cross-section
const RAIL_T := 0.045        # rail bar thickness
const COMFORT_RISE := 0.18   # target per-step rise for AUTO step_count

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
	if has_meta("config_rise_cells"): rise_cells = float(str(get_meta("config_rise_cells")))
	if has_meta("config_step_count"): step_count = int(str(get_meta("config_step_count")))
	if has_meta("config_going"): going = float(str(get_meta("config_going")))
	if has_meta("config_width_cells"): width_cells = float(str(get_meta("config_width_cells")))
	if has_meta("config_stringer_style"): stringer_style = str(get_meta("config_stringer_style")).to_lower()
	if has_meta("config_with_handrail"): with_handrail = str(get_meta("config_with_handrail")).to_lower()
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_striped_nosing"): striped_nosing = _b(get_meta("config_striped_nosing"))
	if has_meta("config_foot_plate"): foot_plate = _b(get_meta("config_foot_plate"))
	if has_meta("config_landing_lip"): landing_lip = _b(get_meta("config_landing_lip"))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_rail_lights"): rail_lights = _b(get_meta("config_rail_lights"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_signage_text"): signage_text = str(get_meta("config_signage_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true

	# Finish recolours the whole family in one move (rams / terminal).
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else Color(pal["body"])
	var pcol: Color = panel_color if not is_terminal else Color(pal["panel"])
	var acol: Color = accent_color if not is_terminal else Color(pal["accent"])
	var ewear: float = wear if not is_terminal else maxf(wear, float(pal["wear"]))

	# ── Derive geometry from the genes ──
	var rise: float = clampf(rise_cells, 0.5, 6.0) * CELL
	var n: int = step_count
	if n <= 0:
		n = clampi(int(round(rise / COMFORT_RISE)), 1, 40)
	else:
		n = clampi(n, 1, 40)
	var step_rise: float = rise / float(n)
	var go: float = clampf(going, 0.18, 0.5)
	var run_len: float = float(n) * go
	var width: float = clampf(width_cells, 1.0, 6.0) * CELL
	var open_stringer: bool = stringer_style == "open"

	# ── Materials ──
	var body_mat := HangarKit.finish_body(finish, bcol, ewear)
	var tread_mat := HangarKit.finish_body(finish, bcol.lightened(0.02), ewear)
	var cheek_mat := HangarKit.finish_body(finish, pcol, ewear)
	var trim_mat := HangarKit.worn_metal(pcol)
	var dark_mat := HangarKit.worn_metal(pcol.darkened(0.12))
	var foot_mat := HangarKit.worn_metal(pcol.darkened(0.05))

	var half_w: float = width * 0.5
	var left_x: float = -half_w
	var right_x: float = half_w

	# ── Treads: one slab per step, climbing in +Z and rising in +Y ──
	# Step i (0..n-1): nosing at z0 = i*go, top surface at y = (i+1)*step_rise.
	for i in range(n):
		var z0: float = float(i) * go
		var top_y: float = float(i + 1) * step_rise
		var tread_cz: float = z0 + go * 0.5
		var tread_cy: float = top_y - TREAD_T * 0.5
		add_child(_box(Vector3(0, tread_cy, tread_cz), Vector3(width - STRINGER_T * 0.5, TREAD_T, go + 0.02), tread_mat))
		# A thin recessed face groove under the nosing (reads as a built tread edge).
		add_child(_box(Vector3(0, top_y - TREAD_T - 0.012, z0 + 0.006), Vector3(width * 0.92, 0.02, 0.006), trim_mat))

		# Caution-striped nosing strip on the front lip of the tread.
		if striped_nosing:
			var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5),
				HangarKit.DISPLAY_DARK if not is_terminal else Color(0.08, 0.08, 0.10))
			add_child(_box(Vector3(0, top_y - 0.012, z0 - 0.004), Vector3(width * 0.9, 0.024, 0.012), smat))

	# ── Stringers: a cheek on each side carrying the treads ──
	for side in [-1.0, 1.0]:
		var sx: float = side * (half_w - STRINGER_T * 0.5)
		if open_stringer:
			_build_open_stringer(sx, n, go, step_rise, cheek_mat, dark_mat)
		else:
			_build_panelled_stringer(sx, n, go, step_rise, rise, run_len, cheek_mat, trim_mat, pcol, ewear)

	# ── Bolted foot plate at the base (lower floor) ──
	if foot_plate:
		add_child(_box(Vector3(0, FOOT_H * 0.5, -0.02), Vector3(width + 0.10, FOOT_H, go * 0.9 + 0.10), foot_mat))
		add_child(_box(Vector3(0, FOOT_H + 0.012, -0.02), Vector3(width + 0.02, 0.022, go * 0.9), trim_mat))
		if bolts:
			var bz: float = -0.02
			add_child(HangarKit.bolts(Vector3(left_x + 0.06, FOOT_H + 0.026, bz + 0.18), Vector3(right_x - 0.06, FOOT_H + 0.026, bz + 0.18), maxi(2, int(width) + 1), 0.014, dark_mat))
			add_child(HangarKit.bolts(Vector3(left_x + 0.06, FOOT_H + 0.026, bz - 0.18), Vector3(right_x - 0.06, FOOT_H + 0.026, bz - 0.18), maxi(2, int(width) + 1), 0.014, dark_mat))

	# ── Flush landing lip at the top (level with the upper floor) ──
	if landing_lip:
		var lip_z: float = run_len + go * 0.45
		add_child(_box(Vector3(0, rise - TREAD_T * 0.5, lip_z), Vector3(width - STRINGER_T * 0.5, TREAD_T, go * 0.9 + 0.06), tread_mat))
		# A slim trim nose framing the landing edge.
		add_child(_box(Vector3(0, rise - 0.014, run_len + 0.004), Vector3(width * 0.92, 0.022, 0.01), trim_mat))
		if striped_nosing:
			var lsmat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5),
				HangarKit.DISPLAY_DARK if not is_terminal else Color(0.08, 0.08, 0.10))
			add_child(_box(Vector3(0, rise - 0.012, run_len - 0.004), Vector3(width * 0.9, 0.024, 0.012), lsmat))

	# ── Handrails (reused station_barrier post + rail + lit-groove grammar) ──
	var want_left: bool = with_handrail in ["both", "left"]
	var want_right: bool = with_handrail in ["both", "right"]
	if want_left:
		_build_handrail(left_x + POST_W * 0.5, n, go, step_rise, rise, run_len, cheek_mat, dark_mat, acol)
	if want_right:
		_build_handrail(right_x - POST_W * 0.5, n, go, step_rise, rise, run_len, cheek_mat, dark_mat, acol)

	# ── Outer-cheek dressing (panelled only): three-bar, stencil, signage, grime ──
	var outer_x: float = right_x - STRINGER_T * 0.5
	var outer_z: float = run_len * 0.42
	var outer_y: float = rise * 0.42
	if not open_stringer:
		if three_bar:
			var bar: Node3D = HangarKit.three_color_bar(minf(run_len * 0.4, 0.9), 0.034, [acol, HangarKit.DISPLAY_DARK, bcol])
			bar.rotation_degrees = Vector3(0, 90, 0)   # face +X (outer cheek)
			bar.position = Vector3(outer_x + STRINGER_T * 0.5 + 0.012, outer_y + 0.18, outer_z)
			add_child(bar)
		if stencil_text.strip_edges() != "":
			var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(run_len * 0.5, 1.0), 0.12))
			if q:
				q.rotation_degrees = Vector3(0, 90, 0)
				q.position = Vector3(outer_x + STRINGER_T * 0.5 + 0.014, outer_y, outer_z)
				add_child(q)
		if signage_text.strip_edges() != "":
			var sign: Node3D = HangarKit.signage(signage_text, [], Vector2(minf(run_len * 0.4, 0.8), 0.16), 0.05, Vector3(1, 0, 0))
			if sign:
				sign.position = Vector3(outer_x + STRINGER_T * 0.5 + 0.01, rise * 0.6, outer_z)
				add_child(sign)

	# ── Restrained wear: a settle band along the stringer base ──
	if grime:
		for side in [-1.0, 1.0]:
			var g: MeshInstance3D = HangarKit.grime_band(run_len * 0.9, 0.05, 0.0, bcol)
			g.rotation_degrees = Vector3(0, 90, 0)
			g.position = Vector3(side * (half_w - STRINGER_T * 0.5 + 0.006), 0.0, run_len * 0.45)
			add_child(g)


# ── Panelled (closed) stringer: a solid sloped cheek panel under the treads, with a seam groove
# and a bolted top rail edge. Reads "contained, finished, lab".
func _build_panelled_stringer(sx: float, n: int, go: float, step_rise: float, rise: float, run_len: float,
		cheek_mat: Material, trim_mat: Material, pcol: Color, ewear: float) -> void:
	# A single quad-ish slab spanning the diagonal, built as a thin sloped box.
	var a := Vector3(sx, 0.0, -go * 0.2)
	var b := Vector3(sx, rise, run_len)
	var diag_len: float = a.distance_to(b)
	var slab_h: float = step_rise * 1.6 + 0.18    # tall enough to sit under the treads
	# Centre of the diagonal slab.
	var mid: Vector3 = (a + b) * 0.5 - Vector3(0, slab_h * 0.32, 0)
	add_child(_sloped_box(sx, mid, diag_len + go, slab_h, STRINGER_T, run_len, rise, cheek_mat))
	# A recessed seam groove running parallel along the cheek face (outer side).
	var groove_mat := HangarKit.finish_body(finish, pcol.darkened(0.06), ewear)
	add_child(_sloped_box(sx + sign_f(sx) * (STRINGER_T * 0.5 + 0.004), mid + Vector3(0, slab_h * 0.10, 0), diag_len, slab_h * 0.34, 0.01, run_len, rise, groove_mat))
	# A bolted edge plate at the bottom of the cheek.
	if bolts:
		var bm := HangarKit.worn_metal(pcol.darkened(0.2))
		add_child(HangarKit.bolts(Vector3(sx + sign_f(sx) * (STRINGER_T * 0.5 + 0.01), 0.12, 0.04), Vector3(sx + sign_f(sx) * (STRINGER_T * 0.5 + 0.01), 0.12, run_len * 0.4), 3, 0.013, bm))


# ── Open (zig-zag) stringer: a slim sawtooth carriage — a short riser block under each step's nosing
# plus a thin diagonal spine. Reads "light service stair, you can see through it".
func _build_open_stringer(sx: float, n: int, go: float, step_rise: float, cheek_mat: Material, dark_mat: Material) -> void:
	var run_len: float = float(n) * go
	var rise: float = float(n) * step_rise
	# Thin diagonal spine running the full flight.
	var a := Vector3(sx, step_rise * 0.5, -go * 0.1)
	var b := Vector3(sx, rise - step_rise * 0.4, run_len)
	add_child(_strut(a, b, STRINGER_T, cheek_mat))
	# Sawtooth riser blocks: one short vertical block under each tread nosing.
	for i in range(n):
		var z0: float = float(i) * go
		var top_y: float = float(i + 1) * step_rise
		var blk_h: float = step_rise + 0.04
		add_child(_box(Vector3(sx, top_y - blk_h * 0.5, z0 + go * 0.12), Vector3(STRINGER_T * 0.9, blk_h, STRINGER_T * 1.4), dark_mat))


# ── Handrail: reuse the station_barrier grammar — bevelled posts climbing the flight, a continuous
# sloped top rail, a lit accent groove, bolted post bases.
func _build_handrail(rx: float, n: int, go: float, step_rise: float, rise: float, run_len: float,
		post_mat: Material, dark_mat: Material, acol: Color) -> void:
	# Post positions: one near the foot, one near the top, and intermediates every ~3 steps.
	var post_steps: Array = []
	var stride: int = maxi(int(round(float(n) / 3.0)), 1)
	var s: int = 0
	while s <= n:
		post_steps.append(s)
		s += stride
	if post_steps[post_steps.size() - 1] != n:
		post_steps.append(n)

	var rail_top_off: float = RAIL_H    # rail height above each nosing
	for ps in post_steps:
		var z0: float = float(ps) * go
		var base_y: float = float(ps) * step_rise    # the nosing line at this post
		var post_h: float = rail_top_off
		# Bevelled post: slim shaft + base collar + tapered cap (station_barrier post grammar).
		add_child(_box(Vector3(rx, base_y + post_h * 0.5, z0), Vector3(POST_W, post_h, POST_W), post_mat))
		add_child(_box(Vector3(rx, base_y + 0.05, z0), Vector3(POST_W + 0.035, 0.045, POST_W + 0.035), dark_mat))
		add_child(_box(Vector3(rx, base_y + post_h - 0.035, z0), Vector3(POST_W * 0.84, 0.045, POST_W * 0.84), dark_mat))
		if bolts:
			add_child(HangarKit.bolts(Vector3(rx - POST_W * 0.4, base_y + 0.03, z0 + POST_W * 0.5 + 0.006), Vector3(rx + POST_W * 0.4, base_y + 0.03, z0 + POST_W * 0.5 + 0.006), 2, 0.011, dark_mat))

	# Continuous sloped top rail from the first post to the last (follows the flight angle).
	var first_z: float = float(post_steps[0]) * go
	var first_y: float = float(post_steps[0]) * step_rise + rail_top_off
	var last_z: float = float(post_steps[post_steps.size() - 1]) * go
	var last_y: float = float(post_steps[post_steps.size() - 1]) * step_rise + rail_top_off
	var ra := Vector3(rx, first_y, first_z)
	var rb := Vector3(rx, last_y, last_z)
	add_child(_strut(ra, rb, RAIL_T, post_mat))
	# A lit accent groove run along the top of the rail.
	if rail_lights:
		var lit := HangarKit.emissive(acol, 1.2)
		add_child(_strut(ra + Vector3(0, RAIL_T * 0.5 + 0.006, 0), rb + Vector3(0, RAIL_T * 0.5 + 0.006, 0), 0.012, lit))
	# A mid (knee) rail parallel below the top rail.
	var mid_off: float = rail_top_off * 0.5
	var ma := Vector3(rx, float(post_steps[0]) * step_rise + mid_off, first_z)
	var mb := Vector3(rx, float(post_steps[post_steps.size() - 1]) * step_rise + mid_off, last_z)
	add_child(_strut(ma, mb, RAIL_T * 0.8, post_mat))


# ── helpers ──

func sign_f(v: float) -> float:
	return 1.0 if v >= 0.0 else -1.0


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


# A thin box of given (length, height, thickness) tilted to span a diagonal in the Y/Z plane at fixed X.
# length/height/thickness map to the box's local size; the box is rotated so its length axis points
# from (0,0) toward (run_len, rise) in the Z/Y plane.
func _sloped_box(x: float, center: Vector3, length: float, height_local: float, thickness: float, run_len: float, rise: float, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, height_local, length)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var angle: float = atan2(rise, maxf(run_len, 0.001))   # pitch of the flight
	mi.position = center
	mi.position.x = x
	mi.rotation = Vector3(-angle, 0.0, 0.0)
	return mi


# A box stretched/rotated between two points (a strut/rail), square cross-section `t`.
func _strut(a: Vector3, b: Vector3, t: float, mat: Material) -> MeshInstance3D:
	var ln: float = maxf(a.distance_to(b), 0.001)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(t, t, ln)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var zv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(zv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(zv).normalized()
	var yv: Vector3 = zv.cross(xv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
