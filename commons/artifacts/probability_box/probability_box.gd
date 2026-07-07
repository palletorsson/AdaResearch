extends Node3D
class_name ProbabilityBox

# @identity
# essence: a wooden dice tray with a low rim and 1-8 cube dice scattered, rowed,
#   stacked, or clustered across the surface — Aperture / casino-lab vocabulary.
#   In the lab's grammar, the probability_box IS the MONTE CARLO METHOD in object
#   form. Tray = sample space. Dice = draws. Face values = outcomes. Arrangement
#   = the geometry of how a sample is laid bare before counting.
# desire: every lab that talks about chance needs an artifact that REFUSES to be
#   a graph. A formula on a chalkboard hides the mechanics. Real dice on real
#   wood show that randomness is mechanical, repeatable, and physically realised.
#   The tray wants to be the smallest possible room in which probability HAPPENS
# critical_parameter: dice_count + face_values — together they ARE the algorithm's
#   key knob. dice_count is N (sample size). face_values is the realised draw.
#   Change them and you change the experiment, not the apparatus
# triggers: _ready() builds tray + rim + dice (per arrangement) + face dots + accent;
#   apply_grid_config rebuilds. face_values is padded/truncated to dice_count
# emerges: 5 scattered dice reads CASUAL SAMPLE. 8 stacked dice reads RIGGED RUN.
#   1 die in a row reads SINGLE TRIAL. Same script, same tray, the algorithm's
#   character changes with the arrangement
# needs: tray base [present]; 4 rim strips [present]; dice per arrangement [present];
#   pip dots 1-6 per face on top of each die [present]; accent stripe around rim
#   [present]
# relationships: peer to entropy_meter (both quantify chance — meter aggregates,
#   box samples); sibling to specimen_jar (both display contained truth — jar
#   contains matter, box contains outcomes); cousin to map_table (both lay
#   evidence flat on a surface); the lab's mechanical witness to the law of
#   large numbers
# truth: a Monte Carlo method is the claim that you can know a distribution by
#   throwing it. The box IS that rule embodied — the dice on the wood ARE the
#   draws, the face values ARE the realised sample, the rim is the bound of the
#   experiment. To roll is to sample. To count is to estimate. The tray is the
#   simulator.

## A wooden dice tray with cube dice arranged across its surface.
##
## Built procedurally from DNA exports. Origin is at the bottom center of the
## tray. Faces +Z. Dice are placed per `arrangement` (scattered / row / stacked
## / cluster) and each die shows its face value (1-6) as pip dots on its
## top face.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var tray_width: float = 0.22
@export var tray_depth: float = 0.16
@export var tray_rim_height: float = 0.015

@export_group("Color")
@export var tray_color: Color = Color(0.78, 0.62, 0.42)
@export var dice_color: Color = Color(0.95, 0.94, 0.88)
@export var dot_color: Color = Color(0.10, 0.10, 0.10)
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

@export_group("Dice")
@export_range(1, 8) var dice_count: int = 5
@export var dice_size: float = 0.018
## "scattered" | "row" | "stacked" | "cluster"
@export var arrangement: String = "scattered"
## Which face is up per die (pad/truncate to dice_count)
@export var face_values: PackedInt32Array = PackedInt32Array([6, 4, 2, 5, 3])

# ── Constants ─────────────────────────────────────────────────────────

const TRAY_BASE_THICKNESS: float = 0.018
const RIM_THICKNESS: float = 0.010
const DOT_RADIUS_FACTOR: float = 0.10
const ACCENT_STRIP_HEIGHT: float = 0.004
const ACCENT_STRIP_DEPTH: float = 0.003

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_probability_box()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_probability_box()


func _read_metadata_overrides() -> void:
	if has_meta("config_tray_width"):
		tray_width = float(str(get_meta("config_tray_width")))
	if has_meta("config_tray_depth"):
		tray_depth = float(str(get_meta("config_tray_depth")))
	if has_meta("config_tray_rim_height"):
		tray_rim_height = float(str(get_meta("config_tray_rim_height")))
	if has_meta("config_tray_color"):
		tray_color = _parse_color(str(get_meta("config_tray_color")), tray_color)
	if has_meta("config_dice_count"):
		dice_count = int(str(get_meta("config_dice_count")))
	if has_meta("config_dice_size"):
		dice_size = float(str(get_meta("config_dice_size")))
	if has_meta("config_dice_color"):
		dice_color = _parse_color(str(get_meta("config_dice_color")), dice_color)
	if has_meta("config_dot_color"):
		dot_color = _parse_color(str(get_meta("config_dot_color")), dot_color)
	if has_meta("config_arrangement"):
		arrangement = str(get_meta("config_arrangement")).to_lower()
	if has_meta("config_face_values"):
		face_values = _parse_int_array(str(get_meta("config_face_values")), face_values)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_probability_box() -> void:
	_built = true
	_build_tray_base()
	_build_rim()
	_build_dice()
	_build_accent_stripe()


func _build_tray_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "TrayBase"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tray_width, TRAY_BASE_THICKNESS, tray_depth)
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tray_color
	mat.roughness = 0.75
	mat.metallic = 0.05
	base.material_override = mat
	base.position = Vector3(0.0, TRAY_BASE_THICKNESS * 0.5, 0.0)
	add_child(base)


func _build_rim() -> void:
	var root := Node3D.new()
	root.name = "Rim"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = tray_color.darkened(0.25)
	mat.roughness = 0.7
	mat.metallic = 0.05

	var y: float = TRAY_BASE_THICKNESS + tray_rim_height * 0.5
	var half_w: float = tray_width * 0.5
	var half_d: float = tray_depth * 0.5

	# Front (+Z)
	var f := MeshInstance3D.new()
	f.name = "RimFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(tray_width, tray_rim_height, RIM_THICKNESS)
	f.mesh = fm
	f.material_override = mat
	f.position = Vector3(0.0, y, half_d - RIM_THICKNESS * 0.5)
	root.add_child(f)

	# Back (-Z)
	var b := MeshInstance3D.new()
	b.name = "RimBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(tray_width, tray_rim_height, RIM_THICKNESS)
	b.mesh = bm
	b.material_override = mat
	b.position = Vector3(0.0, y, -half_d + RIM_THICKNESS * 0.5)
	root.add_child(b)

	# Left (-X)
	var l := MeshInstance3D.new()
	l.name = "RimLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(RIM_THICKNESS, tray_rim_height, tray_depth)
	l.mesh = lm
	l.material_override = mat
	l.position = Vector3(-half_w + RIM_THICKNESS * 0.5, y, 0.0)
	root.add_child(l)

	# Right (+X)
	var r := MeshInstance3D.new()
	r.name = "RimRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(RIM_THICKNESS, tray_rim_height, tray_depth)
	r.mesh = rm
	r.material_override = mat
	r.position = Vector3(half_w - RIM_THICKNESS * 0.5, y, 0.0)
	root.add_child(r)


func _build_dice() -> void:
	var root := Node3D.new()
	root.name = "Dice"
	add_child(root)

	var n: int = clampi(dice_count, 1, 8)
	var y_base: float = TRAY_BASE_THICKNESS + dice_size * 0.5
	# Inner area the dice may occupy (inside the rim).
	var pad: float = RIM_THICKNESS + dice_size * 0.6
	var inner_w: float = max(0.001, tray_width - pad * 2.0)
	var inner_d: float = max(0.001, tray_depth - pad * 2.0)

	for i in range(n):
		var pos: Vector3 = _arrangement_position(i, n, y_base, inner_w, inner_d)
		var face: int = _face_value_for(i)
		var rot: Vector3 = _arrangement_rotation(i, n)
		_place_die(root, i, pos, rot, face)


func _arrangement_position(i: int, n: int, y_base: float, inner_w: float, inner_d: float) -> Vector3:
	match arrangement:
		"row":
			var step: float = 0.0
			if n > 1:
				step = inner_w / float(n - 1)
			var x_row: float = -inner_w * 0.5 + float(i) * step
			if n == 1:
				x_row = 0.0
			return Vector3(x_row, y_base, 0.0)
		"stacked":
			var x_stack: float = 0.0
			var z_stack: float = 0.0
			var y_stack: float = TRAY_BASE_THICKNESS + dice_size * (0.5 + float(i))
			return Vector3(x_stack, y_stack, z_stack)
		"cluster":
			# Tight cluster near +X +Z corner.
			var cx: float = inner_w * 0.25
			var cz: float = inner_d * 0.25
			var ang: float = TAU * float(i) / float(max(1, n))
			var r_cl: float = dice_size * 1.2
			var x_cl: float = cx + cos(ang) * r_cl
			var z_cl: float = cz + sin(ang) * r_cl
			return Vector3(x_cl, y_base, z_cl)
		_:
			# scattered — deterministic hash positions across the inner tray.
			var hx: float = float(((i * 9301 + 49297) % 233280)) / 233280.0
			var hz: float = float(((i * 14741 + 31337) % 233280)) / 233280.0
			var x_sc: float = (hx - 0.5) * inner_w
			var z_sc: float = (hz - 0.5) * inner_d
			return Vector3(x_sc, y_base, z_sc)


func _arrangement_rotation(i: int, n: int) -> Vector3:
	if arrangement == "row":
		return Vector3.ZERO
	if arrangement == "stacked":
		# Small turn per die so the stack reads as a stack and not a tower.
		return Vector3(0.0, deg_to_rad(float(i) * 7.0), 0.0)
	if arrangement == "cluster":
		var ang_c: float = TAU * float(i) / float(max(1, n))
		return Vector3(0.0, ang_c * 0.5, 0.0)
	# scattered — pseudo-random small yaw.
	var seed_i: int = (i * 2654435761) & 0xFFFFFFFF
	var hy: float = float(seed_i % 360) - 180.0
	return Vector3(0.0, deg_to_rad(hy), 0.0)


func _face_value_for(i: int) -> int:
	if i < face_values.size():
		var v: int = int(face_values[i])
		return clampi(v, 1, 6)
	return (i % 6) + 1


func _place_die(parent: Node3D, index: int, pos: Vector3, rot: Vector3, face: int) -> void:
	var die := MeshInstance3D.new()
	die.name = "Die_%d" % index
	var mesh := BoxMesh.new()
	mesh.size = Vector3(dice_size, dice_size, dice_size)
	die.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = dice_color
	mat.roughness = 0.4
	mat.metallic = 0.0
	die.material_override = mat
	die.position = pos
	die.rotation = rot
	parent.add_child(die)

	# Pip dots on top face (local +Y of the die).
	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = dot_color
	dot_mat.roughness = 0.45
	dot_mat.metallic = 0.05

	var dot_r: float = dice_size * DOT_RADIUS_FACTOR
	var inset: float = dice_size * 0.27
	var top_y: float = dice_size * 0.5 + dot_r * 0.5
	var pattern: Array = _pip_pattern_for(face, inset)
	for p in pattern:
		var dot := MeshInstance3D.new()
		dot.name = "Pip"
		var sm := SphereMesh.new()
		sm.radius = dot_r
		sm.height = dot_r * 2.0
		dot.mesh = sm
		dot.material_override = dot_mat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.position = Vector3(p.x, top_y, p.y)
		die.add_child(dot)


func _pip_pattern_for(face: int, inset: float) -> Array:
	# Returns an Array of Vector2(x, z) offsets in the die's local top plane.
	match face:
		1:
			return [Vector2(0.0, 0.0)]
		2:
			return [Vector2(-inset, -inset), Vector2(inset, inset)]
		3:
			return [Vector2(-inset, -inset), Vector2(0.0, 0.0), Vector2(inset, inset)]
		4:
			return [
				Vector2(-inset, -inset), Vector2(inset, -inset),
				Vector2(-inset, inset), Vector2(inset, inset)
			]
		5:
			return [
				Vector2(-inset, -inset), Vector2(inset, -inset),
				Vector2(0.0, 0.0),
				Vector2(-inset, inset), Vector2(inset, inset)
			]
		6:
			return [
				Vector2(-inset, -inset), Vector2(-inset, 0.0), Vector2(-inset, inset),
				Vector2(inset, -inset), Vector2(inset, 0.0), Vector2(inset, inset)
			]
		_:
			return [Vector2(0.0, 0.0)]


func _build_accent_stripe() -> void:
	# Emissive thin stripe ringing the outside of the rim along the front edge.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tray_width * 0.94, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var y: float = TRAY_BASE_THICKNESS + tray_rim_height * 0.5
	strip.position = Vector3(0.0, y, tray_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
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


func _parse_int_array(s: String, fallback: PackedInt32Array) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var parts := s.split(",")
	for p in parts:
		var ts := p.strip_edges()
		if ts == "":
			continue
		out.append(int(ts))
	if out.size() == 0:
		return fallback
	return out
