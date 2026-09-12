extends Node3D
class_name ShannonEntropyMeter

## Wall-mounted Shannon entropy gauge — generates random sequences,
## computes symbol frequencies, and displays H = -Σ p(x) log₂ p(x).

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall gauge that turns a random sequence into a number — the average information per symbol, in bits
# desire: to make the abstract "amount of randomness" a thing on a wall the player can read like a thermometer
# critical_parameter: num_symbols — sets the maximum possible entropy log₂(N), the ceiling against which the actual is measured; disclosure — how much of the measurement the gauge shows behind the number (oracle | tally | ledger | works | origin)
# triggers: continuous re-sampling of a random stream, frequency histogram bars updating, entropy bar climbing toward log₂(N)
# emerges: the visual fact that uniform distributions have HIGHER entropy than skewed ones — randomness IS evenness; at disclosure:oracle the same H arrives with the histogram gone, and the gauge asks to be believed instead of read
# needs: num_symbols[has] sequence_length[has] entropy_label[has] frequency_bars[has] vr_distribution_picker[missing]
# relationships: the measurement instrument for the randomness sequence — pairs with distribution_sampler and entropy_jar; shares the `disclosure` ladder word for word with [[prng_crank_machine]], [[coin_toss]] and [[monte_carlo_dartboard]]
# truth: information IS uncertainty resolved — H = -Σ p(x) log₂ p(x) is the formula for "how surprised should you be?"

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02) — disclosure
#
# ADOPTED, NOT INVENTED. Six machines in the randomness registry already run this
# ladder; prng_crank_machine owns the table and every sibling reads its rung
# through it rather than through a private copy. Same five words, same order,
# same spellings, same legacy default.
#
#   disclosure    oracle  <  tally  <  ledger  <  works  <  origin
#
# WHY THIS QUESTION BELONGS ON A METER. Every other artifact wearing this word is
# a machine that PRODUCES randomness. This one MEASURES it, which puts the axis
# on its sharpest edge: an instrument's whole authority is the account it can
# give of its own reading. A thermometer that shows only a number is asking to be
# trusted; one that shows its scale, its sample and its source is asking to be
# read. H = 2.997 bits is the same number at all five rungs, and it means a
# completely different thing depending on how much of the measurement is still
# on the wall next to it.
#
# WHAT THE RUNGS MEAN ON THIS GAUGE:
#
#   oracle  the panel carries its title and one glowing number. No scale, no
#           ticks, no ceiling, no histogram, no sample, no formula. There is no
#           way to tell 2.997 from 3.997 without the log₂(N) it is measured
#           against — this rung shows the reading and withholds the ruler.
#   tally   + the aggregate. The bar track, its 0/1/2/3/max ticks, the
#           "max = 3.32 bits (10 symbols)" ceiling, and the ten frequency bars
#           with their symbol labels. Now the number has a scale and the
#           distribution has a shape: evenness becomes something you can SEE,
#           which is the artifact's actual lesson.
#   ledger  + the per-trial record. The sequence strip along the bottom —
#           "3 7 1 0 9 4 ..." — the first forty symbols exactly as drawn. The
#           histogram is a claim about this strip and now you can spot-check it.
#   works   + the model. H = -Σ p(x) log₂ p(x) under the title: the rule by
#           which the strip became the bar. THE LEGACY LINEAGE, byte for byte —
#           this is the meter exactly as it has always shipped.
#   origin  + the state that produced it. A SOURCE strip naming the generator,
#           its seed and the sample size, so the measurement acquires a
#           provenance. What the meter reports is a property of a stream somebody
#           configured, not a property of the world.
#
# WHAT IS DELIBERATELY NOT THE AXIS. num_symbols and sequence_length are the
# two obvious exports and both change WHAT IS TAUGHT — the ceiling log₂(N) and
# the sampling error are the curriculum, not staging (R5). bar_color_low /
# bar_color_high are a palette, and "which colour" is not a claim.
#
# NOT TOUCHED, AND NOT NEGOTIABLE: the measurement. The same seeded stream draws
# the same sequence_length symbols in the same order at every rung, the counts
# are accumulated the same way, and H = -Σ p log₂ p is computed and displayed
# identically — including at `oracle`. There is no rung at which the meter reads
# nothing, so this axis has no `none`, exactly as the family's others do not.
# ─────────────────────────────────────────────────────────────────────────────
#
# THE LEDGER (2026-09-11, Waves/Chance/Noise R1, Random_Entropy). A second, opt-in
# axis, `stand`, stages the gauge for a body: `ledger` puts the panel on a post at
# reading height over a desk that carries ALL sequence_length draws as a ribbon of
# coloured tiles, one per draw, in the order they were drawn — the strip on the
# panel shows only the first forty, and the ribbon marks which forty. Three push
# buttons: SORT regroups the same tiles by symbol (a stable sort of a COPY; the
# histogram and H do not move, and the readout prints the sorted copy's H beside
# the reading and counts the tiles that moved); CONTRAST measures a second sample
# of the same alphabet and the same N drawn from a concentrated law (p ∝ 2⁻ᵏ,
# seed + 1), so a lower H arrives with nothing but the distribution changed;
# DISCLOSE steps the meter's own rung. A housed readout prints N, the symbols, the
# source and its seed, the counts and their sum, H and log₂(N). `stand:none` (the
# default) is byte-for-byte the previous behaviour; the measurement path is split
# into the draw (_run_measurement) and the measuring of a given sequence
# (_measure), which the default build still walks in the same order.
#
#   "shannon_entropy_meter:90#stand:ledger#disclosure:ledger"

## The family's ladder, defined once in prng_crank_machine. Preloaded (not the
## global class_name): class_name lookups are not reliable headless, and every
## frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

## THE AXIS — how much of its own measurement this gauge shows behind the number.
## Same five rungs, same order, same spellings as the rest of the family.
## `works` is the legacy default.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares. This is what a map token (#disclosure:) is checked against.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## The staging: `none` (the wall gauge as it is) or `ledger` (see THE LEDGER above).
@export_enum("none", "ledger") var stand: String = "none"

## Rank of the current rung, 0..4, read through the family's one table. An
## unreadable word resolves to the legacy rung, never to silence.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(Disclosure.disclosure_name(disclosure), 3))

# --- Configuration ---
@export var panel_size: Vector2 = Vector2(0.7, 0.5)
@export var num_symbols: int = 10
@export var sequence_length: int = 200
@export var bar_color_low: Color = Color(0.2, 0.3, 0.9)
@export var bar_color_high: Color = Color(0.9, 0.2, 0.3)

## Determinism. This meter has ALWAYS been reproducible — _ready() has seeded a
## LOCAL generator from hash("shannon_entropy") since it shipped, and no draw here
## ever touches the global stream. So there is no false-bite risk on this artifact
## and nothing to repair; the export exists to make the pinning DECLARED rather
## than buried in a literal, and to give the `origin` rung a real number to name.
##
## -1 = today exactly: hash("shannon_entropy"). Any other value replaces it.
@export var stream_seed: int = -1

# --- Internal ---
var _rng := RandomNumberGenerator.new()
var _panel_mesh: MeshInstance3D
var _bar_mesh: MeshInstance3D
var _bar_material: StandardMaterial3D
var _entropy_label: Node3D
var _formula_label: Node3D
var _title_label: Node3D
var _max_label: Node3D
var _sequence_label: Node3D
## The `origin` rung's source strip. Null at every other rung.
var _origin_label: Node3D
var _freq_bars: Array[MeshInstance3D] = []
var _freq_labels: Array[Node3D] = []
## The `origin` rung's declared-law ghosts, one per symbol. Empty at every other
## rung, which is what the size guard in _run_measurement tests.
var _expected_bars: Array[MeshInstance3D] = []
## The `origin` rung's three rows, so the ledger can name a second source on them.
var _origin_rows: Array[Node3D] = []

# Cached positions/colors for boards rebuilt on runtime .text updates.
const ENTROPY_COLOR := Color(1.0, 1.0, 0.6)
const SEQUENCE_COLOR := Color(0.55, 0.6, 0.7)
var _entropy_pos: Vector3
var _sequence_pos: Vector3

# Gauge layout — top section is the entropy bar, bottom section is the histogram
const BAR_REGION_LEFT := -0.28
const BAR_REGION_WIDTH := 0.56
const BAR_REGION_BOTTOM := 0.0
const BAR_REGION_HEIGHT := 0.06
const FREQ_REGION_BOTTOM := -0.18
const FREQ_BAR_HEIGHT := 0.1

# ── the measurement, kept (the ledger and probes read it; the boards show it) ──
var _sequence: Array[int] = []
var _counts: Array[int] = []
var _entropy: float = 0.0
var _strip_text: String = ""

# ── the ledger (stand:ledger only) ──
const LIFT: float = 1.40             # the panel's centre above the deck
const DESK_H: float = 0.92
const DESK_W: float = 2.30
const DESK_D: float = 0.45
const DESK_Z: float = 0.45           # the desk's centre; it spans z 0.225 … 0.675
const RIBBON_Z: float = 0.40
const RIBBON_W: float = 2.0
const TILE := Vector3(0.008, 0.03, 0.02)
const SORT_SECONDS: float = 1.2
var _staging_root: Node3D
var _panel: Node3D
var _readout_case: Node3D
var _readout: Label3D
var _ribbon: MultiMeshInstance3D
var _excerpt: MultiMeshInstance3D   # the first forty, magnified on the desk's front (12 September)
var _strip_mark: MeshInstance3D
var _sample_uniform: Array[int] = []
var _sample_contrast: Array[int] = []
var _contrast_seed: int = 0
var sorted_view: bool = false
var contrast: bool = false
var _source_name: String = "uniform"
var _sorted_index: Array[int] = []   # for tile i (draw order), its place in the sorted copy
var _sort_t: float = 0.0             # 0 = as drawn, 1 = sorted
var _sort_tween: Tween

## True once _ready has built the panel. The museum lane hands a map token's config to
## apply_grid_config BEFORE _ready (measured 2026-09-11, Random_Entropy: twenty frequency
## bars, two of everything, stacked); before that the values are only stored and _ready
## builds once with them. After it, a change rebuilds inline as it always did.
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


## The build sequence, lifted verbatim out of _ready so apply_grid_config can run
## it again after a rung change. Order unchanged: the seed is set before the first
## draw, and _run_measurement runs last because it writes into the bars the three
## builders above it created.
func _build_all() -> void:
	_rng.seed = hash("shannon_entropy") if stream_seed < 0 else stream_seed
	_build_panel()
	_build_gauge()
	_build_frequency_bars()
	_build_labels()
	_run_measurement()
	_apply_stand()


## The effective seed, for the `origin` strip. Same expression _build_all uses.
func _effective_seed() -> int:
	return hash("shannon_entropy") if stream_seed < 0 else stream_seed


func _build_panel() -> void:
	_panel_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	_panel_mesh.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.1)
	mat.roughness = 0.85
	mat.metallic = 0.1
	_panel_mesh.material_override = mat
	add_child(_panel_mesh)

	# Thin frame border
	var frame_color := Color(0.15, 0.2, 0.35)
	_add_frame_edge(Vector3(0, panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002), frame_color)
	_add_frame_edge(Vector3(0, -panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002), frame_color)
	_add_frame_edge(Vector3(-panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002), frame_color)
	_add_frame_edge(Vector3(panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002), frame_color)


func _add_frame_edge(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	add_child(mi)


func _build_gauge() -> void:
	# THE RULER. A reading without a scale is a rumour: 2.997 means nothing until
	# you can see it against log₂(10) = 3.32. So the whole gauge — track, fill,
	# ticks and their numerals — is the `tally` rung's aggregate apparatus, and
	# `oracle` withholds it and keeps only the glowing number.
	if _rung() < 1:
		return

	# Background bar track
	var track := MeshInstance3D.new()
	var track_quad := QuadMesh.new()
	track_quad.size = Vector2(BAR_REGION_WIDTH, BAR_REGION_HEIGHT)
	track.mesh = track_quad
	track.position = Vector3(
		BAR_REGION_LEFT + BAR_REGION_WIDTH / 2.0,
		BAR_REGION_BOTTOM + BAR_REGION_HEIGHT / 2.0,
		0.002
	)
	var track_mat := StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.03, 0.03, 0.05)
	track.material_override = track_mat
	add_child(track)

	# Fill bar
	_bar_mesh = MeshInstance3D.new()
	var bar_quad := QuadMesh.new()
	bar_quad.size = Vector2(0.01, BAR_REGION_HEIGHT - 0.02)
	_bar_mesh.mesh = bar_quad
	_bar_mesh.position = Vector3(BAR_REGION_LEFT, BAR_REGION_BOTTOM + BAR_REGION_HEIGHT / 2.0, 0.003)

	_bar_material = StandardMaterial3D.new()
	_bar_material.albedo_color = bar_color_low
	_bar_material.emission_enabled = true
	_bar_material.emission = bar_color_low
	_bar_material.emission_energy_multiplier = 1.2
	_bar_mesh.material_override = _bar_material
	add_child(_bar_mesh)

	# Scale tick marks: 0, 1, 2, 3, max
	var max_h := log(num_symbols) / log(2.0)
	var ticks := [0.0, 1.0, 2.0, 3.0, max_h]
	for val in ticks:
		if val > max_h + 0.01:
			continue
		var frac: float = val / max_h
		var x_pos: float = BAR_REGION_LEFT + frac * BAR_REGION_WIDTH
		# Tick line
		var tick := MeshInstance3D.new()
		var tick_box := BoxMesh.new()
		tick_box.size = Vector3(0.003, BAR_REGION_HEIGHT + 0.01, 0.001)
		tick.mesh = tick_box
		tick.position = Vector3(x_pos, BAR_REGION_BOTTOM + BAR_REGION_HEIGHT / 2.0, 0.004)
		var tick_mat := StandardMaterial3D.new()
		tick_mat.albedo_color = Color(0.25, 0.25, 0.3)
		tick.material_override = tick_mat
		add_child(tick)
		# Tick label — integrated board
		var tick_text: String = "%.1f" % val if val != max_h else "%.2f" % val
		var tick_lbl: Node3D = BakedText.make_tag(
			tick_text, Color(0.6, 0.6, 0.7), 0.022,
			Color(0.05, 0.05, 0.08), true, Color(0, 0, 0, 0))
		if tick_lbl:
			tick_lbl.position = Vector3(x_pos, BAR_REGION_BOTTOM - 0.02, 0.003)
			add_child(tick_lbl)


func _build_frequency_bars() -> void:
	# THE AGGREGATE ITSELF. p(x) for every symbol, drawn. This histogram is the
	# only place in the artifact where "randomness IS evenness" is a picture
	# rather than an assertion, which is why it arrives at `tally` and not later.
	if _rung() < 1:
		return

	var bar_width: float = BAR_REGION_WIDTH / float(num_symbols) * 0.8
	var gap: float = BAR_REGION_WIDTH / float(num_symbols) * 0.2
	var total_step: float = bar_width + gap

	for i in range(num_symbols):
		var x_pos: float = BAR_REGION_LEFT + i * total_step + bar_width / 2.0
		# Frequency bar
		var bar := MeshInstance3D.new()
		var bar_quad := QuadMesh.new()
		bar_quad.size = Vector2(bar_width, 0.01)
		bar.mesh = bar_quad
		bar.position = Vector3(x_pos, FREQ_REGION_BOTTOM, 0.003)
		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = _symbol_color(i)
		bar_mat.emission_enabled = true
		bar_mat.emission = _symbol_color(i) * 0.5
		bar_mat.emission_energy_multiplier = 0.6
		bar.material_override = bar_mat
		add_child(bar)
		_freq_bars.append(bar)

		# Symbol label beneath — integrated board
		var lbl: Node3D = BakedText.make_tag(
			str(i), Color(0.55, 0.55, 0.6), 0.02,
			Color(0.05, 0.05, 0.08), true, Color(0, 0, 0, 0))
		if lbl:
			lbl.position = Vector3(x_pos, FREQ_REGION_BOTTOM + FREQ_BAR_HEIGHT + 0.015, 0.003)
			add_child(lbl)
		_freq_labels.append(lbl)

		# ORIGIN — the ghost of the LAW. A uniform PRNG DECLARES p = 1/N for every
		# symbol; the histogram shows what it actually did. This rung draws the
		# declaration behind the sample as a pale flat-topped bar, slightly wider
		# so it shows on both sides of the live one. The gap between the two is
		# sampling error, and seeing it is what turns "the source is uniform" from
		# a thing you were told into a thing you can measure by eye. Built inside
		# the loop but only at this rung, so no child index moves below it.
		if _rung() >= 4:
			var ghost := MeshInstance3D.new()
			var ghost_quad := QuadMesh.new()
			ghost_quad.size = Vector2(bar_width + gap * 0.7, 0.01)
			ghost.mesh = ghost_quad
			ghost.position = Vector3(x_pos, FREQ_REGION_BOTTOM, 0.0025)
			var gmat := StandardMaterial3D.new()
			gmat.albedo_color = Color(0.42, 0.44, 0.52)
			gmat.emission_enabled = true
			gmat.emission = Color(0.42, 0.44, 0.52)
			gmat.emission_energy_multiplier = 0.35
			ghost.material_override = gmat
			add_child(ghost)
			_expected_bars.append(ghost)


func _build_labels() -> void:
	# Title
	_title_label = BakedText.make_tag(
		"Shannon Entropy", Color(0.85, 0.9, 1.0), 0.05,
		Color(0.07, 0.08, 0.12), true, Color(0.42, 0.6, 0.95))
	if _title_label:
		_title_label.position = Vector3(0, panel_size.y / 2.0 - 0.045, 0.003)
		add_child(_title_label)

	# Formula
	_formula_label = BakedText.make_tag(
		"H = -\u03a3 p(x) log\u2082 p(x)", Color(0.6, 0.75, 0.95), 0.035,
		Color(0.06, 0.07, 0.11), true, Color(0, 0, 0, 0))
	# THE MODEL, gated at the MOUNT. `works` and `origin` hang the formula exactly
	# where it has always hung; below that rung the plate is built and released
	# without ever being parented, so not one descendant of this node moves on the
	# legacy path. The gate sits here rather than around the make_tag call above so
	# that call — and its Σ / ₂ escape spellings — stays untouched.
	if _formula_label and _rung() >= 3:
		_formula_label.position = Vector3(0, panel_size.y / 2.0 - 0.10, 0.003)
		add_child(_formula_label)
	elif _formula_label:
		_formula_label.free()
		_formula_label = null

	# Entropy value — large, glowing
	_entropy_pos = Vector3(0.06, BAR_REGION_BOTTOM + BAR_REGION_HEIGHT + 0.035, 0.003)
	_rebuild_entropy_board("H = 0.000")

	# Max entropy label
	var max_h := log(num_symbols) / log(2.0)
	_max_label = BakedText.make_tag(
		"max = %.2f bits (%d symbols)" % [max_h, num_symbols],
		Color(0.5, 0.6, 0.75), 0.028,
		Color(0.05, 0.06, 0.09), true, Color(0, 0, 0, 0))
	# THE CEILING. log₂(N) is what the reading is measured against, so it belongs to
	# the ruler and travels with the gauge at `tally`. Gated at the mount, same as
	# the formula above.
	if _max_label and _rung() >= 1:
		_max_label.position = Vector3(0, BAR_REGION_BOTTOM - 0.045, 0.003)
		add_child(_max_label)
	elif _max_label:
		_max_label.free()
		_max_label = null

	# Sequence sample board (rebuilt on runtime updates)
	_sequence_pos = Vector3(0, -panel_size.y / 2.0 + 0.03, 0.003)

	# ORIGIN, appended LAST so every position above is untouched at every other
	# rung. `works` falls through and adds nothing at all.
	if _rung() >= 4:
		_build_origin_strip()


## ORIGIN — a small strip under the title naming the stream this reading came
## from: which generator, what seed, how many symbols. The number on the wall
## stops being a fact about randomness and becomes a fact about ONE configured
## source, sampled once, at a size somebody chose.
func _build_origin_strip() -> void:
	# LEFT MARGIN, deliberately. The centre column at this height is already taken
	# — formula at y+0.15, the big glowing H at y+0.095 offset to x = +0.06 — so
	# the strip stacks down the free left margin (x = -0.235, clear of the H's left
	# edge at about -0.09 and inside the panel's own at -0.35). Three short rows
	# rather than one long one for the same reason.
	var rows: Array = [
		"SRC PRNG" if not contrast else "SRC PRNG p∝2⁻ᵏ",
		"SEED %d" % (_effective_seed() if not contrast else _contrast_seed),
		"N = %d" % sequence_length,
	]
	for i in range(rows.size()):
		var row: Node3D = BakedText.make_tag(
			str(rows[i]), Color(0.82, 0.74, 0.44), 0.020,
			Color(0.08, 0.075, 0.05), true, Color(0.86, 0.72, 0.20))
		if row:
			row.position = Vector3(-0.235, panel_size.y / 2.0 - 0.105 - float(i) * 0.030, 0.003)
			add_child(row)
			_origin_rows.append(row)
			if i == 0:
				_origin_label = row


## The ledger names a second source on the `origin` rows: free them and build them
## again for the sample now on the wall. Nothing at any other rung.
func _refresh_origin_strip() -> void:
	if _rung() < 4:
		return
	for r in _origin_rows:
		if is_instance_valid(r):
			r.queue_free()
	_origin_rows.clear()
	_origin_label = null
	_build_origin_strip()
	if stand == "ledger":
		for r in _origin_rows:
			r.position.y += LIFT


## Rebuild the entropy value board (baked text can't be edited in place).
func _rebuild_entropy_board(text: String) -> void:
	if _entropy_label and is_instance_valid(_entropy_label):
		_entropy_label.queue_free()
	_entropy_label = BakedText.make_tag(
		text, ENTROPY_COLOR, 0.06,
		Color(0.09, 0.09, 0.05), true, Color(0.86, 0.72, 0.20))
	if _entropy_label:
		_entropy_label.position = _entropy_pos
		add_child(_entropy_label)


## Rebuild the sequence-sample board with fresh text.
func _rebuild_sequence_board(text: String) -> void:
	if _sequence_label and is_instance_valid(_sequence_label):
		_sequence_label.queue_free()
	if text.is_empty():
		_sequence_label = null
		return
	_sequence_label = BakedText.make_tag(
		text, SEQUENCE_COLOR, 0.02,
		Color(0.05, 0.06, 0.08), true, Color(0, 0, 0, 0))
	if _sequence_label:
		_sequence_label.position = _sequence_pos
		add_child(_sequence_label)


func _run_measurement() -> void:
	# Generate random sequence
	var sequence: Array[int] = []
	for i in range(sequence_length):
		sequence.append(_rng.randi_range(0, num_symbols - 1))
	_measure(sequence)


## Measure ONE sequence: the counts, H, the boards. The shipped path draws its own
## sequence above and arrives here with it; the ledger arrives with a contrast
## sample or a probe's. Everything below is the measurement exactly as it shipped.
func _measure(sequence: Array[int]) -> void:
	_sequence = sequence

	# Compute symbol frequencies
	var counts: Array[int] = []
	counts.resize(num_symbols)
	counts.fill(0)
	for s in sequence:
		counts[s] += 1

	# Compute Shannon entropy
	var entropy: float = 0.0
	for c in counts:
		if c > 0:
			var p: float = float(c) / float(sequence_length)
			entropy -= p * (log(p) / log(2.0))

	var max_h: float = log(num_symbols) / log(2.0)
	var frac: float = entropy / max_h if max_h > 0.0 else 0.0
	_counts = counts
	_entropy = entropy

	# Update entropy value board (rebuild baked text)
	_rebuild_entropy_board("H = %.3f bits" % entropy)

	# Update gauge bar. NULL-GUARDED: at `oracle` the whole ruler was never built,
	# so there is no fill bar to move. Everything above this line — the draws, the
	# counts, H itself — has already happened and is identical at every rung.
	if _bar_mesh != null and _bar_material != null:
		var bar_width: float = frac * BAR_REGION_WIDTH
		var bar_quad := _bar_mesh.mesh as QuadMesh
		bar_quad.size.x = max(0.005, bar_width)
		_bar_mesh.position.x = BAR_REGION_LEFT + bar_width / 2.0

		var bar_color: Color = bar_color_low.lerp(bar_color_high, frac)
		_bar_material.albedo_color = bar_color
		_bar_material.emission = bar_color

	# Update frequency bars
	var max_count: int = 0
	for c in counts:
		if c > max_count:
			max_count = c

	# SIZE-GUARDED for the same reason: `oracle` builds no histogram, so the array
	# is empty and range(num_symbols) would walk off the end of it.
	if _freq_bars.size() >= num_symbols:
		for i in range(num_symbols):
			var height: float = (float(counts[i]) / float(max_count)) * FREQ_BAR_HEIGHT if max_count > 0 else 0.0
			height = max(0.002, height)
			var bar_q := _freq_bars[i].mesh as QuadMesh
			bar_q.size.y = height
			_freq_bars[i].position.y = FREQ_REGION_BOTTOM + height / 2.0

	# ORIGIN — set the declared law to its heights. For the shipped uniform source
	# sequence_length / num_symbols is what it promises each symbol, on the same
	# scale the sample is drawn on, so the ghosts form a single flat line across the
	# histogram and every live bar reads as an excess or a shortfall against it.
	# Under the ledger's CONTRAST the active law is p(k) ∝ 2⁻ᵏ and the ghosts are its
	# expected counts, a descending staircase (Astra's review, 2026-09-11: the ghosts
	# had kept the uniform expectation while the strip named the concentrated law).
	if _expected_bars.size() >= num_symbols and max_count > 0:
		var expected_k: Array[float] = expected_counts()
		for i in range(num_symbols):
			var gh: float = clampf(expected_k[i] / float(max_count), 0.0, 1.0) * FREQ_BAR_HEIGHT
			gh = max(0.002, gh)
			var gq := _expected_bars[i].mesh as QuadMesh
			gq.size.y = gh
			_expected_bars[i].position.y = FREQ_REGION_BOTTOM + gh / 2.0

	# Show a sample of the sequence.
	# THE PER-TRIAL RECORD. Forty symbols exactly as drawn — the strip the
	# histogram is a claim ABOUT, and the one thing on this panel a visitor can
	# spot-check by hand. It arrives at `ledger`; below it the meter reports an
	# aggregate of a sample it never shows you.
	if _rung() < 2:
		_strip_text = ""
		_rebuild_sequence_board("")
		_after_measure()
		return
	var sample_str := ""
	var show_count := mini(40, sequence_length)
	for i in range(show_count):
		sample_str += str(sequence[i])
		if i < show_count - 1:
			sample_str += " "
	if sequence_length > show_count:
		sample_str += " ..."
	_strip_text = sample_str
	_rebuild_sequence_board(sample_str)
	_after_measure()


## Under the ledger the boards were just rebuilt at the origin's height: lift them,
## recolour the ribbon and print the readout. Nothing on the default path.
func _after_measure() -> void:
	if stand != "ledger" or _staging_root == null:
		return
	if _entropy_label != null and _entropy_label.position.y < LIFT * 0.5:
		_entropy_label.position.y += LIFT
	if _sequence_label != null and _sequence_label.position.y < LIFT * 0.5:
		_sequence_label.position.y += LIFT
	# _measure places every bar and ghost at FREQ_REGION_BOTTOM + h/2 in the shipped frame
	# (about -0.13 m): after the first measure they were lifted with the panel, after any
	# later one — CONTRAST, a probe's measure() — they had dropped into the desk (seen in
	# the origin + contrast capture, 2026-09-11 15:12). Lift them again.
	for b in _freq_bars:
		if is_instance_valid(b) and b.position.y < LIFT * 0.5:
			b.position.y += LIFT
	for g in _expected_bars:
		if is_instance_valid(g) and g.position.y < LIFT * 0.5:
			g.position.y += LIFT
	_lay_strip_rows()
	_print_tags()
	_refresh_ribbon()
	_update_readout()


## READABLE FROM STANDING (Astra's review, 2026-09-11: the upper panel's labels washed
## out in the standing view). The baked tags are dark glass plates with a lit bezel
## and a textured face, all shaded — under the museum's light their specular turns the
## plates pale and the text faint. Under the ledger every tag's meshes are drawn
## unshaded: the plates stay dark, the text keeps its colour. Local to the staging;
## the shipped look is untouched.
func _print_tags() -> void:
	for c in get_children():
		if c == _staging_root or not (c is Node3D) or c.name != "Tag":
			continue
		for m in c.get_children():
			var mi: MeshInstance3D = m as MeshInstance3D
			if mi == null:
				continue
			var mat: Material = mi.material_override
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
				var um: BaseMaterial3D = (mat as BaseMaterial3D).duplicate()
				um.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mi.material_override = um


## The shipped strip is one row of forty symbols, 1.1 m wide at its 2 cm type —
## wider than the panel. Under the ledger the same forty are laid in two rows of
## twenty at 2.6 cm, inside the panel's width, at the panel's foot.
var _strip_rows: Array[Node3D] = []

func _lay_strip_rows() -> void:
	for r in _strip_rows:
		if is_instance_valid(r):
			r.queue_free()
	_strip_rows.clear()
	if _sequence_label == null or _strip_text.is_empty():
		return
	_sequence_label.visible = false
	var syms: Array = []
	for tok in _strip_text.replace(" ...", "").split(" "):
		if tok != "":
			syms.append(tok)
	var half: int = int(ceil(float(syms.size()) / 2.0))
	var rows: Array = [" ".join(syms.slice(0, half)), " ".join(syms.slice(half, syms.size()))]
	for i in range(rows.size()):
		if str(rows[i]).is_empty():
			continue
		var row: Node3D = BakedText.make_tag(str(rows[i]), SEQUENCE_COLOR, 0.026, Color(0.05, 0.06, 0.08), true, Color(0, 0, 0, 0))
		if row:
			row.name = "Tag"
			row.position = Vector3(0, LIFT - panel_size.y / 2.0 + 0.055 - float(i) * 0.032, 0.003)
			add_child(row)
			_strip_rows.append(row)


## The LEDGER panel's cream face and the push buttons' bright caps bloom under the
## museum's light (the review's "very bright button face"): toned to a matte mid grey,
## the labels' off-white plates left as they are.
func _tone_panel() -> void:
	if _panel == null:
		return
	for mi in _panel.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		var mat: Material = m.material_override
		if mat == null and m.mesh != null and m.get_surface_override_material_count() > 0:
			mat = m.get_surface_override_material(0)
		if not (mat is StandardMaterial3D):
			continue
		var sm: StandardMaterial3D = mat
		var lum: float = (sm.albedo_color.r + sm.albedo_color.g + sm.albedo_color.b) / 3.0
		if lum < 0.75 or sm.albedo_texture != null:
			continue
		var tm: StandardMaterial3D = sm.duplicate()
		tm.albedo_color = sm.albedo_color * 0.55
		tm.albedo_color.a = 1.0
		tm.emission_energy_multiplier = 0.0
		tm.roughness = 0.9
		if m.material_override != null:
			m.material_override = tm
		else:
			m.set_surface_override_material(0, tm)


func _symbol_color(index: int) -> Color:
	var hue: float = float(index) / float(num_symbols)
	return Color.from_hsv(hue, 0.6, 0.8)


## Grid system integration.
##
## LATENT BUG PAID (2026-08-02): this method set num_symbols, sequence_length and
## the seed and then stopped. All three decide GEOMETRY that _ready has already
## built — the histogram has num_symbols bars in it and the ceiling label has the
## number printed on it — and the grid calls this AFTER add_child, so every
## `#num_symbols:` token a map ever wrote changed three variables and not one
## pixel. The capture harness applies DNA through this same method
## (commons/testing/capture_artifact_config.gd:108), so an axis that does not
## rebuild here is an axis that cannot be photographed. It rebuilds now.
##
## THE GUARD IS LOAD-BEARING. curation_station.gd calls
## apply_grid_config({"emissive": false}) on everything it curates, one line after
## it has hidden labels and darkened modulates; that dict carries none of these
## keys, and an unconditional rebuild would throw the curator's framing away.
## Nothing changed means touch nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("disclosure"):
		# Falls back to the LEGACY rung, never to silence: a typo must not quietly
		# seal a meter seven rooms expect open.
		var want: String = Disclosure.disclosure_name(str(config_data["disclosure"]))
		if want != disclosure:
			disclosure = want
			changed = true
	if config_data.has("num_symbols"):
		var n: int = int(str(config_data["num_symbols"]))
		if n != num_symbols:
			num_symbols = n
			changed = true
	if config_data.has("sequence_length"):
		var sl: int = int(str(config_data["sequence_length"]))
		if sl != sequence_length:
			sequence_length = sl
			changed = true
	if config_data.has("stream_seed"):
		var ss: int = int(str(config_data["stream_seed"]))
		if ss != stream_seed:
			stream_seed = ss
			changed = true
	if config_data.has("seed"):
		# The legacy key. It used to write straight onto the generator; it now goes
		# through stream_seed so the `origin` strip and the rebuild see the same
		# number the stream does.
		var lg: int = int(str(config_data["seed"]))
		if lg != stream_seed:
			stream_seed = lg
			changed = true
	if config_data.has("stand"):
		var s: String = str(config_data["stand"]).strip_edges().to_lower()
		var s2: String = "ledger" if s in ["ledger", "desk", "bench", "table", "stand"] else "none"
		if s2 != stand:
			stand = s2
			changed = true

	if not changed:
		return
	if not _built:
		return
	_rebuild_now()


## Tear down what this script built and build it again, INLINE. No call_deferred:
## a deferred rebuild leaves the node empty for a frame, and _auto_ground_artifact
## — which runs later in the same deferred queue — would measure a zero AABB and
## leave the panel ungrounded. Every child of this node is script-built, so
## clearing them all is exactly the teardown. The ledger's staging survives a
## rebuild: it holds the ribbon's state, and the boards are lifted onto it again.
func _rebuild_now() -> void:
	for c in get_children():
		if c == _staging_root:
			continue
		remove_child(c)          # leaves the tree synchronously, no double render
		c.queue_free()
	# Every cached ref points at a freed node now. The rebuilt panel repopulates
	# them; the guards in _run_measurement read them, so they must not be stale.
	_freq_bars.clear()
	_freq_labels.clear()
	_expected_bars.clear()
	_origin_rows.clear()
	_strip_rows.clear()
	_panel_mesh = null
	_bar_mesh = null
	_bar_material = null
	_entropy_label = null
	_formula_label = null
	_title_label = null
	_max_label = null
	_sequence_label = null
	_origin_label = null
	_build_all()


# ═════════════════════════════════════════════════════════════════════
# THE LEDGER — the staging (stand:ledger), its ribbon, panel and readout
# ═════════════════════════════════════════════════════════════════════

func _apply_stand() -> void:
	if stand == "ledger":
		if _sample_uniform.is_empty():
			_sample_uniform = _sequence.duplicate()
			_draw_contrast_sample()
		if _staging_root == null:
			_build_ledger()
		_lift_boards()
		if contrast:
			_measure(_sample_contrast)
		else:
			_refresh_ribbon()
			_update_readout()
	elif _staging_root != null:
		_teardown_ledger()


## Every script-built child of the gauge, up onto the post. Skips the staging and
## anything already lifted (the boards _measure rebuilds are lifted there).
func _lift_boards() -> void:
	for c in get_children():
		if c == _staging_root:
			continue
		var n: Node3D = c as Node3D
		if n != null and n.position.y < LIFT * 0.5:
			n.position.y += LIFT


## The second sample: the same alphabet, the same N, its own seeded generator, a
## concentrated law p(k) ∝ 2⁻ᵏ — symbol 0 half the draws, symbol 1 a quarter, and
## so on. Drawn once; CONTRAST measures it and measures the first sample again.
func _draw_contrast_sample() -> void:
	_contrast_seed = _effective_seed() + 1
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = _contrast_seed
	var weights: Array[float] = _contrast_weights()
	var total: float = 0.0
	for w in weights:
		total += w
	_sample_contrast.clear()
	for i in range(sequence_length):
		var u: float = rng2.randf() * total
		var acc: float = 0.0
		var sym: int = num_symbols - 1
		for k in range(num_symbols):
			acc += weights[k]
			if u < acc:
				sym = k
				break
		_sample_contrast.append(sym)


## The concentrated law's weights, 2⁻ᵏ, before normalisation — one table for the draw,
## the probabilities and the expected counts.
func _contrast_weights() -> Array[float]:
	var weights: Array[float] = []
	for k in range(num_symbols):
		weights.append(pow(2.0, -float(k)))
	return weights


## The ACTIVE source's normalised probabilities: 1/N each for the shipped uniform
## source, 2⁻ᵏ / Σ 2⁻ᵏ under CONTRAST. What the `origin` ghosts and the readout's
## law line are drawn from.
func active_probabilities() -> Array[float]:
	var out: Array[float] = []
	if contrast:
		var weights: Array[float] = _contrast_weights()
		var total: float = 0.0
		for w in weights:
			total += w
		for w in weights:
			out.append(w / total)
	else:
		for k in range(num_symbols):
			out.append(1.0 / float(num_symbols))
	return out


## The counts the active law expects of a sample of sequence_length draws.
func expected_counts() -> Array[float]:
	var out: Array[float] = []
	for pk in active_probabilities():
		out.append(pk * float(sequence_length))
	return out


## The heights the ten ghost bars are drawn at (metres), empty below `origin`.
func ghost_heights() -> Array[float]:
	var out: Array[float] = []
	for g in _expected_bars:
		if is_instance_valid(g) and g.mesh is QuadMesh:
			out.append((g.mesh as QuadMesh).size.y)
	return out


func _build_ledger() -> void:
	_staging_root = Node3D.new()
	_staging_root.name = "Staging"
	add_child(_staging_root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.16, 0.17)
	dark.roughness = 0.8
	# the post the gauge hangs on, from the deck to the panel's lower edge
	var post_h: float = LIFT - panel_size.y * 0.5
	_box("Post", Vector3(0.0, post_h * 0.5, -0.03), Vector3(0.06, post_h, 0.06), dark, false)
	# the desk: a solid support the walker meets and a hand rests on
	_box("Desk", Vector3(0.0, DESK_H * 0.5, DESK_Z), Vector3(DESK_W, DESK_H, DESK_D), dark, true)
	# the caption on the desk's front face
	var cap := Label3D.new()
	cap.name = "Caption"
	cap.text = "the %d draws the gauge counted, in the order drawn\nSORT groups them by symbol · the bars and H do not move" % sequence_length
	cap.pixel_size = 0.0012
	cap.font_size = 16
	cap.outline_size = 0
	cap.modulate = Color(0.75, 0.8, 0.85)
	cap.position = Vector3(0.0, 0.50, DESK_Z + DESK_D * 0.5 + 0.011)
	_staging_root.add_child(cap)
	_build_ribbon()
	_build_ledger_panel()
	_build_readout()


func _box(box_name: String, at: Vector3, size: Vector3, mat: Material, solid: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = box_name
	node.position = at
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	node.add_child(mi)
	if solid:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		node.add_child(col)
	_staging_root.add_child(node)
	return node


## One tile per draw, standing on the desk, coloured as the histogram colours its
## symbol. A thin pale mark under the first forty says which of them the panel's
## strip shows; it goes when the tiles are sorted, because those forty scatter.
func _build_ribbon() -> void:
	_ribbon = MultiMeshInstance3D.new()
	_ribbon.name = "Ribbon"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = TILE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	box.material = mat
	mm.mesh = box
	mm.instance_count = sequence_length
	_ribbon.multimesh = mm
	_ribbon.position = Vector3(0.0, DESK_H + TILE.y * 0.5, RIBBON_Z)
	_staging_root.add_child(_ribbon)
	_strip_mark = MeshInstance3D.new()
	_strip_mark.name = "StripMark"
	var mk := BoxMesh.new()
	var pitch: float = RIBBON_W / float(sequence_length)
	# a pale bar lying in FRONT of the first forty tiles (a line under them was hidden by them)
	mk.size = Vector3(pitch * float(mini(40, sequence_length)), 0.008, 0.012)
	_strip_mark.mesh = mk
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.92, 0.93, 0.96)
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_strip_mark.material_override = mmat
	_strip_mark.position = Vector3(-RIBBON_W * 0.5 + mk.size.x * 0.5, DESK_H + 0.004, RIBBON_Z + TILE.z * 0.5 + 0.012)
	_staging_root.add_child(_strip_mark)
	# the visual pass of 12 September: the ribbon's two hundred tiles are a thin strip from
	# the approach, so the first forty stand again on the desk's FRONT face at four times the
	# size, as drawn and staying as drawn through SORT — the same sample, the same colours,
	# labelled as the excerpt it is
	_excerpt = MultiMeshInstance3D.new()
	_excerpt.name = "Excerpt"
	var em := MultiMesh.new()
	em.transform_format = MultiMesh.TRANSFORM_3D
	em.use_colors = true
	var ebox := BoxMesh.new()
	ebox.size = Vector3(0.026, 0.10, 0.012)
	var emat := StandardMaterial3D.new()
	emat.vertex_color_use_as_albedo = true
	emat.roughness = 0.6
	ebox.material = emat
	em.mesh = ebox
	em.instance_count = mini(40, sequence_length)
	var epitch: float = 0.032
	for i in range(em.instance_count):
		em.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(-1.08 + epitch * (float(i) + 0.5), 0.0, 0.0)))
	_excerpt.multimesh = em
	_excerpt.position = Vector3(0.0, 0.80, DESK_Z + DESK_D * 0.5 + 0.008)
	_staging_root.add_child(_excerpt)
	var ecap := Label3D.new()
	ecap.name = "ExcerptCaption"
	ecap.text = "the first forty draws · ×4 · as drawn (they stay while the ribbon sorts)"
	ecap.pixel_size = 0.0012
	ecap.font_size = 12
	ecap.outline_size = 0
	ecap.modulate = Color(0.86, 0.94, 1.0)
	ecap.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ecap.position = Vector3(-1.08, 0.715, DESK_Z + DESK_D * 0.5 + 0.012)
	_staging_root.add_child(ecap)


## Where tile i stands as drawn, and where it stands in the sorted copy.
func _tile_x_drawn(i: int) -> float:
	var pitch: float = RIBBON_W / float(sequence_length)
	return -RIBBON_W * 0.5 + pitch * (float(i) + 0.5)

func _tile_x_sorted(j: int, block: int) -> float:
	# the same pitch, a small gap before every block after the first
	var gap: float = 0.006
	var pitch: float = (RIBBON_W - gap * float(num_symbols - 1)) / float(sequence_length)
	return -RIBBON_W * 0.5 + pitch * (float(j) + 0.5) + gap * float(block)


## Colour every tile for the sample on the wall, compute the stable sort of a copy
## (each tile's place in the sorted order) and place the tiles at the present
## sort position.
func _refresh_ribbon() -> void:
	if _ribbon == null or _sequence.size() != sequence_length:
		return
	var mm: MultiMesh = _ribbon.multimesh
	_sorted_index.resize(sequence_length)
	# a stable sort by symbol: for each symbol in order, its tiles in draw order
	var j: int = 0
	for sym in range(num_symbols):
		for i in range(sequence_length):
			if _sequence[i] == sym:
				_sorted_index[i] = j
				j += 1
	for i in range(sequence_length):
		mm.set_instance_color(i, _symbol_color(_sequence[i]))
	if _excerpt != null and is_instance_valid(_excerpt):
		var em: MultiMesh = _excerpt.multimesh
		for i in range(mini(em.instance_count, sequence_length)):
			em.set_instance_color(i, _symbol_color(_sequence[i]))
	_place_tiles(_sort_t)


func _place_tiles(t: float) -> void:
	if _ribbon == null:
		return
	var mm: MultiMesh = _ribbon.multimesh
	for i in range(sequence_length):
		var xd: float = _tile_x_drawn(i)
		var xs: float = _tile_x_sorted(_sorted_index[i], _sequence[i])
		var lift: float = sin(t * PI) * 0.03   # the tiles hop over one another on the way
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(lerpf(xd, xs, t), lift, 0.0)))
	if _strip_mark != null:
		_strip_mark.visible = t < 0.01


func _set_sort_t(t: float) -> void:
	_sort_t = t
	_place_tiles(t)


## SORT · CONTRAST · DISCLOSE on the desk's front face, right, at hand height.
func _build_ledger_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_panel = RackTpl.create_panel("LEDGER", [
		[{"type": "button", "label": "SORT"}, {"type": "button", "label": "CONTRAST"}, {"type": "button", "label": "DISCLOSE"}],
	])
	_panel.name = "Panel"
	# the panel's button areas are hand targets, not the installation's footprint
	_panel.set_meta("em_local_instrument", true)
	# on the desk's FRONT FACE, at hand height: the desk top is the ribbon's alone
	_panel.position = Vector3(0.78, 0.74, DESK_Z + DESK_D * 0.5 + 0.012)
	_staging_root.add_child(_panel)
	_tone_panel()
	var actions := {"Btn_0": func(): toggle_sort(), "Btn_1": func(): toggle_contrast(), "Btn_2": func(): step_disclosure()}
	for btn_name in actions.keys():
		var btn: Node = _panel.find_child(btn_name, true, false)
		if btn == null:
			continue
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			var action: Callable = actions[btn_name]
			area.button_pressed.connect(func(_b): action.call())


## Five lines on a dark plate on the desk's front face, left: the sample and its source,
## the counts and their sum, H and the ceiling, the sorted copy against the
## reading, and what the present rung shows.
func _build_readout() -> void:
	_readout_case = Node3D.new()
	_readout_case.name = "ReadoutCase"
	_readout_case.set_meta("em_local_instrument", true)
	# on the desk's FRONT FACE, read from above; nothing stands on the top but the ribbon
	_readout_case.position = Vector3(-0.55, 0.72, DESK_Z + DESK_D * 0.5 + 0.012)
	_staging_root.add_child(_readout_case)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.13, 0.14)
	mat.roughness = 0.75
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(0.84, 0.21, 0.02)
	plate.mesh = box
	plate.material_override = mat
	_readout_case.add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.0015
	_readout.font_size = 18
	_readout.outline_size = 0
	_readout.modulate = Color(0.85, 0.95, 1.0)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.position = Vector3(-0.40, 0.0, 0.012)
	_readout_case.add_child(_readout)


func _teardown_ledger() -> void:
	if is_instance_valid(_staging_root):
		_staging_root.queue_free()
	_staging_root = null
	_excerpt = null
	_panel = null
	_readout_case = null
	_readout = null
	_ribbon = null
	_strip_mark = null
	sorted_view = false
	_sort_t = 0.0
	if contrast:
		contrast = false
		_source_name = "uniform"


# ── the readout's arithmetic ──

## The measurement's own loop, over any counts: -Σ p log₂ p with the zero-count
## terms omitted, exactly as _measure computes it.
static func entropy_of(counts: Array, n: int) -> float:
	var entropy: float = 0.0
	for c in counts:
		if int(c) > 0:
			var p: float = float(c) / float(n)
			entropy -= p * (log(p) / log(2.0))
	return entropy

static func counts_of(sequence: Array, symbols: int) -> Array[int]:
	var counts: Array[int] = []
	counts.resize(symbols)
	counts.fill(0)
	for s in sequence:
		counts[int(s)] += 1
	return counts

func max_entropy() -> float:
	return log(num_symbols) / log(2.0)

## The sorted copy — a stable sort of the sample — and how many tiles it moves.
func sorted_copy() -> Array[int]:
	var out: Array[int] = []
	for sym in range(num_symbols):
		for i in range(_sequence.size()):
			if _sequence[i] == sym:
				out.append(sym)
	return out

func tiles_moved() -> int:
	var moved: int = 0
	for i in range(_sorted_index.size()):
		if _sorted_index[i] != i:
			moved += 1
	return moved

static func _fmt_counts(c: Array) -> String:
	var parts: Array[String] = []
	for v in c:
		parts.append(str(int(v)))
	return " ".join(parts)

func _rung_words() -> String:
	match _rung():
		0: return "oracle · the number alone"
		1: return "tally · bars and the ceiling"
		2: return "ledger · the first forty draws shown"
		3: return "works · the formula shown"
		_: return "origin · the source and its seed shown"

func _update_readout() -> void:
	if _readout == null:
		return
	var sum: int = 0
	for c in _counts:
		sum += c
	var sc: Array[int] = sorted_copy()
	var h_sorted: float = entropy_of(counts_of(sc, num_symbols), sequence_length)
	var src: String = ("concentrated p∝2⁻ᵏ · seed %d" % _contrast_seed) if contrast else ("uniform · seed %d" % _effective_seed())
	var law: String = ""
	if _rung() >= 4:
		var parts: Array[String] = []
		for e in expected_counts():
			parts.append("%.1f" % e)
		law = ("\nlaw uniform · expected %.1f each" % (float(sequence_length) / float(num_symbols))) if not contrast else ("\nlaw p∝2⁻ᵏ · expected " + " ".join(parts))
	_readout.text = "N %d · %d symbols · %s\ncounts %s · sum %d\nH %.3f bits · max log2(%d) = %.3f\n%s\ndisclosure %s%s" % [
		sequence_length, num_symbols, src,
		_fmt_counts(_counts), sum,
		_entropy, num_symbols, max_entropy(),
		("sorted copy: H %.3f · %s · %d of %d tiles moved" % [h_sorted, "equal" if absf(h_sorted - _entropy) < 0.0000005 else "differs", tiles_moved(), sequence_length]) if sorted_view else "as drawn · the strip shows the first %d" % mini(40, sequence_length),
		_rung_words(), law]


# ── the panel's actions, and the API probes read ──

## Group the same tiles by symbol (a stable sort of a copy), or lay them out as
## drawn again. The sample, the counts, the histogram and H are not touched.
func set_sorted(on: bool) -> void:
	sorted_view = on
	if _sort_tween != null and _sort_tween.is_valid():
		_sort_tween.kill()
	if _ribbon != null:
		_sort_tween = create_tween()
		_sort_tween.tween_method(_set_sort_t, _sort_t, 1.0 if on else 0.0, SORT_SECONDS)
	_update_readout()

func toggle_sort() -> void:
	set_sorted(not sorted_view)

## Measure the concentrated sample (the same alphabet, the same N) or the first
## sample again. The ribbon recolours; the sort state is kept.
func set_contrast(on: bool) -> void:
	if stand != "ledger" or _sample_contrast.is_empty():
		return
	contrast = on
	_source_name = "concentrated" if on else "uniform"
	_measure(_sample_contrast if on else _sample_uniform)
	_refresh_origin_strip()
	_update_readout()

func toggle_contrast() -> void:
	set_contrast(not contrast)

## Measure a given sequence of sequence_length symbols in 0 … num_symbols-1 — for
## probes and for anything that wants the gauge's reading on its own draws.
func measure(sequence: Array) -> bool:
	if sequence.size() != sequence_length:
		return false
	var seq: Array[int] = []
	for s in sequence:
		var v: int = int(s)
		if v < 0 or v >= num_symbols:
			return false
		seq.append(v)
	_measure(seq)
	return true

func get_sequence() -> Array[int]:
	return _sequence.duplicate()

func get_counts() -> Array[int]:
	return _counts.duplicate()

func get_entropy() -> float:
	return _entropy

func get_strip_text() -> String:
	return _strip_text

## The next rung up the ladder, wrapping from origin to oracle: the meter rebuilds
## its panel through apply_grid_config, the staging stays.
func set_disclosure(rung: String) -> void:
	apply_grid_config({"disclosure": rung})

func step_disclosure() -> void:
	var i: int = DISCLOSURES.find(Disclosure.disclosure_name(disclosure))
	set_disclosure(DISCLOSURES[(i + 1) % DISCLOSURES.size()])

## For probes and reviews.
func get_ledger_state() -> Dictionary:
	var sc: Array[int] = sorted_copy()
	return {"stand": stand, "disclosure": disclosure, "rung": _rung(), "sorted_view": sorted_view, "sort_t": _sort_t, "contrast": contrast,
		"source": _source_name, "seed": _effective_seed() if not contrast else _contrast_seed, "n": sequence_length, "symbols": num_symbols,
		"counts": _counts.duplicate(), "entropy": _entropy, "max": max_entropy(),
		"sorted_entropy": entropy_of(counts_of(sc, num_symbols), sequence_length), "sorted_counts": counts_of(sc, num_symbols),
		"tiles_moved": tiles_moved(), "strip": _strip_text, "ribbon_first_40": _sequence.slice(0, mini(40, _sequence.size())),
		"probabilities": active_probabilities(), "expected_counts": expected_counts(), "ghost_heights": ghost_heights()}
