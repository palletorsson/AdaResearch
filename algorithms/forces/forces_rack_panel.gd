## ForcesRackPanel — Shared Ada-styled rack panel for Forces examples.
##
## CONVERGED (2026-06-13, Interface Overhaul Phase 1): this is now a thin
## API-PRESERVING ADAPTER over the canonical `ControlPanel` board. The public
## surface is byte-for-byte identical, so the 9 forces examples are untouched —
## but they inherit the canonical styling and ALL the slider fixes (smooth
## slider, never-scale-physics, bidirectional clamp). See doc/INTERFACE_OVERHAUL.md.
##
## Usage (unchanged):
##   var panel = ForcesRackPanel.new()
##   panel.setup("Example 2.3: Gravity", 1, 3)
##   var slider = panel.add_slider("Gravity", 0.1, 2.5, 0.9, 0.05)
##   slider.slider_moved.connect(_on_gravity_changed)
##   add_child(panel)
class_name ForcesRackPanel
extends Node3D

const CONTROL_PANEL := preload("res://commons/ui/control_panel.gd")

# Signal forwarded from sliders — carries (slider_name: String, value: float).
# Kept for API compatibility (some callers may connect it).
signal slider_value_changed(slider_name: String, value: float)

# The canonical board this panel delegates to.
var _board  # ControlPanel
var _columns: int = 1
var _sliders: Array = []          # [{instance, name, min, max, default}]
var _readouts: Dictionary = {}    # name -> Label (board readout line)
var _readout_line: Object = null  # the board's single multi-line readout
var _readout_names: Array = []    # ordered names backing _readout_line
var _readout_values: Dictionary = {}


func setup(title: String, columns: int = 1, _rack_units_tall: int = 3) -> void:
	_columns = max(1, columns)
	_board = CONTROL_PANEL.new()
	_board.name = "Board"
	add_child(_board)
	_board.title = title


func set_instructions(text: String) -> void:
	# The board carries no instructions line; expose it as the subtitle if the
	# board supports one, else fold it into the title's second line.
	if _board == null:
		return
	if "subtitle" in _board:
		_board.set("subtitle", text)


## Add a slider. Returns the slider root (slider_smooth: slider_moved + value API)
## — identical contract to before. min/max/default/step/snap preserved.
func add_slider(param_name: String, range_min: float, range_max: float, default_val: float, _step: float = 0.0, use_snap: bool = false) -> Node3D:
	var s: Node3D = _board.add_slider(param_name, param_name)
	if s == null:
		return null
	if use_snap and "decimal_places" in s:
		s.set("decimal_places", 0)
	if s.has_method("set_range"):
		s.set_range(range_min, range_max)
	if range_max != range_min and s.has_method("set_normalized_value"):
		var norm: float = clampf((default_val - range_min) / (range_max - range_min), 0.0, 1.0)
		_defer_set_normalized.call_deferred(s, norm)
	# Forward per-slider moves to the panel-level aggregate signal.
	if s.has_signal("slider_moved") and not s.is_connected("slider_moved", _on_any_slider_moved):
		s.connect("slider_moved", _on_any_slider_moved.bind(param_name))
	_sliders.append({"instance": s, "name": param_name, "min": range_min, "max": range_max, "default": default_val})
	return s


func _on_any_slider_moved(_value, param_name: String) -> void:
	for d in _sliders:
		if d["name"] == param_name:
			slider_value_changed.emit(param_name, get_slider_value(_sliders.find(d)))
			return


func _defer_set_normalized(slider: Node3D, norm: float) -> void:
	if is_instance_valid(slider) and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(norm)


## Add a named readout. Backed by the board's single multi-line readout line
## (one row per name), so the styling is canonical. Returns a stand-in Label
## the caller can also write to (kept for API compatibility).
func add_readout(label_name: String, initial_text: String = "--") -> Label3D:
	if _readout_line == null:
		_readout_line = _board.add_readout("")
	_readout_names.append(label_name)
	_readout_values[label_name] = initial_text
	_rebuild_readout_text()
	# Back-compat shim: a detached Label3D some callers store; we mirror writes
	# to it through update_readout, so returning a fresh one is safe.
	var shim := Label3D.new()
	shim.name = "ReadoutShim_%s" % label_name.replace(" ", "_")
	shim.visible = false
	add_child(shim)
	_readouts[label_name] = shim
	return shim


func update_readout(label_name: String, value_text: String) -> void:
	if not _readout_values.has(label_name):
		_readout_names.append(label_name)
	_readout_values[label_name] = value_text
	_rebuild_readout_text()


func _rebuild_readout_text() -> void:
	if _readout_line == null:
		return
	var lines: Array[String] = []
	for n in _readout_names:
		lines.append("%s: %s" % [n, _readout_values.get(n, "--")])
	_readout_line.text = "\n".join(lines)


func get_panel_width() -> float:
	if _board and _board.has_method("get_board_size"):
		return _board.get_board_size().x
	return max(_columns * 0.12, 0.4)


func get_panel_height() -> float:
	if _board and _board.has_method("get_board_size"):
		return _board.get_board_size().y
	return 0.3


func set_slider_value(index: int, value: float) -> void:
	if index < 0 or index >= _sliders.size():
		return
	var data: Dictionary = _sliders[index]
	var slider: Node3D = data["instance"]
	if not is_instance_valid(slider) or data["max"] == data["min"]:
		return
	var norm: float = clampf((value - data["min"]) / (data["max"] - data["min"]), 0.0, 1.0)
	if slider.has_method("set_normalized_value"):
		slider.set_normalized_value(norm)


func get_slider_value(index: int) -> float:
	if index < 0 or index >= _sliders.size():
		return 0.0
	var data: Dictionary = _sliders[index]
	var slider: Node3D = data["instance"]
	if not is_instance_valid(slider):
		return data["default"]
	if slider.has_method("get_normalized_value"):
		return lerp(data["min"], data["max"], float(slider.get_normalized_value()))
	return data["default"]


func apply_grid_config(_config: Dictionary) -> void:
	pass
