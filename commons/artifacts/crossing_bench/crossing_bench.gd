extends Node3D
class_name CrossingBench

## crossing_bench — TWO ARTIFACTS OWN THE WORD `crossing` AND THEY ARE NOT ASKING THE
## SAME QUESTION. This bench puts both vocabularies on one axis over one pair of waves
## and lets the pictures say how far the collision goes.
##
##   sine_space              algorithms/wavefunctions/sine_space/SineSpace.gd:20
##   sine_space_explanation  commons/artifacts/sine_space_explanation/…:54
##       crossing = product | sum | radial | single
##       "how the two sine directions meet" — a question about an OPERATION on two
##       functions. NOT one scene under two names: two directories, two .tscn files,
##       two scripts, two different renderers (a 625-sphere MultiMesh you stand on
##       against a SurfaceTool display you look at). What they share is the axis
##       declaration character for character, and one substantive DISAGREEMENT — see
##       the registry `declines`, second entry. The corpus's seventh one-scene-many-
##       names family is NOT here.
##
##   fluency_seam            commons/interfaces/foundations/fluency_seam.gd:58
##       crossing = smooth | twice | spread | singular | lattice
##       "HOW FAR PAST THE THRESHOLD THE SEAM IS DRAGGED" — its own header, its own
##       capitals. Nothing to do with waves. It is a question about DISCLOSURE: how
##       much of the machine's variance has been put on the table beside its answer.
##
## So the two vocabularies are a HOMONYM before they are two halves of anything. The
## brief that commissioned this bench proposed that one names the operation and the
## other names the result; the code says the second one names neither, it names a
## distance into being shown. What this bench then does is the only honest thing left:
## take fluency_seam's words as a request — show me the answer at this much disclosure —
## and answer it in the medium the first vocabulary works in, a height field over two
## fixed waves. `lattice` becomes an actual quantisation, `singular` an actual
## fabricated term, `smooth` an actual uncrossed field. Each is buildable, each is
## faithful to what its source's code DOES, and none of them is an operation on two
## waves. That is the claim the sheet is making.
##
## THE TWO SOURCE WAVES ARE THE SAME IN ALL 21 CELLS. That is the control:
##   A(x) = sin(K·x)     the wave in x
##   B(z) = cos(K·z)     the wave in z, a quarter period out — sine_space_explanation's
##                       shipped pair at phase 0, byte for byte (`sin(a) * cos(b)`)
## K = 6π rad/m over a 0.90 m field. Nothing here has a clock: no _process, no Timer,
## no randf, no noise. Two builds of one cell are the same mesh.
##
## Deterministic, and the whole figure is arithmetic on A, B and one bump.


## HOW THE TWO WAVES ARE PUT TOGETHER — or, for the three values that came from the
## other vocabulary, what was done to the answer afterwards. SEVEN VALUES IN TWO
## CLASSES, and the class is the argument:
##
##   OPERATIONS (something is done to the two waves; from sine_space's vocabulary)
##     product   A(x)·B(z). MULTIPLY. A crest survives only where both factors crest,
##               so either factor's zero line cuts the whole surface flat: an egg-crate.
##               THE DEFAULT, and it is the shipped default of both source twins.
##     sum       ½(A(x) + B(z)). SUPERPOSE. What two waves meeting in a medium
##               actually does. Diagonal ridges, because a crest and a trough now
##               cancel to zero instead of to a saddle.
##     radial    sin(K·√(x²+z²)). READ THE CODE BEFORE BELIEVING THE NAME. This does
##               not combine the two waves at all — it DELETES the second one and
##               replaces the argument of the first with a distance. One sine, one
##               scalar argument. It is a change of variable that makes crossing
##               impossible, not a fourth way of crossing. Concentric rings, no axes.
##     single    A(x) alone, the z term withheld. The null of the axis: one wave, no
##               crossing. A corrugation, and the measure of how much of the shipped
##               relief the second factor was doing.
##
##   RESULTS (done to the answer, not to the operands; from fluency_seam's vocabulary)
##     smooth    fluency_seam's "NOT CROSSED … what you are sold. Perfectly calm."
##               Built as the uncrossed field — which is `single`'s field EXACTLY. The
##               two vocabularies name one picture here and nowhere else, and that
##               coincidence is registered as a designed null in `field` and in `zero`.
##               In `parts` they part company: sine_space's `single` knows there is a
##               second wave and withholds it; fluency_seam's `smooth` never admits a
##               second run exists, and gets its source's empty ruled bracket instead.
##     lattice   fluency_seam's "THE SUBSTRATE … a coarse cell mesh with the answer
##               snapped to it." Built as the product SNAPPED — 9 × 9 cells of 0.10 m,
##               five height levels. It is not a crossing. It is a compression applied
##               to a crossing, and the `zero` reading is where that stops being a
##               style: quantised, the nodal set stops being a curve and becomes an
##               AREA, because whole cells land exactly on zero.
##     singular  fluency_seam's "THE ONCE-OCCURRING THING … formatted, confident,
##               sealed, false." Built as the product plus ONE localised raised-cosine
##               bump that no combination of two periodic sines can produce. In `zero`
##               it shows up as a single closed loop belonging to neither family — a
##               citation in the bibliography that is in none of the sources.
## THE DECLARATION STAYS ON ONE LINE. check_dna_declarations.has_export() matches
## `@export[^\n]*\bvar\s+<axis>\b`, so a wrapped @export_enum reports NO_EXPORT and
## fails the gate while apply_dna_block — whose regex allows the newline — derives the
## values happily. Two tools disagreeing about one token is the corpus's own tell.
@export_enum("product", "sum", "radial", "single", "smooth", "lattice", "singular") var crossing: String = "product":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CROSSINGS.has(picked):
			return                      ## an unreachable value keeps the current figure
		crossing = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH OF THE THREE THINGS THERE ARE TO LOOK AT IS BUILT. Every value is real
## geometry over the SAME h(x,z); nothing here is a shader or a label.
##
##   field   the combined surface, y = DATUM + AMP·h(x,z), as a triangle mesh over a
##           72 × 72 grid, coloured by sine_space_explanation's own height ramp.
##   parts   the two SOURCE waves drawn separately as profile curtains on the two
##           near edges, with the middle left empty, and each operand marked with what
##           the crossing did to it: consumed (solid, lit), given-and-discarded
##           (hollow outline, grey), or never asked for (an empty ruled bracket, which
##           is fluency_seam's own `smooth` apparatus). NO RESULT IS SHOWN HERE. It is
##           the ingredient shelf, so it is where the axis is mostly a null.
##   zero    the nodal set — {|h| ≤ 0.20} — as standing fins on a dark deck, found by
##           ONE rule sampled at 96 × 96 and run-length merged, not by seven special
##           cases. THIS READING CARRIES THE THESIS, because the nodal set is where
##           multiplying and adding differ absolutely and where quantising stops being
##           cosmetic. Fins stand UP rather than lying flat: the capture pitches only
##           15° down, and a ruling drawn flat on a horizontal plane is compressed to
##           a quarter of itself before anyone can read it.
@export_enum("field", "parts", "zero") var reading: String = "field":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One crossing, or all seven in a row. NOT PART OF EITHER AXIS, and that is wave 13's
## lesson: capture_config_sweep unions the AABB across a spec's variants, so an
## all-values value declared inside `crossing` would frame every single cell against
## eight metres of row. The registry fixture pins `one`; the cage does the rest.
@export_enum("one", "row") var layout: String = "one":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const CROSSINGS: PackedStringArray = [
	"product", "sum", "radial", "single", "smooth", "lattice", "singular"]
const READINGS: PackedStringArray = ["field", "parts", "zero"]
const LAYOUTS: PackedStringArray = ["one", "row"]

# ── the cage, which is the whole answer to the extent trap ─────────────────────────────
## `field` spans y 0.43…0.69, `zero` 0.56…0.67, `parts` 0.38…0.90. Fitted to the FIGURE
## the camera would move between readings and between values, and a comparison across a
## moving camera is not a comparison. The plate, four pins and four top rails are drawn
## IDENTICALLY in all twenty-one cells and are the largest thing in the scene, so the
## union AABB is 0.96 × 1.00 × 0.96 in every cell by construction.
const CAGE_HALF: float = 0.48
const CAGE_H: float = 1.00
const PLATE_T: float = 0.024
const PIN: float = 0.032
const ROW_PITCH: float = 1.15

# ── the field ──────────────────────────────────────────────────────────────────────────
const FIELD_HALF: float = 0.45
## Where h = 0 lives in the world. The apron rails sit exactly here, in every cell, so
## the zero LEVEL is furniture: in `field` you can read where the surface crosses the
## rail, and in `zero` the fins stand on that same plane.
const DATUM: float = 0.56
const AMP: float = 0.13
## 6π rad/m. In sine_space_explanation's own parametrisation (a = frequency·x·TAU /
## display_size) that is frequency = 3.0 against its shipped 1.5 — DOUBLED, and the
## reason is the `zero` reading: at 1.5 the whole nodal set is five lines and there is
## almost nothing to draw. Both source twins carry frequency as a free parameter that no
## placement pins, so raising it is a choice inside the artifact's own range, not a
## change to its formula.
const K: float = 18.849556

const FIELD_N: int = 72

## The nodal set is {|h| ≤ ZERO_EPS}, sampled on a 96 × 96 lattice and merged into runs.
## ONE rule for all seven values. For a smooth h that set is a ribbon of half-width
## EPS/|∇h| around the true zero curve — about 21 mm wide for `single`, wider for `sum`
## because a sum's slope through zero is gentler than a product's, and it swells into a
## knot at every product crossing where BOTH factors vanish. For `lattice` it is not a
## ribbon at all: whole cells are exactly zero, so the set has area. That difference is
## the reading's entire point and it is why the rule must not be special-cased per value.
const ZERO_N: int = 96
const ZERO_EPS: float = 0.20
const FIN_H: float = 0.11
const DECK_T: float = 0.008

## fluency_seam's "coarse cell mesh with the answer snapped to it", in two dimensions at
## once: 9 cells across the 0.90 m field (0.10 m each, an exact 8 samples of the 72-grid
## per cell) and five height levels, h → round(h·2)/2 ∈ {-1, -0.5, 0, 0.5, 1}.
const LAT_CELLS: int = 9
const LAT_STEP: float = 2.0

## The fabricated term, and every number in it is DERIVED rather than dialled.
##
## Centred on a product MINIMUM: sin(K·0.25) = sin(3π/2) = -1 and cos(K·0.3333333) =
## cos(2π) = +1, so A·B = -1 there exactly. Of the field's several minima this is the
## one nearest the camera corner, and that choice is worth 5x: measured in the replica,
## the same forgery placed at the middle minimum reads 0.50% in `field` and placed here
## reads 2.72%, because a mesa seen against the horizon is a mesa and a mesa seen behind
## four rows of its own crests is nothing. A mark goes where it can be read.
##
## The radius is π/(2K) = 1/12 m, which is
## exactly half a product cell — the distance to the nearest zero line of either family
## — and because the profile is cos² it reaches ZERO HEIGHT AND ZERO SLOPE at that
## radius. So the forgery cannot move a single existing nodal line: every difference
## between `singular` and `product` is inside one 0.167 m disc, by construction.
##
## Height 2.0 carries the centre from -1 to exactly +1.0, the field's own maximum under
## every other value. The fabrication is precisely as tall as the tallest honest crest
## and not one millimetre taller, which is what "formatted, confident" has to mean here,
## and it means no clamp is ever reached and the envelope is identical by construction.
##
## THE LOOP THIS OPENS HAS A CLOSED FORM. Because BUMP_R = π/(2K), the product's own
## profile out of the minimum is -cos(K·d) and the bump's is 2·cos²(K·d), so the sum
## vanishes where cos(K·d) = 1/2, i.e. K·d = π/3, i.e. d = 2·BUMP_R/3 = 1/18 m. A circle
## of radius 0.0556 m — to within 4%, since the product's curvature is 4% tighter on the
## diagonals than on the axes. That circle is the whole visible difference.
const BUMP_C: Vector2 = Vector2(0.25, 0.3333333)
const BUMP_R: float = 0.0833333
const BUMP_H: float = 2.0

# ── the ingredient shelf ───────────────────────────────────────────────────────────────
const PARTS_AMP: float = 0.18
const PARTS_T: float = 0.026
const PARTS_N: int = 96
const RULE_T: float = 0.014
const SEAL_R: float = 0.030

const SIGNS: PackedFloat32Array = [-1.0, 1.0]

# ── colour, and four of the seven are inherited byte for byte ──────────────────────────
## The height ramp is sine_space_explanation's `_height_to_color` low/mid/high triple
## unchanged; C_FALSE is fluency_seam's `divergence_color`; C_LATTICE is its
## `lattice_color`; C_GHOST is its frame grey. Nothing is invented that a source already
## named.
const C_LOW: Color = Color(0.10, 0.20, 0.40)
const C_MID: Color = Color(0.20, 0.50, 0.80)
const C_HIGH: Color = Color(0.80, 0.90, 1.00)
const C_PLATE: Color = Color(0.20, 0.21, 0.24)
const C_CAGE: Color = Color(0.42, 0.43, 0.47)
const C_APRON: Color = Color(0.62, 0.64, 0.70)
const C_DECK: Color = Color(0.13, 0.14, 0.17)
const C_ZERO: Color = Color(1.00, 0.78, 0.30)
const E_ZERO: Color = Color(0.52, 0.38, 0.10)
const C_OP_A: Color = Color(0.98, 0.72, 0.30)
const C_OP_B: Color = Color(0.40, 0.80, 0.95)
const E_OP_A: Color = Color(0.46, 0.32, 0.10)
const E_OP_B: Color = Color(0.14, 0.34, 0.44)
const C_GHOST: Color = Color(0.30, 0.31, 0.35)
const C_FALSE: Color = Color(1.00, 0.42, 0.36)
const E_FALSE: Color = Color(0.52, 0.18, 0.14)
const C_LATTICE: Color = Color(0.40, 0.62, 0.88)

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
	if config_data.has("crossing"):
		crossing = str(config_data["crossing"])
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
	if layout == "row":
		names = CROSSINGS.duplicate()
	else:
		names.append(_pick(crossing, CROSSINGS, "product"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Crossing_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * ROW_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_cage(holder)
		var which: String = names[i]
		if reading == "parts":
			_build_parts(holder, which)
		elif reading == "zero":
			_build_zero(holder, which)
		else:
			_build_field(holder, which)


# ── the arithmetic, and it is the only place the axis is consulted ─────────────────────

## The wave in x. Identical under every crossing and every reading.
func _op_a(x: float) -> float:
	return sin(K * x)


## The wave in z, a quarter period out. sine_space_explanation writes this as cos(b);
## sine_space writes sin(b). Both twins are internally consistent and they disagree with
## each other by exactly π/2 on this operand — see the registry `declines`.
func _op_b(z: float) -> float:
	return cos(K * z)


func _operand(slot: int, t: float) -> float:
	if slot == 0:
		return _op_a(t)
	return _op_b(t)


## The compression grid: which cell centre a coordinate falls into.
func _snap_cell(v: float) -> float:
	var cell: float = (FIELD_HALF * 2.0) / float(LAT_CELLS)
	var i: int = int(floor((v + FIELD_HALF) / cell))
	i = clampi(i, 0, LAT_CELLS - 1)
	return -FIELD_HALF + (float(i) + 0.5) * cell


## A smooth compactly supported hump. C¹ at the rim, so it does not read as a cone.
func _bump(x: float, z: float) -> float:
	var d: float = Vector2(x, z).distance_to(BUMP_C)
	if d >= BUMP_R:
		return 0.0
	var c: float = cos(PI * 0.5 * d / BUMP_R)
	return BUMP_H * c * c


## THE WHOLE AXIS IN TWELVE LINES. Every branch returns h ∈ [-1, 1], so the surface
## occupies exactly DATUM ± AMP in all seven values and no cell is taller than the rest.
func _h(x: float, z: float, which: String) -> float:
	if which == "sum":
		return 0.5 * (_op_a(x) + _op_b(z))
	if which == "radial":
		return sin(K * sqrt(x * x + z * z))
	if which == "single" or which == "smooth":
		# ONE branch, deliberately. `smooth` and `single` are the same field and the
		# designed null in `field` and `zero` is only true to the byte because there is
		# no second code path that could drift from this one.
		return _op_a(x)
	if which == "lattice":
		var q: float = _op_a(_snap_cell(x)) * _op_b(_snap_cell(z))
		return round(q * LAT_STEP) / LAT_STEP
	if which == "singular":
		return clampf(_op_a(x) * _op_b(z) + _bump(x, z), -1.0, 1.0)
	return _op_a(x) * _op_b(z)


## What the crossing did to an operand it was handed. slot 0 = A (the wave in x),
## slot 1 = B (the wave in z). THIS IS THE ONLY PLACE `parts` BRANCHES, which is why
## product, sum and lattice are one picture there.
func _operand_state(which: String, slot: int) -> String:
	if which == "radial":
		return "ghost"                  ## neither wave survives the change of argument
	if which == "single":
		return "lit" if slot == 0 else "ghost"
	if which == "smooth":
		return "lit" if slot == 0 else "absent"
	return "lit"


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_cage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(CAGE_HALF * 2.0, PLATE_T, CAGE_HALF * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, Color.BLACK, false)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var off: float = CAGE_HALF - PIN * 0.5
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * off, CAGE_H * 0.5, sz * off),
				Vector3(PIN, CAGE_H, PIN))
	for sz in SIGNS:
		_add_box(cage, Vector3(0.0, CAGE_H - PIN * 0.5, sz * off),
			Vector3(CAGE_HALF * 2.0 - PIN * 2.0, PIN, PIN))
	for sx in SIGNS:
		_add_box(cage, Vector3(sx * off, CAGE_H - PIN * 0.5, 0.0),
			Vector3(PIN, PIN, CAGE_HALF * 2.0 - PIN * 2.0))
	_commit(holder, "Cage", cage, C_CAGE, Color.BLACK, false)

	# The apron IS the zero level, drawn as furniture in every one of the 21 cells.
	var apron := SurfaceTool.new()
	apron.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rail: float = 0.024
	var run: float = FIELD_HALF * 2.0 + rail
	for sz in SIGNS:
		_add_box(apron, Vector3(0.0, DATUM, sz * FIELD_HALF),
			Vector3(run, rail, rail))
	for sx in SIGNS:
		_add_box(apron, Vector3(sx * FIELD_HALF, DATUM, 0.0),
			Vector3(rail, rail, run))
	_commit(holder, "Apron", apron, C_APRON, Color.BLACK, false)


## The combined surface. Flat-shaded per quad, which is exact for `lattice`'s terraces
## and invisible as faceting at 72 × 72 on a 0.90 m field.
func _build_field(holder: Node3D, which: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = (FIELD_HALF * 2.0) / float(FIELD_N)
	for i in range(FIELD_N):
		var x0: float = -FIELD_HALF + step * float(i)
		var x1: float = x0 + step
		for j in range(FIELD_N):
			var z0: float = -FIELD_HALF + step * float(j)
			var z1: float = z0 + step
			var h00: float = _h(x0, z0, which)
			var h10: float = _h(x1, z0, which)
			var h11: float = _h(x1, z1, which)
			var h01: float = _h(x0, z1, which)
			_quad_col(st,
				Vector3(x0, DATUM + AMP * h00, z0), _ramp(h00),
				Vector3(x1, DATUM + AMP * h10, z0), _ramp(h10),
				Vector3(x1, DATUM + AMP * h11, z1), _ramp(h11),
				Vector3(x0, DATUM + AMP * h01, z1), _ramp(h01))
	_commit(holder, "Field", st, Color.WHITE, Color.BLACK, true)


## The nodal set, one rule, no special cases. Adjacent cells in a row are merged into a
## single box so a band that is three cells wide is three boxes, not three hundred.
func _build_zero(holder: Node3D, which: String) -> void:
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(deck, Vector3(0.0, DATUM - DECK_T * 0.5, 0.0),
		Vector3(FIELD_HALF * 2.0, DECK_T, FIELD_HALF * 2.0))
	_commit(holder, "Deck", deck, C_DECK, Color.BLACK, false)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell: float = (FIELD_HALF * 2.0) / float(ZERO_N)
	for j in range(ZERO_N):
		var cz: float = -FIELD_HALF + (float(j) + 0.5) * cell
		var run_start: int = -1
		for i in range(ZERO_N + 1):
			var inside: bool = false
			if i < ZERO_N:
				var cx: float = -FIELD_HALF + (float(i) + 0.5) * cell
				inside = absf(_h(cx, cz, which)) <= ZERO_EPS
			if inside and run_start < 0:
				run_start = i
			elif not inside and run_start >= 0:
				var x0: float = -FIELD_HALF + float(run_start) * cell
				var x1: float = -FIELD_HALF + float(i) * cell
				_add_box(st, Vector3((x0 + x1) * 0.5, DATUM + FIN_H * 0.5, cz),
					Vector3(x1 - x0, FIN_H, cell))
				run_start = -1
	var tint: Color = C_LATTICE if which == "lattice" else C_ZERO
	var glow: Color = Color(0.16, 0.28, 0.44) if which == "lattice" else E_ZERO
	_commit(holder, "Nodal", st, tint, glow, false)


## The ingredient shelf. Both operands on the two edges nearest the camera, forming an
## open V with the middle empty, so nothing the axis draws stands in front of anything
## else the axis draws.
func _build_parts(holder: Node3D, which: String) -> void:
	var lit_a := SurfaceTool.new()
	lit_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lit_b := SurfaceTool.new()
	lit_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ghost := SurfaceTool.new()
	ghost.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fake := SurfaceTool.new()
	fake.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arg := SurfaceTool.new()
	arg.begin(Mesh.PRIMITIVE_TRIANGLES)

	var any_a: bool = false
	var any_b: bool = false
	var any_ghost: bool = false

	for slot in range(2):
		var state: String = _operand_state(which, slot)
		if state == "lit":
			if slot == 0:
				_add_curtain(lit_a, 0, false)
				any_a = true
			else:
				_add_curtain(lit_b, 1, false)
				any_b = true
		elif state == "ghost":
			_add_curtain(ghost, slot, true)
			any_ghost = true
		else:
			_add_bracket(ghost, slot)
			any_ghost = true

	# The change of argument, for the one value that performs one. Two rings at the
	# radii where sin(K·r) vanishes, and a post at the origin the radius is measured
	# from — the coordinate the two waves were replaced by.
	var any_arg: bool = false
	if which == "radial":
		_add_box(arg, Vector3(0.0, DATUM + 0.050, 0.0), Vector3(0.030, 0.100, 0.030))
		_add_ring(arg, 1.0 / 6.0, 0.020, 0.030, 64)
		_add_ring(arg, 1.0 / 3.0, 0.020, 0.030, 64)
		any_arg = true

	# The fabricated ingredient, standing at the coordinates the bump actually occupies
	# in the field, with the seal fluency_seam puts on its invented citation. It is
	# formatted like the other two, it is taller than either, and there is no wave
	# behind it.
	var any_fake: bool = false
	if which == "singular":
		_add_hump(fake, BUMP_C, BUMP_R, PARTS_AMP * BUMP_H, 10, 24)
		# The seal sits on the flank facing the camera, not on the tip: fluency_seam
		# puts its seal to one side of the plate too, and a sphere balanced on the apex
		# would reach the cage's top rail.
		var sf: float = 0.55
		var sy: float = DATUM + PARTS_AMP * BUMP_H * pow(cos(PI * 0.5 * sf), 2.0)
		var sd: float = BUMP_R * sf * 0.7071
		_add_sphere(fake, Vector3(BUMP_C.x + sd, sy, BUMP_C.y + sd), SEAL_R, 8, 12)
		any_fake = true

	if any_a:
		_commit(holder, "OperandA", lit_a, C_OP_A, E_OP_A, false)
	if any_b:
		_commit(holder, "OperandB", lit_b, C_OP_B, E_OP_B, false)
	if any_ghost:
		_commit(holder, "Unused", ghost, C_GHOST, Color.BLACK, false)
	if any_arg:
		_commit(holder, "Argument", arg, C_LATTICE, Color.BLACK, false)
	if any_fake:
		_commit(holder, "Fabricated", fake, C_FALSE, E_FALSE, false)


## A profile drawn as a staircase of thin boxes: solid fills between the datum line and
## the curve, hollow traces the curve and the datum line and leaves the middle open.
## Solid says CONSUMED; hollow says GIVEN AND DISCARDED. The shape survives either way,
## so the difference is structural and not merely a change of colour.
func _add_curtain(st: SurfaceTool, slot: int, hollow: bool) -> void:
	var span: float = FIELD_HALF * 2.0
	var step: float = span / float(PARTS_N)
	for i in range(PARTS_N):
		var t: float = -FIELD_HALF + step * (float(i) + 0.5)
		var h: float = PARTS_AMP * _operand(slot, t)
		var at: Vector3 = _shelf_point(slot, t, DATUM + h * 0.5)
		var top: Vector3 = _shelf_point(slot, t, DATUM + h)
		var base: Vector3 = _shelf_point(slot, t, DATUM)
		if hollow:
			_add_box(st, top, _shelf_size(slot, step, RULE_T))
			_add_box(st, base, _shelf_size(slot, step, RULE_T))
		else:
			_add_box(st, at, _shelf_size(slot, step, maxf(absf(h), RULE_T)))


## An empty ruled bracket where a second run would go. fluency_seam draws exactly this
## at `smooth` and captions it "[ NOT ASKED ]".
func _add_bracket(st: SurfaceTool, slot: int) -> void:
	var span: float = FIELD_HALF * 2.0
	var high: float = PARTS_AMP * 1.05
	for s in SIGNS:
		_add_box(st, _shelf_point(slot, 0.0, DATUM + s * high),
			_shelf_size(slot, span, RULE_T))
		_add_box(st, _shelf_point(slot, s * FIELD_HALF, DATUM),
			_shelf_size(slot, RULE_T, high * 2.0))


## Where a shelf point lives in world space. Operand A stands on the near z edge and
## runs along x; operand B stands on the near x edge and runs along z. Both face the
## camera; neither occludes the other or the middle.
func _shelf_point(slot: int, t: float, y: float) -> Vector3:
	if slot == 0:
		return Vector3(t, y, FIELD_HALF)
	return Vector3(FIELD_HALF, y, t)


func _shelf_size(slot: int, along: float, up: float) -> Vector3:
	if slot == 0:
		return Vector3(along, up, PARTS_T)
	return Vector3(PARTS_T, up, along)


# ── mesh primitives ────────────────────────────────────────────────────────────────────

func _ramp(h: float) -> Color:
	var t: float = clampf((h + 1.0) * 0.5, 0.0, 1.0)
	if t < 0.5:
		return C_LOW.lerp(C_MID, t * 2.0)
	return C_MID.lerp(C_HIGH, (t - 0.5) * 2.0)


## A surface of revolution over the bump's own profile — the same cos² the field uses,
## so the fabricated ingredient on the shelf is the fabricated feature in the field.
func _add_hump(st: SurfaceTool, centre: Vector2, radius: float, height: float,
		rings: int, segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var r: float = radius * float(i) / float(rings)
		var c: float = cos(PI * 0.5 * r / radius)
		var y: float = DATUM + height * c * c
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var a: float = TAU * float(j) / float(segs)
			ring.append(Vector3(centre.x + cos(a) * r, y, centre.y + sin(a) * r))
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r0[k], r1[k], r1[j])


## A standing annular band: outer wall, inner wall, top cap.
func _add_ring(st: SurfaceTool, r: float, band: float, h: float, segs: int) -> void:
	var ro: float = r + band * 0.5
	var ri: float = r - band * 0.5
	var y0: float = DATUM
	var y1: float = DATUM + h
	for j in range(segs):
		var a0: float = TAU * float(j) / float(segs)
		var a1: float = TAU * float(j + 1) / float(segs)
		var oa: Vector3 = Vector3(cos(a0) * ro, 0.0, sin(a0) * ro)
		var ob: Vector3 = Vector3(cos(a1) * ro, 0.0, sin(a1) * ro)
		var ia: Vector3 = Vector3(cos(a0) * ri, 0.0, sin(a0) * ri)
		var ib: Vector3 = Vector3(cos(a1) * ri, 0.0, sin(a1) * ri)
		var up: Vector3 = Vector3(0.0, y1, 0.0)
		var dn: Vector3 = Vector3(0.0, y0, 0.0)
		_quad(st, oa + dn, ob + dn, ob + up, oa + up)
		_quad(st, ia + up, ib + up, ib + dn, ia + dn)
		_quad(st, oa + up, ob + up, ib + up, ia + up)


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int,
		segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th),
				sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


## Two triangles wound a → b → c → d with the normal taken from the winding, and every
## material is CULL_DISABLED besides: a height field has no honest inside, and a sheet
## photographed from behind is indistinguishable from a sheet that was never built.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		# The apex ring of a hump and the poles of a sphere collapse a quad onto a
		# triangle, and taking the normal from the collapsed half returns zero and drops
		# the ring — a pinhole at every tip. Fall back to the other diagonal.
		n = (c - a).cross(d - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _quad_col(st: SurfaceTool, a: Vector3, ca: Color, b: Vector3, cb: Color,
		c: Vector3, cc: Color, d: Vector3, cd: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	var cols: PackedColorArray = PackedColorArray([ca, cb, cc, ca, cc, cd])
	for i in range(6):
		st.set_normal(n)
		st.set_color(cols[i])
		st.add_vertex(tri[i])


## Only non-empty tools are committed. SurfaceTool.commit() on a tool that was begun and
## never given a vertex is not a mesh with no surfaces, it is an error in the log, and
## `parts` leaves four of its five tools empty in most cells by design.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emission: Color, vertex_colour: bool) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emission, vertex_colour)
	holder.add_child(mi)


func _mat(c: Color, emission: Color, vertex_colour: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.15
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if vertex_colour:
		m.vertex_color_use_as_albedo = true
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
