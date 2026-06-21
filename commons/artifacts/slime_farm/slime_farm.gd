extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SlimeFarm

## @identity
## name: Slime Farm
## tier: applied
## truth: a network you can watch arrive — growth is a verb, not a noun
##
## A tabletop device (~1m) that grows a DLA / slime aggregate live. Every tick it
## releases a fresh batch of walkers; each random-walks until it touches the
## frozen cluster and sticks. The dendrite thickens before your eyes. When it
## reaches its cap the chamber resets and a new seed starts over. A readout
## counts the particles currently stuck.

@export var grid_radius: int = 22
@export var cap: int = 240
@export var walkers_per_tick: int = 4
@export var tick_interval: float = 0.4
@export var core_color: Color = Color(0.55, 0.9, 1.0)
@export var tip_color: Color = Color(1.0, 0.55, 0.85)

const CELL: float = 0.0125
const DEVICE_H: float = 0.5

var _stuck: Array[Vector2i] = []
var _occupied: Dictionary = {}
var _container: Node3D
var _field_mi: MultiMeshInstance3D
var _readout: Label3D
var _accum: float = 0.0
var _spawn_radius: float = 8.0
var _dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# housing — a growth chamber on a short pedestal
	add_child(_box(Vector3(0.0, DEVICE_H * 0.5, 0.0), Vector3(0.7, DEVICE_H, 0.7), _matte_mat(Color(0.16, 0.18, 0.22))))
	add_child(_box(Vector3(0.0, DEVICE_H + 0.02, 0.0), Vector3(0.74, 0.04, 0.74), _matte_mat(Color(0.05, 0.06, 0.08))))
	add_child(_sphere(Vector3(0.0, DEVICE_H + 0.36, 0.0), 0.34, _glass_mat(Color(0.5, 0.9, 1.0), 0.06)))
	_readout = _billboard_label("particles: 0", Vector3(0.0, 1.05, 0.0), 30, tip_color)
	add_child(_readout)

	# the live aggregate lives in its own container we re-fill each reset
	_container = Node3D.new()
	_container.position = Vector3(0.0, DEVICE_H + 0.36, 0.0)
	add_child(_container)
	_reset_cluster()
	_rebuild_field()


func _reset_cluster() -> void:
	_stuck.clear()
	_occupied.clear()
	_spawn_radius = 8.0
	_stick(Vector2i.ZERO)


func _stick(p: Vector2i) -> void:
	_occupied[p] = true
	_stuck.append(p)


func _add_walkers(count: int) -> void:
	var kill_radius: int = grid_radius + 5
	for _w in range(count):
		if _stuck.size() >= cap:
			return
		var ang: float = _rng.randf() * TAU
		var pos := Vector2i(int(round(cos(ang) * _spawn_radius)), int(round(sin(ang) * _spawn_radius)))
		for _step in range(3000):
			var touching: bool = false
			for d: Vector2i in _dirs:
				if _occupied.has(pos + d):
					touching = true
					break
			if touching:
				_stick(pos)
				var r: float = sqrt(float(pos.x * pos.x + pos.y * pos.y))
				_spawn_radius = maxf(_spawn_radius, r + 5.0)
				break
			pos += _dirs[_rng.randi() % 4]
			if absi(pos.x) > kill_radius or absi(pos.y) > kill_radius:
				var a2: float = _rng.randf() * TAU
				pos = Vector2i(int(round(cos(a2) * _spawn_radius)), int(round(sin(a2) * _spawn_radius)))


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _rebuild_field() -> void:
	if _field_mi != null:
		_container.remove_child(_field_mi)
		_field_mi.queue_free()
		_field_mi = null
	var n: int = _stuck.size()
	if n == 0:
		return
	_field_mi = _field(n)
	var mm: MultiMesh = _field_mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(CELL, CELL, CELL) * 1.5
	var denom: float = maxf(float(cap - 1), 1.0)
	for i in range(n):
		var cell: Vector2i = _stuck[i]
		var p := Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL)
		var t: float = float(i) / denom
		mm.set_instance_transform(i, Transform3D(Basis(), p))
		mm.set_instance_color(i, core_color.lerp(tip_color, t))
	_container.add_child(_field_mi)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < tick_interval:
		return
	_accum = 0.0
	if _stuck.size() >= cap:
		_reset_cluster()
	else:
		_add_walkers(walkers_per_tick)
	_rebuild_field()
	if _readout != null:
		_readout.text = "particles: %d / %d" % [_stuck.size(), cap]
