extends Node3D
class_name StationLuminaire

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the station kit's ONLY source of light — a painted-metal Dieter-Rams fixture that carries a REAL Godot light. Two modes via config `mode`: "task" = an aimed SpotLight3D on a gooseneck arm that leans out over a focal bay and throws a tight pool onto ONE thing; "area" = a soft OmniLight3D in a hung housing dropped from a thin rod that fills a whole bay. A foot base on the floor (origin at the floor centre), a stem/arm up to `height`, a head with an emissive lens AND a live light node. 1 cell = 1 m.
# desire: to throw attention onto one thing — the kit's first piece that acts on the OTHERS, not beside them. Every other station prop sits and holds; the luminaire reaches across the room and says "this one" by lighting it, so the bay reads as a serviced inhabited place with a real source casting real shadow, not a flat emissive diorama.
# critical_parameter: mode × intensity — whether it is a focused task spot on a gooseneck or a soft area omni in a hung can, and how hard it pushes light; the composer matches a task spot to a single plinth and an area omni to a whole stage / bench run.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new mode / height / colour / intensity / reach; the light node + lens emission ride the mode.
# emerges: a gooseneck leaning over a bay reads "aimed at this work"; a hung can dropped on a rod reads "overhead room light"; a lit lens + a real cast pool reads "this is the source, the rest is consequence"; warm vs cool reads "inhabited" vs "clinical"; a Rams accent bar + caution rim read "plant, maintained".
# needs: a painted-metal foot/canopy mount [present]; a gooseneck arm (task) or a drop rod + hung housing (area) [present]; an emissive lens / diffuser [present]; a REAL light node — SpotLight3D aimed down the gooseneck (task) or OmniLight3D in the housing (area) [present]; optional warm/cool tint, Rams accent bar, grime band, stencil ID [optional].
# relationships: the overhead, room-acting cousin of the floor-standing display pieces — it lights the [[station_plinth]] / [[station_stage]] / [[station_bench]] that [[curation_station]] composes; the standalone real-source extraction of the underside ring-light look of [[station_gantry]]; shares the HangarKit / Dieter-Rams weathered painted-metal family with the whole station kit.
# truth: a floor makes a place to stand and a wall makes it enclosed, but a light is what makes it usable and what chooses where the eye goes. The luminaire is the kit's first honest piece of infrastructure that acts on its neighbours — to aim a real source at one artifact is attention made visible, and a lit bay is never quite empty.

@export_group("Mode")
## "task" = an aimed SpotLight3D on a gooseneck arm over a focal bay | "area" = a soft OmniLight3D in a hung housing on a drop rod.
@export var mode: String = "task"

@export_group("Dimensions")
## Mount height in metres — the top of the gooseneck post (task) or the ceiling plane the area housing hangs from (area).
@export var height: float = 1.9
## How far the gooseneck arm reaches out over the work in metres (task mode). Ignored by area mode.
@export var arm_reach: float = 0.6

@export_group("Light")
## Real light energy (SpotLight3D / OmniLight3D light_energy).
@export var intensity: float = 3.0
## Light + lens colour, passed via config as a STRING "r,g,b,a". Default = a warm Rams white.
@export var light_color: Color = Color(1.0, 0.95, 0.86)
## Warm/cool: when true, biases the light toward warm tungsten; when false, toward a cool clinical white. Modulates light_color.
@export var warm: bool = true
## Real light range / attenuation distance (m) — OmniLight3D omni_range or SpotLight3D spot_range.
@export var light_range: float = 6.0
## Lens emission energy (the glowing diffuser face, independent of the cast light).
@export var lens_energy: float = 2.2
## Casts real shadows. Off by default (headless/perf); on for hero stills.
@export var cast_shadows: bool = false

@export_group("Surface")
## A Dieter-Rams three-colour accent bar on the housing / foot.
@export var three_bar: bool = true
## Bolt rows on the foot / canopy plate.
@export var bolts: bool = true
## Faint grime band where dust settles on the base.
@export var grime: bool = true
## "rams" (light Braun default) | "terminal" (dark charcoal finish).
@export var finish: String = "rams"
@export var stencil_text: String = ""
@export var wear: float = 0.10

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const WARM_TINT := Color(1.0, 0.90, 0.74)   # tungsten bias when warm
const COOL_TINT := Color(0.90, 0.94, 1.0)   # clinical bias when not warm

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
	if has_meta("config_mode"): mode = str(get_meta("config_mode")).to_lower()
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_arm_reach"): arm_reach = float(str(get_meta("config_arm_reach")))
	if has_meta("config_intensity"): intensity = float(str(get_meta("config_intensity")))
	if has_meta("config_light_color"): light_color = _pc(str(get_meta("config_light_color")), light_color)
	if has_meta("config_warm"): warm = _b(get_meta("config_warm"))
	if has_meta("config_light_range"): light_range = float(str(get_meta("config_light_range")))
	if has_meta("config_lens_energy"): lens_energy = float(str(get_meta("config_lens_energy")))
	if has_meta("config_cast_shadows"): cast_shadows = _b(get_meta("config_cast_shadows"))
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
	var m: String = "area" if mode == "area" else "task"

	# Finish drives the family palette; explicit colours still win away from the terminal finish.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	# The emitted colour: light_color biased warm/cool.
	var lit_col: Color = light_color * (WARM_TINT if warm else COOL_TINT)

	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	var trim_mat: StandardMaterial3D = HangarKit.worn_metal(pcol)
	var lens_mat: StandardMaterial3D = HangarKit.emissive(lit_col, lens_energy)

	if m == "area":
		_build_area(bcol, pcol, acol, ewear, lit_col, body_mat, trim_mat, lens_mat)
	else:
		_build_task(bcol, pcol, acol, ewear, lit_col, body_mat, trim_mat, lens_mat)


# ── TASK: a foot on the floor, a gooseneck arm up to `height` and out `arm_reach`, a head with an
# aimed SpotLight3D throwing a tight pool down onto one focal bay. Origin = floor centre. ──
func _build_task(bcol: Color, pcol: Color, acol: Color, ewear: float, lit_col: Color, body_mat: StandardMaterial3D, trim_mat: StandardMaterial3D, lens_mat: StandardMaterial3D) -> void:
	var h: float = maxf(height, 0.4)
	var reach: float = clampf(arm_reach, 0.0, 1.4)

	# Weighted foot plate on the floor (origin y=0 sits the base flat on the ground).
	add_child(HangarKit.box(Vector3(0, 0.03, 0), Vector3(0.42, 0.06, 0.42), trim_mat))
	add_child(HangarKit.box(Vector3(0, 0.085, 0), Vector3(0.30, 0.05, 0.30), body_mat))
	if bolts:
		add_child(HangarKit.bolts(Vector3(-0.13, 0.064, 0.13), Vector3(0.13, 0.064, 0.13), 2, 0.014, HangarKit.worn_metal(pcol.darkened(0.2))))
		add_child(HangarKit.bolts(Vector3(-0.13, 0.064, -0.13), Vector3(0.13, 0.064, -0.13), 2, 0.014, HangarKit.worn_metal(pcol.darkened(0.2))))

	# Vertical post from the foot up to the gooseneck top.
	var post_top: float = h
	add_child(_pipe(Vector3(0, 0.11, 0), Vector3(0, post_top, 0), 0.034, body_mat))

	# Gooseneck arc: from the post top, arc out +X and gently down to the head mount over the bay.
	var head_mount: Vector3 = Vector3(reach, post_top - 0.18, 0)
	var pts: Array = _gooseneck_points(Vector3(0, post_top, 0), head_mount, 5)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		add_child(_pipe(a, b, 0.026, body_mat))
		add_child(_pipe(a, b, 0.009, HangarKit.emissive(acol, 0.5)))   # slim accent ride on the arm
	# A knuckle where the post meets the arm.
	add_child(_ball(Vector3(0, post_top, 0), 0.05, HangarKit.worn_metal(pcol.darkened(0.12))))

	# Head at the gooseneck end: a small conical shade + emissive lens, tilted down over the bay.
	var head: Node3D = _build_spot_head(head_mount, lit_col, bcol, pcol, acol, ewear, lens_mat)
	add_child(head)

	# Rams bar + grime + stencil on the foot.
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(0.22, 0.026, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, 0.10, 0.155)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(0.34, 0.04, 0.21, bcol))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(0.20, 0.05))
		if q:
			q.position = Vector3(0, 0.10, 0.155)
			add_child(q)


# ── AREA: a thin drop rod from `height` (a ceiling mount), a hung housing can, an emissive lens on
# the underside, a soft OmniLight3D filling the bay. Origin = floor centre (the rod descends from h). ──
func _build_area(bcol: Color, pcol: Color, acol: Color, ewear: float, lit_col: Color, body_mat: StandardMaterial3D, trim_mat: StandardMaterial3D, lens_mat: StandardMaterial3D) -> void:
	var h: float = maxf(height, 0.5)
	var w: float = 0.52                              # housing width
	var hd: float = 0.16                             # housing depth
	var drop: float = clampf(h * 0.22, 0.18, 0.8)    # rod length below the ceiling plane

	# Ceiling canopy plate at the mount height.
	add_child(HangarKit.box(Vector3(0, h - 0.02, 0), Vector3(0.18, 0.04, 0.18), trim_mat))
	# Thin drop rod from the ceiling down to the housing top.
	var housing_top: float = h - drop
	add_child(_pipe(Vector3(0, h - 0.02, 0), Vector3(0, housing_top, 0), 0.02, HangarKit.worn_metal(pcol.darkened(0.15))))

	# Hung housing can.
	var body_cy: float = housing_top - hd * 0.5
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(w, hd, w), body_mat))
	# Inner darker reflector trough.
	add_child(HangarKit.box(Vector3(0, body_cy, 0), Vector3(w * 0.86, hd * 0.92, w * 0.86), HangarKit.rams_body(pcol.darkened(0.06), ewear)))
	# Emissive lens on the underside, facing down.
	var lens_y: float = housing_top - hd + 0.012
	add_child(HangarKit.box(Vector3(0, lens_y, 0), Vector3(w * 0.74, 0.024, w * 0.74), lens_mat))

	# Real soft OmniLight just below the lens.
	_add_omni(Vector3(0, lens_y - 0.06, 0), lit_col)

	# Caution rim + Rams bar + bolts + grime on the housing.
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(w * 0.5, 0.026, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, body_cy, w * 0.5 + 0.014)
		add_child(bar)
	if bolts:
		add_child(HangarKit.bolts(Vector3(-w * 0.34, housing_top - 0.012, 0), Vector3(w * 0.34, housing_top - 0.012, 0), 2, 0.014, HangarKit.worn_metal(pcol.darkened(0.2))))
	if grime:
		var g := HangarKit.grime_band(w * 0.8, 0.04, w * 0.5 + 0.006, bcol)
		g.position.y += body_cy
		add_child(g)
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.5, 0.4), 0.07))
		if q:
			q.position = Vector3(0, body_cy, w * 0.5 + 0.014)
			add_child(q)


# A small tilted shade head holding the SpotLight3D, mounted at the gooseneck end and aimed down.
func _build_spot_head(at: Vector3, lit_col: Color, bcol: Color, pcol: Color, acol: Color, ewear: float, lens_mat: StandardMaterial3D) -> Node3D:
	var head := Node3D.new()
	# Aim mostly down, leaning slightly toward the post (-X) so the cone lands on the bay below the arc.
	var aim: Vector3 = Vector3(-0.32, -1.0, 0.0).normalized()
	var ny: Vector3 = -aim                                    # head local +Y = up the shade
	var ref: Vector3 = Vector3.UP if absf(ny.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var nx: Vector3 = ref.cross(ny).normalized()
	var nz: Vector3 = nx.cross(ny).normalized()
	head.transform = Transform3D(Basis(nx, ny, nz), at)

	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	var hs: float = 0.18

	# Yoke block where the arm meets the head.
	head.add_child(_box_local(Vector3(0, hs * 0.55, 0), Vector3(hs * 0.5, hs * 0.4, hs * 0.5), HangarKit.worn_metal(pcol)))
	# Conical shade, wide mouth opening toward -Y (the aim).
	var cone := CylinderMesh.new()
	cone.top_radius = hs * 0.30
	cone.bottom_radius = hs * 0.92
	cone.height = hs * 1.05
	var cmi := MeshInstance3D.new()
	cmi.mesh = cone
	cmi.material_override = body_mat
	cmi.position = Vector3(0, -hs * 0.1, 0)
	head.add_child(cmi)
	# Accent rim ring at the mouth.
	head.add_child(_cyl_local(Vector3(0, -hs * 0.62, 0), hs * 0.94, 0.03, HangarKit.worn_metal(acol.darkened(0.05))))
	# Emissive lens disc in the mouth.
	head.add_child(_cyl_local(Vector3(0, -hs * 0.5, 0), hs * 0.62, 0.02, lens_mat))

	# The REAL SpotLight3D aimed down local -Y (SpotLight3D points down -Z by default → rotate -90° X).
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, -hs * 0.5, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.light_color = lit_col
	spot.light_energy = maxf(intensity, 0.0)
	spot.spot_range = clampf(light_range, 0.5, 12.0)
	spot.spot_angle = 34.0
	spot.spot_angle_attenuation = 1.4
	spot.spot_attenuation = 1.2
	spot.shadow_enabled = cast_shadows
	head.add_child(spot)
	return head


# Gooseneck knuckle points: from `top`, arc out toward `end` along a shallow downward curve.
func _gooseneck_points(top: Vector3, end: Vector3, segs: int) -> Array:
	var pts: Array = [top]
	for i in range(segs):
		var t: float = float(i + 1) / float(segs)
		var lift: float = sin(t * PI) * 0.10   # bow the arc up a touch so it reads as a gooseneck, not a stick
		pts.append(top.lerp(end, t) + Vector3(0, lift, 0))
	return pts


# ── Real lights ───────────────────────────────────────────────────────
func _add_omni(at: Vector3, col: Color) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = col
	l.light_energy = maxf(intensity, 0.0)
	l.omni_range = maxf(light_range, 0.5)
	l.omni_attenuation = 1.0
	l.shadow_enabled = cast_shadows
	add_child(l)


# ── Primitives ────────────────────────────────────────────────────────
func _ball(at: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = mat
	mi.position = at
	return mi


func _cyl_local(center: Vector3, radius: float, height_y: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_y
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _box_local(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
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
