extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseFlowDrones
## @identity
## lineage: a Perlin flow field steering a swarm — noise(x,z)*TAU becomes a heading
## essence: thirty lights threading invisible currents, the field doing all the navigation
## truth: give chaos a gradient and it becomes a wind you can ride

@export var count: float = 30.0
@export var field_size: float = 1.4
@export var speed: float = 0.45

var _noise := FastNoiseLite.new()
var _drones: Array[Dictionary] = []
var _trail_root: Node3D
var _drone_mat: StandardMaterial3D
var _trail_mat: StandardMaterial3D


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("count"): count = float(config["count"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.5
	_drone_mat = _glow_mat(Color(0.5, 0.9, 1.0), 2.4)
	_trail_mat = _glow_mat(Color(0.4, 0.7, 1.0), 1.2)
	# ground pad + faint field arrows
	add_child(_box(Vector3(0, 0.01, 0), Vector3(field_size * 2.2, 0.02, field_size * 2.2), _matte_mat(Color(0.05, 0.06, 0.08))))
	var arrow_mat := _glow_mat(Color(0.25, 0.4, 0.6), 0.6)
	var steps: int = 6
	for ix in range(steps):
		for iz in range(steps):
			var px: float = (float(ix) / float(steps - 1) - 0.5) * field_size * 2.0
			var pz: float = (float(iz) / float(steps - 1) - 0.5) * field_size * 2.0
			var ang: float = _noise.get_noise_2d(px * 2.0, pz * 2.0) * TAU
			var a := Vector3(px, 0.03, pz)
			var b := a + Vector3(cos(ang), 0.0, sin(ang)) * 0.14
			add_child(_arrow(a, b, 0.006, arrow_mat))
	add_child(_billboard_label("Noise fields & textures", Vector3(0, 0.9, 0), 24, Color(0.7, 0.9, 1.0)))
	_trail_root = Node3D.new()
	add_child(_trail_root)
	_drones.clear()
	for i in range(int(count)):
		var pos := Vector3(_rng.randf_range(-field_size, field_size), 0.12 + _rng.randf() * 0.25, _rng.randf_range(-field_size, field_size))
		var body := _sphere(pos, 0.03, _drone_mat)
		add_child(body)
		_drones.append({"body": body, "pos": pos, "trail": [] as Array[Vector3]})


func _heading(p: Vector3) -> Vector3:
	var ang: float = _noise.get_noise_2d(p.x * 2.0, p.z * 2.0) * TAU
	return Vector3(cos(ang), 0.0, sin(ang))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	for c in _trail_root.get_children(): _trail_root.remove_child(c); c.queue_free()
	for d in _drones:
		var p: Vector3 = d["pos"]
		p += _heading(p) * speed * delta
		if absf(p.x) > field_size: p.x = -signf(p.x) * field_size
		if absf(p.z) > field_size: p.z = -signf(p.z) * field_size
		d["pos"] = p
		(d["body"] as MeshInstance3D).position = p
		var tr: Array = d["trail"]
		tr.append(p)
		if tr.size() > 6: tr.pop_front()
		for i in range(1, tr.size()):
			_trail_root.add_child(_cylinder_between(tr[i - 1], tr[i], 0.008, _trail_mat))
