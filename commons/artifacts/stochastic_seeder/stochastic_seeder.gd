extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StochasticSeeder

## @identity
## lineage: a stochastic L-system on a clock — Lindenmayer's dice, rolled live.
## essence: A seeder device that grows one new plant every couple of seconds. The
##   grammar never changes; only the seed advances. Each grown plant is a fresh
##   draw from the same species, and a readout counts how many the rule has made.
## truth: "randomness is how a grammar makes a population, not a clone"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var plant_seed: int = 1
@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var grow_interval: float = 2.0
@export var base_col: Color = Color(0.14, 0.46, 0.18)
@export var tip_col: Color = Color(0.58, 0.88, 0.34)
@export var plant_height: float = 0.7
@export var device_col: Color = Color(0.55, 0.58, 0.62)

var _plant: MultiMeshInstance3D = null
var _readout: Label3D = null
var _holder: Node3D = null
var _timer: float = 0.0
var _current_seed: int = 0
var _grown_count: int = 0


func _expand_stoch(axiom: String, rules: Dictionary, n: int, rng: RandomNumberGenerator) -> String:
	var s := axiom
	for _i in range(n):
		var out := ""
		for ch: String in s:
			if rules.has(ch):
				var roll := rng.randf()
				var acc := 0.0
				var rep := ch
				for opt: Array in rules[ch]:
					acc += float(opt[0])
					if roll <= acc:
						rep = String(opt[1])
						break
				out += rep
			else:
				out += ch
		s = out
	return s


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	emissive = bool(config.get("emissive", emissive))
	plant_seed = int(config.get("plant_seed", plant_seed))
	iters = int(config.get("iters", iters))
	angle_deg = float(config.get("angle_deg", angle_deg))
	grow_interval = float(config.get("grow_interval", grow_interval))
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	plant_height = float(config.get("plant_height", plant_height))
	device_col = _parse_color(config.get("device_col"), device_col)
	for c in get_children():
		c.queue_free()
	_plant = null
	_readout = null
	_holder = null
	_timer = 0.0
	_grown_count = 0
	_build()


func _build() -> void:
	# ~1m device — a base plinth with a planter dish on top.
	var steel := _steel_mat(device_col)
	add_child(_box(Vector3(0.0, 0.45, 0.0), Vector3(0.7, 0.9, 0.7), _matte_mat(device_col, 0.5, 0.4)))
	add_child(_box(Vector3(0.0, 0.92, 0.0), Vector3(0.8, 0.06, 0.8), steel))
	# Planter dish the plant rises from.
	add_child(_cylinder(Vector3(0.0, 0.98, 0.0), 0.16, 0.08, _matte_mat(Color(0.18, 0.12, 0.08), 0.95)))
	# A small status lamp on the front face.
	add_child(_sphere(Vector3(0.0, 0.6, 0.36), 0.04, _glow_mat(tip_col, 2.0)))

	# Holder that we regrow into — keeps add/free cheap and isolated.
	_holder = Node3D.new()
	_holder.position = Vector3(0.0, 1.02, 0.0)
	add_child(_holder)

	_current_seed = plant_seed
	_grow_plant()

	add_child(_billboard_label("Stochastic L-systems", Vector3(0.0, 1.7, 0.0), 24, tip_col))
	add_child(_billboard_label("STOCHASTIC SEEDER", Vector3(0.0, 1.86, 0.0), 18, Color(0.85, 0.95, 0.82)))

	_readout = _billboard_label("seeds grown: %d   seed %d" % [_grown_count, _current_seed], Vector3(0.0, 1.56, 0.0), 14, Color(0.80, 0.92, 0.78))
	add_child(_readout)


func _grow_plant() -> void:
	# Rebuild the SINGLE plant with a new seed. Called on the timer, never per frame.
	if _holder == null:
		return
	for c in _holder.get_children():
		c.queue_free()

	var rules := {
		"F": [
			[0.34, "F[+F]F[-F]F"],
			[0.33, "F[+F]F"],
			[0.33, "F[-F]F"],
		],
	}
	var lrng := RandomNumberGenerator.new()
	lrng.seed = _current_seed
	var walk: Dictionary = LST.walk(_expand_stoch("F", rules, iters, lrng), {
		"angle_deg": angle_deg,
		"step_len": 0.07,
		"step_shrink": 0.82,
		"base_width": 0.018,
		"width_shrink": 0.72,
		"seed": _current_seed,
	})
	_plant = LST.to_tubes(walk, base_col, tip_col, 6)
	_scale_plant_to(_plant, plant_height)
	_holder.add_child(_plant)

	_grown_count += 1
	if _readout != null:
		_readout.text = "seeds grown: %d   seed %d" % [_grown_count, _current_seed]


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	var span: float = maxf(_measure_height(node), 0.001)
	var s: float = clampf(target_h / span, 0.02, 12.0)
	node.scale = Vector3.ONE * s


func _measure_height(node: MultiMeshInstance3D) -> float:
	var mm: MultiMesh = node.multimesh
	var min_y := INF
	var max_y := -INF
	for i in range(mm.instance_count):
		var o: Vector3 = mm.get_instance_transform(i).origin
		min_y = minf(min_y, o.y)
		max_y = maxf(max_y, o.y)
	if min_y == INF:
		return 1.0
	return max_y - min_y


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_timer += delta
	if _timer >= maxf(grow_interval, 0.25):
		_timer = 0.0
		_current_seed += 1
		_grow_plant()
