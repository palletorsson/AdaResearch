## Demo scene for the Panel Bridge system.
##
## Press number keys 1–4 to switch between example panel sets:
##   1  4-shaft twill (loom)
##   2  8-shaft overshot (loom)
##   3  P4M square domain (pattern maker)
##   4  P6M hex rosette (pattern maker)
##
## Works in both desktop (mouse) and VR (controller pointer).
##
## STAGE-2 DNA PROMOTION (2026-07-29). Before this the artifact had no exports: it
## loaded example 0 — the shipped 4-shaft twill sample — and every placement in the
## project showed the same cloth. The constants worth lifting are not in the panel
## chrome but in the draft the panels display, and a weaving draft has exactly two
## orders in it: the order the warps are drawn onto the shafts, and the order the
## picks press the treadles. The tie-up sits between them and is left alone.
##
##   threading_draw    order warps are drawn onto shafts   straight · point · block · broken
##   treadling_order   order picks press the treadles      straight · point · block · broken
##
## This is the axis a loom actually has. straight/straight is the sample's own
## twill diagonal; point in the warp is a herringbone; point in both is a diamond
## twill — same tie-up, same threads, a different cloth. It makes the drawdown
## argue that the diagonal is not IN the tie-up, it is in the order of the draw.
##
## Both defaults are "straight", and the straight/straight case returns before
## touching the data store at all, so the draft is the sample file byte-for-byte
## and the 6 existing placements are unchanged.
##
## Usage in map_data.json:
##   "panel_bridge_loom#threading_draw:point"                          — herringbone
##   "panel_bridge_loom#threading_draw:point#treadling_order:point"    — diamond twill
extends Node3D

const SAMPLE_DIR := "res://commons/ui/panel_bridge/sample_data/"

## Order in which warps are drawn onto the shafts. "straight" leaves the loaded
## draft exactly as its JSON wrote it (for the shipped sample, a 1-2-3-4 straight
## draw). point zigzags back down (herringbone), block doubles each shaft, broken
## reverses direction every repeat without sharing the turning thread.
@export_enum("straight", "point", "block", "broken") var threading_draw: String = "straight"
## Order in which picks press the treadles — the same four orders, read down the
## cloth instead of across it. "straight" leaves the loaded draft untouched.
@export_enum("straight", "point", "block", "broken") var treadling_order: String = "straight"

@onready var panel_bridge: PanelBridgeLoader = $PanelBridgeLoader

## Example definitions: [display_name, layout_path, data_path]
var examples: Array = [
	["4-Shaft Twill",     SAMPLE_DIR + "loom_panel_layout.json",        SAMPLE_DIR + "loom_draft_data.json"],
	["8-Shaft Overshot",  SAMPLE_DIR + "loom_overshot_layout.json",     SAMPLE_DIR + "loom_overshot_data.json"],
	["P4M Square Domain", SAMPLE_DIR + "pattern_maker_layout.json",     SAMPLE_DIR + "pattern_maker_data.json"],
	["P6M Hex Rosette",   SAMPLE_DIR + "pattern_maker_hex_layout.json", SAMPLE_DIR + "pattern_maker_hex_data.json"],
]

var current_example: int = -1
var _info_label: Label


## Config injection for capture_with_config.gd audit loop, plus the two DNA axes.
## Detects tool type from config keys and loads the matching panel layout.
##
## The axis keys are peeled off FIRST. A map token like
## "panel_bridge_loom#threading_draw:point" carries nothing else, and the capture
## path below would write that dict out as the draft data — blanking the drawdown.
## An axis-only config therefore never reaches it: it reweaves in place instead,
## and only when a value actually changed and _ready has already loaded once.
func apply_grid_config(config_data: Dictionary) -> void:
	var axes_changed: bool = false
	if config_data.has("threading_draw"):
		var wanted_warp: String = str(config_data["threading_draw"])
		if wanted_warp != threading_draw:
			threading_draw = wanted_warp
			axes_changed = true
	if config_data.has("treadling_order"):
		var wanted_weft: String = str(config_data["treadling_order"])
		if wanted_weft != treadling_order:
			treadling_order = wanted_weft
			axes_changed = true

	var rest: Dictionary = config_data.duplicate(true)
	rest.erase("threading_draw")
	rest.erase("treadling_order")
	if rest.is_empty():
		if axes_changed and current_example >= 0 and panel_bridge != null:
			_load_example(current_example)
		return
	config_data = rest

	# Write config to temp file for PanelBridgeLoader
	var tmp_dir := "user://tmp"
	if not DirAccess.dir_exists_absolute(tmp_dir):
		DirAccess.make_dir_recursive_absolute(tmp_dir)

	var tmp_path := tmp_dir + "/capture_data.json"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error("test_panel_bridge: Cannot write temp data to %s" % tmp_path)
		return
	file.store_string(JSON.stringify(config_data))
	file.close()

	# Detect tool type from config keys and pick layout
	var layout_path: String
	var tool_name: String

	if config_data.has("wallpaper_group") or config_data.has("tile_size"):
		# --- Pattern Maker ---
		tool_name = "pattern_maker"
		layout_path = SAMPLE_DIR + "pattern_maker_layout.json"
		print("test_panel_bridge: apply_grid_config [pattern_maker] group=%s size=%s" % [
			config_data.get("wallpaper_group", "?"),
			config_data.get("tile_size", "?"),
		])
	elif config_data.has("placements") or config_data.has("grid_size"):
		# --- Grid Editor ---
		tool_name = "grid_editor"
		layout_path = SAMPLE_DIR + "grid_editor_layout.json"
		var placements: Array = config_data.get("placements", [])
		print("test_panel_bridge: apply_grid_config [grid_editor] %d placements" % placements.size())
	else:
		# --- Loom (default) ---
		tool_name = "loom"
		var shaft_count: int = config_data.get("shafts", 4) as int
		if shaft_count > 4:
			layout_path = SAMPLE_DIR + "loom_overshot_layout.json"
		else:
			layout_path = SAMPLE_DIR + "loom_panel_layout.json"
		print("test_panel_bridge: apply_grid_config [loom] %d shafts, %d warps, %d picks" % [
			shaft_count,
			config_data.get("warps", 0),
			config_data.get("picks", 0),
		])

	panel_bridge.layout_json_path = layout_path
	panel_bridge.data_json_path = tmp_path
	panel_bridge.load_panels()

	# Add CaptureCamera — panels are at y=1.4, z=-0.65 in arc
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 50.0
	cam.position = Vector3(0.0, 1.4, 0.5)
	cam.look_at(Vector3(0.0, 1.4, -0.65), Vector3.UP)
	add_child(cam)

	_apply_draw_axes_deferred()

	print("test_panel_bridge: loaded %s layout" % tool_name)


func _ready() -> void:
	# Create an on-screen info label (visible in desktop mode)
	_create_info_label()

	# Load first example
	_load_example(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		match key.keycode:
			KEY_1:
				_load_example(0)
			KEY_2:
				_load_example(1)
			KEY_3:
				_load_example(2)
			KEY_4:
				_load_example(3)
			KEY_R:
				# Reload current example
				if current_example >= 0:
					_load_example(current_example)


func _load_example(idx: int) -> void:
	if idx < 0 or idx >= examples.size():
		return

	current_example = idx
	var example: Array = examples[idx]
	var display_name: String = example[0]
	var layout_path: String = example[1]
	var data_path: String = example[2]

	print("--- Loading example %d: %s ---" % [idx + 1, display_name])

	panel_bridge.layout_json_path = layout_path
	panel_bridge.data_json_path = data_path
	panel_bridge.load_panels()

	# Wait for panels to build, then apply the DNA axes and print diagnostics
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_draw_axes()
	_print_diagnostics(display_name)
	_update_info_label(display_name)


func _print_diagnostics(name: String) -> void:
	print("  Panels: %d" % panel_bridge.panel_instances.size())

	if panel_bridge.data_store:
		var ds := panel_bridge.data_store
		print("  Data store: %d warps, %d picks, %d shafts, %d treadles" % [
			ds.warps, ds.picks, ds.shafts, ds.treadles
		])
		print("  drawdown[0,0] = %d" % ds.get_drawdown(0, 0))
	else:
		print("  Data store: null (pattern maker mode)")

	# Report overlay elements
	for inst in panel_bridge.panel_instances:
		if inst.overlay_elements.size() > 0:
			print("  Panel '%s' overlays: %s" % [
				inst.panel_def.get("id", "?"),
				str(inst.overlay_elements.map(func(e): return e.get("overlay_3d", "")))
			])


# ── DNA axes: threading_draw / treadling_order ──────────────────

## Wait for the panels to finish building, then reweave. Used by the config path,
## which is not a coroutine.
func _apply_draw_axes_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_draw_axes()


## Rewrite the loaded draft's threading and treadling with the declared draw
## orders. The tie-up and the colours are never touched — the axes change the
## ORDER of the draw, not the loom's wiring or its yarn.
func _apply_draw_axes() -> void:
	# Default: the draft exactly as its JSON wrote it, not one cell rewritten.
	if threading_draw == "straight" and treadling_order == "straight":
		return
	if panel_bridge == null:
		return
	var store: DraftDataStore = panel_bridge.data_store
	if store == null:
		return  # pattern_maker / grid_editor pages carry no draft
	var draft: Dictionary = store.to_dict()
	if threading_draw != "straight":
		draft["threading"] = _redraw(draft.get("threading", []), threading_draw)
	if treadling_order != "straight":
		draft["treadling"] = _redraw(draft.get("treadling", []), treadling_order)
	store.load_from_dict(draft)
	print("test_panel_bridge: reweave threading=%s treadling=%s" % [threading_draw, treadling_order])


## Rewrite a one-hot matrix (each row lights exactly one column) with a new draw
## order. Row count and column count are kept, and only the columns the loaded
## draft actually used are reused — so a 4-shaft draft stays a 4-shaft draft even
## though the loom has 6 treadles wired.
func _redraw(matrix: Array, draw: String) -> Array:
	var rows: int = matrix.size()
	if rows == 0:
		return matrix
	var cols: int = 0
	var period: int = 0
	for r in rows:
		var row: Array = matrix[r]
		cols = maxi(cols, row.size())
		for c in row.size():
			if int(row[c]) != 0:
				period = maxi(period, c + 1)
	if period < 2 or cols == 0:
		return matrix
	var out: Array = []
	for r in rows:
		var new_row: Array = []
		for c in cols:
			new_row.append(0)
		var col: int = _draw_index(draw, r, period)
		if col >= 0 and col < cols:
			new_row[col] = 1
		out.append(new_row)
	return out


## Which column row [param i] lights, for a draw of period [param n].
func _draw_index(draw: String, i: int, n: int) -> int:
	match draw:
		"point":
			# Zigzag that shares its turning thread: 0,1,2,3,2,1 — a herringbone.
			var span: int = 2 * n - 2
			var k: int = i % span
			return k if k < n else span - k
		"block":
			# Each shaft taken twice before moving on: 0,0,1,1,2,2,3,3.
			var pair: int = floori(float(i) / 2.0)
			return pair % n
		"broken":
			# Straight, but the direction flips every repeat with no shared thread.
			var group: int = floori(float(i) / float(n))
			var step: int = i % n
			return step if group % 2 == 0 else n - 1 - step
	return i % n


## Create a 2D overlay Label for displaying current example info.
func _create_info_label() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "InfoOverlay"
	add_child(canvas)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.position = Vector2(12, 12)
	_info_label.add_theme_color_override("font_color", Color(0.0, 0.78, 0.85))
	_info_label.add_theme_font_size_override("font_size", 16)
	_info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_info_label.add_theme_constant_override("shadow_offset_x", 1)
	_info_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(_info_label)


func _update_info_label(display_name: String) -> void:
	if not _info_label:
		return

	var lines := PackedStringArray()
	lines.append("Panel Bridge Demo")
	lines.append("")

	for i in examples.size():
		var prefix := "> " if i == current_example else "  "
		lines.append("%s[%d] %s" % [prefix, i + 1, examples[i][0]])

	lines.append("")
	lines.append("  [R] Reload current")
	lines.append("")
	lines.append("Current: %s" % display_name)

	_info_label.text = "\n".join(lines)
