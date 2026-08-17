extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MacrostateShelf

## @identity
## name: Macrostate Shelf
## truth: a macrostate is not an arrangement, it is the COUNT of the arrangements a
##        description cannot tell apart — and of the two artifacts that share the word,
##        one draws the arrangement and never counts, and the other prints a count that
##        is not a function of the arrangement it draws.
## essence: for each of four macrostates, draw one microstate, or nine, or the number of
##          them — the number computed from the same box and the same body size that the
##          microstates were drawn in.
## critical_parameter: reading — whether the shelf shows a member of the class, a sample
##                     of the class, or the size of the class.
## relationships: synthesised from microstate_counter and random_cubes, the corpus's only
##                two-member `macrostate` family.
##
## ─────────────────────────────────────────────────────────────────────────────
## WHAT THE TWO SOURCES ACTUALLY DO, read line by line before anything here was drawn.
##
## random_cubes.gd:217-269 fences four regions off a 2 x 1 x 2 m volume and scatters 20
## cubes in whichever one `macrostate` names. It draws a wire box of the SHIPPED volume
## for the three non-default values (random_cubes.gd:212-213, 275-296) so the constraint
## is legible. There is no counter anywhere in that file, no label, no readout, no
## arithmetic. Its four values are four ARRANGEMENTS.
##
## microstate_counter.gd:461-469 does compute a multiplicity and print it
## (microstate_counter.gd:472-495): W = cells^N, log10 W = N*log10(cells), rendered as
## "W ~ 10^55 microstates" beside S = k ln W in J/K. So the starting suspicion — that
## neither member represents the count — is HALF WRONG. One of them does.
##
## BUT THE NUMBER IS NOT A FUNCTION OF THE GEOMETRY. `cells` comes from a four-entry
## table, microstate_counter.gd:47-52 — uniform 24.0, corner 3.35, layered 6.8, spilled
## 24.0 — and the file's own comment (microstate_counter.gd:43-45) states the table by
## its OUTPUT: "24.0 -> 10^55, 3.35 -> 10^21, 6.8 -> 10^33". Those constants were chosen
## for their exponents. Check them against the regions the same file draws:
##   interior half-extent 0.62 * 0.42 (microstate_counter.gd:439-440), so the interior is
##   0.5208 m on a side, V = 0.141262 m3; the corner octant is CORNER_SIDE 0.20
##   (microstate_counter.gd:63), V = 0.008 m3. A volume ratio of 17.66.
##   If cells scaled with the drawn volume, corner would be 24.0/17.66 = 1.359 cells and
##   the plate would read 10^5. It reads 10^21. The table implies a ratio of 7.16.
##   `layered` misses in the other direction: two 0.57 x 0.57 x 0.12 slabs
##   (microstate_counter.gd:64-66) are 0.552 of the interior, so 13.25 cells and 10^45,
##   against the table's 10^33.
## The artifact named for the count computes it from constants that do not follow from
## anything it draws, and misses in opposite directions on two different values.
##
## AND THE TABLE CANNOT TELL uniform FROM spilled: microstate_counter.gd:51 gives
## `spilled` the uniform base 24.0 exactly. The file is honest about this — the readout
## branches at microstate_counter.gd:481-484 and prints "W ~ unbounded" instead — but the
## internal number for the two values is the same float. That identity is this shelf's
## designed null.
##
## WHERE THE TWO SOURCES CONTRADICT EACH OTHER, which is the sharpest thing in the family:
## on `spilled`, microstate_counter takes the LID OFF — five glass plates instead of six
## and the four top frame edges skipped (microstate_counter.gd:182-202, 512) — because
## "the seal is what made the count mean anything". random_cubes lifts six cubes over the
## rim (random_cubes.gd:245-260) and still draws a CLOSED wire box, top ring included
## (random_cubes.gd:287-296). Cubes outside a box with no opening. This shelf follows
## microstate_counter: under `spilled` the top four edges are not built and no bounded
## region is drawn, because there is not one.
##
## ─────────────────────────────────────────────────────────────────────────────
## WHAT THIS SHELF ADDS, and it is one thing: the ARITHMETIC IS DERIVED FROM THE DRAWING.
## `_count_log10_for()` reads the same lo/hi that `_regions_for()` hands the cube loop,
## divides by the same body volume the cubes are built at, and adds the multinomial term
## that `layered` earns for not saying WHICH bodies are in the upper slab. Change the box
## and the column changes. Neither source has that property.
## ─────────────────────────────────────────────────────────────────────────────

# --- the shared word ---------------------------------------------------------
## Which region of the possibility box the bodies occupy — the DESCRIPTION whose
## arrangements are being counted. Character for character both sources' list
## (random_cubes.gd:69, microstate_counter.gd:37).
@export_enum("uniform", "corner", "layered", "spilled") var macrostate: String = "uniform"

## How the shelf is read. specimen = one member of the class. ensemble = nine members,
## countable. ledger = the size of the class, counted from this shelf's own geometry.
## asserted = the size microstate_counter's constant table gives for the same bodies.
@export_enum("specimen", "ensemble", "ledger", "asserted") var reading: String = "specimen"

## Pinned. Every draw in this file comes from _rng seeded with this, so a value of an axis
## is ONE arrangement rather than a fresh object per boot. random_cubes ships unseeded
## (random_cubes.gd:74-77, chance_seed 0 = the global RNG) and needed a fixture to be
## photographable at all; there is no unseeded path here.
@export var arrangement_seed: int = 20260817

## Bodies per microstate. 20 is random_cubes' cube_count (random_cubes.gd:80).
## microstate_counter uses 40 (microstate_counter.gd:76); the `asserted` column is
## recomputed at THIS count so the two columns differ by the cell constant alone and
## not by N.
@export var body_count: int = 20

const MACROSTATES: PackedStringArray = ["uniform", "corner", "layered", "spilled"]
const READINGS: PackedStringArray = ["specimen", "ensemble", "ledger", "asserted"]

# --- the carcass, identical in all sixteen cells ------------------------------
const SHELF_W: float = 1.30
const SHELF_D: float = 0.40
const SHELF_TOP: float = 1.545
const PLINTH_H: float = 0.08

# --- the possibility box ------------------------------------------------------
const BOX_SIZE: Vector3 = Vector3(1.10, 0.90, 0.30)
const BOX_CENTER: Vector3 = Vector3(0.0, 0.75, 0.0)
## Body edge. Capped by `corner`: 20 bodies of 0.045 m fill 18.7% of the corner region,
## so the confined pile is dense but does not interpenetrate its own walls.
const BODY_EDGE: float = 0.045
## random_cubes' corner is 0.64r of a 2r span in x and z and 0.32r of an r span in y —
## 0.32 of the full span on every axis (random_cubes.gd:229).
const CORNER_F: float = 0.32
## random_cubes' slabs: 0..0.22r and 0.78r..r (random_cubes.gd:237-243).
const LAYER_F: float = 0.22
## random_cubes' out_n = round(N * 0.3) (random_cubes.gd:250).
const SPILL_F: float = 0.30
const SPILL_RISE: float = 0.20

# --- the ensemble grid --------------------------------------------------------
const TILE_SCALE: float = 0.30
const TILE_COLS: int = 3
const TILE_ROWS: int = 3
const TILE_X: float = 0.41
const TILE_Y0: float = 0.40
const TILE_DY: float = 0.32

# --- the column ---------------------------------------------------------------
const COL_W: float = 0.90
const COL_D: float = 0.28
const BLOCK_H: float = 0.016
const PITCH: float = 0.019
const COL_BASE_Y: float = 0.10

## microstate_counter's own phase-cell table, quoted (microstate_counter.gd:47-52).
## Not used to draw anything; used only to build the `asserted` column beside the
## counted one. uniform and spilled are the same float in the source and are the same
## float here — that is the designed null.
const SOURCE_CELLS: Dictionary = {
	"uniform": 24.0,
	"corner": 3.35,
	"layered": 6.8,
	"spilled": 24.0,
}

const ENTROPY_RED: Color = Color(0.9, 0.3, 0.3)      # random_cubes.gd:93
const COUNT_CYAN: Color = Color(0.45, 0.85, 1.0)     # microstate_counter.gd:80
const AMBER: Color = Color(1.0, 0.68, 0.2)           # microstate_counter.gd:70
const FRAME_BLUE: Color = Color(0.55, 0.7, 0.95)     # microstate_counter.gd:82
const STEEL: Color = Color(0.16, 0.2, 0.3)

var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_read_dna_meta()
	_build_all()
	_built = true


# ══════════════════════════════════════════════════════════════════════════════
# CONFIG
# ══════════════════════════════════════════════════════════════════════════════

## GridInteractablesComponent sets `config_*` metadata on the ROOT before add_child, so
## this runs ahead of the build. An unknown word keeps the default: an axis must never be
## able to blank an artifact by typo (random_cubes.gd:111-124 for the same reason).
func _read_dna_meta() -> void:
	if has_meta("config_macrostate"):
		macrostate = _pick(str(get_meta("config_macrostate")), MACROSTATES, macrostate)
	if has_meta("config_reading"):
		reading = _pick(str(get_meta("config_reading")), READINGS, reading)
	if has_meta("config_arrangement_seed"):
		arrangement_seed = int(str(get_meta("config_arrangement_seed")))
	if has_meta("config_body_count"):
		body_count = clampi(int(str(get_meta("config_body_count"))), 2, 64)


func apply_grid_config(config: Dictionary) -> void:
	var before_m: String = macrostate
	var before_r: String = reading
	var before_s: int = arrangement_seed
	var before_n: int = body_count

	if config.has("macrostate"):
		macrostate = _pick(str(config["macrostate"]), MACROSTATES, macrostate)
	if config.has("reading"):
		reading = _pick(str(config["reading"]), READINGS, reading)
	if config.has("arrangement_seed"):
		arrangement_seed = int(str(config["arrangement_seed"]))
	if config.has("body_count"):
		body_count = clampi(int(str(config["body_count"])), 2, 64)

	# Applied before every early return: an accepted key must DO something, and the
	# curation station sends {"emissive": false} with no axis key at all. It is applied
	# by REBUILD rather than in place, and only once _ready has built — a rebuild here
	# ahead of _ready would give the shelf two sets of geometry.
	var emissive_changed: bool = false
	if config.has("emissive"):
		var want: bool = bool(config["emissive"])
		if want != emissive:
			emissive = want
			emissive_changed = true

	if not _built:
		return
	if emissive_changed:
		_rebuild()
		return
	if macrostate == before_m and reading == before_r \
			and arrangement_seed == before_s and body_count == before_n:
		return
	_rebuild()


func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


func _rebuild() -> void:
	# Free ONLY what this script made — get_children() would destroy plates and bezels
	# the grid added (microstate_counter.gd:139-153 learned this).
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


func _own(n: Node) -> Node:
	_owned.append(n)
	add_child(n)
	return n


# ══════════════════════════════════════════════════════════════════════════════
# BUILD
# ══════════════════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_build_carcass()
	match reading:
		"ensemble":
			_build_ensemble()
		"ledger":
			_build_column(_count_log10_for(macrostate), COUNT_CYAN)
		"asserted":
			_build_column(_asserted_log10_for(macrostate), AMBER)
		_:
			_build_specimen()
	_build_plate()


## The shelf itself. Nothing here reads either axis, which is why the union AABB is a
## constant 1.30 x 1.545 x 0.40 across all sixteen cells and the fixed camera frames every
## one of them identically.
func _build_carcass() -> void:
	var steel: StandardMaterial3D = _steel_mat(STEEL)
	var back: StandardMaterial3D = _matte_mat(Color(0.10, 0.12, 0.17), 0.85, 0.1)
	var body_h: float = SHELF_TOP - 0.045 - PLINTH_H
	var body_c: float = PLINTH_H + body_h * 0.5

	_own(_box(Vector3(0.0, PLINTH_H * 0.5, 0.0), Vector3(SHELF_W, PLINTH_H, SHELF_D), steel))
	_own(_box(Vector3(0.0, SHELF_TOP - 0.0225, 0.0), Vector3(SHELF_W, 0.045, SHELF_D), steel))
	_own(_box(Vector3(-SHELF_W * 0.5 + 0.02, body_c, 0.0), Vector3(0.04, body_h, SHELF_D), steel))
	_own(_box(Vector3(SHELF_W * 0.5 - 0.02, body_c, 0.0), Vector3(0.04, body_h, SHELF_D), steel))
	_own(_box(Vector3(0.0, body_c, -SHELF_D * 0.5 + 0.01), Vector3(SHELF_W, body_h, 0.02), back))


# ── the arrangement ───────────────────────────────────────────────────────────

## One microstate at full size, in the possibility box.
func _build_specimen() -> void:
	_draw_arrangement(BOX_CENTER, BOX_SIZE * 0.5, 1.0, arrangement_seed)


## Nine microstates of the SAME macrostate. Nine of the ways it could have been, made
## countable by being enumerable — which is the move neither source has.
func _build_ensemble() -> void:
	var half: Vector3 = BOX_SIZE * 0.5 * TILE_SCALE
	var row: int = 0
	while row < TILE_ROWS:
		var col: int = 0
		while col < TILE_COLS:
			var idx: int = row * TILE_COLS + col
			var c: Vector3 = Vector3(
				float(col - 1) * TILE_X,
				TILE_Y0 + float(row) * TILE_DY,
				0.0)
			_draw_arrangement(c, half, TILE_SCALE, arrangement_seed + idx * 7919)
			col += 1
		row += 1


## The possibility box in wire, the bounded regions of this macrostate as translucent
## solids, and one draw of the bodies inside them.
##
## THE REGION SOLID IS THE MACROSTATE AND THE BODIES ARE THE MICROSTATE. Neither source
## draws the region: random_cubes draws a wire box of the whole volume whatever is
## occupied (random_cubes.gd:275-296), microstate_counter draws an amber cage only on
## `corner` (microstate_counter.gd:209-215). Drawing the occupied set as a body is what
## lets one still say which arrangements the description admits.
func _draw_arrangement(center: Vector3, half: Vector3, scale_f: float, seed_val: int) -> void:
	_rng.seed = seed_val
	var open_top: bool = macrostate == "spilled"
	_wire_box(center, half, 0.008 * maxf(scale_f, 0.45), _glow_mat(FRAME_BLUE, 1.6), open_top)

	var solid: StandardMaterial3D = _glass_mat(ENTROPY_RED, 0.16)
	var body_mat: StandardMaterial3D = _glow_mat(ENTROPY_RED, 1.1)
	var edge: float = BODY_EDGE * scale_f

	for region_v in _regions_for(macrostate, center, half, SPILL_RISE * scale_f):
		var region: Dictionary = region_v
		var lo: Vector3 = region["lo"]
		var hi: Vector3 = region["hi"]
		var n: int = int(region["count"])
		if bool(region["bounded"]):
			_own(_box((lo + hi) * 0.5, hi - lo, solid))
		var i: int = 0
		while i < n:
			var p: Vector3 = Vector3(
				_rng.randf_range(lo.x + edge * 0.5, hi.x - edge * 0.5),
				_rng.randf_range(lo.y + edge * 0.5, hi.y - edge * 0.5),
				_rng.randf_range(lo.z + edge * 0.5, hi.z - edge * 0.5))
			_own(_box(p, Vector3(edge, edge, edge), body_mat))
			i += 1


## The regions this macrostate fences off, and how many bodies live in each. `bounded`
## is false for the escaped group of `spilled`: nothing confines it, so it has no cell
## count and the ledger has no denominator.
func _regions_for(ms: String, c: Vector3, h: Vector3, rise: float) -> Array:
	var out: Array = []
	var n: int = body_count

	if ms == "corner":
		var lo: Vector3 = c - h
		out.append({
			"lo": lo,
			"hi": lo + Vector3(h.x * 2.0 * CORNER_F, h.y * 2.0 * CORNER_F, h.z * 2.0 * CORNER_F),
			"count": n, "bounded": true})
	elif ms == "layered":
		var t: float = h.y * 2.0 * LAYER_F
		var top_n: int = n / 2
		out.append({
			"lo": Vector3(c.x - h.x, c.y + h.y - t, c.z - h.z),
			"hi": Vector3(c.x + h.x, c.y + h.y, c.z + h.z),
			"count": top_n, "bounded": true})
		out.append({
			"lo": Vector3(c.x - h.x, c.y - h.y, c.z - h.z),
			"hi": Vector3(c.x + h.x, c.y - h.y + t, c.z + h.z),
			"count": n - top_n, "bounded": true})
	elif ms == "spilled":
		var out_n: int = int(round(float(n) * SPILL_F))
		out.append({"lo": c - h, "hi": c + h, "count": n - out_n, "bounded": true})
		out.append({
			"lo": Vector3(c.x - h.x * 1.05, c.y + h.y + rise * 0.1, c.z - h.z * 1.05),
			"hi": Vector3(c.x + h.x * 1.05, c.y + h.y + rise * 0.1 + rise, c.z + h.z * 1.05),
			"count": out_n, "bounded": false})
	else:
		out.append({"lo": c - h, "hi": c + h, "count": n, "bounded": true})

	return out


# ── the count ─────────────────────────────────────────────────────────────────

## log10 W for a macrostate, COUNTED FROM THE SAME NUMBERS THE BODIES ARE DRAWN AT.
## Returns -1.0 for unbounded.
##
##   W = C(N; n1, n2, ...) * PROD_i (V_i / v_body) ^ n_i
##
## The multinomial term is the part microstate_counter has no equivalent of: `layered`
## says two slabs, not WHICH bodies are in the upper one, so every assignment is a
## distinct microstate of the same macrostate. For 10 and 10 of 20 that is C(20,10) =
## 184756, worth 5.27 decades, and it partly repays what the confinement costs.
func _count_log10_for(ms: String) -> float:
	var regions: Array = _regions_for(ms, BOX_CENTER, BOX_SIZE * 0.5, SPILL_RISE)
	var v_body: float = BODY_EDGE * BODY_EDGE * BODY_EDGE
	var total: float = _log10_fact(body_count)
	for region_v in regions:
		var region: Dictionary = region_v
		if not bool(region["bounded"]):
			return -1.0
		var lo: Vector3 = region["lo"]
		var hi: Vector3 = region["hi"]
		var d: Vector3 = hi - lo
		var cells: float = maxf((d.x * d.y * d.z) / v_body, 1.0001)
		var n: int = int(region["count"])
		total += float(n) * (log(cells) / log(10.0)) - _log10_fact(n)
	return total


## The same four macrostates through microstate_counter's constant table, at THIS shelf's
## body count so the only difference between the two columns is the cell number.
func _asserted_log10_for(ms: String) -> float:
	var cells: float = float(SOURCE_CELLS.get(ms, 24.0))
	return float(body_count) * (log(cells) / log(10.0))


func _log10_fact(n: int) -> float:
	var s: float = 0.0
	var i: int = 2
	while i <= n:
		s += log(float(i)) / log(10.0)
		i += 1
	return s


## A stack of blocks, one per decade of W, against a wire benchmark at the height the
## UNIFORM count reaches on this same shelf. The benchmark is drawn in both column
## readings and at the same height in both, so a short column is short against something.
func _build_column(log10_w: float, tint: Color) -> void:
	var bench: int = int(round(_count_log10_for("uniform")))
	var bench_top: float = COL_BASE_Y + float(bench) * PITCH
	var ghost: StandardMaterial3D = _glow_mat(FRAME_BLUE * 0.85, 0.7)
	_wire_box(
		Vector3(0.0, (COL_BASE_Y + bench_top) * 0.5, 0.0),
		Vector3(COL_W * 0.52, (bench_top - COL_BASE_Y) * 0.5, COL_D * 0.55),
		0.006, ghost, false)

	if log10_w < 0.0:
		# Unbounded: no stack, an open chevron over the benchmark. The count needed the
		# seal (microstate_counter.gd:484) and this value is the one that took it off.
		var chev: StandardMaterial3D = _glow_mat(tint, 2.0)
		var tip: Vector3 = Vector3(0.0, bench_top + 0.042, 0.0)
		_own(_cylinder_between(tip, tip + Vector3(-0.16, -0.07, 0.0), 0.009, chev))
		_own(_cylinder_between(tip, tip + Vector3(0.16, -0.07, 0.0), 0.009, chev))
		_own(_cylinder_between(
			tip - Vector3(0.0, 0.062, 0.0), tip + Vector3(-0.16, -0.132, 0.0), 0.009, chev))
		_own(_cylinder_between(
			tip - Vector3(0.0, 0.062, 0.0), tip + Vector3(0.16, -0.132, 0.0), 0.009, chev))
		return

	var decades: int = maxi(int(round(log10_w)), 1)
	var block: StandardMaterial3D = _glow_mat(tint, 1.4)
	var cap: StandardMaterial3D = _glow_mat(Color(1.0, 1.0, 1.0), 2.4)
	var i: int = 0
	while i < decades:
		var y: float = COL_BASE_Y + float(i) * PITCH + BLOCK_H * 0.5
		var m: StandardMaterial3D = cap if i == decades - 1 else block
		_own(_box(Vector3(0.0, y, 0.0), Vector3(COL_W, BLOCK_H, COL_D), m))
		i += 1


# ── captions ──────────────────────────────────────────────────────────────────

## Every caption stands ABOVE the carcass. Label3D is not a MeshInstance3D, so it is
## outside the capture AABB entirely — the frame is set by the shelf and cannot be moved
## by a longer word.
func _build_plate() -> void:
	var line_a: String = ""
	var line_b: String = ""
	var w: String = _w_text()

	match reading:
		"specimen":
			line_a = macrostate.to_upper()
			line_b = "ONE MICROSTATE OF"
		"ensemble":
			line_a = macrostate.to_upper()
			line_b = "%d SHOWN, OF" % (TILE_COLS * TILE_ROWS)
		"ledger":
			line_a = macrostate.to_upper()
			line_b = "COUNTED FROM THIS BOX"
		"asserted":
			# NO MACROSTATE NAME, AND THAT IS THE POINT. This reading quotes
			# microstate_counter's cell table, and the table gives uniform and spilled
			# the same float (microstate_counter.gd:47-52), so it cannot name which of
			# the two you are looking at. The two cells are one photograph.
			line_a = "AS DECLARED"
			line_b = "microstate_counter cells^N"

	_own(_billboard_label("MACROSTATE SHELF", Vector3(0.0, 1.86, 0.0), 16, FRAME_BLUE))
	_own(_billboard_label(line_a, Vector3(0.0, 1.775, 0.0), 26, Color(1.0, 1.0, 1.0)))
	_own(_billboard_label(line_b, Vector3(0.0, 1.695, 0.0), 15, Color(0.78, 0.86, 0.98)))
	var w_tint: Color = COUNT_CYAN
	if reading == "asserted":
		w_tint = AMBER
	_own(_billboard_label(w, Vector3(0.0, 1.60, 0.0), 30, w_tint))


func _w_text() -> String:
	var v: float = _count_log10_for(macrostate)
	if reading == "asserted":
		v = _asserted_log10_for(macrostate)
	if v < 0.0:
		return "W UNBOUNDED"
	return "W ~ 10^%d" % int(round(v))


# ── helpers ───────────────────────────────────────────────────────────────────

## Twelve edges, minus the top four when there is no longer a boundary up there to read
## (microstate_counter.gd:498-516 does exactly this; random_cubes.gd:287-296 does not,
## and photographs bodies outside a closed box).
func _wire_box(center: Vector3, half: Vector3, r: float, mat: Material, open_top: bool) -> void:
	var corners: Array = [
		Vector3(-half.x, -half.y, -half.z), Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, half.z), Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x, half.y, -half.z), Vector3(half.x, half.y, -half.z),
		Vector3(half.x, half.y, half.z), Vector3(-half.x, half.y, half.z)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e_v in edges:
		var e: Array = e_v
		var i0: int = int(e[0])
		var i1: int = int(e[1])
		if open_top and i0 >= 4 and i1 >= 4:
			continue
		var a: Vector3 = center + corners[i0]
		var b: Vector3 = center + corners[i1]
		_own(_cylinder_between(a, b, r, mat))
