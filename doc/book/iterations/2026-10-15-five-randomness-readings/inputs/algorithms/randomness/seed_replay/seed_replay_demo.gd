# seed_replay_demo.gd
# Seed Replay Demo — demonstrates seed reproducibility
# Seeded colour grids, shown as cubes or translucent leaded panes.
# Replay repeats a pattern when the generator, seed and draw procedure are held fixed.
#
# @identity
# essence: a seeded pseudorandom stream, replayed with or without one discarded draw
# desire: slide the seed, watch the grid repaint; hit Replay, see it unchanged
# critical_parameter: comparison — whether the claim gets a second panel to be checked against; then the RNG seed, one integer controlling 64 colors
# triggers: slider_moved updates seed live; Replay regenerates same pattern; Random picks new seed; apply_grid_config({comparison, seed, contrast_seed}) rebuilds the columns
# emerges: the same seed can dress the grid differently when draw consumption changes
# needs: RackTemplates panel [has]; BoxMesh cubes [has]; Label3D seed display [has]
# relationships: feeds into monte_carlo (seed control for reproducible sampling); sibling to coin_toss (both explore RNG)
# truth: Nothing in a draw says that it is red; the program assigns that role by where the draw falls.

extends Node3D

class_name SeedReplayDemo
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")

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
#   seed_witness  three stacked windows: start, same-seed replay, seed + 1.
#             Only the middle replay changes its draw offset or colour mapping.
#
# `replicas` is the same word, with the same meaning, that distribution_comparator
# uses one entry away in randomness.json: one generator run again, unchanged.
#
# comparison="single" builds one column at the shipped origin_x with no caption
# labels, seeded from `seed_value` (42, the number `_current_seed` was born
# with), so all 7 direct placements and the 85 exhibit_furniture mounts render
# the object they rendered before.
#
# THE PANEL'S THIRD BUTTON, "+1 DRAW", toggles the extra draw on the LAST
# grid (the MIDDLE replay in seed_witness) — so a visitor at `replicas` can break the
# match with one press and mend it with the next, and a visitor at `single`
# can see the one grid change under an unchanged seed. The draw count is
# printed under the headline, so what "the procedure" means is on the panel.
# ──────────────────────────────────────────────────────────────────────────────

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var grid_cols: int = 8
@export var grid_rows: int = 8
@export var cube_size: float = 0.03
@export var cube_gap: float = 0.005
## An opt-in window finish; the colour procedure and its sample API stay the same.
@export_enum("solid", "glass") var surface: String = "solid"
const LeadedGlass = preload("res://algorithms/randomness/seed_replay/leaded_glass.gd")
const SeedStack = preload("res://algorithms/randomness/seed_replay/seed_stack.gd")
var _window_frames: Node3D

# ── DNA ───────────────────────────────────────────────────────────────────────
@export_enum("single", "replicas", "seeds", "ladder", "offset", "seed_witness") var comparison: String = "single"
@export var seed_value: int = 42
@export var contrast_seed: int = 137
## How many values the offset grid draws and discards before colouring.
## Placed as `#offset:N`; 1 is enough to move every colour.
@export var extra_draws: int = 1
## Opt in per hall. Nothing is fetched on arrival, replay or restore.
@export var atmosphere: bool = false
@export var recorded_atmosphere: bool = false
@export var movement_seed: bool = false
@export var route_link: String = ""
## Compare assignments on the target window while preserving the baseline and draws.
@export var mapping_study: bool = false
const MAPPING_MODES := ["RGB", "RED ONLY", "SWAP R/B"]
var mapping_mode: int = 0
var mapping_narrow: bool = false
signal seed_selected(value: int, receipt: Dictionary)
signal sequence_replayed
const EDITOR_PARTS = preload("res://algorithms/randomness/seed_replay/editor_parts.gd")
var _part_layout: Dictionary = {}
var _journey: Node
const AtmosphericSeed = preload("res://algorithms/randomness/seed_replay/atmospheric_seed.gd")
const MovementSampler = preload("res://algorithms/randomness/seed_replay/movement_sampler.gd")
var _movement_sampler: Node3D
var _atmosphere_client: Node
var _source_label: Label3D
var _large_seed: Label3D
var _source_receipt: Dictionary = {}
var _seed_revision: int = 0
var _requested_revision: int = -1
## What the demo stands on. The shipped object is a table-top piece: cubes from
## 0.35 m and a panel at 0.12 m above its origin. On a museum deck that put the
## panel at ankle height (observed 2026-09-10, probe: 0.16 m). "table" stands a
## column and a top under it and lifts everything by TABLE_HEIGHT, so the panel
## meets a hand and the cubes an eye. Placed as `#stand:table`; the default
## builds nothing new.
@export_enum("none", "table") var stand: String = "none"
const TABLE_HEIGHT: float = 0.85
const STANDS := ["none", "table"]

const COMPARISONS := ["single", "replicas", "seeds", "ladder", "offset", "seed_witness"]
const COLUMN_GAP: float = 0.04
## Draws per cell: one randf() for each of R, G, B — see _regenerate.
const DRAWS_PER_CELL: int = 3

# ── State ─────────────────────────────────────────────────────────────────────
var _current_seed: int = 42
var _columns: Array = []   # "cubes" retains its API name for both cubes and glass panes.
var _seed_label: Label3D
var _rng := RandomNumberGenerator.new()
## RANDOM's own generator. The shipped code called the global randi(), which
## advances the game's RNG for every other artifact in the hall; the card says
## "preserve global game RNG state", so this one is local and randomized once.
var _pick := RandomNumberGenerator.new()
var _extra_on: bool = false
var _built: bool = false
var _syncing_seed_slider: bool = false
var wall_display: bool = false
var _number_display: Node3D
var _grid_width: float = 0.0
var _grid_height: float = 0.0
var _reference_cube_size: float = 0.0
var _syncing_resolution: bool = false
const MIN_SIDE := 2
const MAX_SIDE := 16

## The stacked comparison keeps a different-seed control untouched at the top.
func comparison_target() -> int:
	return 1 if comparison == "seed_witness" else _columns.size()-1

## Raw prefix for inspection; its independent generator never consumes exhibit draws.
func raw_prefix(column: int, count: int = 24) -> PackedFloat32Array:
	var source := RandomNumberGenerator.new()
	source.seed = int(_column_seeds()[column])
	if _extra_on and column == comparison_target():
		for i in range(extra_draws): source.randf()
	var values := PackedFloat32Array()
	for i in range(count): values.append(source.randf())
	return values

func _draw_number_strips() -> void:
	if not wall_display: return
	if is_instance_valid(_number_display):
		remove_child(_number_display); _number_display.queue_free()
	_number_display = Node3D.new(); add_child(_number_display)
	if comparison == "seed_witness":
		SeedStack.draw_readouts(self, _number_display)
		return
	var stage = load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
	for c in range(_columns.size()):
		var values := raw_prefix(c)
		var x0: float = -1.22 + c * 1.275
		if surface!="glass":
			stage.box(_number_display,Vector3(x0+0.56,1.74,-0.10),Vector3(1.25,1.3,0.06),Color(0.045,0.065,0.08))
		stage.box(_number_display,Vector3(x0+0.56,2.64,0),Vector3(1.2,0.38,0.035),Color(0.035,0.06,0.08))
		for i in range(values.size()):
			var h: float = 0.025 + values[i]*0.24
			stage.box(_number_display,Vector3(x0+i*0.047,2.5+h*0.5,0.04),Vector3(0.033,h,0.025),Color(0.2,0.85,0.72))
		var label: Label3D = stage.label(_number_display,"DRAWS 1–24" if not (_extra_on and c==_columns.size()-1) else "DRAWS %d–%d" % [extra_draws+1,extra_draws+24],Vector3(x0+0.55,2.89,0.06))
		label.font_size=22; label.pixel_size=0.0015


func _ready() -> void:
	if HallSeed.enabled(self): seed_value = HallSeed.current(self)
	_current_seed = seed_value
	if recorded_atmosphere and atmosphere:
		var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://algorithms/randomness/seed_replay/opening_seed.json"))
		if receipt is Dictionary and int(receipt.get("seed", -1)) == _current_seed:
			_source_receipt = receipt.duplicate(true)
	if HallSeed.enabled(self): _pick.seed = HallSeed.START
	else: _pick.randomize()
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
	_build_atmosphere()
	if movement_seed:
		_movement_sampler = MovementSampler.new()
		_movement_sampler.position = Vector3(-1.65,0,0.95)
		add_child(_movement_sampler)
		_movement_sampler.started.connect(func(): _seed_revision += 1)
		_movement_sampler.received.connect(_receive_movement_seed)
	_regenerate()
	_sync_seed_slider()
	_built = true
	if movement_seed and route_link.is_empty():
		_place_editor_parts.call_deferred()
	if not route_link.is_empty():
		_journey = load("res://algorithms/randomness/seed_replay/seed_journey.gd").new()
		add_child(_journey)
	HallSeed.bind(self)
	if HallSeed.enabled(self): seed_selected.connect(_hall_selection)

func can_apply_hall_seed() -> bool:
	return not is_instance_valid(_movement_sampler) or not _movement_sampler.collecting

func _apply_hall_seed(value: int, receipt: Dictionary) -> void:
	_current_seed = value
	_seed_revision += 1
	_source_receipt = receipt.duplicate(true)
	_regenerate()
	_sync_seed_slider()
	_note_action("HALL SEED")
	_show_seed_source()
	seed_selected.emit(value,receipt.duplicate(true))

func _hall_selection(value: int, receipt: Dictionary) -> void:
	if not HallSeed.choose(self,value,receipt):
		var hub := HallSeed.state(self)
		hub.applying = true
		_apply_hall_seed(hub.value,hub.receipt)
		hub.applying = false
		_show_seed_source("Release the active hand/body before changing the hall seed.")

var _lift: float = 0.0
var _stand_root: Node3D

## A plain table: a column and a round top, dark, under the whole demo.
func _build_stand() -> void:
	if _stand_root != null and is_instance_valid(_stand_root):
		_stand_root.queue_free()
		_stand_root = null
	if stand != "table" or comparison == "seed_witness":
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
	_sync_seed_slider()


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
		"seed_witness":
			return [_current_seed, _current_seed, _current_seed + 1]
	return [_current_seed]


## Draws one grid consumes: three per cell, row by row. The extra draws of the
## offset grid come on top and are named separately in the headline.
func draws_per_grid() -> int:
	return grid_rows * grid_cols * DRAWS_PER_CELL


func _headline() -> String:
	if comparison == "seed_witness": return "ONE START · TWO RUNS · ONE CHANGED SEED"
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
	if is_instance_valid(_window_frames):
		remove_child(_window_frames)
		_window_frames.queue_free()
		_window_frames=null
	if surface=="glass":
		_window_frames=Node3D.new()
		_window_frames.name="LeadedWindows"
		add_child(_window_frames)
	var seeds: Array = _column_seeds()
	var n: int = seeds.size()
	if _grid_width == 0.0:
		_grid_width = grid_cols * (cube_size + cube_gap) - cube_gap
		_grid_height = grid_rows * (cube_size + cube_gap) - cube_gap
		_reference_cube_size = cube_size
	if comparison == "seed_witness": SeedStack.build_body(self)
	var col_w: float = _grid_width
	var fill: float = cube_size / (cube_size + cube_gap)
	if surface=="glass": fill=0.97
	var step_x: float = _grid_width / (grid_cols - 1 + fill)
	var step_y: float = _grid_height / (grid_rows - 1 + fill)
	var cell_x: float = step_x * fill
	var cell_y: float = step_y * fill
	var span: float = n * col_w + float(n - 1) * COLUMN_GAP
	var origin_y: float = 0.35 + _lift  # raised above panel; plus the stand, when there is one

	for c in range(n):
		# With n == 1 this is -col_w / 2.0, the shipped origin_x exactly.
		var origin_x: float = -span / 2.0 + float(c) * (col_w + COLUMN_GAP)
		if comparison == "seed_witness":
			var centre: Vector3 = SeedStack.centre(self,c)
			origin_x = centre.x - (col_w-_reference_cube_size)*0.5
			origin_y = centre.y - (_grid_height-_reference_cube_size)*0.5
		var entry: Dictionary = {"seed": int(seeds[c]), "cubes": [], "label": null}
		var cubes: Array = entry["cubes"]

		for row in grid_rows:
			for col in grid_cols:
				var mi := MeshInstance3D.new()
				if surface=="glass":
					var pane:=QuadMesh.new()
					pane.size=Vector2(cell_x,cell_y)
					mi.mesh=pane
					mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				else:
					var box := BoxMesh.new()
					box.size = Vector3(cell_x, cell_y, minf(cell_x, cell_y))
					mi.mesh = box

				var mat: StandardMaterial3D = LeadedGlass.material() if surface=="glass" else StandardMaterial3D.new()
				mat.albedo_color = Color.WHITE
				mi.material_override = mat

				mi.position = Vector3(
					origin_x + col * step_x + (cell_x - _reference_cube_size) * 0.5,
					origin_y + row * step_y + (cell_y - _reference_cube_size) * 0.5,
					0
				)
				add_child(mi)
				cubes.append(mi)

		if surface=="glass":
			var centre:=Vector3(origin_x+(col_w-_reference_cube_size)*0.5,origin_y+(_grid_height-_reference_cube_size)*0.5,0)
			LeadedGlass.frame(_window_frames,centre,col_w,_grid_height,grid_cols,grid_rows,Vector2(step_x,step_y),Vector2(cell_x,cell_y),comparison!="seed_witness")

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
				origin_x + (col_w - _reference_cube_size) * 0.5,
				origin_y - (0.11 if wall_display else 0.05),
				0
			)
			if mapping_study and wall_display:
				cap.position.y = origin_y + _grid_height - _reference_cube_size*0.5 + 0.055
				cap.font_size = 23
			if comparison == "seed_witness":
				cap.position = Vector3(SeedStack.INFO_X,SeedStack.centre(self,c).y+0.37,0.06)
				cap.font_size = 40
				cap.pixel_size = 0.0018
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
		# THE PROCEDURE CHANGE. The target grid, when the extra draw is on, asks the
		# generator for `extra_draws` values and throws them away. Same seed,
		# same generator, same cells — and every colour after this line is the
		# one the neighbouring grid gets one draw later.
		if _extra_on and i == comparison_target():
			for k in range(extra_draws):
				_rng.randf()
		var cubes: Array = entry["cubes"]
		for mi in cubes:
			var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override
			var sample := Color(
				_rng.randf(),
				_rng.randf(),
				_rng.randf()
			)
			mat.albedo_color = map_sample(sample) if mapping_study and i == comparison_target() else sample
		var cap = entry["label"]
		if cap != null:
			var tag := "SEED: %d" % s
			if _extra_on and i == comparison_target():
				tag += "  +%d" % extra_draws
			if mapping_study:
				tag += " · " + (mapping_description() if i == comparison_target() else "BASELINE · RGB [0, 1]")
			if comparison == "seed_witness":
				tag = "%s\nSEED %d" % [["START","REPLAY","SEED + 1"][i],s]
			(cap as Label3D).text = tag
	if _seed_label:
		_seed_label.text = _headline()
		_seed_label.position = Vector3(0,3.13 if wall_display else 0.68+_lift,0)
		_seed_label.pixel_size = 0.003 if wall_display else 0.002
		_seed_label.font_size = 18
		if comparison == "seed_witness":
			_seed_label.position = Vector3(0.16,SeedStack.centre(self,2).y+_grid_height*0.5+0.17,0.11)
			_seed_label.pixel_size = 0.002
			_seed_label.font_size = 30
	var source_display := get_node_or_null("AtmosphereDisplay") as Node3D
	if source_display:
		source_display.position = Vector3(0,3.85 if wall_display else 1.35+_lift,0.02)
		source_display.scale = Vector3.ONE * (1.0 if wall_display else 0.35)
		if comparison == "seed_witness":
			source_display.position = Vector3(-0.64,SeedStack.CONTROL_HEIGHT,0.15)
			source_display.scale = Vector3.ONE * 0.40
	_draw_number_strips()
	_note_action(_last_action)


## Three draws are consumed in every mode. Mapping never advances either journey RNG.
func map_sample(sample: Color) -> Color:
	var low := 0.2 if mapping_narrow else 0.0
	var high := 0.8 if mapping_narrow else 1.0
	var mapped := Color(lerpf(low,high,sample.r),lerpf(low,high,sample.g),lerpf(low,high,sample.b))
	if mapping_mode == 1: return Color(mapped.r,0.5,0.5)
	if mapping_mode == 2: return Color(mapped.b,mapped.g,mapped.r)
	return mapped

func mapping_description() -> String:
	return "%s · %s" % [MAPPING_MODES[mapping_mode],"[0.2, 0.8]" if mapping_narrow else "[0, 1]"]

func cycle_mapping() -> void:
	mapping_mode = (mapping_mode+1) % MAPPING_MODES.size()
	_regenerate()
	_note_action(_mapping_target_name() + " " + mapping_description())

func toggle_mapping_range() -> void:
	mapping_narrow = not mapping_narrow
	_regenerate()
	_note_action(_mapping_target_name() + " " + mapping_description())

func reset_mapping() -> void:
	mapping_mode = 0
	mapping_narrow = false
	_regenerate()
	_note_action(_mapping_target_name() + " RGB [0, 1] · draw offset unchanged")

func _mapping_target_name() -> String:
	return "REPLAY" if comparison == "seed_witness" else "RIGHT"


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
	_sync_seed_slider()


# ═════════════════════════════════════════════════════════════════════════════
# LABEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_label() -> void:
	_seed_label = Label3D.new()
	_seed_label.name = "SeedLabel"
	_seed_label.text = "SEED: %d" % _current_seed
	_seed_label.pixel_size = 0.003 if wall_display else 0.002
	_seed_label.font_size = 18
	_seed_label.modulate = Color(0.9, 0.85, 0.5)
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_label.position = Vector3(0, 3.13 if wall_display else 0.68 + _lift, 0)
	add_child(_seed_label)
	# the visual pass of 12 September: the active action and seed on a cased line at the
	# panel's foot, where the hand is — the title above the grids is large, the panel's own
	# labels are small, and the last thing done had no readable place
	var plate := MeshInstance3D.new()
	plate.name = "ActionPlate"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(0.60, 0.085, 0.01)
	plate.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.12, 0.12, 0.14)
	pmat.roughness = 0.85
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = pmat
	plate.position = Vector3(0, 0.035 + _lift, 0.30)
	plate.rotation_degrees = Vector3(-55, 0, 0)
	add_child(plate)
	if comparison == "seed_witness": plate.visible=false
	_action_line = Label3D.new()
	_action_line.name = "ActionLine"
	_action_line.pixel_size = 0.0013
	_action_line.font_size = 20
	_action_line.outline_size = 0
	_action_line.modulate = Color(0.86, 0.94, 1.0)
	_action_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_line.position = plate.position + Vector3(0, 0.004, 0.006)
	_action_line.rotation_degrees = plate.rotation_degrees
	add_child(_action_line)
	if comparison == "seed_witness":
		_action_line.position=Vector3(0.16,SeedStack.CONTROL_HEIGHT+0.29,0.14)
		_action_line.rotation=Vector3.ZERO
		_action_line.pixel_size=0.0018
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
	var rows: Array = [
		[{"type": "slider_h", "label": "SEED", "default": 0.042}],
		[{"type": "slider_h", "label": "MATRIX", "default": float(grid_cols - MIN_SIDE) / (MAX_SIDE - MIN_SIDE)}],
		[
			{"type": "button", "label": "REPLAY"},
			{"type": "button", "label": "SEED +1" if HallSeed.enabled(self) else "RANDOM"},
			{"type": "button", "label": "+1 DRAW"},
		],
	]
	if atmosphere:
		rows.append([{"type": "button", "label": "RESET 435" if HallSeed.enabled(self) else "ATMOSPHERE", "shape": "rect"}])
	if mapping_study:
		var primary: Array = rows[2]
		if atmosphere: primary.append(rows[3][0])
		for button in primary: button["shape"] = "rect"
		rows = [[rows[0][0],rows[1][0]],primary]
		rows.append([{"type":"button","label":_mapping_target_name()+": MAP","shape":"rect"},
			{"type":"button","label":_mapping_target_name()+": RANGE","shape":"rect"},
			{"type":"button","label":"RESET MAP","shape":"rect"}])
	if comparison == "seed_witness":
		# Both sliders above one row of seven buttons; original IDs and callbacks remain.
		var sliders: Array=[]
		var buttons: Array=[]
		for row in rows:
			for element in row:
				if element.type=="slider_h": sliders.append(element)
				else: buttons.append(element)
		rows=[sliders,buttons]
	var panel: Node3D = RackTpl.create_panel("" if comparison=="seed_witness" else "SEED REPLAY", rows,comparison=="seed_witness")
	panel.name = "Panel"
	panel.set_meta("em_local_instrument", true)   # its button areas are hand targets, not this body's footprint
	panel.position = Vector3(0, 0.12 + _lift, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	panel.scale = Vector3(1.5, 1.5, 1.5)   # 12 September: the labels read from the operating position
	add_child(panel)
	if comparison == "seed_witness": SeedStack.fit_controls(panel)
	_contrast_panel(panel)
	_contrast_panel.call_deferred(panel)   # and once more a frame later, for parts built on entering the tree

	# Seed slider (Param_0)
	var seed_slider: Node = panel.find_child("Param_0", true, false)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.set_range(0.0, 999.0)
		seed_slider.set("decimal_places", 0)
		seed_slider.slider_moved.connect(_on_seed_slider)
	var resolution: Node = panel.find_child("Param_1", true, false)
	if resolution:
		var choices: Array = []
		for side in range(MIN_SIDE, MAX_SIDE + 1): choices.append("%d x %d" % [side, side])
		resolution.set_choices(choices)
		resolution.slider_moved.connect(_on_resolution_slider)
		_sync_resolution_slider()

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
	var atmosphere_btn := panel.find_child("Btn_3", true, false)
	if atmosphere and atmosphere_btn:
		atmosphere_btn.get_node("InteractableAreaButton").button_pressed.connect(func(_b): request_atmospheric_seed())
	if mapping_study:
		var start := 4 if atmosphere else 3
		var callbacks := [cycle_mapping,toggle_mapping_range,reset_mapping]
		for index in range(3):
			var area: Node = panel.find_child("Btn_%d" % (start+index),true,false).get_node("InteractableAreaButton")
			area.button_pressed.connect(func(_b): callbacks[index].call())


func _build_atmosphere() -> void:
	if not (atmosphere or movement_seed) or is_instance_valid(_source_label): return
	if atmosphere:
		_atmosphere_client = AtmosphericSeed.new()
		add_child(_atmosphere_client)
		_atmosphere_client.received.connect(_receive_atmospheric_seed)
		_atmosphere_client.status_changed.connect(_show_seed_source)
	# A number seen from the doorway, with its provenance kept visibly beside it.
	var display := Node3D.new()
	display.name = "AtmosphereDisplay"
	display.position = Vector3(0, 3.85 if wall_display else 1.35 + _lift, 0.02)
	if not wall_display: display.scale = Vector3.ONE * 0.35
	add_child(display)
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 1.22, 0.06)
	plate.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.018, 0.029, 0.033)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = material
	display.add_child(plate)
	if comparison == "seed_witness": plate.visible=false
	_large_seed = Label3D.new()
	_large_seed.name = "LargeSeed"
	_large_seed.font_size = 200
	_large_seed.pixel_size = 0.0035
	_large_seed.modulate = Color(0.94, 0.98, 0.90)
	_large_seed.outline_size = 0
	_large_seed.position = Vector3(0, 0.16, 0.04)
	display.add_child(_large_seed)
	_source_label = Label3D.new()
	_source_label.name = "SeedSource"
	_source_label.font_size = 24
	_source_label.pixel_size = 0.002
	_source_label.outline_size = 0
	_source_label.position = Vector3(0, -0.35, 0.04)
	display.add_child(_source_label)
	if comparison == "seed_witness":
		_source_label.font_size=40
		_source_label.position.y=-0.48
		_source_label.width=1300
		_source_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_show_seed_source()


func _show_seed_source(message: String = "") -> void:
	if not is_instance_valid(_source_label): return
	_large_seed.text = str(_current_seed)
	var source := "Seed chosen locally"
	if _source_receipt.get("provider", "") == "RANDOM.ORG":
		var date := str(_source_receipt.get("received_utc", "")).get_slice("T", 0)
		source = "RANDOM.ORG · %s · atmospheric noise" % date
	var action := "ATMOSPHERE asks for 0–999 · REPLAY keeps the seed"
	if bool(_source_receipt.get("recorded", false)):
		action = "Saved draw · 0–999 · ATMOSPHERE asks again"
	if _source_receipt.get("provider", "") == "movement":
		var kind := "XR tracking" if _source_receipt.get("source", "") == "xr_tracking" else "Desktop movement"
		source = "%s · %d samples · seed 0–999" % [kind,int(_source_receipt.get("sample_count",0))]
		action = "Movement recorded · REPLAY repeats its colours"
	if _source_receipt.has("label"):
		source = str(_source_receipt.label) + " · seed 0–999"
	if not route_link.is_empty():
		action = "Kept seed → colours + journey · REPLAY returns to trip 1"
	if HallSeed.enabled(self): action = "Shared hall seed · choose a number or record a gesture · RESET 435 restores the opening"
	_source_label.text = source + "\n" + (message if not message.is_empty() else action)


func request_atmospheric_seed() -> bool:
	if HallSeed.enabled(self):
		HallSeed.reset(self)
		return false # The recorded arrival is reused; no HTTP request.
	if not atmosphere or not is_instance_valid(_atmosphere_client): return false
	if is_instance_valid(_movement_sampler) and _movement_sampler.collecting:
		_show_seed_source("Release the sphere before requesting another source")
		return false
	# Do not let a second press make an obsolete pending reply current again.
	if _atmosphere_client.is_busy(): return false
	_requested_revision = _seed_revision
	return _atmosphere_client.request_seed()


func _receive_atmospheric_seed(value: int, receipt: Dictionary) -> void:
	if HallSeed.enabled(self): return
	if _requested_revision != _seed_revision:
		_show_seed_source("Reply arrived after your edit — your chosen seed kept")
		return
	_current_seed = value
	_seed_revision += 1
	_source_receipt = receipt.duplicate(true)
	_regenerate()
	_sync_seed_slider()
	_note_action("ATMOSPHERE")
	_show_seed_source("Godot draws the colours · REPLAY keeps this pattern")
	seed_selected.emit(_current_seed, _source_receipt.duplicate(true))


func _receive_movement_seed(value: int, receipt: Dictionary) -> void:
	if HallSeed.enabled(self):
		HallSeed.choose(self,value,receipt); return
	_current_seed = value
	_seed_revision += 1
	_source_receipt = receipt.duplicate(true)
	_regenerate()
	_sync_seed_slider()
	_note_action("MOVEMENT")
	_show_seed_source()
	seed_selected.emit(_current_seed, _source_receipt.duplicate(true))


func _choose_local_seed() -> void:
	_seed_revision += 1
	_source_receipt.clear()
	if is_instance_valid(_movement_sampler) and _movement_sampler.collecting:
		_movement_sampler.cancel_capture("Seed edited; movement sample cancelled.")
	_show_seed_source()


# Compact museum staging reparents Panel beneath ReachConsole; locate its live slider.
func _on_seed_slider(_value) -> void:
	if _syncing_seed_slider:
		return
	var slider: Node = find_child("Param_0", true, false)
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = clampf(slider.get_normalized_value(), 0.0, 1.0)
		if HallSeed.enabled(self):
			if not HallSeed.choose(self,roundi(norm * 999.0)): _sync_seed_slider()
			return
		_current_seed = roundi(norm * 999.0)
		_choose_local_seed()
		_regenerate()
		_note_action("SLIDER")
		seed_selected.emit(_current_seed, _source_receipt.duplicate(true))


func _on_resolution_slider(_value) -> void:
	if _syncing_resolution: return
	var slider: Node = find_child("Param_1", true, false)
	if slider:
		set_grid_side(MIN_SIDE + roundi(slider.get_normalized_value() * (MAX_SIDE - MIN_SIDE)))


## Change cell count without moving the panel or drawing a new seed.
func set_grid_side(value: int) -> void:
	var side := clampi(value, MIN_SIDE, MAX_SIDE)
	if side != grid_cols or side != grid_rows:
		grid_cols = side
		grid_rows = side
		if _built: _rebuild_columns()
		_note_action("MATRIX %d x %d" % [side, side])
	_sync_resolution_slider()


func _sync_resolution_slider() -> void:
	var slider: Node = find_child("Param_1", true, false)
	if slider:
		_syncing_resolution = true
		slider.set_normalized_value(float(grid_cols - MIN_SIDE) / (MAX_SIDE - MIN_SIDE))
		_syncing_resolution = false


## Keep a programmatic seed update from being mistaken for a visitor's gesture.
func _sync_seed_slider() -> void:
	var slider: Node = find_child("Param_0", true, false)
	if slider and slider.has_method("set_normalized_value"):
		_syncing_seed_slider = true
		slider.set_normalized_value(clampf(float(_current_seed) / 999.0, 0.0, 1.0))
		_syncing_seed_slider = false


func _randomize_seed() -> void:
	if HallSeed.enabled(self):
		HallSeed.next(self); return
	_current_seed = _pick.randi() % 1000
	_choose_local_seed()
	_regenerate()
	_note_action("RANDOM")
	_sync_seed_slider()
	seed_selected.emit(_current_seed, _source_receipt.duplicate(true))


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


## Small, explicit visit state. The portal can unload the scene completely
## while retaining the visitor's experiment and RANDOM's next local draw.
func capture_museum_state() -> Dictionary:
	return {"seed": _current_seed, "extra_on": _extra_on,
		"mapping_mode": mapping_mode, "mapping_narrow": mapping_narrow,
		"pick_state": str(_pick.state), "last_action": _last_action, "side": grid_cols,
		"source_receipt": _source_receipt.duplicate(true),
		"source_bank": _journey.capture_state() if is_instance_valid(_journey) else {}}


func restore_museum_state(saved: Dictionary) -> void:
	if HallSeed.enabled(self):
		saved = saved.duplicate(true)
		if not HallSeed.choose(self,int(saved.get("seed",435)),saved.get("source_receipt",{})):
			saved["seed"] = HallSeed.current(self)
			saved["source_receipt"] = HallSeed.state(self).receipt.duplicate(true)
	if is_instance_valid(_movement_sampler) and _movement_sampler.collecting:
		_movement_sampler.cancel_capture("Saved visit restored; sample cancelled.")
	_current_seed = int(saved.get("seed", seed_value))
	_seed_revision += 1
	_source_receipt = saved.get("source_receipt", {}).duplicate(true)
	if is_instance_valid(_journey): _journey.restore_state(saved.get("source_bank", {}))
	_show_seed_source()
	_extra_on = bool(saved.get("extra_on", false))
	mapping_mode = clampi(int(saved.get("mapping_mode",0)),0,MAPPING_MODES.size()-1)
	mapping_narrow = bool(saved.get("mapping_narrow",false))
	if saved.has("pick_state"):
		_pick.state = int(saved.pick_state)
	if saved.has("side"): set_grid_side(int(saved.side))
	_regenerate()
	_sync_seed_slider()
	_note_action(String(saved.get("last_action", "RETURN")))
	seed_selected.emit(_current_seed, _source_receipt.duplicate(true))

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
		if sm.albedo_texture != null:
			# Keep the baked black lettering on its pale tag; room light must not wash it out.
			var tag_mat: StandardMaterial3D = sm.duplicate()
			tag_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.material_override = tag_mat
			continue
		if lum < 0.75 and not m.has_meta("seed_dark_plate"):
			continue
		var dm: StandardMaterial3D = sm.duplicate()
		dm.albedo_color = Color(0.14, 0.14, 0.16, 1.0)
		dm.roughness = 0.85
		dm.emission_energy_multiplier = 0.0
		dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = dm
		m.set_meta("seed_dark_plate", true)
	for l in p.find_children("*", "Label3D", true, false):
		var lb: Label3D = l
		lb.modulate = Color(0.95, 0.96, 1.0)
		lb.outline_size = 6
		lb.outline_modulate = Color(0, 0, 0, 1)
		if not lb.has_meta("seed_contrast_font"):
			lb.set_meta("seed_contrast_font", lb.font_size)
		# Retain the previous two-pass size without multiplying it on later passes.
		lb.font_size = roundi(roundf(float(lb.get_meta("seed_contrast_font")) * 1.35) * 1.35)

func replay() -> void:
	if HallSeed.enabled(self):
		HallSeed.choose(self,HallSeed.current(self),HallSeed.state(self).receipt)
		return
	_regenerate()
	_note_action("REPLAY")
	sequence_replayed.emit()

## The linked room keeps a receipt per source. Selection never resamples it.
func use_kept_seed(value: int, receipt: Dictionary) -> void:
	if HallSeed.enabled(self):
		HallSeed.choose(self,value,receipt); return
	_current_seed = clampi(value, 0, 999)
	_seed_revision += 1
	if is_instance_valid(_movement_sampler) and _movement_sampler.collecting:
		_movement_sampler.cancel_capture("Source changed; previous recording kept.")
	_source_receipt = receipt.duplicate(true)
	_regenerate()
	_sync_seed_slider()
	_note_action("KEPT SOURCE")
	_show_seed_source()
	seed_selected.emit(_current_seed, _source_receipt.duplicate(true))

func randomize_seed() -> void:
	_randomize_seed()


## GUARDED: rebuilds only when a DNA value actually CHANGED, and only after
## _ready has built the columns once. Shipped, this was `pass` — so nothing in
## the corpus has ever reached it, and nothing in the corpus moves now.
func _place_editor_parts() -> void:
	if is_instance_valid(_journey):
		_journey.apply_part_layout()
	elif is_instance_valid(_movement_sampler):
		EDITOR_PARTS.place(self, _movement_sampler, "movement_sampler",
			global_transform * Transform3D(Basis.IDENTITY, Vector3(-1.65, 0, 0.95)))

func apply_grid_config(config: Dictionary) -> void:
	if config.has("hall_seed"): set_meta("config_hall_seed",config.hall_seed)
	var layout_changed := false
	for key in ["part_movement_sampler", "part_frame_timing", "part_source_console",
		"part_movement_sampler_removed", "part_frame_timing_removed", "part_source_console_removed"]:
		if config.has(key) and _part_layout.get(key) != config[key]:
			_part_layout[key] = config[key]
			layout_changed = true
	if layout_changed and _built:
		_place_editor_parts.call_deferred()
	if config.is_empty():
		return
	# Placement configuration arrives before _ready; ordinary benches stay offline.
	if not _built and config.has("atmosphere"):
		atmosphere = str(config.atmosphere).to_lower() in ["true", "1"]
	if not _built and config.has("recorded_atmosphere"):
		recorded_atmosphere = str(config.recorded_atmosphere).to_lower() in ["true", "1"]
	if not _built and config.has("movement_seed"):
		movement_seed = str(config.movement_seed).to_lower() in ["true", "1"]
	if not _built and config.has("route_link"):
		route_link = str(config.route_link)
	if not _built and config.has("mapping_study"):
		mapping_study = str(config.mapping_study).to_lower() in ["true","1"]

	var changed: bool = false
	if config.has("surface") and str(config.surface) in ["solid","glass"] and surface!=str(config.surface):
		surface=str(config.surface)
		changed=true
	if config.has("display") and str(config["display"]) == "wall" and not wall_display:
		wall_display = true
		cube_size = 0.14; cube_gap = 0.015
		_grid_width = 0.0
		_grid_height = 0.0
		changed = true

	# A hall can start with fewer, larger cells without shrinking its panels.
	# The MATRIX slider continues to resize this same retained footprint.
	if config.has("side"):
		var side := clampi(int(config["side"]), MIN_SIDE, MAX_SIDE)
		if _grid_width == 0.0:
			_grid_width = grid_cols * (cube_size + cube_gap) - cube_gap
			_grid_height = grid_rows * (cube_size + cube_gap) - cube_gap
			_reference_cube_size = cube_size
		if side != grid_cols or side != grid_rows:
			grid_cols = side
			grid_rows = side
			changed = true

	if config.has("comparison"):
		var c: String = str(config["comparison"]).strip_edges().to_lower()
		if COMPARISONS.has(c) and c != comparison:
			comparison = c
			changed = true

	if config.has("seed") and not (_built and HallSeed.enabled(self)):
		var s: int = int(config["seed"])
		if s != _current_seed:
			seed_value = s
			_current_seed = s
			_choose_local_seed()
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
