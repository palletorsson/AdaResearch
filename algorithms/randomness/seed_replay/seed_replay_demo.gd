# seed_replay_demo.gd
# Seed Replay Demo — demonstrates seed reproducibility
# An 8x8 grid of colored cubes generated from a seed.
# Same seed always produces the exact same pattern.
#
# @identity
# essence: deterministic chaos — identical seeds yield identical worlds
# desire: slide the seed, watch the grid repaint; hit Replay, see it unchanged
# critical_parameter: comparison — whether the claim gets a second panel to be checked against; then the RNG seed, one integer controlling 64 colors
# triggers: slider_moved updates seed live; Replay regenerates same pattern; Random picks new seed; apply_grid_config({comparison, seed, contrast_seed}) rebuilds the columns
# emerges: the grid looks random but is perfectly repeatable — chaos and order coexist
# needs: RackTemplates panel [has]; BoxMesh cubes [has]; Label3D seed display [has]
# relationships: feeds into monte_carlo (seed control for reproducible sampling); sibling to coin_toss (both explore RNG)
# truth: Pseudorandomness is determinism wearing a mask — the seed is the face underneath.

extends Node3D

class_name SeedReplayDemo

# ── STAGE-2 DNA (promoted 2026-08-03) ─────────────────────────────────────────
# One axis: `comparison` — what the machine puts side by side.
#
# The artifact's whole claim is "same seed, same grid", and the shipped object
# could not show it. One grid is one grid; a still photograph of it is not
# evidence of anything, because a grid from an UNSEEDED generator looks exactly
# the same. The claim needs a second panel.
#
#   single    one grid, one seed label. The claim, unwitnessed.  (SHIPPED)
#   replicas  the SAME seed run twice, side by side, identical. The control.
#   seeds     two different seeds, side by side. What the integer buys.
#   ladder    three consecutive seeds. Adjacent seeds are not adjacent worlds.
#
# `replicas` is the same word, with the same meaning, that distribution_comparator
# uses one entry away in randomness.json: one generator run again, unchanged.
#
# comparison="single" builds one column at the shipped origin_x with no caption
# labels, seeded from `seed_value` (42, the number `_current_seed` was born
# with), so all 7 direct placements and the 85 exhibit_furniture mounts render
# the object they rendered before.
# ──────────────────────────────────────────────────────────────────────────────

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var grid_cols: int = 8
@export var grid_rows: int = 8
@export var cube_size: float = 0.03
@export var cube_gap: float = 0.005

# ── DNA ───────────────────────────────────────────────────────────────────────
@export_enum("single", "replicas", "seeds", "ladder") var comparison: String = "single"
@export var seed_value: int = 42
@export var contrast_seed: int = 137

const COMPARISONS := ["single", "replicas", "seeds", "ladder"]
const COLUMN_GAP: float = 0.04

# ── State ─────────────────────────────────────────────────────────────────────
var _current_seed: int = 42
var _columns: Array = []   # each: { "seed": int, "cubes": Array, "label": Label3D }
var _seed_label: Label3D
var _rng := RandomNumberGenerator.new()
var _built: bool = false


func _ready() -> void:
	_current_seed = seed_value
	_build_grid()
	_build_label()
	_build_panel()
	_regenerate()
	_built = true


# ═════════════════════════════════════════════════════════════════════════════
# GRID
# ═════════════════════════════════════════════════════════════════════════════

## The seed each column is drawn from. One entry = one grid.
func _column_seeds() -> Array:
	match comparison:
		"replicas":
			return [_current_seed, _current_seed]
		"seeds":
			return [_current_seed, contrast_seed]
		"ladder":
			return [_current_seed, _current_seed + 1, _current_seed + 2]
	return [_current_seed]


func _headline() -> String:
	match comparison:
		"replicas":
			return "SAME SEED TWICE"
		"seeds":
			return "TWO SEEDS"
		"ladder":
			return "THREE SEEDS IN A ROW"
	return "SEED: %d" % _current_seed


func _build_grid() -> void:
	var seeds: Array = _column_seeds()
	var n: int = seeds.size()
	var col_w: float = grid_cols * (cube_size + cube_gap) - cube_gap
	var span: float = n * col_w + float(n - 1) * COLUMN_GAP
	var origin_y: float = 0.35  # raised above panel

	for c in range(n):
		# With n == 1 this is -col_w / 2.0, the shipped origin_x exactly.
		var origin_x: float = -span / 2.0 + float(c) * (col_w + COLUMN_GAP)
		var entry: Dictionary = {"seed": int(seeds[c]), "cubes": [], "label": null}
		var cubes: Array = entry["cubes"]

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
				cubes.append(mi)

		# Per-column caption ONLY when there is something to compare. At
		# `single` no extra node is created, so the shipped object is untouched.
		if n > 1:
			var cap := Label3D.new()
			cap.name = "ColumnSeed_%d" % c
			cap.text = "SEED: %d" % int(seeds[c])
			cap.pixel_size = 0.002
			cap.font_size = 14
			cap.modulate = Color(0.9, 0.85, 0.5)
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cap.position = Vector3(
				origin_x + (col_w - cube_size) * 0.5,
				origin_y - 0.05,
				0
			)
			add_child(cap)
			entry["label"] = cap

		_columns.append(entry)


func _regenerate() -> void:
	var seeds: Array = _column_seeds()
	for i in range(_columns.size()):
		var entry: Dictionary = _columns[i]
		var s: int = int(seeds[i]) if i < seeds.size() else _current_seed
		entry["seed"] = s
		_rng.seed = s
		var cubes: Array = entry["cubes"]
		for mi in cubes:
			var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override
			mat.albedo_color = Color(
				_rng.randf(),
				_rng.randf(),
				_rng.randf()
			)
		var cap = entry["label"]
		if cap != null:
			(cap as Label3D).text = "SEED: %d" % s
	if _seed_label:
		_seed_label.text = _headline()


## Tear down every column and rebuild. Only reached from apply_grid_config,
## and only when a DNA value actually changed.
func _rebuild_columns() -> void:
	for entry in _columns:
		var e: Dictionary = entry
		for mi in (e["cubes"] as Array):
			(mi as Node).queue_free()
		var cap = e["label"]
		if cap != null:
			(cap as Node).queue_free()
	_columns.clear()
	_build_grid()
	_regenerate()


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


## GUARDED: rebuilds only when a DNA value actually CHANGED, and only after
## _ready has built the columns once. Shipped, this was `pass` — so nothing in
## the corpus has ever reached it, and nothing in the corpus moves now.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty() or not _built:
		return

	var changed: bool = false

	if config.has("comparison"):
		var c: String = str(config["comparison"]).strip_edges().to_lower()
		if COMPARISONS.has(c) and c != comparison:
			comparison = c
			changed = true

	if config.has("seed"):
		var s: int = int(config["seed"])
		if s != _current_seed:
			seed_value = s
			_current_seed = s
			changed = true

	if config.has("contrast_seed"):
		var t: int = int(config["contrast_seed"])
		if t != contrast_seed:
			contrast_seed = t
			changed = true

	if not changed:
		return

	_rebuild_columns()
