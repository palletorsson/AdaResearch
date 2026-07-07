extends Node3D
class_name LabPrism

# @identity
# essence: a small triangular prism of faintly-emissive translucent glass on a
#   dark cylindrical pedestal, with a single emissive white beam entering from
#   -X and a fan of N rainbow beams exiting toward +X, hues evenly spaced from
#   red to violet — Aperture / spectroscope vocabulary. In the lab's grammar,
#   the prism IS SPECTRAL DECOMPOSITION (Fourier in glass) in object form.
#   White beam = composite signal. Rainbow fan = its basis decomposition.
#   Wavelength = frequency. Position in the fan = amplitude per band.
# desire: every lab that teaches frequency-domain thinking needs an artifact
#   that proves white light is ALREADY many colors — that decomposition is not
#   a transformation you do TO a signal but a TRUTH the signal already holds.
#   The prism wants to be the smallest possible Fourier transform you can put
#   on a shelf
# critical_parameter: spectrum_band_count + light_glow — together they ARE the
#   algorithm's key knob. band_count is the resolution of the decomposition;
#   light_glow is the intensity of the realised reading. Same prism, change the
#   bands and you change the FFT bin count
# triggers: _ready() builds pedestal (optional) + prism body + incoming beam
#   (optional) + spectrum_band_count outgoing rainbow beams (optional) + accent;
#   apply_grid_config rebuilds
# emerges: 3 bands reads RGB FILTER. 7 bands reads VISIBLE SPECTRUM. 16 bands
#   reads HI-FI FOURIER. Same prism, the algorithm's resolution changes with the
#   count
# relationships: peer to map_table (both NAME an algorithm by laying it flat —
#   table on wood, prism in glass); sibling to specimen_jar (both contain
#   without trapping — jar contains matter, prism contains light); cousin to
#   pendulum (both freeze a continuous phenomenon at one moment); the lab's
#   confession that NOTHING IS SIMPLE AT THE BASIS
# truth: spectral decomposition is the claim that ANY signal can be written as
#   a sum of pure frequencies and that the prism (or the FFT) finds them. The
#   prism IS that rule embodied — the white beam is the time-domain signal, the
#   rainbow fan is the frequency-domain spectrum, and the dispersion of the
#   glass IS the basis transform.

## A small triangular glass prism on a dark pedestal, with an incoming
## white beam and a fanned-out rainbow spectrum.
##
## Built procedurally from DNA exports. Origin is at the bottom center of
## the pedestal (or of the prism, if pedestal_visible is false). Light
## enters from -X and exits to +X.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Prism")
@export var prism_size: float = 0.10
@export var prism_height: float = 0.18
@export var glass_color: Color = Color(0.88, 0.92, 0.96, 0.30)
@export var glass_emission: float = 0.08

@export_group("Pedestal")
@export var pedestal_visible: bool = true
@export var pedestal_radius: float = 0.07
@export var pedestal_height: float = 0.03
@export var pedestal_color: Color = Color(0.22, 0.22, 0.25)

@export_group("Light In")
@export var light_in_visible: bool = true
@export var light_in_color: Color = Color(1.0, 0.98, 0.92)

@export_group("Light Out")
@export var light_out_visible: bool = true
@export_range(2, 12) var spectrum_band_count: int = 7
@export var light_glow: float = 1.8

@export_group("Accent")
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

# ── Constants ─────────────────────────────────────────────────────────

const BEAM_RADIUS: float = 0.003
const BEAM_IN_LENGTH_FACTOR: float = 2.0       # vs prism_size
const BEAM_OUT_LENGTH_FACTOR: float = 2.5      # vs prism_size
const SPECTRUM_FAN_DEG: float = 18.0           # total fan angle for outgoing beams
const ACCENT_STRIP_HEIGHT: float = 0.004
const ACCENT_STRIP_DEPTH: float = 0.003

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_prism_artifact()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_prism_artifact()


func _read_metadata_overrides() -> void:
	if has_meta("config_prism_size"):
		prism_size = float(str(get_meta("config_prism_size")))
	if has_meta("config_prism_height"):
		prism_height = float(str(get_meta("config_prism_height")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_glass_emission"):
		glass_emission = float(str(get_meta("config_glass_emission")))
	if has_meta("config_pedestal_visible"):
		pedestal_visible = _parse_bool(str(get_meta("config_pedestal_visible")), pedestal_visible)
	if has_meta("config_pedestal_radius"):
		pedestal_radius = float(str(get_meta("config_pedestal_radius")))
	if has_meta("config_pedestal_height"):
		pedestal_height = float(str(get_meta("config_pedestal_height")))
	if has_meta("config_pedestal_color"):
		pedestal_color = _parse_color(str(get_meta("config_pedestal_color")), pedestal_color)
	if has_meta("config_light_in_visible"):
		light_in_visible = _parse_bool(str(get_meta("config_light_in_visible")), light_in_visible)
	if has_meta("config_light_in_color"):
		light_in_color = _parse_color(str(get_meta("config_light_in_color")), light_in_color)
	if has_meta("config_light_out_visible"):
		light_out_visible = _parse_bool(str(get_meta("config_light_out_visible")), light_out_visible)
	if has_meta("config_spectrum_band_count"):
		spectrum_band_count = int(str(get_meta("config_spectrum_band_count")))
	if has_meta("config_light_glow"):
		light_glow = float(str(get_meta("config_light_glow")))
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_prism_artifact() -> void:
	_built = true
	if pedestal_visible:
		_build_pedestal()
	_build_prism_body()
	if light_in_visible:
		_build_light_in()
	if light_out_visible:
		_build_spectrum()
	if pedestal_visible:
		_build_accent_stripe()


func _prism_center_y() -> float:
	# Center of the prism along Y. If there is a pedestal, prism sits on top.
	var base_y: float = pedestal_height if pedestal_visible else 0.0
	return base_y + prism_size * 0.5


func _build_pedestal() -> void:
	var ped := MeshInstance3D.new()
	ped.name = "Pedestal"
	var mesh := CylinderMesh.new()
	mesh.top_radius = pedestal_radius
	mesh.bottom_radius = pedestal_radius
	mesh.height = pedestal_height
	ped.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.roughness = 0.45
	mat.metallic = 0.6
	ped.material_override = mat
	ped.position = Vector3(0.0, pedestal_height * 0.5, 0.0)
	add_child(ped)


func _build_prism_body() -> void:
	# A triangular PrismMesh oriented so its triangular cross-section sits in
	# the XY plane (the axis of the prism runs along Z, length = prism_height).
	# The X axis becomes the dispersion axis: light enters from -X, exits to +X.
	var prism := MeshInstance3D.new()
	prism.name = "PrismBody"
	var mesh := PrismMesh.new()
	mesh.size = Vector3(prism_size, prism_size, prism_height)
	mesh.left_to_right = 0.5
	prism.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	if glass_color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = max(0.0, glass_emission)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	prism.material_override = mat
	prism.position = Vector3(0.0, _prism_center_y(), 0.0)
	add_child(prism)


func _build_light_in() -> void:
	# Thin emissive cylinder pointing along X, extending from the prism's -X
	# face outward in the -X direction.
	var beam := MeshInstance3D.new()
	beam.name = "BeamIn"
	var length: float = prism_size * BEAM_IN_LENGTH_FACTOR
	var cm := CylinderMesh.new()
	cm.top_radius = BEAM_RADIUS
	cm.bottom_radius = BEAM_RADIUS
	cm.height = length
	beam.mesh = cm
	# Cylinder default axis is +Y; rotate to align with the X axis.
	beam.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = light_in_color
	mat.emission_enabled = true
	mat.emission = light_in_color
	mat.emission_energy_multiplier = max(0.0, light_glow) * 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	beam.material_override = mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Center of the beam at the midpoint of its length, just outside the prism's -X face.
	var x_face: float = -prism_size * 0.5
	var x_center: float = x_face - length * 0.5
	beam.position = Vector3(x_center, _prism_center_y(), 0.0)
	add_child(beam)


func _build_spectrum() -> void:
	# N emissive cylinder beams exiting the +X face, fanned vertically with
	# rainbow hues. Each beam has its own axis: rotate first to lie along +X,
	# then tilt around Z by a per-beam angle so they spread in the XY plane.
	var root := Node3D.new()
	root.name = "Spectrum"
	add_child(root)

	var n: int = clampi(spectrum_band_count, 2, 12)
	var length: float = prism_size * BEAM_OUT_LENGTH_FACTOR
	var fan_rad: float = deg_to_rad(SPECTRUM_FAN_DEG)
	var x_face: float = prism_size * 0.5
	var cy: float = _prism_center_y()

	for i in range(n):
		var t: float = float(i) / float(max(1, n - 1))
		# Hue 0.0 = red, ~0.83 = violet — span red→violet.
		var hue: float = lerpf(0.0, 0.83, t)
		var col := Color.from_hsv(hue, 0.95, 1.0)

		# Tilt: t=0 (red) → +fan_rad/2 (above), t=1 (violet) → -fan_rad/2 (below).
		# Reverse to match red-on-top dispersion convention.
		var tilt: float = lerpf(fan_rad * 0.5, -fan_rad * 0.5, t)

		var beam := MeshInstance3D.new()
		beam.name = "Band_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = BEAM_RADIUS
		cm.bottom_radius = BEAM_RADIUS
		cm.height = length
		beam.mesh = cm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = max(0.0, light_glow) * 2.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		beam.material_override = mat
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Orient: cylinder default axis is +Y. We want the band to lie along the
		# direction (cos(tilt), sin(tilt), 0) in the XY plane. Rotation about Z
		# by (90° - tilt_deg) does this: at tilt=0, beam aligns with +X.
		# Equivalent quaternion-free derivation: rotate +Y by -90° around Z to
		# align with +X, then rotate by +tilt around Z to tilt up.
		beam.rotation = Vector3(0.0, 0.0, deg_to_rad(-90.0) + tilt)

		# Compute beam center: starts at (x_face, cy, 0), goes outward in
		# direction (cos(tilt), sin(tilt), 0). Center is at start + dir * length/2.
		var dir := Vector3(cos(tilt), sin(tilt), 0.0)
		var center := Vector3(x_face, cy, 0.0) + dir * (length * 0.5)
		beam.position = center
		root.add_child(beam)


func _build_accent_stripe() -> void:
	# Thin emissive stripe ringing the front of the pedestal.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var mesh := TorusMesh.new()
	mesh.inner_radius = pedestal_radius - ACCENT_STRIP_DEPTH * 1.5
	mesh.outer_radius = pedestal_radius + ACCENT_STRIP_DEPTH * 0.5
	mesh.ring_segments = 6
	mesh.rings = 24
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, pedestal_height - ACCENT_STRIP_HEIGHT * 0.5, 0.0)
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


func _parse_bool(s: String, fallback: bool) -> bool:
	var v := s.to_lower()
	if v in ["true", "1", "yes", "on"]:
		return true
	if v in ["false", "0", "no", "off"]:
		return false
	return fallback
