extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RiverCrossing

## @identity
## lineage: the applied face of Subtraction — a boat crossing a flowing river. The current carries
##   it downstream, so the actual track is the boat's heading minus what the river steals.
## essence: to land where you mean to, you aim upstream: heading = desired − current. Relative
##   velocity is a subtraction you can see in the drift between where you point and where you go.
## truth: subtraction is the direction of the gap — between the course you steer and the course you make.

@export var current_color: Color = Color(0.30, 0.58, 0.92)
@export var heading_color: Color = Color(0.55, 0.95, 0.58)
@export var track_color: Color = Color(0.98, 0.72, 0.32)
@export var boat_color: Color = Color(0.85, 0.5, 0.98)
var _boat: Node3D
var _vectors: Node3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, -0.04, 0), Vector3(8, 0.06, 3.2), _glow_mat(Color(0.18, 0.34, 0.5), 0.35)))   # the river
	add_child(_box(Vector3(0, 0.0, 2.0), Vector3(8, 0.12, 0.6), _matte_mat(Color(0.3, 0.34, 0.26), 0.9)))   # far bank (target side)
	add_child(_box(Vector3(0, 0.0, -2.0), Vector3(8, 0.12, 0.6), _matte_mat(Color(0.3, 0.34, 0.26), 0.9)))  # near bank
	add_child(_sphere(Vector3(0, 0.3, 2.0), 0.16, _glow_mat(Color(0.98, 0.9, 0.4), 1.6)))                   # the target dock
	_boat = Node3D.new(); add_child(_boat)
	_boat.add_child(_box(Vector3(0, 0.16, 0), Vector3(0.6, 0.2, 0.34), _glow_mat(boat_color, 0.8)))
	_vectors = Node3D.new(); add_child(_vectors)
	add_child(_billboard_label("RIVER CROSSING\nheading = target − current\naim upstream to land true",
		Vector3(0, 2.4, 0), 25, track_color.lerp(Color.WHITE, 0.3)))
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _boat == null:
		return
	_t += delta * 0.5
	_redraw()


func _redraw() -> void:
	var frac: float = fmod(_t, 1.0)
	var start := Vector3(-2.4, 0.3, -2.0)
	var target := Vector3(0, 0.3, 2.0)
	var current := Vector3(1.0, 0, 0) * 0.9                 # the river pushes +x
	var desired: Vector3 = (target - start)
	var heading: Vector3 = desired - current * 1.4          # aim = desired minus current (the subtraction)
	# boat tracks straight to target because the heading already cancels the drift
	_boat.position = start.lerp(target, frac)
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var o := _boat.position
	_vectors.add_child(_arrow(o, o + current.normalized() * 1.1, 0.045, _glow_mat(current_color, 1.4)))                   # current
	_vectors.add_child(_arrow(o, o + heading.normalized() * 1.3, 0.05, _glow_mat(heading_color, 1.6)))                    # heading (steered)
	_vectors.add_child(_arrow(o, o + (target - o).normalized() * 1.2, 0.05, _glow_mat(track_color, 1.6)))                 # actual track to dock
