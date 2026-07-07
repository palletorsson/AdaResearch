extends Node3D
class_name TestTubeRack

# @identity
# essence: a small bench-top tube rack — wood-and-glass vocabulary borrowed from chemistry classrooms. A pale wooden base with four short corner pillars holding an upper plate, a single row of evenly-spaced glass test tubes slotted through the upper plate and resting in the base, the first few tubes carrying coloured content (sickly green, suspended at the bottom), an emissive accent strip running along the front of the base. Modest, classroom-scale, almost domestic against the rest of the lab
# desire: every lab wants a way to display ITERATION — a row of identical containers showing variation. The rack wants to be a small museum of "the same thing measured many times". Each tube is a sample; the rack is the comparison. The row exposes how the work is structured: by trial, not by triumph
# critical_parameter: tube_content_count — zero tubes filled = SETUP, all tubes filled = COMPLETED RUN, partial fill (default 3) = MID-EXPERIMENT. The rack is a tiny chronicle. The number of filled tubes encodes how far the experiment has progressed. Same shape, three different states of being-in-process
# triggers: _ready() builds base + corner posts + upper plate + tubes (with optional content) + accent strip; apply_grid_config rebuilds
# emerges: empty rack reads STERILE, AWAITING. Half-filled rack reads ACTIVE EXPERIMENT. Fully-filled rack reads COMPLETED, AWAITING ANALYSIS. The artifact is a clock for the experimental cycle
# needs: rectangular wooden base [present]; four corner posts [present]; upper holding plate [present]; a single row of test tubes evenly spaced [present]; subset of tubes contain coloured liquid [present]; accent strip along the front of the base [present]
# relationships: peer to specimen_jar (jar = single, named subject; rack = many, indexed samples — the difference between PORTRAIT and SERIES); cousin to microscope (the rack PRODUCES specimens; the microscope LOOKS at one of them); sibling to large_table (the rack is one of the things tables are FOR — bench-scale containers of bench-scale work); the lab's vocabulary of SERIAL MEASUREMENT
# truth: a test tube rack is the architectural form of REPEATED ATTEMPTS. It says: this is a thing where one measurement is never enough. The row is the assertion that knowledge is not a point but a distribution. The classroom-wood and glass refuse the steel-and-screens monumentality of the rest of the lab — the rack is what science actually looks like most of the time

## A bench-top wooden test tube rack with a single row of glass tubes.
##
## Built procedurally from DNA exports. Origin is at the bottom-center
## of the rack base, on the floor or a tabletop. Tubes face +Y (point
## upward). The rack's long axis runs along +X. The accent strip sits
## on the +Z face of the base — the front of the rack.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var rack_width: float = 0.32          # X — long axis
@export var rack_depth: float = 0.10          # Z — short axis
@export var rack_height: float = 0.18         # Y — overall rack height

@export_group("Tubes")
@export_range(3, 12) var tube_count: int = 6
@export var tube_height: float = 0.14
@export var tube_radius: float = 0.012
## How many tubes (from the leftmost) contain liquid content.
@export_range(0, 12) var tube_content_count: int = 3

@export_group("Color")
## Light wood for the rack body.
@export var rack_color: Color = Color(0.78, 0.62, 0.42)
## Faint blue translucent glass.
@export var tube_glass_color: Color = Color(0.78, 0.88, 0.94, 0.30)
## Sickly green default content.
@export var content_color: Color = Color(0.45, 0.85, 0.35, 0.92)
## Portal orange accent strip on the front of the base.
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

# ── Constants ─────────────────────────────────────────────────────────

const BASE_HEIGHT_FACTOR: float = 0.25         # vs rack_height
const POST_THICKNESS: float = 0.012
const UPPER_PLATE_THICKNESS: float = 0.012
const TUBE_BOTTOM_INSET: float = 0.008         # how far above base top the tube bottom sits
const ACCENT_STRIP_HEIGHT: float = 0.010
const ACCENT_STRIP_DEPTH: float = 0.004

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_rack()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_rack()


func _read_metadata_overrides() -> void:
	if has_meta("config_rack_width"):
		rack_width = float(str(get_meta("config_rack_width")))
	if has_meta("config_rack_depth"):
		rack_depth = float(str(get_meta("config_rack_depth")))
	if has_meta("config_rack_height"):
		rack_height = float(str(get_meta("config_rack_height")))
	if has_meta("config_tube_count"):
		tube_count = int(str(get_meta("config_tube_count")))
	if has_meta("config_tube_height"):
		tube_height = float(str(get_meta("config_tube_height")))
	if has_meta("config_tube_radius"):
		tube_radius = float(str(get_meta("config_tube_radius")))
	if has_meta("config_tube_content_count"):
		tube_content_count = int(str(get_meta("config_tube_content_count")))
	if has_meta("config_rack_color"):
		rack_color = _parse_color(str(get_meta("config_rack_color")), rack_color)
	if has_meta("config_tube_glass_color"):
		tube_glass_color = _parse_color(str(get_meta("config_tube_glass_color")), tube_glass_color)
	if has_meta("config_content_color"):
		content_color = _parse_color(str(get_meta("config_content_color")), content_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_rack() -> void:
	_built = true
	_build_base()
	_build_corner_posts()
	_build_upper_plate()
	_build_tubes()
	_build_accent_strip()


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := BoxMesh.new()
	var bh: float = rack_height * BASE_HEIGHT_FACTOR
	mesh.size = Vector3(rack_width, bh, rack_depth)
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = rack_color
	mat.roughness = 0.7
	mat.metallic = 0.05
	base.material_override = mat
	base.position = Vector3(0.0, bh * 0.5, 0.0)
	add_child(base)


func _build_corner_posts() -> void:
	# Four thin vertical posts at the corners of the rack, between base and upper plate.
	var root := Node3D.new()
	root.name = "Posts"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = rack_color.darkened(0.15)
	mat.roughness = 0.6
	mat.metallic = 0.1

	var bh: float = rack_height * BASE_HEIGHT_FACTOR
	var post_h: float = rack_height - bh - UPPER_PLATE_THICKNESS
	var x_inset: float = POST_THICKNESS * 0.5 + 0.012
	var z_inset: float = POST_THICKNESS * 0.5 + 0.012

	var corners := [
		Vector3(rack_width * 0.5 - x_inset, 0.0, rack_depth * 0.5 - z_inset),
		Vector3(-rack_width * 0.5 + x_inset, 0.0, rack_depth * 0.5 - z_inset),
		Vector3(rack_width * 0.5 - x_inset, 0.0, -rack_depth * 0.5 + z_inset),
		Vector3(-rack_width * 0.5 + x_inset, 0.0, -rack_depth * 0.5 + z_inset),
	]

	for i in range(corners.size()):
		var post := MeshInstance3D.new()
		post.name = "Post_%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(POST_THICKNESS, post_h, POST_THICKNESS)
		post.mesh = m
		post.material_override = mat
		var c: Vector3 = corners[i]
		post.position = Vector3(c.x, bh + post_h * 0.5, c.z)
		root.add_child(post)


func _build_upper_plate() -> void:
	# Holding plate where the tubes pass through; same footprint as base.
	var plate := MeshInstance3D.new()
	plate.name = "UpperPlate"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rack_width, UPPER_PLATE_THICKNESS, rack_depth)
	plate.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = rack_color
	mat.roughness = 0.65
	mat.metallic = 0.05
	plate.material_override = mat
	plate.position = Vector3(0.0, rack_height - UPPER_PLATE_THICKNESS * 0.5, 0.0)
	add_child(plate)


func _build_tubes() -> void:
	var tubes_root := Node3D.new()
	tubes_root.name = "Tubes"
	add_child(tubes_root)

	# Translucent glass material for tubes.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = tube_glass_color
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.12
	glass.metallic = 0.0
	glass.emission_enabled = true
	glass.emission = Color(tube_glass_color.r, tube_glass_color.g, tube_glass_color.b)
	glass.emission_energy_multiplier = 0.08
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Content material — solid emissive sickly liquid.
	var liquid := StandardMaterial3D.new()
	liquid.albedo_color = content_color
	liquid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if content_color.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
	liquid.roughness = 0.30
	liquid.metallic = 0.05
	liquid.emission_enabled = true
	liquid.emission = content_color
	liquid.emission_energy_multiplier = 0.55
	liquid.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var n: int = clampi(tube_count, 1, 24)
	var bh: float = rack_height * BASE_HEIGHT_FACTOR
	# Tubes are placed in a row along +X. Useful X extent is the rack width minus the corner inset.
	var usable_x: float = rack_width - 0.06
	var step: float = 0.0
	if n > 1:
		step = usable_x / float(n - 1)
	var x_start: float = -usable_x * 0.5

	# Tube bottom sits just above base top; tube extends upward through upper plate.
	var bottom_y: float = bh + TUBE_BOTTOM_INSET
	var clamped_content_count: int = clampi(tube_content_count, 0, n)

	for i in range(n):
		var tube := MeshInstance3D.new()
		tube.name = "Tube_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = tube_radius
		cm.bottom_radius = tube_radius
		cm.height = tube_height
		tube.mesh = cm
		tube.material_override = glass
		var x: float = x_start + step * float(i) if n > 1 else 0.0
		tube.position = Vector3(x, bottom_y + tube_height * 0.5, 0.0)
		tubes_root.add_child(tube)

		# First N tubes contain content — a shorter cylinder near the bottom of the tube.
		if i < clamped_content_count:
			var content := MeshInstance3D.new()
			content.name = "Content_%d" % i
			var ccm := CylinderMesh.new()
			ccm.top_radius = tube_radius * 0.86
			ccm.bottom_radius = tube_radius * 0.86
			var content_h: float = tube_height * 0.45
			ccm.height = content_h
			content.mesh = ccm
			content.material_override = liquid
			content.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			content.position = Vector3(x, bottom_y + content_h * 0.5 + 0.004, 0.0)
			tubes_root.add_child(content)


func _build_accent_strip() -> void:
	# Emissive Portal-orange strip along the +Z (front) face of the base.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rack_width * 0.94, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bh: float = rack_height * BASE_HEIGHT_FACTOR
	strip.position = Vector3(0.0, bh * 0.5, rack_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
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
