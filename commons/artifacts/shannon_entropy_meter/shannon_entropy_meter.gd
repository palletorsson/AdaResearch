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


func _ready() -> void:
	_build_all()


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
		"SRC PRNG",
		"SEED %d" % _effective_seed(),
		"N = %d" % sequence_length,
	]
	for i in range(rows.size()):
		var row: Node3D = BakedText.make_tag(
			str(rows[i]), Color(0.82, 0.74, 0.44), 0.020,
			Color(0.08, 0.075, 0.05), true, Color(0.86, 0.72, 0.20))
		if row:
			row.position = Vector3(-0.235, panel_size.y / 2.0 - 0.105 - float(i) * 0.030, 0.003)
			add_child(row)
			if i == 0:
				_origin_label = row


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

	# ORIGIN — set the declared law to its one height. sequence_length / num_symbols
	# is what a uniform source promises each symbol, on the same scale the sample
	# is drawn on, so the ghosts form a single flat line across the histogram and
	# every live bar reads as an excess or a shortfall against it.
	if _expected_bars.size() >= num_symbols and max_count > 0:
		var expected: float = float(sequence_length) / float(num_symbols)
		var gh: float = clampf(expected / float(max_count), 0.0, 1.0) * FREQ_BAR_HEIGHT
		gh = max(0.002, gh)
		for i in range(num_symbols):
			var gq := _expected_bars[i].mesh as QuadMesh
			gq.size.y = gh
			_expected_bars[i].position.y = FREQ_REGION_BOTTOM + gh / 2.0

	# Show a sample of the sequence.
	# THE PER-TRIAL RECORD. Forty symbols exactly as drawn — the strip the
	# histogram is a claim ABOUT, and the one thing on this panel a visitor can
	# spot-check by hand. It arrives at `ledger`; below it the meter reports an
	# aggregate of a sample it never shows you.
	if _rung() < 2:
		_rebuild_sequence_board("")
		return
	var sample_str := ""
	var show_count := mini(40, sequence_length)
	for i in range(show_count):
		sample_str += str(sequence[i])
		if i < show_count - 1:
			sample_str += " "
	if sequence_length > show_count:
		sample_str += " ..."
	_rebuild_sequence_board(sample_str)


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

	if not changed:
		return
	_rebuild_now()


## Tear down what this script built and build it again, INLINE. No call_deferred:
## a deferred rebuild leaves the node empty for a frame, and _auto_ground_artifact
## — which runs later in the same deferred queue — would measure a zero AABB and
## leave the panel ungrounded. Every child of this node is script-built, so
## clearing them all is exactly the teardown.
func _rebuild_now() -> void:
	for c in get_children():
		remove_child(c)          # leaves the tree synchronously, no double render
		c.queue_free()
	# Every cached ref points at a freed node now. The rebuilt panel repopulates
	# them; the guards in _run_measurement read them, so they must not be stale.
	_freq_bars.clear()
	_freq_labels.clear()
	_expected_bars.clear()
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
