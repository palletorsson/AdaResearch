extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RandomFireworks
## @identity
## lineage: a particle system's per-particle RNG — one seed, a thousand fates
## essence: each spark gets its own velocity and hue; the shape is their disagreement
## truth: from identical rules, divergent draws — the bloom is randomness made visible

@export var max_bursts: int = 4
@export var dots_per_burst: int = 22

var _sky: Node3D
var _bursts: Array = []
var _spawn := 0.0

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_bursts.clear()
	var steel := _steel_mat(Color(0.3, 0.32, 0.4))
	# Launcher tube + base.
	add_child(_cylinder(Vector3(0, 0.1, 0), 0.22, 0.08, steel))
	add_child(_cylinder(Vector3(0, 0.4, 0), 0.08, 0.6, steel))
	add_child(_cylinder(Vector3(0, 0.72, 0), 0.1, 0.06, _glow_mat(Color(1.0, 0.8, 0.3), 3.0)))
	_sky = Node3D.new()
	add_child(_sky)
	# Several bursts already mid-bloom at different ages/heights.
	_spawn_burst(Vector3(0.0, 1.7, 0.0), 0.45)
	_spawn_burst(Vector3(-0.5, 2.1, -0.2), 0.7)
	_spawn_burst(Vector3(0.55, 1.5, 0.25), 0.2)
	add_child(_billboard_label("Particle randomness", Vector3(0, 0.95, 0), 24, Color(1.0, 0.85, 0.6)))

func _spawn_burst(center: Vector3, age: float) -> void:
	var root := Node3D.new()
	root.position = center
	_sky.add_child(root)
	var base_hue := _rng.randf()
	var dots: Array = []
	for i in range(dots_per_burst):
		# Per-dot random direction, speed, hue.
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
		var speed := _rng.randf_range(0.7, 1.6)
		var hue := fmod(base_hue + _rng.randf_range(-0.12, 0.12), 1.0)
		var mat := _glow_mat(Color.from_hsv(hue, 0.7, 1.0), 3.5)
		var d := _sphere(Vector3.ZERO, 0.03, mat)
		root.add_child(d)
		dots.append({"node": d, "vel": dir * speed})
	_bursts.append({"root": root, "dots": dots, "age": age})

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	var dead: Array = []
	for b in _bursts:
		b["age"] += delta
		var t: float = b["age"]
		for dot in b["dots"]:
			var v: Vector3 = dot["vel"]
			var node: MeshInstance3D = dot["node"]
			# Expand outward, then fall under gravity.
			node.position = v * t + Vector3(0, -0.6, 0) * t * t
			var fade: float = clampf(1.0 - t * 0.55, 0.0, 1.0)
			node.scale = Vector3.ONE * (0.4 + fade)
		if t > 1.9:
			dead.append(b)
	for b in dead:
		b["root"].queue_free()
		_bursts.erase(b)
	# Spawn a new burst periodically, capped.
	_spawn += delta
	if _spawn > 0.8 and _bursts.size() < max_bursts:
		_spawn = 0.0
		_spawn_burst(Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(1.5, 2.2), _rng.randf_range(-0.3, 0.3)), 0.0)
