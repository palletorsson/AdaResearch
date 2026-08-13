extends Node3D

# @identity
# essence: four bases evaluated at the SAME 2304 positions and stood in the SAME body, so
#   simplex, perlin, value and cellular differ by the basis and by nothing else
# desire: to stop being told that the four noises are different and to be able to point at
#   the place where they differ — and at the place where they stop differing
# critical_parameter: octaves — how many scales are summed, which is also how much of each
#   basis's own character survives the summing
# triggers: nothing. There is no interaction, no animation and no randomness in this file.
# emerges: three of the four are smooth fields and one is a partition; and past two octaves
#   the two gradient bases converge on each other while cellular does not
# needs: four benches on one apron [has]; a datum rule the four can be read against [has];
#   a counted census of each bench [has]; a fourth octave rung [declined — Nyquist, see dna]
# relationships: the TRANSPOSE of noise_quarry, which holds one field and cuts it three ways;
#   this holds one cut and fills it four ways. Reads the `generator` vocabulary out of
#   shader_noise_space's own const and the `evidence` ladder out of noise_quarry's own const
# truth: the four bases are not four flavours of the same thing — one of them is not an
#   interpolation at all — and the summing that makes noise look like landscape is also the
#   operation that makes the four hardest to tell apart

# ─────────────────────────────────────────────────────────────────────────────
# THE FAMILY WORD IS EXHIBITED, NOT SWEPT — and the reason is in the members' CODE.
#
# `generator` is declared by six registry names over five scenes: perlin_noise,
# noise_terrain, noise_space, shader_noise_space, and voxel_noise_demo /
# marchingcubes_voxel_noise_demo, which are one scene under two names. All six
# carry simplex | perlin | value | cellular, in that order, with no reordering.
#
# The four values sit SIDE BY SIDE, not nested. In five of the six the word is
# spent by a flat four-branch dispatch returning four mutually exclusive
# FastNoiseLite enum constants — _noise_type_for() in noiseterrain.gd:128,
# VoxelNoiseMarchingCubes.gd:147 and NoiseVisualizer.gd:119, and the same four
# branches written inline in NoiseSpace._build_noise. In the sixth the word is an
# INDEX written into one shader uniform which noise2d() dispatches on
# (QueerNoiseShader.gdshader). No branch contains another; no value is another
# value plus a term. Parallel values are exactly the case where holding them all
# at once is NOT merely the top value — it is the object. So the four stand
# together in every frame, lettered on the apron, and the axes vary something
# else.
#
# THE WORD IS READ OUT OF THE FAMILY'S OWN CONST, NOT RETYPED. Four members carry
# four byte-identical copies of the array (noiseterrain.gd:109, NoiseSpace.gd:65,
# VoxelNoiseMarchingCubes.gd:85, noiseroom.gd:33) and there is no owner and no
# alias table. noiseroom.gd is preloaded because it is the only one of the four
# whose script parses with NO external dependency at all — no class_name, no
# preload, no reference to a global class. The other three are class_name'd, and
# NoiseSpace extends TopologySpace besides, so preloading any of them would put
# another script between this artifact and its own vocabulary. _check_family_list()
# then push_errors in BOTH directions at _ready.
#
# WHY THE BASES ARE PORTED AND NOT FastNoiseLite'd, on the record.
# Five of the six members reach the four bases through FastNoiseLite; the sixth
# implements them itself, in GLSL, and amplitude-matches them so its axis is about
# structure rather than about exposure. This bench takes the sixth route and ports
# noiseroom's four functions — perlin2d, value2d, simplex2d, cellular2d — construction
# for construction, including its three matching constants (0.770, 38.0, 0.827).
# Two reasons, both about being able to check the thing before shipping it:
#   1. A ported basis is exactly replicable in Python, so dna.predicted_degeneracy
#      is arithmetic done on this geometry rather than an estimate, and the GAIN
#      below is a measured no-clip figure rather than a hope. FastNoiseLite's
#      fractal normalisation cannot be reproduced offline, and the bench is
#      forbidden to run Godot.
#   2. Four bases on ONE fixed gauge only works if their amplitudes are already
#      matched. FastNoiseLite's four are not: cellular at RETURN_DISTANCE is
#      one-sided, which is why voxel_noise_demo had to override it. The shader's
#      constants are the family's own answer to that problem.
# WHAT IT COSTS, said plainly: this bench's picture of `perlin` is not byte-identical
# to what perlin_noise or noise_terrain photograph. The CONSTRUCTIONS are shared and
# the structural claims transfer; the particular draw does not. And GLSL runs float32
# while GDScript runs float64, so this file's field is not the shader's field either —
# sin() hashes are precision-sensitive by design.
#
# WHERE THIS DISAGREES WITH noise_quarry, AND WHO IS RIGHT.
# noise_quarry declined `generator` and gave as its decisive reason that "in all four
# members that declare it the word names a FastNoiseLite noise type". That was already
# untrue when it was written: shader_noise_space declares the same four values against
# a hand-written GLSL dispatch. The quarry's decline is still CORRECT — a single
# hand-written gradient basis calling itself `perlin` would be taking a word without
# its answers — but its stated reason is wrong, and the word does not mean "a
# FastNoiseLite enum". It means "which basis fills the field", and the family already
# contains one member that answers it without FastNoiseLite.
# ─────────────────────────────────────────────────────────────────────────────

## The `generator` vocabulary, live. Not a copy: the benches, their order, their count
## and their lettering all come out of this array at build time.
const GENERATOR_SRC := preload("res://algorithms/randomness/shadernoisespace/noiseroom.gd")

## The `evidence` ladder, live. noise_quarry is this artifact's explicit companion and
## carries the three-rung sub-list six siblings share; preloading it rather than
## retyping means the transpose pair cannot drift apart.
const EVIDENCE_SRC := preload("res://commons/artifacts/noise_quarry/noise_quarry.gd")

## DNA axis — what the bench puts in the frame as proof that the four benches were
## asked the same question. The family word (46 declarations before this one) with the
## three-rung sub-list seven siblings carry, character for character and in their order.
##   result   — the four crusts on one apron, and nothing else.
##   trace    — + the datum rule: one blade across all four, its top edge exactly at
##              the field's zero, so the four fields are read against one line
##              instead of against each other.
##   longhand — + a counted census of each bench on the board behind it: the same
##              2304 numbers the crust in front is standing on, binned by height on
##              the crust's OWN gauge translated up by exactly its own height, with
##              one count ceiling shared by all four benches and all three rungs.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

## DNA axis — how many scales are summed into each bench's field. The family word,
## declared seven times before this one in three different value lists. The ladder stops
## at THREE and not at noise_space's four; the Nyquist arithmetic for this grid is in
## dna.kin and the refusal is on the record.
@export_range(1, 3, 1) var octaves: int = 1

## Retyped ONCE, because @export_enum needs a literal. _check_evidence_list() holds it
## against EVIDENCE_SRC.EVIDENCES in both directions at _ready, so the two cannot drift.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand"]
const OCTAVE_MIN := 1
const OCTAVE_MAX := 3

## The four bases this file can evaluate. NOT the canon — the canon is
## GENERATOR_SRC.GENERATORS — but the list _check_family_list holds the canon against.
const BASES: PackedStringArray = ["simplex", "perlin", "value", "cellular"]

# ── the sampling: identical for all four benches (law 3) ─────────────────────
const GRID := 48
const BENCH_E := 1.20
const CELL := BENCH_E / GRID            # 0.025 m
## Lattice cells across a bench at octave 1. FOUR, not the quarry's one, because this
## bench's whole subject is the STRUCTURE of the four lattices and a single cell has no
## structure to show. It is also what caps the octave ladder at three: see dna.kin.
const SPAN := 4.0
const ORIGIN_U := 3.37                  # where on the lattice the bench is cut —
const ORIGIN_V := 7.91                  # noise_quarry's own cut, taken not invented
const PERSISTENCE := 0.5                # the family's gain (NoiseSpace.persistence)
## ONE gain, applied identically to all four bases at all three rungs. Read off the
## widest excursion measured over the whole 12-frame sheet in a Python replica of these
## exact functions: the widest raw sample is 0.4338 (perlin, K=1), so 1/0.4338 = 2.3053
## is the no-clip ceiling and 2.20 is that rounded down for 4.6% of headroom. Nothing
## clips anywhere: the widest realised |h| over all twelve fields is 0.95431. The
## residual narrowing with K (std 0.361 at K=1, 0.246 at K=3) is a true property of fBm
## and is left visible rather than normalised away, which would be a per-rung ceiling.
const GAIN := 2.20

# ── layout ───────────────────────────────────────────────────────────────────
const AMP := 0.24                       # the field's half-range in metres
const BENCH_GAP := 0.18
const Y_FLOOR := 0.10                   # apron top
const DATUM := Y_FLOOR + AMP            # 0.34 m; the field's zero
const APRON_MARGIN := 0.12
const APRON_Z0 := -1.27
const APRON_Z1 := 0.90
const LIP := 0.035                      # the crust's edge: a skin, not a solid
const BLADE_H := 0.070                  # 7.8 px at the sweep's 115.42 px/m
const BLADE_T := 0.022
## The datum rule stands at the apron's front lip, NOT tucked against the benches, and
## the reason is occlusion arithmetic. At the sweep's standpoint a sight line descends
## 0.3269 m per metre of -Z travel, so a blade whose top edge is at DATUM hides, at the
## benches' front row, everything below DATUM - 0.3269 * (BLADE_Z - 0.60). At 0.86 that
## is 0.2650 m, i.e. h < -0.31 in the front row of 48; moving the blade nearer the
## benches would hide MORE, not less.
const BLADE_Z := 0.86
# ── the board: the chart ground, and the crust's gauge stacked on top of itself ──
## The board's lower edge sits at the crust's h = +1 line, so the crust can never
## occlude it: the tallest sample this artifact can draw is DATUM + AMP * 0.95431 =
## 0.5690 m and the board starts at 0.58. Its 0.48 m of height is exactly 2 * AMP, the
## crust's own full range, so the bench reads as one continuous 0.96 m ruler from the
## apron to the board's top, the bottom half being where the field STANDS and the top
## half being where it is COUNTED.
const WALL_Z := -1.15
const WALL_T := 0.030
const BAND_Y0 := DATUM + AMP            # 0.58
const WALL_TOP := BAND_Y0 + 2.0 * AMP   # 1.06
const POST_E := 0.09
## The board is two-toned and the step is at the census's h = 0. A rule drawn ACROSS the
## bars would have been furniture in front of the marks (law 7) and at a legible 0.036 m
## it would have covered 30% of each of the two longest bars; a tonal boundary is the
## same information with nothing in front of anything. It also puts every cold bar on
## the dark half and every warm bar on the light half, which is where the greyscale
## contrast is: COLD's luminance is 0.386 against STONE's 0.340, near-invisible to the
## critic, and against BOARD_LO's 0.171 it is not.
const BINS := 8
## FIXED across every bench and every rung. The largest bin count anywhere in the sheet
## is 1006 of 2304 (cellular at K=3), so 1050 is that plus 4.4% and nothing is ever
## clipped or rescaled. A bar is (count / 1050) * BENCH_E metres long, so its longest
## reach is 1.15 m into a 1.20 m section and it stops 0.23 m short of the next bench.
const COUNT_CEIL := 1050.0
const BAR_T := 0.020

## The ramp is the family's, character for character: NoiseVisualizer.gd:56 writes
## lerp(Color(0.2, 0.4, 0.8), Color(0.8, 0.6, 0.2), height_ratio). Its ceiling is FIXED
## at h = -1 .. +1 on all four benches, in both the crust and the census, at every rung.
const COLD := Color(0.20, 0.40, 0.80)
const WARM := Color(0.80, 0.60, 0.20)
const STONE := Color(0.34, 0.345, 0.36)
const BOARD_LO := Color(0.165, 0.17, 0.185)
const BOARD_HI := Color(0.275, 0.28, 0.295)
const DATUM_COLOR := Color(0.36, 0.72, 0.85)

const F2 := 0.366025403784439
const G2 := 0.211324865405187

## True once _ready has built the bench. apply_grid_config before that is a value change
## with no geometry to answer it (the force_pad fault).
var _built: bool = false


func _ready() -> void:
	# The grid stamps config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred, i.e. after this, so the meta read happens here.
	_read_grid_config_meta()
	_check_family_list()
	_check_evidence_list()
	_build()
	_built = true


# ── the vocabulary ───────────────────────────────────────────────────────────
func _generators() -> PackedStringArray:
	return GENERATOR_SRC.GENERATORS


## Both directions. A family value this bench cannot evaluate would be a lane silently
## dropped; a basis this bench evaluates that the family no longer declares would be a
## fifth noise this bench invented. Neither may pass quietly.
func _check_family_list() -> void:
	var family: PackedStringArray = _generators()
	for i in range(family.size()):
		var value: String = family[i]
		if not BASES.has(value):
			push_error("generator_bench: the generator family declares '%s' and this bench has no basis for it. Add one or refuse the value on the record." % value)
	for i in range(BASES.size()):
		var mine: String = BASES[i]
		if not family.has(mine):
			push_error("generator_bench: this bench evaluates '%s' and the generator family no longer declares it. The vocabulary has moved." % mine)


## The @export_enum hint above is a literal GDScript will not let me compute, so the
## literal is checked against the family's own const instead of trusted.
func _check_evidence_list() -> void:
	var family: PackedStringArray = EVIDENCE_SRC.EVIDENCES
	for i in range(family.size()):
		if not EVIDENCES.has(family[i]):
			push_error("generator_bench: the evidence family declares '%s' and this bench's export hint does not offer it." % family[i])
	for i in range(EVIDENCES.size()):
		if not family.has(EVIDENCES[i]):
			push_error("generator_bench: this bench offers evidence '%s' and the evidence family no longer declares it." % EVIDENCES[i])


# ── the four bases, ported from QueerNoiseShader.gdshader ────────────────────
func _fract(x: float) -> float:
	return x - floor(x)


func _hash2(px: float, py: float) -> Vector2:
	var ax: float = px * 127.1 + py * 311.7
	var ay: float = px * 269.5 + py * 183.3
	return Vector2(-1.0 + 2.0 * _fract(sin(ax) * 43758.5453123),
		-1.0 + 2.0 * _fract(sin(ay) * 43758.5453123))


func _hash1(px: float, py: float) -> float:
	return _fract(sin(px * 127.1 + py * 311.7) * 43758.5453123)


## PERLIN — a random GRADIENT at each lattice corner, dotted with the offset to it and
## smoothed between. The value is zero at every corner, so the square lattice stays
## faintly latent in the result: smooth swells on a grid.
func _perlin2d(px: float, py: float) -> float:
	var ix: float = floor(px)
	var iy: float = floor(py)
	var fx: float = px - ix
	var fy: float = py - iy
	var ux: float = fx * fx * (3.0 - 2.0 * fx)
	var uy: float = fy * fy * (3.0 - 2.0 * fy)
	var g00: float = _hash2(ix, iy).dot(Vector2(fx, fy))
	var g10: float = _hash2(ix + 1.0, iy).dot(Vector2(fx - 1.0, fy))
	var g01: float = _hash2(ix, iy + 1.0).dot(Vector2(fx, fy - 1.0))
	var g11: float = _hash2(ix + 1.0, iy + 1.0).dot(Vector2(fx - 1.0, fy - 1.0))
	var a: float = g00 + ux * (g10 - g00)
	var b: float = g01 + ux * (g11 - g01)
	return a + uy * (b - a)


## VALUE — a random HEIGHT at each corner instead of a gradient, interpolated
## identically. The field no longer passes through zero on the lattice, so cells become
## plateaus and the grid stops being latent and becomes the picture.
func _value2d(px: float, py: float) -> float:
	var ix: float = floor(px)
	var iy: float = floor(py)
	var fx: float = px - ix
	var fy: float = py - iy
	var ux: float = fx * fx * (3.0 - 2.0 * fx)
	var uy: float = fy * fy * (3.0 - 2.0 * fy)
	var h00: float = _hash1(ix, iy)
	var h10: float = _hash1(ix + 1.0, iy)
	var h01: float = _hash1(ix, iy + 1.0)
	var h11: float = _hash1(ix + 1.0, iy + 1.0)
	var a: float = h00 + ux * (h10 - h00)
	var b: float = h01 + ux * (h11 - h01)
	return ((a + uy * (b - a)) - 0.5) * 0.770


## SIMPLEX — the same gradient idea on a TRIANGULAR lattice, summed from three corners
## with a radial falloff instead of interpolated from four. Perlin's square grid
## disappears and what is left has no preferred direction.
func _simplex2d(px: float, py: float) -> float:
	var sk: float = (px + py) * F2
	var ix: float = floor(px + sk)
	var iy: float = floor(py + sk)
	var un: float = (ix + iy) * G2
	var x0: float = px - ix + un
	var y0: float = py - iy + un
	var i1x: float = 1.0 if x0 > y0 else 0.0
	var i1y: float = 0.0 if x0 > y0 else 1.0
	var x1: float = x0 - i1x + G2
	var y1: float = y0 - i1y + G2
	var x2: float = x0 - 1.0 + 2.0 * G2
	var y2: float = y0 - 1.0 + 2.0 * G2
	var t0: float = maxf(0.5 - (x0 * x0 + y0 * y0), 0.0)
	var t1: float = maxf(0.5 - (x1 * x1 + y1 * y1), 0.0)
	var t2: float = maxf(0.5 - (x2 * x2 + y2 * y2), 0.0)
	t0 = t0 * t0
	t0 = t0 * t0
	t1 = t1 * t1
	t1 = t1 * t1
	t2 = t2 * t2
	t2 = t2 * t2
	var g0: float = _hash2(ix, iy).dot(Vector2(x0, y0))
	var g1: float = _hash2(ix + i1x, iy + i1y).dot(Vector2(x1, y1))
	var g2: float = _hash2(ix + 1.0, iy + 1.0).dot(Vector2(x2, y2))
	return (t0 * g0 + t1 * g1 + t2 * g2) * 38.0


## CELLULAR — Worley, and not a smooth field at all. Space is partitioned by scattered
## feature points and every sample reports the distance to its nearest one, so the
## result has EDGES: the only one of the four that admits it is made of cells. It is
## also the only one that is not an interpolation, which is this bench's whole argument.
func _cellular2d(px: float, py: float) -> float:
	var ix: float = floor(px)
	var iy: float = floor(py)
	var fx: float = px - ix
	var fy: float = py - iy
	var best: float = 8.0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var fox: float = float(ox)
			var foy: float = float(oy)
			var h: Vector2 = _hash2(ix + fox, iy + foy)
			var featx: float = fox + (h.x * 0.5 + 0.5)
			var featy: float = foy + (h.y * 0.5 + 0.5)
			var d: float = Vector2(featx - fx, featy - fy).length()
			best = minf(best, d)
	return (0.5 - best) * 0.827


func _basis(name_in: String, px: float, py: float) -> float:
	if name_in == "perlin":
		return _perlin2d(px, py)
	if name_in == "value":
		return _value2d(px, py)
	if name_in == "cellular":
		return _cellular2d(px, py)
	return _simplex2d(px, py)


## ONE COPY OF THE ARITHMETIC, evaluated once per bench and read TWICE: the crust stands
## on this array and the census counts THIS array, not a second evaluation of the same
## function. If the two ever disagreed, the artifact would be a picture of one field with
## a histogram of another.
func _compute_field(basis_name: String) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(GRID * GRID)
	var k: int = clampi(octaves, OCTAVE_MIN, OCTAVE_MAX)
	for i in range(GRID):
		for j in range(GRID):
			var u: float = (float(i) + 0.5) / float(GRID)
			var v: float = (float(j) + 0.5) / float(GRID)
			var amp: float = 1.0
			var freq: float = SPAN
			var s: float = 0.0
			var norm: float = 0.0
			for _o in range(k):
				s += amp * _basis(basis_name, ORIGIN_U + u * freq, ORIGIN_V + v * freq)
				norm += amp
				amp *= PERSISTENCE
				freq *= 2.0
			out[i * GRID + j] = clampf(GAIN * s / norm, -1.0, 1.0)
	return out


func _ramp(h: float) -> Color:
	return COLD.lerp(WARM, (h + 1.0) * 0.5)


# ── construction ─────────────────────────────────────────────────────────────
func _build() -> void:
	# remove_child first: queue_free is deferred, so a rebuild would otherwise stand the
	# new bench inside the old one for a frame — and a capture taken in that frame is a
	# photograph of two variants at once.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var names: PackedStringArray = _generators()
	var n: int = names.size()
	var run: float = float(n) * BENCH_E + float(maxi(n - 1, 0)) * BENCH_GAP
	var apron_w: float = run + 2.0 * APRON_MARGIN

	_slab("Apron", Vector3(0.0, Y_FLOOR * 0.5, (APRON_Z0 + APRON_Z1) * 0.5),
		Vector3(apron_w, Y_FLOOR, APRON_Z1 - APRON_Z0), STONE)
	var mid: float = BAND_Y0 + AMP
	_slab("BoardBelowZero", Vector3(0.0, (BAND_Y0 + mid) * 0.5, WALL_Z),
		Vector3(run, mid - BAND_Y0, WALL_T), BOARD_LO)
	_slab("BoardAboveZero", Vector3(0.0, (mid + WALL_TOP) * 0.5, WALL_Z),
		Vector3(run, WALL_TOP - mid, WALL_T), BOARD_HI)
	for si in range(2):
		var side: float = -1.0 if si == 0 else 1.0
		_slab("BoardPost", Vector3(side * (run - POST_E) * 0.5, (Y_FLOOR + BAND_Y0) * 0.5, WALL_Z),
			Vector3(POST_E, BAND_Y0 - Y_FLOOR, POST_E), STONE)

	var fields: Array = []
	for k in range(n):
		var value: String = names[k]
		var bx: float = -run * 0.5 + BENCH_E * 0.5 + float(k) * (BENCH_E + BENCH_GAP)
		var f: PackedFloat32Array = PackedFloat32Array()
		if BASES.has(value):
			f = _compute_field(value)
			_build_bench(value, bx, f)
		fields.append(f)
		_letter(value, bx)

	if evidence == "trace" or evidence == "longhand":
		_slab("DatumRule", Vector3(0.0, DATUM - BLADE_H * 0.5, BLADE_Z),
			Vector3(run, BLADE_H, BLADE_T), DATUM_COLOR)

	if evidence == "longhand":
		var zf: float = WALL_Z + WALL_T * 0.5 + BAR_T * 0.5
		for k in range(n):
			var bx2: float = -run * 0.5 + BENCH_E * 0.5 + float(k) * (BENCH_E + BENCH_GAP)
			var fk: PackedFloat32Array = fields[k]
			_census(fk, bx2, zf)


## THE CENSUS. It counts the thing it claims to count: how many of the SAME 2304 samples
## the crust in front is standing on fall in each of eight equal bands of h, against a
## ceiling fixed across all four benches and all three rungs. It is a census of the
## bench, NOT an estimate of the basis — at SPAN = 4 a bench cuts 16 lattice cells at
## octave 1, so the shape of the first rung is as much about which 16 cells were cut as
## about the basis, and it settles as octaves are added. Said here rather than implied.
func _census(f: PackedFloat32Array, bx: float, zf: float) -> void:
	if f.is_empty():
		return
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(BINS)
	for i in range(f.size()):
		var b: int = clampi(int(floor((f[i] + 1.0) * 0.5 * float(BINS))), 0, BINS - 1)
		counts[b] += 1
	var binh: float = 2.0 * AMP / float(BINS)
	for j in range(BINS):
		if counts[j] <= 0:
			continue
		var bar_len: float = (float(counts[j]) / COUNT_CEIL) * BENCH_E
		var hc: float = -1.0 + 2.0 * (float(j) + 0.5) / float(BINS)
		var y: float = BAND_Y0 + AMP * (hc + 1.0)
		_slab("Count", Vector3(bx - BENCH_E * 0.5 + bar_len * 0.5, y, zf),
			Vector3(bar_len, binh, BAR_T), _ramp(hc))


func _build_bench(value: String, bx: float, f: PackedFloat32Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = bx - BENCH_E * 0.5
	var z0: float = -BENCH_E * 0.5
	for i in range(GRID):
		for j in range(GRID):
			var h: float = f[i * GRID + j]
			var c: Color = _ramp(h)
			var cx: float = x0 + (float(i) + 0.5) * CELL
			var cz: float = z0 + (float(j) + 0.5) * CELL
			# The field as TERRAIN — the family's own default readout, held fixed on all
			# four benches so the basis is the only variable. The tile stands at its
			# sample and skirts run to the neighbours', so the surface is continuous and
			# the edge is a 0.035 m lip: a skin over the apron, not a solid.
			var y: float = DATUM + AMP * h
			_tile(st, cx, y, cz, c)
			if i + 1 < GRID:
				var y2: float = DATUM + AMP * f[(i + 1) * GRID + j]
				_skirt_x(st, cx + CELL * 0.5, cz, minf(y, y2), maxf(y, y2), c * 0.85, y > y2)
			if j + 1 < GRID:
				var y3: float = DATUM + AMP * f[i * GRID + j + 1]
				_skirt_z(st, cx, cz + CELL * 0.5, minf(y, y3), maxf(y, y3), c * 0.85, y > y3)
			if i == 0 or i == GRID - 1 or j == 0 or j == GRID - 1:
				_box(st, Vector3(cx, y - LIP * 0.5, cz), Vector3(CELL, LIP, CELL), c * 0.8)
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Bench_" + value
	mi.mesh = mesh
	mi.material_override = _vertex_material()
	add_child(mi)


func _letter(value: String, bx: float) -> void:
	# The exhibited word, present at EVERY value of both axes, so no tile contains a
	# rendered word naming its own variant. Billboard is off, which also keeps LabelFramer
	# out — it treats billboard-enabled as the hanging signal and would bolt a panel and a
	# bezel behind each one. Label3D defaults to HORIZONTAL_ALIGNMENT_CENTER, so the tab is
	# centred on its origin and hanging it at the bench's centre x is correct; a LEFT-aligned
	# block would have hung from this point and run right.
	var label := Label3D.new()
	label.name = "Tab_" + value
	label.text = value
	label.font_size = 64
	label.pixel_size = 0.0012
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color(0.88, 0.90, 0.94)
	label.position = Vector3(bx, Y_FLOOR + 0.045, APRON_Z1 - 0.015)
	add_child(label)


# ── mesh helpers ─────────────────────────────────────────────────────────────
func _vertex_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.85
	m.metallic = 0.0
	# Cull-disabled on purpose: the crust is a skin with a 0.035 m lip and its underside is
	# part of the reading. It also means a mistaken winding cannot silently delete a face.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _slab(node_name: String, centre: Vector3, size: Vector3, c: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	m.metallic = 0.0
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = box
	mi.material_override = m
	mi.position = centre
	add_child(mi)


## THE NORMAL IS PASSED IN, NOT DERIVED FROM THE WINDING. A cross product of the first
## three vertices would have lit every top face from underneath — the tile quads are
## emitted (-x,-z) (+x,-z) (+x,+z) (-x,+z), whose cross product points at -Y — and the
## bench material is cull-disabled, so a wrong winding would not even show as a missing
## face. Every quad here is axis-aligned and its outward direction is known at the call
## site, so it is stated there.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c: Color, nrm: Vector3) -> void:
	var pts: Array[Vector3] = [p0, p1, p2, p0, p2, p3]
	for i in range(6):
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(pts[i])


func _tile(st: SurfaceTool, cx: float, y: float, cz: float, c: Color) -> void:
	var r: float = CELL * 0.5
	_quad(st, Vector3(cx - r, y, cz - r), Vector3(cx + r, y, cz - r),
		Vector3(cx + r, y, cz + r), Vector3(cx - r, y, cz + r), c, Vector3.UP)


## A riser between two cells. `face_positive` is which way the drop is: the wall belongs to
## whichever neighbour is higher, so the normal is not a property of the quad, it is a
## property of the field.
func _skirt_x(st: SurfaceTool, xe: float, cz: float, ylo: float, yhi: float, c: Color, face_positive: bool) -> void:
	var r: float = CELL * 0.5
	var nrm: Vector3 = Vector3.RIGHT if face_positive else Vector3.LEFT
	_quad(st, Vector3(xe, ylo, cz - r), Vector3(xe, ylo, cz + r),
		Vector3(xe, yhi, cz + r), Vector3(xe, yhi, cz - r), c, nrm)


func _skirt_z(st: SurfaceTool, cx: float, ze: float, ylo: float, yhi: float, c: Color, face_positive: bool) -> void:
	var r: float = CELL * 0.5
	var nrm: Vector3 = Vector3.BACK if face_positive else Vector3.FORWARD
	_quad(st, Vector3(cx - r, ylo, ze), Vector3(cx + r, ylo, ze),
		Vector3(cx + r, yhi, ze), Vector3(cx - r, yhi, ze), c, nrm)


## Four sides, no top and no bottom: this is the crust's edge lip, and its top is the tile
## that is already there.
func _box(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color) -> void:
	var x0: float = centre.x - size.x * 0.5
	var x1: float = centre.x + size.x * 0.5
	var y0: float = centre.y - size.y * 0.5
	var y1: float = centre.y + size.y * 0.5
	var z0: float = centre.z - size.z * 0.5
	var z1: float = centre.z + size.z * 0.5
	_quad(st, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), c, Vector3.FORWARD)
	_quad(st, Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x1, y1, z1), c, Vector3.BACK)
	_quad(st, Vector3(x0, y0, z1), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1), c, Vector3.LEFT)
	_quad(st, Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), c, Vector3.RIGHT)


# ── the three doors, one validator each ──────────────────────────────────────
func _is_evidence(v: String) -> bool:
	return EVIDENCES.has(v)


func _valid_octaves(v: int) -> bool:
	return v >= OCTAVE_MIN and v <= OCTAVE_MAX


## Walk the ancestor chain for config_* metadata the grid stamps before _ready.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			var e: String = str(node.get_meta("config_evidence")).strip_edges().to_lower()
			if _is_evidence(e):
				evidence = e
		if node.has_meta("config_octaves"):
			var o: int = int(node.get_meta("config_octaves"))
			if _valid_octaves(o):
				octaves = o
		node = node.get_parent()


## Guarded: rebuild only when a declared axis actually CHANGED, and only after _ready has
## built once. An unrecognised word or an out-of-range integer keeps the standing value.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("evidence"):
		var e: String = str(config_data["evidence"]).strip_edges().to_lower()
		if _is_evidence(e) and e != evidence:
			evidence = e
			changed = true
	if config_data.has("octaves"):
		var o: int = int(config_data["octaves"])
		if _valid_octaves(o) and o != octaves:
			octaves = o
			changed = true
	if changed and _built:
		_build()
