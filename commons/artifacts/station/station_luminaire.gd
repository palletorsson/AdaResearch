extends Node3D
class_name StationLuminaire

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the CEILING LIGHT FIXTURE of the curation station — a painted-metal luminaire that actually emits light. A Dieter-Rams housing (recessed can / linear troffer / hung pendant / wall sconce) carries an EMISSIVE lens panel AND a real Godot light node (OmniLight3D for area fixtures, SpotLight3D for a pendant aimed down), so the bay is no longer lit only by glowing trim — there is a source on the ceiling that casts onto the floor and the work below. Origin at the MOUNT face (ceiling plane for ceiling mounts, wall plane for sconces); the body hangs/sits below or stands off it. 1 cell = 1 m.
# desire: to be the thing that lights the room instead of merely looking lit — to drop a warm, weathered, intentional source over a stage so artifacts catch real shadow and the space reads as a serviced, inhabited bay rather than a flat emissive diorama. The fixture that admits a room needs a light, not just a glow.
# critical_parameter: fixture_style × light_energy — what KIND of fixture it is (a clean recessed can, a long troffer, a focused pendant, a wall sconce) and how hard it pushes light. The composer matches style to the bay (troffer over a bench run, pendant over a single plinth, recessed in a low ceiling, sconce on a wall).
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new style / size / colour / energy; `lit` toggles the real light + lens emission on or off.
# emerges: a bare can reads "ceiling service"; a lit lens reads "powered"; a real cast pool on the floor reads "this is the source, the rest is consequence"; a troffer reads "industrial bay lighting"; a pendant on a drop reads "focused on one thing below"; a sconce reads "this wall is finished"; caution trim + a Rams bar read "plant, maintained".
# needs: a painted-metal housing matched to fixture_style [present]; an emissive lens / diffuser panel [present]; a REAL light node — OmniLight3D (recessed/troffer/sconce) or SpotLight3D aimed down (pendant) [present]; a mount detail (recess collar / surface plate / drop stem / wall bracket) per `mount` [present]; optional caution trim + Rams accent bar + bolts + grime [optional]; optional stencil ID [optional].
# relationships: hangs from / is the counterpart to [[station_gantry]] (whose underside strip + ring-light look this fixture extracts and turns into a STANDALONE real source); lights the [[station_stage]] / [[station_bench]] / [[station_plinth]] that [[curation_station]] composes; the overhead sibling of the floor-standing [[station_pillar]]; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look with the whole station kit.
# truth: a floor makes a place stand and a roof makes it enclosed, but a light is what makes it usable after dark. To hang a real source — not a painted glow — is to admit the room is meant to be worked in. The fixture is the smallest honest infrastructure: it does the thing it depicts.

@export_group("Fixture")
## "pendant" (hung on a drop stem, SpotLight aimed down) | "recessed" (sunk into the ceiling, flush can) | "troffer" (long surface/recessed linear panel) | "sconce" (wall-mounted half-shell uplight/downlight).
@export var fixture_style: String = "recessed"
## "ceiling" (mounts to the ceiling plane, body hangs below) | "wall" (mounts to a wall plane, body stands off it). Sconce forces "wall".
@export var mount: String = "ceiling"

@export_group("Dimensions")
## Footprint width (X) of the housing in metres. Recessed/pendant ~ a square; troffer uses `length` for the long axis.
@export var size: float = 0.6
## Long-axis length (X) for a troffer / linear fixture in metres. Ignored by recessed/pendant (they use `size`).
@export var length: float = 1.8
## Drop length (m) of the pendant stem below the ceiling, or stand-off depth of a sconce from the wall.
@export var drop: float = 0.55
## Housing depth (m) — how thick the can / troffer body is.
@export var housing_depth: float = 0.16

@export_group("Light")
## Whether the fixture is powered: the real light node is enabled and the lens glows. false = dark fixture (off).
@export var lit: bool = true
## Lens / light colour. Default = warm Rams white.
@export var light_color: Color = Color(1.0, 0.96, 0.88)
## Real light energy (OmniLight3D / SpotLight3D `light_energy`).
@export var light_energy: float = 3.0
## Real light range / attenuation distance (m) — OmniLight3D `omni_range` or SpotLight3D `spot_range`.
@export var light_range: float = 6.0
## Lens emission energy (the glowing diffuser face, independent of the cast light).
@export var lens_energy: float = 2.2
## Casts real shadows. Off by default in headless/perf contexts; on for hero stills.
@export var cast_shadows: bool = false

@export_group("Surface")
## A diagonal caution-stripe trim band around the housing rim.
@export var caution_stripe: bool = true
## A Dieter-Rams three-colour accent bar on the housing side.
@export var three_bar: bool = true
## Bolt rows on the mount plate.
@export var bolts: bool = true
## Faint grime band where dust settles on the housing.
@export var grime: bool = true
## "rams" (light Braun default) | "terminal" (dark charcoal finish).
@export var finish: String = "rams"
@export var stencil_text: String = ""
@export var wear: float = 0.10

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

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
	if has_meta("config_fixture_style"): fixture_style = str(get_meta("config_fixture_style")).to_lower()
	if has_meta("config_mount"): mount = str(get_meta("config_mount")).to_lower()
	if has_meta("config_size"): size = float(str(get_meta("config_size")))
	if has_meta("config_length"): length = float(str(get_meta("config_length")))
	if has_meta("config_drop"): drop = float(str(get_meta("config_drop")))
	if has_meta("config_housing_depth"): housing_depth = float(str(get_meta("config_housing_depth")))
	if has_meta("config_lit"): lit = _b(get_meta("config_lit"))
	if has_meta("config_light_color"): light_color = _pc(str(get_meta("config_light_color")), light_color)
	if has_meta("config_light_energy"): light_energy = float(str(get_meta("config_light_energy")))
	if has_meta("config_light_range"): light_range = float(str(get_meta("config_light_range")))
	if has_meta("config_lens_energy"): lens_energy = float(str(get_meta("config_lens_energy")))
	if has_meta("config_cast_shadows"): cast_shadows = _b(get_meta("config_cast_shadows"))
	if has_meta("config_caution_stripe"): caution_stripe = _b(get_meta("config_caution_stripe"))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var style: String = fixture_style
	if not style in ["pendant", "recessed", "troffer", "sconce"]:
		style = "recessed"
	# A sconce is inherently wall-mounted; everything else honours `mount`.
	var mnt: String = "wall" if style == "sconce" else ("wall" if mount == "wall" else "ceiling")

	# Finish drives the family palette; explicit colours still win away from default.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	var body_mat := HangarKit.finish_body(finish, bcol, ewear)
	var trim_mat := HangarKit.worn_metal(pcol)
	var lens_col: Color = light_color if lit else light_color.darkened(0.55)
	var lens_mat: Material = HangarKit.emissive(lens_col, lens_energy) if lit else HangarKit.rams_body(lens_col, 0.2)

	match style:
		"recessed":
			_build_can(bcol, pcol, acol, ewear, body_mat, trim_mat, lens_mat, mnt, false)
		"troffer":
			_build_troffer(bcol, pcol, acol, ewear, body_mat, trim_mat, lens_mat, mnt)
		"pendant":
			_build_pendant(bcol, pcol, acol, ewear, body_mat, trim_mat, lens_mat)
		"sconce":
			_build_sconce(bcol, pcol, acol, ewear, body_mat, trim_mat, lens_mat)


# ── RECESSED: a flush can sunk into the ceiling, lens flush with the mount plane, light below ──
func _build_can(bcol: Color, pcol: Color, acol: Color, ewear: float, body_mat: Material, trim_mat: Material, lens_mat: Material, mnt: String, _wall: bool) -> void:
	var w: float = clampf(size, 0.3, 1.6)
	var hd: float = clampf(housing_depth, 0.08, 0.5)
	# Recess collar mount plate flush on the ceiling.
	add_child(HangarKit.box(Vector3(0, 0.01, 0), Vector3(w + 0.10, 0.02, w + 0.10), trim_mat))
	# Can body — hangs DOWN from the ceiling plane (origin y=0 = ceiling).
	var body_cy: float = -hd * 0.5
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(w, hd, w), body_mat))
	# Reflector cone hint: a slightly inset darker ring just inside the rim.
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(w * 0.86, hd * 0.92, w * 0.86), HangarKit.rams_body(pcol.darkened(0.06), ewear)))
	# Emissive lens panel on the UNDERSIDE (facing down into the room).
	var lens_y: float = -hd + 0.012
	add_child(HangarKit.box(Vector3(0, lens_y, 0), Vector3(w * 0.74, 0.024, w * 0.74), lens_mat))
	# Real downward source just below the lens.
	_add_omni(Vector3(0, lens_y - 0.05, 0))
	_trim_round(w, hd, body_cy, bcol, pcol, acol)


# ── TROFFER: a long linear panel fixture (a bench/bay run light) ──
func _build_troffer(bcol: Color, pcol: Color, acol: Color, ewear: float, body_mat: Material, trim_mat: Material, lens_mat: Material, _mnt: String) -> void:
	var ln: float = clampf(length, 0.6, 4.0)
	var w: float = clampf(size, 0.2, 1.0)
	var hd: float = clampf(housing_depth, 0.08, 0.4)
	# Surface mount plate along the spine.
	add_child(HangarKit.box(Vector3(0, 0.01, 0), Vector3(ln + 0.08, 0.02, w + 0.06), trim_mat))
	var body_cy: float = -hd * 0.5
	# Long housing.
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(ln, hd, w), body_mat))
	# Inner reflector trough.
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(ln * 0.97, hd * 0.9, w * 0.82), HangarKit.rams_body(pcol.darkened(0.06), ewear)))
	# Long emissive lens strip on the underside.
	var lens_y: float = -hd + 0.012
	add_child(HangarKit.box(Vector3(0, lens_y, 0), Vector3(ln * 0.92, 0.024, w * 0.68), lens_mat))
	# Two real sources spread along the length so a long fixture lights its whole run.
	var n_lights: int = 2 if ln < 2.6 else 3
	for i in range(n_lights):
		var t: float = 0.0 if n_lights <= 1 else (float(i) / float(n_lights - 1)) - 0.5
		_add_omni(Vector3(t * ln * 0.7, lens_y - 0.05, 0))
	# End caps + Rams trim along the long side.
	for sx in [-1.0, 1.0]:
		add_child(HangarKit.box(Vector3(sx * ln * 0.5, body_cy, 0), Vector3(0.05, hd + 0.02, w + 0.02), trim_mat))
	if caution_stripe:
		var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		for sx in [-1.0, 1.0]:
			add_child(HangarKit.box(Vector3(sx * (ln * 0.5 - 0.10), body_cy, w * 0.5 + 0.006), Vector3(0.14, hd * 0.7, 0.012), smat))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(ln * 0.4, 0.6), 0.03, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, body_cy, w * 0.5 + 0.014)
		add_child(bar)
	if bolts:
		var bm := HangarKit.worn_metal(pcol.darkened(0.2))
		add_child(HangarKit.bolts(Vector3(-ln * 0.4, 0.012, w * 0.5 - 0.02), Vector3(ln * 0.4, 0.012, w * 0.5 - 0.02), 4, 0.014, bm))
	_finish_surface(ln, hd, body_cy, bcol, Vector3(0, body_cy, w * 0.5 + 0.012))


# ── PENDANT: a hung shade on a drop stem with a SpotLight aimed straight down ──
func _build_pendant(bcol: Color, pcol: Color, acol: Color, ewear: float, body_mat: Material, trim_mat: Material, lens_mat: Material) -> void:
	var w: float = clampf(size, 0.25, 1.2)
	var hd: float = clampf(housing_depth, 0.1, 0.5)
	var dl: float = clampf(drop, 0.1, 2.0)
	# Ceiling canopy plate.
	add_child(HangarKit.box(Vector3(0, 0.0, 0), Vector3(0.18, 0.04, 0.18), trim_mat))
	# Drop stem.
	add_child(_pipe(Vector3(0, 0.0, 0), Vector3(0, -dl, 0), 0.022, HangarKit.worn_metal(pcol.darkened(0.15))))
	# Shade: a downward-tapering can (cylinder) hanging at the stem end.
	var shade_top: float = -dl
	var shade_cy: float = shade_top - hd * 0.5
	add_child(_cyl(Vector3(0, shade_cy, 0), w * 0.5, hd, body_mat))
	# Inner darker reflector.
	add_child(_cyl(Vector3(0, shade_cy, 0), w * 0.44, hd * 0.9, HangarKit.rams_body(pcol.darkened(0.08), ewear)))
	# Emissive ring-light lens at the shade mouth (extracted from the gantry ring-light look).
	var lens_y: float = shade_top - hd + 0.01
	var ring := TorusMesh.new()
	ring.inner_radius = w * 0.30
	ring.outer_radius = w * 0.42
	ring.rings = 24
	ring.ring_segments = 12
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = ring
	ring_mi.material_override = lens_mat
	ring_mi.position = Vector3(0, lens_y, 0)
	add_child(ring_mi)
	# A filled emissive disc inside the ring (the diffuser).
	add_child(_cyl(Vector3(0, lens_y, 0), w * 0.30, 0.02, lens_mat))
	# Warm accent pip at the hub.
	add_child(_cyl(Vector3(0, lens_y + 0.01, 0), w * 0.07, 0.03, HangarKit.emissive(acol, 1.4 if lit else 0.0)))
	# Real focused SpotLight aimed straight down.
	_add_spot(Vector3(0, lens_y - 0.04, 0))
	# Rams bar around the shade body.
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(w * 0.7, 0.028, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, shade_cy + hd * 0.2, w * 0.5 + 0.012)
		add_child(bar)
	if grime:
		add_child(_cyl(Vector3(0, shade_cy - hd * 0.45, 0), w * 0.505, 0.03, HangarKit.painted_metal(bcol.darkened(0.28), 0.4)))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(w * 0.6, 0.08))
		if q:
			q.position = Vector3(0, shade_cy, w * 0.5 + 0.012)
			add_child(q)


# ── SCONCE: a wall half-shell, body standing off the wall, light washing out/up ──
func _build_sconce(bcol: Color, pcol: Color, acol: Color, ewear: float, body_mat: Material, trim_mat: Material, lens_mat: Material) -> void:
	# Mount plane is a WALL (the +Z face here = the wall surface; body stands off toward +Z... we model
	# origin AT the wall, body proud toward +Z, lens facing OUT). Keep it simple: wall is the XY plane at z=0.
	var w: float = clampf(size, 0.2, 1.0)
	var hd: float = clampf(housing_depth, 0.1, 0.5)
	var so: float = clampf(drop, 0.08, 0.6)   # stand-off depth from the wall
	# Wall bracket plate.
	add_child(HangarKit.box(Vector3(0, 0, 0.01), Vector3(w + 0.08, w * 0.8 + 0.08, 0.02), trim_mat))
	# Half-shell body standing off the wall (a box proud toward +Z, open top/bottom for an up/down wash).
	var body_cz: float = so * 0.5 + 0.02
	add_child(HangarKit.box(Vector3(0, 0, body_cz), Vector3(w, w * 0.7, so), body_mat))
	# Inner reflector.
	add_child(HangarKit.box(Vector3(0, 0, body_cz), Vector3(w * 0.84, w * 0.56, so * 0.9), HangarKit.rams_body(pcol.darkened(0.06), ewear)))
	# Emissive lens on the OUTWARD face (facing +Z, away from the wall).
	var lens_z: float = so + 0.03
	add_child(HangarKit.box(Vector3(0, 0, lens_z), Vector3(w * 0.7, w * 0.5, 0.024), lens_mat))
	# Real omni source just off the wall in front of the shell (washes the wall + room).
	_add_omni(Vector3(0, 0, lens_z + 0.06))
	# Caution + Rams trim along the bottom rim.
	if caution_stripe:
		var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		add_child(HangarKit.box(Vector3(0, -w * 0.36, body_cz), Vector3(w * 0.9, 0.04, so * 0.8), smat))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(w * 0.6, 0.026, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, w * 0.36, lens_z)
		add_child(bar)
	if bolts:
		var bm := HangarKit.worn_metal(pcol.darkened(0.2))
		add_child(HangarKit.bolts(Vector3(-w * 0.4, w * 0.34, 0.02), Vector3(w * 0.4, w * 0.34, 0.02), 2, 0.014, bm))
		add_child(HangarKit.bolts(Vector3(-w * 0.4, -w * 0.34, 0.02), Vector3(w * 0.4, -w * 0.34, 0.02), 2, 0.014, bm))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(w * 0.55, 0.07))
		if q:
			q.position = Vector3(0, -w * 0.30, lens_z + 0.01)
			add_child(q)


# ── Shared ceiling-fixture trim (round can / recessed): caution rim + bar + bolts + grime ──
func _trim_round(w: float, hd: float, body_cy: float, bcol: Color, pcol: Color, acol: Color) -> void:
	if caution_stripe:
		var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var center: Vector3 = nrm * (w * 0.5 + 0.006) + Vector3(0, body_cy, 0)
			var sz: Vector3 = Vector3(0.012, hd * 0.6, w * 0.8) if absf(nrm.x) > 0.5 else Vector3(w * 0.8, hd * 0.6, 0.012)
			add_child(HangarKit.box(center, sz, smat))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(w * 0.6, 0.028, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, body_cy, w * 0.5 + 0.014)
		add_child(bar)
	if bolts:
		var bm := HangarKit.worn_metal(pcol.darkened(0.2))
		add_child(HangarKit.bolts(Vector3(-w * 0.36, 0.012, 0), Vector3(w * 0.36, 0.012, 0), 2, 0.014, bm))
	_finish_surface(w, hd, body_cy, bcol, Vector3(0, body_cy, w * 0.5 + 0.012))


# Grime band + stencil shared across the surface-mount styles.
func _finish_surface(span: float, _hd: float, body_cy: float, bcol: Color, stencil_pos: Vector3) -> void:
	if grime:
		var g := HangarKit.grime_band(span * 0.8, 0.04, span * 0.5 + 0.006, bcol)
		g.position.y += body_cy
		add_child(g)
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(span * 0.5, 0.6), 0.08))
		if q:
			q.position = stencil_pos
			add_child(q)


# ── Real lights ───────────────────────────────────────────────────────
func _add_omni(at: Vector3) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = light_color
	l.light_energy = light_energy if lit else 0.0
	l.omni_range = maxf(light_range, 0.5)
	l.omni_attenuation = 1.0
	l.shadow_enabled = cast_shadows and lit
	add_child(l)


func _add_spot(at: Vector3) -> void:
	var l := SpotLight3D.new()
	l.position = at
	# Aim straight down (default SpotLight3D points toward -Z; rotate to point -Y).
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.light_color = light_color
	l.light_energy = light_energy if lit else 0.0
	l.spot_range = maxf(light_range, 0.5)
	l.spot_angle = 38.0
	l.spot_angle_attenuation = 1.0
	l.shadow_enabled = cast_shadows and lit
	add_child(l)


# ── Primitives ────────────────────────────────────────────────────────
func _cyl(center: Vector3, radius: float, height_y: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_y
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


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
