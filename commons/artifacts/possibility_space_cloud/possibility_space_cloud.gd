extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PossibilitySpaceCloud

## @identity
## name: Possibility Space Cloud
## truth: entropy is the size of the space of what could be.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). A phase box holds a cloud of
## state-points (one MultiMesh). The cloud BREATHES between a tiny tight cluster — LOW
## ENTROPY, few accessible states, ordered — and a vast filled volume — HIGH ENTROPY,
## many accessible states. The "ACCESSIBLE STATES" readout scales with the cloud's
## occupied volume. Entropy here is not motion or noise; it is the measure of the box
## of everything the system could presently be.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `occupancy`
# ═══════════════════════════════════════════════════════════════════
#
# How much of the phase box the accessible states actually occupy, and whether the
# box that supplies the denominator is built at all.
#
# Entropy here is a RATIO. Before this axis the artifact only ever varied the
# NUMERATOR, and only as an animation nobody controls: a map could not place a space
# that is nearly empty, a space that is full, or a system with no bounding space at
# all. `pinched` and `packed` make the two ends photographable; `widened` moves the
# change into the DENOMINATOR (the same states, a bigger space of what-could-be);
# `unboxed` removes the denominator entirely — a cloud with no box is a quantity with
# no measure.
#
#   breath   — unchanged. 220 points cycling between a 0.10 m knot and a 0.90 m cloud
#              (clamped to the 0.322 m box half-extent) inside the 0.7 m glass box.
#   pinched  — breath stopped at min_radius: a 0.10 m knot alone in a 0.7 m box that is
#              99.7% empty by volume, all points cold blue; readout pinned at 10^1.
#   packed   — breath stopped at max_radius: every outer point clamped onto the 0.322 m
#              shell, so the cube reads solid bright cyan; readout pinned at 10^18.
#   unboxed  — no glass box, no 12 glowing edge cylinders, no floor ticks. The same
#              breathing cloud on the bare post, making no claim about entropy at all.
#   widened  — the box built at 1.4x (0.98 m a side), frame and ticks scaled with it,
#              the cloud held at its own default max radius of 0.45 m.
const OCCUPANCIES: PackedStringArray = [
	"breath", "pinched", "packed", "unboxed", "widened"]

## The occupancy of the possibility space. `breath` is the shipped look.
@export_enum("breath", "pinched", "packed", "unboxed", "widened") var occupancy: String = "breath"

@export var point_count: int = 220
@export var phase_box: Vector3 = Vector3(0.7, 0.7, 0.7)
@export var breath_period: float = 7.0
@export var min_radius: float = 0.05  # tight ordered cluster
@export var max_radius: float = 0.45  # vast filled cloud
@export var low_color: Color = Color(0.4, 0.55, 1.0)   # ordered / cold
@export var high_color: Color = Color(0.55, 0.95, 1.0) # spread / bright cyan
@export var frame_color: Color = Color(0.6, 0.5, 0.95) # purple instrument frame

## Fixed cloud seed. The pre-promotion build called _rng.randomize(), which makes the
## sweep sheet an experiment about the RNG instead of about the axis. Same 220 points,
## same sqrt-biased volume-uniform fill — one fixed member of the same distribution.
const CLOUD_SEED: int = 20260729

## The TextScreen carrying the readout. Sized so its board clears the top of the phase
## box (whatever scale the box was built at) by SCREEN_CLEAR.
const SCREEN_W: float = 0.66
const SCREEN_H: float = 0.4452   # 0.66 * TextScreen.ASPECT(0.62) + 2 * BEZEL(0.018)
const SCREEN_CLEAR: float = 0.05
## Gap from the top of the screen board to the centre of the framed title plate
## (half the plate's 0.21 m height plus a 0.055 m air gap).
const TITLE_GAP: float = 0.16

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _dirs: PackedVector3Array = PackedVector3Array()   # unit direction per point
var _radii: PackedFloat32Array = PackedFloat32Array()  # max fractional radius per point
var _phases: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _screen = null                # TextScreen (untyped: preload, not class_name)
var _t: float = 0.0

var _built: bool = false
var _owned: Array[Node] = []
var _emissive_mats: Array[Dictionary] = []
var _box_scale: float = 1.0
var _frozen: float = -1.0         # >= 0.0: cloud held at this breath value, no _process
var _last_title: String = ""
var _last_body: String = ""


func _ready() -> void:
	_rng.seed = CLOUD_SEED
	_build_all()
	_built = true


func apply_grid_config(config: Dictionary) -> void:
	var before_occupancy: String = occupancy
	if config.has("occupancy"):
		occupancy = _pick_axis(str(config["occupancy"]), OCCUPANCIES, occupancy)

	# Applied IN PLACE, before any early return. The old build tore every child down on
	# any dictionary at all — including curation_station's {"emissive": false}, one line
	# after it had framed the labels. Dimming is a material property; it never needed a
	# rebuild, and doing it here is what keeps the accepted key doing something.
	if config.has("emissive"):
		emissive = bool(config["emissive"])
		_apply_emissive()

	if not _built:
		return
	if occupancy == before_occupancy:
		return
	_rebuild_now()
	print("[PossibilitySpaceCloud] Config applied — occupancy=%s" % [occupancy])


## Accept an axis value only if it names something we actually build; a typo has to
## fall back to the shipped look rather than strand a placement with no box.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	# Only nodes THIS script created. get_children() would also take the plates the
	# label framer added and anything the grid parented onto us.
	for c: Node in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_emissive_mats.clear()
	_mm = null
	_mm_inst = null
	_title = null
	_readout = null
	_screen = null
	_last_title = ""
	_last_body = ""
	_t = 0.0
	_rng.seed = CLOUD_SEED
	_build_all()


func _own(n: Node) -> void:
	_owned.append(n)
	add_child(n)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_box_scale = 1.0
	_frozen = -1.0
	var build_box: bool = true
	match occupancy:
		"pinched":
			_frozen = 0.0
		"packed":
			_frozen = 1.0
		"unboxed":
			build_box = false
		"widened":
			_frozen = 1.0
			_box_scale = 1.4

	# --- floor base (y ~ 0) --- identical in every value: the instrument is the same
	# instrument, only the space it measures changes.
	_own(_cylinder(Vector3(0.0, 0.04, 0.0), 0.4, 0.08, _steel_r(Color(0.16, 0.18, 0.28))))
	_own(_cylinder(Vector3(0.0, 0.32, 0.0), 0.045, 0.34, _steel_r(frame_color * 0.7)))

	# --- phase box (the accessible-state container) centered ~0.72 ---
	var box_center: Vector3 = Vector3(0.0, 0.72, 0.0)
	var box_size: Vector3 = phase_box * _box_scale
	if build_box:
		_own(_box(box_center, box_size, _glass_r(frame_color, 0.07)))
		_add_box_frame(box_center, box_size, 0.011 * _box_scale, _glow_r(frame_color, 1.8))

		# axis ticks on the floor of the phase box to read it as a state-space
		var tick_mat: StandardMaterial3D = _glow_r(low_color * 0.8, 0.8)
		var tick_t: float = 0.008 * _box_scale
		_own(_box(box_center + Vector3(0.0, -box_size.y * 0.5 + 0.006 * _box_scale, 0.0),
			Vector3(box_size.x * 0.9, tick_t, tick_t), tick_mat))
		_own(_box(box_center + Vector3(0.0, -box_size.y * 0.5 + 0.006 * _box_scale, 0.0),
			Vector3(tick_t, tick_t, box_size.z * 0.9), tick_mat))

	# --- the state-point cloud: ONE MultiMesh ---
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = point_count
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.011
	sph.height = 0.022
	sph.radial_segments = 6
	sph.rings = 3
	_mm.mesh = sph
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "StateCloud"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_r(high_color, 2.2)
	_mm_inst.position = box_center
	_own(_mm_inst)

	_dirs.resize(point_count)
	_radii.resize(point_count)
	_phases.resize(point_count)
	var i: int = 0
	while i < point_count:
		# random direction on a sphere; sqrt-biased radius for volume-uniform fill
		var d: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0))
		if d.length() < 0.001:
			d = Vector3.UP
		_dirs[i] = d.normalized()
		_radii[i] = sqrt(_rng.randf())  # 0..1, denser fill at larger radii
		_phases[i] = _rng.randf() * TAU
		_mm.set_instance_transform(i, Transform3D(Basis(), _dirs[i] * min_radius))
		_mm.set_instance_color(i, low_color)
		i += 1

	# --- titles / readout -----------------------------------------------------
	# Both used to be hanging billboard Label3Ds. The framer now turns those into
	# opaque plates, and the readout's plate (2.30 x 0.37 m, three lines with a
	# 46-character regime line) stood a slab twice the artifact's width across the top
	# of the box. It is a screen, so it is now a screen; the title still hangs, moved
	# up to leave the screen its air.
	var body_top: float = box_center.y + box_size.y * 0.5
	var screen_y: float = body_top + SCREEN_CLEAR + SCREEN_H * 0.5
	var title_y: float = screen_y + SCREEN_H * 0.5 + TITLE_GAP

	_title = _billboard_label("POSSIBILITY SPACE", Vector3(0.0, title_y, 0.0), 28, high_color)
	_own(_title)

	# Configure BEFORE add_child — TextScreen's setters rebuild only when in-tree.
	_screen = TextScreenScript.new()
	_screen.name = "StateReadout"
	_screen.mode = 0                      # Mode.SCREEN — a framed board, no stand
	_screen.width_m = SCREEN_W
	_screen.title_color = high_color   # the only palette override: the readout tint
	_screen.position = Vector3(0.0, screen_y, 0.0)
	_own(_screen)

	# The live text source, kept per the migration rule: the Label3D survives so the
	# per-frame .text assignment keeps working, billboard OFF so the framer skips it,
	# glyphs scaled to nothing so the board is the only thing you read.
	_readout = _billboard_label("", Vector3.ZERO, 19, high_color)
	_readout.name = "ReadoutSource"
	_readout.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_readout.no_depth_test = false
	_readout.scale = Vector3.ONE * 0.001
	_screen.add_child(_readout)

	_apply_emissive()

	if _frozen >= 0.0:
		_seat_cloud(_frozen, false)
		_update_readout(_frozen)
		set_process(false)
	else:
		_update_readout(0.0)
		set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# breathe: 0 = tight ordered cluster, 1 = vast filled cloud
	var breath: float = 0.5 - 0.5 * cos(_t * TAU / maxf(breath_period, 0.5))
	_seat_cloud(breath, true)
	_update_readout(breath)

	if _title != null:
		_title.modulate = high_color.lerp(Color(1.0, 1.0, 1.0), 0.2 * breath)


## Place every point for one breath value. `wobble` is the per-point shimmer; the held
## values (pinched / packed / widened) seat with it off, so the still is the same still
## every time the shutter opens.
func _seat_cloud(breath: float, wobble: bool) -> void:
	if _mm == null:
		return
	var radius_now: float = lerpf(min_radius, max_radius, breath)
	var col_now: Color = low_color.lerp(high_color, breath)
	var limit: float = phase_box.x * 0.46 * _box_scale
	var i: int = 0
	while i < point_count:
		var w: float = 1.0
		if wobble:
			w = 1.0 + 0.06 * sin(_t * 1.7 + _phases[i])
		var r: float = radius_now * _radii[i] * w
		# keep within the box half-extent
		r = minf(r, limit)
		var pos: Vector3 = _dirs[i] * r
		_mm.set_instance_transform(i, Transform3D(Basis(), pos))
		# brighter as it spreads
		_mm.set_instance_color(i, col_now.lerp(Color(1.0, 1.0, 1.0), 0.15 * breath))
		i += 1


func _update_readout(breath: float) -> void:
	# Accessible states scale with occupied VOLUME (~ radius^3). Express as a magnitude
	# that sweeps from "few" (ordered) to a huge number (spread).
	var radius_now: float = lerpf(min_radius, max_radius, breath)
	var vol_frac: float = pow(radius_now / max_radius, 3.0)  # 0..1 of the full box
	var states_exp: float = lerpf(1.0, 18.0, vol_frac)       # 10^1 .. 10^18
	var regime: String = "LOW ENTROPY — few accessible states (ordered)"
	if breath > 0.66:
		regime = "HIGH ENTROPY — many accessible states (spread)"
	elif breath > 0.33:
		regime = "RISING ENTROPY — the box of what could be widens"

	var line_title: String = "ACCESSIBLE STATES ~ 10^%d" % [int(round(states_exp))]
	var line_body: String = regime + "\nS = log(states)"

	if _readout != null:
		_readout.text = line_title + "\n" + line_body

	# TextScreen bakes its text into a texture, so only push when the string actually
	# changes — a per-frame set_text() would rebuild the board every frame and mint a
	# new ImageTexture per distinct string.
	if _screen != null and (line_title != _last_title or line_body != _last_body):
		_last_title = line_title
		_last_body = line_body
		if _screen.has_method("set_text"):
			_screen.set_text(line_title, line_body)


func _add_box_frame(center: Vector3, size: Vector3, r: float, mat: Material) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var corners: Array = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz),
		Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz),
		Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		var a: Vector3 = center + corners[e[0]]
		var b: Vector3 = center + corners[e[1]]
		_own(_cylinder_between(a, b, r, mat))


# ═══════════════════════════════════════════════════════════════════
# EMISSIVE — registered materials, so `emissive` can be applied without a rebuild
# ═══════════════════════════════════════════════════════════════════

func _reg_mat(m: StandardMaterial3D, on_e: float, off_e: float) -> StandardMaterial3D:
	_emissive_mats.append({"mat": m, "on": on_e, "off": off_e})
	return m


func _glow_r(c: Color, energy: float) -> StandardMaterial3D:
	return _reg_mat(_glow_mat(c, energy), energy, energy * 0.3)


func _steel_r(c: Color) -> StandardMaterial3D:
	return _reg_mat(_steel_mat(c), 0.1, 0.0)


func _glass_r(c: Color, alpha: float) -> StandardMaterial3D:
	return _reg_mat(_glass_mat(c, alpha), 0.3, 0.0)


func _apply_emissive() -> void:
	for e: Dictionary in _emissive_mats:
		var m: StandardMaterial3D = e.get("mat") as StandardMaterial3D
		if m == null:
			continue
		m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])
