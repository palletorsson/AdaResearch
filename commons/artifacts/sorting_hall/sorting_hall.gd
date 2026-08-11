extends Node3D
class_name SortingHall

# @identity
# essence: one array, six sorts, one moment. Six bar_array rows stacked on a single
#   board, every row handed the SAME starting array and then wound forward to the same
#   FRACTION of its own work — so the six pictures differ only in what the algorithm
#   did, never in what it was given or in how long it was left running.
# desire: to be read down the column, not across it. The rows share an x axis index
#   for index, so a value that bubble sort has parked at the far right is at the same
#   horizontal position as the one insertion sort has just admitted on the left.
# critical_parameter: the FRACTION, and the unit it is counted in. Matching absolute
#   step counts would photograph the fast sorts barely started and the slow ones nearly
#   done, which is a picture of the clock. Matching fractions of each algorithm's own
#   total is the only fair cut through six procedures of six different lengths.
# triggers: none. Nothing plays. Each row is built, wound and stopped at build time;
#   auto_play is off on all six and no clock is left running behind the picture.
# emerges: two green regions that are not the same claim. On a reversed array at half,
#   bubble sort has 9 cells in FINAL position at the right end and insertion sort has 0 —
#   its sorted prefix of about 23 is sorted and provisional, the largest values gathered
#   in order, every one of them still to move. Both cartridges paint their region green.
#   The two sorts cost identically (992 cells each, measured), and selection, which the
#   corpus calls a bureaucrat's economy, arrives having moved 32.
# truth: the same start and the same end do not make the same journey. Six algorithms
#   agree completely about where the array is going and about nothing else, and the
#   only place that disagreement is visible is the middle, which no single artifact in
#   this family can show, because a still of a running sort catches one arbitrary pass.

# ─────────────────────────────────────────────────────────────────────────────
# SYNTHESIS (2026-08-06). Sources: the ten bar_array_* tokens, which are ONE SCENE
# WEARING TEN NAMES — bar_array (the substrate itself), the six sorts, and the three
# non-sorts (histogram, fibonacci, prime_sieve) that share the script and therefore
# inherited the axis whether they wanted it or not.
#
# THE SOURCES ARE INSTANCED, NOT IMITATED. Every row here is
# commons/substrates/bar_array/bar_array_substrate.tscn with the source's own lookup
# name stamped on it before _ready, so the family's own
# _resolve_algorithm_from_lookup_name() picks the cartridge. The bars, the spacing,
# the base plate, the rim, the label, the palette and every highlight colour are the
# family's, by construction rather than by transcription — the hall cannot drift from
# the artifacts it is about, and if somebody edits a cartridge tomorrow the hall says
# the new thing. Nothing in this file re-implements a sort.
#
# WHAT THE HALL ADDS, and it is only two things:
#   1. It winds each row forward at BUILD TIME and stops it. The substrate's own
#      promotion note says "a sort is time-domain and a still catches one arbitrary
#      pass, so how far through is not an honest axis for a photograph" — and that is
#      true of a row with a clock running. It stops being true the moment the position
#      is CHOSEN and identical across the six. The refused question becomes answerable
#      by putting six of them side by side and cutting them all at once.
#   2. It counts the work, in a currency the six can share. See THE UNIT below.
#
# THE UNIT: ONE CELL OF THE ARRAY REWRITTEN. Not one cartridge step. The cartridges'
# steps are not comparable to each other and it is not their fault — heap sort's step()
# sifts an entire subtree, quicksort's does a whole Lomuto partition in one call, and
# bubble sort's compares one adjacent pair. Budgeting in steps would have said heap
# sort costs a tenth of bubble sort, which is a fact about animation pacing wearing the
# costume of a fact about complexity. So the hall never asks the algorithm how hard it
# is working. It reads the array after every step and counts how many cells moved. That
# is measured from OUTSIDE, in the same currency for all six, it is what the eye can
# check against the picture, and it is exactly the quantity the family's own note is
# about: for the two adjacent-swap sorts it is twice the inversion count.
#   The array is always a permutation of 32 distinct values, so "moved" is exact float
#   inequality and never a rounding question.
#
# ONLY THE SIX SORTS ARE ON THE BOARD, and the three absences are load-bearing. The
# substrate's _arrange asks the CARTRIDGE (get_category() != "sorting") rather than
# checking a list of names, precisely so histogram, fibonacci and prime_sieve cannot
# have their bin counts, their series or their sieve overwritten by a ramp. They carry
# the axis and it is a deliberate no-op for them. A hall of nine would have had three
# rows on which the knob does nothing — and the reason it does nothing is the most
# careful thing in the source, so it is stated here rather than staged.
#
# WHY A WALL AND NOT A RAKED BANK. The first geometry was six benches tiered like
# lecture seating, which is what the word hall wants. It was abandoned on arithmetic,
# not taste: the capture bench looks down at 15 degrees (PITCH -0.26), and a 0.30 m bar
# occludes everything within 1.12 m behind it at that elevation, so a bank steep enough
# not to hide its own back rows is a wall with extra steps. The rows therefore share one
# plane, which also buys the thing the comparison actually needs — the six rows are the
# same size in frame, index-aligned, and none is further from the eye than another.
#
# THE PANEL IS THE EXTENT ANCHOR, and it is honest geometry rather than an invisible
# prop. The bars are a MultiMeshInstance3D, which the capture AABB counts only when no
# MeshInstance3D exists at all; the base plates are MeshInstance3D and they stop 0.30 m
# below the top row's tallest bar, so a hall without a backing board would have been
# framed to the plates and photographed with its top row cropped. The board covers the
# true extent and not a millimetre more.
#
# MEASURED BEFORE IT WAS BUILT. The six cartridge step() functions were ported to Python
# and the per-step cell diff counted exactly as _changed() below counts it, because a
# gauge that draws an unverified number is worse than no gauge. Cells moved over a whole
# run at array_size 32 —
#         reversed:  bubble 992  insertion 992  selection  32  merge 160  quick 112  heap 143
#         sorted:    bubble   0  insertion   0  selection   0  merge   0  quick  32  heap 193
# — and all six ports finish sorted, which is the port's check on itself. Two things in
# that table were wrong in the draft this file replaces: merge sort was assumed to churn
# on an already-sorted array (it writes every cell and changes none, so it moves 0), and
# heap sort's build was assumed expensive on `reversed` (a descending array is already a
# max-heap at every node, so the build moves 0 of its 143). The input that ruins both
# adjacency sorts is free for heap sort, and the input that costs them nothing is heap
# sort's worst in the whole table.
#
# DETERMINISTIC. order_seed defaults to 20260805 — the substrate's own documented sweep
# pin, not 0 — because at 0 the shipped shuffle is the global unseeded randi() and five
# variants would be five different arrays. There is no randf in this file, no _process,
# no timer and no physics. Two captures of one value are two photographs of one object.
#
# FOUND WHILE BUILDING, and left on the record for the family: the substrate's
# BasePlate/Rim BoxMesh sub-resources are NOT resource_local_to_scene, so every
# instance of bar_array_substrate.tscn in one scene shares one mesh, and
# _update_base_plate writes its size. Six rows at one array_size is fine and this hall
# is fine; two bar_arrays at different array_size in one map are not, and the last one
# to build wins both plates. That is a fact about the source, not about this artifact.
# ─────────────────────────────────────────────────────────────────────────────

## The sources, instanced. Not a copy of the scene, not a copy of the cartridges.
const ROW_SCENE := preload("res://commons/substrates/bar_array/bar_array_substrate.tscn")
## Read for its geometry constants (bar width, bar depth, bar height) so the hall's
## gauge is drawn in the family's own gauge and cannot drift from it.
const ROW_RENDERER := preload("res://commons/substrates/bar_array/bar_array_renderer.gd")
## Read for ORDERS — the initial_order value list, taken from the code that owns it
## rather than retyped here. The slot_machine pattern: one vocabulary, one home.
const ROW_SUBSTRATE := preload("res://commons/substrates/bar_array/bar_array_substrate.gd")

## The six rows, top to bottom, in the family's own teaching order: the three O(n^2)
## sorts first, then the three O(n log n). Each string is a real registry token and is
## stamped on its row as artifact_lookup_name, so the substrate's own dispatch chooses
## the cartridge. The hall never names an Algorithm enum value.
const ROWS: PackedStringArray = [
	"bar_array_bubble_sort",
	"bar_array_insertion_sort",
	"bar_array_selection_sort",
	"bar_array_merge_sort",
	"bar_array_quicksort",
	"bar_array_heap_sort",
]

## moment -> fraction of each row's OWN total work. Kept as a dispatch table as well as
## an export hint so the two cannot silently disagree.
const MOMENTS: Dictionary = {"start": 0.0, "quarter": 0.25, "half": 0.5, "done": 1.0}

## initial_order — REUSED CHARACTER FOR CHARACTER from the bar_array substrate, whose
## own ORDERS const is what validates it below. shuffled: the shipped Fisher-Yates draw.
## reversed: the worst case, n(n-1)/2 inversions. nearly_sorted: ascending with a scatter
## of adjacent transpositions. sorted: the best case for the adjacency sorts and, as this
## hall shows, no help at all to heap sort.
@export_enum("shuffled", "reversed", "nearly_sorted", "sorted") var initial_order: String = "reversed"

## moment — WHICH MOMENT OF THE COMPUTATION IS STANDING IN THE ROOM. Every row is wound
## to the same fraction of its own total work: start (untouched input), quarter, half,
## done. The word is taken from laser_exploding_sphere and its value list is refused —
## see the registry's dna.axes_note.
@export_enum("start", "quarter", "half", "done") var moment: String = "half"

## NOT AN AXIS — the determinism pin, and the substrate's own sweep seed. 0 would hand
## the rows back to the global unseeded randi().
@export var order_seed: int = 20260805
## NOT AN AXIS — the family's shipped default. Every row gets the same one; that is the
## whole premise.
@export var array_size: int = 32

## Vertical gap between one row's tallest possible bar and the next row's baseline.
const ROW_GAP: float = 0.06
## Gap between the left edge of a row's base plate and its work gauge.
const GAUGE_GAP: float = 0.05
const PANEL_MARGIN: float = 0.06
const PANEL_T: float = 0.02
const PANEL_Z: float = -0.105
const GAUGE_D: float = 0.02
## No sort of 32 distinct values reaches this. It exists so a cartridge that never
## reports done cannot hang the build.
const STEP_CAP: int = 6000

const PANEL_COLOR := Color(0.115, 0.120, 0.135)
const TRACK_COLOR := Color(0.200, 0.210, 0.240)
const COLUMN_COLOR := Color(0.420, 0.460, 0.520)
## The renderer's own comparison highlight, Color(1.0, 1.0, 0.2). The gauge fill is
## counted work, so it is drawn in the colour the family uses for work being done.
const SPENT_COLOR := Color(1.0, 1.0, 0.2)

var _built: bool = false
## Totals in the unit named by _unit, one per row, for the registry and for anybody
## reading this artifact from a report rather than from a photograph.
var _totals: Array = []
var _spent: Array = []
var _unit: String = "writes"


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_totals = []
	_spent = []

	initial_order = _pick(initial_order, ROW_SUBSTRATE.ORDERS, "shuffled")
	if not MOMENTS.has(moment):
		moment = "half"
	var fraction: float = float(MOMENTS[moment])
	var n: int = clampi(array_size, 8, 96)

	# ── The six rows, each one the source artifact it names ──────────────────────
	var rows: Array = []
	for i in range(ROWS.size()):
		var row: Node3D = ROW_SCENE.instantiate()
		# BEFORE add_child, so _ready builds with them. The lookup name is what makes
		# this row bar_array_bubble_sort rather than a bar array set to bubble sort.
		row.set_meta("artifact_lookup_name", ROWS[i])
		row.set("auto_play", false)
		row.set("array_size", n)
		row.set("order_seed", order_seed)
		row.set("initial_order", initial_order)
		row.name = "Row%d_%s" % [i, ROWS[i]]
		add_child(row)
		var work: Dictionary = _wind(row, fraction)
		_totals.append(int(work["total"]))
		_spent.append(int(work["spent"]))
		_unit = str(work["unit"])
		rows.append(row)

	# ── Ask the first row how big a row is. Never assume it. ─────────────────────
	var row_w: float = float(n) * float(ROW_RENDERER.BAR_BASE_WIDTH) * 1.15
	var bar_h: float = float(ROW_RENDERER.MAX_BAR_HEIGHT)
	if rows.size() > 0:
		var rend: Node = (rows[0] as Node3D).get_node_or_null("Renderer")
		if rend != null and rend.has_method("get_world_size"):
			var ws: Vector2 = rend.call("get_world_size")
			if ws.x > 0.01:
				row_w = ws.x
			if ws.y > 0.01:
				bar_h = ws.y
	var plate_w: float = row_w + 0.08
	if rows.size() > 0:
		var plate: Node = (rows[0] as Node3D).get_node_or_null("BasePlate")
		if plate is MeshInstance3D and (plate as MeshInstance3D).mesh is BoxMesh:
			plate_w = ((plate as MeshInstance3D).mesh as BoxMesh).size.x

	var pitch: float = bar_h + ROW_GAP
	var gauge_w: float = float(ROW_RENDERER.BAR_BASE_WIDTH)
	var gauge_x: float = -(plate_w * 0.5) - GAUGE_GAP - gauge_w * 0.5

	# Content extents in row-local x, then a shift so the board is centred on the
	# artifact's own origin — a placement engine drops this on a cell centre.
	var left: float = gauge_x - gauge_w * 0.5
	var right: float = plate_w * 0.5
	var x_shift: float = -(left + right) * 0.5

	var top: float = float(ROWS.size() - 1) * pitch + bar_h
	var bottom: float = -0.03

	for i in range(rows.size()):
		(rows[i] as Node3D).position = Vector3(
			x_shift, float(ROWS.size() - 1 - i) * pitch, 0.0)

	# ── The work gauges ──────────────────────────────────────────────────────────
	# One column per row: how many cells that algorithm rewrites on THIS input, as a
	# fraction of the busiest row in the frame, with the elapsed portion filled. The
	# columns differ; the fills all sit at the same relative height, because the whole
	# method is one fraction cut through six different amounts of work.
	var max_total: int = 1
	for t in _totals:
		max_total = maxi(max_total, int(t))

	var mat_track := _matte(TRACK_COLOR, 0.0)
	var mat_column := _matte(COLUMN_COLOR, 0.0)
	var mat_spent := _matte(SPENT_COLOR, 0.45)
	for i in range(rows.size()):
		var gy: float = (rows[i] as Node3D).position.y
		var gx: float = gauge_x + x_shift
		_box(Vector3(gauge_w * 0.55, bar_h, GAUGE_D * 0.5),
			Vector3(gx, gy + bar_h * 0.5, -0.006), mat_track, "GaugeCeiling%d" % i)
		var h_total: float = bar_h * float(_totals[i]) / float(max_total)
		if h_total > 0.002:
			_box(Vector3(gauge_w, h_total, GAUGE_D),
				Vector3(gx, gy + h_total * 0.5, 0.0), mat_column, "GaugeCost%d" % i)
		var h_spent: float = bar_h * float(_spent[i]) / float(max_total)
		if h_spent > 0.002:
			_box(Vector3(gauge_w * 0.62, h_spent, GAUGE_D),
				Vector3(gx, gy + h_spent * 0.5, 0.010), mat_spent, "GaugeSpent%d" % i)

	# ── The board. Also the capture's extent anchor; see the header. ─────────────
	var px0: float = left + x_shift - PANEL_MARGIN
	var px1: float = right + x_shift + PANEL_MARGIN
	var py0: float = bottom - PANEL_MARGIN
	var py1: float = top + PANEL_MARGIN
	_box(Vector3(px1 - px0, py1 - py0, PANEL_T),
		Vector3((px0 + px1) * 0.5, (py0 + py1) * 0.5, PANEL_Z),
		_matte(PANEL_COLOR, 0.0), "Board")

	_built = true


## Run one row to the end to learn what its whole job costs, then rewind it and run it
## again to the requested fraction of that cost. Two passes over the same deterministic
## array; the cartridge resets its own cursors inside reset().
func _wind(row: Node3D, fraction: float) -> Dictionary:
	var by_writes: bool = not _read_array(row).is_empty()
	if not by_writes:
		push_warning("sorting_hall: bar_array no longer exposes its array — "
			+ "falling back to cartridge steps, which are NOT comparable between sorts.")
	var unit: String = "steps"
	if by_writes:
		unit = "writes"
	var total: int = _drive(row, -1, by_writes)
	var spent: int = total
	if fraction < 1.0:
		row.call("reset")
		spent = _drive(row, int(floor(fraction * float(total))), by_writes)
	return {"total": total, "spent": spent, "unit": unit}


## Step the row until it is done (budget < 0) or until it has spent its budget. The
## step that reaches the budget is the last one taken — a single heap-sort sift can
## rewrite six cells at once and is not divisible.
func _drive(row: Node3D, budget: int, by_writes: bool) -> int:
	if budget == 0:
		return 0
	var prev: PackedFloat32Array = _read_array(row)
	var used: int = 0
	var steps: int = 0
	while steps < STEP_CAP:
		if bool(row.call("is_done")):
			break
		if budget > 0 and used >= budget:
			break
		row.call("single_step")
		steps += 1
		if by_writes:
			var cur: PackedFloat32Array = _read_array(row)
			used += _changed(prev, cur)
			prev = cur
		else:
			used += 1
	return used


## A SNAPSHOT, and the duplicate() is not optional. In Godot 4 a Packed*Array is passed
## and assigned BY REFERENCE, and the cartridges mutate the array in place — step() writes
## into the same buffer it was handed and returns it, and the substrate then assigns that
## same buffer back to _array. Without the copy, `prev` and `cur` in _drive are one object,
## every diff is zero, every total is zero, all six gauges are empty and every moment shows
## the input. It would have looked exactly like a correct exhibit of an axis that does
## nothing — the failure mode this corpus keeps having to name.
func _read_array(row: Node3D) -> PackedFloat32Array:
	var v: Variant = row.get("_array")
	if v is PackedFloat32Array:
		var arr: PackedFloat32Array = v
		return arr.duplicate()
	return PackedFloat32Array()


## How many cells hold a different value than they did. The array is a permutation of
## distinct values, so exact inequality is the right test and no epsilon is wanted.
func _changed(a: PackedFloat32Array, b: PackedFloat32Array) -> int:
	if a.size() != b.size():
		return b.size()
	var moved: int = 0
	for i in range(a.size()):
		if a[i] != b[i]:
			moved += 1
	return moved


func _pick(want: String, allowed: PackedStringArray, fallback: String) -> String:
	var w: String = str(want).strip_edges().to_lower()
	return w if allowed.has(w) else fallback


func _matte(c: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	m.metallic = 0.25
	if emission > 0.0:
		m.roughness = 0.55
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.name = nm
	add_child(mi)
	return mi


## Rebuild only when a named value VALIDATES, DIFFERS, and _ready has already built
## once. A hall that tears down six substrate instances on every config call — including
## the ones naming nothing it owns — is the force_pad trap.
func apply_grid_config(config: Dictionary) -> void:
	var rebuild: bool = false

	if config.has("initial_order"):
		var want: String = str(config["initial_order"]).strip_edges().to_lower()
		if ROW_SUBSTRATE.ORDERS.has(want) and want != initial_order:
			initial_order = want
			rebuild = true

	if config.has("moment"):
		var m: String = str(config["moment"]).strip_edges().to_lower()
		if MOMENTS.has(m) and m != moment:
			moment = m
			rebuild = true

	if config.has("order_seed"):
		var s: int = int(config["order_seed"])
		if s != order_seed:
			order_seed = s
			rebuild = true

	if config.has("size"):
		var sz: int = clampi(int(config["size"]), 8, 96)
		if sz != array_size:
			array_size = sz
			rebuild = true

	if rebuild and _built:
		_build()


## What the hall measured, for a report that has no photograph. Keys are the source
## tokens; values are cells rewritten in total and cells rewritten by the frozen moment.
func work_report() -> Dictionary:
	var out: Dictionary = {}
	for i in range(ROWS.size()):
		if i < _totals.size() and i < _spent.size():
			out[ROWS[i]] = {"total": _totals[i], "spent": _spent[i], "unit": _unit}
	return out
