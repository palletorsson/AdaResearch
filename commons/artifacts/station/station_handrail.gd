extends Node3D
class_name StationHandrail

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the EDGE-FALL GUARDRAIL of a raised stage / gantry mezzanine / grate pit — a length_cells × 1 m run of slim painted-metal stanchions bolted along the open edge, carrying a continuous round-section TOP RAIL at hand height (~1.1 m), an optional mid-rail, and an optional caution-striped KICKPLATE / toe-board at the floor. It is the thing you grab so you do not go over. Bolted base flanges pin it to the deck edge; a slim lit accent groove runs the top rail; surface-pinned brand text. Origin at the floor centre of the run; the protected drop is at -Z (rail faces -Z, the fall), the safe deck at +Z.
# desire: to make a raised edge safe to stand at — to turn a sheer drop into something you can walk up to, lean on, and be held by, the way a mezzanine rail or a catwalk handrail says "the deck ends here, but you are caught". To do it in the Dieter-Rams family hand: a light body that recedes, ONE warm accent, caution stripes worn just enough to read as real plant.
# critical_parameter: length_cells + height + with_kickplate — how long the protected edge is, how tall the catch sits (waist vs chest), and whether a toe-board seals the floor gap (grate pit / tool-drop) or the run reads as an open mezzanine rail.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new length / height / fit-out.
# emerges: a bare top rail on slim posts reads "mezzanine, look over the edge"; a mid-rail + kickplate reads "industrial fall-protection, regulation"; heavy posts + chevrons reads "plant, mind the drop"; terminal finish reads "dark catwalk"; a long run with brand text reads "perimeter of a serviced deck".
# needs: stanchion posts on each cell boundary with bolted base flanges [present]; a continuous round top rail at hand height [present]; optional mid-rail [optional]; optional caution kickplate / toe-board [optional]; optional keep-clear chevrons [optional]; optional 2D-in-3D brand plate [optional].
# relationships: the EDGE-MOUNT sibling of [[station_barrier]] (a barrier is a front-of-bay CORDON across the stage; a handrail is the fall-protection along the open edge) — shares its post/rail/kickplate part vocabulary; guards the lip of [[station_stage]] and the deck of [[station_gantry]]'s mezzanine; placed along open edges by [[curation_station]]; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look.
# truth: a handrail is the promise the floor makes at its own edge: come stand where it ends, you will be held. The cheapest architecture of care — one rail at hand height — is what lets a body lean into the drop and look.

@export_group("Grid")
## Length of the guarded edge in 1 m cells (X). A post lands on every cell boundary.
@export var length_cells: int = 4

@export_group("Dimensions")
## Height of the top rail above the deck (m). ~1.1 = code handrail; lower = waist mezzanine.
@export var height: float = 1.1
## Spacing between stanchion posts in metres. The run snaps post count to fit the length.
@export var post_spacing: float = 1.0
## Stanchion cross-section width (square). Slim = mezzanine, chunky = heavy plant.
@export var post_w: float = 0.07
## Radius of the round top / mid rail tube.
@export var rail_r: float = 0.028

@export_group("Fit-out")
## A horizontal mid-rail at ~half height (the second bar of fall-protection).
@export var with_midrail: bool = true
## A caution-striped kickplate / toe-board sealing the floor gap (grate pit / tool drop).
@export var with_kickplate: bool = true
## Keep-clear chevron strip painted low on the deck face (reads "official, mind the drop").
@export var with_chevrons: bool = false
## "rams" (light Braun default) | "terminal" (dark charcoal catwalk finish).
@export var finish: String = "rams"
## Post form — "bevelled" (chamfer collar + tapered cap) | "box" (plain stanchion).
@export var post_style: String = "bevelled"

@export_group("Surface")
## A Dieter-Rams three-colour accent bar near one end of the top rail.
@export var three_bar: bool = true
## Bolt rows on the base flanges + rail-end caps.
@export var bolt_rows: bool = true
## A slim lit accent groove run along the front of the top rail.
@export var cap_lights: bool = true
## Faint settle band + restrained grime along the base.
@export var grime: bool = true
## 2D-in-3D brand text along the deck side of the run (empty = none).
@export var brand_text: String = ""
@export var wear: float = 0.09

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var post_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const FLANGE_W := 0.16
const FLANGE_H := 0.028
const KICK_H := 0.14

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
	if has_meta("config_post_spacing"): post_spacing = float(str(get_meta("config_post_spacing")))
	if has_meta("config_post_w"): post_w = float(str(get_meta("config_post_w")))
	if has_meta("config_rail_r"): rail_r = float(str(get_meta("config_rail_r")))
	if has_meta("config_with_midrail"): with_midrail = _b(get_meta("config_with_midrail"))
	if has_meta("config_with_kickplate"): with_kickplate = _b(get_meta("config_with_kickplate"))
	if has_meta("config_with_chevrons"): with_chevrons = _b(get_meta("config_with_chevrons"))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_post_style"): post_style = str(get_meta("config_post_style")).to_lower()
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_bolt_rows"): bolt_rows = _b(get_meta("config_bolt_rows"))
	if has_meta("config_cap_lights"): cap_lights = _b(get_meta("config_cap_lights"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_brand_text"): brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_post_color"): post_color = _pc(str(get_meta("config_post_color")), post_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	# Finish recolours the whole family in one move (rams / terminal).
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var body_c: Color = body_color if not is_terminal else Color(pal["body"])
	var post_c: Color = post_color if not is_terminal else Color(pal["panel"])
	var acc_c: Color = accent_color if not is_terminal else Color(pal["accent"])
	var local_wear: float = wear if not is_terminal else maxf(wear, float(pal["wear"]))

	var n: int = maxi(length_cells, 1)
	var w: float = float(n) * CELL
	var h: float = clampf(height, 0.6, 1.6)
	var pw: float = clampf(post_w, 0.04, 0.2)
	var rr: float = clampf(rail_r, 0.018, 0.06)
	# The rail line sits on the -Z (drop) side of the post centres, the deck is +Z.
	var rail_z: float = 0.0

	var post_mat := HangarKit.finish_body(finish, post_c.darkened(0.04), local_wear)
	var post_trim := HangarKit.worn_metal(post_c)
	var flange_mat := HangarKit.worn_metal(post_c.darkened(0.05))
	var bolt_mat := HangarKit.worn_metal(post_c.darkened(0.18))
	var rail_mat := HangarKit.finish_body(finish, body_c.lightened(0.02), local_wear)

	# ── Stanchion posts: snap a post count to the run from post_spacing, always endpoints ──
	var spacing: float = clampf(post_spacing, 0.5, 2.0)
	var bays: int = maxi(int(round(w / spacing)), 1)
	var post_count: int = bays + 1
	for i in range(post_count):
		var x: float = -w * 0.5 + w * (float(i) / float(bays))
		_build_post(x, h, pw, rail_z, post_mat, post_trim, acc_c, rr)
		# Bolted base flange pinning the stanchion to the deck edge.
		add_child(_box(Vector3(x, FLANGE_H * 0.35, rail_z), Vector3(FLANGE_W + 0.03, FLANGE_H * 0.7, FLANGE_W + 0.03), flange_mat))
		add_child(_box(Vector3(x, FLANGE_H + 0.01, rail_z), Vector3(FLANGE_W, 0.02, FLANGE_W), post_trim))
		if bolt_rows:
			var bo: float = FLANGE_W * 0.5 - 0.03
			var by: float = FLANGE_H + 0.022
			add_child(HangarKit.bolts(Vector3(x - bo, by, rail_z - bo), Vector3(x + bo, by, rail_z - bo), 2, 0.012, bolt_mat))
			add_child(HangarKit.bolts(Vector3(x - bo, by, rail_z + bo), Vector3(x + bo, by, rail_z + bo), 2, 0.012, bolt_mat))

	# ── Continuous round TOP RAIL at hand height, running the full length ──
	var top_y: float = h - rr
	add_child(_railx(-w * 0.5 - pw * 0.5, w * 0.5 + pw * 0.5, top_y, rail_z, rr, rail_mat))
	# Rounded end returns (the rail bends down into a short stub at each end — no sharp open ends).
	for s in [-1.0, 1.0]:
		var ex: float = s * (w * 0.5 + pw * 0.5)
		add_child(_pipe(Vector3(ex, top_y, rail_z), Vector3(ex, top_y - minf(0.22, h * 0.28), rail_z), rr, rail_mat))
		if bolt_rows:
			add_child(HangarKit.bolts(Vector3(ex, top_y - 0.04, rail_z + rr + 0.01), Vector3(ex, top_y - 0.12, rail_z + rr + 0.01), 2, 0.011, bolt_mat))
	# Slim lit accent groove along the deck-facing front of the top rail.
	if cap_lights:
		add_child(_box(Vector3(0, top_y, rail_z + rr + 0.006), Vector3(w * 0.99, 0.012, 0.012), _emi(acc_c, 1.2)))

	# ── Mid-rail (second bar of fall-protection) ──
	if with_midrail:
		var mid_y: float = h * 0.52
		add_child(_railx(-w * 0.5, w * 0.5, mid_y, rail_z, rr * 0.86, rail_mat))

	# ── Caution kickplate / toe-board sealing the floor gap ──
	if with_kickplate:
		var kp := HangarKit.striped_mat(Color(0.95, 0.75, 0.05), HangarKit.DISPLAY_DARK if not is_terminal else Color(0.08, 0.08, 0.10))
		add_child(_box(Vector3(0, KICK_H * 0.5 + 0.01, rail_z - rr - 0.01), Vector3(w * 0.99, KICK_H, 0.022), kp))
		# Thin worn-metal lip framing the top of the kickplate.
		add_child(_box(Vector3(0, KICK_H + 0.018, rail_z - rr - 0.012), Vector3(w * 0.99, 0.012, 0.026), post_trim))

	# ── Keep-clear chevrons painted low on the deck face ──
	if with_chevrons:
		_build_chevrons(w, h, rail_z + rr + 0.008, acc_c)

	# ── Rams three-colour accent bar near one end of the top rail ──
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.4, 0.8), 0.03, [acc_c, HangarKit.DISPLAY_DARK, body_c])
		bar.position = Vector3(w * 0.5 - minf(w * 0.25, 0.55), top_y - rr - 0.08, rail_z + rr + 0.012)
		add_child(bar)

	# ── Restrained settle band along the base ──
	if grime:
		var g := HangarKit.grime_band(w, 0.05, rail_z + rr + 0.004, body_c)
		add_child(g)

	# ── Surface-pinned 2D-in-3D brand plate, hung on the deck side of the run ──
	if brand_text.strip_edges() != "":
		var plate_w: float = minf(w * 0.45, 1.2)
		var plate: MeshInstance3D = BakedText.make_panel_mesh(brand_text.to_upper(), Color(0.10, 0.11, 0.13), Color(0.93, 0.91, 0.86), Vector2(plate_w, 0.14), 1400, false)
		if plate:
			var py: float = h * 0.5
			plate.position = Vector3(-w * 0.5 + minf(w * 0.32, 0.85), py, rail_z + rr + 0.02)
			plate.rotation_degrees = Vector3(0, 180, 0)   # face the deck (+Z viewer reads it)
			add_child(plate)
			# A thin worn-metal frame ring pinning the plate.
			var fz: float = rail_z + rr + 0.016
			var ft := 0.014
			add_child(_box(Vector3(plate.position.x, py + 0.07 + ft * 0.5, fz), Vector3(plate_w + ft * 2.0, ft, 0.01), post_trim))
			add_child(_box(Vector3(plate.position.x, py - 0.07 - ft * 0.5, fz), Vector3(plate_w + ft * 2.0, ft, 0.01), post_trim))


func _build_post(x: float, h: float, pw: float, rz: float, post_mat: Material, trim_mat: Material, acc_c: Color, rr: float) -> void:
	if post_style == "bevelled":
		var shaft_h: float = h - 0.05
		add_child(_box(Vector3(x, shaft_h * 0.5 + FLANGE_H, rz), Vector3(pw, shaft_h, pw), post_mat))
		# Base collar (chamfer read where the stanchion meets the flange).
		add_child(_box(Vector3(x, FLANGE_H + 0.045, rz), Vector3(pw + 0.03, 0.045, pw + 0.03), trim_mat))
		# Recessed seam groove up the deck face of the shaft.
		add_child(_box(Vector3(x, shaft_h * 0.5 + FLANGE_H, rz + pw * 0.5 + 0.003), Vector3(pw * 0.32, shaft_h * 0.82, 0.006), trim_mat))
		# Tapered cap saddle where the round rail seats on the post.
		add_child(_box(Vector3(x, h - rr - 0.02, rz), Vector3(pw * 0.86, 0.04, pw * 0.86), trim_mat))
		if cap_lights:
			add_child(_box(Vector3(x, h - rr - 0.01, rz + pw * 0.5 + 0.005), Vector3(pw * 0.5, 0.018, 0.01), _emi(acc_c, 0.7)))
	else:
		add_child(_box(Vector3(x, h * 0.5 + FLANGE_H * 0.5, rz), Vector3(pw, h - rr, pw), post_mat))
		if cap_lights:
			add_child(_box(Vector3(x, h - rr - 0.02, rz + pw * 0.5 + 0.005), Vector3(pw * 0.5, 0.018, 0.01), _emi(acc_c, 0.6)))


# A horizontal round rail tube laid along X between two end x's at (y, z).
func _railx(x0: float, x1: float, y: float, z: float, r: float, mat: Material) -> MeshInstance3D:
	return _pipe(Vector3(x0, y, z), Vector3(x1, y, z), r, mat)


func _build_chevrons(w: float, h: float, front_z: float, acc_c: Color) -> void:
	# A keep-clear chevron strip: short diagonal segments alternating direction,
	# painted as a thin band low on the deck face. Deterministic, restrained.
	var cy: float = h * 0.26
	var seg: float = 0.12
	var count: int = maxi(int(w / (seg * 1.4)), 3)
	var mat := _emi(acc_c, 0.45)
	for i in range(count):
		var t: float = (float(i) + 0.5) / float(count)
		var x: float = lerpf(-w * 0.45, w * 0.45, t)
		var dirn: float = 1.0 if (i % 2 == 0) else -1.0
		var c := _box(Vector3(x, cy, front_z + 0.004), Vector3(0.018, seg, 0.007), mat)
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


# A cylinder pipe between two points (any orientation) — used for the round rails + end returns.
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


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
