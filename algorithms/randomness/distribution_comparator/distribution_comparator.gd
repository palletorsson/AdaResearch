# distribution_comparator.gd
# Distribution Comparator — side-by-side probability distributions
# Three columns of histogram bars showing Uniform, Gaussian, and Exponential
# distributions generated from the same number of random samples.
#
# @identity
# essence: shape is statistics made visible — three distributions from one source
# desire: slide the sample count, hit resample, watch the bars redraw and diverge
# critical_parameter: sample count — more samples smooth the curves toward their ideal shape
# triggers: SAMPLES slider scales resolution; RESAMPLE regenerates all three columns
# emerges: uniform stays flat, gaussian peaks in the center, exponential decays — same randomness, different rules
# needs: RackTemplates panel [has]; BoxMesh bars [has]; Label3D headers [has]
# relationships: sibling to seed_replay (both explore RNG); feeds into monte_carlo (sampling foundations)
# truth: The same random source produces radically different shapes depending on the rule that channels it.

extends Node3D

class_name DistributionComparator

# ── Config ────────────────────────────────────────────────────────────
const NUM_BINS: int = 16
const MAX_BAR_HEIGHT: float = 0.25
const BAR_WIDTH: float = 0.012
const BAR_DEPTH: float = 0.012
const BAR_GAP: float = 0.004
const COLUMN_GAP: float = 0.06

# ── Colors ────────────────────────────────────────────────────────────
const COLOR_UNIFORM := Color(0.3, 0.5, 0.9)
const COLOR_GAUSSIAN := Color(0.3, 0.85, 0.4)
const COLOR_EXPONENTIAL := Color(0.9, 0.55, 0.2)

# ── State ─────────────────────────────────────────────────────────────
var _sample_count: int = 1000
var _rng := RandomNumberGenerator.new()
var _bars: Array[Array] = [[], [], []]  # 3 columns × 16 bars
var _column_labels: Array[Label3D] = []


func _ready() -> void:
	_rng.randomize()
	_build_bars()
	_build_headers()
	_build_panel()
	_resample()


# ═════════════════════════════════════════════════════════════════════
# BARS
# ═════════════════════════════════════════════════════════════════════

func _build_bars() -> void:
	var col_width: float = NUM_BINS * (BAR_WIDTH + BAR_GAP) - BAR_GAP
	var total_width: float = 3.0 * col_width + 2.0 * COLUMN_GAP
	var colors := [COLOR_UNIFORM, COLOR_GAUSSIAN, COLOR_EXPONENTIAL]

	for col in 3:
		var col_origin_x: float = -total_width / 2.0 + float(col) * (col_width + COLUMN_GAP)
		var column_bars: Array[MeshInstance3D] = []
		for bin_idx in NUM_BINS:
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(BAR_WIDTH, 0.01, BAR_DEPTH)
			mi.mesh = box

			var mat := StandardMaterial3D.new()
			mat.albedo_color = colors[col]
			mat.emission = colors[col] * 0.3
			mat.emission_energy_multiplier = 0.4
			mi.material_override = mat

			mi.position = Vector3(
				col_origin_x + float(bin_idx) * (BAR_WIDTH + BAR_GAP),
				0.35,
				0
			)
			add_child(mi)
			column_bars.append(mi)
		_bars[col] = column_bars


# ═════════════════════════════════════════════════════════════════════
# HEADERS
# ═════════════════════════════════════════════════════════════════════

func _build_headers() -> void:
	var col_width: float = NUM_BINS * (BAR_WIDTH + BAR_GAP) - BAR_GAP
	var total_width: float = 3.0 * col_width + 2.0 * COLUMN_GAP
	var titles := ["UNIFORM", "GAUSSIAN", "EXPONENTIAL"]
	var colors := [COLOR_UNIFORM, COLOR_GAUSSIAN, COLOR_EXPONENTIAL]

	for col in 3:
		var col_center_x: float = -total_width / 2.0 + float(col) * (col_width + COLUMN_GAP) + col_width / 2.0
		var lbl := Label3D.new()
		lbl.text = titles[col]
		lbl.pixel_size = 0.002
		lbl.font_size = 14
		lbl.modulate = colors[col]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector3(col_center_x, 0.66, 0)
		add_child(lbl)
		_column_labels.append(lbl)


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("DISTRIBUTIONS", [
		[{"type": "slider_h", "label": "SAMPLES", "default": 0.1}],
		[{"type": "button", "label": "RESAMPLE"}],
	])
	panel.position = Vector3(0, 0.12, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(panel)

	# Samples slider (Param_0)
	var samples_slider: Node = panel.find_child("Param_0", true, false)
	if samples_slider and samples_slider.has_signal("slider_moved"):
		samples_slider.slider_moved.connect(_on_samples_slider)

	# Resample button (Btn_0)
	var resample_btn: Node = panel.find_child("Btn_0", true, false)
	if resample_btn:
		var area = resample_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _resample())


func _on_samples_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("DISTRIBUTIONS/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		# Map 0..1 to 100..10000
		_sample_count = int(100.0 + norm * 9900.0)
		_resample()


# ═════════════════════════════════════════════════════════════════════
# SAMPLING
# ═════════════════════════════════════════════════════════════════════

func _resample() -> void:
	var buckets: Array[Array] = [[], [], []]
	for col in 3:
		var bins: Array[int] = []
		bins.resize(NUM_BINS)
		for i in NUM_BINS:
			bins[i] = 0
		buckets[col] = bins

	# Generate samples
	_rng.randomize()
	var lambda: float = 1.5  # exponential decay rate

	for _i in _sample_count:
		# Uniform: [0, 1)
		var u: float = _rng.randf()
		var u_bin: int = clampi(int(u * NUM_BINS), 0, NUM_BINS - 1)
		buckets[0][u_bin] += 1

		# Gaussian: randfn centered at 0.5, sigma 0.15, clamp to [0, 1)
		var g: float = clampf(_rng.randfn(0.5, 0.15), 0.0, 0.9999)
		var g_bin: int = clampi(int(g * NUM_BINS), 0, NUM_BINS - 1)
		buckets[1][g_bin] += 1

		# Exponential: -ln(randf()) / lambda, normalized to [0, 1) range
		var raw: float = -log(_rng.randf()) / lambda
		var e: float = clampf(raw / 4.0, 0.0, 0.9999)  # scale so most values fit
		var e_bin: int = clampi(int(e * NUM_BINS), 0, NUM_BINS - 1)
		buckets[2][e_bin] += 1

	# Update bar heights
	for col in 3:
		var max_count: int = 1
		for b in buckets[col]:
			if b > max_count:
				max_count = b

		for bin_idx in NUM_BINS:
			var bar: MeshInstance3D = _bars[col][bin_idx]
			var ratio: float = float(buckets[col][bin_idx]) / float(max_count)
			var h: float = maxf(ratio * MAX_BAR_HEIGHT, 0.003)
			var box: BoxMesh = bar.mesh
			box.size.y = h
			bar.position.y = 0.35 + h / 2.0


func apply_grid_config(config: Dictionary) -> void:
	pass
