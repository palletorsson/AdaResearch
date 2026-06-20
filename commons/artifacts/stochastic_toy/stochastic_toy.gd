extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StochasticToy

## @identity
## lineage: Lindenmayer's stochastic L-systems — a symbol carries SEVERAL rules,
##   chosen by probability, so one grammar grows a population, not a clone.
## essence: A single plant you can hold, grown from `plant_seed`. The grammar is
##   fixed; the dice are fixed too, once the seed is set. Same seed, same plant —
##   change the seed and the same rules grow a different individual.
## truth: "randomness is how a grammar makes a population, not a clone"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var plant_seed: int = 7
@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var base_col: Color = Color(0.14, 0.45, 0.16)
@export var tip_col: Color = Color(0.58, 0.88, 0.34)
@export var plant_height: float = 0.4
@export var sway_amount: float = 0.03

var _plant: MultiMeshInstance3D = null


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
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	plant_height = float(config.get("plant_height", plant_height))
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_plant = null
	_build()


func _build() -> void:
	# No table — a held toy. Grow the plant near the origin and scale it to ~0.4m.
	var rules := {
		"F": [
			[0.34, "F[+F]F[-F]F"],
			[0.33, "F[+F]F"],
			[0.33, "F[-F]F"],
		],
	}
	var lrng := RandomNumberGenerator.new()
	lrng.seed = plant_seed
	var walk: Dictionary = LST.walk(_expand_stoch("F", rules, iters, lrng), {
		"angle_deg": angle_deg,
		"step_len": 0.07,
		"step_shrink": 0.82,
		"base_width": 0.018,
		"width_shrink": 0.72,
		"seed": plant_seed,
	})
	_plant = LST.to_tubes(walk, base_col, tip_col, 6)
	_scale_plant_to(_plant, plant_height)
	_plant.position = Vector3.ZERO
	add_child(_plant)

	# A small earth pad the plant rises from.
	add_child(_cylinder(Vector3(0.0, -0.01, 0.0), 0.06, 0.02, _matte_mat(Color(0.20, 0.13, 0.09), 0.9)))

	add_child(_billboard_label("Stochastic L-systems", Vector3(0.0, plant_height + 0.12, 0.0), 18, tip_col))
	add_child(_billboard_label("seed %d" % plant_seed, Vector3(0.0, plant_height + 0.04, 0.0), 14, Color(0.85, 0.95, 0.82)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	# The unit-cylinder AABB is not the plant; measure span from segment origins.
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
	if _plant == null:
		return
	# Gentle sway, never a rebuild.
	var t: float = Time.get_ticks_msec() / 1000.0
	_plant.rotation.z = sin(t * 0.6) * sway_amount
	_plant.rotation.x = cos(t * 0.45) * sway_amount * 0.5
