extends Node3D

# @identity
# essence: one scalar field, evaluated ONCE at build time and cut three ways — h[i,j] becomes
#   a lifted crust, a flat coloured sheet and a rank of bars, from the same 576 numbers
# desire: to stop meeting the noise conventions one at a time, in six different rooms, and to
#   be able to point at the place where they disagree
# critical_parameter: octaves — how many scales are summed into the one field the three
#   conventions have to embody
# triggers: nothing. There is no interaction, no animation and no randomness in this file.
# emerges: the learner sees that `relief`, `plate` and `column` are not three renderers but
#   three CLAIMS about what a number is, and that they do not even agree where zero is
# needs: three ruled wall sections [has]; a datum rule the three can be read against [has];
#   an occlusion ledger [declined — see dna.declines]
# relationships: synthesis of the `readout` family's B dialect (relief · plate · column),
#   whose word it reads out of ProfileRandom.gd rather than retyping; sibling in argument to
#   slack_yard, which does the same thing for the `slack` family
# truth: a convention is not a way of showing a number, it is a claim about what the number
#   is — and the three claims here put zero in three different places, which is visible only
#   when they are standing next to each other

# ─────────────────────────────────────────────────────────────────────────────
# THE FAMILY WORD IS EXHIBITED, NOT SWEPT.
#
# `readout` is declared by eighteen artifacts in two dialects that ask DIFFERENT
# QUESTIONS under one word:
#
#   A. none | numeral | gradation | lattice  (9 members, owner
#      commons/primitives/point/xyz_slider_plate.gd, which also owns the alias
#      table and a static readout_name()) — HOW IS A VALUE DISPLAYED. The subject
#      is one scalar and the values are apparatus hung beside it.
#
#   B. relief | plate | column  (6 members: mandelbrot_set, complexity_pattern,
#      perlin_noise, perlin_noise_terrain, random_edge_profile, simplex_noise;
#      plus noisesphere and noisetorus, which drop `column` for `none` because a
#      closed surface has nowhere to stand a bar) — HOW IS A SCALAR FIELD
#      EMBODIED. The subject is a whole field and the values are three bodies.
#
#   C. entropy_jar alone: figures | number | verdict | none.
#
# This quarry takes dialect B. It holds a field, not a value.
#
# The three values sit SIDE BY SIDE, not nested, and the evidence is in the
# members' code rather than their prose. NoiseVisualizer._shape_cube writes three
# mutually exclusive assignments of one sample: relief sets size (res,res,res)
# and position.y = value; plate sets the same size and position.y = 0.0; column
# sets size (res, value+amplitude, res) and position.y = height*0.5. No branch
# contains another. complexity_pattern is the same shape in different numbers
# (_alive_lift returns 1.5 / 1.0 / 8.0 and _body_height 0.5 / 0.12 / 0.5 of a
# cell). MandelbrotSet._apply_readout reads one MultiMesh and either leaves it,
# flattens it to y = 0 or fills it into bars.
#
# Because they are parallel and not nested, showing all three at once is NOT
# merely the top value — it is the object. So the word stands, lettered on the
# apron, and the axes vary the FIELD instead.
#
# THE WORD IS READ OUT OF THE FAMILY'S OWN CONST, NOT RETYPED. Dialect B has no
# owner: five members carry five byte-identical copies of the same array
# (MandelbrotSet.gd:62, terrain_generator.gd:63, ProfileRandom.gd:76,
# complexity_pattern.gd:108, and the two sphere/torus variants). ProfileRandom.gd
# is preloaded here because it is the only one of the five whose script parses
# with no external dependency at all — no class_name, no preload, no reference to
# a global class — so reading its const cannot drag a third party's parse failure
# into this file. _check_family_list() then push_errors in BOTH directions at
# _ready: a value the family declares that this quarry has no builder for, and a
# builder this quarry has that the family has dropped.
# ─────────────────────────────────────────────────────────────────────────────

const READOUT_SRC := preload("res://algorithms/randomness/ProfileRandom.gd")

## DNA axis — what the quarry offers as proof that the three bodies are the same
## numbers. The family word (45 declarations), and the three-rung sub-list that
## six siblings already carry. `axiom` is refused: see dna.declines.
##   result   — the three bodies and nothing else.
##   trace    — + the datum rule: one blade across all three, its top edge exactly
##              at the field's zero, so the three bodies can be read against one
##              line instead of against each other.
##   longhand — + the wall ruled in three sections, each in its OWN convention:
##              relief signed with zero at the datum, column rectified with zero
##              at the floor, plate a colour ramp with NO levels on it at all,
##              because a plate has no length to measure.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

## DNA axis — how many scales are summed into the one field. The family word,
## taken with noise_space's value list [1, 2, 3, 4] rather than simplex_noise's
## [1, 2, 4, 6], for noise_space's own reason re-derived on THIS grid: see
## dna.kin for the Nyquist arithmetic.
@export_range(1, 8, 1) var octaves: int = 4

const EVIDENCES: PackedStringArray = ["result", "trace", "longhand"]
const OCTAVE_MIN := 1
const OCTAVE_MAX := 8

# ── the field: one evaluation, read three ways (law 3) ───────────────────────
# An integer hash rather than RandomNumberGenerator or FastNoiseLite. Three
# reasons, in order of weight:
#   1. It is exactly replicable in Python, so dna.predicted_degeneracy is
#      arithmetic done on this geometry rather than an estimate.
#   2. It has no state at all, so there is nothing a fixture could forget to pin.
#   3. It keeps this file out of the `generator` vocabulary. simplex | perlin |
#      value | cellular means four FastNoiseLite noise types to the four
#      artifacts that declare it; a hand-written basis calling itself `perlin`
#      would be taking a word without its answers. The basis here is fixed and
#      unswept, and no basis vocabulary is claimed.
const FIELD_SEED := 20260812
const HASH_MASK := 0xFFFFFFFF
const GRID := 24
const SPAN := 1.0            # lattice cells across a bench at octave 1
const ORIGIN_U := 3.37       # where on the lattice the bench is cut
const ORIGIN_V := 7.91
const PERSISTENCE := 0.5     # the family's gain (NoiseSpace.persistence, FastNoiseLite default)
## One fixed gain, applied identically at every rung. The fBm normaliser (the sum
## of the octave amplitudes) is a BOUND that a sum of decorrelated components
## never reaches: measured over this grid the raw field spans only 0.998 of the
## available 2.0 at one octave and 0.792 at four. 1.80 was read off the widest
## rung (1 / 0.5405 = 1.85, rounded down for headroom) so that NOTHING clips at
## any rung — checked: the extremes are -0.9729 and +0.8234 at K=1, -0.6916 and
## +0.7335 at K=4. The residual narrowing with K is a true property of fBm and is
## left visible rather than normalised away, which would have been a per-rung
## ceiling and is what law 5 forbids.
const GAIN := 1.80

# ── layout ───────────────────────────────────────────────────────────────────
const BENCH_E := 1.20                  # a bench is BENCH_E square in plan
const CELL := BENCH_E / GRID           # 0.05 m
const AMP := 0.24                      # the field's half-range in metres
const BENCH_GAP := 0.18
const Y_FLOOR := 0.10                  # apron top; the column's zero
const DATUM := Y_FLOOR + AMP           # 0.34 m; the relief's zero, and the plate
const BAR_FILL := 0.80
const APRON_MARGIN := 0.12
const APRON_Z0 := -1.27
const APRON_Z1 := 0.90
const LIP_RELIEF := 0.035              # the crust's edge: a skin, not a solid
const LIP_PLATE := 0.014
const BLADE_H := 0.09
const BLADE_T := 0.022
const BLADE_Z := 0.82
## The wall stands 0.55 m behind the benches so it is not grazed by their own
## back rows. At the sweep's standpoint a sight line descends 0.3268 m per metre
## of ground travel, so 0.55 m of standoff buys 0.1797 m of clearance: the plate
## bench, whose back row is at DATUM = 0.34 exactly, hides the wall below 0.1603,
## which is the bottom 12.6% of the 0.48 m ruled span. Stated rather than hidden.
const WALL_Z := -1.15
const WALL_T := 0.030
const TICK_H := 0.040                  # 5.4 px at the sweep's 139.90 px/m — see dna.framing_why
const TICK_T := 0.028
const ZERO_TICK_SCALE := 1.8
const RAMP_BANDS := 12
const TICKS: Array[float] = [-1.0, -0.5, 0.0, 0.5, 1.0]

## The ramp is the family's, character for character: NoiseVisualizer.gd:56 and
## SimplexVisualizer both write lerp(Color(0.2, 0.4, 0.8), Color(0.8, 0.6, 0.2),
## height_ratio). Its ceiling is FIXED at h = -1 .. +1 on all three bodies and at
## every rung of `octaves`, so a colour means one number everywhere in the sheet.
const COLD := Color(0.20, 0.40, 0.80)
const WARM := Color(0.80, 0.60, 0.20)
const STONE := Color(0.34, 0.345, 0.36)
const ACCENT := Color(0.95, 0.55, 0.12)
const DATUM_COLOR := Color(0.36, 0.72, 0.85)

## True once _ready has built the quarry. apply_grid_config before that is a
## value change with no geometry to answer it (the force_pad fault).
var _built: bool = false


func _ready() -> void:
	# The grid stamps config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred, i.e. after this, so the meta read happens here.
	_read_grid_config_meta()
	_check_family_list()
	_build()
	_built = true


# ── the vocabulary ───────────────────────────────────────────────────────────
func _readouts() -> PackedStringArray:
	return READOUT_SRC.READOUTS


## Push an error in both directions. A family value with no builder here would be
## a lane the quarry silently drops; a builder with no family value would be a
## fourth convention this quarry invented. Neither is allowed to pass quietly.
func _check_family_list() -> void:
	var family: PackedStringArray = _readouts()
	for i in range(family.size()):
		var value: String = family[i]
		if not _has_builder(value):
			push_error("noise_quarry: the readout family declares '%s' and this quarry has no builder for it. Add one or refuse the value on the record." % value)
	for i in range(BUILDERS.size()):
		var mine: String = BUILDERS[i]
		if not family.has(mine):
			push_error("noise_quarry: this quarry builds '%s' and the readout family no longer declares it. The vocabulary has moved." % mine)


## The three bodies this file knows how to build. NOT the canon — the canon is
## READOUT_SRC.READOUTS — but the list _check_family_list holds the canon against.
const BUILDERS: PackedStringArray = ["relief", "plate", "column"]


func _has_builder(value: String) -> bool:
	return BUILDERS.has(value)


# ── the field ────────────────────────────────────────────────────────────────
func _hash2(ix: int, iy: int) -> int:
	var h: int = (ix * 374761393 + iy * 668265263 + FIELD_SEED * 1442695041) & HASH_MASK
	h = (h ^ (h >> 13)) & HASH_MASK
	h = (h * 1274126177) & HASH_MASK
	return (h ^ (h >> 16)) & HASH_MASK


func _grad(ix: int, iy: int) -> Vector2:
	var a: float = TAU * (float(_hash2(ix, iy)) / 4294967296.0)
	return Vector2(cos(a), sin(a))


func _fade(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


## Gradient noise on the unit lattice, scaled to roughly -1 .. +1 (the raw form
## bounds at sqrt(2)/2).
func _perlin(x: float, y: float) -> float:
	var x0: int = int(floor(x))
	var y0: int = int(floor(y))
	var fx: float = x - float(x0)
	var fy: float = y - float(y0)
	var n00: float = _grad(x0, y0).dot(Vector2(fx, fy))
	var n10: float = _grad(x0 + 1, y0).dot(Vector2(fx - 1.0, fy))
	var n01: float = _grad(x0, y0 + 1).dot(Vector2(fx, fy - 1.0))
	var n11: float = _grad(x0 + 1, y0 + 1).dot(Vector2(fx - 1.0, fy - 1.0))
	var u: float = _fade(fx)
	var v: float = _fade(fy)
	var a: float = n00 + u * (n10 - n00)
	var b: float = n01 + u * (n11 - n01)
	return (a + v * (b - a)) * sqrt(2.0)


## ONE COPY OF THE ARITHMETIC. Every body reads this array; none recomputes it,
## and none samples a grid the others do not visit.
func _compute_field() -> PackedFloat32Array:
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
				s += amp * _perlin(ORIGIN_U + u * freq, ORIGIN_V + v * freq)
				norm += amp
				amp *= PERSISTENCE
				freq *= 2.0
			out[i * GRID + j] = clampf(GAIN * s / norm, -1.0, 1.0)
	return out


func _ramp(h: float) -> Color:
	return COLD.lerp(WARM, (h + 1.0) * 0.5)


# ── construction ─────────────────────────────────────────────────────────────
func _build() -> void:
	# remove_child first: queue_free is deferred, so a rebuild would otherwise
	# stand the new quarry inside the old one for a frame — and a capture taken in
	# that frame is a photograph of two variants at once.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var field: PackedFloat32Array = _compute_field()
	var names: PackedStringArray = _readouts()
	var n: int = names.size()
	var run: float = float(n) * BENCH_E + float(maxi(n - 1, 0)) * BENCH_GAP
	var apron_w: float = run + 2.0 * APRON_MARGIN

	_slab("Apron", Vector3(0.0, Y_FLOOR * 0.5, (APRON_Z0 + APRON_Z1) * 0.5),
		Vector3(apron_w, Y_FLOOR, APRON_Z1 - APRON_Z0), STONE)
	_slab("Wall", Vector3(0.0, Y_FLOOR + AMP, WALL_Z),
		Vector3(apron_w, 2.0 * AMP, WALL_T), STONE)

	for k in range(n):
		var bx: float = -run * 0.5 + BENCH_E * 0.5 + float(k) * (BENCH_E + BENCH_GAP)
		var value: String = names[k]
		if _has_builder(value):
			_build_bench(value, bx, field)
		_letter(value, bx)

	if evidence == "trace" or evidence == "longhand":
		_slab("DatumRule", Vector3(0.0, DATUM - BLADE_H * 0.5, BLADE_Z),
			Vector3(run, BLADE_H, BLADE_T), DATUM_COLOR)

	if evidence == "longhand":
		var zf: float = WALL_Z + WALL_T * 0.5 + TICK_T * 0.5
		for q in range(n):
			var bx2: float = -run * 0.5 + BENCH_E * 0.5 + float(q) * (BENCH_E + BENCH_GAP)
			_rule_wall(names[q], bx2, zf)


## Each convention's scale, in its OWN terms. This is the whole of `longhand`:
## three rulings of one field, drawn side by side on one wall so their zeros can
## be compared. They do not agree, and that disagreement is the artifact.
func _rule_wall(value: String, bx: float, zf: float) -> void:
	if value == "plate":
		# No levels. A plate spends the sample entirely on colour, so its scale is
		# a colour ramp and there is nothing on it to read a length against. The
		# blank where the other two carry ticks IS the finding.
		for t in range(RAMP_BANDS):
			var hh: float = -1.0 + 2.0 * (float(t) + 0.5) / float(RAMP_BANDS)
			var band: float = 2.0 * AMP / float(RAMP_BANDS)
			_slab("RampBand", Vector3(bx, Y_FLOOR + (float(t) + 0.5) * band, zf),
				Vector3(BENCH_E, band, TICK_T), _ramp(hh))
		return
	for i in range(TICKS.size()):
		var m: float = TICKS[i]
		var y: float = DATUM + AMP * m
		# WHERE EACH CONVENTION PUTS ZERO. relief is signed about the datum, so its
		# zero tick is the middle one. column is rectified — its height is
		# (h + 1) * AMP measured up from the floor — so its zero is the BOTTOM one.
		var is_zero: bool = false
		if value == "column":
			is_zero = absf(m + 1.0) < 0.000001
		else:
			is_zero = absf(m) < 0.000001
		var h: float = TICK_H * ZERO_TICK_SCALE if is_zero else TICK_H
		var c: Color = DATUM_COLOR if is_zero else ACCENT
		_slab("Tick", Vector3(bx, y, zf), Vector3(BENCH_E, h, TICK_T), c)


func _build_bench(value: String, bx: float, field: PackedFloat32Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = bx - BENCH_E * 0.5
	var z0: float = -BENCH_E * 0.5
	for i in range(GRID):
		for j in range(GRID):
			var h: float = field[i * GRID + j]
			var c: Color = _ramp(h)
			var cx: float = x0 + (float(i) + 0.5) * CELL
			var cz: float = z0 + (float(j) + 0.5) * CELL
			var edge: bool = i == 0 or i == GRID - 1 or j == 0 or j == GRID - 1
			if value == "plate":
				# The field as IMAGE: every tile on the datum, the value surviving
				# only as colour. NoiseVisualizer's `plate` exactly — position.y = 0.
				_tile(st, cx, DATUM, cz, c)
				if edge:
					_box(st, Vector3(cx, DATUM - LIP_PLATE * 0.5, cz),
						Vector3(CELL, LIP_PLATE, CELL), c * 0.8, false, false)
			elif value == "column":
				# The field as MEASURED QUANTITY: a bar from the floor to the
				# sample. The height is (h + 1) * AMP, so the column's zero is at
				# the relief's minimum and no sample is ever negative.
				var top: float = DATUM + AMP * h
				var bh: float = maxf(top - Y_FLOOR, 0.004)
				_box(st, Vector3(cx, Y_FLOOR + bh * 0.5, cz),
					Vector3(CELL * BAR_FILL, bh, CELL * BAR_FILL), c, true, false)
			else:
				# The field as TERRAIN: a crust. The tile stands at its sample and
				# skirts run to the neighbours', so the surface is continuous and
				# the edge is a 0.035 m lip — a skin over the apron, not a solid.
				var y: float = DATUM + AMP * h
				_tile(st, cx, y, cz, c)
				if i + 1 < GRID:
					var y2: float = DATUM + AMP * field[(i + 1) * GRID + j]
					_skirt_x(st, cx + CELL * 0.5, cz, minf(y, y2), maxf(y, y2), c * 0.85, y > y2)
				if j + 1 < GRID:
					var y3: float = DATUM + AMP * field[i * GRID + j + 1]
					_skirt_z(st, cx, cz + CELL * 0.5, minf(y, y3), maxf(y, y3), c * 0.85, y > y3)
				if edge:
					_box(st, Vector3(cx, y - LIP_RELIEF * 0.5, cz),
						Vector3(CELL, LIP_RELIEF, CELL), c * 0.8, false, false)
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Bench_" + value
	mi.mesh = mesh
	mi.material_override = _vertex_material()
	add_child(mi)


func _letter(value: String, bx: float) -> void:
	# The exhibited word, present at EVERY value of both axes, so no tile contains
	# a rendered word naming its own variant. Billboard is off, which also keeps
	# LabelFramer out — it treats billboard-enabled as the hanging signal and
	# would bolt a panel and a bezel behind each one.
	#
	# ALIGNMENT IS NOT ASSUMED. Label3D defaults to HORIZONTAL_ALIGNMENT_CENTER, so
	# the tab is centred on its origin and hanging it at the bench's centre x is
	# correct. A LEFT-aligned block would have hung from this point and run right,
	# which is how operations_gallery pushed a 0.467 m block 0.157 m past its panel.
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
	# Cull-disabled on purpose: the relief bench is a CRUST with a 0.035 m lip and
	# its underside is part of the reading — a skin over the apron rather than a
	# solid. It also means a mistaken winding cannot silently delete a face.
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


## THE NORMAL IS PASSED IN, NOT DERIVED FROM THE WINDING. A cross product of the
## first three vertices would have lit every top face from underneath — the tile
## quads are emitted (-x,-z) (+x,-z) (+x,+z) (-x,+z), whose cross product points
## at -Y — and the bench material is cull-disabled, so a wrong winding would not
## even have shown up as a missing face. Every quad here is axis-aligned and its
## outward direction is known at the call site, so it is stated there.
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


## A riser between two cells. `face_positive` is which way the drop is: the wall
## belongs to whichever neighbour is higher, so the normal is not a property of
## the quad, it is a property of the field.
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


func _box(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color, top: bool, bottom: bool) -> void:
	var x0: float = centre.x - size.x * 0.5
	var x1: float = centre.x + size.x * 0.5
	var y0: float = centre.y - size.y * 0.5
	var y1: float = centre.y + size.y * 0.5
	var z0: float = centre.z - size.z * 0.5
	var z1: float = centre.z + size.z * 0.5
	if top:
		_quad(st, Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), c, Vector3.UP)
	if bottom:
		_quad(st, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x0, y0, z0), c, Vector3.DOWN)
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


## Guarded: rebuild only when a declared axis actually CHANGED, and only after
## _ready has built once. An unrecognised word keeps the standing value.
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
