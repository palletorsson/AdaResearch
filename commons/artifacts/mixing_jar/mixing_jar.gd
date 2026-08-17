# mixing_jar.gd
# MIXING JAR — a jar, its coarse-graining, and the number that survives.
#
# WAVE 22 SYNTHESIS of [[entropy_jar]] and [[entropy_morphogenesis]], the corpus's
# two-member `found_state` family.
#
# THE HYPOTHESIS THE FAMILY MAKES is that these two artifacts are about the same
# thing. They are not, and the difference is the DIRECTION OF THE ARROW.
#
#   entropy_jar MEASURES. 80 bodies lie somewhere; _measure_entropy()
#   (entropy_jar.gd:422-465) bins them into six VERTICAL slices and computes a
#   Shannon number from the counts. Arrangement -> instrument -> number.
#
#   entropy_morphogenesis DECLARES. There is no measurement anywhere in the file.
#   S is an @export (entropy_morphogenesis_vr.gd:88) that drives frequency, noise
#   amplitude and cut threshold together (:175-177) and a gyroid is grown from it.
#   Number -> parameters -> form.
#
# Same word, opposite arrow. The jar's `found_state` names a state you can be
# WRONG about; the gyroid's names a state you TYPED IN.
#
# AND THE JAR'S OWN FOURTH VALUE ALREADY KNEW THIS. `shelled` (entropy_jar.gd:617-624)
# sorts the bodies RADIALLY — a red core inside a blue shell, as visibly ordered as
# `sorted` — and the instrument, which coarse-grains along Y and only along Y, reports
# MAXIMUM ENTROPY. entropy_morphogenesis refused to borrow the word, calling it "a joke
# about the jar's vertical binning" (its registry note, and :41-46 of its own header).
# It is not a joke and it is not a container detail. It is the one place in the family
# where the number is shown to be a fact about the GRID rather than about the stuff, and
# it is the only reason the family is worth building.
#
# SO THIS JAR IS THE SAME 72 BODIES SEEN AT FOUR STEPS OF ONE REDUCTION —
# the bodies, the six cell counts, the number, and the form that number grows —
# crossed against the four states the family declares. Three of the four steps
# cannot tell `mixed` from `shelled`. One can. That is the whole sentence.
#
# ── AXIS 1 · found_state ─────────────────────────────────────────────────────
# The family word, taken from entropy_jar.gd:68 with all four values, including the
# one entropy_morphogenesis declined. Each value is a BIN PLAN: which of the six
# vertical cells each colour occupies, and at what radius.
#
#   sorted   red in cells 0-2, blue in 3-5, both full radius. S = 0.00 exactly.
#   stirred  red in 0-3, blue in 2-5 — a two-cell overlap band. S = 0.50 exactly.
#   mixed    both colours in all six cells, both full radius. S = 1.00 exactly.
#   shelled  both colours in all six cells; red confined to r < 0.46 R and blue to
#            r > 0.74 R (entropy_jar.gd:623-624, its constants verbatim). The SAME
#            six cell counts as `mixed`, body for body. S = 1.00 exactly.
#
# THE STANDING SUSPICION WAS THAT `mixed` IS AN ALL-RUNGS VALUE — the union of
# `sorted` and `stirred` rather than a third peer. It is not, in either source, and
# the arithmetic says why: entropy_jar's three shared values are three samples of ONE
# SCALAR, the reach of each group into the other's half (0, 0.35, 1.0 of a half-height,
# :611-616 against :628-629), and entropy_morphogenesis' three are three samples of ONE
# SCALAR, S itself (0.0, 0.3, 1.0, :138-145). `mixed` is the TOP RUNG of a monotone
# ladder, not a superset of the rungs below it. It looks like a union in the jar only
# because the top of an interval-reach ladder happens to equal the union of the two
# halves it started from. No all-rungs value is added here and none was inherited.
#
# ── AXIS 2 · reduction ───────────────────────────────────────────────────────
# The chain from stuff to number, one step at a time, each step MOUNTED ALONE.
# Every step throws information away, and the axis exists so you can watch which
# step throws away the thing that mattered.
#
#   bodies  the 72 spheres where they lie. Nothing has been counted yet. This is
#           what entropy_jar shows and what entropy_morphogenesis has no version of.
#   cells   the bodies are gone; the six cells stand as split bars, each bar's WIDTH
#           its population and its SPLIT its red:blue ratio. Everything the instrument
#           at entropy_jar.gd:436-446 retains, and nothing else.
#   figure  the number alone, seven-segment, standing where the bodies stood. This is
#           the payload both sources treat as the point, and it occupies about half of
#           one percent of the jar.
#   form    the number handed to entropy_morphogenesis' own mapping — frequency
#           lerp(0.9, 1.6, S), noise amplitude lerp(0.05, 0.20, S), cut threshold
#           0.15*(S-0.5)*2, all three from :175-177 — and drawn as one z = 0 slice of
#           the very voxel field its GyroidFieldGenerator fills (:129-148). The arrow
#           run backwards: a shape grown from a number that came from a jar.
#
# Each value draws ONE thing and none contains another: `cells` does not keep the
# bodies, `figure` does not keep the cells, `form` does not keep the figure. This is
# readout_bench's rule (mount each rung alone) applied to a chain rather than a ladder.
#
# ── WHY THERE IS NO SECOND INSTRUMENT ────────────────────────────────────────
# The obvious second axis is `grain` — bin by height, by radius, by angle — and it was
# refused. entropy_jar HAS ONLY ONE GRAIN, hard-coded at :427 and :439, and the whole
# force of `shelled` is that this one grain is the one every placement has ever used.
# Offering a radial grain would let a reader repair the blindness by turning a knob,
# which is exactly the wrong lesson. The grain here is the source's, fixed, six
# vertical cells, and it stays wrong about `shelled` in every frame.
#
# ── SEEDS ────────────────────────────────────────────────────────────────────
# The y of every body is STRATIFIED, not drawn: body m of a group in cell j sits at
# (m + 0.5)/count of that cell's height. So the six counts are exact integers, S is
# exact to the last bit, and `mixed` and `shelled` share their y coordinates body for
# body — which is what makes three of the four designed nulls exact by construction
# rather than statistically close. Only azimuth and radius come from the RNG, and that
# RNG is seeded from jar_seed, which ships PINNED. entropy_jar ships particle_seed = 0
# (:82), i.e. the global randf, and its registry declares no dna.fixture at all, so
# every sweep of it has photographed four different jars.

extends Node3D

class_name MixingJar

# ═══════════════════════════════════════════════════════════════════════════════
# AXES
# ═══════════════════════════════════════════════════════════════════════════════

@export_enum("sorted", "stirred", "mixed", "shelled") var found_state: String = "sorted"
@export_enum("bodies", "cells", "figure", "form") var reduction: String = "bodies"

## Azimuth and radius only — y is stratified and never random. Ships pinned, unlike
## entropy_jar.gd:82 which ships 0 and falls through to the global RNG.
@export var jar_seed: int = 20260817

const FOUND_STATES: PackedStringArray = ["sorted", "stirred", "mixed", "shelled"]
const REDUCTIONS: PackedStringArray = ["bodies", "cells", "figure", "form"]

# ═══════════════════════════════════════════════════════════════════════════════
# THE BODY (constants; the carcass is identical in all sixteen cells)
# ═══════════════════════════════════════════════════════════════════════════════

const FOOT_W: float = 0.40
const FOOT_H: float = 0.028
const PLINTH_W: float = 0.34
const PLINTH_H: float = 0.60
const COLLAR_R: float = 0.155
const COLLAR_H: float = 0.030
const GLASS_R: float = 0.135
const GLASS_IN_R: float = 0.130
const GLASS_H: float = 0.44
const LID_R: float = 0.146
const LID_H: float = 0.020

const GLASS_Y0: float = 0.658                       # FOOT_H + PLINTH_H + COLLAR_H
const CONTENT_C: float = 0.878                      # GLASS_Y0 + GLASS_H * 0.5
const CONTENT_HALF: float = 0.20                    # content spans 0.678 .. 1.078
const BIN_COUNT: int = 6                            # entropy_jar.gd:427, verbatim
const BODIES_PER_GROUP: int = 36                    # divisible by 3, 4 and 6 — see below
const BODY_R: float = 0.014
const INNER_R: float = 0.112                        # GLASS_IN_R - BODY_R - wall

## entropy_jar.gd:623-624, character for character.
const SHELL_CORE: float = 0.46
const SHELL_SKIN: float = 0.74

# The family's palette, taken from the two sources rather than invented.
const RED: Color = Color(0.9, 0.15, 0.1)            # entropy_jar.gd:33
const BLUE: Color = Color(0.1, 0.3, 0.9)            # entropy_jar.gd:34
const GLASS_COL: Color = Color(0.85, 0.92, 0.95, 0.22)  # entropy_jar.gd:28
const PLINTH_COL: Color = Color(0.12, 0.1, 0.08)    # entropy_jar.gd:39
const AMBER: Color = Color(1.0, 0.85, 0.3)          # entropy_jar.gd:500
const FORM_COL: Color = Color(0.85, 0.93, 1.0)      # entropy_morphogenesis_vr.gd:107
const RIM_COL: Color = Color(0.2, 0.6, 1.0)         # entropy_morphogenesis_vr.gd:108

# Seven-segment cell, standing inside the glass where the bodies stand.
const SEG_W: float = 0.066
const SEG_H: float = 0.115
const SEG_T: float = 0.0128
const SEG_GAP: float = 0.013
const SEG_D: float = 0.012

# entropy_morphogenesis_vr.gd:96-100 and GyroidFieldGenerator.gd:13-18.
const BASE_FREQ: float = 0.9
const HIGH_FREQ: float = 1.6
const BASE_NOISE: float = 0.05
const HIGH_NOISE: float = 0.20
const THRESH_WOBBLE: float = 0.15
const NOISE_FREQ: float = 0.7
const FIELD_HALF: float = 4.0                       # GyroidFieldGenerator.gd:17, box_size 8
const FORM_R: float = 0.122
const FORM_N: int = 56

var _rng: RandomNumberGenerator = null
var _contents: Node3D = null
var _built: bool = false


# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_carcass()
	_rebuild_contents()
	_built = true


## Map/bench entry point. Guarded the way both sources guard theirs: act only when a
## declared value actually moved, and only once there is something to replace.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var restate: bool = false

	if config.has("found_state"):
		var v: String = str(config["found_state"]).strip_edges().to_lower()
		if FOUND_STATES.has(v) and v != found_state:
			found_state = v
			restate = true

	if config.has("reduction"):
		var r: String = str(config["reduction"]).strip_edges().to_lower()
		if REDUCTIONS.has(r) and r != reduction:
			reduction = r
			restate = true

	if config.has("jar_seed"):
		var s: int = int(config["jar_seed"])
		if s != jar_seed:
			jar_seed = s
			restate = true

	if not restate or not _built:
		return
	_rebuild_contents()


# ═══════════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC — bin plan, counts, S
# ═══════════════════════════════════════════════════════════════════════════════

## Which of the six vertical cells each colour occupies. THE AXIS. Returned as two
## arrays of cell indices; the group's 36 bodies are split evenly between them, which
## is why BODIES_PER_GROUP is 36: divisible by 3 (sorted), 4 (stirred) and 6 (mixed,
## shelled), so every cell count is an exact integer and S is exact.
func _bin_plan() -> Array:
	match found_state:
		"stirred":
			return [[0, 1, 2, 3], [2, 3, 4, 5]]
		"mixed":
			return [[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]]
		"shelled":
			return [[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]]
		_:
			return [[0, 1, 2], [3, 4, 5]]


## The radial annulus each colour is confined to. Only `shelled` uses it, and it is
## invisible to the cell counts by construction — which is the artifact's subject.
func _radial_plan() -> Array:
	if found_state == "shelled":
		return [[0.0, INNER_R * SHELL_CORE], [INNER_R * SHELL_SKIN, INNER_R]]
	return [[0.0, INNER_R], [0.0, INNER_R]]


func _cell_counts() -> Array:
	var plan: Array = _bin_plan()
	var a: Array = []
	var b: Array = []
	for i in range(BIN_COUNT):
		a.append(0)
		b.append(0)
	var groups: Array = [a, b]
	for g in range(2):
		var cells: Array = plan[g]
		var per: int = BODIES_PER_GROUP / int(cells.size())
		for c in cells:
			groups[g][int(c)] = per
	return [a, b]


## entropy_jar.gd:449-465, the same weighted per-cell binary Shannon entropy, on counts
## that are exact integers rather than the results of eighty uniform draws.
func _measure() -> float:
	var counts: Array = _cell_counts()
	var bins_a: Array = counts[0]
	var bins_b: Array = counts[1]
	var total_entropy: float = 0.0
	var n_all: float = float(BODIES_PER_GROUP * 2)
	for i in range(BIN_COUNT):
		var na: float = float(bins_a[i])
		var nb: float = float(bins_b[i])
		var total: float = na + nb
		if total < 1.0:
			continue
		var pa: float = na / total
		var pb: float = nb / total
		var bin_ent: float = 0.0
		if pa > 0.001:
			bin_ent -= pa * log(pa) / log(2.0)
		if pb > 0.001:
			bin_ent -= pb * log(pb) / log(2.0)
		total_entropy += bin_ent * (total / n_all)
	return total_entropy


# ═══════════════════════════════════════════════════════════════════════════════
# CARCASS — drawn once, identical in every cell of the sheet
# ═══════════════════════════════════════════════════════════════════════════════

func _mat(col: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m


## Unshaded and emissive, so a frame difference is an area and not a lighting accident.
func _flat(col: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.name = nm
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, y: float, mat: Material, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = 32
	mi.mesh = cm
	mi.material_override = mat
	mi.position = Vector3(0, y, 0)
	mi.name = nm
	parent.add_child(mi)
	return mi


func _build_carcass() -> void:
	var dark: StandardMaterial3D = _mat(PLINTH_COL, 0.6, 0.3)
	var steel: StandardMaterial3D = _mat(Color(0.30, 0.31, 0.33), 0.45, 0.6)

	_box(self, Vector3(FOOT_W, FOOT_H, FOOT_W), Vector3(0, FOOT_H * 0.5, 0), steel, "Foot")
	_box(self, Vector3(PLINTH_W, PLINTH_H, PLINTH_W),
		Vector3(0, FOOT_H + PLINTH_H * 0.5, 0), dark, "Plinth")
	_cyl(self, COLLAR_R, COLLAR_R, COLLAR_H, FOOT_H + PLINTH_H + COLLAR_H * 0.5, steel, "Collar")

	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.albedo_color = GLASS_COL
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.1
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cyl(self, GLASS_R, GLASS_R, GLASS_H, GLASS_Y0 + GLASS_H * 0.5, glass, "Glass")
	_cyl(self, GLASS_IN_R - 0.002, GLASS_IN_R - 0.002, 0.004, GLASS_Y0 + 0.004, steel, "JarFloor")
	_cyl(self, LID_R, LID_R * 0.98, LID_H, GLASS_Y0 + GLASS_H + LID_H * 0.5, steel, "Lid")

	# The name of the number, fixed in every frame so it can never explain a difference.
	# A seven-segment S and a five are the same five bars; that is a fact about the
	# instrument and it is allowed to be visible.
	var sig: Node3D = Node3D.new()
	sig.name = "Sigil"
	sig.position = Vector3(-0.115, 0.40, PLINTH_W * 0.5 + 0.004)
	add_child(sig)
	_seven_seg(sig, "5", 0.44, _flat(AMBER.darkened(0.35)), Vector3.ZERO)


# ═══════════════════════════════════════════════════════════════════════════════
# CONTENTS — the reduction axis. Exactly one of these four runs.
# ═══════════════════════════════════════════════════════════════════════════════

func _rebuild_contents() -> void:
	if _contents != null and is_instance_valid(_contents):
		remove_child(_contents)
		_contents.queue_free()
	_contents = Node3D.new()
	_contents.name = "Contents"
	add_child(_contents)

	_rng = RandomNumberGenerator.new()
	_rng.seed = jar_seed

	match reduction:
		"cells":
			_draw_cells()
		"figure":
			_draw_figure()
		"form":
			_draw_form()
		_:
			_draw_bodies()


## STEP 0. The 72 spheres where they lie. y is stratified inside its cell; azimuth and
## radius come from the seeded RNG. Radius is drawn uniform in AREA, which is where this
## departs from entropy_jar.gd:642 — the source draws uniform in r, which piles a third
## of every group onto the axis and would make a red core look dense for the wrong reason.
func _draw_bodies() -> void:
	var counts: Array = _cell_counts()
	var radial: Array = _radial_plan()
	var cols: Array = [RED, BLUE]
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = BODY_R
	sphere.height = BODY_R * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var bin_h: float = CONTENT_HALF * 2.0 / float(BIN_COUNT)

	for g in range(2):
		var mat: StandardMaterial3D = _mat(cols[g], 0.35, 0.15)
		mat.emission_enabled = true
		mat.emission = cols[g]
		mat.emission_energy_multiplier = 0.4
		var r_lo: float = float(radial[g][0])
		var r_hi: float = float(radial[g][1])
		var idx: int = 0
		for j in range(BIN_COUNT):
			var n: int = int(counts[g][j])
			if n <= 0:
				continue
			var y0: float = CONTENT_C - CONTENT_HALF + float(j) * bin_h
			for m in range(n):
				var y: float = y0 + (float(m) + 0.5) / float(n) * bin_h
				var ang: float = _rng.randf() * TAU
				var u: float = _rng.randf()
				var r: float = sqrt(r_lo * r_lo + u * (r_hi * r_hi - r_lo * r_lo))
				var mi: MeshInstance3D = MeshInstance3D.new()
				mi.mesh = sphere
				mi.material_override = mat
				mi.position = Vector3(cos(ang) * r, y, sin(ang) * r)
				mi.name = "Body_%d_%d" % [g, idx]
				_contents.add_child(mi)
				idx += 1


## STEP 1. Everything the instrument at entropy_jar.gd:436-446 retains: six cells, each
## holding a population and a ratio, and no information about where in the cell anything
## was or how far from the axis it stood. `mixed` and `shelled` are ONE PICTURE here.
func _draw_cells() -> void:
	var counts: Array = _cell_counts()
	var bin_h: float = CONTENT_HALF * 2.0 / float(BIN_COUNT)
	var bar_h: float = bin_h * 0.78
	var w_max: float = 0.216
	var pop_max: float = 18.0                      # stirred's fullest cell; a fixed scale
	var red_mat: StandardMaterial3D = _flat(RED)
	var blue_mat: StandardMaterial3D = _flat(BLUE)

	for j in range(BIN_COUNT):
		var na: float = float(counts[0][j])
		var nb: float = float(counts[1][j])
		var tot: float = na + nb
		if tot <= 0.0:
			continue
		var w: float = w_max * (tot / pop_max)
		var y: float = CONTENT_C - CONTENT_HALF + (float(j) + 0.5) * bin_h
		var wa: float = w * (na / tot)
		var wb: float = w - wa
		if wa > 0.0005:
			_box(_contents, Vector3(wa, bar_h, 0.05),
				Vector3(-w * 0.5 + wa * 0.5, y, 0.0), red_mat, "Cell_%d_a" % j)
		if wb > 0.0005:
			_box(_contents, Vector3(wb, bar_h, 0.05),
				Vector3(w * 0.5 - wb * 0.5, y, 0.0), blue_mat, "Cell_%d_b" % j)


## STEP 2. The number alone, standing where the bodies stood. Seven-segment geometry
## rather than a Label3D, so the frame difference between two values is three rectangles
## whose areas are constants in this file.
func _draw_figure() -> void:
	var s: float = _measure()
	var txt: String = "%.2f" % s
	var mat: StandardMaterial3D = _flat(AMBER)
	var glyphs: Array = []
	for i in range(txt.length()):
		glyphs.append(txt.substr(i, 1))

	var width: float = 0.0
	for gl in glyphs:
		if str(gl) == ".":
			width += SEG_T + SEG_GAP
		else:
			width += SEG_W + SEG_GAP
	width -= SEG_GAP

	var x: float = -width * 0.5
	for gl in glyphs:
		var ch: String = str(gl)
		if ch == ".":
			_box(_contents, Vector3(SEG_T, SEG_T, SEG_D),
				Vector3(x + SEG_T * 0.5, CONTENT_C - SEG_H * 0.5 + SEG_T * 0.5, 0.0),
				mat, "Point")
			x += SEG_T + SEG_GAP
		else:
			_seven_seg(_contents, ch, 1.0, mat, Vector3(x + SEG_W * 0.5, CONTENT_C, 0.0))
			x += SEG_W + SEG_GAP


## STEP 3. The arrow run backwards. S is handed to entropy_morphogenesis' own mapping
## (:175-177) and one z = 0 slice of the resulting field is drawn, cell by cell, from the
## same gyroid expression GyroidFieldGenerator.calculate_gyroid_density uses (:58-70) —
## including its double application of noise_freq (:43 sets it on the noise object and
## :64-68 also scales the sample coordinates by it), because this is meant to be the
## source's arithmetic and not a corrected version of it.
func _draw_form() -> void:
	var s: float = _measure()
	var freq: float = lerpf(BASE_FREQ, HIGH_FREQ, s)
	var amp: float = lerpf(BASE_NOISE, HIGH_NOISE, s)
	var thresh: float = THRESH_WOBBLE * (s - 0.5) * 2.0

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQ
	noise.seed = jar_seed

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))

	var cell: float = (FORM_R * 2.0) / float(FORM_N)
	var span: float = FIELD_HALF * 2.0
	var emitted: int = 0
	for i in range(FORM_N):
		var fx: float = (float(i) + 0.5) / float(FORM_N)
		var px: float = -FORM_R + fx * FORM_R * 2.0
		var wx: float = -FIELD_HALF + fx * span
		for j in range(FORM_N):
			var fy: float = (float(j) + 0.5) / float(FORM_N)
			var py: float = -FORM_R + fy * FORM_R * 2.0
			if px * px + py * py > FORM_R * FORM_R:
				continue
			var wy: float = -FIELD_HALF + fy * span
			# The gyroid at z = 0: sin(kx)cos(ky) + sin(ky)cos(0) + sin(0)cos(kx).
			var g: float = sin(freq * wx) * cos(freq * wy) + sin(freq * wy)
			g += amp * noise.get_noise_2d(wx * NOISE_FREQ, wy * NOISE_FREQ)
			if g <= thresh:
				continue
			var x0: float = px - cell * 0.5
			var x1: float = px + cell * 0.5
			var y0: float = CONTENT_C + py - cell * 0.5
			var y1: float = CONTENT_C + py + cell * 0.5
			var a: Vector3 = Vector3(x0, y0, 0.0)
			var b: Vector3 = Vector3(x1, y0, 0.0)
			var c: Vector3 = Vector3(x1, y1, 0.0)
			var d: Vector3 = Vector3(x0, y1, 0.0)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
			emitted += 1

	if emitted == 0:
		return
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.name = "FormSlice"
	var m: StandardMaterial3D = _flat(FORM_COL.lerp(RIM_COL, 0.25))
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	_contents.add_child(mi)


# ═══════════════════════════════════════════════════════════════════════════════
# SEVEN SEGMENT
# ═══════════════════════════════════════════════════════════════════════════════

## a top, b top-right, c bottom-right, d bottom, e bottom-left, f top-left, g middle.
func _segments_for(ch: String) -> Array:
	match ch:
		"0": return ["a", "b", "c", "d", "e", "f"]
		"1": return ["b", "c"]
		"2": return ["a", "b", "g", "e", "d"]
		"3": return ["a", "b", "g", "c", "d"]
		"4": return ["f", "g", "b", "c"]
		"5": return ["a", "f", "g", "c", "d"]
		"6": return ["a", "f", "g", "e", "c", "d"]
		"7": return ["a", "b", "c"]
		"8": return ["a", "b", "c", "d", "e", "f", "g"]
		"9": return ["a", "b", "c", "d", "f", "g"]
	return []


func _seven_seg(parent: Node3D, ch: String, scale_f: float, mat: Material, centre: Vector3) -> void:
	var w: float = SEG_W * scale_f
	var h: float = SEG_H * scale_f
	var t: float = SEG_T * scale_f
	var d: float = SEG_D * scale_f
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var vlen: float = (h - 3.0 * t) * 0.5
	var vy: float = hh - t - vlen * 0.5
	var lh: float = w - 2.0 * t

	for seg in _segments_for(ch):
		var sz: Vector3 = Vector3(lh, t, d)
		var off: Vector3 = Vector3.ZERO
		match str(seg):
			"a": off = Vector3(0.0, hh - t * 0.5, 0.0)
			"g": off = Vector3(0.0, 0.0, 0.0)
			"d": off = Vector3(0.0, -hh + t * 0.5, 0.0)
			"f":
				sz = Vector3(t, vlen, d)
				off = Vector3(-hw + t * 0.5, vy, 0.0)
			"b":
				sz = Vector3(t, vlen, d)
				off = Vector3(hw - t * 0.5, vy, 0.0)
			"e":
				sz = Vector3(t, vlen, d)
				off = Vector3(-hw + t * 0.5, -vy, 0.0)
			"c":
				sz = Vector3(t, vlen, d)
				off = Vector3(hw - t * 0.5, -vy, 0.0)
		_box(parent, sz, centre + off, mat, "seg_%s_%s" % [ch, str(seg)])


# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC — for a map, a bench or a probe
# ═══════════════════════════════════════════════════════════════════════════════

func get_entropy() -> float:
	return _measure()


func get_cell_counts() -> Array:
	return _cell_counts()
