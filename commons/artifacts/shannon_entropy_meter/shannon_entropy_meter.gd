extends Node3D
class_name ShannonEntropyMeter

## Wall-mounted Shannon entropy gauge — generates random sequences,
## computes symbol frequencies, and displays H = -Σ p(x) log₂ p(x).

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
var _entropy_label: Label3D
var _formula_label: Label3D
var _title_label: Label3D
var _max_label: Label3D
var _sequence_label: Label3D
var _freq_bars: Array[MeshInstance3D] = []
var _freq_labels: Array[Label3D] = []

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
		# Tick label
		var tick_lbl := Label3D.new()
		tick_lbl.pixel_size = 0.001
		tick_lbl.font_size = 20
		tick_lbl.text = "%.1f" % val if val != max_h else "%.2f" % val
		tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tick_lbl.position = Vector3(x_pos, BAR_REGION_BOTTOM - 0.02, 0.003)
		tick_lbl.modulate = Color(0.5, 0.5, 0.6)
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

		# Symbol label beneath
		var lbl := Label3D.new()
		lbl.pixel_size = 0.001
		lbl.font_size = 16
		lbl.text = str(i)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector3(x_pos, FREQ_REGION_BOTTOM + FREQ_BAR_HEIGHT + 0.015, 0.003)
		lbl.modulate = Color(0.45, 0.45, 0.5)
		add_child(lbl)
		_freq_labels.append(lbl)


func _build_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.pixel_size = 0.001
	_title_label.font_size = 42
	_title_label.outline_size = 5
	_title_label.text = "Shannon Entropy"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector3(0, panel_size.y / 2.0 - 0.04, 0.003)
	_title_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_title_label)

	# Formula
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 28
	_formula_label.outline_size = 4
	_formula_label.text = "H = -\u03a3 p(x) log\u2082 p(x)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, panel_size.y / 2.0 - 0.09, 0.003)
	_formula_label.modulate = Color(0.6, 0.75, 0.95)
	add_child(_formula_label)

	# Entropy value — large, glowing
	_entropy_label = Label3D.new()
	_entropy_label.pixel_size = 0.001
	_entropy_label.font_size = 56
	_entropy_label.outline_size = 6
	_entropy_label.text = "H = 0.000"
	_entropy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entropy_label.position = Vector3(0.06, BAR_REGION_BOTTOM + BAR_REGION_HEIGHT + 0.035, 0.003)
	_entropy_label.modulate = Color(1.0, 1.0, 0.6)
	add_child(_entropy_label)

	# Max entropy label
	var max_h := log(num_symbols) / log(2.0)
	_max_label = Label3D.new()
	_max_label.pixel_size = 0.001
	_max_label.font_size = 22
	_max_label.outline_size = 3
	_max_label.text = "max = %.2f bits (%d symbols)" % [max_h, num_symbols]
	_max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_max_label.position = Vector3(0, BAR_REGION_BOTTOM - 0.04, 0.003)
	_max_label.modulate = Color(0.4, 0.5, 0.65)
	add_child(_max_label)

	# Sequence sample label
	_sequence_label = Label3D.new()
	_sequence_label.pixel_size = 0.001
	_sequence_label.font_size = 18
	_sequence_label.outline_size = 2
	_sequence_label.text = ""
	_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sequence_label.position = Vector3(0, -panel_size.y / 2.0 + 0.03, 0.003)
	_sequence_label.modulate = Color(0.35, 0.4, 0.5)
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

	# Update entropy value label
	_entropy_label.text = "H = %.3f bits" % entropy

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
	_sequence_label.text = sample_str


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
