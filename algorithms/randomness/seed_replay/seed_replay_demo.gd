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
#   offset    the SAME seed twice, but the right grid takes `extra_draws` values
#             from the generator BEFORE it starts colouring. Same seed, changed
#             procedure, different picture: the seed alone is not the name of the
#             image. (2026-09-10, the Random_Definition pilot — the card asked for
#             "one optional deliberate extra draw before colour assignment".)
#
# `replicas` is the same word, with the same meaning, that distribution_comparator
# uses one entry away in randomness.json: one generator run again, unchanged.
#
# comparison="single" builds one column at the shipped origin_x with no caption
# labels, seeded from `seed_value` (42, the number `_current_seed` was born
# with), so all 7 direct placements and the 85 exhibit_furniture mounts render
# the object they rendered before.
#
# THE PANEL'S THIRD BUTTON, "+1 DRAW", toggles the extra draw live on the LAST
# grid, whatever the comparison — so a visitor at `replicas` can break the
# match with one press and mend it with the next, and a visitor at `single`
# can see the one grid change under an unchanged seed. The draw count is
# printed under the headline, so what "the procedure" means is on the panel.
# ──────────────────────────────────────────────────────────────────────────────

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var grid_cols: int = 8
@export var grid_rows: int = 8
@export var cube_size: float = 0.03
@export var cube_gap: float = 0.005

# ── DNA ───────────────────────────────────────────────────────────────────────
@export_enum("single", "replicas", "seeds", "ladder", "offset") var comparison: String = "single"
@export var seed_value: int = 42
@export var contrast_seed: int = 137
## How many values the offset grid draws and discards before colouring.
## Placed as `#offset:N`; 1 is enough to move every colour.
@export var extra_draws: int = 1
## What the demo stands on. The shipped object is a table-top piece: cubes from
## 0.35 m and a panel at 0.12 m above its origin. On a museum deck that put the
## panel at ankle height (observed 2026-09-10, probe: 0.16 m). "table" stands a
## column and a top under it and lifts everything by TABLE_HEIGHT, so the panel
## meets a hand and the cubes an eye. Placed as `#stand:table`; the default
## builds nothing new.
@export_enum("none", "table") var stand: String = "none"
const TABLE_HEIGHT: float = 0.85
const STANDS := ["none", "table"]

const COMPARISONS := ["single", "replicas", "seeds", "ladder", "offset"]
const COLUMN_GAP: float = 0.04
## Draws per cell: one randf() for each of R, G, B — see _regenerate.
const DRAWS_PER_CELL: int = 3

# ── State ─────────────────────────────────────────────────────────────────────
var _current_seed: int = 42
var _columns: Array = []   # each: { "seed": int, "cubes": Array, "label": Label3D }
var _seed_label: Label3D
var _rng := RandomNumberGenerator.new()
## RANDOM's own generator. The shipped code called the global randi(), which
## advances the game's RNG for every other artifact in the hall; the card says
## "preserve global game RNG state", so this one is local and randomized once.
var _pick := RandomNumberGenerator.new()
var _extra_on: bool = false
var _built: bool = false


func _ready() -> void:
	_current_seed = seed_value
	_pick.randomize()
	_extra_on = comparison == "offset"
	# the grid sets config_* metadata before add_child; the museum calls apply_grid_config before add_child
	if has_meta("config_stand"):
		var st: String = str(get_meta("config_stand")).strip_edges().to_lower()
		stand = st if STANDS.has(st) else stand
	_lift = TABLE_HEIGHT if stand == "table" else 0.0
	_build_stand()
	_build_grid()
	_build_label()
	_build_panel()
	_regenerate()
	_built = true

var _lift: float = 0.0
var _stand_root: Node3D

## A plain table: a column and a round top, dark, under the whole demo.
func _build_stand() -> void:
	if _stand_root != null and is_instance_valid(_stand_root):
		_stand_root.queue_free()
		_stand_root = null
	if stand != "table":
		return
	_stand_root = Node3D.new()
	_stand_root.name = "Stand"
	add_child(_stand_root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.15, 0.14)
	mat.roughness = 0.7
	var column := MeshInstance3D.new()
	column.name = "Column"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.17
	cyl.height = TABLE_HEIGHT - 0.03
	column.mesh = cyl
	column.material_override = mat
	column.position = Vector3(0.0, (TABLE_HEIGHT - 0.03) * 0.5, 0.0)
	_stand_root.add_child(column)
	var top := MeshInstance3D.new()
	top.name = "Top"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.03
	top.mesh = disc
	top.material_override = mat
	top.position = Vector3(0.0, TABLE_HEIGHT - 0.015, 0.0)
	_stand_root.add_child(top)

## Everything above the deck is rebuilt at the new height: columns, caption, label, panel.
func _rebuild_all() -> void:
	for entry in _columns:
		var e: Dictionary = entry
		for mi in (e["cubes"] as Array):
			(mi as Node).queue_free()
		var cap = e["label"]
		if cap != null:
			(cap as Node).queue_free()
	_columns.clear()
	if _seed_label != null and is_instance_valid(_seed_label):
		_seed_label.queue_free()
		_seed_label = null
	var old_panel: Node = get_node_or_null("Panel")
	if old_panel != null:
		old_panel.queue_free()
	_build_stand()
	_build_grid()
	_build_label()
	_build_panel()
	_regenerate()


# ═════════════════════════════════════════════════════════════════════════════
# GRID
# ═════════════════════════════════════════════════════════════════════════════

## The seed each column is drawn from. One entry = one grid.
func _column_seeds() -> Array:
	match comparison:
		"replicas", "offset":
			return [_current_seed, _current_seed]
		"seeds":
			return [_current_seed, contrast_seed]
		"ladder":
			return [_current_seed, _current_seed + 1, _current_seed + 2]
	return [_current_seed]


## Draws one grid consumes: three per cell, row by row. The extra draws of the
## offset grid come on top and are named separately in the headline.
func draws_per_grid() -> int:
	return grid_rows * grid_cols * DRAWS_PER_CELL


func _headline() -> String:
	var head: String
	match comparison:
		"replicas":
			head = "SAME SEED TWICE"
		"seeds":
			head = "TWO SEEDS"
		"ladder":
			head = "THREE SEEDS IN A ROW"
		"offset":
			head = "SAME SEED, %d EXTRA DRAW%s FIRST" % [extra_draws, "" if extra_draws == 1 else "S"]
		_:
			head = "SEED: %d" % _current_seed
	# At `single` the shipped label is exactly the line above; the draw count is
	# a second line that exists only where there is a comparison to read.
	if comparison == "single" and not _extra_on:
		return head
	var draws := "%d draws per grid · 3 per cell, row by row" % draws_per_grid()
	if _extra_on:
		draws += " · last grid skips %d first" % extra_draws
	return head + "\n" + draws


func _build_grid() -> void:
	var seeds: Array = _column_seeds()
	var n: int = seeds.size()
	var col_w: float = grid_cols * (cube_size + cube_gap) - cube_gap
	var span: float = n * col_w + float(n - 1) * COLUMN_GAP
	var origin_y: float = 0.35 + _lift  # raised above panel; plus the stand, when there is one

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
			cap.font_size = 20
			cap.outline_size = 5
			cap.outline_modulate = Color(0, 0, 0, 1)
			cap.modulate = Color(0.95, 0.9, 0.55)
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
		# THE PROCEDURE CHANGE. The last grid, when the extra draw is on, asks the
		# generator for `extra_draws` values and throws them away. Same seed,
		# same generator, same cells — and every colour after this line is the
		# one the neighbouring grid gets one draw later.
		if _extra_on and i == _columns.size() - 1:
			for k in range(extra_draws):
				_rng.randf()
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
			var tag := "SEED: %d" % s
			if _extra_on and i == _columns.size() - 1:
				tag += "  +%d" % extra_draws
			(cap as Label3D).text = tag
	if _seed_label:
		_seed_label.text = _headline()
	_note_action(_last_action)


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
	_seed_label.position = Vector3(0, 0.68 + _lift, 0)
	add_child(_seed_label)
	# the visual pass of 12 September: the active action and seed on a cased line at the
	# panel's foot, where the hand is — the title above the grids is large, the panel's own
	# labels are small, and the last thing done had no readable place
	var plate := MeshInstance3D.new()
	plate.name = "ActionPlate"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(0.50, 0.075, 0.01)
	plate.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.12, 0.12, 0.14)
	pmat.roughness = 0.85
	plate.material_override = pmat
	plate.position = Vector3(0, 0.035 + _lift, 0.30)
	plate.rotation_degrees = Vector3(-55, 0, 0)
	add_child(plate)
	_action_line = Label3D.new()
	_action_line.name = "ActionLine"
	_action_line.pixel_size = 0.0013
	_action_line.font_size = 15
	_action_line.outline_size = 0
	_action_line.modulate = Color(0.86, 0.94, 1.0)
	_action_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_line.position = plate.position + Vector3(0, 0.004, 0.006)
	_action_line.rotation_degrees = plate.rotation_degrees
	add_child(_action_line)
	_note_action("ARRIVAL")


var _action_line: Label3D
var _last_action: String = "ARRIVAL"

## The last thing done, the seed, and whether the two grids agree cell for cell.
func _note_action(what: String) -> void:
	_last_action = what
	if _action_line == null:
		return
	var agree: String = ""
	if _columns.size() >= 2:
		var a: PackedColorArray = column_colors(0)
		var b: PackedColorArray = column_colors(1)
		var same: bool = a.size() == b.size() and a.size() > 0
		if same:
			for i in range(a.size()):
				if not a[i].is_equal_approx(b[i]): same = false; break
		agree = "grids equal" if same else "grids differ"
	_action_line.text = "%s · seed %d · %s" % [what, _current_seed, agree]

func last_action() -> String:
	return _last_action


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
			{"type": "button", "label": "+1 DRAW"},
		],
	])
	panel.name = "Panel"
	panel.set_meta("em_local_instrument", true)   # its button areas are hand targets, not this body's footprint
	panel.position = Vector3(0, 0.12 + _lift, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	panel.scale = Vector3(1.5, 1.5, 1.5)   # 12 September: the labels read from the operating position
	add_child(panel)
	_contrast_panel(panel)
	_contrast_panel.call_deferred(panel)   # and once more a frame later, for parts built on entering the tree

	# Seed slider (Param_0)
	var seed_slider: Node = panel.find_child("Param_0", true, false)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.slider_moved.connect(_on_seed_slider)

	# Replay button (Btn_0)
	var replay_btn: Node = panel.find_child("Btn_0", true, false)
	if replay_btn:
		var area = replay_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): replay())

	# Random button (Btn_1)
	var random_btn: Node = panel.find_child("Btn_1", true, false)
	if random_btn:
		var area = random_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _randomize_seed())

	# +1 DRAW (Btn_2): the procedure change, on and off
	var extra_btn: Node = panel.find_child("Btn_2", true, false)
	if extra_btn:
		var area = extra_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): toggle_extra_draw())


func _on_seed_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("SEED_REPLAY/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		_current_seed = int(norm * 999.0)
		_regenerate()


func _randomize_seed() -> void:
	_current_seed = _pick.randi() % 1000
	_regenerate()
	_note_action("RANDOM")
	# Update slider position to match (the panel is named "Panel" since 2026-09-10; find the slider by name)
	var slider: Node = find_child("Param_0", true, false)
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(float(_current_seed) / 999.0)


## The +1 DRAW button. Public so a probe can press what the visitor presses.
func toggle_extra_draw() -> void:
	_extra_on = not _extra_on
	_regenerate()
	_note_action("+1 DRAW on" if _extra_on else "+1 DRAW off")


# ── read by the probe (commons/testing/probe_wcn_random_definition.gd) ────────
func current_seed() -> int:
	return _current_seed

func extra_on() -> bool:
	return _extra_on

func column_count() -> int:
	return _columns.size()

## Every cell colour of one grid, row by row — the sample values themselves,
## which is what "replay two grids and compare all sample values" means.
func column_colors(i: int) -> PackedColorArray:
	var out := PackedColorArray()
	if i < 0 or i >= _columns.size():
		return out
	for mi in (_columns[i]["cubes"] as Array):
		out.append(((mi as MeshInstance3D).material_override as StandardMaterial3D).albedo_color)
	return out

## The rack panel ships cream with small dark lettering, which washes out under the museum's
## light (Astra's review of the visual pass, 12 September: "finish contrast, not just size"):
## its pale plates go dark and every label on it goes light with a dark outline, a third
## larger. Local to this panel; the rack template is untouched.
func _contrast_panel(p: Node3D) -> void:
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		var mat: Material = m.material_override
		if mat == null and m.mesh != null and m.get_surface_override_material_count() > 0:
			mat = m.get_surface_override_material(0)
		if mat == null and m.mesh != null:
			mat = m.mesh.surface_get_material(0) if m.mesh.get_surface_count() > 0 else null
		if not (mat is StandardMaterial3D):
			continue
		var sm: StandardMaterial3D = mat
		var lum: float = (sm.albedo_color.r + sm.albedo_color.g + sm.albedo_color.b) / 3.0
		if lum < 0.75 or sm.albedo_texture != null:
			continue
		var dm: StandardMaterial3D = sm.duplicate()
		dm.albedo_color = Color(0.14, 0.14, 0.16, 1.0)
		dm.roughness = 0.85
		dm.emission_energy_multiplier = 0.0
		m.material_override = dm
	for l in p.find_children("*", "Label3D", true, false):
		var lb: Label3D = l
		lb.modulate = Color(0.95, 0.96, 1.0)
		lb.outline_size = 6
		lb.outline_modulate = Color(0, 0, 0, 1)
		lb.font_size = int(round(lb.font_size * 1.35))

func replay() -> void:
	_regenerate()
	_note_action("REPLAY")

func randomize_seed() -> void:
	_randomize_seed()


## GUARDED: rebuilds only when a DNA value actually CHANGED, and only after
## _ready has built the columns once. Shipped, this was `pass` — so nothing in
## the corpus has ever reached it, and nothing in the corpus moves now.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
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

	if config.has("offset"):
		var n: int = maxi(0, int(config["offset"]))
		if n != extra_draws:
			extra_draws = n
			changed = true

	if config.has("stand"):
		var st: String = str(config["stand"]).strip_edges().to_lower()
		if STANDS.has(st) and st != stand:
			stand = st
			_lift = TABLE_HEIGHT if stand == "table" else 0.0
			if _built:
				_rebuild_all()
				return
			changed = true

	if not changed:
		return

	_extra_on = comparison == "offset"
	# Museum configuration arrives before add_child/_ready. Keep those values
	# immediately; build only after dependencies exist.
	if _built:
		_rebuild_columns()
