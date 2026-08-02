extends Node3D

# TRNG vs PRNG Comparison
# Demonstrates true vs pseudo-random number generation
# Uses MultiMesh for all dynamic visualization (no per-frame CSG creation)

# @identity
# essence: two parallel machines side by side — one harvesting physical noise, one running an algorithm — both pretending to be random
# desire: to expose pseudo-randomness as deterministic theatre, while showing what TRUE randomness actually feels like
# critical_parameter: prng_seed — change it and the entire pseudo-stream is reborn the same way; nothing about the TRNG stream changes. disclosure — how much either side admits about where its numbers came from (oracle | tally | ledger | works | origin)
# triggers: side-by-side bar charts, statistical comparison, entropy histories diverging in real time
# emerges: the visual lie — a PRNG output is indistinguishable from TRNG until you reset the seed and see history repeat; at disclosure:oracle both panels are two rows of bars and nothing on the rig will tell you which one you could replay
# needs: prng_seed[has] entropy_sources[has] statistical_comparison[has] entropy_history[has] vr_seed_dial[missing]
# relationships: pairs with seed_replay_demo (PRNG determinism) and slot_machine (gambler's view of randomness); shares the disclosure ladder with prng_crank_machine and coin_toss
# truth: a pseudo-random number generator is determinism wearing a mask — the seed is the face underneath

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02). The randomness family's ONE axis, adopted:
#
#   disclosure   oracle  <  tally  <  ledger  <  works  <  origin
#
# defined in prng_crank_machine.gd, already shared with coin_toss and
# random_number_book_page_1955. This rig is that ladder staged as a COMPARISON: it
# stands a true source next to a pseudo one and asks you to tell them apart. So
# the axis is not "how much does the machine admit" but "how much does the rig let
# you SEE about either side" — and the point of the low rungs is that with the
# account withheld the two panels are indistinguishable, which is the artifact's
# entire claim rather than a degradation of it.
#
#   oracle  Two rows of output bars, one per panel, in two identical vitrines.
#           No source diagram, no algorithm pipeline, no statistics, no history,
#           no captions. Twenty numbers on the left and twenty on the right, and
#           NOTHING on the rig says one of them can be replayed tomorrow.
#   tally   + the aggregate: the four-test comparison block returns (mean,
#           variance, chi-square, runs), green bars against blue. The statistical
#           alibi — "both are uniform" is a true sentence about a different
#           question, and at this rung it is the only sentence available.
#   ledger  + the per-sample record: the two entropy trails return, fifty
#           segments each, the two histories running side by side over time.
#   works   + the mechanism: the four-source entropy harvest on the left, the
#           five-stage LCG pipeline with its arrows and state sphere on the
#           right, and the two captions that name what each is doing. THE LEGACY
#           RIG, byte for byte — this is the default.
#   origin  + the substrate: a register wall behind the PRNG panel — the seed as
#           thirty-two lit lamps, MSB left, the exact bit pattern the whole right
#           side unrolls from — and, facing it across the rig, the TRNG's empty
#           socket row: thirty-two dark sockets and no lamps, because that side
#           has no seed to show. The asymmetry IS the teaching.
#
# HOW THE RUNGS WITHHOLD: by setting `layers = 0` on the VisualInstance3D, never
# by not simulating. Every sample is still drawn, every statistic still computed,
# every multimesh transform still written at every rung — so the mathematics is
# untouched (it is curriculum) and, just as importantly, the artifact's bounding
# box is identical at all five rungs, which means the capture camera does not move
# between variants and the sweep measures the axis instead of its own framing.
# `visible = false` would have done the first job and not the second.
#
# NOT PROMOTED: the sample rate (0.1 s), the buffer lengths, the frame colours.
# A rate is invisible to a still. prng_seed is not promoted either — it changes
# which numbers, not what is shown about them, and sweeping it would produce five
# tiles of the same rig with different bar heights.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once in prng_crank_machine. Preloaded rather than
## reached through class_name — class_name lookups are not reliable headless and
## every frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

## THE AXIS — how much this rig lets you see about where either stream came from.
## Same five rungs, same order, same spellings as prng_crank_machine and coin_toss.
## `works` is the legacy rig.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum declares.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## PIN. -1 (the default) is today's behaviour exactly: quantum_fluctuation() and
## atmospheric_fluctuation() call the GLOBAL randf(), which Godot seeds from the OS
## at startup, and system_timing_jitter() reads the wall clock — so the TRNG panel,
## the four statistics and both entropy trails are different on every instantiation
## and keep moving for as long as the artifact lives. That is correct for a true
## random source and fatal for evidence: a disclosure sweep would render five
## different rigs and report a confident bite that was entirely noise.
##
## Any value >= 0 seeds the global generator before _ready builds anything and
## replaces the wall clock with a fixed t, so two photographs of this rig can be
## compared. The TRNG side stays statistically true; it just stops being fresh.
## The DNA fixture must set it.
@export var stream_seed: int = -1

var time := 0.0
var sample_timer := 0.0
## Frozen clock, used in place of Time.get_ticks_msec() when stream_seed >= 0.
var _pinned: bool = false

# Random number generators
var prng_seed := 12345
var prng_state := 0
var trng_buffer := []
var prng_buffer := []

# Statistical analysis
var trng_samples := []
var prng_samples := []
var entropy_history := []

@export var show_visual_frames := true
@export var frame_back_color := Color(0.06, 0.08, 0.12, 0.9)
@export var frame_border_color := Color(0.72, 0.8, 0.95, 1.0)
@export var frame_border_thickness := 0.08
@export var frame_depth := 0.03

# ── MultiMesh references ──────────────────────────────────────────────
# TrueRandomGenerator section
var mm_trng_sources: MultiMeshInstance3D      # 4 entropy source "spheres"
var mm_trng_connections: MultiMeshInstance3D   # 4 connection lines
var mm_trng_combiner: MultiMeshInstance3D      # 1 central combiner
var mm_trng_output: MultiMeshInstance3D        # 20 output bars

# PseudoRandomGenerator section
var mm_prng_steps: MultiMeshInstance3D         # 5 algorithm step boxes
var mm_prng_arrows: MultiMeshInstance3D        # 4 arrows between steps
var mm_prng_state: MultiMeshInstance3D         # 1 state display
var mm_prng_output: MultiMeshInstance3D        # 20 output bars

# StatisticalComparison section
var mm_stat_trng_bars: MultiMeshInstance3D     # 4 TRNG stat bars
var mm_stat_prng_bars: MultiMeshInstance3D     # 4 PRNG stat bars
var mm_stat_labels: MultiMeshInstance3D        # 4 label indicators

# EntropyVisualization section
var mm_entropy_trng_sphere: MultiMeshInstance3D  # 1 TRNG entropy sphere
var mm_entropy_prng_sphere: MultiMeshInstance3D  # 1 PRNG entropy sphere
var mm_entropy_trng_history: MultiMeshInstance3D # 50 TRNG history segments
var mm_entropy_prng_history: MultiMeshInstance3D # 50 PRNG history segments

# Instance counts
const ENTROPY_SOURCE_COUNT := 4
const OUTPUT_BAR_COUNT := 20
const PRNG_STEP_COUNT := 5
const PRNG_ARROW_COUNT := 4
const STAT_TEST_COUNT := 4
const ENTROPY_HISTORY_COUNT := 50

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read happens here, before any geometry exists.
	_read_meta_overrides()
	# BEFORE the first draw of any kind. seed() replaces the OS entropy Godot
	# starts the global generator with; at the default (-1) this line does nothing
	# and the stream is exactly what it always was.
	if stream_seed >= 0:
		seed(stream_seed)
	initialize_generators()
	_setup_visual_frames()
	_setup_explanation_labels()
	_setup_all_multimeshes()
	# APPENDED LAST so every node index above is untouched on the legacy path.
	_build_origin_register()
	_apply_disclosure()
	if stream_seed >= 0:
		_prime_pinned()

func _process(delta: float) -> void:
	if _pinned:
		# A pinned rig holds its samples: the buffers, the statistics and the
		# trails were filled once in _ready and stay put, so two frames of this
		# artifact are the same picture. The visualizers below still run — they
		# only READ the buffers — so nothing about the drawing path changes.
		visualize_true_random()
		visualize_pseudo_random()
		show_statistical_comparison()
		demonstrate_entropy_visualization()
		return

	time += delta
	sample_timer += delta

	if sample_timer > 0.1:
		sample_timer = 0.0
		collect_samples()

	visualize_true_random()
	visualize_pseudo_random()
	show_statistical_comparison()
	demonstrate_entropy_visualization()

func initialize_generators() -> void:
	prng_state = prng_seed
	trng_buffer.clear()
	prng_buffer.clear()
	trng_samples.clear()
	prng_samples.clear()

func collect_samples() -> void:
	var trng_sample = simulate_true_random()
	trng_buffer.append(trng_sample)
	trng_samples.append(trng_sample)

	var prng_sample = generate_pseudo_random()
	prng_buffer.append(prng_sample)
	prng_samples.append(prng_sample)

	if trng_buffer.size() > 100:
		trng_buffer.remove_at(0)
	if prng_buffer.size() > 100:
		prng_buffer.remove_at(0)
	if trng_samples.size() > 1000:
		trng_samples.remove_at(0)
	if prng_samples.size() > 1000:
		prng_samples.remove_at(0)

# ── Entropy simulation functions (unchanged) ──────────────────────────

func simulate_true_random() -> float:
	var quantum_noise = quantum_fluctuation()
	var thermal_noise = thermal_fluctuation()
	var atmospheric_noise = atmospheric_fluctuation()
	var timing_jitter = system_timing_jitter()
	var combined_entropy = (quantum_noise + thermal_noise + atmospheric_noise + timing_jitter) / 4.0
	return fmod(combined_entropy * 1000000.0, 1.0)

func quantum_fluctuation() -> float:
	return randf()

func thermal_fluctuation() -> float:
	var thermal_energy = sin(time * 137.3) + cos(time * 241.7) + sin(time * 383.1)
	return fmod(abs(thermal_energy), 1.0)

func atmospheric_fluctuation() -> float:
	return fmod(sin(time * 1000.0 + randf() * 100.0), 1.0)

func system_timing_jitter() -> float:
	if _pinned:
		# The wall clock is the one entropy source a seed cannot reach, so a pinned
		# rig reads its own frozen t instead. Same shape of signal, reproducible.
		return fmod(time * 3.0, 1.0)
	return fmod(Time.get_ticks_msec() * 0.001, 1.0)

func generate_pseudo_random() -> float:
	prng_state = (prng_state * 1664525 + 1013904223) % (2**32)
	return float(prng_state) / float(2**32)

# ── MultiMesh setup ──────────────────────────────────────────────────

func _create_multimesh_instance(parent: Node3D, instance_count: int, mesh: Mesh, nm: String = "") -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	if nm != "":
		mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = instance_count
	mm.visible_instance_count = 0
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi

func _make_box_mesh(sx: float = 1.0, sy: float = 1.0, sz: float = 1.0) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m

func _make_sphere_mesh(radius: float = 0.5) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m

func _setup_all_multimeshes() -> void:
	var trng_container = $TrueRandomGenerator
	var prng_container = $PseudoRandomGenerator
	var stat_container = $StatisticalComparison
	var entropy_container = $EntropyVisualization

	# Use an emissive material on a unit-sphere mesh; colour set per-instance
	var unit_sphere := _make_sphere_mesh(0.5)
	var unit_box := _make_box_mesh(1.0, 1.0, 1.0)

	# We need a material that uses the per-instance colour (vertex colour)
	var base_mat := StandardMaterial3D.new()
	base_mat.vertex_color_use_as_albedo = true
	base_mat.emission_enabled = true
	base_mat.emission = Color(1, 1, 1)
	base_mat.emission_energy_multiplier = 0.5

	var base_mat_transparent := base_mat.duplicate() as StandardMaterial3D
	base_mat_transparent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# -- TrueRandomGenerator --
	var src_sphere := unit_sphere.duplicate() as SphereMesh
	src_sphere.material = base_mat
	mm_trng_sources = _create_multimesh_instance(trng_container, ENTROPY_SOURCE_COUNT, src_sphere, "MMSources")

	var conn_box := _make_box_mesh(0.04, 1.0, 0.04)
	var conn_mat := base_mat_transparent.duplicate() as StandardMaterial3D
	conn_box.material = conn_mat
	mm_trng_connections = _create_multimesh_instance(trng_container, ENTROPY_SOURCE_COUNT, conn_box, "MMConnections")

	var comb_sphere := unit_sphere.duplicate() as SphereMesh
	comb_sphere.material = base_mat.duplicate()
	mm_trng_combiner = _create_multimesh_instance(trng_container, 1, comb_sphere, "MMCombiner")

	var trng_out_box := _make_box_mesh(0.15, 1.0, 0.15)
	trng_out_box.material = base_mat.duplicate()
	mm_trng_output = _create_multimesh_instance(trng_container, OUTPUT_BAR_COUNT, trng_out_box, "MMTrngOutput")

	# -- PseudoRandomGenerator --
	var step_box := _make_box_mesh(1.0, 0.6, 0.6)
	var step_mat := StandardMaterial3D.new()
	step_mat.vertex_color_use_as_albedo = true
	step_mat.metallic = 0.3
	step_mat.roughness = 0.4
	step_box.material = step_mat
	mm_prng_steps = _create_multimesh_instance(prng_container, PRNG_STEP_COUNT, step_box, "MMSteps")

	var arrow_box := _make_box_mesh(0.15, 0.3, 0.15)
	arrow_box.material = base_mat.duplicate()
	mm_prng_arrows = _create_multimesh_instance(prng_container, PRNG_ARROW_COUNT, arrow_box, "MMArrows")

	var state_sphere := unit_sphere.duplicate() as SphereMesh
	state_sphere.material = base_mat.duplicate()
	mm_prng_state = _create_multimesh_instance(prng_container, 1, state_sphere, "MMState")

	var prng_out_box := _make_box_mesh(0.15, 1.0, 0.15)
	prng_out_box.material = base_mat.duplicate()
	mm_prng_output = _create_multimesh_instance(prng_container, OUTPUT_BAR_COUNT, prng_out_box, "MMPrngOutput")

	# -- StatisticalComparison --
	var stat_box := _make_box_mesh(0.4, 1.0, 0.4)
	var stat_trng_mat := StandardMaterial3D.new()
	stat_trng_mat.vertex_color_use_as_albedo = true
	stat_trng_mat.emission_enabled = true
	stat_trng_mat.emission = Color(0.2, 1.0, 0.2)
	stat_trng_mat.emission_energy_multiplier = 0.3
	var stat_trng_box := stat_box.duplicate() as BoxMesh
	stat_trng_box.material = stat_trng_mat
	mm_stat_trng_bars = _create_multimesh_instance(stat_container, STAT_TEST_COUNT, stat_trng_box, "MMStatTrng")

	var stat_prng_mat := StandardMaterial3D.new()
	stat_prng_mat.vertex_color_use_as_albedo = true
	stat_prng_mat.emission_enabled = true
	stat_prng_mat.emission = Color(0.2, 0.2, 1.0)
	stat_prng_mat.emission_energy_multiplier = 0.3
	var stat_prng_box := stat_box.duplicate() as BoxMesh
	stat_prng_box.material = stat_prng_mat
	mm_stat_prng_bars = _create_multimesh_instance(stat_container, STAT_TEST_COUNT, stat_prng_box, "MMStatPrng")

	var label_box := _make_box_mesh(1.5, 0.2, 0.2)
	var label_mat := StandardMaterial3D.new()
	label_mat.vertex_color_use_as_albedo = true
	label_box.material = label_mat
	mm_stat_labels = _create_multimesh_instance(stat_container, STAT_TEST_COUNT, label_box, "MMStatLabels")

	# -- EntropyVisualization --
	var ent_sphere := unit_sphere.duplicate() as SphereMesh
	ent_sphere.material = base_mat_transparent.duplicate()
	mm_entropy_trng_sphere = _create_multimesh_instance(entropy_container, 1, ent_sphere, "MMEntTrngSphere")
	mm_entropy_prng_sphere = _create_multimesh_instance(entropy_container, 1, ent_sphere.duplicate(), "MMEntPrngSphere")

	var hist_box := _make_box_mesh(0.1, 0.04, 0.04)
	hist_box.material = base_mat.duplicate()
	mm_entropy_trng_history = _create_multimesh_instance(entropy_container, ENTROPY_HISTORY_COUNT, hist_box, "MMEntTrngHist")
	var hist_box2 := hist_box.duplicate() as BoxMesh
	hist_box2.material = base_mat.duplicate()
	mm_entropy_prng_history = _create_multimesh_instance(entropy_container, ENTROPY_HISTORY_COUNT, hist_box2, "MMEntPrngHist")

# ── Explanation labels ───────────────────────────────────────────────

func _setup_explanation_labels() -> void:
	var trng_container = $TrueRandomGenerator
	var prng_container = $PseudoRandomGenerator

	# TRNG explanation label
	var trng_label := Label3D.new()
	trng_label.name = "TrngExplanation"
	trng_label.text = "TRUE RANDOM (TRNG)\nUnpredictable — Uses physical entropy\n(thermal noise, radioactive decay,\nquantum fluctuations)\n\nEach number is fundamentally\nunreproducible"
	trng_label.font_size = 48
	trng_label.position = Vector3(0, 3.8, 0.1)
	trng_label.modulate = Color(0.3, 1.0, 0.4)
	trng_label.outline_modulate = Color(0, 0, 0)
	trng_label.outline_size = 8
	trng_label.pixel_size = 0.01
	trng_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trng_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trng_label.set_meta("persistent_frame", true)
	trng_container.add_child(trng_label)

	# PRNG explanation label
	var prng_label := Label3D.new()
	prng_label.name = "PrngExplanation"
	prng_label.text = "PSEUDO-RANDOM (PRNG)\nDeterministic — Uses mathematical formula\n(same seed → same sequence)\n\nLCG: state = (state × 1664525\n+ 1013904223) mod 2³²"
	prng_label.font_size = 48
	prng_label.position = Vector3(0, 3.8, 0.1)
	prng_label.modulate = Color(0.3, 0.6, 1.0)
	prng_label.outline_modulate = Color(0, 0, 0)
	prng_label.outline_size = 8
	prng_label.pixel_size = 0.01
	prng_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prng_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prng_label.set_meta("persistent_frame", true)
	prng_container.add_child(prng_label)

# ── Helper: set a single MultiMesh instance transform + color ────────

func _mm_set(mmi: MultiMeshInstance3D, idx: int, xform: Transform3D, col: Color) -> void:
	mmi.multimesh.set_instance_transform(idx, xform)
	mmi.multimesh.set_instance_color(idx, col)

# ── Visualization (MultiMesh updates only — zero allocations) ────────

func visualize_true_random() -> void:
	# The four source spheres are sized from a FRESH draw every frame, which is
	# correct for a live rig and fatal for a still: four of the sweep's variants
	# would differ by four random radii before the axis said anything. A pinned rig
	# reads the snapshot taken at the end of priming instead.
	var entropy_values: Array = _entropy_snapshot if _pinned else [
		quantum_fluctuation(),
		thermal_fluctuation(),
		atmospheric_fluctuation(),
		system_timing_jitter()
	]

	mm_trng_sources.multimesh.visible_instance_count = ENTROPY_SOURCE_COUNT
	mm_trng_connections.multimesh.visible_instance_count = ENTROPY_SOURCE_COUNT

	for i in range(ENTROPY_SOURCE_COUNT):
		var angle := float(i) / float(ENTROPY_SOURCE_COUNT) * TAU
		var radius_val: float = 0.3 + entropy_values[i] * 0.3
		var pos := Vector3(cos(angle) * 2.0, sin(angle) * 2.0, 0)

		# Source sphere — scale the unit sphere
		var src_xform := Transform3D(Basis().scaled(Vector3.ONE * radius_val * 2.0), pos)
		var hue := float(i) / float(ENTROPY_SOURCE_COUNT)
		var src_color := Color.from_hsv(hue, 0.8, 1.0)
		_mm_set(mm_trng_sources, i, src_xform, src_color)

		# Connection line from source to center
		var mid := pos * 0.5
		var dist := pos.length()
		# Build a transform that places a thin box along source→center
		var dir := -pos.normalized() if pos.length() > 0.001 else Vector3.UP
		var up := Vector3.FORWARD if abs(dir.dot(Vector3.UP)) > 0.98 else Vector3.UP
		var basis := Basis.looking_at(dir, up)
		# The box mesh is 0.04 × 1.0 × 0.04; scale Y to match distance
		var conn_xform := Transform3D(basis.scaled(Vector3(1, dist, 1)), mid)
		_mm_set(mm_trng_connections, i, conn_xform, Color(0.8, 0.8, 0.8, 0.5))

	# Central combiner sphere
	mm_trng_combiner.multimesh.visible_instance_count = 1
	_mm_set(mm_trng_combiner, 0, Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3.ZERO), Color(1, 1, 1))

	# Output bars
	_update_output_bars(mm_trng_output, trng_buffer, Vector3(0, -3, 0), Color.GREEN)

func visualize_pseudo_random() -> void:
	# Algorithm step boxes
	mm_prng_steps.multimesh.visible_instance_count = PRNG_STEP_COUNT
	for i in range(PRNG_STEP_COUNT):
		var pos := Vector3(0, i * 1.0 - 2.0, 0)
		var xform := Transform3D(Basis.IDENTITY, pos)
		_mm_set(mm_prng_steps, i, xform, Color(0.3, 0.7, 1.0))

	# Arrows between steps
	mm_prng_arrows.multimesh.visible_instance_count = PRNG_ARROW_COUNT
	for i in range(PRNG_ARROW_COUNT):
		var pos := Vector3(0, i * 1.0 - 1.5, 0)
		var xform := Transform3D(Basis.IDENTITY, pos)
		_mm_set(mm_prng_arrows, i, xform, Color(1.0, 0.5, 0.0))

	# State display sphere
	mm_prng_state.multimesh.visible_instance_count = 1
	var state_ratio := float(prng_state % 1000) / 1000.0
	var state_color := Color.from_hsv(state_ratio, 0.8, 1.0)
	var state_xform := Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(2, 0, 0))
	_mm_set(mm_prng_state, 0, state_xform, state_color)

	# Output bars
	_update_output_bars(mm_prng_output, prng_buffer, Vector3(0, -3, 0), Color.CYAN)

func _update_output_bars(mmi: MultiMeshInstance3D, buffer: Array, base_pos: Vector3, color: Color) -> void:
	var count := mini(OUTPUT_BAR_COUNT, buffer.size())
	mmi.multimesh.visible_instance_count = count

	for i in range(count):
		var value: float = buffer[buffer.size() - 1 - i]
		var height := value * 2.0 + 0.1
		var pos := base_pos + Vector3(i * 0.2 - 2.0, height * 0.5, 0)
		# Scale Y of the unit box (1.0 tall) to the desired height
		var xform := Transform3D(Basis().scaled(Vector3(1, height, 1)), pos)
		var bar_color := Color(color.r, color.g, color.b, 1.0).lerp(Color.WHITE, value * 0.3)
		_mm_set(mmi, i, xform, bar_color)

func show_statistical_comparison() -> void:
	if trng_samples.size() < 50 or prng_samples.size() < 50:
		mm_stat_trng_bars.multimesh.visible_instance_count = 0
		mm_stat_prng_bars.multimesh.visible_instance_count = 0
		mm_stat_labels.multimesh.visible_instance_count = 0
		return

	var trng_stats := calculate_statistics(trng_samples)
	var prng_stats := calculate_statistics(prng_samples)

	var trng_results := [trng_stats.mean, trng_stats.variance, trng_stats.chi_square, trng_stats.runs_test]
	var prng_results := [prng_stats.mean, prng_stats.variance, prng_stats.chi_square, prng_stats.runs_test]

	mm_stat_trng_bars.multimesh.visible_instance_count = STAT_TEST_COUNT
	mm_stat_prng_bars.multimesh.visible_instance_count = STAT_TEST_COUNT
	mm_stat_labels.multimesh.visible_instance_count = STAT_TEST_COUNT

	for i in range(STAT_TEST_COUNT):
		# TRNG bar
		var trng_h: float = trng_results[i] * 3.0 + 0.1
		var trng_pos := Vector3(i * 2.0 - 3.0, trng_h * 0.5, -0.5)
		var trng_xform := Transform3D(Basis().scaled(Vector3(1, trng_h, 1)), trng_pos)
		_mm_set(mm_stat_trng_bars, i, trng_xform, Color(0.2, 1.0, 0.2))

		# PRNG bar
		var prng_h: float = prng_results[i] * 3.0 + 0.1
		var prng_pos := Vector3(i * 2.0 - 3.0, prng_h * 0.5, 0.5)
		var prng_xform := Transform3D(Basis().scaled(Vector3(1, prng_h, 1)), prng_pos)
		_mm_set(mm_stat_prng_bars, i, prng_xform, Color(0.2, 0.2, 1.0))

		# Label indicator
		var label_pos := Vector3(i * 2.0 - 3.0, -1.0, 0)
		_mm_set(mm_stat_labels, i, Transform3D(Basis.IDENTITY, label_pos), Color(1, 1, 1))

func calculate_statistics(samples: Array) -> Dictionary:
	var stats := {}

	var sum := 0.0
	for sample in samples:
		sum += sample
	stats.mean = sum / samples.size()

	var variance_sum := 0.0
	for sample in samples:
		variance_sum += pow(sample - stats.mean, 2)
	stats.variance = variance_sum / samples.size()

	var bins := [0, 0, 0, 0, 0]
	for sample in samples:
		var bin_index := int(sample * bins.size())
		if bin_index >= bins.size():
			bin_index = bins.size() - 1
		bins[bin_index] += 1

	var expected := float(samples.size()) / bins.size()
	var chi_square := 0.0
	for observed in bins:
		chi_square += pow(observed - expected, 2) / expected
	stats.chi_square = chi_square / 10.0

	var runs := 0
	var above_median := false
	var prev_above_median := false
	for i in range(samples.size()):
		above_median = samples[i] > stats.mean
		if i > 0 and above_median != prev_above_median:
			runs += 1
		prev_above_median = above_median
	stats.runs_test = float(runs) / samples.size()

	return stats

func demonstrate_entropy_visualization() -> void:
	var trng_entropy := calculate_entropy(trng_samples)
	var prng_entropy := calculate_entropy(prng_samples)

	# TRNG entropy sphere
	mm_entropy_trng_sphere.multimesh.visible_instance_count = 1
	var trng_r := trng_entropy + 0.1
	var trng_xform := Transform3D(Basis().scaled(Vector3.ONE * trng_r * 2.0), Vector3(-2, 0, 0))
	_mm_set(mm_entropy_trng_sphere, 0, trng_xform, Color(0.2, 1.0, 0.2, 0.7))

	# PRNG entropy sphere
	mm_entropy_prng_sphere.multimesh.visible_instance_count = 1
	var prng_r := prng_entropy + 0.1
	var prng_xform := Transform3D(Basis().scaled(Vector3.ONE * prng_r * 2.0), Vector3(2, 0, 0))
	_mm_set(mm_entropy_prng_sphere, 0, prng_xform, Color(0.2, 0.2, 1.0, 0.7))

	# Update entropy history. A pinned rig does not extend it: the trail was filled
	# during priming and must not keep growing a flat tail while the sweep settles.
	if not _pinned:
		entropy_history.append({"trng": trng_entropy, "prng": prng_entropy})
		if entropy_history.size() > ENTROPY_HISTORY_COUNT:
			entropy_history.remove_at(0)

	# TRNG history line
	var hist_count := maxi(0, entropy_history.size() - 1)
	mm_entropy_trng_history.multimesh.visible_instance_count = hist_count
	mm_entropy_prng_history.multimesh.visible_instance_count = hist_count

	for i in range(hist_count):
		var hdata: Dictionary = entropy_history[i]
		var x_pos := i * 0.1 - entropy_history.size() * 0.05

		# TRNG history segment
		var trng_seg_pos := Vector3(x_pos, hdata.trng * 2.0 - 3.0, -1.0)
		_mm_set(mm_entropy_trng_history, i, Transform3D(Basis.IDENTITY, trng_seg_pos), Color(0.2, 1.0, 0.2))

		# PRNG history segment
		var prng_seg_pos := Vector3(x_pos, hdata.prng * 2.0 - 3.0, 1.0)
		_mm_set(mm_entropy_prng_history, i, Transform3D(Basis.IDENTITY, prng_seg_pos), Color(0.2, 0.2, 1.0))

func calculate_entropy(samples: Array) -> float:
	if samples.size() < 10:
		return 0.0

	var bins := {}
	var bin_count := 10

	for sample in samples:
		var bin := int(sample * bin_count)
		if bin >= bin_count:
			bin = bin_count - 1
		if bin in bins:
			bins[bin] += 1
		else:
			bins[bin] = 1

	var entropy := 0.0
	var total_samples := samples.size()

	for bin in bins:
		var probability := float(bins[bin]) / total_samples
		if probability > 0:
			entropy -= probability * log(probability) / log(2)

	return entropy / log(bin_count) / log(2)

# ── Visual frames (unchanged — persistent MeshInstance3D) ────────────

func _setup_visual_frames() -> void:
	if not show_visual_frames:
		return
	_create_panel_frame($TrueRandomGenerator, "TrueRandomFrame", Vector3(0, -0.4, -0.18), Vector2(6.4, 6.8))
	_create_panel_frame($PseudoRandomGenerator, "PseudoRandomFrame", Vector3(0, -0.4, -0.18), Vector2(6.0, 6.8))

func _create_panel_frame(parent: Node3D, root_name: String, center: Vector3, panel_size: Vector2) -> void:
	if parent.get_node_or_null(root_name):
		return

	var root := Node3D.new()
	root.name = root_name
	root.set_meta("persistent_frame", true)
	parent.add_child(root)

	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = frame_back_color
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = frame_border_color
	border_mat.emission_enabled = true
	border_mat.emission = frame_border_color * 0.25
	border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var half_w := panel_size.x * 0.5
	var half_h := panel_size.y * 0.5
	var half_t := frame_border_thickness * 0.5

	_add_frame_piece(root, "Back", center, Vector3(panel_size.x, panel_size.y, frame_depth), back_mat)
	_add_frame_piece(root, "Top", center + Vector3(0, half_h - half_t, 0), Vector3(panel_size.x, frame_border_thickness, frame_depth), border_mat)
	_add_frame_piece(root, "Bottom", center + Vector3(0, -half_h + half_t, 0), Vector3(panel_size.x, frame_border_thickness, frame_depth), border_mat)
	_add_frame_piece(root, "Left", center + Vector3(-half_w + half_t, 0, 0), Vector3(frame_border_thickness, panel_size.y, frame_depth), border_mat)
	_add_frame_piece(root, "Right", center + Vector3(half_w - half_t, 0, 0), Vector3(frame_border_thickness, panel_size.y, frame_depth), border_mat)

func _add_frame_piece(parent: Node3D, nm: String, pos: Vector3, size_vec: Vector3, material: Material) -> void:
	var piece := MeshInstance3D.new()
	piece.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size_vec
	piece.mesh = mesh
	piece.material_override = material
	piece.position = pos
	piece.set_meta("persistent_frame", true)
	parent.add_child(piece)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-08-02): this was `pass`. GridInteractablesComponent parsed
## every `#token: value` on a trng_vs_prng placement, logged it, stashed it as
## metadata and then nothing on this artifact read it back — so any map that tried
## to configure this rig was configuring nothing, silently. It reads its metadata
## now. The grid sets that metadata BEFORE add_child and calls this deferred, so
## _ready does the read that decides what is shown; this is the re-read.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var before: String = disclosure
	_read_meta_overrides()
	if disclosure != before:
		# The register is the only rung that ADDS a body; build it if we just
		# climbed to it, then re-mask. Everything else is a layer mask, so a rung
		# change is free and needs no rebuild at all.
		if _register_root == null:
			_build_origin_register()
		_apply_disclosure()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		disclosure = Disclosure.disclosure_name(str(get_meta("config_disclosure")))
	if has_meta("config_stream_seed"):
		stream_seed = int(str(get_meta("config_stream_seed")))


## Rank of the current rung, 0..4. Every gate here is `_rung() >= n`.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 3))


# ── DISCLOSURE ───────────────────────────────────────────────────────────────

## Fixed sample cadence and count used when the rig is pinned — 0.1 s matches the
## live collector's interval, and 240 steps is comfortably past the 50 the
## statistics block needs before it will draw at all.
const PIN_DT := 0.1
const PIN_STEPS := 240

## The four source values, frozen at the end of priming.
var _entropy_snapshot: Array = [0.0, 0.0, 0.0, 0.0]
## disclosure:origin — the seed register wall and its empty twin.
var _register_root: Node3D = null


## Fill the buffers ONCE, deterministically, then stop. Everything downstream of
## this — the twenty bars per panel, the four statistics, the fifty-segment trails
## — becomes a pure function of stream_seed rather than of how long the capture
## happened to take.
func _prime_pinned() -> void:
	_pinned = true
	for i in range(PIN_STEPS):
		time += PIN_DT
		collect_samples()
		entropy_history.append({
			"trng": calculate_entropy(trng_samples),
			"prng": calculate_entropy(prng_samples),
		})
		if entropy_history.size() > ENTROPY_HISTORY_COUNT:
			entropy_history.remove_at(0)
	_entropy_snapshot = [
		quantum_fluctuation(),
		thermal_fluctuation(),
		atmospheric_fluctuation(),
		system_timing_jitter(),
	]


## Withhold by LAYER MASK, never by not computing. Every sample, statistic and
## transform is produced at every rung; the rung decides only what the camera is
## allowed to see. Two reasons, and the second is the one that matters for
## evidence: the mathematics is curriculum and must not vary, and the artifact's
## bounding box stays identical across all five rungs, so the capture camera does
## not move and the sweep measures the axis instead of its own framing.
func _apply_disclosure() -> void:
	var r: int = _rung()
	# tally — the aggregate: the four-test comparison block.
	_mask(get_node_or_null("StatisticalComparison"), r >= 1)
	# ledger — the per-sample record: the two entropy spheres and their trails.
	_mask(get_node_or_null("EntropyVisualization"), r >= 2)
	# works — the mechanism: the harvest on one side, the pipeline on the other,
	# and the two captions that name what each is doing.
	var mech: Array = [
		mm_trng_sources, mm_trng_connections, mm_trng_combiner,
		mm_prng_steps, mm_prng_arrows, mm_prng_state,
		get_node_or_null("TrueRandomGenerator/TrngExplanation"),
		get_node_or_null("PseudoRandomGenerator/PrngExplanation"),
	]
	for n in mech:
		_mask(n, r >= 3)
	# origin — the substrate: the register wall, and the socket row facing it.
	_mask(_register_root, r >= 4)


## layers = 0 on every VisualInstance3D in the subtree. NOT `visible = false`:
## visibility propagates to children and, more to the point, this artifact is
## measured by a capturer that fits the camera to the union of its meshes without
## consulting visibility — so a masked node keeps its place in the bounding box
## and every variant is photographed from the same spot.
func _mask(n: Node, on: bool) -> void:
	if n == null or not is_instance_valid(n):
		return
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 1 if on else 0
	for c in n.get_children():
		_mask(c, on)


## disclosure:origin — THE REGISTER WALL.
##
## Thirty-two lamps across the top of the PRNG vitrine, MSB left: the seed, in
## binary, the exact pattern the entire right-hand panel unrolls from. A set bit
## stands tall and lit; a clear bit is a dark stub in its socket. Facing it across
## the rig, in the same band of the TRNG vitrine, the same thirty-two sockets with
## NO lamps in them at all — because that side has no seed, has never had one, and
## could not be replayed by anyone.
##
## The asymmetry is the whole teaching, and it is the one thing the legacy rig
## never says out loud: both panels currently show twenty bars each and the
## captions assert a difference the geometry does not draw.
func _build_origin_register() -> void:
	if _rung() < 4:
		return
	if _register_root != null and is_instance_valid(_register_root):
		return
	_register_root = Node3D.new()
	_register_root.name = "SeedRegister"
	add_child(_register_root)

	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.35, 0.65, 1.0)
	lit.emission_enabled = true
	lit.emission = Color(0.35, 0.65, 1.0)
	lit.emission_energy_multiplier = 3.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.10, 0.11, 0.15)
	dark.metallic = 0.4
	dark.roughness = 0.5
	var sill := StandardMaterial3D.new()
	sill.albedo_color = Color(0.30, 0.32, 0.38)
	sill.metallic = 0.6
	sill.roughness = 0.35
	var absent := StandardMaterial3D.new()
	absent.albedo_color = Color(0.55, 0.20, 0.16)
	absent.emission_enabled = true
	absent.emission = Color(0.75, 0.24, 0.16)
	absent.emission_energy_multiplier = 1.2

	# Both registers sit in the free band across the top of each vitrine, inside
	# the frame that is already there, so nothing leaves the panel it belongs to.
	# Built under ONE root (not under the two containers) so the layer mask reaches
	# every piece from a single walk; the ±8 m panel offset is applied by hand.
	var pitch := 0.18
	var base_y := 2.20
	var span: float = pitch * 31.0
	for side in range(2):
		var ox: float = 8.0 if side == 0 else -8.0     # 0 = pseudo (right), 1 = true (left)
		var rail := Node3D.new()
		rail.name = "Register_PRNG" if side == 0 else "Register_TRNG"
		rail.position = Vector3(ox, 0, 0)
		_register_root.add_child(rail)
		# The sill the lamps stand on — full width, so an empty register still
		# reads as a register rather than as nothing.
		rail.add_child(_reg_box(Vector3(0, base_y - 0.09, -0.12),
			Vector3(span + 0.24, 0.09, 0.09), sill))
		for i in range(32):
			var x: float = -span * 0.5 + float(i) * pitch
			# The socket: identical on both sides. What differs is what is in it.
			rail.add_child(_reg_box(Vector3(x, base_y - 0.01, -0.12),
				Vector3(0.13, 0.07, 0.13), dark))
			if side == 1:
				continue                     # the true source has no seed to show
			# MSB left. A pinned rig shows its actual seed; an unpinned one has no
			# recorded seed at all and stands its lamps down — the honest picture,
			# because randomize() cannot be read back.
			var bit: int = 0
			if stream_seed >= 0:
				bit = (stream_seed >> (31 - i)) & 1
			if bit == 1:
				rail.add_child(_reg_box(Vector3(x, base_y + 0.32, -0.12),
					Vector3(0.11, 0.62, 0.11), lit))
			else:
				rail.add_child(_reg_box(Vector3(x, base_y + 0.09, -0.12),
					Vector3(0.11, 0.14, 0.11), dark))
		if side == 1:
			# A struck-through bar across the empty register: the row is not merely
			# empty, it is CLOSED. Nothing will ever be written there.
			rail.add_child(_reg_box(Vector3(0, base_y + 0.16, -0.11),
				Vector3(span + 0.10, 0.07, 0.05), absent))


func _reg_box(center: Vector3, size_vec: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_vec
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
