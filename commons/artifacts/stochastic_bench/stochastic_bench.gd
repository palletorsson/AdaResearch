extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StochasticBench

## @identity
## lineage: Lindenmayer's stochastic L-systems set side by side — one grammar,
##   several seeds, a small population on a bench.
## essence: A bench carrying 3-4 plants. They share one rewrite rule with
##   probabilistic branches; only the seed differs. No two are alike, yet none
##   is hand-drawn — the variety is the grammar rolling its own dice.
## truth: "randomness is how a grammar makes a population, not a clone"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var plant_seed: int = 11
@export var plant_count: int = 4
@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var base_col: Color = Color(0.12, 0.44, 0.16)
@export var tip_col: Color = Color(0.56, 0.87, 0.32)
@export var plant_height: float = 0.7
@export var sway_amount: float = 0.03

var _plants: Array[MultiMeshInstance3D] = []


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
	plant_count = int(config.get("plant_count", plant_count))
	iters = int(config.get("iters", iters))
	angle_deg = float(config.get("angle_deg", angle_deg))
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	plant_height = float(config.get("plant_height", plant_height))
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_plants.clear()
	_build()


func _build() -> void:
	# Bench base box ~1.1 x 0.2, top at y ~0.85, on a pillar.
	var wood := _matte_mat(Color(0.30, 0.22, 0.16), 0.85)
	add_child(_box(Vector3(0.0, 0.40, 0.0), Vector3(0.30, 0.80, 0.30), wood))
	add_child(_box(Vector3(0.0, 0.83, 0.0), Vector3(1.1, 0.2, 0.45), _matte_mat(Color(0.42, 0.31, 0.22), 0.7)))

	var rules := {
		"F": [
			[0.34, "F[+F]F[-F]F"],
			[0.33, "F[+F]F"],
			[0.33, "F[-F]F"],
		],
	}

	var n: int = clampi(plant_count, 3, 4)
	var top_y: float = 0.93
	for i in range(n):
		# Each plant grows from a DIFFERENT seed — same rules, no two alike.
		var seed_i: int = plant_seed + i * 101
		var lrng := RandomNumberGenerator.new()
		lrng.seed = seed_i
		var walk: Dictionary = LST.walk(_expand_stoch("F", rules, iters, lrng), {
			"angle_deg": angle_deg,
			"step_len": 0.07,
			"step_shrink": 0.82,
			"base_width": 0.018,
			"width_shrink": 0.72,
			"seed": seed_i,
		})
		var plant: MultiMeshInstance3D = LST.to_tubes(walk, base_col, tip_col, 6)
		_scale_plant_to(plant, plant_height)

		# Line them up across the top of the bench.
		var span: float = 0.9
		var x: float = -span * 0.5 + span * float(i) / float(maxi(n - 1, 1))
		plant.position = Vector3(x, top_y, 0.0)
		add_child(plant)
		_plants.append(plant)

		# Small pot under each plant.
		add_child(_cylinder(Vector3(x, top_y, 0.0), 0.05, 0.04, _matte_mat(Color(0.20, 0.13, 0.09), 0.9)))

	add_child(_billboard_label("Stochastic L-systems", Vector3(0.0, 1.6, 0.0), 26, tip_col))
	add_child(_billboard_label("NO TWO PLANTS THE SAME", Vector3(0.0, 1.78, 0.0), 18, Color(0.85, 0.95, 0.82)))


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
	var t: float = Time.get_ticks_msec() / 1000.0
	for i in range(_plants.size()):
		var p: MultiMeshInstance3D = _plants[i]
		if p == null:
			continue
		var phase: float = float(i) * 0.7
		p.rotation.z = sin(t * 0.55 + phase) * sway_amount
