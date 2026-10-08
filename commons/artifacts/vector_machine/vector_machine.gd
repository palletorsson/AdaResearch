extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VectorMachine

## @identity
## lineage: the dial of local acceleration — a workbench that aims and sizes the vector
##   supplied to compatible force_field zones. A crossing depends on the receiver's incoming
##   movement, contact and controller as well as this setting.
## essence: PITCH and YAW compose a direction; the magnitude slider supplies acceleration.
##   The default is 9.8 m/s² downward. The force_as_place lesson labels the slider ACCEL and
##   publishes only to lesson zones in the same museum hall. Legacy controls retain FORCE/F
##   labels and publish to unscoped zones; the velocity update still treats the vector as acceleration.
## truth: a vector setting becomes motion only through the receiving zone and body controller.
##
## Built on the shared InterfacePresets "workbench" housing (the Reformed_Instruments look):
## a tilted slider plate + a floating viz stage. Slider values are polled each frame (the
## workbench pattern), the acceleration published through set_field_vector() with the scope above.

const InterfacePresets := preload("res://commons/ui/interface_presets.gd")

@export var force_max: float = 15.0
@export var plate_height: float = 0.95
@export var skin: String = "braun"
@export var arrow_color: Color = Color(0.92, 0.45, 0.12)     # braun accent

var _console: Node3D
var _sliders: Array = []
var _readout
var _preview: Node3D
var _ghost_mat: StandardMaterial3D
var _arrow_mat: StandardMaterial3D
var _last_v: Vector3 = Vector3.INF
var _last_yaw: float = -1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build()
	set_process(true)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("force_max"): force_max = float(config_data["force_max"])
	if config_data.has("skin"): skin = String(config_data["skin"])
	arrow_color = _parse_color(config_data.get("arrow_color", arrow_color), arrow_color)
	if _console == null and is_inside_tree():
		_build()


func _build() -> void:
	if _console != null: return
	_console = InterfacePresets.build("workbench", "VECTOR MACHINE", plate_height, skin)
	if is_carry_lesson(): _console.position.y = plate_height
	add_child(_console)
	if is_carry_lesson():
		# Support the desktop-form cabinet at standing reach.
		var foot = _box(Vector3(0, 0.18, 0), Vector3(0.60, 0.36, 0.42), _matte_mat(Color(0.21, 0.24, 0.29), 0.8))
		add_child(foot)
	if _console.has_method("add_readout"):
		_readout = _console.add_readout("")
	for nm in ["PITCH", "YAW", "ACCEL" if is_carry_lesson() else "FORCE"]:
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


## The azimuth the YAW fader is currently holding, in degrees, whether or not it
## is reaching the field. 0 is +Z, 90 is +X.
func _yaw_deg() -> float:
	return rad_to_deg(_norm(1) * TAU)


## True when PITCH is near enough to a pole that the yaw term is multiplied out.
## The threshold is where a full turn of the yaw fader moves the field by less
## than a tenth of its magnitude, which is the point at which a visitor cannot
## see the difference.
func _yaw_idle() -> bool:
	var pitch: float = lerpf(-PI * 0.5, PI * 0.5, _norm(0))
	return absf(cos(pitch)) < 0.1


## Where the field WILL point once the pitch comes off the pole. Drawn as a
## ghost so the yaw fader shows its work while it is idle: you can aim before
## you lift, which is the order the room's own crossing wants.
func _yaw_ghost() -> Vector3:
	var yaw: float = _norm(1) * TAU
	return Vector3(sin(yaw), 0.0, cos(yaw))


# poll the sliders each frame (workbench pattern — no signal-timing dependency)
func _process(_delta: float) -> void:
	_update()
	if is_carry_lesson(): _publish(current_vector()) # Also bind fields loaded after the bench.


func _update() -> void:
	var v := current_vector()
	# The early return watches the FIELD, and at a pole the yaw fader does not
	# change the field. Watching only v would have frozen the ghost arrow at
	# whatever azimuth was set when the vector last moved, which is the same
	# silent-nothing-happens the ghost exists to cure, one level up. So watch
	# the yaw as well while it is idle.
	var yaw_now: float = _norm(1)
	if v.distance_to(_last_v) < 0.02 and absf(yaw_now - _last_yaw) < 0.005:
		return
	_last_v = v
	_last_yaw = yaw_now
	var mag: float = v.length()
	if _preview:
		for ch in _preview.get_children():
			_preview.remove_child(ch); ch.queue_free()
		if mag > 0.001:
			_preview.add_child(_arrow(Vector3.ZERO, v.normalized() * clampf(mag / 9.8, 0.4, 2.0) * 0.5, 0.04, _arrow_mat))
		# The ghost: a dim horizontal arrow showing the azimuth the yaw fader is
		# holding. It is only worth drawing while yaw is idle, because that is
		# exactly when the live arrow cannot show it.
		if _yaw_idle():
			if _ghost_mat == null:
				_ghost_mat = _glow_mat(Color(arrow_color, 0.35), 0.5)
			_preview.add_child(_arrow(Vector3.ZERO, _yaw_ghost() * 0.30, 0.02, _ghost_mat))
	if _readout:
		var dy: float = v.y
		var word: String = "DOWN — fall" if dy < -1.0 else ("UP — lift" if dy > 1.0 else "ACROSS")
		var txt := "F = (%.1f, %.1f, %.1f)\n|F| = %.1f   %s" % [v.x, v.y, v.z, mag, word]
		# SAY WHEN A CONTROL HAS NOTHING TO DO. Both horizontal terms carry a
		# cos(pitch), so at either end of the PITCH travel the field is vertical
		# and the whole 14 cm of YAW changes nothing. That is not a fault, it is
		# what two angles cost you at the poles — but it shipped SILENT, so a
		# visitor could work the yaw fader end to end and conclude the machine
		# was broken. The value is still being kept; it is waiting.
		if _yaw_idle():
			txt += "\nYAW held at %d° — idle while the field is vertical" % int(round(_yaw_deg()))
		if is_carry_lesson(): txt = txt.replace("|F|", "|a|").replace("F =", "a =") + "\nm/s² / this hall only"
		_readout.set("text", txt)
	_publish(v)


func is_carry_lesson() -> bool:
	return str(get_meta("config_lesson", "")) == "force_as_place"

func _room(node: Node) -> Node:
	while node != null:
		if node.has_meta("em_map"): return node
		node = node.get_parent()
	return null

func _publish(v: Vector3) -> void:
	if not is_inside_tree(): return
	for field in get_tree().get_nodes_in_group("force_field"):
		if not field.has_method("set_field_vector"): continue
		var scoped: bool = field.has_method("is_carry_lesson") and field.is_carry_lesson()
		if is_carry_lesson():
			if scoped and _room(self) != null and _room(self) == _room(field): field.set_field_vector(v)
		elif not scoped: field.set_field_vector(v)
