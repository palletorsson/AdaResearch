extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name IncompletenessTower

## @identity
## name: Incompleteness Tower
## lineage: Godel's second move and the limit of "just add an axiom". Each
##   consistent system strong enough for arithmetic has its own unprovable
##   truth; bolt it on as a new axiom and the larger system has a new one.
## essence: a tower of ringed platforms, one formal system per level. A pulse
##   climbs it: at each level a gold Godel-gap opens in the floor, an AXIOM bar
##   drops in to patch it (the gap goes cool/closed) — and the next level up
##   immediately splits open a fresh gold gap. Patch, climb, new hole, forever.
## truth: closing the gap with a new axiom does not finish the system; it makes
##   a bigger system, which has its own gap one level up. Incompleteness all the
##   way up.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var level_blue: Color = Color(0.40, 0.62, 0.95)
@export var patch_cyan: Color = Color(0.45, 0.85, 0.92)
@export var gap_gold: Color = Color(1.0, 0.78, 0.30)
@export var level_count: int = 5
@export var level_height: float = 0.20
@export var climb_period: float = 5.0

## Stage-2 DNA axis — how far the patch-and-climb regress is drawn to run, and
## whether the tower is allowed to declare itself finished.
##
## The tower's argument is ITERATION, and iteration is the one thing a still
## cannot show: the climbing pulse gives an arbitrary phase per capture. So the
## argument moves into the SHAPE of the stack, where a photograph can hold it.
##
##   taper    the shipped tower — 5 platforms, 0.40 -> 0.22 m, a regress that
##            quietly stops at five with a lid on it.
##   endless  9 platforms at 0.14 m pitch narrowing to a 0.06 m disc at y = 1.18;
##            the regress drawn as a VANISHING POINT, the top three levels barely
##            wider than their own gap discs.
##   capped   5 platforms, but the top one carries no gap and no AXIOM bar — a
##            solid cool-white slab seals it and the plate reads "the system is
##            complete". Hilbert's finished foundation: the claim the theorem
##            kills, standing in the middle of the argument against itself.
##   column   5 platforms all at 0.40 m with no taper and enlarged gaps — a
##            0.80 x 0.86 m cylinder. The regress that does not even converge:
##            every system as large as the one meant to complete it.
##
## INTERACTION, stated so a map is not silently surprised: `endless` OVERWRITES
## level_count to 9 and the pitch to 0.14 unconditionally, and `column` overrides
## the radius lerp. A placement that sets level_count and then regress:endless
## gets nine levels, not the count it asked for — the axis wins.
@export_enum("taper", "endless", "capped", "column") var regress: String = "taper"

## Allow-list for the axis. A typo in a map token falls back to the shipped look
## rather than stranding a placement with no tower at all.
const REGRESSS: PackedStringArray = ["taper", "endless", "capped", "column"]

## Fixed seed. Nothing in _build() draws from _rng today, but two builds of one
## axis value must be pixel-identical or the critic reads noise as signal.
const BUILD_SEED: int = 20260728

# --- geometry constants the axis moves ---------------------------------------
const R_BASE: float = 0.40                    # bottom platform radius, all values
const R_TOP_TAPER: float = 0.22               # taper / capped
const R_TOP_ENDLESS: float = 0.06             # endless: narrows to a point
const ENDLESS_LEVELS: int = 9
const ENDLESS_PITCH: float = 0.14
const GAP_R: float = 0.06                     # taper / endless / capped
const GAP_R_COLUMN: float = 0.09              # the gap that does not shrink
const CAP_R: float = 0.24                     # capped: the sealing slab
const CAP_H: float = 0.06

var _t: float = 0.0
var _base_y: float = 0.06
var _gap_mats: Array[StandardMaterial3D] = []     # the gold gap disc per level
var _gaps: Array[MeshInstance3D] = []
var _patch_bars: Array[Node3D] = []               # the AXIOM bar that drops to patch each level
var _rings: Array[StandardMaterial3D] = []
var _level_r: PackedFloat32Array = PackedFloat32Array()

# Effective stack, resolved from `regress` at build time. The @export vars are
# left as the AUTHORED values so switching the axis back restores them.
var _n: int = 5
var _pitch: float = 0.20

# Only what THIS script added. Freeing get_children() would destroy grid-added
# label plates, packaging and tag markers.
var _owned: Array[Node] = []
var _built: bool = false

# Emissive is honoured in place — no rebuild — so curation_station's
# {"emissive": false} cannot discard the framing it applied one line earlier.
var _lit_mats: Array[StandardMaterial3D] = []
var _lit_on: PackedFloat32Array = PackedFloat32Array()
var _lit_off: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_rng.seed = BUILD_SEED
	# Builds from the @export values alone — the sweep harness sets `regress`
	# before add_child() and never calls apply_grid_config().
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	var before_regress: String = regress
	var before_count: int = level_count
	var before_height: float = level_height

	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
	if config_data.has("regress"):
		regress = _pick_axis(str(config_data["regress"]), REGRESSS, regress)
	if config_data.has("level_count"):
		level_count = clampi(int(config_data["level_count"]), 1, 16)
	if config_data.has("level_height"):
		level_height = clampf(float(config_data["level_height"]), 0.06, 0.60)

	# Emission never needs new geometry; fold it straight into the live materials.
	_apply_emissive()

	if not _built:
		return
	if regress == before_regress and level_count == before_count and is_equal_approx(level_height, before_height):
		return    # curation_station's {"emissive": false}: touch nothing, say nothing

	_rebuild_now()
	print("[IncompletenessTower] Config applied — regress=%s, levels=%d, pitch=%.3f" % [regress, _n, _pitch])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)     # leaves the tree synchronously — no double-render
			c.queue_free()
	_owned.clear()
	_gap_mats.clear()
	_gaps.clear()
	_patch_bars.clear()
	_rings.clear()
	_lit_mats.clear()
	_lit_on.clear()
	_lit_off.clear()
	_build()                    # SYNCHRONOUS — a deferred rebuild would hand
	                            # _auto_ground_artifact a zero AABB.


## add_child + remember, so a rebuild frees only what this script made.
func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


# --- material tracking -------------------------------------------------------
# The base helpers bake the emissive flag into emission_energy_multiplier at
# creation time. Recording both branches lets a later emissive change be applied
# without rebuilding a single mesh.

func _lit(m: StandardMaterial3D, on_energy: float, off_energy: float) -> StandardMaterial3D:
	_lit_mats.append(m)
	_lit_on.append(on_energy)
	_lit_off.append(off_energy)
	return m


func _t_glow(c: Color, energy: float) -> StandardMaterial3D:
	return _lit(_glow_mat(c, energy), energy, energy * 0.3)


func _t_glass(c: Color, alpha: float) -> StandardMaterial3D:
	return _lit(_glass_mat(c, alpha), 0.3, 0.0)


func _t_steel(c: Color) -> StandardMaterial3D:
	return _lit(_steel_mat(c), 0.1, 0.0)


func _apply_emissive() -> void:
	var i: int = 0
	while i < _lit_mats.size():
		var m: StandardMaterial3D = _lit_mats[i]
		if m != null:
			m.emission_energy_multiplier = _lit_on[i] if emissive else _lit_off[i]
		i += 1


# --- build -------------------------------------------------------------------

func _build() -> void:
	_t = 0.0
	_gap_mats.clear()
	_gaps.clear()
	_patch_bars.clear()
	_rings.clear()

	# Resolve the stack the axis asks for. `endless` overwrites the authored
	# count and pitch; `column` overwrites the radius lerp; `capped` changes only
	# the top level and the plate. `taper` is the shipped tower, untouched.
	_n = clampi(level_count, 1, 16)
	_pitch = level_height
	var r_bot: float = R_BASE
	var r_top: float = R_TOP_TAPER
	match regress:
		"endless":
			_n = ENDLESS_LEVELS
			_pitch = ENDLESS_PITCH
			r_top = R_TOP_ENDLESS
		"column":
			r_top = R_BASE          # no taper at all
		_:
			pass

	var gap_r: float = GAP_R_COLUMN if regress == "column" else GAP_R
	_level_r.resize(_n)

	# --- chalk ring on the floor ---
	_own(_torus(Vector3(0.0, 0.02, 0.0), 0.50, 0.012, _t_glow(wire_purple, 0.5)))

	var frame_mat: StandardMaterial3D = _t_steel(Color(0.32, 0.34, 0.42))
	var lvl: int = 0
	while lvl < _n:
		var y: float = _base_y + float(lvl) * _pitch
		# platforms taper as the tower rises — flat for `column`, to a point for `endless`
		var r: float = lerpf(r_bot, r_top, float(lvl) / float(maxi(_n - 1, 1)))
		_level_r[lvl] = r

		var is_sealed_top: bool = (regress == "capped" and lvl == _n - 1)

		# platform disc (the system's floor)
		var floor_mat: StandardMaterial3D = _t_glass(level_blue, 0.18)
		_own(_cylinder(Vector3(0.0, y, 0.0), r, 0.014, floor_mat))
		# ring edge — the boundary of this formal system
		_rings.append(_t_glow(level_blue, 1.0))
		_own(_torus(Vector3(0.0, y + 0.008, 0.0), r, 0.010, _rings[lvl]))

		# four support struts down to the previous level (or the floor).
		# With `column` r is a constant 0.40, so this is the flat 0.28 m strut
		# circle the axis names.
		var below: float = (_base_y + float(lvl - 1) * _pitch) if lvl > 0 else 0.0
		var strut_r: float = r * 0.7
		var k: int = 0
		while k < 4:
			var a: float = float(k) / 4.0 * TAU + PI * 0.25
			var px: float = cos(a) * strut_r
			var pz: float = sin(a) * strut_r
			_own(_cylinder_between(Vector3(px, below + 0.01, pz), Vector3(px, y - 0.01, pz), 0.012, frame_mat))
			k += 1

		if is_sealed_top:
			# `capped`: no gold gap, no AXIOM bar. A solid cool-white slab seals
			# the tower — the finished foundation the theorem denies. Nulls keep
			# the per-level arrays index-aligned for _process.
			_own(_cylinder(Vector3(0.0, y + 0.007 + CAP_H * 0.5, 0.0), CAP_R, CAP_H,
				_matte_mat(cool_white, 0.35, 0.10)))
			_gap_mats.append(null)
			_gaps.append(null)
			_patch_bars.append(null)
		else:
			# the gold Godel-gap: a glowing disc set in this level's floor
			var gmat: StandardMaterial3D = _t_glow(gap_gold, 1.2)
			_gap_mats.append(gmat)
			var gap: MeshInstance3D = _cylinder(Vector3(0.0, y + 0.012, r * 0.30), gap_r, 0.012, gmat)
			_gaps.append(gap)
			_own(gap)

			# the AXIOM patch bar that drops into the gap (starts lifted above)
			var bar_root: Node3D = Node3D.new()
			var bar_mat: StandardMaterial3D = _t_glow(patch_cyan, 1.0)
			bar_root.add_child(_box(Vector3.ZERO, Vector3(0.14, 0.03, 0.14), bar_mat))
			bar_root.add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.10, 0.012, 0.10), _matte_mat(cool_white, 0.5)))
			bar_root.position = Vector3(0.0, y + 0.30, r * 0.30)
			_patch_bars.append(bar_root)
			_own(bar_root)

		# tiny level tag
		_own(_billboard_label("S%d" % (lvl + 1), Vector3(-r - 0.02, y + 0.04, 0.0), 13, level_blue))
		lvl += 1

	# axiom-ladder label up the side
	_own(_billboard_label("+ AXIOM", Vector3(0.34, _base_y + _pitch * 0.5, 0.34), 12, patch_cyan))

	# --- title ---
	var top_y: float = _base_y + float(_n - 1) * _pitch
	if regress == "capped":
		top_y += CAP_H
	_own(_billboard_label("INCOMPLETENESS TOWER", Vector3(0.0, top_y + 0.42, 0.0), 28, cool_white))
	if regress == "capped":
		# The claim on the floor. The sequence around it is the counter-argument.
		_own(_billboard_label("the system is complete", Vector3(0.0, top_y + 0.30, 0.0), 13, cool_white))
	else:
		_own(_billboard_label("patch the gap — a new gap opens above", Vector3(0.0, top_y + 0.30, 0.0), 13, gap_gold))

	_apply_emissive()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _n <= 0:
		return
	_t += delta

	# A patch-pulse climbs the tower. At any moment the "active" level is being
	# patched (its gap closes as the AXIOM bar drops); the level just above has
	# its fresh gap flaring open. Everything cycles upward and wraps.
	var travel: float = fmod(_t / climb_period, 1.0) * float(_n)  # 0.._n

	var lvl: int = 0
	while lvl < _n:
		# distance of this level from the climbing pulse front
		var d: float = travel - float(lvl)
		# patch progress for this level: 0 = gap wide open (gold), 1 = patched (closed/cyan)
		var patched: float = 0.0
		var bar_drop: float = 0.0
		if d >= 0.0 and d < 1.0:
			# the pulse is currently AT this level — patch it as the front passes
			patched = _smooth(d)
			bar_drop = _smooth(d)
		elif d >= 1.0:
			# pulse has gone above — this level stays patched (until the wrap reopens it)
			patched = 1.0
			bar_drop = 1.0
		else:
			# pulse not here yet — gap wide open, bar lifted
			patched = 0.0
			bar_drop = 0.0

		# the gap disc: gold + large when open, cools to cyan + shrinks when patched
		if lvl < _gap_mats.size() and _gap_mats[lvl] != null:
			var gm: StandardMaterial3D = _gap_mats[lvl]
			var col: Color = gap_gold.lerp(patch_cyan, patched)
			gm.albedo_color = col
			gm.emission = col
			var flare: float = (1.0 - patched)  # open gaps flare
			gm.emission_energy_multiplier = (0.5 + flare * 1.2 + 0.25 * sin(_t * 5.0) * flare) if emissive else 0.0
		if lvl < _gaps.size() and is_instance_valid(_gaps[lvl]):
			var s: float = lerpf(1.0, 0.25, patched)  # open=full, patched=nearly gone
			_gaps[lvl].scale = Vector3(s, 1.0, s)

		# the AXIOM bar drops into the gap as it patches, lifts back when reopened
		if lvl < _patch_bars.size() and is_instance_valid(_patch_bars[lvl]):
			var y: float = _base_y + float(lvl) * _pitch
			var lifted: float = y + 0.30
			var seated: float = y + 0.03
			_patch_bars[lvl].position.y = lerpf(lifted, seated, bar_drop)
			_patch_bars[lvl].rotation.y = _t * 1.2

		# ring edge brightens on the level currently being worked
		if lvl < _rings.size() and _rings[lvl] != null:
			var active: float = 0.0
			if d >= -0.3 and d < 1.0:
				active = 1.0 - clampf(absf(d - 0.3), 0.0, 1.0)
			_rings[lvl].emission_energy_multiplier = (0.7 + active * 1.0) if emissive else 0.0

		lvl += 1


func _smooth(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
