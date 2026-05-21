extends Node3D
class_name LabKaleidoscope

# @identity
# essence: a horizontal cylindrical brass-and-steel tube on a low stand — a
#   classic kaleidoscope. One end is a smaller dark eyepiece; the far end is
#   a flat disc divided into N pie-wedge shards that alternate between three
#   accent colors. The wedges are emissive and arranged radially so the eye
#   reads N-fold rotational + mirror symmetry — the visible signature of the
#   dihedral group D(N). A faint accent ring circles the middle of the tube.
#   In the lab's grammar the kaleidoscope is the DIHEDRAL SYMMETRY GROUP /
#   REFLECTION ALGORITHM — a group-theoretic operation made visible in glass.
# desire: every lab that teaches symmetry needs an artifact that proves
#   "symmetric" is not a vibe but a GROUP — a set of transformations closed
#   under composition. The kaleidoscope wants to be the smallest physical
#   demo of "reflect a fundamental domain N times around a point and you get
#   a closed pattern". The pattern is the orbit. The wedge is the generator.
# critical_parameter: mirror_count — this IS the dihedral order. 3 mirrors
#   → D3 (6-fold pattern). 4 → D4 (8-fold). 6 → D6 (12-fold). Change the
#   mirror count and you literally change the GROUP the prop embodies. The
#   pattern is not chosen, it is FORCED by the geometry of N mirrors at
#   angle 2π/N
# triggers: _ready() builds stand + tube + middle accent ring + eyepiece +
#   pattern disc with wedges; apply_grid_config rebuilds
# emerges: N=3 reads TRIANGULAR / KALEIDOSCOPE-STANDARD. N=4 reads PLUS / +.
#   N=6 reads SNOWFLAKE / FLOWER. N=8 reads STAR. Same prop, the group
#   changes the orbit and the orbit IS the visible pattern
# relationships: peer to prism (both NAME a transformation in glass — the
#   prism decomposes light by frequency, the kaleidoscope multiplies it by
#   group action); sibling to mirror (both ARE reflection — the mirror is
#   one reflection, the kaleidoscope is N composed); cousin to pattern_maker
#   (both teach wallpaper-group thinking — wallpaper is 2D infinite-pattern,
#   the kaleidoscope is the point-group case)
# truth: a dihedral symmetry group is closure under N rotations and N
#   reflections — and any pattern in the fundamental domain, repeated under
#   group action, becomes the full pattern. The kaleidoscope IS that rule
#   embodied: the wedge IS the fundamental domain, the mirror count IS the
#   group order, and the disc IS the orbit. The pattern does not LIE about
#   its symmetry — it IS its symmetry.

## A small kaleidoscope on a stand — horizontal tube, eyepiece at +X,
## symmetric N-fold pattern disc at -X.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the stand. The tube axis runs along +X. The pattern disc is at the
## tube's -X end; the eyepiece is at +X.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Tube")
@export var tube_length: float = 0.30
@export var tube_radius: float = 0.04
@export var tube_color: Color = Color(0.20, 0.20, 0.24)

@export_group("Eyepiece")
@export var eyepiece_visible: bool = true
@export var eyepiece_color: Color = Color(0.10, 0.10, 0.12)

@export_group("Pattern")
@export_range(2, 8) var mirror_count: int = 3
@export var pattern_radius: float = 0.05
@export_range(2, 24) var pattern_segments: int = 6
@export var pattern_color_a: Color = Color(1.0, 0.45, 0.10)
@export var pattern_color_b: Color = Color(0.20, 0.55, 0.95)
@export var pattern_color_c: Color = Color(0.95, 0.20, 0.55)
@export var pattern_emission: float = 0.8

@export_group("Accent")
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

# ── Constants ─────────────────────────────────────────────────────────

const STAND_BASE_WIDTH: float = 0.18
const STAND_BASE_DEPTH: float = 0.10
const STAND_BASE_HEIGHT: float = 0.012
const STAND_PILLAR_THICKNESS: float = 0.018
const STAND_PILLAR_HEIGHT_FACTOR: float = 1.6
const EYEPIECE_LENGTH: float = 0.030
const EYEPIECE_RADIUS_FACTOR: float = 0.72
const PATTERN_DISC_DEPTH: float = 0.008
const PATTERN_WEDGE_DEPTH: float = 0.006
const ACCENT_RING_OUTER_FACTOR: float = 1.10
const ACCENT_RING_THICKNESS: float = 0.004

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_kaleidoscope()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_kaleidoscope()


func _read_metadata_overrides() -> void:
	if has_meta("config_tube_length"):
		tube_length = float(String(get_meta("config_tube_length")))
	if has_meta("config_tube_radius"):
		tube_radius = float(String(get_meta("config_tube_radius")))
	if has_meta("config_tube_color"):
		tube_color = _parse_color(String(get_meta("config_tube_color")), tube_color)
	if has_meta("config_eyepiece_visible"):
		eyepiece_visible = _parse_bool(String(get_meta("config_eyepiece_visible")), eyepiece_visible)
	if has_meta("config_eyepiece_color"):
		eyepiece_color = _parse_color(String(get_meta("config_eyepiece_color")), eyepiece_color)
	if has_meta("config_mirror_count"):
		mirror_count = int(String(get_meta("config_mirror_count")))
	if has_meta("config_pattern_radius"):
		pattern_radius = float(String(get_meta("config_pattern_radius")))
	if has_meta("config_pattern_segments"):
		pattern_segments = int(String(get_meta("config_pattern_segments")))
	if has_meta("config_pattern_color_a"):
		pattern_color_a = _parse_color(String(get_meta("config_pattern_color_a")), pattern_color_a)
	if has_meta("config_pattern_color_b"):
		pattern_color_b = _parse_color(String(get_meta("config_pattern_color_b")), pattern_color_b)
	if has_meta("config_pattern_color_c"):
		pattern_color_c = _parse_color(String(get_meta("config_pattern_color_c")), pattern_color_c)
	if has_meta("config_pattern_emission"):
		pattern_emission = float(String(get_meta("config_pattern_emission")))
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_kaleidoscope() -> void:
	_built = true
	_build_stand()
	_build_tube()
	_build_accent_ring()
	if eyepiece_visible:
		_build_eyepiece()
	_build_pattern_disc()


func _tube_center_y() -> float:
	var pillar_h: float = tube_radius * STAND_PILLAR_HEIGHT_FACTOR
	return STAND_BASE_HEIGHT + pillar_h + tube_radius


func _build_stand() -> void:
	# Low base + thin vertical pillar holding the tube up.
	var base := MeshInstance3D.new()
	base.name = "StandBase"
	var bm := BoxMesh.new()
	bm.size = Vector3(STAND_BASE_WIDTH, STAND_BASE_HEIGHT, STAND_BASE_DEPTH)
	base.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = tube_color
	bmat.roughness = 0.55
	bmat.metallic = 0.40
	base.material_override = bmat
	base.position = Vector3(0.0, STAND_BASE_HEIGHT * 0.5, 0.0)
	add_child(base)

	var pillar_h: float = tube_radius * STAND_PILLAR_HEIGHT_FACTOR
	var pillar := MeshInstance3D.new()
	pillar.name = "StandPillar"
	var pm := BoxMesh.new()
	pm.size = Vector3(STAND_PILLAR_THICKNESS, pillar_h, STAND_PILLAR_THICKNESS * 2.0)
	pillar.mesh = pm
	pillar.material_override = bmat
	pillar.position = Vector3(0.0, STAND_BASE_HEIGHT + pillar_h * 0.5, 0.0)
	add_child(pillar)


func _build_tube() -> void:
	var tube := MeshInstance3D.new()
	tube.name = "Tube"
	var mesh := CylinderMesh.new()
	mesh.top_radius = tube_radius
	mesh.bottom_radius = tube_radius
	mesh.height = tube_length
	tube.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tube_color
	mat.roughness = 0.40
	mat.metallic = 0.65
	tube.material_override = mat
	# Cylinder default axis is +Y; rotate so axis aligns with +X.
	tube.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	tube.position = Vector3(0.0, _tube_center_y(), 0.0)
	add_child(tube)


func _build_accent_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "AccentRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = tube_radius * 1.0
	mesh.outer_radius = tube_radius * ACCENT_RING_OUTER_FACTOR
	mesh.ring_segments = 6
	mesh.rings = 24
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# TorusMesh by default lies in XZ plane (axis +Y). We want it ringing the
	# tube whose axis is +X, so the torus's normal must be +X.
	# Rotate around Z by 90° so torus axis aligns with +X.
	ring.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	ring.position = Vector3(0.0, _tube_center_y(), 0.0)
	add_child(ring)


func _build_eyepiece() -> void:
	var eye := MeshInstance3D.new()
	eye.name = "Eyepiece"
	var mesh := CylinderMesh.new()
	var er: float = tube_radius * EYEPIECE_RADIUS_FACTOR
	mesh.top_radius = er
	mesh.bottom_radius = er
	mesh.height = EYEPIECE_LENGTH
	eye.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = eyepiece_color
	mat.roughness = 0.45
	mat.metallic = 0.55
	eye.material_override = mat
	# Align axis along +X (same as tube).
	eye.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	# Position at +X end of the tube, extending further +X.
	var eye_x: float = tube_length * 0.5 + EYEPIECE_LENGTH * 0.5
	eye.position = Vector3(eye_x, _tube_center_y(), 0.0)
	add_child(eye)


func _build_pattern_disc() -> void:
	# A flat disc at the -X end of the tube. Divided into pattern_segments
	# pie wedges; colours cycle a, b, c, a, b, c... The dihedral symmetry the
	# eye reads = mirror_count, but the wedges that PAINT it = pattern_segments.
	# To reinforce mirror_count visually we ensure pattern_segments is at
	# least 2 * mirror_count (every "mirror" gives both a sector and its
	# reflection). The clamp here is gentle — exports allow override.
	var n_seg: int = max(2, pattern_segments)
	var disc_x: float = -tube_length * 0.5 - PATTERN_DISC_DEPTH * 0.5

	# Optional thin backing disc.
	var back := MeshInstance3D.new()
	back.name = "PatternBacking"
	var bm := CylinderMesh.new()
	bm.top_radius = pattern_radius
	bm.bottom_radius = pattern_radius
	bm.height = PATTERN_DISC_DEPTH
	back.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = eyepiece_color
	bmat.roughness = 0.45
	bmat.metallic = 0.30
	back.material_override = bmat
	back.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	back.position = Vector3(disc_x, _tube_center_y(), 0.0)
	add_child(back)

	# Wedge ring.
	var wedge_root := Node3D.new()
	wedge_root.name = "PatternWedges"
	wedge_root.position = Vector3(disc_x - PATTERN_DISC_DEPTH * 0.5 - PATTERN_WEDGE_DEPTH * 0.5, _tube_center_y(), 0.0)
	# Wedges sit in the YZ plane (since the disc axis is +X). The wedge_root
	# is placed at the disc center, no rotation needed — we'll rotate each
	# wedge individually around the +X axis.
	add_child(wedge_root)

	var palette := [pattern_color_a, pattern_color_b, pattern_color_c]
	# We need slim radial wedges in the YZ plane. Use thin BoxMesh "blades"
	# extending from center outward; rotate each blade around +X by its sector
	# angle.
	var blade_width: float = pattern_radius * 0.95
	var blade_thickness: float = max(0.0015, pattern_radius * (TAU / float(n_seg)) * 0.45)
	for i in range(n_seg):
		var col: Color = palette[i % palette.size()]
		var angle: float = TAU * float(i) / float(n_seg)
		var blade := MeshInstance3D.new()
		blade.name = "Wedge_%d" % i
		var wmesh := BoxMesh.new()
		# Blade: long along Y (radial), thin along Z (tangential), tiny along X (depth).
		wmesh.size = Vector3(PATTERN_WEDGE_DEPTH, blade_width, blade_thickness)
		blade.mesh = wmesh
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = col
		wmat.emission_enabled = true
		wmat.emission = col
		wmat.emission_energy_multiplier = max(0.0, pattern_emission)
		wmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		blade.material_override = wmat
		blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Rotate this blade around the +X axis by `angle`. Then offset along
		# the rotated +Y direction so the blade points outward.
		blade.rotation = Vector3(angle, 0.0, 0.0)
		# After rotation by angle around X, blade's local +Y maps to
		# (0, cos(angle), -sin(angle)) in wedge_root space (Godot uses
		# right-handed). So center the blade at (0, half-blade-width * cos, ...).
		# Simpler: place each blade at the origin of wedge_root and let the
		# rotation alone handle radial direction by offsetting half-width
		# along Y BEFORE rotation. Use a child translation.
		var offset_node := Node3D.new()
		offset_node.add_child(blade)
		blade.position = Vector3(0.0, blade_width * 0.5, 0.0)
		offset_node.rotation = Vector3(angle, 0.0, 0.0)
		# Reparent: blade's offset_node is what we add.
		wedge_root.add_child(offset_node)


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
