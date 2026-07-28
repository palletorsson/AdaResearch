extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ProvabilitySorter

## @identity
## name: Provability Sorter
## lineage: the semantic picture of Godel — the set of TRUE statements strictly
##   contains the set of PROVABLE statements. Tarski-flavoured: truth outruns
##   proof.
## essence: two nested rings on a low plinth — an inner ring PROVABLE inside an
##   outer ring TRUE. Statement-tokens (small spheres) rain down and sort: most
##   settle in the inner PROVABLE disc, but some land in the gold GAP band
##   between the rings — "TRUE BUT UNPROVABLE" — where the Godel sentence sits
##   glowing, never falling inward.
## truth: the provable is a proper subset of the true. The gold band is never
##   empty and never closes; some truths have no proof.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var true_blue: Color = Color(0.40, 0.62, 0.95)
@export var provable_cyan: Color = Color(0.45, 0.85, 0.92)
@export var gap_gold: Color = Color(1.0, 0.78, 0.30)
@export var token_count: int = 22
@export var inner_radius: float = 0.24
@export var outer_radius: float = 0.46
@export var plinth_y: float = 0.30

# ═══════════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — reach
# ═══════════════════════════════════════════════════════════════════════
#
## How far proof reaches into the true — the size of the gold remainder, which
## is this artifact's entire quantitative claim and was, until now, the magic
## literal 0.28 buried in _build_tokens(). The ladder is a real ordering a map
## can point at:
##
##   complete  the inner PROVABLE ring is built AT the outer TRUE radius, so the
##             two rings this object exists to separate are shown fused. No gold
##             band, no gap label, no Godel sentence, every token cyan. The
##             Hilbert picture, drawn honestly: proof exhausts truth.
##   hairline  inner 0.43 against outer 0.46 — a 0.03 m gold line and exactly 2
##             gold tokens. How a confident formalism draws its own exception:
##             conceded, technical, nearly invisible.
##   proper    THE SHIPPED LOOK. Inner 0.24, outer 0.46, an 0.11 m gold band,
##             the 0.28 probabilistic draw untouched, the G sphere at 0.35.
##   chasm     inner 0.10 against outer 0.46 — an 0.18 m gold band, 16 of 22
##             tokens gold, the cyan disc reduced to a 0.09 m coin. How a
##             sceptic draws it: most truths are outside the reach of any proof.
##   total     no inner ring, no cyan disc, no PROVABLE label. The gold band is
##             a filled 0.46 m disc and every token lands on it — a system that
##             proves nothing at all.
##
## Radii and token colour are the most room-legible knobs this object owns, and
## nothing on the ladder depends on reading a caption. Set BEFORE _ready() (the
## sweep path) or via the `reach` config key.
@export_enum("complete", "hairline", "proper", "chasm", "total") var reach: String = "proper"

## Allow-list for the token parser. A misspelling in a map falls back to the
## value already in force rather than half-resolving into a build no one asked
## for — this artifact stands in two shipped maps.
const REACHES: PackedStringArray = ["complete", "hairline", "proper", "chasm", "total"]

## Fixed RNG seed. The token scatter used to call _rng.randomize(), so two runs
## of the SAME configuration produced different stills and a pixel critic would
## read the noise as axis signal. The distribution is unchanged; only its draw
## is now repeatable.
const BUILD_SEED: int = 731701

var _t: float = 0.0
var _mm_inst: MultiMeshInstance3D
var _mm: MultiMesh
var _drop_t: PackedFloat32Array = PackedFloat32Array()    # per-token fall progress phase offset
var _is_gap: PackedInt32Array = PackedInt32Array()        # 1 = lands in the gold gap
var _ang: PackedFloat32Array = PackedFloat32Array()       # resting angle on its ring
var _rest_r: PackedFloat32Array = PackedFloat32Array()    # resting radius
var _spawn_r: PackedFloat32Array = PackedFloat32Array()   # x offset at spawn (above)
var _spawn_z: PackedFloat32Array = PackedFloat32Array()
var _godel_dot: MeshInstance3D
var _godel_mat: StandardMaterial3D
var _gap_ring_mat: StandardMaterial3D

# --- lifecycle bookkeeping ---------------------------------------------------
# Only nodes THIS script created are ever freed. get_children() also holds the
# label plates, packaging and tag markers the grid adds after us.
var _built: bool = false
var _owned: Array[Node] = []
var _mats: Array[StandardMaterial3D] = []
var _mat_on: PackedFloat32Array = PackedFloat32Array()
var _mat_off: PackedFloat32Array = PackedFloat32Array()

# --- geometry resolved from `reach`, read by _build/_build_tokens ------------
var _r_inner: float = 0.24
var _r_outer: float = 0.46
var _gap_r: float = 0.35
var _gap_tube: float = 0.105
var _fill_r: float = 0.23
var _has_inner_ring: bool = true
var _has_gap_band: bool = true
var _gap_band_is_disc: bool = false
var _has_fill_disc: bool = true
var _has_godel: bool = true
var _has_provable_label: bool = true
var _has_gap_label: bool = true
var _gold_count: int = -1     # -1 = keep the shipped 0.28 probabilistic draw


func _ready() -> void:
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


## Contract: runs AFTER _ready(), via call_deferred, ahead of label framing and
## auto-grounding. curation_station calls it with {"emissive": false} one line
## after hiding the labels — so a change of `emissive` alone must NOT rebuild,
## or the fresh billboarded labels discard the framing applied a moment earlier.
## Emissive is therefore retuned on the live materials in place.
func apply_grid_config(config: Dictionary) -> void:
	var before_reach: String = reach
	var before_inner: float = inner_radius
	var before_outer: float = outer_radius
	var before_tokens: int = token_count

	if config.has("emissive"):
		emissive = bool(config["emissive"])
		_apply_emissive()
	if config.has("reach"):
		reach = _pick_axis(str(config["reach"]), REACHES, reach)
	if config.has("inner_radius"):
		inner_radius = clampf(float(config["inner_radius"]), 0.02, 1.20)
	if config.has("outer_radius"):
		outer_radius = clampf(float(config["outer_radius"]), 0.04, 1.50)
	if config.has("token_count"):
		token_count = clampi(int(config["token_count"]), 1, 200)

	if not _built:
		return
	if reach == before_reach \
			and is_equal_approx(inner_radius, before_inner) \
			and is_equal_approx(outer_radius, before_outer) \
			and token_count == before_tokens:
		return    # nothing structural moved — say nothing, touch nothing
	_rebuild_now()
	print("[ProvabilitySorter] Config applied — reach=%s, rings=%.2f/%.2f" % [
		reach, _r_inner, _r_outer])


## Accept an axis value only if it names something we actually build. A typo has
## to land on the value already in force; a half-recognised value would strand a
## shipped placement with rings it never asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. No call_deferred anywhere in the build path:
## a deferred rebuild leaves the node empty for a frame, _auto_ground_artifact
## measures a zero AABB, returns early, and the artifact never grounds.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_mats.clear()
	_mat_on.resize(0)
	_mat_off.resize(0)
	_mm = null
	_mm_inst = null
	_godel_dot = null
	_godel_mat = null
	_gap_ring_mat = null
	_build()


func _own(n: Node) -> Node:
	_owned.append(n)
	add_child(n)
	return n


## Record a material with its lit and unlit emission energies so `emissive` can
## be retuned later without freeing anything.
func _track(m: StandardMaterial3D, on_e: float, off_e: float) -> StandardMaterial3D:
	_mats.append(m)
	_mat_on.append(on_e)
	_mat_off.append(off_e)
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	return _track(_glow_mat(c, energy), energy, energy * 0.3)


func _steel(c: Color) -> StandardMaterial3D:
	return _track(_steel_mat(c), 0.1, 0.0)


func _glass(c: Color, alpha: float) -> StandardMaterial3D:
	return _track(_glass_mat(c, alpha), 0.3, 0.0)


func _apply_emissive() -> void:
	var i: int = 0
	while i < _mats.size():
		var m: StandardMaterial3D = _mats[i]
		if m != null:
			m.emission_energy_multiplier = _mat_on[i] if emissive else _mat_off[i]
		i += 1


# ═══════════════════════════════════════════════════════════════════════
# AXIS RESOLUTION
# ═══════════════════════════════════════════════════════════════════════

## Turn `reach` into the geometry the build reads. `proper` is the ONLY value
## that reads inner_radius / outer_radius from the exports — the shipped
## placements and any map that ever sets a radius must be untouched by this
## promotion. The other four state their radii outright, because a severity
## ladder that scaled off whatever the map happened to set would not be a ladder.
func _resolve_reach() -> void:
	# defaults = the shipped picture
	_r_inner = inner_radius
	_r_outer = outer_radius
	_has_inner_ring = true
	_has_gap_band = true
	_gap_band_is_disc = false
	_has_fill_disc = true
	_has_godel = true
	_has_provable_label = true
	_has_gap_label = true
	_gold_count = -1

	match reach:
		"complete":
			# PROVABLE built at the TRUE radius: one ring wearing two names.
			_r_inner = 0.46
			_r_outer = 0.46
			_has_gap_band = false
			_has_godel = false
			_has_gap_label = false
			_gold_count = 0
		"hairline":
			_r_inner = 0.43
			_r_outer = 0.46
			_gold_count = 2
		"proper":
			pass    # exports, verbatim — see the doc comment above
		"chasm":
			_r_inner = 0.10
			_r_outer = 0.46
			_gold_count = 16
		"total":
			# nothing proves anything: the gold reaches the centre.
			_r_inner = 0.0
			_r_outer = 0.46
			_has_inner_ring = false
			_gap_band_is_disc = true
			_has_fill_disc = false
			_has_provable_label = false
			_gold_count = token_count

	_gap_r = (_r_inner + _r_outer) * 0.5
	_gap_tube = maxf((_r_outer - _r_inner) * 0.5 - 0.005, 0.0)
	_fill_r = maxf(_r_inner - 0.01, 0.0)
	if _gap_band_is_disc:
		# the G sentence still has to sit somewhere legible on the filled disc
		_gap_r = _r_outer * 0.5
	if _gold_count > token_count:
		_gold_count = token_count


# ═══════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════

func _build() -> void:
	_t = 0.0
	_rng.seed = BUILD_SEED
	_resolve_reach()

	# --- low plinth the rings rest on ---
	var plinth_mat: StandardMaterial3D = _steel(Color(0.30, 0.32, 0.40))
	_own(_cylinder(Vector3(0.0, plinth_y - 0.04, 0.0), _r_outer + 0.06, 0.08, plinth_mat))
	# faint plinth top disc
	var top_mat: StandardMaterial3D = _glow(Color(0.20, 0.22, 0.30), 0.2)
	_own(_cylinder(Vector3(0.0, plinth_y + 0.005, 0.0), _r_outer + 0.04, 0.01, top_mat))

	# --- the gold GAP band between the rings (the proper-subset annulus) ---
	if _has_gap_band:
		_gap_ring_mat = _glow(gap_gold, 0.7)
		if _gap_band_is_disc:
			# `total`: the remainder is the whole disc, so it is drawn as one.
			_own(_cylinder(Vector3(0.0, plinth_y + 0.012, 0.0), _r_outer, 0.012, _gap_ring_mat))
		else:
			# a flat torus filling the mid radius, gold — home of TRUE-but-unprovable
			var gap_band: MeshInstance3D = _torus(
				Vector3(0.0, plinth_y + 0.012, 0.0), _gap_r, _gap_tube, _gap_ring_mat)
			gap_band.scale = Vector3(1.0, 0.10, 1.0)  # flatten into a band on the plinth
			_own(gap_band)

	# --- outer ring: TRUE ---
	var true_mat: StandardMaterial3D = _glow(true_blue, 1.0)
	_own(_torus(Vector3(0.0, plinth_y + 0.02, 0.0), _r_outer, 0.012, true_mat))
	_own(_billboard_label("TRUE", Vector3(0.0, plinth_y + 0.10, -_r_outer - 0.02), 18, true_blue))

	# --- inner ring: PROVABLE ---
	if _has_inner_ring:
		var prov_mat: StandardMaterial3D = _glow(provable_cyan, 1.0)
		# `complete` puts this ring at the TRUE radius; lift it 4 mm so the two
		# coincident tori read as fused rather than as z-fighting confetti.
		var ring_y: float = plinth_y + 0.02
		if is_equal_approx(_r_inner, _r_outer):
			ring_y += 0.004
		_own(_torus(Vector3(0.0, ring_y, 0.0), _r_inner, 0.012, prov_mat))
	if _has_fill_disc:
		# faint inner disc to read it as a filled region
		var prov_fill: StandardMaterial3D = _glass(provable_cyan, 0.16)
		_own(_cylinder(Vector3(0.0, plinth_y + 0.015, 0.0), _fill_r, 0.006, prov_fill))
	if _has_provable_label:
		_own(_billboard_label("PROVABLE", Vector3(0.0, plinth_y + 0.16, 0.0), 16, provable_cyan))

	# gap label
	if _has_gap_label:
		_own(_billboard_label("TRUE BUT UNPROVABLE",
			Vector3(0.0, plinth_y + 0.30, _r_outer + 0.04), 14, gap_gold))

	# --- the Godel sentence: a fixed glowing token sitting in the gap ---
	if _has_godel:
		_godel_mat = _glow(gap_gold, 1.6)
		_godel_dot = _sphere(Vector3(_gap_r, plinth_y + 0.05, 0.0), 0.034, _godel_mat)
		_own(_godel_dot)
		_own(_billboard_label("G", Vector3(_gap_r, plinth_y + 0.13, 0.0), 18, gap_gold))

	# --- the raining statement-tokens (MultiMesh) ---
	_build_tokens()

	# --- title ---
	_own(_billboard_label("PROVABILITY SORTER", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	_own(_billboard_label("the provable is a proper part of the true",
		Vector3(0.0, 1.36, 0.0), 14, wire_purple))

	_apply_emissive()


func _build_tokens() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.022
	sphere.height = 0.044
	sphere.radial_segments = 8
	sphere.rings = 4
	var mat: StandardMaterial3D = _glow(cool_white, 0.7)
	sphere.material = mat

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = sphere
	_mm.instance_count = token_count

	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.multimesh = _mm
	_own(_mm_inst)

	_drop_t.resize(token_count)
	_is_gap.resize(token_count)
	_ang.resize(token_count)
	_rest_r.resize(token_count)
	_spawn_r.resize(token_count)
	_spawn_z.resize(token_count)

	# Exact-count modes name a number of gold tokens rather than a probability.
	# Which tokens get it is a seeded shuffle, so the scatter is repeatable but
	# not a visible arc. `proper` skips this entirely and keeps its 0.28 draw.
	var gold_flags: PackedInt32Array = PackedInt32Array()
	gold_flags.resize(token_count)
	if _gold_count >= 0:
		var order: Array[int] = []
		for q in range(token_count):
			order.append(q)
		var j: int = token_count - 1
		while j > 0:
			var k: int = _rng.randi_range(0, j)
			var tmp: int = order[j]
			order[j] = order[k]
			order[k] = tmp
			j -= 1
		var n: int = clampi(_gold_count, 0, token_count)
		var m: int = 0
		while m < n:
			gold_flags[order[m]] = 1
			m += 1

	var i: int = 0
	while i < token_count:
		_drop_t[i] = _rng.randf()                        # stagger the fall
		var gap: bool
		if _gold_count >= 0:
			gap = gold_flags[i] == 1
		else:
			# roughly 1 in 4 lands in the gold gap (true-but-unprovable); rest provable
			gap = (_rng.randf() < 0.28)
		_is_gap[i] = 1 if gap else 0
		_ang[i] = _rng.randf() * TAU
		if gap:
			if _gap_band_is_disc:
				# `total`: nothing bounds it inward, so it can land anywhere
				_rest_r[i] = _rng.randf() * maxf(_r_outer - 0.03, 0.0)
			else:
				# jitter never exceeds the band it is jittering inside — at
				# `hairline` the band is 0.01 m of half-width and ±0.02 would
				# throw gold tokens onto bare plinth.
				var jit: float = minf(0.02, _gap_tube)
				_rest_r[i] = _gap_r + _rng.randf_range(-jit, jit)
		else:
			_rest_r[i] = _rng.randf() * maxf(_fill_r - 0.03, 0.0)
		# spawn somewhere above the disc
		var sr: float = _rng.randf() * _r_outer
		var sa: float = _rng.randf() * TAU
		_spawn_r[i] = cos(sa) * sr
		_spawn_z[i] = sin(sa) * sr
		# Seed the buffer at REST, not at spawn height. Under _process this frame is
		# overwritten within 1/60 s, so nothing about a running placement changes —
		# but a still taken with no process pass now shows the SORTED state, which
		# is the whole claim, instead of an undifferentiated cloud in mid-air.
		var bx := Basis().scaled(Vector3.ONE)
		_mm.set_instance_transform(i, Transform3D(bx, Vector3(
			cos(_ang[i]) * _rest_r[i], plinth_y + 0.05, sin(_ang[i]) * _rest_r[i])))
		_mm.set_instance_color(i, gap_gold if gap else provable_cyan)
		i += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _mm == null:
		return

	var fall_h: float = 0.9   # spawn height above plinth top
	var period: float = 4.0   # one full fall+reset cycle
	var i: int = 0
	while i < token_count:
		# each token cycles: fall from above to its resting slot, hold, respawn
		var p: float = fmod(_t / period + _drop_t[i], 1.0)
		var rest := Vector3(cos(_ang[i]) * _rest_r[i], plinth_y + 0.05, sin(_ang[i]) * _rest_r[i])
		var spawn := Vector3(_spawn_r[i], plinth_y + 0.05 + fall_h, _spawn_z[i])
		var pos: Vector3
		if p < 0.55:
			# falling — ease the descent, drift x/z toward the resting slot
			var f: float = p / 0.55
			var ef: float = f * f                         # accelerate downward
			pos = spawn.lerp(rest, ef)
			# a little settle bounce near the bottom
			if f > 0.85:
				pos.y += sin((f - 0.85) / 0.15 * PI) * 0.03
		else:
			# resting in its region until the cycle resets
			pos = rest

		var col: Color = gap_gold if _is_gap[i] == 1 else provable_cyan
		var sc: float = 1.0
		if _is_gap[i] == 1:
			# gap tokens pulse — they are the conspicuous remainder
			sc = 1.0 + 0.25 * sin(_t * 3.0 + float(i))
		var b := Basis().scaled(Vector3.ONE * sc)
		_mm.set_instance_transform(i, Transform3D(b, pos))
		_mm.set_instance_color(i, col)
		i += 1

	# the Godel token in the gap breathes and never moves inward
	if is_instance_valid(_godel_dot):
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.2)
		_godel_dot.scale = Vector3.ONE * (1.0 + pulse * 0.18)
	if _godel_mat != null:
		_godel_mat.emission_energy_multiplier = (1.4 + 0.5 * sin(_t * 2.2)) if emissive else 0.0
	if _gap_ring_mat != null:
		_gap_ring_mat.emission_energy_multiplier = (0.6 + 0.25 * sin(_t * 1.6)) if emissive else 0.0
