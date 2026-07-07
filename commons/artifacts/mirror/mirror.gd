extends Node3D
class_name LabMirror

# @identity
# essence: a flat rectangular glass pane in a dark wooden frame, optionally on
#   a small base — a hand mirror or full-length looking-glass standing in the
#   lab. Multi-mirror arrangements compose: "single" (one mirror, identity),
#   "parallel" (two mirrors facing each other, infinite reflection cone),
#   "triangular" (three mirrors arranged as an equilateral triangle viewing
#   inward, the kaleidoscope's parent geometry), or "rect" (four mirrors
#   arranged as a square, mutual reflection). A faint Portal-orange accent
#   stripe sits on the bottom of each frame. In the lab's grammar the mirror
#   is the FIXED POINT / IDENTITY OPERATION — the algorithm whose answer is
#   ALWAYS "the input again".
# desire: every lab that teaches transformations needs an artifact that proves
#   "identity is itself a transformation" — that doing nothing is the
#   distinguished element of any group. The mirror wants to be the operator
#   that says f(x) = x. Multi-mirror configurations turn that single identity
#   into a CHAIN — parallel mirrors compose identity with reflection, the
#   triangle and rect arrangements compose identity with the dihedral group
# critical_parameter: mirror_arrangement + mirror_count — together they ARE
#   the operator the prop embodies. "single" = identity. "parallel" =
#   identity-via-reflection-cone (the famous infinite hall). "triangular" =
#   D3 starter / kaleidoscope kernel. "rect" = D4 starter. Same mirror, the
#   arrangement IS the group
# triggers: _ready() reads arrangement, builds 1/2/3/4 mirrors with frames
#   and optional stands; apply_grid_config rebuilds
# emerges: single reads ITSELF / IDENTITY / FIXED-POINT. Parallel reads
#   INFINITE LOOP / FEEDBACK / RECURSION. Triangular reads KALEIDOSCOPE-KERNEL.
#   Rect reads HALL-OF-MIRRORS / FULL-D4. Same prop, the configuration IS
#   the algorithm
# relationships: peer to kaleidoscope (the kaleidoscope is THREE mirrors
#   sealed in a tube; the mirror prop is the OPEN form); sibling to prism
#   (both teach optics — the prism decomposes, the mirror reflects); cousin
#   to pendulum (both freeze a fixed point — the pendulum at equilibrium,
#   the mirror at identity)
# truth: the identity transformation is the rule that EVERY group contains
#   one element which does nothing. The mirror IS that rule embodied — the
#   glass reflects you back to you, unchanged. In arrangement-with-others
#   the identity composes into reflections and rotations, generating the
#   point and dihedral groups. The glass does not LIE about what it shows —
#   what's in front IS what is shown.

## Mirror prop — single, parallel, triangular, or rectangular arrangement
## of framed mirrors with optional small stands.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the FIRST mirror (the main one for "single"; the front one for
## composed arrangements). For "single", the mirror lies in the XY plane
## with the reflective face on +Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Mirror")
@export var mirror_width: float = 0.45
@export var mirror_height: float = 0.65
@export var mirror_depth: float = 0.04
@export var frame_thickness: float = 0.025
@export var frame_color: Color = Color(0.30, 0.20, 0.15)
@export var glass_color: Color = Color(0.90, 0.92, 0.95)
@export var glass_emission: float = 0.15

@export_group("Arrangement")
@export_range(1, 4) var mirror_count: int = 1
## "single" | "parallel" | "triangular" | "rect"
@export var mirror_arrangement: String = "single"

@export_group("Mount")
@export var mount_stand: bool = true

@export_group("Accent")
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

# ── Constants ─────────────────────────────────────────────────────────

const PARALLEL_GAP: float = 0.60
const STAND_HEIGHT: float = 0.040
const STAND_WIDTH_FACTOR: float = 0.85  # vs mirror_width
const STAND_DEPTH: float = 0.10
const ACCENT_STRIP_HEIGHT: float = 0.006
const ACCENT_STRIP_DEPTH: float = 0.004

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_arrangement()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_arrangement()


func _read_metadata_overrides() -> void:
	if has_meta("config_mirror_width"):
		mirror_width = float(str(get_meta("config_mirror_width")))
	if has_meta("config_mirror_height"):
		mirror_height = float(str(get_meta("config_mirror_height")))
	if has_meta("config_mirror_depth"):
		mirror_depth = float(str(get_meta("config_mirror_depth")))
	if has_meta("config_frame_thickness"):
		frame_thickness = float(str(get_meta("config_frame_thickness")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_glass_emission"):
		glass_emission = float(str(get_meta("config_glass_emission")))
	if has_meta("config_mirror_count"):
		mirror_count = int(str(get_meta("config_mirror_count")))
	if has_meta("config_mirror_arrangement"):
		mirror_arrangement = str(get_meta("config_mirror_arrangement")).to_lower()
	if has_meta("config_mount_stand"):
		mount_stand = _parse_bool(str(get_meta("config_mount_stand")), mount_stand)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_arrangement() -> void:
	_built = true
	var arr: String = mirror_arrangement.to_lower().strip_edges()
	# Resolve effective mirror_count from arrangement string when possible.
	if arr == "parallel":
		_build_parallel()
	elif arr == "triangular":
		_build_triangular()
	elif arr == "rect":
		_build_rect()
	else:
		_build_single_at(self, Vector3.ZERO, 0.0, "Mirror_main")


func _build_single_at(parent: Node3D, pos: Vector3, y_rot_rad: float, n: String) -> void:
	# Create a Node3D container that holds the frame+glass at a position and
	# Y rotation; bottom center of the mirror is at `pos`. Glass faces +Z in
	# local space (and rotated accordingly by y_rot_rad in world).
	var unit := Node3D.new()
	unit.name = n
	unit.position = pos
	unit.rotation = Vector3(0.0, y_rot_rad, 0.0)
	parent.add_child(unit)

	var base_y: float = 0.0
	if mount_stand:
		_build_stand(unit, base_y)
		base_y += STAND_HEIGHT

	_build_frame_and_glass(unit, base_y)
	_build_accent_strip(unit, base_y)


func _build_stand(parent: Node3D, base_y: float) -> void:
	var stand := MeshInstance3D.new()
	stand.name = "Stand"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(mirror_width * STAND_WIDTH_FACTOR, STAND_HEIGHT, STAND_DEPTH)
	stand.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.65
	mat.metallic = 0.0
	stand.material_override = mat
	stand.position = Vector3(0.0, base_y + STAND_HEIGHT * 0.5, 0.0)
	parent.add_child(stand)


func _build_frame_and_glass(parent: Node3D, base_y: float) -> void:
	# Frame is built as 4 thin BoxMesh strips around the glass. Glass is a
	# thin BoxMesh inset.
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = frame_color
	fmat.roughness = 0.65
	fmat.metallic = 0.0

	# Top strip.
	var top := MeshInstance3D.new()
	top.name = "FrameTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(mirror_width, frame_thickness, mirror_depth)
	top.mesh = tm
	top.material_override = fmat
	top.position = Vector3(0.0, base_y + mirror_height - frame_thickness * 0.5, 0.0)
	parent.add_child(top)

	# Bottom strip.
	var bot := MeshInstance3D.new()
	bot.name = "FrameBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(mirror_width, frame_thickness, mirror_depth)
	bot.mesh = bm
	bot.material_override = fmat
	bot.position = Vector3(0.0, base_y + frame_thickness * 0.5, 0.0)
	parent.add_child(bot)

	# Left strip.
	var left := MeshInstance3D.new()
	left.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(frame_thickness, mirror_height - frame_thickness * 2.0, mirror_depth)
	left.mesh = lm
	left.material_override = fmat
	left.position = Vector3(-mirror_width * 0.5 + frame_thickness * 0.5, base_y + mirror_height * 0.5, 0.0)
	parent.add_child(left)

	# Right strip.
	var right := MeshInstance3D.new()
	right.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(frame_thickness, mirror_height - frame_thickness * 2.0, mirror_depth)
	right.mesh = rm
	right.material_override = fmat
	right.position = Vector3(mirror_width * 0.5 - frame_thickness * 0.5, base_y + mirror_height * 0.5, 0.0)
	parent.add_child(right)

	# Glass — slightly inset on each side.
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var glass_w: float = mirror_width - frame_thickness * 2.0
	var glass_h: float = mirror_height - frame_thickness * 2.0
	var gm := BoxMesh.new()
	gm.size = Vector3(glass_w, glass_h, mirror_depth * 0.65)
	glass.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = glass_color
	gmat.roughness = 0.05
	gmat.metallic = 0.95
	gmat.emission_enabled = true
	gmat.emission = glass_color
	gmat.emission_energy_multiplier = max(0.0, glass_emission)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	glass.material_override = gmat
	# Push glass slightly forward (+Z) so its front face reads on top of the
	# frame depth.
	glass.position = Vector3(0.0, base_y + mirror_height * 0.5, mirror_depth * 0.15)
	parent.add_child(glass)


func _build_accent_strip(parent: Node3D, base_y: float) -> void:
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(mirror_width * 0.85, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, base_y + frame_thickness + ACCENT_STRIP_HEIGHT * 0.5, mirror_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5 - 0.001)
	parent.add_child(strip)


func _build_parallel() -> void:
	# Two mirrors facing each other along the Z axis, separated by PARALLEL_GAP.
	# Mirror A at z=0 faces +Z. Mirror B at z=PARALLEL_GAP faces -Z (rotated 180°).
	_build_single_at(self, Vector3(0.0, 0.0, 0.0), 0.0, "Mirror_front")
	_build_single_at(self, Vector3(0.0, 0.0, PARALLEL_GAP), PI, "Mirror_back")


func _build_triangular() -> void:
	# Three mirrors arranged as an equilateral triangle, all viewing INWARD.
	# Each mirror sits tangent to a circle of radius R, centered on the origin.
	# We compute R so the mirrors form a triangle whose side length is
	# mirror_width plus a small margin.
	var side: float = mirror_width * 1.05
	# For an equilateral triangle of side s, the inradius is s / (2*sqrt(3)).
	var inradius: float = side / (2.0 * sqrt(3.0))
	# Place mirrors at angles 0°, 120°, 240°, each facing INWARD (toward origin).
	# Mirror's local +Z face is its reflective side, so a mirror at angle θ
	# placed at (R*cos θ, 0, R*sin θ) and rotated by Y so +Z points toward
	# origin must rotate Y by (θ + 180°) — its facing direction is then
	# (-cos θ, 0, -sin θ).
	for i in range(3):
		var theta: float = deg_to_rad(90.0) + TAU * float(i) / 3.0
		var pos := Vector3(inradius * cos(theta), 0.0, inradius * sin(theta))
		# +Z of the mirror should point toward origin, i.e. direction
		# -pos.normalized(). Rotation Y rotates local +Z by atan2(z, x)-style.
		# We want world +Z direction post-rotation = -normalize(pos).
		# Default mirror's +Z is (0, 0, 1) in local; rotate around Y by yaw so
		# that local (0,0,1) becomes (sin(yaw), 0, cos(yaw)).
		# We want (sin(yaw), 0, cos(yaw)) = -pos.normalized().
		var dir: Vector3 = -pos.normalized()
		var yaw: float = atan2(dir.x, dir.z)
		_build_single_at(self, pos, yaw, "Mirror_tri_%d" % i)


func _build_rect() -> void:
	# Four mirrors arranged as a square, all viewing INWARD. Square side
	# slightly larger than mirror_width. Mirrors at the midpoints of each
	# side of the square, oriented to face origin.
	var side: float = mirror_width * 1.10
	var half: float = side * 0.5
	# Four edge centers and corresponding inward yaws.
	var positions: Array[Vector3] = [
		Vector3(0.0, 0.0, -half),  # front edge, facing +Z (toward origin)
		Vector3(half, 0.0, 0.0),   # right edge, facing -X
		Vector3(0.0, 0.0, half),   # back edge, facing -Z
		Vector3(-half, 0.0, 0.0),  # left edge, facing +X
	]
	for i in range(4):
		var pos: Vector3 = positions[i]
		var dir: Vector3 = -pos.normalized()
		var yaw: float = atan2(dir.x, dir.z)
		_build_single_at(self, pos, yaw, "Mirror_rect_%d" % i)


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
