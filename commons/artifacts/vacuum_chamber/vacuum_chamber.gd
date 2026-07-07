extends Node3D
class_name VacuumChamber

# @identity
# essence: a translucent bell-jar on a dark steel platform — Aperture / alchemy vocabulary for "this is the controlled void". A round platform base, a cylindrical glass body capped with a hemispherical dome, an interior emissive disc that gives the chamber its eerie inside-light, a tiny pressure gauge on the platform, and an optional floating specimen at the chamber's heart. The lab's WANT for "outside the world, briefly".
# desire: every chamber wants its inside to be DIFFERENT from its outside. The vacuum chamber is the architectural assertion that conditions can be locally REVERSED — pressure can drop, atmosphere can vanish, a specimen can FLOAT free of weight inside it. It wants the player to walk around it. To look IN, not at.
# critical_parameter: pressure_status — "vacuum" reads as RESEARCH (green needle, calm interior, "we are observing nothing"), "atmospheric" reads as INERT / not-in-use (white needle, just storage), "over" reads as DANGER (red needle, the experiment IS pressurised, something is happening). Same hardware, three different stories about what the chamber is doing right now.
# triggers: _ready() builds platform + glass body + dome + interior glow disc + gauge + optional specimen + accent stripe from exports; apply_grid_config rebuilds
# emerges: vacuum + green + specimen visible = "we are studying something in suspension"; over + red + specimen visible = "the experiment is HOT, do not approach"; atmospheric + white + no specimen = "this chamber is empty, between runs"; interior_glow high = "the chamber is the room's lantern". The gauge becomes the chamber's mood.
# needs: cylindrical platform [present]; translucent glass cylinder + dome top [present]; interior emissive disc [present]; pressure gauge with status-colored needle [present]; optional floating specimen [present]; accent stripe around platform top edge [present]
# relationships: sibling to specimen_jar (both PRESERVE something inside transparent glass — the specimen_jar is HANDS-ON, the vacuum chamber is HANDS-OFF); cousin to fume_hood (both manage controlled atmospheres — the fume_hood pulls AWAY, the chamber holds APART); peer to microscope (both are LOOKING-AT-ME architectures — but the vacuum chamber wants to be looked-IN, not looked-THROUGH)
# truth: a vacuum chamber is not just a glass jar on a platform. It is the lab's most explicit claim about ISOLATION — that conditions can be made local, that there is an INSIDE the experiment cannot escape from. The chamber is QFEP made literal: a sealed surface that produces different physics on either side.

## A bell-jar vacuum chamber on a platform.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the platform footprint, on the floor. The dome rises in +Y. Gauge
## sits on the +Z (front) face of the platform.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var jar_height: float = 0.65
@export var jar_radius: float = 0.22
@export var platform_radius: float = 0.30
@export var platform_height: float = 0.10

@export_group("Color")
@export var glass_color: Color = Color(0.78, 0.85, 0.92, 0.30)
@export var platform_color: Color = Color(0.18, 0.18, 0.22)
@export var interior_color: Color = Color(0.65, 0.85, 1.0)
@export var specimen_color: Color = Color(0.40, 0.85, 0.55, 0.92)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Gauge")
@export var gauge_present: bool = true
## "vacuum" | "atmospheric" | "over"
@export var pressure_status: String = "vacuum"

@export_group("Interior")
@export_range(0.0, 2.0, 0.05) var interior_glow: float = 0.5
@export var specimen_visible: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const JAR_WALL_THICKNESS: float = 0.008
const DOME_FRACTION: float = 0.20         # dome takes top 20% of jar_height
const PLATFORM_RIM_HEIGHT: float = 0.018
const PLATFORM_RIM_DEPTH: float = 0.006
const GAUGE_RADIUS: float = 0.04
const GAUGE_THICKNESS: float = 0.012
const GAUGE_NEEDLE_LENGTH: float = 0.030
const GAUGE_NEEDLE_THICKNESS: float = 0.003
const SPECIMEN_RADIUS: float = 0.055
const ACCENT_STRIP_HEIGHT: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_chamber()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_chamber()


func _read_metadata_overrides() -> void:
	if has_meta("config_jar_height"):
		jar_height = float(str(get_meta("config_jar_height")))
	if has_meta("config_jar_radius"):
		jar_radius = float(str(get_meta("config_jar_radius")))
	if has_meta("config_platform_radius"):
		platform_radius = float(str(get_meta("config_platform_radius")))
	if has_meta("config_platform_height"):
		platform_height = float(str(get_meta("config_platform_height")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_platform_color"):
		platform_color = _parse_color(str(get_meta("config_platform_color")), platform_color)
	if has_meta("config_interior_color"):
		interior_color = _parse_color(str(get_meta("config_interior_color")), interior_color)
	if has_meta("config_specimen_color"):
		specimen_color = _parse_color(str(get_meta("config_specimen_color")), specimen_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_gauge_present"):
		var gv := str(get_meta("config_gauge_present")).to_lower()
		gauge_present = gv in ["true", "1", "yes", "on"]
	if has_meta("config_pressure_status"):
		pressure_status = str(get_meta("config_pressure_status")).to_lower()
	if has_meta("config_interior_glow"):
		interior_glow = float(str(get_meta("config_interior_glow")))
	if has_meta("config_specimen_visible"):
		var sv := str(get_meta("config_specimen_visible")).to_lower()
		specimen_visible = sv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_chamber() -> void:
	_built = true
	_build_platform()
	_build_glass_body()
	_build_dome()
	_build_interior_glow()
	if gauge_present:
		_build_gauge()
	if specimen_visible:
		_build_specimen()
	_build_accent_stripe()


func _build_platform() -> void:
	var platform := MeshInstance3D.new()
	platform.name = "Platform"
	var pm := CylinderMesh.new()
	pm.top_radius = platform_radius
	pm.bottom_radius = platform_radius
	pm.height = platform_height
	platform.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.roughness = 0.45
	mat.metallic = 0.65
	platform.material_override = mat
	platform.position = Vector3(0.0, platform_height * 0.5, 0.0)
	add_child(platform)


func _build_glass_body() -> void:
	# Translucent cylinder reaching up to about 80% of jar_height.
	var body_height: float = jar_height * (1.0 - DOME_FRACTION)
	var glass := MeshInstance3D.new()
	glass.name = "GlassBody"
	var gm := CylinderMesh.new()
	gm.top_radius = jar_radius
	gm.bottom_radius = jar_radius
	gm.height = body_height
	glass.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position = Vector3(0.0, platform_height + body_height * 0.5, 0.0)
	add_child(glass)


func _build_dome() -> void:
	# Approximate the hemispherical dome with a SphereMesh placed so the
	# equator sits at the top of the glass body, and only the upper half
	# is visible above the body.
	var dome := MeshInstance3D.new()
	dome.name = "Dome"
	var sm := SphereMesh.new()
	sm.radius = jar_radius
	sm.height = jar_radius * 2.0
	dome.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	dome.material_override = mat
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body_height: float = jar_height * (1.0 - DOME_FRACTION)
	# Sphere center at top of body — dome height above center is jar_radius,
	# but the dome target height is jar_height * DOME_FRACTION. Scale Y if
	# the natural sphere top exceeds the target.
	var dome_target: float = jar_height * DOME_FRACTION
	if jar_radius > 0.0:
		dome.scale = Vector3(1.0, dome_target / jar_radius, 1.0)
	dome.position = Vector3(0.0, platform_height + body_height, 0.0)
	add_child(dome)


func _build_interior_glow() -> void:
	# Emissive thin disc just above the platform top inside the jar.
	var disc := MeshInstance3D.new()
	disc.name = "InteriorGlow"
	var cm := CylinderMesh.new()
	cm.top_radius = jar_radius * 0.85
	cm.bottom_radius = jar_radius * 0.85
	cm.height = 0.008
	disc.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = interior_color
	mat.emission_enabled = true
	mat.emission = interior_color
	var energy: float = max(0.0, interior_glow) * 2.4
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.8
	disc.material_override = mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position = Vector3(0.0, platform_height + 0.008, 0.0)
	add_child(disc)


func _build_gauge() -> void:
	var root := Node3D.new()
	root.name = "Gauge"
	add_child(root)

	# Gauge face — small disc on the front (+Z) of the platform.
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_color = Color(0.92, 0.92, 0.94)
	face_mat.roughness = 0.4
	face_mat.metallic = 0.2

	var face := MeshInstance3D.new()
	face.name = "GaugeFace"
	var fm := CylinderMesh.new()
	fm.top_radius = GAUGE_RADIUS
	fm.bottom_radius = GAUGE_RADIUS
	fm.height = GAUGE_THICKNESS
	face.mesh = fm
	face.material_override = face_mat
	# Lay flat against the +Z platform face.
	face.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var gauge_y: float = platform_height * 0.5
	var gauge_z: float = platform_radius + GAUGE_THICKNESS * 0.5 - 0.002
	face.position = Vector3(0.0, gauge_y, gauge_z)
	root.add_child(face)

	# Bezel ring (slightly larger, darker).
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = platform_color
	bezel_mat.roughness = 0.45
	bezel_mat.metallic = 0.6
	var bezel := MeshInstance3D.new()
	bezel.name = "GaugeBezel"
	var bm := CylinderMesh.new()
	bm.top_radius = GAUGE_RADIUS * 1.18
	bm.bottom_radius = GAUGE_RADIUS * 1.18
	bm.height = GAUGE_THICKNESS * 0.5
	bezel.mesh = bm
	bezel.material_override = bezel_mat
	bezel.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	bezel.position = Vector3(0.0, gauge_y, gauge_z - GAUGE_THICKNESS * 0.25)
	root.add_child(bezel)

	# Needle — thin rotated box. Status drives both color and rotation.
	var needle_color: Color = Color(0.30, 0.85, 0.40)   # vacuum = green
	var needle_angle_deg: float = -55.0                 # left-of-center
	if pressure_status == "atmospheric":
		needle_color = Color(0.95, 0.95, 0.95)
		needle_angle_deg = 0.0
	elif pressure_status == "over":
		needle_color = Color(0.95, 0.25, 0.25)
		needle_angle_deg = 55.0

	var needle := MeshInstance3D.new()
	needle.name = "GaugeNeedle"
	var nm := BoxMesh.new()
	nm.size = Vector3(GAUGE_NEEDLE_THICKNESS, GAUGE_NEEDLE_LENGTH, GAUGE_NEEDLE_THICKNESS)
	needle.mesh = nm
	var n_mat := StandardMaterial3D.new()
	n_mat.albedo_color = needle_color
	n_mat.emission_enabled = true
	n_mat.emission = needle_color
	n_mat.emission_energy_multiplier = 1.0
	needle.material_override = n_mat
	# Rotate around the gauge face axis (Z). Needle pivot is at its base; shift up so
	# its base sits at the gauge center.
	var pivot := Node3D.new()
	pivot.name = "NeedlePivot"
	root.add_child(pivot)
	pivot.position = Vector3(0.0, gauge_y, gauge_z + GAUGE_THICKNESS * 0.6)
	pivot.rotation = Vector3(0.0, 0.0, deg_to_rad(needle_angle_deg))
	needle.position = Vector3(0.0, GAUGE_NEEDLE_LENGTH * 0.5, 0.0)
	pivot.add_child(needle)


func _build_specimen() -> void:
	# Floating sphere in the chamber center.
	var spec := MeshInstance3D.new()
	spec.name = "Specimen"
	var sm := SphereMesh.new()
	sm.radius = SPECIMEN_RADIUS
	sm.height = SPECIMEN_RADIUS * 2.0
	spec.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = specimen_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(specimen_color.r, specimen_color.g, specimen_color.b)
	mat.emission_energy_multiplier = 0.8
	mat.roughness = 0.3
	mat.metallic = 0.1
	spec.material_override = mat
	spec.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Float around the chamber's vertical middle.
	var body_height: float = jar_height * (1.0 - DOME_FRACTION)
	var y: float = platform_height + body_height * 0.55
	spec.position = Vector3(0.0, y, 0.0)
	add_child(spec)


func _build_accent_stripe() -> void:
	# Thin emissive ring around the top edge of the platform — approximated
	# with a short cylinder slightly wider than the platform.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var cm := CylinderMesh.new()
	cm.top_radius = platform_radius + PLATFORM_RIM_DEPTH
	cm.bottom_radius = platform_radius + PLATFORM_RIM_DEPTH
	cm.height = PLATFORM_RIM_HEIGHT
	strip.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, platform_height - PLATFORM_RIM_HEIGHT * 0.5, 0.0)
	add_child(strip)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
