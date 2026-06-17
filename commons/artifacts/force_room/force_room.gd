extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ForceRoom

## @identity
## lineage: the room-scale, walk-in end of the Force ladder — a heavy block on the floor with a
##   room-sized applied-force arrow and the acceleration arrow it produces, both growing as you watch.
## essence: F = m·a, so a = F/m. The orange arrow is the input you push with; the green arrow is the
##   mass's answer, shorter by exactly the mass; oscillate F and the acceleration breathes with it.
## truth: a force is a vector applied to a mass — and the mass answers with acceleration.

@export var mass: float = 2.0
@export var fcolor: Color = Color(0.98, 0.55, 0.2)
@export var acolor: Color = Color(0.5, 0.92, 0.5)
var _rig: Node3D
var _readout: Label3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("mass"): mass = maxf(float(config["mass"]), 0.5)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.08, 7), _matte_mat(Color(0.15, 0.16, 0.2), 0.9)))   # the room floor
	add_child(_box(Vector3(0, 0.5, 0), Vector3(1, 1, 1), _steel_mat(Color(0.4, 0.42, 0.5))))             # the heavy mass
	add_child(_billboard_label("m", Vector3(0, 0.5, 0), 40, Color.WHITE))
	_rig = Node3D.new(); _rig.position = Vector3(0, 0.5, 0); add_child(_rig)
	_readout = _billboard_label("FORCE", Vector3(0, 3.6, 0), 30, acolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var f: float = 3.0 + sin(_t * 0.8) * 2.2          # F oscillates
	var a: float = f / mass                            # the mass answers
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	_rig.add_child(_arrow(Vector3(0.6, 0, 0), Vector3(0.6 + f, 0, 0), 0.09, _glow_mat(fcolor, 1.7)))   # applied force (input)
	_rig.add_child(_arrow(Vector3(0, 1.1, 0), Vector3(a, 1.1, 0), 0.07, _glow_mat(acolor, 1.7)))       # acceleration (output = F/m)
	if _readout:
		_readout.text = "FORCE\nF = m · a   →   a = F/m\nF = %.1f  m = %.1f  a = %.2f" % [f, mass, a]
