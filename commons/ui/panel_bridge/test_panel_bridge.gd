## Demo scene for the Panel Bridge system.
##
## Press number keys 1–4 to switch between example panel sets:
##   1  4-shaft twill (loom)
##   2  8-shaft overshot (loom)
##   3  P4M square domain (pattern maker)
##   4  P6M hex rosette (pattern maker)
##
## Works in both desktop (mouse) and VR (controller pointer).
extends Node3D

const SAMPLE_DIR := "res://commons/ui/panel_bridge/sample_data/"

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

	# Wait for panels to build, then print diagnostics
	await get_tree().process_frame
	await get_tree().process_frame
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
