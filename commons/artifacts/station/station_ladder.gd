extends Node3D
class_name StationLadder

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the VERTICAL ACCESS rail of a serviced multi-level bay — two painted-metal stiles rise from a bolted floor shoe, joined by a regular array of round rungs, optionally caged by safety hoops from the climb-start up to the top, and capped by a caution-striped landing band where the climb meets the upper deck. The single universal "you can get up there" signal — no other family piece reads it. Origin at the floor centre between the stiles; 1 cell = 1 m, height set in whole cells.
# desire: to admit the room has a level above this one and to say, plainly, that a body is meant to reach it — to turn a blank wall or gantry leg into a route, so a multi-level station reads as inhabited and serviced rather than sealed.
# critical_parameter: height_cells + with_cage — how high the climb goes and whether it is a free wall ladder (open, light, short runs) or a caged fixed ladder (hooped, the OSHA-tall "this is real infrastructure" read). The composer matches height to the deck it serves.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new height / cage / spacing.
# emerges: a bare two-stile rung run reads "access, get up"; safety hoops read "tall, fixed, fall-rated — real plant"; a caution-stripe top band reads "the landing is here, mind the gap"; a standoff gap reads "wall-mounted, bolted off the surface"; warm-accent grooves up the stiles read "powered, lit route".
# needs: two vertical stiles with a bolted floor shoe [present]; a regular rung array [present]; a caution-stripe top landing band [present]; optional safety cage hoops + back straps [optional]; optional standoff brackets to a wall [optional]; optional climb-side signage / stencil [optional].
# relationships: the VERTICAL cousin of the horizontal [[station_gantry]] — where the gantry spans the air, the ladder climbs to it; stands against a [[station_wall]] run or a [[station_pillar]] the way a fixed ladder hugs a column; assembled into a multi-level bay by [[curation_station]]; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look with the rest of the station kit.
# truth: a ladder is the proof that a floor is not the only floor. To bolt rungs up a wall is to declare the space has an above — and that a person, not just a crane, is meant to go there. Access is the quietest claim that a place is used.

@export_group("Dimensions")
## Climb height in whole 1 m cells (Y). Clamped 1..8. The top rung lands near this height.
@export var height_cells: int = 3
## Clear gap between the two stiles (m) — the rung length / shoulder width.
@export var stile_gap: float = 0.46
## Square cross-section of each stile rail (m).
@export var stile_width: float = 0.05
## Round rung radius (m).
@export var rung_radius: float = 0.022

@export_group("Rungs")
## If true, rung count is derived from height / rung_spacing. If false, use rung_count.
@export var rung_count_auto: bool = true
## Centre-to-centre vertical spacing between rungs (m) when auto. Code/ladder standard ~0.30.
@export var rung_spacing: float = 0.30
## Explicit rung count when rung_count_auto = false.
@export var rung_count: int = 9

@export_group("Cage")
## Safety cage: arc hoops around the climb + vertical back straps.
@export var with_cage: bool = true
## Height (m) above the floor where the cage starts (a free run before the hoops begin).
@export var cage_start: float = 2.2
## Centre-to-centre vertical spacing between cage hoops (m).
@export var cage_hoop_spacing: float = 0.6
## Radius of each cage hoop arc (m) — how far the cage stands off the rungs.
@export var cage_radius: float = 0.36

@export_group("Mount")
## Standoff gap from the back of the stiles to the wall behind (m). 0 = flush. >0 adds wall brackets.
@export var standoff: float = 0.12
## A bolted floor shoe / kick plate at the base of the stiles.
@export var floor_shoe: bool = true

@export_group("Surface")
## A diagonal caution-stripe band at the top (the landing / mind-the-gap signal).
@export var caution_stripe: bool = true
## Lit warm-accent grooves running up the outer face of each stile.
@export var lit_grooves: bool = true
## Bolt detail on the floor shoe and wall brackets.
@export var bolts: bool = true
## Faint vertical dust streaks down the stiles.
@export var dust: bool = true
## "rams" (light Braun default) | "terminal" (dark charcoal console finish).
@export var finish: String = "rams"
## Painted stencil text low on the climb-side (e.g. an ID or "ACCESS"). Empty = none.
@export var stencil_text: String = ""
## Surface-pinned signage header near the top (bracketed plate). Empty = none.
@export var signage_text: String = ""
@export var wear: float = 0.12
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const SHOE_H := 0.10

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
	if has_meta("config_height_cells"): height_cells = int(str(get_meta("config_height_cells")))
	if has_meta("config_stile_gap"): stile_gap = float(str(get_meta("config_stile_gap")))
	if has_meta("config_stile_width"): stile_width = float(str(get_meta("config_stile_width")))
	if has_meta("config_rung_radius"): rung_radius = float(str(get_meta("config_rung_radius")))
	if has_meta("config_rung_count_auto"): rung_count_auto = _b(get_meta("config_rung_count_auto"))
	if has_meta("config_rung_spacing"): rung_spacing = float(str(get_meta("config_rung_spacing")))
	if has_meta("config_rung_count"): rung_count = int(str(get_meta("config_rung_count")))
	if has_meta("config_with_cage"): with_cage = _b(get_meta("config_with_cage"))
	if has_meta("config_cage_start"): cage_start = float(str(get_meta("config_cage_start")))
	if has_meta("config_cage_hoop_spacing"): cage_hoop_spacing = float(str(get_meta("config_cage_hoop_spacing")))
	if has_meta("config_cage_radius"): cage_radius = float(str(get_meta("config_cage_radius")))
	if has_meta("config_standoff"): standoff = float(str(get_meta("config_standoff")))
	if has_meta("config_floor_shoe"): floor_shoe = _b(get_meta("config_floor_shoe"))
	if has_meta("config_caution_stripe"): caution_stripe = _b(get_meta("config_caution_stripe"))
	if has_meta("config_lit_grooves"): lit_grooves = _b(get_meta("config_lit_grooves"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_signage_text"): signage_text = str(get_meta("config_signage_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var h: float = float(clampi(height_cells, 1, 8)) * CELL
	var gap: float = clampf(stile_gap, 0.28, 0.70)
	var sw: float = clampf(stile_width, 0.03, 0.10)
	var rr: float = clampf(rung_radius, 0.012, 0.04)

	# Finish drives the family palette; explicit colours still win in rams, terminal overrides them.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	var rung_mat: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.05))
	var dark_mat: StandardMaterial3D = HangarKit.worn_metal(pcol)

	var half: float = gap * 0.5            # stile centre on each side of X=0
	var back_z: float = -standoff           # stiles sit standoff behind the climb face (climb faces +Z)
	var stile_x: Array = [-half, half]

	# Vertical run of the stiles: from just above the shoe to the top.
	var stile_bottom: float = SHOE_H if floor_shoe else 0.0
	var stile_top: float = h
	var stile_h: float = maxf(stile_top - stile_bottom, 0.4)
	var stile_cy: float = stile_bottom + stile_h * 0.5

	# ── Floor shoe: a bolted kick plate the stiles stand on ──
	if floor_shoe:
		var shoe_w: float = gap + sw * 2.0 + 0.10
		add_child(_box(Vector3(0, SHOE_H * 0.5, back_z), Vector3(shoe_w, SHOE_H, sw * 2.6), dark_mat))
		add_child(_box(Vector3(0, SHOE_H * 0.5, back_z + sw * 0.9), Vector3(shoe_w * 0.86, SHOE_H * 0.7, 0.018), _body_mat(pcol, ewear)))
		if bolts:
			var bz: float = back_z + sw * 1.1
			add_child(HangarKit.bolts(Vector3(-shoe_w * 0.4, SHOE_H + 0.006, bz), Vector3(shoe_w * 0.4, SHOE_H + 0.006, bz), 2, 0.016, dark_mat))

	# ── Two stiles ──
	for sx in stile_x:
		add_child(_box(Vector3(float(sx), stile_cy, back_z), Vector3(sw, stile_h, sw), body_mat))
		# a thin trim cap top & bottom of each stile
		add_child(_box(Vector3(float(sx), stile_top - 0.02, back_z), Vector3(sw + 0.012, 0.04, sw + 0.012), dark_mat))
		# lit warm-accent groove up the OUTER face of each stile
		if lit_grooves:
			var outward: float = -1.0 if float(sx) < 0.0 else 1.0
			add_child(_box(Vector3(float(sx) + outward * (sw * 0.5 + 0.006), stile_cy, back_z),
				Vector3(0.012, stile_h * 0.82, sw * 0.5), HangarKit.emissive(acol, 0.7)))

	# ── Rung array ──
	var n_rungs: int = _rung_count(stile_h)
	# rungs span from the first step above the shoe to near the top, evenly.
	var rung_lo: float = stile_bottom + maxf(rung_spacing * 0.5, 0.18)
	var rung_hi: float = stile_top - 0.10
	var rung_span: float = maxf(rung_hi - rung_lo, 0.2)
	var rung_z: float = back_z + sw * 0.5 + rr * 0.4   # rungs sit slightly proud of the climb face
	for i in range(n_rungs):
		var t: float = 0.0 if n_rungs <= 1 else float(i) / float(n_rungs - 1)
		var ry: float = rung_lo + rung_span * t
		# the rung itself (a horizontal cylinder between the inner faces of the stiles)
		add_child(_pipe(Vector3(-half + sw * 0.4, ry, rung_z), Vector3(half - sw * 0.4, ry, rung_z), rr, rung_mat))
		# small end collars where the rung meets each stile (welded look)
		for sx in stile_x:
			var inward: float = 1.0 if float(sx) < 0.0 else -1.0
			add_child(_cyl_axis(Vector3(float(sx) + inward * sw * 0.4, ry, rung_z), rr * 1.5, sw * 0.4, dark_mat, true))

	# ── Safety cage: arc hoops + back straps ──
	if with_cage and h - cage_start > cage_hoop_spacing:
		_build_cage(h, gap, sw, back_z, rung_z, dark_mat, _body_mat(pcol, ewear))

	# ── Standoff wall brackets (stiles held off the wall behind) ──
	if standoff > 0.001:
		var bracket_zs: Array = [stile_bottom + stile_h * 0.32, stile_bottom + stile_h * 0.72]
		for sx in stile_x:
			for bz2 in bracket_zs:
				# a short arm from the stile back to the wall plane (z = 0 is the climb face; wall is behind stiles)
				var arm_a := Vector3(float(sx), float(bz2), back_z - sw * 0.5)
				var arm_b := Vector3(float(sx), float(bz2), back_z - standoff)
				add_child(_pipe(arm_a, arm_b, sw * 0.42, dark_mat))
				# wall plate
				add_child(_box(Vector3(float(sx), float(bz2), back_z - standoff), Vector3(sw * 2.0, sw * 2.4, 0.02), _body_mat(pcol, ewear)))
				if bolts:
					add_child(HangarKit.bolts(
						Vector3(float(sx) - sw * 0.6, float(bz2), back_z - standoff - 0.012),
						Vector3(float(sx) + sw * 0.6, float(bz2), back_z - standoff - 0.012), 2, 0.01, dark_mat))

	# ── Caution-stripe top landing band (across both stiles, the mind-the-gap signal) ──
	if caution_stripe:
		var smat: StandardMaterial3D = HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		var band_w: float = gap + sw * 2.0 + 0.06
		var band_y: float = stile_top - 0.12
		add_child(_box(Vector3(0, band_y, back_z + sw * 0.5 + 0.012), Vector3(band_w, 0.10, 0.014), smat))

	# ── Surface detail ──
	if dust:
		for sx in stile_x:
			var ds: Node3D = HangarKit.dust_streaks(sw * 1.4, stile_h * 0.5, back_z + sw * 0.5 + 0.01, 2)
			ds.position.x = float(sx)
			add_child(ds)
	if grime and floor_shoe:
		var g: MeshInstance3D = HangarKit.grime_band(gap + sw * 2.0, 0.05, back_z + sw * 1.3, bcol)
		add_child(g)

	# ── Painted stencil text low on the climb-side ──
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(gap * 0.9, 0.4), 0.10))
		if q:
			q.position = Vector3(0, stile_bottom + stile_h * 0.18, back_z + sw * 0.5 + 0.014)
			add_child(q)

	# ── Surface-pinned signage header near the top ──
	if signage_text.strip_edges() != "":
		var sign: Node3D = HangarKit.signage(signage_text, [], Vector2(minf(gap * 1.0, 0.42), 0.13), 0.05, Vector3(0, 0, 1))
		if sign:
			sign.position = Vector3(0, stile_top - 0.30, back_z + sw * 0.5 + 0.01)
			add_child(sign)


func _rung_count(stile_h: float) -> int:
	if rung_count_auto:
		var usable: float = maxf(stile_h - 0.28, 0.2)
		return clampi(int(round(usable / maxf(rung_spacing, 0.12))) + 1, 2, 64)
	return clampi(rung_count, 2, 64)


func _build_cage(h: float, gap: float, sw: float, back_z: float, climb_z: float, hoop_mat: Material, strap_mat: Material) -> void:
	var cr: float = clampf(cage_radius, 0.26, 0.55)
	# Hoop centre is out in front of the climb face by ~cr, so the arc wraps the climber.
	var hoop_cz: float = climb_z + 0.04
	var start_y: float = clampf(cage_start, 1.0, h - cage_hoop_spacing)
	var hoop_ys: Array = []
	var y: float = start_y
	while y <= h - 0.10:
		hoop_ys.append(y)
		y += maxf(cage_hoop_spacing, 0.3)
	if hoop_ys.is_empty():
		return
	# ── Arc hoops: a part-torus (front 3/4) around the climb ──
	for hy in hoop_ys:
		add_child(_arc_hoop(Vector3(0, float(hy), hoop_cz), cr, sw * 0.34, hoop_mat))
	# ── Vertical back straps tying the hoop fronts together (3 straps: centre + two sides) ──
	var strap_top: float = float(hoop_ys[hoop_ys.size() - 1])
	var strap_bot: float = float(hoop_ys[0])
	var strap_h: float = maxf(strap_top - strap_bot, 0.2)
	var strap_cy: float = (strap_top + strap_bot) * 0.5
	var ang_set: Array = [-0.62, 0.0, 0.62]   # radians around the front of the hoop
	for a in ang_set:
		var px: float = sin(float(a)) * cr
		var pz: float = hoop_cz + cos(float(a)) * cr
		add_child(_box(Vector3(px, strap_cy, pz), Vector3(0.022, strap_h, 0.022), strap_mat))


# A 3/4 arc hoop (open at the back toward the wall) built from short box segments.
func _arc_hoop(center: Vector3, radius: float, thickness: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "CageHoop"
	var segs: int = 18
	var a0: float = -2.36   # ~ -135 deg
	var a1: float = 2.36    # ~ +135 deg  (open 90deg wedge at the back)
	for i in range(segs):
		var t0: float = float(i) / float(segs)
		var t1: float = float(i + 1) / float(segs)
		var aa: float = lerpf(a0, a1, t0)
		var ab: float = lerpf(a0, a1, t1)
		var pa := center + Vector3(sin(aa) * radius, 0, cos(aa) * radius)
		var pb := center + Vector3(sin(ab) * radius, 0, cos(ab) * radius)
		root.add_child(_seg(pa, pb, thickness, mat))
	return root


# A short box segment between two points (used for arc tessellation).
func _seg(a: Vector3, b: Vector3, t: float, mat: Material) -> MeshInstance3D:
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


# ── helpers ──
func _body_mat(c: Color, w: float) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, w)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


# A cylinder between two points (a rung), radius r.
func _pipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


# A short cylinder collar; if x_axis, lay it along X (a rung end cap), else upright.
func _cyl_axis(center: Vector3, radius: float, height_y: float, mat: Material, x_axis: bool) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_y
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	if x_axis:
		mi.rotation_degrees = Vector3(0, 0, 90)
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
