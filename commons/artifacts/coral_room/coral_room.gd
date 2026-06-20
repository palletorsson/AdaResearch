extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CoralRoom

## @identity
## lineage: a reef — many corals, one greedy local rule, varied seed & hue
## essence: A room of corals on the floor, each grown from the same fork-rule but
##   a different seed and colour. The reef is not designed; it is the same rule
##   run many times under different starting noise.
## truth: "One greedy local rule." No coral sees the reef. Each fork takes the
##   cheapest next step, and the room-scale order is emergent, not authored.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var coral_count: int = 5
@export var sway_amount: float = 0.02

var _corals: Array[MultiMeshInstance3D] = []

const _PALETTE: Array = [
	[Color(0.85, 0.32, 0.30), Color(0.99, 0.66, 0.55)],   # red coral
	[Color(0.90, 0.55, 0.20), Color(1.0, 0.82, 0.45)],    # orange
	[Color(0.75, 0.30, 0.55), Color(0.95, 0.60, 0.85)],   # pink/violet
	[Color(0.30, 0.55, 0.62), Color(0.55, 0.85, 0.90)],   # teal
	[Color(0.80, 0.72, 0.30), Color(0.98, 0.95, 0.60)],   # yellow
]


func _expand(axiom: String, rules: Dictionary, n: int) -> String:
	var s := axiom
	for _i in range(n):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	emissive = bool(config.get("emissive", emissive))
	iters = int(config.get("iters", iters))
	angle_deg = float(config.get("angle_deg", angle_deg))
	coral_count = int(config.get("coral_count", coral_count))
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_corals.clear()
	_build()


func _build() -> void:
	# Reef floor.
	var floor_mat := _matte_mat(Color(0.10, 0.14, 0.18), 0.95)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))

	var axiom := "F"
	var rules := {"F": "FF-[-F+&F+^F]+[+F-&F-^F]"}

	var n: int = max(coral_count, 1)
	for i in range(n):
		var ang: float = angle_deg + _rng.randf_range(-4.0, 4.0)
		var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
			"angle_deg": ang,
			"step_len": 0.07,
			"step_shrink": 0.78,
			"base_width": 0.03,
			"width_shrink": 0.72,
			"seed": _rng.randi(),
		})
		var pal: Array = _PALETTE[i % _PALETTE.size()]
		var bc: Color = pal[0]
		var tc: Color = pal[1]
		var coral: MultiMeshInstance3D = LST.to_tubes(walk, bc, tc, 6)

		var target_h: float = _rng.randf_range(2.0, 3.0)
		_scale_plant_to(coral, target_h)

		var theta: float = TAU * float(i) / float(n) + _rng.randf_range(-0.25, 0.25)
		var radius: float = _rng.randf_range(1.3, 2.7)
		coral.position = Vector3(cos(theta) * radius, 0.0, sin(theta) * radius)
		coral.rotation.y = _rng.randf_range(0.0, TAU)

		# Rocky holdfast under each coral.
		add_child(_sphere(coral.position + Vector3(0.0, 0.08, 0.0), 0.16, _matte_mat(Color(0.30, 0.28, 0.27), 0.95)))
		add_child(coral)
		_corals.append(coral)

	add_child(_billboard_label("Coral & vines", Vector3(0.0, 3.4, 0.0), 30, Color(0.99, 0.7, 0.55)))
	add_child(_billboard_label("ONE GREEDY LOCAL RULE", Vector3(0.0, 3.6, 0.0), 22, Color(0.98, 0.88, 0.82)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	var span: float = maxf(_plant_height(node), 0.001)
	var s: float = clampf(target_h / span, 0.05, 12.0)
	node.scale = Vector3.ONE * s


func _plant_height(node: MultiMeshInstance3D) -> float:
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
	for i in range(_corals.size()):
		var c: MultiMeshInstance3D = _corals[i]
		if c == null:
			continue
		var phase: float = float(i) * 0.9
		c.rotation.z = sin(t * 0.4 + phase) * sway_amount
