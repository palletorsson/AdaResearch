extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VectorMachine

## @identity
## lineage: the dial of gravity — a workbench that aims and sizes the one vector ruling every
##   force_field in the room. Point it down for the void to swallow; tilt it up-and-across to
##   turn the void into a bridge.
## essence: three sliders — PITCH (down ↔ up), YAW (which way across), FORCE (how hard) —
##   compose a single force vector, drawn live as a big arrow on the stage, and pushed straight
##   into every force_field. The default is gravity: straight down, 9.8.
## truth: a field is only ever as dangerous as the vector you hand it; this bench is where the
##   danger is chosen.
##
## Built on the shared InterfacePresets "workbench" housing (the Reformed_Instruments look):
## a tilted slider plate + a floating viz stage. Slider values are polled each frame (the
## workbench pattern), the vector pushed to group "force_field" via set_field_vector().

const InterfacePresets := preload("res://commons/ui/interface_presets.gd")

@export var force_max: float = 15.0
@export var plate_height: float = 0.95
@export var skin: String = "braun"
@export var arrow_color: Color = Color(0.92, 0.45, 0.12)     # braun accent

var _console: Node3D
var _sliders: Array = []
var _readout
var _preview: Node3D
var _arrow_mat: StandardMaterial3D
var _last_v: Vector3 = Vector3.INF


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build()
	set_process(true)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("force_max"): force_max = float(config_data["force_max"])
	if config_data.has("skin"): skin = String(config_data["skin"])
	arrow_color = _parse_color(config_data.get("arrow_color", arrow_color), arrow_color)
	if _console == null:
		_build()


func _build() -> void:
	_console = InterfacePresets.build("workbench", "VECTOR MACHINE", plate_height, skin)
	add_child(_console)
	if _console.has_method("add_readout"):
		_readout = _console.add_readout("")
	for nm in ["PITCH", "YAW", "FORCE"]:
		if _console.has_method("add_slider"):
			_sliders.append(_console.add_slider(nm, nm))
	# defaults: pitch = straight down, yaw = 0, force = 9.8 → gravity, down
	_set_slider(0, 0.0)
	_set_slider(1, 0.0)
	_set_slider(2, 9.8 / force_max)

	# the live preview arrow on the workbench's floating stage
	var anchor: Node3D = _console
	if _console.has_method("viz_anchor"):
		var a = _console.viz_anchor()
		if a is Node3D: anchor = a
	_preview = Node3D.new(); _preview.name = "VectorPreview"
	anchor.add_child(_preview)
	_arrow_mat = _glow_mat(arrow_color, 2.0)
	_last_v = Vector3.INF
	_update()


func _set_slider(i: int, val: float) -> void:
	if i < _sliders.size() and _sliders[i] and _sliders[i].has_method("set_normalized_value"):
		_sliders[i].call("set_normalized_value", val)


func _norm(i: int) -> float:
	if i < _sliders.size() and _sliders[i] and _sliders[i].has_method("get_normalized_value"):
		return clampf(float(_sliders[i].call("get_normalized_value")), 0.0, 1.0)
	return 0.0


func current_vector() -> Vector3:
	var pitch: float = lerpf(-PI * 0.5, PI * 0.5, _norm(0))      # down ↔ up
	var yaw: float = _norm(1) * TAU
	var mag: float = _norm(2) * force_max
	return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag


# poll the sliders each frame (workbench pattern — no signal-timing dependency)
func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var v := current_vector()
	if v.distance_to(_last_v) < 0.02:
		return
	_last_v = v
	var mag: float = v.length()
	if _preview:
		for ch in _preview.get_children():
			_preview.remove_child(ch); ch.queue_free()
		if mag > 0.001:
			_preview.add_child(_arrow(Vector3.ZERO, v.normalized() * clampf(mag / 9.8, 0.4, 2.0) * 0.5, 0.04, _arrow_mat))
	if _readout:
		var dy: float = v.y
		var word: String = "DOWN — fall" if dy < -1.0 else ("UP — lift" if dy > 1.0 else "ACROSS")
		_readout.set("text", "F = (%.1f, %.1f, %.1f)\n|F| = %.1f   %s" % [v.x, v.y, v.z, mag, word])
	for f in get_tree().get_nodes_in_group("force_field"):
		if f.has_method("set_field_vector"):
			f.set_field_vector(v)
