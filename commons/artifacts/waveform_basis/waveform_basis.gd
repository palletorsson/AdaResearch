extends Node3D
class_name WaveformBasis

## waveform_basis — a two-member family that lists a basis vector alongside three
## things built out of it, as though the four were peers.
##
## THE FAMILY, and it is the smallest this programme has built on. Two artifacts
## declare an axis called `waveform`:
##
##   additive_wave_demo   sine · square · sawtooth · triangle · clear      default sine
##   fourier_transform    sine · square · impulse · triangle · sawtooth · noise
##                                                                        default sine
##
## Two scenes, two scripts, no shared scene — commons/artifacts/additive_wave_demo/
## additive_wave_demo.tscn on AdditiveWaveDemo, and algorithms/wavefunctions/
## fouriertransform/fouriertransform.tscn on FourierTransform plus SignalGenerator.
## Both ship `sine`: 2 of 2, counted.
##
## AND THE BRIEF WAS WRONG ABOUT THE FIRST THING IT ASKED ME TO CHECK. It said the
## two members "declare the same flat list". THEY DO NOT. Only FOUR words are
## common — sine, square, sawtooth, triangle. `clear` is additive_wave_demo's alone
## and `impulse`/`noise` are fourier_transform's alone. The axis built here is the
## INTERSECTION, and the three declined words are in `declines` with reasons.
##
## THE ARGUMENT. `sine` is not one option among four. It is the BASIS the other
## three are made of, and each of the other three is an infinite sum of sines:
##
##   square    (4/pi)   * [ sin t + sin3t/3 + sin5t/5 + ... ]     odd n, 1/n
##   sawtooth  (2/pi)   * [ sin t - sin2t/2 + sin3t/3 - ... ]     all n, 1/n, alternating
##   triangle  (8/pi^2) * [ sin t - sin3t/9 + sin5t/25 - ... ]    odd n, 1/n^2, alternating
##
## So a flat four-value list puts a basis vector beside three of its own sums. And
## the artifact whose ENTIRE SUBJECT is that decomposition — fourier_transform — is
## the second member and declares the flat list too. The family contains its own
## refutation.
##
## WHAT THE CODE SAID THAT THE BRIEF DID NOT, and it is the finding of this pass.
## The brief asked whether additive_wave_demo actually sums harmonics or reaches for
## a closed form, and warned that a closed form would mean the artifact named
## "additive" is not additive. IT IS ADDITIVE. _calculate_wave_value() is
##
##   for h in range(harmonic_amplitudes.size()): value += a[h] * sin(phase * (h + 1))
##
## a genuine five-term sum of sines and nothing else. THE CLOSED FORMS ARE IN THE
## OTHER MEMBER. SignalGenerator.generate_signal_at_time() is a match on an int:
##
##   1 square    sign(sin(omega * t))
##   2 triangle  2.0 * abs(2.0 * (u - floor(u + 0.5))) - 1.0
##   3 sawtooth  2.0 * (u - floor(u + 0.5))
##
## Not one sine is summed for any of them. The artifact named after the theorem that
## these three ARE sums of sines synthesises all three by sign() and floor(). It does
## own an additive branch — `if harmonics > 1` adds 1/h partials — but `harmonics`
## ships at 1 (HarmonicsSlider value = 1.0, and the slider is a Control node map
## placements suppress as demo chrome), so that branch has never run at a placement;
## and when it does run it adds partials ON TOP of an already-complete closed form,
## which is not a better square wave, it is a square wave plus a ripple.
##
## SO THE TWO MEMBERS SYNTHESISE THE SAME FOUR WORDS BY OPPOSITE METHODS, and the
## names are the wrong way round.
##
## AND A SECOND, SHARPER ONE. additive_wave_demo's triangle preset is
## _set_amplitudes([1.0, 0.0, 0.111, 0.0, 0.04]) — odd harmonics at 1/n^2, which is
## the right MAGNITUDE and THE WRONG SIGN. A triangle needs (-1)^((n-1)/2), so n = 3
## must be MINUS 1/9. Sum_{n odd} sin(nt)/n^2 is not a triangle wave in any phase:
## differentiate it and you get Sum_{n odd} cos(nt)/n = 0.5*ln|cot(t/2)|, a
## logarithmic singularity, not the square wave a triangle's slope has to be. And the
## correct value is UNREACHABLE by construction — _setup_sliders() calls
## set_range(0.0, 1.0) on all five, so a negative amplitude cannot be entered. The
## artifact cannot represent a triangle wave, and its own _detect_preset() reports
## the shape as "~ Triangle Wave" because it tests abs(a[2] - a[0]/9.0) < 0.1 and
## never looks at a sign. THIS BENCH DRAWS THE CORRECT ALTERNATING SERIES and puts
## rung 3 BELOW the axis, so the sign is a body rather than a claim.
##
## WHAT THIS BENCH DOES. One period of one waveform across a 0.84 m field, as real
## geometry — a solid ribbon 0.150 m wide and 0.006 m thick following the curve — and
## `reading` decides which of the family's three ways of holding it is standing in
## the room:
##
##   wave      the ideal closed form. fourier_transform's method, drawn.
##   partials  the sine components, each a ribbon of its own at TRUE amplitude, on
##             five fixed rungs indexed by harmonic number. additive_wave_demo's
##             `components=ladder` with the amplitudes made honest.
##   sum       the five-term partial sum — additive_wave_demo's NUM_HARMONICS = 5 and
##             its five sliders — drawn against the ideal, which stands as a slab
##             from the axis plane up to the closed form. Where the sum agrees, the
##             ribbon covers the slab's top edge. Where it disagrees, daylight opens
##             between them: that is Gibbs, as a gap you can measure.
##
## RUNG 1 IS AT THE AXIS, WHICH IS THE WHOLE POINT. `partials` puts the fundamental
## on exactly the line `wave` draws on, so at `sine` — where c1 = 1.0 and c2..c5 = 0 —
## the partials frame and the wave frame are THE SAME OBJECT, vertex for vertex. That
## is the designed null and it is the thesis: for the basis vector, decomposition is
## the identity map. Every other cell's partial stack CONTAINS that frame unchanged
## as its first rung.
##
## Deterministic and clockless: no RandomNumberGenerator (there is nothing to draw
## from), no randf, no FastNoiseLite, no _process, no Timer, no tween. Both members
## animate — additive_wave_demo._process advances _time every frame and
## SignalGenerator._process advances animation_time — so in both of them the phase
## when the shutter opens is a fact about the clock. Everything here is built inside
## _ready from arithmetic. Two builds of one cell are the same mesh.


## WHICH WAVEFORM. The four words the two members share, in additive_wave_demo's own
## order. Every value below is glossed by its harmonic series, because the series IS
## the value — the closed form is only how the sum happens to be written down.
##
##   sine      c = [1, 0, 0, 0, 0]. ONE partial, itself. Not a member of the list in
##             the same sense the others are: it is the basis they are written in.
##   square    c = (4/pi) * [1, 0, 1/3, 0, 1/5] = [1.27324, 0, 0.42441, 0, 0.25465].
##             Odd harmonics at 1/n, all the same sign. Both members agree on this
##             one: additive_wave_demo's preset is [1.0, 0, 0.333, 0, 0.2] and
##             SignalGenerator's dead additive branch is `if h % 2 == 1` at 1/h.
##   sawtooth  c = (2/pi) * [1, -1/2, 1/3, -1/4, 1/5]
##                = [0.63662, -0.31831, 0.21221, -0.15915, 0.12732].
##             ALL harmonics at 1/n, ALTERNATING. This is the series of the closed
##             form fourier_transform ships, 2*(u - floor(u + 0.5)), whose jump sits
##             at the middle of the period. additive_wave_demo's preset is all
##             POSITIVE, [1, 0.5, 0.333, 0.25, 0.2], which is also a sawtooth — the
##             one with its jump at the END of the period, half a period away. Two
##             members, one word, two phases; the reason for taking this one is in
##             `declines`.
##   triangle  c = (8/pi^2) * [1, 0, -1/9, 0, 1/25]
##                = [0.81057, 0, -0.09006, 0, 0.03242].
##             Odd harmonics at 1/n^2, ALTERNATING. The alternation is the correction
##             described above and it is visible: rung 3 hangs upside down.
##
## THE FIRST COEFFICIENTS ARE NOT EQUAL AND THAT IS A FINDING, not an inconvenience.
## Each waveform here is normalised so its CLOSED FORM peaks at AMP, which keeps all
## four `wave` frames the same height and stops the camera earning a difference the
## axis did not. The consequence is that the fundamentals differ: to build a unit
## square you need a sine 27.3 percent TALLER than the square, and to build a unit
## sawtooth one 36.3 percent SHORTER than the sawtooth. That fact exists only in the
## `partials` reading and only because the partials are drawn at true amplitude.
@export_enum("sine", "square", "sawtooth", "triangle") var waveform: String = "sine":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not WAVEFORMS.has(picked):
			return                      ## an unreachable value keeps the standing figure
		waveform = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW THE WAVEFORM IS HELD. Three values, and each one is a method one of the two
## members actually uses rather than a display option invented here.
##
##   wave      the closed form as one ribbon, centred on the axis at Y_AXIS. This is
##             fourier_transform's sign()/floor() branch drawn as a body. At a
##             discontinuity the ribbon stands up: square and sawtooth each carry one
##             vertical wall 2*AMP = 0.144 m tall at the centre of the field, which is
##             the largest single feature in the sheet.
##   partials  up to five ribbons, rung n at y = Y_AXIS - (n-1)*RUNG_DROP, amplitude
##             c[n]*AMP, drawn only where c[n] is not zero. sine draws 1, square 3,
##             sawtooth 5, triangle 3. Rung n carries n cycles across the field, so
##             the rung index is legible as a cycle count. A negative coefficient is
##             drawn as an INVERTED ribbon, not as a colour.
##   sum       the five-term partial sum as the ribbon, plus the ideal as a slab
##             standing from the axis plane to the closed form. N = 5 because that is
##             additive_wave_demo's NUM_HARMONICS and the number of sliders it has;
##             at that N the nonzero terms are sine 1, square 3, sawtooth 5,
##             triangle 3, and the difference between this reading and `wave` IS the
##             truncation.
##
## The three readings are one photograph at `sine` and three at every other value,
## which is Fourier's theorem stated as a sheet rather than as a caption.
@export_enum("wave", "partials", "sum") var reading: String = "wave":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or all four waveforms in a row. NOT PART OF EITHER AXIS, and the reason
## is a lesson every wave since 13 has paid for: capture_config_sweep unions the AABB
## across a spec's variants, so an all-waveforms value declared inside `waveform`
## would frame every single cell against four and a half metres and photograph the
## 0.006 m ribbons as hairs. The registry fixture pins `single`; `ladder` is a design
## view for looking at the four side by side in the editor.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const WAVEFORMS: PackedStringArray = ["sine", "square", "sawtooth", "triangle"]
const READINGS: PackedStringArray = ["wave", "partials", "sum"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the series ─────────────────────────────────────────────────────────────────────────
## Fourier sine coefficients for n = 1..5, normalised so the CLOSED FORM peaks at 1.
## Written out rather than computed so the sign pattern is readable at a glance and so
## the registry note can be checked against the file without running anything.
##   sine      1
##   square    (4/pi)/n,                     n odd,  all +
##   sawtooth  (2/pi)*(-1)^(n+1)/n,          all n,  alternating
##   triangle  (8/pi^2)*(-1)^((n-1)/2)/n^2,  n odd,  alternating
const C_SINE: PackedFloat32Array = [1.0, 0.0, 0.0, 0.0, 0.0]
const C_SQUARE: PackedFloat32Array = [1.273240, 0.0, 0.424413, 0.0, 0.254648]
const C_SAWTOOTH: PackedFloat32Array = [0.636620, -0.318310, 0.212207, -0.159155, 0.127324]
const C_TRIANGLE: PackedFloat32Array = [0.810570, 0.0, -0.090063, 0.0, 0.032423]

## additive_wave_demo's own number: NUM_HARMONICS = 5, five sliders, five amplitudes.
## fourier_transform's HarmonicsSlider runs 1..8 and ships 1, so the only member that
## ever sums anything sums five terms.
const N_TERMS: int = 5

# ── the stage, identical to the millimetre in all twelve cells ─────────────────────────
## THE FOUR CORNER POSTS ARE THE ONLY REASON THE AABB HOLDS STILL, and here they carry
## more weight than usual because the readings occupy wildly different bands of the
## stage: `wave` lives in a 0.144 m strip around the axis, `partials` hangs 0.328 m of
## rungs below it, and `sum` adds a slab that reaches down to the axis. Without the
## posts the box would be 0.15 m tall in one cell and 0.44 m in another, the camera
## would move between them, and every measured pair would carry a framing difference
## it did not earn. The posts stand POST_H tall at the plate corners, so the world box
## is 0.96 x 0.492 x 0.24 before a single ribbon exists.
const PLATE_HALF_X: float = 0.48
const PLATE_HALF_Z: float = 0.12
const PLATE_T: float = 0.018
const CORNER_W: float = 0.016
const CORNER_X: float = 0.470
const CORNER_Z: float = 0.110
const POST_H: float = 0.474            ## top of box = PLATE_T + POST_H = 0.492

# ── the field ──────────────────────────────────────────────────────────────────────────
## ONE PERIOD across the field, which is neither member's number and is a decline.
## additive_wave_demo draws four (phase = t*TAU*4.0 over WAVE_LENGTH 2.0) and
## fourier_transform about eleven (frequency 1.1 over t in [-5, 5]). At four periods
## the fifth partial is twenty cycles across 0.84 m, which is four pixels a cycle once
## the critic crops and resizes to 160 x 160. At one period it is five cycles and about
## sixteen — and the rung index becomes readable as a cycle count, which is the whole
## content of the axis.
const FIELD_HALF: float = 0.42
const SAMPLES: int = 160               ## even, so index 80 lands exactly on x = 0
## AMP is the peak of every CLOSED FORM, so all four `wave` frames are the same height.
const AMP: float = 0.072
const Y_AXIS: float = 0.392
const RUNG_DROP: float = 0.082
## Binding constraint is SAWTOOTH, the only waveform with adjacent nonzero rungs:
## c1*AMP + c2*AMP + RIB_T = 0.04584 + 0.02292 + 0.006 = 0.0748 < 0.082. Square's
## rungs 1 and 3 are two drops apart and need 0.1272 < 0.164. Checked, not hoped.

# ── the bodies ─────────────────────────────────────────────────────────────────────────
## A RIBBON, NOT A LINE. Both members draw their waves as ImmediateMesh line strips —
## additive_wave_demo PRIMITIVE_LINE_STRIP at 256 points, fourier_transform 20
## CSGSphere3D markers — and a line has no body: it photographs as one or two pixels
## and a still cannot report it. This is a solid strip 0.150 m wide and 0.006 m thick
## following the curve, which is about 1.10 percent of frame per rung. That matters at
## the bottom of the stack: triangle's fifth partial has amplitude 0.00233 m, which is
## a third of the ribbon's own thickness, and if the partial were a line it would be
## invisible. As a ribbon it is a nearly straight bar — and "nearly straight" is
## exactly what 1/n^2 at n = 5 looks like. The falloff reads as CURVATURE, not as
## disappearance, so nothing in the stack falls below the critic's blank floor.
const RIB_W: float = 0.150
const RIB_T: float = 0.006
## The ideal, in the `sum` reading, as a slab from the axis plane up to the closed
## form. Thinner in z than the ribbon and centred on the same z, so where the sum
## agrees with the ideal the ribbon covers the slab's top edge and where it disagrees
## the edge comes out. Square's three-term sum overshoots its own plateau by 18.8
## percent — 0.0135 m of daylight, about eight pixels in the published 760 x 760 tile.
const SLAB_T: float = 0.010

const LADDER_PITCH: float = 1.10
## Iterated rather than written inline, so no loop variable is left untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

# ── colour ─────────────────────────────────────────────────────────────────────────────
## Rec.709 luminance written down so the greyscale reading is checkable rather than
## hoped: plate 0.180, post 0.310, ideal slab 0.459, ribbon 0.901. Nothing that must be
## told apart sits within 0.13 of anything else, and the capture background is
## Color(0.055, 0.055, 0.070) at luminance 0.056, so the ribbon stands 0.845 clear of
## the void it is drawn against.
##
## THE RIBBON AND THE PARTIALS ARE THE SAME COLOUR ON PURPOSE. It is not a saving —
## the designed null requires the two frames to be identical, and a partial IS a wave,
## so giving the components their own hue would be the one decoration that contradicts
## the argument. additive_wave_demo tints its five harmonics green, blue, pink, yellow
## and purple, which makes the ladder legible and makes the components look like a
## different KIND of thing from the sum they add up to.
const C_PLATE: Color = Color(0.17, 0.18, 0.21)
const C_POST: Color = Color(0.30, 0.31, 0.34)
const C_IDEAL: Color = Color(0.44, 0.46, 0.50)
const C_WAVE: Color = Color(0.90, 0.90, 0.92)

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("waveform"):
		waveform = str(config_data["waveform"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = WAVEFORMS.duplicate()
	else:
		names.append(_pick(waveform, WAVEFORMS, "sine"))
	var how: String = _pick(reading, READINGS, "wave")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_draw_reading(holder, names[i], how)


# ── the arithmetic ─────────────────────────────────────────────────────────────────────

## The five Fourier sine coefficients of one waveform, normalised so the closed form
## peaks at 1. Falls back to the basis, which is the only value that cannot be wrong.
func _coefficients(who: String) -> PackedFloat32Array:
	match who:
		"square":
			return C_SQUARE
		"sawtooth":
			return C_SAWTOOTH
		"triangle":
			return C_TRIANGLE
		_:
			return C_SINE


## THE CLOSED FORMS, taken from SignalGenerator.generate_signal_at_time() where they
## exist there, with u the fraction of one period rather than that member's omega * t.
##   sine      sin(2*pi*u)
##   square    sign(sin(2*pi*u)) — that member's branch 1, written without sign() so a
##             sample landing exactly on the jump reads 0 and the ribbon stands up
##             through it rather than teleporting.
##   sawtooth  2*(u - floor(u + 0.5)) — that member's branch 3, verbatim. Ramps 0 -> 1
##             over the first half period, drops to -1 at u = 0.5, ramps back to 0.
##             The jump is at the CENTRE of the field, which is where a still can
##             photograph it.
##   triangle  peak +1 at u = 0.25, zero at 0 and 0.5, -1 at u = 0.75. This is the
##             SINE-PHASE triangle, a quarter period from that member's branch 2
##             (which is 2*abs(saw) - 1 and peaks at the centre). The quarter turn is
##             what makes all four of these pure SINE series in one phase convention,
##             so `partials` can stack them without a cosine appearing halfway down
##             the ladder. It is recorded as a decline.
func _ideal(who: String, u: float) -> float:
	match who:
		"square":
			var s: float = sin(TAU * u)
			if s > 0.0:
				return 1.0
			if s < 0.0:
				return -1.0
			return 0.0
		"sawtooth":
			return 2.0 * (u - floor(u + 0.5))
		"triangle":
			var v: float = fposmod(u, 1.0)
			if v < 0.25:
				return 4.0 * v
			if v < 0.75:
				return 2.0 - 4.0 * v
			return 4.0 * v - 4.0
		_:
			return sin(TAU * u)


## One partial. n is 1-based. THE NULL LIVES HERE: at who = "sine" and n = 1 this is
## 1.0 * sin(TAU * 1.0 * u), and 1.0 * y is bit-identical to y and TAU * 1.0 is
## bit-identical to TAU, so the value returned is the same double _ideal() returns for
## the same u. Nothing else is needed to make the two frames the same object.
func _partial(coeff: PackedFloat32Array, n: int, u: float) -> float:
	if n < 1 or n > coeff.size():
		return 0.0
	return coeff[n - 1] * sin(TAU * float(n) * u)


## The N-term partial sum. additive_wave_demo's _calculate_wave_value(), with the
## coefficients derived from the closed form rather than typed into a preset table.
func _partial_sum(coeff: PackedFloat32Array, u: float) -> float:
	var total: float = 0.0
	for n in range(1, N_TERMS + 1):
		total += _partial(coeff, n, u)
	return total


## SAMPLES + 1 heights in metres, sampled evenly across one period. Index 0 is the left
## edge of the field and index SAMPLES the right; index SAMPLES / 2 is exactly x = 0,
## which is where both discontinuities sit.
func _sample_ideal(who: String) -> PackedFloat32Array:
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i in range(SAMPLES + 1):
		var u: float = float(i) / float(SAMPLES)
		ys.append(AMP * _ideal(who, u))
	return ys


func _sample_partial(coeff: PackedFloat32Array, n: int) -> PackedFloat32Array:
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i in range(SAMPLES + 1):
		var u: float = float(i) / float(SAMPLES)
		ys.append(AMP * _partial(coeff, n, u))
	return ys


func _sample_sum(coeff: PackedFloat32Array) -> PackedFloat32Array:
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i in range(SAMPLES + 1):
		var u: float = float(i) / float(SAMPLES)
		ys.append(AMP * _partial_sum(coeff, u))
	return ys


# ── drawing ────────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HALF_X * 2.0, PLATE_T, PLATE_HALF_Z * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, 0.95, 0.0)

	var posts := SurfaceTool.new()
	posts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(posts,
				Vector3(sx * CORNER_X, PLATE_T + POST_H * 0.5, sz * CORNER_Z),
				Vector3(CORNER_W, POST_H, CORNER_W))
	_commit(holder, "CornerPosts", posts, C_POST, 0.80, 0.0)


func _draw_reading(holder: Node3D, who: String, how: String) -> void:
	var coeff: PackedFloat32Array = _coefficients(who)
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	if how == "partials":
		for n in range(1, N_TERMS + 1):
			# A zero coefficient is not a flat partial, it is an ABSENT one. square and
			# triangle leave rungs 2 and 4 empty and that emptiness is the statement
			# "odd harmonics only" made as a hole in the stack.
			if absf(coeff[n - 1]) < 0.0000001:
				continue
			_add_ribbon(body, _sample_partial(coeff, n),
				Y_AXIS - float(n - 1) * RUNG_DROP)
	elif how == "sum":
		# The ideal first, so it is behind in draw order as well as in argument.
		var ideal := SurfaceTool.new()
		ideal.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_slab(ideal, _sample_ideal(who))
		_commit(holder, "Ideal_" + who, ideal, C_IDEAL, 0.85, 0.0)
		_add_ribbon(body, _sample_sum(coeff), Y_AXIS)
	else:
		_add_ribbon(body, _sample_ideal(who), Y_AXIS)
	_commit(holder, "Body_" + how + "_" + who, body, C_WAVE, 0.55, 0.0)


## A solid strip following the curve: one oriented box per sample interval, each wound
## outward from its own centre. Adjacent boxes share a face plane; the two coincident
## quads carry the same albedo out of the same material, so any depth tie between them
## is invisible by construction rather than by luck.
func _add_ribbon(st: SurfaceTool, ys: PackedFloat32Array, y0: float) -> void:
	var n: int = ys.size()
	if n < 2:
		return
	var step: float = FIELD_HALF * 2.0 / float(n - 1)
	for i in range(n - 1):
		var xa: float = -FIELD_HALF + float(i) * step
		var xb: float = -FIELD_HALF + float(i + 1) * step
		_add_segment(st, Vector2(xa, y0 + ys[i]), Vector2(xb, y0 + ys[i + 1]))


## One box of the strip, thickness RIB_T along the curve's normal and width RIB_W in z.
func _add_segment(st: SurfaceTool, a: Vector2, b: Vector2) -> void:
	var d: Vector2 = b - a
	if d.length() < 0.0000001:
		return
	var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * (RIB_T * 0.5)
	var hz: float = RIB_W * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		Vector3(a.x + nrm.x, a.y + nrm.y, hz), Vector3(b.x + nrm.x, b.y + nrm.y, hz),
		Vector3(b.x + nrm.x, b.y + nrm.y, -hz), Vector3(a.x + nrm.x, a.y + nrm.y, -hz),
		Vector3(a.x - nrm.x, a.y - nrm.y, hz), Vector3(b.x - nrm.x, b.y - nrm.y, hz),
		Vector3(b.x - nrm.x, b.y - nrm.y, -hz), Vector3(a.x - nrm.x, a.y - nrm.y, -hz)])
	var c: Vector3 = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	_quad(st, p[0], p[1], p[2], p[3], c)
	_quad(st, p[4], p[5], p[6], p[7], c)
	_quad(st, p[0], p[1], p[5], p[4], c)
	_quad(st, p[3], p[2], p[6], p[7], c)
	_quad(st, p[0], p[3], p[7], p[4], c)
	_quad(st, p[1], p[2], p[6], p[5], c)


## The ideal, as the region between the axis plane and the curve, extruded SLAB_T in z.
## Four faces per interval and no interior end caps, so nothing coplanar faces the same
## way twice; the two outer caps are added so the slab is closed at the field edges.
func _add_slab(st: SurfaceTool, ys: PackedFloat32Array) -> void:
	var n: int = ys.size()
	if n < 2:
		return
	var step: float = FIELD_HALF * 2.0 / float(n - 1)
	var hz: float = SLAB_T * 0.5
	for i in range(n - 1):
		var xa: float = -FIELD_HALF + float(i) * step
		var xb: float = -FIELD_HALF + float(i + 1) * step
		var ya: float = Y_AXIS + ys[i]
		var yb: float = Y_AXIS + ys[i + 1]
		var c: Vector3 = Vector3((xa + xb) * 0.5,
			(4.0 * Y_AXIS + ys[i] + ys[i + 1]) * 0.25, 0.0)
		var f0 := Vector3(xa, Y_AXIS, hz)
		var f1 := Vector3(xa, ya, hz)
		var f2 := Vector3(xb, yb, hz)
		var f3 := Vector3(xb, Y_AXIS, hz)
		var b0 := Vector3(xa, Y_AXIS, -hz)
		var b1 := Vector3(xa, ya, -hz)
		var b2 := Vector3(xb, yb, -hz)
		var b3 := Vector3(xb, Y_AXIS, -hz)
		_quad(st, f0, f1, f2, f3, c)          ## +z face
		_quad(st, b0, b1, b2, b3, c)          ## -z face
		_quad(st, f1, f2, b2, b1, c)          ## the curve edge
		_quad(st, f0, f3, b3, b0, c)          ## the axis edge
		if i == 0:
			_quad(st, f0, f1, b1, b0, c)
		if i == n - 2:
			_quad(st, f3, f2, b2, b3, c)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`. Every material here is CULL_DISABLED as well, so a quad
## that happened to wind inward is still drawn rather than becoming a hole in the
## picture — which matters at a discontinuity, where one segment of the ribbon is very
## nearly vertical and its neighbours are flat.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var nvec: Vector3 = (b - a).cross(c - a)
	if nvec.length() < 0.0000001:
		return
	nvec = nvec.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if nvec.dot(mid - inside) < 0.0:
		nvec = -nvec
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for vtx in tri:
		st.set_normal(nvec)
		st.add_vertex(vtx)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, col: Color,
		rough: float, metal: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
