# perlin_noise_bridge.gd
# Perlin Noise Bridge — from chaos to terrain.
# Side-by-side 16x16 heightfield grids: white noise (random) vs Perlin noise (coherent).
# Shows how noise functions transform raw randomness into structured, terrain-like form.
#
# QFEP: Coherence from constraint — the same [0,1] range, but Perlin imposes
# spatial correlation. Structure is not added, it is revealed by the rule.
#
# @identity
# essence: Perlin(x,y) = smoothstep(dot(gradient, offset)) — gradient noise with spatial memory
# desire: see two grids side by side — one chaotic, one terrain — and feel the moment randomness becomes landscape
# critical_parameter: frequency — controls the scale of coherent features; low = rolling hills, high = jagged peaks
# triggers: _rebuild_grids() regenerates both heightfields when octaves, frequency, or seed change
# emerges: the Perlin grid looks like terrain not because terrain was coded, but because neighbors remember each other
# needs: FastNoiseLite [has]; RackTemplates panel with OCTAVES/FREQUENCY/SEED sliders [has]; RESAMPLE button [has]
# relationships: depends on white_noise_spectrum (conceptual base); feeds noise_layers and procedural terrain artifacts
# truth: Coherence is not the opposite of randomness — it is randomness with memory.

extends Node3D

class_name PerlinNoiseBridge

# ── Grid ────────────────────────────────────────────────────────────────────
const GRID_SIZE := 16
const CELL_WIDTH := 0.015
const MAX_HEIGHT := 0.15
const GRID_SPACING := 0.35  # distance between the two grids (center to center)

# ── Noise parameters ───────────────────────────────────────────────────────
var _octaves: int = 3
var _frequency: float = 2.0
var _seed_val: int = 42

# ── Internal ───────────────────────────────────────────────────────────────
var _white_columns: Array[MeshInstance3D] = []
var _perlin_columns: Array[MeshInstance3D] = []
var _noise: FastNoiseLite
var _white_parent: Node3D
var _perlin_parent: Node3D


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_create_grids()
	_create_labels()
	_create_vr_controls()
	_rebuild_grids()


# ═════════════════════════════════════════════════════════════════════════════
# GRIDS
# ═════════════════════════════════════════════════════════════════════════════

func _create_grids() -> void:
	_white_parent = Node3D.new()
	_white_parent.name = "WhiteNoiseGrid"
	_white_parent.position = Vector3(-GRID_SPACING / 2.0, 1.0, 0)
	add_child(_white_parent)

	_perlin_parent = Node3D.new()
	_perlin_parent.name = "PerlinNoiseGrid"
	_perlin_parent.position = Vector3(GRID_SPACING / 2.0, 1.0, 0)
	add_child(_perlin_parent)

	var half := GRID_SIZE / 2.0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var px := (x - half) * CELL_WIDTH
			var pz := (y - half) * CELL_WIDTH

			# White noise column
			var w_col := _create_column()
			w_col.position = Vector3(px, 0, pz)
			_white_parent.add_child(w_col)
			_white_columns.append(w_col)

			# Perlin noise column
			var p_col := _create_column()
			p_col.position = Vector3(px, 0, pz)
			_perlin_parent.add_child(p_col)
			_perlin_columns.append(p_col)


func _create_column() -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(CELL_WIDTH * 0.9, 0.01, CELL_WIDTH * 0.9)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	return mesh


func _rebuild_grids() -> void:
	# Configure noise
	_noise.seed = _seed_val
	_noise.fractal_octaves = _octaves
	_noise.frequency = _frequency / 10.0  # scale to reasonable range

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_val

	for i in range(GRID_SIZE * GRID_SIZE):
		var gx: int = i % GRID_SIZE
		var gy: int = i / GRID_SIZE

		# White noise: pure random [0, 1]
		var white_val: float = rng.randf()

		# Perlin noise: [-1, 1] mapped to [0, 1]
		var perlin_raw: float = _noise.get_noise_2d(float(gx), float(gy))
		var perlin_val: float = (perlin_raw + 1.0) * 0.5

		_apply_column(_white_columns[i], white_val)
		_apply_column(_perlin_columns[i], perlin_val)


func _apply_column(col: MeshInstance3D, value: float) -> void:
	var h: float = max(value * MAX_HEIGHT, 0.002)
	var box: BoxMesh = col.mesh as BoxMesh
	box.size.y = h
	# Shift column up so base stays at y=0
	col.position.y = h / 2.0

	# Color: blue (low) -> green (mid) -> white (high)
	var color: Color
	if value < 0.5:
		var t := value * 2.0
		color = Color(0.1, 0.2, 0.8).lerp(Color(0.2, 0.8, 0.3), t)
	else:
		var t := (value - 0.5) * 2.0
		color = Color(0.2, 0.8, 0.3).lerp(Color(0.95, 0.95, 1.0), t)

	var mat: StandardMaterial3D = col.material_override as StandardMaterial3D
	mat.albedo_color = color
	mat.emission = color


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# White noise header
	var wl := Label3D.new()
	wl.text = "WHITE NOISE"
	wl.pixel_size = 0.002
	wl.font_size = 14
	wl.modulate = Color(0.9, 0.4, 0.3)
	wl.position = Vector3(-GRID_SPACING / 2.0, 1.0 + MAX_HEIGHT + 0.04, 0)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(wl)

	# Perlin noise header
	var pl := Label3D.new()
	pl.text = "PERLIN NOISE"
	pl.pixel_size = 0.002
	pl.font_size = 14
	pl.modulate = Color(0.3, 0.8, 0.5)
	pl.position = Vector3(GRID_SPACING / 2.0, 1.0 + MAX_HEIGHT + 0.04, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(pl)

	# Title
	var title := Label3D.new()
	title.text = "PERLIN NOISE BRIDGE"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, 1.0 + MAX_HEIGHT + 0.1, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var sub := Label3D.new()
	sub.text = "From chaos to terrain"
	sub.pixel_size = 0.0013
	sub.font_size = 10
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0, 1.0 + MAX_HEIGHT + 0.07, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("NOISE CONTROLS", [
		[
			{"type": "slider_h", "label": "OCTAVES", "default": (_octaves - 1.0) / 5.0},
			{"type": "slider_h", "label": "FREQUENCY", "default": (_frequency - 0.5) / 3.5},
		],
		[
			{"type": "slider_h", "label": "SEED", "default": _seed_val / 99.0},
			{"type": "button", "label": "RESAMPLE"},
		],
	])
	panel.position = Vector3(0, 0.75, 0.2)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# OCTAVES slider (Param_0) — maps [0, 1] to [1, 6]
	var oct_slider: Node = panel.find_child("Param_0", true, false)
	if oct_slider and oct_slider.has_signal("slider_moved"):
		oct_slider.slider_moved.connect(func(_val: float):
			_octaves = int(oct_slider.get_normalized_value() * 5.0) + 1
			_rebuild_grids()
		)

	# FREQUENCY slider (Param_1) — maps [0, 1] to [0.5, 4.0]
	var freq_slider: Node = panel.find_child("Param_1", true, false)
	if freq_slider and freq_slider.has_signal("slider_moved"):
		freq_slider.slider_moved.connect(func(_val: float):
			_frequency = freq_slider.get_normalized_value() * 3.5 + 0.5
			_rebuild_grids()
		)

	# SEED slider (Param_2) — maps [0, 1] to [0, 99]
	var seed_slider: Node = panel.find_child("Param_2", true, false)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.slider_moved.connect(func(_val: float):
			_seed_val = int(seed_slider.get_normalized_value() * 99.0)
			_rebuild_grids()
		)

	# RESAMPLE button (Btn_0)
	var resample_btn: Node = panel.find_child("Btn_0", true, false)
	if resample_btn:
		var area = resample_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b):
				_seed_val = randi() % 100
				_rebuild_grids()
			)


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
