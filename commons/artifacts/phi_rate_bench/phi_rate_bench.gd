extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PhiRateBench

## @identity
## name: Phi Rate Bench
## concept: phi (rate & becoming) — φ·ΔE(S,t) in QFE = F − λE(S) + φΔE(S,t)
## tier: medium
## truth: some forms are preserved only by being kept in motion — freeze the rate and they die.
##
## A floor-standing QFEP instrument staging φ as sensitivity to the RATE of change (ΔE/Δt).
## A pattern — a standing wave column / a flame of ~60 units — exists ONLY while it moves.
## The instrument periodically "freezes" the rate to zero: the form instantly slumps, greys,
## and collapses to a dead pile. Let the rate return and it springs back to life. A readout
## tracks "ΔE/Δt" rising and falling with the motion.

@export var unit_count: int = 60
@export var column_radius: float = 0.16
@export var column_height: float = 0.9
@export var column_center: Vector3 = Vector3(0.0, 1.05, 0.0)
@export var freeze_period: float = 8.0        # seconds between freeze events
@export var alive_color: Color = Color(0.4, 0.95, 1.0)
@export var hot_color: Color = Color(0.7, 0.95, 1.0)
@export var dead_color: Color = Color(0.32, 0.34, 0.4)

## AXIS — COMPLEMENT: what this bench shows of the equation it does NOT run.
##
## The token says "rate", and the axis is not one — a rate is invisible in a still,
## and the freeze cycle here is already the demonstration. Read what the rate is FOR:
## "some forms are preserved only by being kept in motion." That is not a claim about
## tempo, it is a claim about EXISTENCE — this column has no persisting substance to
## fall back on, so the moment φ·ΔE stops being paid it is a heap on the floor. φ is
## what buys presence, per second, forever.
##
## Which is exactly why the bench cannot honestly stand alone. QFE = F − λE(S) +
## φΔE(S,t): a rate term is a rate of change OF something, priced against an F it is
## buying and a λE it is spending. Alone on a plinth, φ is a bill with no account.
## The bench prints "ΔE/Δt = 1.00 MOVING = ALIVE" and nothing on the furniture records
## that two thirds of the sentence is missing. So the axis is the record: how much of
## its own complement does this bench admit is missing?
##
##   none       nothing — the legacy lineage, byte for byte. φ alone, unremarked.
##   ghost      two dead mounts on the deck: capped stubs, blanked grey face plates,
##              unlit F and λ tags. Provision was made for them and never fitted.
##   supply     two lit tributary conduits rise from the deck into the emitter ring at
##              the column's foot. The rate is not self-standing; it is being fed.
##   redaction  a bone-white plate across the front carrying the whole formula, with
##              F and λE(S) struck under black bars and φΔE boxed in accent. The bench
##              prints what it cut.
##   quorum     two lit satellite dials stand with the column, F and λ present and
##              linked in. Three terms in session; one of them speaking.
##
## Shared word for word with [[f_order_bench]], [[lambda_dial_bench]] and
## [[qfep_reactor_bench]] — one equation, one vocabulary. It would be incoherent for
## the φ bench and the λ bench to speak differently about the same formula.
@export_enum("none", "ghost", "supply", "redaction", "quorum") var complement: String = "none"
const COMPLEMENTS: PackedStringArray = ["none", "ghost", "supply", "redaction", "quorum"]

## Seed for the helical twist offsets + wave phases. −1 keeps today's behaviour
## (randomize on every spawn); any value ≥ 0 makes the column reproducible, which is
## what a sweep needs — otherwise five variants of an axis are also five different
## columns, and the noise is measured as the axis.
@export var column_seed: int = -1

# The two terms this bench does not run — glyph, and the colour the family gives it.
const COMP_A_GLYPH := "F"
const COMP_A_COLOR := Color(0.55, 0.92, 0.99)
const COMP_B_GLYPH := "λ"
const COMP_B_COLOR := Color(0.62, 0.55, 0.98)
# Where the complement hardware stands: flank offset, deck height, forward offset.
# Deliberately inside the existing silhouette (the meter rail already reaches x −0.48,
# the column y 1.50) so a variant is not also a different camera distance.
const COMP_X := 0.34
const COMP_Y := 0.145
const COMP_Z := 0.10

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _count: int = 0
var _base_ang: PackedFloat32Array = PackedFloat32Array()
var _base_h: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _rate_bar: MeshInstance3D
var _rate_bar_mat: StandardMaterial3D
var _t: float = 0.0
var _rate: float = 1.0      # 0 = frozen (dead), 1 = full motion (alive)


func _ready() -> void:
	_read_dna_meta()
	if column_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = column_seed
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("complement"):
		var c_in: String = str(config["complement"]).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if config.has("column_seed"):
		column_seed = int(str(config["column_seed"]))
		if column_seed >= 0:
			_rng.seed = column_seed
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the first
# build; apply_grid_config (deferred) covers the rebuild path. Unknown words keep the
# default — an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_complement"):
		var c_in: String = str(get_meta("config_complement")).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if has_meta("config_column_seed"):
		column_seed = int(str(get_meta("config_column_seed")))


func _build() -> void:
	_count = unit_count

	# --- plinth + post ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.44, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.38, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.05, 0.5, _steel_mat(Color(0.4, 0.5, 0.7))))
	# emitter ring at the base of the flame/wave
	add_child(_torus(column_center + Vector3(0.0, -column_height * 0.5 - 0.02, 0.0), column_radius + 0.04, 0.02, _glow_mat(alive_color, 2.2)))

	# --- title + readout ---
	_title = _billboard_label("φ  —  RATE & BECOMING", Vector3(0.0, 1.72, 0.0), 22, Color(0.88, 0.95, 1.0))
	add_child(_title)
	add_child(_billboard_label("φ·ΔE/Δt  —  alive only while moving", Vector3(0.0, 1.58, 0.0), 14, Color(0.7, 0.78, 0.92)))
	_readout = _billboard_label("ΔE/Δt", Vector3(0.46, 1.34, 0.0), 22, alive_color)
	add_child(_readout)

	# --- ΔE/Δt meter rail + fill ---
	add_child(_box(Vector3(-0.46, 1.05, 0.0), Vector3(0.04, 0.55, 0.04), _matte_mat(Color(0.1, 0.13, 0.2))))
	_rate_bar_mat = _glow_mat(alive_color, 2.2)
	_rate_bar = _box(Vector3(-0.46, 1.05, 0.0), Vector3(0.05, 0.55, 0.05), _rate_bar_mat)
	add_child(_rate_bar)
	add_child(_billboard_label("ΔE/Δt", Vector3(-0.46, 1.4, 0.0), 14, Color(0.85, 0.9, 1.0)))

	# --- the form: a column of units arranged as a helix/flame ---
	_base_ang.resize(_count)
	_base_h.resize(_count)
	_phase.resize(_count)
	for i in range(_count):
		_base_h[i] = float(i) / float(_count)                       # 0..1 up the column
		_base_ang[i] = _base_h[i] * TAU * 3.0 + _rng.randf() * 0.3   # helical twist
		_phase[i] = _rng.randf() * TAU
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = _count
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.03
	sph.height = 0.06
	sph.radial_segments = 7
	sph.rings = 4
	_mm.mesh = sph
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "StandingWave"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(Color(1, 1, 1), 2.2)
	add_child(_mm_inst)

	_apply_form()

	# COMPLEMENT dressing, appended LAST so every child index and position above is
	# untouched on the legacy path. "none" falls through and adds nothing at all.
	match complement:
		"ghost":
			_comp_ghost()
		"supply":
			_comp_supply()
		"redaction":
			_comp_redaction()
		"quorum":
			_comp_quorum()
		_:
			pass                                  # "none" — the legacy lineage


func _apply_form() -> void:
	# rate 1 → a coherent living standing wave / flame; rate 0 → collapsed dead pile.
	var bottom: float = column_center.y - column_height * 0.5
	for i in range(_count):
		var h01: float = _base_h[i]
		# alive height taper (flame narrows toward the top)
		var taper: float = 1.0 - h01 * 0.6
		var rad: float = column_radius * taper
		# the wave: angle + radial breathing driven by time × rate
		var ang: float = _base_ang[i] + _t * 2.5 * _rate
		var breath: float = 1.0 + 0.35 * sin(_t * 4.0 * _rate + _phase[i])
		var alive_pos: Vector3 = Vector3(
			cos(ang) * rad * breath,
			bottom + h01 * column_height + sin(_t * 5.0 * _rate + _phase[i]) * 0.04 * _rate,
			sin(ang) * rad * breath)
		# dead pose: everything slumps to a low disordered pile at the base
		var dead_pos: Vector3 = Vector3(
			cos(_phase[i]) * column_radius * 1.3 * h01 * 0.4,
			bottom + h01 * 0.12,
			sin(_phase[i]) * column_radius * 1.3 * h01 * 0.4)
		var pos: Vector3 = column_center + dead_pos.lerp(alive_pos, _rate)
		_mm.set_instance_transform(i, Transform3D(Basis(), pos))
		var col: Color = dead_color.lerp(alive_color.lerp(hot_color, h01), _rate)
		_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Most of the time fully alive (rate≈1). Periodically the rate is frozen to ~0,
	# the form collapses, then the rate returns and it springs back.
	var phase: float = fmod(_t, freeze_period) / freeze_period
	if phase > 0.72 and phase < 0.86:
		# brief freeze window: rate dives to ~0 (form dies)
		var f: float = (phase - 0.72) / 0.14         # 0..1 across the window
		_rate = 1.0 - sin(f * PI) * 0.96             # dip to ~0.04 and back
	else:
		_rate = 1.0
	_apply_form()

	# meter + readout follow the rate
	if _rate_bar != null:
		var hh: float = clampf(_rate, 0.02, 1.0) * 0.55
		var bm: BoxMesh = _rate_bar.mesh as BoxMesh
		bm.size = Vector3(0.05, hh, 0.05)
		_rate_bar.position = Vector3(-0.46, (1.05 - 0.275) + hh * 0.5, 0.0)
		_rate_bar_mat.emission = dead_color.lerp(alive_color, _rate)
	if _readout != null:
		if _rate < 0.2:
			_readout.text = "ΔE/Δt → 0\nFROZEN = DEAD"
			_readout.modulate = dead_color
		else:
			_readout.text = "ΔE/Δt = %.2f\nMOVING = ALIVE" % _rate
			_readout.modulate = alive_color.lerp(hot_color, _rate)


# ── COMPLEMENT ───────────────────────────────────────────────────────────────
# Five values, four builders, appended after everything else. The gestures are
# identical across the four QFEP benches — only the anchors and the two absent
# glyphs change — so a room of them reads as one instrument family taking one
# position on its own isolation.

# Where the missing terms would plug in: the emitter ring at the column's foot.
func _comp_hub() -> Vector3:
	return column_center + Vector3(0.0, -column_height * 0.5, 0.0)


## Engraved text: NOT _billboard_label. Depth-tested and non-billboard so the black
## redaction bars can actually cover it, and so LabelFramer leaves it alone (it frames
## hanging billboards, and this text lies on a body already).
func _comp_ink(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.modulate = col
	l.outline_size = 0
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.position = pos
	return l


## GHOST — provision, unfitted. A capped stub on the deck carrying a blanked face
## plate with the term's tag on it, all unlit. Grey and not black on purpose: the
## capture stage is near-black, and a black value is an invisible one.
func _comp_ghost_one(sx: float, glyph: String) -> void:
	var post_mat: StandardMaterial3D = _matte_mat(Color(0.34, 0.36, 0.42), 0.85, 0.3)
	var face_mat: StandardMaterial3D = _matte_mat(Color(0.21, 0.22, 0.27), 0.95, 0.1)
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.15, COMP_Z), 0.05, 0.30, post_mat))
	add_child(_torus(Vector3(sx, COMP_Y + 0.30, COMP_Z), 0.075, 0.016, post_mat))
	add_child(_box(Vector3(sx, COMP_Y + 0.42, COMP_Z), Vector3(0.23, 0.27, 0.02), post_mat))
	add_child(_box(Vector3(sx, COMP_Y + 0.42, COMP_Z + 0.016), Vector3(0.20, 0.24, 0.02), face_mat))
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.42, COMP_Z + 0.035), 26, Color(0.52, 0.54, 0.60)))


func _comp_ghost() -> void:
	_comp_ghost_one(-COMP_X, COMP_A_GLYPH)
	_comp_ghost_one(COMP_X, COMP_B_GLYPH)


## SUPPLY — the term is fed. A lit conduit rises off the deck and elbows into the
## emitter ring, in the colour the family gives that term, tagged at the base.
func _comp_supply_one(sx: float, glyph: String, col: Color) -> void:
	var lit: StandardMaterial3D = _glow_mat(col, 1.6)
	add_child(_torus(Vector3(sx, COMP_Y + 0.02, COMP_Z), 0.07, 0.018, _steel_mat(col.darkened(0.45))))
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.16, COMP_Z), 0.028, 0.28, lit))
	add_child(_cylinder_between(Vector3(sx, COMP_Y + 0.28, COMP_Z), _comp_hub(), 0.026, lit))
	add_child(_box(Vector3(sx, COMP_Y + 0.34, COMP_Z + 0.055), Vector3(0.13, 0.11, 0.015),
		_matte_mat(Color(0.87, 0.86, 0.82), 0.55)))
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.34, COMP_Z + 0.07), 20, Color(0.10, 0.11, 0.15)))


func _comp_supply() -> void:
	_comp_supply_one(-COMP_X, COMP_A_GLYPH, COMP_A_COLOR)
	_comp_supply_one(COMP_X, COMP_B_GLYPH, COMP_B_COLOR)
	add_child(_torus(_comp_hub(), 0.09, 0.02, _steel_mat(Color(0.55, 0.60, 0.72))))


## REDACTION — the bench prints what it cut. A bone plate across the front carries the
## whole formula; the term this bench runs is boxed in accent, the other two are struck
## under matte-black bars. `keep` is the slot that survives: 0 = F, 1 = λE, 2 = φΔE.
func _comp_formula_plate(keep: int) -> void:
	var py: float = 0.36
	var pz: float = 0.155
	var bone: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.82), 0.55)
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.52))
	var bar: StandardMaterial3D = _matte_mat(Color(0.05, 0.05, 0.07), 0.98)
	add_child(_cylinder_between(Vector3(0.0, py, 0.03), Vector3(0.0, py, pz - 0.012), 0.02, steel))
	add_child(_box(Vector3(0.0, py, pz - 0.012), Vector3(0.78, 0.26, 0.02), steel))
	add_child(_box(Vector3(0.0, py, pz), Vector3(0.74, 0.22, 0.02), bone))
	add_child(_comp_ink("QFE =", Vector3(-0.20, py, pz + 0.02), 13, Color(0.10, 0.11, 0.15)))
	var slot_x: PackedFloat32Array = PackedFloat32Array([-0.065, 0.055, 0.225])
	var slot_w: PackedFloat32Array = PackedFloat32Array([0.075, 0.135, 0.175])
	var slot_t: PackedStringArray = PackedStringArray(["F", "- λE", "+ φΔE"])
	for i in range(3):
		if i == keep:
			add_child(_box(Vector3(slot_x[i], py, pz + 0.011),
				Vector3(slot_w[i] + 0.03, 0.15, 0.006), _glow_mat(alive_color, 1.4)))
			add_child(_comp_ink(slot_t[i], Vector3(slot_x[i], py, pz + 0.025), 13,
				Color(0.06, 0.07, 0.10)))
		else:
			add_child(_box(Vector3(slot_x[i], py, pz + 0.015),
				Vector3(slot_w[i] + 0.02, 0.135, 0.012), bar))


func _comp_redaction() -> void:
	_comp_formula_plate(2)


## QUORUM — three terms in session. Two lit satellite dials stand with the column,
## each tied back into the emitter: the bench admits it cannot mean anything alone.
func _comp_quorum_one(sx: float, glyph: String, col: Color) -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.55, 0.60, 0.72))
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.24, COMP_Z), 0.035, 0.48, steel))
	add_child(_box(Vector3(sx, COMP_Y + 0.50, COMP_Z), Vector3(0.20, 0.20, 0.015),
		_matte_mat(Color(0.88, 0.90, 0.94), 0.4)))
	var ring: MeshInstance3D = _torus(Vector3(sx, COMP_Y + 0.50, COMP_Z + 0.012), 0.115, 0.014,
		_glow_mat(col, 2.0))
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(ring)
	var needle: MeshInstance3D = _box(Vector3(sx, COMP_Y + 0.548, COMP_Z + 0.03),
		Vector3(0.014, 0.085, 0.012), _glow_mat(Color(1.0, 0.85, 0.40), 2.2))
	needle.rotation_degrees = Vector3(0.0, 0.0, 22.0)
	add_child(needle)
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.455, COMP_Z + 0.03), 20, Color(0.10, 0.11, 0.15)))
	add_child(_cylinder_between(Vector3(sx, COMP_Y + 0.50, COMP_Z),
		_comp_hub() + Vector3(0.0, -0.02, 0.0), 0.014, _glow_mat(col, 1.2)))


func _comp_quorum() -> void:
	_comp_quorum_one(-COMP_X, COMP_A_GLYPH, COMP_A_COLOR)
	_comp_quorum_one(COMP_X, COMP_B_GLYPH, COMP_B_COLOR)
