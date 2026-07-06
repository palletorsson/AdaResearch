extends Node3D
class_name ShannonEntropyMeter

## Wall-mounted Shannon entropy gauge — generates random sequences,
## computes symbol frequencies, and displays H = -Σ p(x) log₂ p(x).

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall gauge that turns a random sequence into a number — the average information per symbol, in bits
# desire: to make the abstract "amount of randomness" a thing on a wall the player can read like a thermometer
# critical_parameter: num_symbols — sets the maximum possible entropy log₂(N), the ceiling against which the actual is measured
# triggers: continuous re-sampling of a random stream, frequency histogram bars updating, entropy bar climbing toward log₂(N)
# emerges: the visual fact that uniform distributions have HIGHER entropy than skewed ones — randomness IS evenness
# needs: num_symbols[has] sequence_length[has] entropy_label[has] frequency_bars[has] vr_distribution_picker[missing]
# relationships: the measurement instrument for the randomness sequence — pairs with distribution_sampler and entropy_jar
# truth: information IS uncertainty resolved — H = -Σ p(x) log₂ p(x) is the formula for "how surprised should you be?"

# --- Configuration ---
@export var panel_size: Vector2 = Vector2(0.7, 0.5)
@export var num_symbols: int = 10
@export var sequence_length: int = 200
@export var bar_color_low: Color = Color(0.2, 0.3, 0.9)
@export var bar_color_high: Color = Color(0.9, 0.2, 0.3)

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
var _freq_bars: Array[MeshInstance3D] = []
var _freq_labels: Array[Node3D] = []

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
	_rng.seed = hash("shannon_entropy")
	_build_panel()
	_build_gauge()
	_build_frequency_bars()
	_build_labels()
	_run_measurement()


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
	if _formula_label:
		_formula_label.position = Vector3(0, panel_size.y / 2.0 - 0.10, 0.003)
		add_child(_formula_label)

	# Entropy value — large, glowing
	_entropy_pos = Vector3(0.06, BAR_REGION_BOTTOM + BAR_REGION_HEIGHT + 0.035, 0.003)
	_rebuild_entropy_board("H = 0.000")

	# Max entropy label
	var max_h := log(num_symbols) / log(2.0)
	_max_label = BakedText.make_tag(
		"max = %.2f bits (%d symbols)" % [max_h, num_symbols],
		Color(0.5, 0.6, 0.75), 0.028,
		Color(0.05, 0.06, 0.09), true, Color(0, 0, 0, 0))
	if _max_label:
		_max_label.position = Vector3(0, BAR_REGION_BOTTOM - 0.045, 0.003)
		add_child(_max_label)

	# Sequence sample board (rebuilt on runtime updates)
	_sequence_pos = Vector3(0, -panel_size.y / 2.0 + 0.03, 0.003)


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

	# Update gauge bar
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

	for i in range(num_symbols):
		var height: float = (float(counts[i]) / float(max_count)) * FREQ_BAR_HEIGHT if max_count > 0 else 0.0
		height = max(0.002, height)
		var bar_q := _freq_bars[i].mesh as QuadMesh
		bar_q.size.y = height
		_freq_bars[i].position.y = FREQ_REGION_BOTTOM + height / 2.0

	# Show a sample of the sequence
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


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_symbols"):
		num_symbols = int(config_data["num_symbols"])
	if config_data.has("sequence_length"):
		sequence_length = int(config_data["sequence_length"])
	if config_data.has("seed"):
		_rng.seed = int(config_data["seed"])
