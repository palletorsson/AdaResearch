# temperament_table.gd
# Temperament Table — a synthesis of chord_tension_spring and harmonic_distance_table
#
# TWELVE SPRINGS ON A RULER. Each spring is one interval above a fixed root: the
# minor second at station 1, the perfect fifth at station 7. Behind them a comb of
# thirteen teeth marks equal temperament — twelve equal steps from the unison to the
# octave — and it never moves at any value of anything.
#
# WHY IT EXISTS. Two artifacts in this corpus declare an axis called
# `consonance_theory` with the same four words: western | blues | ratio | flat.
# chord_tension_spring OWNS the four tables (gd:57-117); harmonic_distance_table
# PRELOADS them rather than copying (gd:50). That looks like one vocabulary held by
# two members. Read from the dispatch instead of the prose, it is not:
#
#   1. NEITHER ARTIFACT'S THEORY TOUCHES A FREQUENCY. chord_tension_spring's
#      _pitch_to_freq (gd:708-712) is 440 * 2^((midi-69)/12) unconditionally, and
#      harmonic_distance_table's _get_note_frequency (gd:556-562) is the same
#      expression. Every value plays 12-TET. So `ratio` does not mean just
#      intonation and `flat` does not mean equal temperament — all four are
#      twelve-entry JUDGEMENT tables about which intervals are tense, at one
#      unchanging tuning. The word is not two questions the way a tuning/repertoire
#      split would make it; it is one question, honestly.
#   2. BUT `western` IS TWO ANSWERS. harmonic_distance_table's _shared_for
#      short-circuits on that one word to its OWN SHARED_OVERTONES (gd:326-328) —
#      integers 1..16 whose largest non-unison entry is the fifth at 5 — and never
#      reaches _CTS.CONSONANCE at all. One word, two arrays, in the same family.
#   3. AND THE TUNING QUESTION IS SITTING IN BOTH FILES AS A CONFESSION.
#      harmonic_distance_table's own QFEP audit (gd:14-20) names it: "a 12-TET fifth
#      is 700 cents vs. a pure 3:2 at ~702 cents", and its registry then DECLINES an
#      axis over it, on a number — 15.6 cents is 0.029 m on that ring, "a real
#      displacement and a weak picture."
#
# This bench is that declined axis, built where it is not a weak picture: the
# deviation is drawn against a comb that does not move, and `comma` magnifies it so a
# still can hold it. The tuning question gets its own axis and its own name, because
# putting it inside `consonance_theory` would invent the false friend this file exists
# to report.
#
# COGNITIVE COMPRESSION TARGET:
#   Temperament stops being a number in cents and becomes a gap. Twelve springs that
#   should stand on twelve teeth, and eleven of them do not.
#
# QFEP AUDIT:
#   The comb is the colonising object here. It asserts that the octave divides into
#   twelve equal parts, which is a decision taken in Europe about 1700 and is
#   observed by almost no tuning tradition before it and by a minority of the world's
#   music since. Under `just` the springs desert it; under `comma` they desert it
#   visibly. But note what the bench still assumes and cannot argue with itself: that
#   there are TWELVE intervals, that the octave is where the ruler ends, and that
#   5-limit ratios are the pure ones. A 22-sruti or 7-equal or 53-comma table would
#   need a different bench, not a different value.
#
extends Node3D
class_name TemperamentTable


# @identity
# essence: gap(i) = 1200*log2(just_ratio(i)) - 100*i — temperament as a distance the grid does not close
# desire: Look down the rail and see which springs stand on their teeth and which have walked off
# critical_parameter: comma_gain — the magnification without which a 15.6 cent error is 8 mm
# triggers: nothing; this is a bench, it is read rather than played
# emerges: equal temperament as a compromise you can see the size of, interval by interval
# needs: no interaction [by design], one still photograph [has]
# relationships: synthesises chord_tension_spring (the spring body, the four tables) and harmonic_distance_table (the interval as a distance); answers the tuning axis that artifact declined
# truth: A temperament is not a tuning, it is a decision about which errors to accept and where to put them.

const _P = preload("res://commons/ui/ada_palette.gd")

# The four tables are PRELOADED from the artifact that owns them, never copied —
# harmonic_distance_table:50 set that rule for this family and it holds here. A third
# private copy of twelve floats is how one vocabulary becomes three.
const _CTS = preload("res://commons/artifacts/chord_tension_spring/chord_tension_spring.gd")

# ── The just interval each station is measured against ──
# NOT INVENTED HERE. These are the ratios chord_tension_spring writes in the comments
# beside CONSONANCE_RATIO (gd:98-109), read off in order: 1:1, 16:15, 9:8, 6:5, 5:4,
# 4:3, 45:32, 3:2, 8:5, 5:3, 16:9, 15:8. That file used them to RANK the intervals and
# then discarded them; this one keeps them as lengths.
#
# In cents (1200*log2), against the tempered 100*i:
#   0   1/1     0.000     0     +0.000
#   1   16/15   111.731   100   +11.731
#   2   9/8     203.910   200   +3.910
#   3   6/5     315.641   300   +15.641   <- worst, with 5/3
#   4   5/4     386.314   400   -13.686
#   5   4/3     498.045   500   -1.955
#   6   45/32   590.224   600   -9.776
#   7   3/2     701.955   700   +1.955    <- the fifth the audit names
#   8   8/5     813.686   800   +13.686
#   9   5/3     884.359   900   -15.641
#   10  16/9    996.090   1000  -3.910
#   11  15/8    1088.269  1100  -11.731
# The list is antisymmetric about the tritone because inversion is exact in both
# systems, which is why `comma` pinches the rail toward its middle rather than
# shearing it.
const JUST: Array = [
	[1, 1], [16, 15], [9, 8], [6, 5], [5, 4], [4, 3],
	[45, 32], [3, 2], [8, 5], [5, 3], [16, 9], [15, 8],
]

# ── Bench geometry ──
const RAIL := 0.60              # the octave, drawn: 1200 cents across 0.60 m
const STEP := 0.05              # RAIL / 12 — one tempered semitone, 100 cents
const CENT := 0.0005            # RAIL / 1200 — one cent, half a millimetre
const DECK := Vector3(0.68, 0.012, 0.18)
const TOOTH_X := 0.0025
const TOOTH_Z := 0.15
const TOOTH_H := 0.006
const TOOTH_H_ANCHOR := 0.012   # stations 0 and 12: the two the systems agree on
const CAP := Vector3(0.018, 0.005, 0.018)
const STRAND := 0.0025          # coil wire diameter
const SEG_PER_COIL := 8         # chord_tension_spring:635 — points_per_coil
const H_MIN := 0.035
const H_SPAN := 0.205           # so a weight of 1.0 stands 0.240 m
const LATTICE_X := 0.15         # 3-exponent step; the lattice spans -2..2 = the rail
const LATTICE_Z := 0.055        # 5-exponent step; -1..1 stays on the deck

# ═══════════════════════════════════════════
#  DNA (stage 2 — variation)
# ═══════════════════════════════════════════
# consonance_theory: THE FAMILY AXIS, the same four words and the same four tables as
#   chord_tension_spring and harmonic_distance_table, imported from the former. It
#   sets each spring's HEIGHT, its COIL COUNT and its COIL RADIUS through that
#   artifact's own two expressions (gd:633-634), so a fifth is a short fat four-turn
#   spring and a tritone is a tall thin eleven-turn one under `western`, and under
#   `blues` the tritone is fat too. `flat` rates every interval 0.5 and the twelve
#   springs become one spring twelve times — that theory's claim, drawn.
#   IT DOES NOT MOVE ANY SPRING SIDEWAYS. Judging an interval does not retune it,
#   which is the finding this bench is built to state.
# interval_space: THE READING AXIS — what a horizontal distance on the rail MEANS.
#   tempered — 12-TET. Station i at i * STEP. Every spring on its own tooth.
#   just     — 5-limit just intonation. Station i at its true cents. Eleven of the
#              twelve springs step off their teeth, by 1.955 to 15.641 cents, which
#              is 0.98 to 7.82 mm. Real, and nearly invisible: this is the picture
#              harmonic_distance_table's registry declined to build, and it was right
#              that the picture is weak. It is kept because the weakness is the fact.
#   comma    — the same displacement times comma_gain. At the shipped 5.0 the worst
#              error is 39 mm against a 50 mm tooth spacing, so the minor third and
#              the major sixth swap places with their neighbours and the rail pinches
#              toward its centre. The magnification is honest and labelled; without
#              it the axis is 8 mm and a still cannot hold it.
#   lattice  — off the rail entirely. Each interval's just ratio is 2^a 3^b 5^c;
#              plot b across and c into the deck and the row becomes the 5-limit
#              lattice, where nearness is factorisation rather than pitch. All twelve
#              cells are distinct (checked: 1/1 sits at the origin and 2/1, which
#              would share it, is not a station — the ruler ends at the octave and
#              the octave needs no entry, being 2:1 in every system on earth).
@export_enum("tempered", "just", "comma", "lattice") var interval_space: String = "tempered"
@export_enum("western", "blues", "ratio", "flat") var consonance_theory: String = "western"

const SPACES: Array[String] = ["tempered", "just", "comma", "lattice"]
const THEORIES: Array[String] = ["western", "blues", "ratio", "flat"]

## NOT AN AXIS — the magnification the `comma` reading applies to the tuning error,
## and read by that reading alone. 1.0 makes `comma` bit-equal to `just`, which is the
## bench's own control. The default 5.0 was chosen against a number rather than by
## eye: at 5.0 the closest pair of stations on the rail is 23.4 mm apart, and the
## widest spring is 41 mm across, so the crowd just touches; at 8.0 the gap falls to
## 19 mm and springs interpenetrate; at 20.0 the minor third and the major sixth land
## on top of each other at the rail's centre.
@export var comma_gain: float = 5.0

var _built: bool = false
var _deck: MeshInstance3D
var _comb: Node3D
var _stations: Node3D
var _coil_mm: MultiMesh
var _coil_mmi: MultiMeshInstance3D

func _ready() -> void:
	_build_deck()
	_build_comb()
	_build_stations()
	_built = true

# ═══════════════════════════════════════════
#  THE TWO AXES, AS ARITHMETIC
# ═══════════════════════════════════════════

## The theory's twelve weights. Imported, never re-typed.
func _weights() -> Array:
	match consonance_theory:
		"blues":
			return _CTS.CONSONANCE_BLUES
		"ratio":
			return _CTS.CONSONANCE_RATIO
		"flat":
			return _CTS.CONSONANCE_FLAT
		_:
			return _CTS.CONSONANCE

## Station i's just interval, in cents above the root.
func _cents(i: int) -> float:
	var pair: Array = JUST[i]
	return 1200.0 * (log(float(pair[0]) / float(pair[1])) / log(2.0))

## The 3-exponent and 5-exponent of station i's just ratio, octaves divided out.
## Derived by trial division rather than tabulated, so the lattice cannot disagree
## with the cents: both read the same twelve fractions.
func _exponents(i: int) -> Vector2i:
	var num: int = int(JUST[i][0])
	var den: int = int(JUST[i][1])
	var e3: int = 0
	var e5: int = 0
	while num % 3 == 0:
		num /= 3
		e3 += 1
	while den % 3 == 0:
		den /= 3
		e3 -= 1
	while num % 5 == 0:
		num /= 5
		e5 += 1
	while den % 5 == 0:
		den /= 5
		e5 -= 1
	return Vector2i(e3, e5)

## Where station i stands. The reading axis, and nothing else, decides this.
func _station_pos(i: int) -> Vector3:
	var tempered: float = -RAIL * 0.5 + float(i) * STEP
	match interval_space:
		"just":
			return Vector3(-RAIL * 0.5 + _cents(i) * CENT, 0.0, 0.0)
		"comma":
			var j: float = -RAIL * 0.5 + _cents(i) * CENT
			return Vector3(tempered + comma_gain * (j - tempered), 0.0, 0.0)
		"lattice":
			var e: Vector2i = _exponents(i)
			return Vector3(float(e.x) * LATTICE_X, 0.0, float(e.y) * LATTICE_Z)
		_:
			return Vector3(tempered, 0.0, 0.0)

## chord_tension_spring:639-645, character for character. Green when the theory calls
## the interval consonant, red when it does not.
func _spring_color(c: float) -> Color:
	if c > 0.6:
		return _P.ACCENT_GREEN.lerp(_P.ACCENT_CYAN, (c - 0.6) / 0.4)
	elif c > 0.3:
		return _P.ACCENT_YELLOW.lerp(_P.ACCENT_GREEN, (c - 0.3) / 0.3)
	return _P.ACCENT_RED.lerp(_P.ACCENT_YELLOW, c / 0.3)

# ═══════════════════════════════════════════
#  CONSTRUCTION
# ═══════════════════════════════════════════

func _build_deck() -> void:
	_deck = MeshInstance3D.new()
	_deck.name = "Deck"
	var box := BoxMesh.new()
	box.size = DECK
	_deck.mesh = box
	_deck.position = Vector3(0.0, -DECK.y * 0.5, 0.0)
	_deck.material_override = _P.make_material(_P.PANEL_DARK, 0.25, 0.65, 0.0)
	add_child(_deck)

## Thirteen teeth at exact hundred-cent marks. This is the object that does not move:
## whatever the reading and whatever the theory, equal temperament stays where it is
## and the springs are measured against it. The two end teeth are twice as tall,
## because 1:1 and 2:1 are the two intervals every temperament agrees about.
func _build_comb() -> void:
	_comb = Node3D.new()
	_comb.name = "Comb"
	add_child(_comb)
	var mat: StandardMaterial3D = _P.make_material(_P.METAL_CHROME, 0.5, 0.4, 0.15)
	for i in range(13):
		var anchor: bool = (i == 0 or i == 12)
		var h: float = TOOTH_H_ANCHOR if anchor else TOOTH_H
		var tooth := MeshInstance3D.new()
		tooth.name = "Tooth_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(TOOTH_X, h, TOOTH_Z)
		tooth.mesh = box
		tooth.position = Vector3(-RAIL * 0.5 + float(i) * STEP, h * 0.5, 0.0)
		tooth.material_override = mat
		_comb.add_child(tooth)

## Twelve springs and twelve caps. The coil geometry is chord_tension_spring's own —
## its coil count and coil radius expressions (gd:633-634) turned from a line between
## two nodes into a post standing on a ruler.
func _build_stations() -> void:
	_stations = Node3D.new()
	_stations.name = "Stations"
	add_child(_stations)

	var w: Array = _weights()

	# One pass to size the MultiMesh: the coil count depends on the theory, so the
	# instance count does too.
	var total_segments: int = 0
	for i in range(12):
		total_segments += _coils(float(w[i])) * SEG_PER_COIL

	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 0

	_coil_mm = MultiMesh.new()
	_coil_mm.transform_format = MultiMesh.TRANSFORM_3D
	_coil_mm.use_colors = true
	_coil_mm.mesh = cyl
	_coil_mm.instance_count = total_segments

	var coil_mat := StandardMaterial3D.new()
	coil_mat.vertex_color_use_as_albedo = true
	coil_mat.metallic = 0.35
	coil_mat.roughness = 0.4
	coil_mat.emission_enabled = true
	coil_mat.emission = Color.WHITE
	coil_mat.emission_energy_multiplier = 0.25

	_coil_mmi = MultiMeshInstance3D.new()
	_coil_mmi.name = "Coils"
	_coil_mmi.multimesh = _coil_mm
	_coil_mmi.material_override = coil_mat
	_stations.add_child(_coil_mmi)

	var slot: int = 0
	for i in range(12):
		var weight: float = float(w[i])
		var base: Vector3 = _station_pos(i)
		var h: float = H_MIN + weight * H_SPAN
		var coils: int = _coils(weight)
		var rad: float = lerpf(0.005, 0.02, weight)
		var col: Color = _spring_color(weight)
		var segments: int = coils * SEG_PER_COIL

		var prev: Vector3 = base + Vector3(rad, 0.0, 0.0)
		for p in range(1, segments + 1):
			var t: float = float(p) / float(segments)
			var ang: float = t * float(coils) * TAU
			var cur: Vector3 = base + Vector3(cos(ang) * rad, t * h, sin(ang) * rad)
			_coil_mm.set_instance_transform(slot, _segment_xform(prev, cur))
			_coil_mm.set_instance_color(slot, col)
			slot += 1
			prev = cur

		# The cap is a real MeshInstance3D on purpose: the capture AABB counts
		# MeshInstance3D only, and a bench whose whole payload is a MultiMesh
		# measures as a 1 m box. Deck plus caps give the frame an honest height.
		var cap := MeshInstance3D.new()
		cap.name = "Cap_%d" % i
		var cbox := BoxMesh.new()
		cbox.size = CAP
		cap.mesh = cbox
		cap.position = base + Vector3(0.0, h + CAP.y * 0.5, 0.0)
		cap.material_override = _P.make_material(col, 0.3, 0.35, 0.35)
		_stations.add_child(cap)

func _coils(weight: float) -> int:
	# chord_tension_spring:633 — tighter coils for more tension.
	return int(lerpf(4.0, 12.0, 1.0 - weight))

## harmonic_distance_table:512-521, the same unit-cylinder-along-a-segment transform
## its overtone web is built from.
func _segment_xform(a: Vector3, b: Vector3) -> Transform3D:
	var xf := Transform3D()
	var delta: Vector3 = b - a
	var length: float = delta.length()
	if length < 0.00001:
		xf.origin = a
		return xf
	var direction: Vector3 = delta / length
	if absf(direction.dot(Vector3.UP)) < 0.99:
		var look_basis: Basis = Basis.looking_at(direction, Vector3.UP)
		look_basis = look_basis * Basis(Vector3.RIGHT, PI / 2.0)
		xf.basis = look_basis
	xf.basis = xf.basis.scaled(Vector3(STRAND, length, STRAND))
	xf.origin = (a + b) * 0.5
	return xf

# ═══════════════════════════════════════════
#  REBUILD
# ═══════════════════════════════════════════

## Only the twelve stations are torn down. The deck and the comb are the frame of
## reference and must be bit-identical across every variant, or the bench is
## measuring against something that moved.
func _relay_stations() -> void:
	if is_instance_valid(_stations):
		_stations.queue_free()
	_coil_mm = null
	_coil_mmi = null
	_build_stations()

# ═══════════════════════════════════════════
#  GRID INTEGRATION
# ═══════════════════════════════════════════

## Guarded twice, the way both parents guard theirs: a word is taken only if this
## artifact actually builds it AND it differs from the word already held, and nothing
## is torn down before _ready has laid the stations out once.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("interval_space"):
		var s: String = str(config_data["interval_space"])
		if SPACES.has(s) and s != interval_space:
			interval_space = s
			changed = true
	if config_data.has("consonance_theory"):
		var t: String = str(config_data["consonance_theory"])
		if THEORIES.has(t) and t != consonance_theory:
			consonance_theory = t
			changed = true
	if config_data.has("comma_gain"):
		# ZERO IS ADMISSIBLE and is one of the bench's own controls: at gain 0.0 the
		# `comma` reading is bit-equal to `tempered`, at 1.0 it is bit-equal to `just`.
		# A `> 0.0` guard here would have silently refused the first of those and made
		# a registered null unreachable from a map token.
		var g: float = float(config_data["comma_gain"])
		if g >= 0.0 and not is_equal_approx(g, comma_gain):
			comma_gain = g
			changed = true
	if changed and _built:
		_relay_stations()

# ═══════════════════════════════════════════
#  PUBLIC API (readable without a headset)
# ═══════════════════════════════════════════

## The tuning error at station i, in cents. Positive = just is sharp of tempered.
func error_cents(i: int) -> float:
	return _cents(i) - 100.0 * float(i)

## The theory's weight for station i, 0..1.
func weight(i: int) -> float:
	return float(_weights()[i])
