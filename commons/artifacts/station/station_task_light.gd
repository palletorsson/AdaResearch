extends Node3D
class_name StationTaskLight

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the CLAMP TASK LAMP of a curation station — a painted-metal C-clamp grips a bench or plinth edge, a jointed counter-balanced arm reaches out over the work, and a small shade head holds an emissive bulb and a REAL SpotLight3D aimed forward/down. A local pool of light, thrown by hand exactly where the work is. Origin at the floor/edge-mount point under the clamp; 1 cell = 1 m.
# desire: to be the single strongest "this station is IN USE" cue and the artist's spotlight — to drop a warm, contained pool of light onto one bench or one displayed artifact so the eye is told where to look, without lighting the whole room. The arm reaches; the head leans in; the bulb says someone is working here right now.
# critical_parameter: reach × head_tilt — how far the arm throws the head over the work and how steeply it leans the cone down onto the surface; the composer matches reach to the bench depth and tilt to the surface height.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new arm pose / colour / energy.
# emerges: a dark bulb reads "idle, nobody home"; a lit bulb + a cast cone reads "in use, work happening under this"; a long multi-segment arm reads "drafting / precision tooling"; a wide flat shade reads "softbox, even fill for a displayed piece"; a warm accent and caution band read "this is bench plant, part of the kit".
# needs: a clamp base that grips an edge [present]; a jointed arm of 1..4 segments with knuckle joints [present]; a shade head with an emissive bulb [present]; a real SpotLight3D in the head aimed forward/down [present]; optional cable run down the arm [optional]; optional caution band + stencil + signage [optional].
# relationships: clamps onto the edge of [[station_bench]] / [[station_plinth]] the way [[station_gantry]] spans overhead; the local, hand-aimed cousin of the gantry's fixed ring-light; lights the piece staged by [[curation_station]]; shares the lit-accent / caution-stripe language of [[station_pillar]]; same HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family.
# truth: a lamp you can aim is a finger pointing. To clamp a light to a bench and lean it over the work is the oldest signal that someone has chosen THIS spot to care about — the pool of light is attention made visible, and an empty bench with a lit lamp is never quite empty.

@export_group("Arm")
## Number of jointed arm segments between the clamp and the head (1..4).
@export var arm_segments: int = 2
## Total horizontal reach of the arm out over the work, in metres (X+). Clamped 0.25..1.6.
@export var reach: float = 0.7
## Height of the first knuckle above the clamp / mount surface (m).
@export var post_height: float = 0.42

@export_group("Head")
## Diameter of the shade head bell (m). Larger = a softbox-style flood; smaller = a tight task spot.
@export var head_size: float = 0.22
## Downward tilt of the head (degrees from horizontal). 0 = aims straight forward, 90 = straight down.
@export var head_tilt: float = 42.0
## "bell" (classic conical shade) | "softbox" (flat square panel) | "tube" (cylindrical can).
@export var head_style: String = "bell"

@export_group("Clamp")
## "c_clamp" (a C jaw that grips an edge) | "base_plate" (a weighted disc that just sits on a surface).
@export var clamp_style: String = "c_clamp"
## Thickness of the bench/plinth edge the C-clamp opens to grip (m). Visual only.
@export var grip_thickness: float = 0.08

@export_group("Light")
## Whether the lamp is switched ON — drives the emissive bulb AND the real SpotLight3D.
@export var lit: bool = true
## Colour of the emitted light + the bulb glow.
@export var light_color: Color = Color(1.0, 0.86, 0.62)
## Brightness of the real SpotLight3D (Godot light energy).
@export var light_energy: float = 3.2
## Cone half-angle of the spotlight (degrees). Narrow = a tight task pool; wide = a soft flood.
@export var spot_angle: float = 32.0
## How far the cone reaches before it fades (m).
@export var spot_range: float = 3.5

@export_group("Surface")
## A segmented cable run clipped along the underside of the arm.
@export var with_cable: bool = true
## A diagonal caution-stripe band around the clamp.
@export var caution_stripe: bool = true
## "rams" (light Braun default) | "terminal" (dark charcoal console finish).
@export var finish: String = "rams"
@export var stencil_text: String = ""
## Surface-pinned signage line on a bracket off the clamp. Empty = none.
@export var signage_text: String = ""
@export var wear: float = 0.10
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const SEG_THICK := 0.045        # arm tube radius
const JOINT_R := 0.058          # knuckle joint radius

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
	if has_meta("config_arm_segments"): arm_segments = int(str(get_meta("config_arm_segments")))
	if has_meta("config_reach"): reach = float(str(get_meta("config_reach")))
	if has_meta("config_post_height"): post_height = float(str(get_meta("config_post_height")))
	if has_meta("config_head_size"): head_size = float(str(get_meta("config_head_size")))
	if has_meta("config_head_tilt"): head_tilt = float(str(get_meta("config_head_tilt")))
	if has_meta("config_head_style"): head_style = str(get_meta("config_head_style")).to_lower()
	if has_meta("config_clamp_style"): clamp_style = str(get_meta("config_clamp_style")).to_lower()
	if has_meta("config_grip_thickness"): grip_thickness = float(str(get_meta("config_grip_thickness")))
	if has_meta("config_lit"): lit = _b(get_meta("config_lit"))
	if has_meta("config_light_color"): light_color = _pc(str(get_meta("config_light_color")), light_color)
	if has_meta("config_light_energy"): light_energy = float(str(get_meta("config_light_energy")))
	if has_meta("config_spot_angle"): spot_angle = float(str(get_meta("config_spot_angle")))
	if has_meta("config_spot_range"): spot_range = float(str(get_meta("config_spot_range")))
	if has_meta("config_with_cable"): with_cable = _b(get_meta("config_with_cable"))
	if has_meta("config_caution_stripe"): caution_stripe = _b(get_meta("config_caution_stripe"))
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
	var segs: int = clampi(arm_segments, 1, 4)
	var rch: float = clampf(reach, 0.25, 1.6)
	var ph: float = clampf(post_height, 0.18, 0.9)
	var hs: float = clampf(head_size, 0.10, 0.5)
	var tilt: float = clampf(head_tilt, 0.0, 90.0)

	# Finish drives the family palette; explicit colours still win unless terminal forces them.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	var trim_mat: StandardMaterial3D = HangarKit.worn_metal(pcol)
	var joint_mat: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.12))

	# ── Clamp base (grips an edge or sits as a weighted plate) ──
	var post_base_y: float = _build_clamp(bcol, pcol, acol, ewear, trim_mat)

	# ── Jointed arm: a poly-line of knuckle points from the post top out to the head mount ──
	# The arm rises, then reaches out X+ and slightly down toward the work — a counter-balanced
	# task-lamp pose. Knuckles are evenly spaced along an arc; the LAST point is the head mount.
	var pts: Array = _arm_points(post_base_y, ph, rch, segs)
	# Post (vertical first segment) from the clamp up to the first knuckle.
	add_child(_pipe(Vector3(0, post_base_y, 0), pts[0], SEG_THICK * 1.15, body_mat))
	add_child(_joint(pts[0], JOINT_R * 1.1, joint_mat, acol))
	# Arm segments + knuckle joints between consecutive points.
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		add_child(_pipe(a, b, SEG_THICK, body_mat))
		# A slim accent stripe riding the top of each tube.
		add_child(_pipe(a, b, SEG_THICK * 0.32, HangarKit.emissive(acol, 0.5) if lit else trim_mat))
		add_child(_joint(b, JOINT_R, joint_mat, acol))
		# Counter-balance spring/strut on the first segment (the classic Anglepoise read).
		if i == 0 and segs >= 2:
			var mid: Vector3 = a.lerp(b, 0.5) + Vector3(0, JOINT_R * 1.6, 0)
			add_child(_pipe(a + Vector3(0, JOINT_R, 0), mid, SEG_THICK * 0.5, trim_mat))
			add_child(_pipe(mid, b + Vector3(0, JOINT_R, 0), SEG_THICK * 0.5, trim_mat))

	# ── Cable run clipped under the arm ──
	if with_cable:
		_build_cable(pts, trim_mat, pcol)

	# ── Head: shade + bulb + REAL SpotLight3D, mounted at the last knuckle and tilted down ──
	_build_head(pts[pts.size() - 1], hs, tilt, bcol, pcol, acol, ewear)

	# ── Surface detail ──
	if grime:
		add_child(HangarKit.grime_band(0.34, 0.04, 0.18, bcol))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(0.18, 0.05))
		if q:
			q.position = Vector3(0, post_base_y - 0.05, 0.14)
			add_child(q)
	if signage_text.strip_edges() != "":
		var sign: Node3D = HangarKit.signage(signage_text, [], Vector2(0.26, 0.10), 0.05, Vector3(0, 0, 1))
		if sign:
			sign.position = Vector3(-0.16, post_base_y - 0.04, 0.13)
			add_child(sign)


# Build the clamp/base. Returns the Y at which the vertical post begins (the top of the clamp body).
func _build_clamp(bcol: Color, pcol: Color, acol: Color, ewear: float, trim_mat: StandardMaterial3D) -> float:
	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	if clamp_style == "base_plate":
		# A weighted disc base that simply sits on a bench/plinth top.
		add_child(_cyl(Vector3(0, 0.022, 0), 0.16, 0.044, trim_mat))
		add_child(_cyl(Vector3(0, 0.058, 0), 0.11, 0.03, body_mat))
		# A warm accent ring on the cap.
		if caution_stripe:
			add_child(_cyl(Vector3(0, 0.075, 0), 0.115, 0.012, HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)))
		add_child(HangarKit.bolts(Vector3(-0.06, 0.046, 0.10), Vector3(0.06, 0.046, 0.10), 2, 0.012, trim_mat))
		return 0.075

	# C-clamp: a vertical spine + an upper jaw and a lower jaw that open toward +Z to grip an edge.
	var gap: float = clampf(grip_thickness, 0.02, 0.2)
	var jaw_z: float = 0.13                       # how far the jaws reach out over the edge
	var spine_h: float = gap + 0.13
	var spine_cy: float = spine_h * 0.5
	# Spine (the back of the C).
	add_child(_box(Vector3(0, spine_cy, -0.02), Vector3(0.13, spine_h, 0.06), body_mat))
	# Upper jaw (reaches out over the top of the edge).
	add_child(_box(Vector3(0, spine_h - 0.03, jaw_z * 0.5 - 0.02), Vector3(0.12, 0.05, jaw_z), trim_mat))
	# Lower jaw (under the edge) + a thumbscrew pushing up.
	add_child(_box(Vector3(0, 0.025, jaw_z * 0.5 - 0.02), Vector3(0.12, 0.05, jaw_z), trim_mat))
	add_child(_cyl(Vector3(0, gap * 0.5 + 0.03, jaw_z - 0.02), 0.02, gap * 0.6, HangarKit.worn_metal(pcol.darkened(0.2))))
	add_child(_box(Vector3(0, 0.012, jaw_z - 0.02), Vector3(0.07, 0.024, 0.07), HangarKit.worn_metal(pcol.darkened(0.2))))  # thumbscrew handle
	# Caution stripe band around the spine.
	if caution_stripe:
		var smat: StandardMaterial3D = HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		add_child(_box(Vector3(0, 0.06, -0.052), Vector3(0.12, 0.05, 0.012), smat))
	add_child(HangarKit.bolts(Vector3(-0.04, spine_h - 0.06, 0.012), Vector3(0.04, spine_h - 0.06, 0.012), 2, 0.012, trim_mat))
	return spine_h


# Compute the knuckle points of the arm: post top, then `segs` reaching segments out toward +X,
# arcing slightly down so the head leans over the work. Returns Array[Vector3] of length segs+1.
func _arm_points(post_base_y: float, ph: float, rch: float, segs: int) -> Array:
	var pts: Array = []
	var top: Vector3 = Vector3(0, post_base_y + ph, 0)
	pts.append(top)
	# The arm reaches out +X and drops a little; build along a shallow downward arc.
	var end: Vector3 = Vector3(rch, post_base_y + ph * 0.62, 0)
	for i in range(segs):
		var t: float = float(i + 1) / float(segs)
		# arc the mid points up a touch so it doesn't read as a straight stick (counter-balanced lift).
		var lift: float = sin(t * PI) * (ph * 0.18)
		var p: Vector3 = top.lerp(end, t) + Vector3(0, lift, 0)
		pts.append(p)
	return pts


# A spherical knuckle joint with a small accent pip — the rotatable elbow of the arm.
func _joint(at: Vector3, r: float, mat: StandardMaterial3D, acol: Color) -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = mat
	mi.position = at
	root.add_child(mi)
	# a thin accent collar around the joint.
	root.add_child(_cyl(at, r * 0.6, r * 1.5, HangarKit.worn_metal(acol.darkened(0.1))))
	return root


# Build the shade head + emissive bulb + a real SpotLight3D. Mounted at `at`, the whole head is
# tilted `tilt` degrees downward about X so the cone aims forward and down onto the work.
func _build_head(at: Vector3, hs: float, tilt: float, bcol: Color, pcol: Color, acol: Color, ewear: float) -> void:
	var head := Node3D.new()
	head.position = at
	# Build the head's basis from an explicit AIM vector so the orientation is unambiguous.
	# The head's local -Y axis IS the aim (the shade mouth, bulb and spotlight all point down local -Y).
	# Aim = forward (+X reach) rotated DOWN by `tilt` degrees: tilt 0 = straight +X, tilt 90 = straight down.
	var tr: float = deg_to_rad(tilt)
	var aim: Vector3 = Vector3(cos(tr), -sin(tr), 0.0).normalized()   # the direction the cone throws
	var ny: Vector3 = -aim                                            # head local +Y = up the shade (opposite the aim)
	var ref: Vector3 = Vector3.UP if absf(ny.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var nx: Vector3 = ref.cross(ny).normalized()
	var nz: Vector3 = nx.cross(ny).normalized()
	head.transform = Transform3D(Basis(nx, ny, nz), at)
	add_child(head)

	var body_mat: StandardMaterial3D = HangarKit.finish_body(finish, bcol, ewear)
	var trim_mat: StandardMaterial3D = HangarKit.worn_metal(pcol)

	# A small yoke block where the arm meets the head (toward local +Y, back of the lamp).
	head.add_child(_box(Vector3(0, hs * 0.55, 0), Vector3(hs * 0.5, hs * 0.4, hs * 0.5), trim_mat))

	# The shade. Local -Y points "out the front" of the lamp (the aim direction).
	if head_style == "softbox":
		# Flat square panel + a lit diffuser face.
		head.add_child(_box(Vector3(0, 0, 0), Vector3(hs * 1.4, 0.05, hs * 1.4), body_mat))
		var face_mat: StandardMaterial3D = HangarKit.emissive(light_color, 1.6) if lit else HangarKit.rams_body(pcol.lightened(0.1), 0.04)
		head.add_child(_box(Vector3(0, -0.03, 0), Vector3(hs * 1.22, 0.02, hs * 1.22), face_mat))
		# thin accent frame edge.
		head.add_child(_box(Vector3(0, 0.005, 0), Vector3(hs * 1.44, 0.018, hs * 1.44), HangarKit.worn_metal(acol.darkened(0.05))))
	elif head_style == "tube":
		# A cylindrical can shade.
		head.add_child(_cyl(Vector3(0, 0, 0), hs * 0.6, hs * 1.1, body_mat))
		head.add_child(_cyl(Vector3(0, hs * 0.5, 0), hs * 0.62, 0.03, HangarKit.worn_metal(acol.darkened(0.05))))
	else:
		# "bell": a conical shade (a cone whose wide mouth opens toward -Y, the aim).
		var cone := CylinderMesh.new()
		cone.top_radius = hs * 0.30          # narrow neck (top, toward the yoke)
		cone.bottom_radius = hs * 0.92       # wide mouth (front, the aim)
		cone.height = hs * 1.05
		var cmi := MeshInstance3D.new()
		cmi.mesh = cone
		cmi.material_override = body_mat
		cmi.position = Vector3(0, -hs * 0.1, 0)
		head.add_child(cmi)
		# accent rim ring at the mouth.
		head.add_child(_cyl(Vector3(0, -hs * 0.62, 0), hs * 0.94, 0.03, HangarKit.worn_metal(acol.darkened(0.05))))
		# a Rams three-colour bar on the shade neck (faces the viewer roughly).
		var bar: Node3D = HangarKit.three_color_bar(hs * 0.7, 0.022, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, hs * 0.18, hs * 0.31)
		bar.rotation_degrees = Vector3(90, 0, 0)
		head.add_child(bar)

	# The emissive BULB sitting in the mouth of the shade (always present; dark when off).
	var bulb := SphereMesh.new()
	var br: float = hs * 0.34
	bulb.radius = br
	bulb.height = br * 2.0
	var bmi := MeshInstance3D.new()
	bmi.mesh = bulb
	bmi.material_override = HangarKit.emissive(light_color, 4.0) if lit else HangarKit.rams_body(Color(0.86, 0.85, 0.82), 0.1)
	bmi.position = Vector3(0, -hs * 0.45, 0)
	head.add_child(bmi)

	# The REAL SpotLight3D, in the head, aiming down local -Y (the shade mouth / aim direction).
	# A SpotLight3D points down its local -Z by default, so rotate it -90° about X to face -Y.
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, -hs * 0.5, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.light_color = light_color
	spot.light_energy = maxf(light_energy, 0.0) if lit else 0.0
	spot.spot_range = clampf(spot_range, 0.5, 12.0)
	spot.spot_angle = clampf(spot_angle, 6.0, 70.0)
	spot.spot_angle_attenuation = 1.4
	spot.spot_attenuation = 1.2
	spot.shadow_enabled = lit
	spot.visible = lit
	head.add_child(spot)


# Cable run clipped under the arm: a few small box clips + a sagging tube between knuckles.
func _build_cable(pts: Array, trim_mat: StandardMaterial3D, pcol: Color) -> void:
	var cab_mat: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.2))
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i] + Vector3(0, -SEG_THICK * 1.1, 0)
		var b: Vector3 = pts[i + 1] + Vector3(0, -SEG_THICK * 1.1, 0)
		# a sag point between the two clips.
		var mid: Vector3 = a.lerp(b, 0.5) + Vector3(0, -0.03, 0)
		add_child(_pipe(a, mid, 0.012, cab_mat))
		add_child(_pipe(mid, b, 0.012, cab_mat))
		# a small clip at the start knuckle.
		add_child(_box(a + Vector3(0, SEG_THICK * 0.5, 0), Vector3(0.022, 0.018, 0.022), trim_mat))


# ── helpers ──
func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


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


# A cylinder pipe between a and b (any orientation) — the arm tubes + cable runs.
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
