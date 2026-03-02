## Row of clickable operation buttons for the VR panel bridge.
##
## Reads "actions" from JSON metadata and creates a grid of Buttons.
## When clicked (mouse or VR pointer), emits [signal operation_pressed]
## and optionally calls [method ColorGridWidget.execute_operation] on a
## connected target widget.
##
## Button labels use short display names derived from action IDs.
class_name OperationsBarWidget
extends Control

const P = preload("res://commons/ui/ada_palette.gd")

# ── Signals ──────────────────────────────────────────────────────

## Emitted when any operation button is pressed.
signal operation_pressed(action_name: String)

# ── Configuration ───────────────────────────────────────────────

## The target widget to call execute_operation() on (ColorGridWidget for pattern maker).
## Set by PanelContentBuilder after building the panel.
var target_widget: Node = null

## The data store to call execute_operation() on (DraftDataStore for loom pages).
## Set by PanelBridgeLoader after building panels.
var data_store: DraftDataStore = null

## Action names from JSON metadata.
var actions: PackedStringArray = PackedStringArray()

# ── Internal ─────────────────────────────────────────────────────

var _buttons: Array[Button] = []


# ── Setup ────────────────────────────────────────────────────────

## Build the button grid from an array of action name strings.
func setup(p_actions: Array, p_target: Node = null) -> void:
	target_widget = p_target
	actions.clear()
	for a in p_actions:
		actions.append(str(a))
	_build_buttons()


func _build_buttons() -> void:
	# Clear existing
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_buttons.clear()

	if actions.is_empty():
		return

	# Use a GridContainer for automatic wrapping
	var grid := GridContainer.new()
	grid.name = "ButtonGrid"
	grid.columns = mini(actions.size(), 5)  # max 5 per row
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	add_child(grid)

	# Style for buttons
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.22, 0.24, 0.32)
	normal_style.border_color = Color(0.40, 0.43, 0.52)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	normal_style.set_content_margin_all(4)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.28, 0.32, 0.42)
	hover_style.border_color = P.ACCENT_CYAN
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	hover_style.set_content_margin_all(4)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.16, 0.18, 0.26)
	pressed_style.border_color = P.ACCENT_CYAN
	pressed_style.set_border_width_all(1)
	pressed_style.set_corner_radius_all(P.CORNER_RADIUS_SM)
	pressed_style.set_content_margin_all(4)

	for action_name in actions:
		var btn := Button.new()
		btn.text = _action_label(action_name)
		btn.tooltip_text = action_name
		btn.custom_minimum_size = Vector2(48, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Apply styles
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_color_override("font_color", P.TEXT_ON_DARK)
		btn.add_theme_color_override("font_hover_color", P.ACCENT_CYAN)
		btn.add_theme_color_override("font_pressed_color", P.ACCENT_CYAN)
		btn.add_theme_font_size_override("font_size", P.FONT_SIZE_SMALL)

		# Connect via lambda capturing action_name
		btn.pressed.connect(_on_button_pressed.bind(action_name))

		grid.add_child(btn)
		_buttons.append(btn)


func _on_button_pressed(action_name: String) -> void:
	operation_pressed.emit(action_name)

	# Try target widget first (ColorGridWidget for pattern maker)
	if target_widget and target_widget.has_method("execute_operation"):
		target_widget.execute_operation(action_name)
	# Fall back to data store (DraftDataStore for loom pages)
	elif data_store:
		data_store.execute_operation(action_name)


# ── Display name mapping ─────────────────────────────────────────

## Convert action ID to a short button label.
static func _action_label(action_name: String) -> String:
	match action_name:
		"mirror_x":          return "↔ MirX"
		"mirror_y":          return "↕ MirY"
		"rotate_cw":         return "↻ RotR"
		"rotate_ccw":        return "↺ RotL"
		"invert":            return "◐ Inv"
		"shift_l":           return "← Shift"
		"shift_r":           return "→ Shift"
		"shift_u":           return "↑ Shift"
		"shift_d":           return "↓ Shift"
		"clear":             return "✕ Clear"
		"export_json":       return "JSON"
		"export_png":        return "PNG"
		"copy_array":        return "Copy"
		"export_panel_layout": return "Layout"
		"mirror_threading":    return "↔ Thread"
		"mirror_treadling":    return "↕ Treadl"
		"invert_tieup":        return "◐ Tieup"
		"invert_threading":    return "◐ Thread"
		"invert_treadling":    return "◐ Treadl"
		"shift_threading_l":   return "← Thread"
		"shift_threading_r":   return "→ Thread"
		"shift_treadling_u":   return "↑ Treadl"
		"shift_treadling_d":   return "↓ Treadl"
		"rotate_tieup_cw":     return "↻ Tieup"
		_:
			# Fallback: capitalize action name
			return action_name.replace("_", " ").capitalize()
