extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CityToy

## CityToy — Grammar architecture (cities/dungeons), SMALL tier.
##
## A held tiny orthogonal L-system city block (~0.4m). Point the same
## turtle at right angles and the grammar grows streets and blocks
## instead of a tree.
##
## @identity
##   truth: "point the rules at right angles and the same engine grows a city"
##   truth: "the grammar is the DNA, the material is a choice"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F[+F]F[-F]F"}
@export var iters: int = 3
@export var angle: float = 90.0
@export var c1: Color = Color(0.4, 0.45, 0.55)
@export var c2: Color = Color(0.5, 0.9, 1.0)
@export var spin_speed: float = 0.5


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("axiom"):
		axiom = String(config["axiom"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("c1"):
		c1 = _parse_color(config["c1"], c1)
	if config.has("c2"):
		c2 = _parse_color(config["c2"], c2)
	for child in get_children():
		child.queue_free()
	_build()


func _expand(p_axiom: String, p_rules: Dictionary, p_iters: int) -> String:
	var s := p_axiom
	for _i in range(p_iters):
		var out := ""
		for ch: String in s:
			out += String(p_rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle, "step_len": 0.08, "step_shrink": 0.85,
		"base_width": 0.02, "width_shrink": 0.8, "seed": 1,
	})

	var holder := Node3D.new()
	add_child(holder)
	# render the orthogonal layout as low tube walls
	var tubes: MultiMeshInstance3D = LST.to_tubes(walk, c1, c2, 6)
	holder.add_child(tubes)
	# tiny base plate so it reads as a held block
	add_child(_box(Vector3(0.0, -0.02, 0.0), Vector3(0.42, 0.02, 0.42), _matte_mat(Color(0.12, 0.13, 0.16), 0.8)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y += spin_speed * delta
