extends Node3D
class_name FumeHood

# @identity
# essence: a glass-fronted chemistry enclosure — Black Mesa / Aperture lab vocabulary for "the danger is INSIDE the box and we are looking AT it through glass". U-shaped enclosure (3 solid walls + ceiling, open front), a translucent sash that slides up to reveal the worktop within, an interior emissive ceiling-light, and a thin Portal-orange accent stripe along the front frame.
# desire: the fume hood wants to BE a viewing membrane. The closed sash says "experiment running, do not disturb"; the open sash says "you may reach in, you may participate". The hood is the consent ritual of laboratory work — the body of the lab learning when to look and when to act.
# critical_parameter: sash_open_amount — 0 reads as "sealed cabinet" (witness only), 0.5 reads as "active station" (reach in to work), 1.0 reads as "open shelf" (the hood as merely decorative). Same enclosure, three completely different room postures.
# triggers: _ready() builds enclosure + worktop + sash + light + frame from exports; apply_grid_config rebuilds
# emerges: closed + interior light on = "containment with secret inside"; half-open + bright interior = "active fume work"; fully open + dim = "decommissioned, props"; bright accent stripe = phase-coded danger
# needs: U-enclosure of BoxMesh walls + ceiling, open front [present]; translucent glass sash BoxMesh that slides up [present]; interior worktop BoxMesh [present]; emissive ceiling light face [present]; dark steel frame edges [present]; accent stripe [present]
# relationships: sibling to large_table (the hood is a table with a sealed lid — the experiment-on-a-table that doesn't trust the room); cousin to large_window (both are a glass-mediated way of seeing across a boundary, but the window faces OUT and the hood faces IN); peer to control_board (the hood is the experiment, the board is the operator — they want each other)
# truth: a fume hood is not just a glass cabinet. It is the architectural admission that some chemistry is too dangerous to share air with. The sash is not a door. The sash is a NEGOTIATION between researcher and reagent.

## A glass-fronted chemistry fume hood.
##
## Built procedurally from DNA. Origin is at the bottom center of the front
## face — the enclosure backs into -Z, the sash and front frame face +Z.
## The sash slides upward by `sash_open_amount * (hood_height - 0.4)`.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var hood_width: float = 1.6    # X
@export var hood_height: float = 2.1   # Y
@export var hood_depth: float = 0.7    # Z

@export_group("Sash")
## 0 = fully closed, 1 = fully open (slid up to the top of the frame).
@export_range(0.0, 1.0, 0.01) var sash_open_amount: float = 0.5

@export_group("Color")
@export var interior_color: Color = Color(0.74, 0.74, 0.76)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)
@export var frame_color: Color = Color(0.18, 0.18, 0.22)
@export var light_color: Color = Color(0.92, 0.96, 1.0)

@export_group("Light")
@export var interior_light: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.04
const WORKTOP_HEIGHT: float = 0.85
const WORKTOP_THICKNESS: float = 0.05
const SASH_THICKNESS: float = 0.018
const SASH_BOTTOM_MARGIN: float = 0.05      # sash rests slightly above worktop
const FRAME_THICKNESS: float = 0.04
const ACCENT_STRIP_HEIGHT: float = 0.014
const ACCENT_STRIP_DEPTH: float = 0.006

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_hood()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_hood()


func _read_metadata_overrides() -> void:
	if has_meta("config_hood_width"):
		hood_width = float(String(get_meta("config_hood_width")))
	if has_meta("config_hood_height"):
		hood_height = float(String(get_meta("config_hood_height")))
	if has_meta("config_hood_depth"):
		hood_depth = float(String(get_meta("config_hood_depth")))
	if has_meta("config_sash_open_amount"):
		sash_open_amount = clamp(float(String(get_meta("config_sash_open_amount"))), 0.0, 1.0)
	if has_meta("config_interior_color"):
		interior_color = _parse_color(String(get_meta("config_interior_color")), interior_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(String(get_meta("config_frame_color")), frame_color)
	if has_meta("config_light_color"):
		light_color = _parse_color(String(get_meta("config_light_color")), light_color)
	if has_meta("config_interior_light"):
		var v := String(get_meta("config_interior_light")).to_lower()
		interior_light = v in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_hood() -> void:
	_built = true
	_build_enclosure()
	_build_worktop()
	if interior_light:
		_build_interior_light()
	_build_sash()
	_build_front_frame()
	_build_accent_strip()


func _build_enclosure() -> void:
	# U-shaped enclosure (3 walls + ceiling, open in front). Origin is at the
	# bottom center of the front face. Back wall sits at z = -hood_depth.
	var enc := Node3D.new()
	enc.name = "Enclosure"
	add_child(enc)

	var interior_mat := StandardMaterial3D.new()
	interior_mat.albedo_color = interior_color
	interior_mat.roughness = 0.55
	interior_mat.metallic = 0.05

	# Back wall
	var back := MeshInstance3D.new()
	back.name = "BackWall"
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(hood_width, hood_height, WALL_THICKNESS)
	back.mesh = back_mesh
	back.material_override = interior_mat
	back.position = Vector3(0.0, hood_height * 0.5, -hood_depth + WALL_THICKNESS * 0.5)
	enc.add_child(back)

	# Left wall (-X)
	var left := MeshInstance3D.new()
	left.name = "LeftWall"
	var left_mesh := BoxMesh.new()
	left_mesh.size = Vector3(WALL_THICKNESS, hood_height, hood_depth)
	left.mesh = left_mesh
	left.material_override = interior_mat
	left.position = Vector3(-hood_width * 0.5 + WALL_THICKNESS * 0.5, hood_height * 0.5, -hood_depth * 0.5)
	enc.add_child(left)

	# Right wall (+X)
	var right := MeshInstance3D.new()
	right.name = "RightWall"
	var right_mesh := BoxMesh.new()
	right_mesh.size = Vector3(WALL_THICKNESS, hood_height, hood_depth)
	right.mesh = right_mesh
	right.material_override = interior_mat
	right.position = Vector3(hood_width * 0.5 - WALL_THICKNESS * 0.5, hood_height * 0.5, -hood_depth * 0.5)
	enc.add_child(right)

	# Ceiling
	var ceil := MeshInstance3D.new()
	ceil.name = "Ceiling"
	var ceil_mesh := BoxMesh.new()
	ceil_mesh.size = Vector3(hood_width, WALL_THICKNESS, hood_depth)
	ceil.mesh = ceil_mesh
	ceil.material_override = interior_mat
	ceil.position = Vector3(0.0, hood_height - WALL_THICKNESS * 0.5, -hood_depth * 0.5)
	enc.add_child(ceil)


func _build_worktop() -> void:
	# Interior worktop at WORKTOP_HEIGHT.
	var top := MeshInstance3D.new()
	top.name = "Worktop"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(hood_width - WALL_THICKNESS * 2.0, WORKTOP_THICKNESS, hood_depth - WALL_THICKNESS)
	top.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.86)
	mat.roughness = 0.4
	mat.metallic = 0.1
	top.material_override = mat
	top.position = Vector3(0.0, WORKTOP_HEIGHT - WORKTOP_THICKNESS * 0.5, -hood_depth * 0.5 + WALL_THICKNESS * 0.25)
	add_child(top)


func _build_interior_light() -> void:
	# Emissive ceiling face — reads as a built-in fluorescent strip.
	var light := MeshInstance3D.new()
	light.name = "InteriorLight"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(hood_width * 0.7, 0.025, hood_depth * 0.5)
	light.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = light_color
	mat.emission_enabled = true
	mat.emission = light_color
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	light.material_override = mat
	light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just under the ceiling, centered along depth.
	light.position = Vector3(0.0, hood_height - WALL_THICKNESS - 0.02, -hood_depth * 0.5)
	add_child(light)


func _build_sash() -> void:
	# Translucent glass sash that slides up by sash_open_amount.
	# When closed, the sash sits from worktop+margin up to the top of the frame.
	var sash_min_y := WORKTOP_HEIGHT + SASH_BOTTOM_MARGIN
	var sash_max_y := hood_height - FRAME_THICKNESS
	var sash_height_closed := sash_max_y - sash_min_y
	if sash_height_closed < 0.1:
		sash_height_closed = 0.1

	# The sash itself doesn't change size — it shifts upward, hiding behind the
	# top frame. Slide range is sash_height_closed - 0.4 so a small lower lip
	# is always visible (reads as physical sash, not a vanishing pane).
	var slide_range: float = max(0.0, hood_height - 0.4)

	var sash := MeshInstance3D.new()
	sash.name = "Sash"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(hood_width - FRAME_THICKNESS * 2.0, sash_height_closed, SASH_THICKNESS)
	sash.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.78, 0.85, 0.32)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.65, 0.78)
	mat.emission_energy_multiplier = 0.18
	mat.roughness = 0.1
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sash.material_override = mat
	sash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var slide_y: float = sash_open_amount * slide_range
	sash.position = Vector3(0.0, sash_min_y + sash_height_closed * 0.5 + slide_y, 0.0)
	add_child(sash)

	# Sash handle — a thin BoxMesh stripe across the bottom of the sash.
	var handle := MeshInstance3D.new()
	handle.name = "SashHandle"
	var hmesh := BoxMesh.new()
	hmesh.size = Vector3(hood_width * 0.6, 0.04, 0.02)
	handle.mesh = hmesh
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = frame_color
	hmat.roughness = 0.4
	hmat.metallic = 0.7
	handle.material_override = hmat
	handle.position = Vector3(0.0, sash_min_y + 0.02 + slide_y, SASH_THICKNESS * 0.5 + 0.012)
	add_child(handle)


func _build_front_frame() -> void:
	# Dark steel frame around the front opening — left post, right post, top header.
	var frame := Node3D.new()
	frame.name = "FrontFrame"
	add_child(frame)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.35
	mat.metallic = 0.75

	# Left post
	var lp := MeshInstance3D.new()
	lp.name = "LeftPost"
	var lpm := BoxMesh.new()
	lpm.size = Vector3(FRAME_THICKNESS, hood_height, FRAME_THICKNESS)
	lp.mesh = lpm
	lp.material_override = mat
	lp.position = Vector3(-hood_width * 0.5 + FRAME_THICKNESS * 0.5, hood_height * 0.5, 0.0)
	frame.add_child(lp)

	# Right post
	var rp := MeshInstance3D.new()
	rp.name = "RightPost"
	var rpm := BoxMesh.new()
	rpm.size = Vector3(FRAME_THICKNESS, hood_height, FRAME_THICKNESS)
	rp.mesh = rpm
	rp.material_override = mat
	rp.position = Vector3(hood_width * 0.5 - FRAME_THICKNESS * 0.5, hood_height * 0.5, 0.0)
	frame.add_child(rp)

	# Top header
	var th := MeshInstance3D.new()
	th.name = "TopHeader"
	var thm := BoxMesh.new()
	thm.size = Vector3(hood_width, FRAME_THICKNESS, FRAME_THICKNESS)
	th.mesh = thm
	th.material_override = mat
	th.position = Vector3(0.0, hood_height - FRAME_THICKNESS * 0.5, 0.0)
	frame.add_child(th)

	# Bottom kick — short solid panel below the worktop so the front doesn't
	# look like it floats over open space.
	var kick := MeshInstance3D.new()
	kick.name = "BottomKick"
	var km := BoxMesh.new()
	km.size = Vector3(hood_width - FRAME_THICKNESS * 2.0, WORKTOP_HEIGHT - FRAME_THICKNESS, FRAME_THICKNESS)
	kick.mesh = km
	kick.material_override = mat
	kick.position = Vector3(0.0, (WORKTOP_HEIGHT - FRAME_THICKNESS) * 0.5, 0.0)
	frame.add_child(kick)


func _build_accent_strip() -> void:
	# Side accent stripe along the bottom of the front frame — sits just under
	# the worktop, runs the full width minus the frame posts.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(hood_width - FRAME_THICKNESS * 2.0, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just above the bottom kick, on the front plane.
	var y := WORKTOP_HEIGHT - ACCENT_STRIP_HEIGHT * 0.5 - 0.02
	strip.position = Vector3(0.0, y, FRAME_THICKNESS * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
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
