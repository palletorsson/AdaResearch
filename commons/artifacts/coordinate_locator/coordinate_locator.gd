extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CoordinateLocator

## @identity
## lineage: the applied face of the Coordinate system concept — a beacon that locates a real point
##   by reading off its (x, y, z) address, the way GPS pins you to a spot on the grid.
## essence: a position is three numbers against an agreed frame; drop lines to each axis and the
##   address is just where those lines meet. Applied coordinates: finding where a thing is.
## truth: space is a promise three numbers keep — and the beacon collects on it.

@export var target: Vector3 = Vector3(2.0, 1.6, -1.0)
@export var beacon_color: Color = Color(0.40, 0.85, 0.60)
var _beacon: Node3D
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
	var gm := _glow_mat(Color(0.30, 0.32, 0.40), 0.3)
	for i in range(-3, 4):
		add_child(_box(Vector3(i, 0, 0), Vector3(0.012, 0.012, 6.0), gm))
		add_child(_box(Vector3(0, 0, i), Vector3(6.0, 0.012, 0.012), gm))
	add_child(_arrow(Vector3.ZERO, Vector3(3.2, 0, 0), 0.03, _glow_mat(Color(0.92, 0.42, 0.42), 1.2)))
	add_child(_arrow(Vector3.ZERO, Vector3(0, 3.2, 0), 0.03, _glow_mat(Color(0.5, 0.92, 0.5), 1.2)))
	add_child(_arrow(Vector3.ZERO, Vector3(0, 0, 3.2), 0.03, _glow_mat(Color(0.5, 0.6, 0.95), 1.2)))
	var foot := Vector3(target.x, 0, target.z)
	add_child(_dashed(target, foot, 0.015, _glow_mat(beacon_color, 0.8)))                       # drop to floor (y)
	add_child(_dashed(foot, Vector3(target.x, 0, 0), 0.012, _glow_mat(Color(0.5, 0.6, 0.95), 0.6)))  # z leg
	add_child(_dashed(Vector3(target.x, 0, 0), Vector3.ZERO, 0.012, _glow_mat(Color(0.92, 0.42, 0.42), 0.6)))  # x leg
	_beacon = Node3D.new(); _beacon.position = target; add_child(_beacon)
	_beacon.add_child(_sphere(Vector3.ZERO, 0.16, _glow_mat(beacon_color, 1.7)))
	_beacon.add_child(_cylinder(Vector3(0, 0.9, 0), 0.02, 1.8, _glow_mat(beacon_color, 1.0)))
	add_child(_billboard_label("LOCATE\n(x, y, z) = (%.1f, %.1f, %.1f)\nspace is a promise three numbers keep" % [target.x, target.y, target.z],
		target + Vector3(0, 2.4, 0), 24, beacon_color.lerp(Color.WHITE, 0.3)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _beacon == null:
		return
	_t += delta
	_beacon.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.06)   # a gentle locator pulse
