# seed_replay_demo.gd
# Seed Replay Demo — demonstrates seed reproducibility
# An 8x8 grid of colored cubes generated from a seed.
# Same seed always produces the exact same pattern.
#
# @identity
# essence: deterministic chaos — identical seeds yield identical worlds
# desire: slide the seed, watch the grid repaint; hit Replay, see it unchanged
# critical_parameter: the RNG seed — one integer controls 64 colors
# triggers: slider_moved updates seed live; Replay regenerates same pattern; Random picks new seed
# emerges: the grid looks random but is perfectly repeatable — chaos and order coexist
# needs: RackTemplates panel [has]; BoxMesh cubes [has]; Label3D seed display [has]
# relationships: feeds into monte_carlo (seed control for reproducible sampling); sibling to coin_toss (both explore RNG)
# truth: Pseudorandomness is determinism wearing a mask — the seed is the face underneath.

extends Node3D

class_name SeedReplayDemo

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var grid_cols: int = 8
@export var grid_rows: int = 8
@export var cube_size: float = 0.03
@export var cube_gap: float = 0.005

# ── State ─────────────────────────────────────────────────────────────────────
var _current_seed: int = 42
var _cubes: Array[MeshInstance3D] = []
var _seed_label: Label3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_build_grid()
	_build_label()
	_build_panel()
	_regenerate()


# ═════════════════════════════════════════════════════════════════════════════
# GRID
# ═════════════════════════════════════════════════════════════════════════════

func _build_grid() -> void:
	var total_w: float = grid_cols * (cube_size + cube_gap) - cube_gap
	var total_h: float = grid_rows * (cube_size + cube_gap) - cube_gap
	var origin_x: float = -total_w / 2.0
	var origin_y: float = 0.35  # raised above panel

	for row in grid_rows:
		for col in grid_cols:
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(cube_size, cube_size, cube_size)
			mi.mesh = box

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color.WHITE
			mi.material_override = mat

			mi.position = Vector3(
				origin_x + col * (cube_size + cube_gap),
				origin_y + row * (cube_size + cube_gap),
				0
			)
			add_child(mi)
			_cubes.append(mi)


func _regenerate() -> void:
	_rng.seed = _current_seed
	for mi in _cubes:
		var mat: StandardMaterial3D = mi.material_override
		mat.albedo_color = Color(
			_rng.randf(),
			_rng.randf(),
			_rng.randf()
		)
	if _seed_label:
		_seed_label.text = "SEED: %d" % _current_seed


# ═════════════════════════════════════════════════════════════════════════════
# LABEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_label() -> void:
	_seed_label = Label3D.new()
	_seed_label.name = "SeedLabel"
	_seed_label.text = "SEED: %d" % _current_seed
	_seed_label.pixel_size = 0.002
	_seed_label.font_size = 18
	_seed_label.modulate = Color(0.9, 0.85, 0.5)
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_label.position = Vector3(0, 0.68, 0)
	add_child(_seed_label)


# ═════════════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("SEED REPLAY", [
		[{"type": "slider_h", "label": "SEED", "default": 0.042}],
		[
			{"type": "button", "label": "REPLAY"},
			{"type": "button", "label": "RANDOM"},
		],
	])
	panel.position = Vector3(0, 0.12, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(panel)

	# Seed slider (Param_0)
	var seed_slider: Node = panel.find_child("Param_0", true, false)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.slider_moved.connect(_on_seed_slider)

	# Replay button (Btn_0)
	var replay_btn: Node = panel.find_child("Btn_0", true, false)
	if replay_btn:
		var area = replay_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _regenerate())

	# Random button (Btn_1)
	var random_btn: Node = panel.find_child("Btn_1", true, false)
	if random_btn:
		var area = random_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _randomize_seed())


func _on_seed_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("SEED_REPLAY/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		_current_seed = int(norm * 999.0)
		_regenerate()


func _randomize_seed() -> void:
	_current_seed = randi() % 1000
	_regenerate()
	# Update slider position to match
	var slider: Node = get_node_or_null("SEED_REPLAY/Param_0")
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(float(_current_seed) / 999.0)


func apply_grid_config(config: Dictionary) -> void:
	pass
