extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StochasticRoom

## @identity
## lineage: one stochastic plant grammar, instanced into a meadow — Lindenmayer's
##   population, walkable.
## essence: A room you walk into, scattered with ~7 plants. Every plant runs the
##   same probabilistic rewrite rule; only its seed differs. Stand among them and
##   the claim is plain — this is a species, not a set of drawings.
## truth: "randomness is how a grammar makes a population, not a clone"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var plant_seed: int = 23
@export var plant_count: int = 7
@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var base_col: Color = Color(0.10, 0.42, 0.16)
@export var tip_col: Color = Color(0.56, 0.87, 0.32)
@export var sway_amount: float = 0.025

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
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_plants.clear()
	_build()


func _build() -> void:
	# Room floor ~7 x 7, top at y = -0.05.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.14, 0.16, 0.13), 0.95)))

	var rules := {
		"F": [
			[0.34, "F[+F]F[-F]F"],
			[0.33, "F[+F]F"],
			[0.33, "F[-F]F"],
		],
	}

	# A meadow of plants — same grammar, different seed each.
	var n: int = maxi(plant_count, 1)
	for i in range(n):
		var seed_i: int = plant_seed + i * 257
		var lrng := RandomNumberGenerator.new()
		lrng.seed = seed_i
		var walk: Dictionary = LST.walk(_expand_stoch("F", rules, iters, lrng), {
			"angle_deg": angle_deg,
			"step_len": 0.07,
			"step_shrink": 0.82,
			"base_width": 0.02,
			"width_shrink": 0.72,
			"seed": seed_i,
		})
		# A touch of colour variety per plant, still from the shared palette.
		var bc: Color = base_col.lerp(Color(0.06, 0.30, 0.18), lrng.randf())
		var tc: Color = tip_col.lerp(Color(0.70, 0.90, 0.45), lrng.randf())
		var plant: MultiMeshInstance3D = LST.to_tubes(walk, bc, tc, 6)

		var target_h: float = 2.0 + lrng.randf() * 1.0
		_scale_plant_to(plant, target_h)

		# Scatter across the floor in a loose ring.
		var theta: float = TAU * float(i) / float(n) + lrng.randf_range(-0.3, 0.3)
		var radius: float = 1.4 + lrng.randf() * 1.3
		plant.position = Vector3(cos(theta) * radius, 0.0, sin(theta) * radius)
		plant.rotation.y = lrng.randf_range(0.0, TAU)

		add_child(_cylinder(plant.position + Vector3(0.0, 0.02, 0.0), 0.16, 0.06, _matte_mat(Color(0.20, 0.13, 0.09), 0.9)))
		add_child(plant)
		_plants.append(plant)

	add_child(_billboard_label("Stochastic L-systems", Vector3(0.0, 3.4, 0.0), 30, tip_col))
	add_child(_billboard_label("A GRAMMAR MAKES A POPULATION, NOT A CLONE", Vector3(0.0, 3.6, 0.0), 22, Color(0.85, 0.95, 0.82)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	var span: float = maxf(_measure_height(node), 0.001)
	var s: float = clampf(target_h / span, 0.02, 16.0)
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
		var phase: float = float(i) * 0.6
		p.rotation.z = sin(t * 0.5 + phase) * sway_amount
