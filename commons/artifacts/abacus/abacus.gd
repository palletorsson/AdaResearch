extends Node3D
class_name LabAbacus

# @identity
# essence: a rectangular wooden frame holding N vertical steel rods, each rod
#   threaded with M small spherical beads. Per rod a configurable count of
#   beads have been pushed to the TOP (accent color); the remainder rest at
#   the BOTTOM (dark wood). Each rod is a DIGIT, the up-beads are the DIGIT
#   VALUE, and the row of digits across the rods is a POSITIONAL NUMBER. By
#   default the up-counts encode π to 7 digits (3, 1, 4, 1, 5, 9, 2). In the
#   lab's grammar the abacus is the ALGORITHM OF POSITIONAL NUMERALS — the
#   place-value representation of integers in object form.
# desire: every lab that teaches representation needs an artifact that proves
#   "a number" is not a single thing but a STRING OF DIGITS each weighted by
#   a power of the base. The abacus wants to be the smallest physical
#   demonstration that 314 ≠ 143 — that position carries meaning. Move a
#   bead, change a digit; change a digit, change the number
# critical_parameter: bead_positions — this IS the number the abacus
#   represents. Combined with beads_per_rod (the base or capacity per digit)
#   it ENCODES the digit sequence. Change bead_positions and you change the
#   number; change beads_per_rod and you change the BASE (binary at 1,
#   decimal at 9, etc.)
# triggers: _ready() builds frame + rods + beads at high/low positions;
#   apply_grid_config rebuilds
# emerges: default π reads PI / KNOWN-CONSTANT. All-rods-zero reads ZERO /
#   GROUND. All-rods-max reads OVERFLOW / FULL. Same prop, the bead pattern
#   IS the number
# relationships: peer to wall_clock (both ENCODE A QUANTITY IN POSITION — the
#   clock encodes time as hand angles, the abacus encodes number as bead
#   heights); sibling to probability_box (both make a discrete tally
#   physically legible); cousin to map_table (both name the IDEA OF AN INDEX
#   — the table is spatial index, the abacus is positional index)
# truth: a positional numeral system is the rule that any natural number can
#   be written as a finite string of digits where each digit's contribution
#   is value × base^position. The abacus IS that rule embodied — the rod IS
#   the position, the bead count IS the digit, and the assembled rack IS
#   the number. The beads do not LIE about which digit is which — the rod
#   defines the place.

## A classical abacus — wooden frame, vertical rods, beads at high/low
## positions encoding a positional numeral.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the frame. Frame lies in the XY plane, faces +Z (the viewer side). Rod
## index 0 is the LEFTMOST (most significant) digit by convention.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Frame")
@export var frame_width: float = 0.35
@export var frame_height: float = 0.20
@export var frame_depth: float = 0.025
@export var frame_color: Color = Color(0.78, 0.62, 0.42)

@export_group("Rods")
@export_range(3, 10) var rod_count: int = 7
@export var rod_color: Color = Color(0.30, 0.30, 0.32)

@export_group("Beads")
@export_range(4, 10) var beads_per_rod: int = 5
@export var bead_radius: float = 0.012
@export var bead_color_low: Color = Color(0.30, 0.20, 0.15)
@export var bead_color_high: Color = Color(0.95, 0.20, 0.20)
@export var bead_positions: PackedInt32Array = PackedInt32Array([3, 1, 4, 1, 5, 9, 2])

@export_group("Accent")
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

# ── Constants ─────────────────────────────────────────────────────────

const FRAME_RAIL_THICKNESS: float = 0.018
const ROD_RADIUS: float = 0.0030
const ROD_INSET_TOP: float = 0.014
const ROD_INSET_BOTTOM: float = 0.014
const ROD_MARGIN_X: float = 0.028
const ACCENT_STRIP_HEIGHT: float = 0.006
const ACCENT_STRIP_DEPTH: float = 0.004
const BEAD_GAP_FACTOR: float = 1.05

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_abacus()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_abacus()


func _read_metadata_overrides() -> void:
	if has_meta("config_frame_width"):
		frame_width = float(String(get_meta("config_frame_width")))
	if has_meta("config_frame_height"):
		frame_height = float(String(get_meta("config_frame_height")))
	if has_meta("config_frame_depth"):
		frame_depth = float(String(get_meta("config_frame_depth")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(String(get_meta("config_frame_color")), frame_color)
	if has_meta("config_rod_count"):
		rod_count = int(String(get_meta("config_rod_count")))
	if has_meta("config_rod_color"):
		rod_color = _parse_color(String(get_meta("config_rod_color")), rod_color)
	if has_meta("config_beads_per_rod"):
		beads_per_rod = int(String(get_meta("config_beads_per_rod")))
	if has_meta("config_bead_radius"):
		bead_radius = float(String(get_meta("config_bead_radius")))
	if has_meta("config_bead_color_low"):
		bead_color_low = _parse_color(String(get_meta("config_bead_color_low")), bead_color_low)
	if has_meta("config_bead_color_high"):
		bead_color_high = _parse_color(String(get_meta("config_bead_color_high")), bead_color_high)
	if has_meta("config_bead_positions"):
		bead_positions = _parse_int_array(String(get_meta("config_bead_positions")), bead_positions)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_abacus() -> void:
	_built = true
	_build_frame()
	_build_rods_and_beads()
	_build_accent_strip()


func _build_frame() -> void:
	# Frame = 4 rails forming an open rectangle in the XY plane, depth along Z.
	var root := Node3D.new()
	root.name = "Frame"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.65
	mat.metallic = 0.0

	# Top rail.
	var top := MeshInstance3D.new()
	top.name = "TopRail"
	var tm := BoxMesh.new()
	tm.size = Vector3(frame_width, FRAME_RAIL_THICKNESS, frame_depth)
	top.mesh = tm
	top.material_override = mat
	top.position = Vector3(0.0, frame_height - FRAME_RAIL_THICKNESS * 0.5, 0.0)
	root.add_child(top)

	# Bottom rail.
	var bot := MeshInstance3D.new()
	bot.name = "BottomRail"
	var bm := BoxMesh.new()
	bm.size = Vector3(frame_width, FRAME_RAIL_THICKNESS, frame_depth)
	bot.mesh = bm
	bot.material_override = mat
	bot.position = Vector3(0.0, FRAME_RAIL_THICKNESS * 0.5, 0.0)
	root.add_child(bot)

	# Left rail.
	var left := MeshInstance3D.new()
	left.name = "LeftRail"
	var lm := BoxMesh.new()
	lm.size = Vector3(FRAME_RAIL_THICKNESS, frame_height, frame_depth)
	left.mesh = lm
	left.material_override = mat
	left.position = Vector3(-frame_width * 0.5 + FRAME_RAIL_THICKNESS * 0.5, frame_height * 0.5, 0.0)
	root.add_child(left)

	# Right rail.
	var right := MeshInstance3D.new()
	right.name = "RightRail"
	var rm := BoxMesh.new()
	rm.size = Vector3(FRAME_RAIL_THICKNESS, frame_height, frame_depth)
	right.mesh = rm
	right.material_override = mat
	right.position = Vector3(frame_width * 0.5 - FRAME_RAIL_THICKNESS * 0.5, frame_height * 0.5, 0.0)
	root.add_child(right)


func _build_rods_and_beads() -> void:
	var root := Node3D.new()
	root.name = "RodsAndBeads"
	add_child(root)

	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = rod_color
	rod_mat.roughness = 0.30
	rod_mat.metallic = 0.85

	var bead_low_mat := StandardMaterial3D.new()
	bead_low_mat.albedo_color = bead_color_low
	bead_low_mat.roughness = 0.55
	bead_low_mat.metallic = 0.0

	var bead_high_mat := StandardMaterial3D.new()
	bead_high_mat.albedo_color = bead_color_high
	bead_high_mat.roughness = 0.45
	bead_high_mat.metallic = 0.15
	bead_high_mat.emission_enabled = true
	bead_high_mat.emission = bead_color_high
	bead_high_mat.emission_energy_multiplier = 0.20
	bead_high_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Vertical extent for rods/beads.
	var rod_top_y: float = frame_height - ROD_INSET_TOP
	var rod_bot_y: float = ROD_INSET_BOTTOM
	var rod_h: float = rod_top_y - rod_bot_y
	if rod_h <= 0.0:
		return
	var rod_cy: float = (rod_top_y + rod_bot_y) * 0.5

	# Horizontal spacing of rods.
	var n_rods: int = clampi(rod_count, 1, 32)
	var avail_w: float = frame_width - ROD_MARGIN_X * 2.0
	var dx: float = avail_w
	if n_rods > 1:
		dx = avail_w / float(n_rods - 1)
	var x0: float = -avail_w * 0.5

	var bpr: int = clampi(beads_per_rod, 1, 64)
	var bead_step: float = bead_radius * 2.0 * BEAD_GAP_FACTOR
	# How far the beads can travel — the stack of bpr beads must fit in rod_h.
	var stack_len: float = bead_step * float(bpr)
	if stack_len > rod_h:
		# Shrink the bead step to fit.
		bead_step = rod_h / float(bpr)

	for r in range(n_rods):
		var x: float = 0.0
		if n_rods > 1:
			x = x0 + dx * float(r)
		# Rod.
		var rod := MeshInstance3D.new()
		rod.name = "Rod_%d" % r
		var rm := CylinderMesh.new()
		rm.top_radius = ROD_RADIUS
		rm.bottom_radius = ROD_RADIUS
		rm.height = rod_h
		rod.mesh = rm
		rod.material_override = rod_mat
		rod.position = Vector3(x, rod_cy, 0.0)
		root.add_child(rod)

		# Number of beads in the HIGH position on this rod.
		var high_count: int = 0
		if r < bead_positions.size():
			high_count = clampi(bead_positions[r], 0, bpr)
		var low_count: int = bpr - high_count

		# Place high beads from the TOP downward.
		for j in range(high_count):
			var by_high: float = rod_top_y - bead_step * (float(j) + 0.5)
			_place_bead(root, x, by_high, bead_high_mat, "BeadH_%d_%d" % [r, j])

		# Place low beads from the BOTTOM upward.
		for k in range(low_count):
			var by_low: float = rod_bot_y + bead_step * (float(k) + 0.5)
			_place_bead(root, x, by_low, bead_low_mat, "BeadL_%d_%d" % [r, k])


func _place_bead(parent: Node3D, x: float, y: float, mat: StandardMaterial3D, n: String) -> void:
	var bead := MeshInstance3D.new()
	bead.name = n
	var mesh := SphereMesh.new()
	mesh.radius = bead_radius
	mesh.height = bead_radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	bead.mesh = mesh
	bead.material_override = mat
	bead.position = Vector3(x, y, 0.0)
	parent.add_child(bead)


func _build_accent_strip() -> void:
	# Thin emissive stripe across the bottom rail's front face.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(frame_width * 0.85, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, FRAME_RAIL_THICKNESS * 0.5, frame_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5 - 0.001)
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


func _parse_int_array(s: String, fallback: PackedInt32Array) -> PackedInt32Array:
	var trimmed: String = s.strip_edges()
	if trimmed.is_empty():
		return fallback
	# Accept either "3,1,4,1,5,9,2" or "[3,1,4,1,5,9,2]".
	if trimmed.begins_with("["):
		trimmed = trimmed.substr(1, trimmed.length() - 1)
	if trimmed.ends_with("]"):
		trimmed = trimmed.substr(0, trimmed.length() - 1)
	var parts := trimmed.split(",")
	var out := PackedInt32Array()
	for p in parts:
		var pp: String = p.strip_edges()
		if pp.is_empty():
			continue
		out.append(int(pp))
	if out.is_empty():
		return fallback
	return out
