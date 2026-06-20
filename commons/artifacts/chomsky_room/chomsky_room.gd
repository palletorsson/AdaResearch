extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ChomskyRoom

## @identity
## lineage: Chomsky-hierarchy room — four nested arches, regular -> recursively-enumerable
## essence: a room you walk inward through; each arch a wider class of grammar, each
##   a little more tangled than the last, the L-system plant living at the centre
##   where the most expressive grammars are.
## truth: grammar is generative, and there is a hierarchy of generative power.
##   The plant in the middle is a context-free L-system — the deepest classes hold
##   forms simpler grammars can never reach.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var angle_deg: float = 23.0
@export var trunk_color: Color = Color(0.42, 0.30, 0.18)
@export var tip_color: Color = Color(0.50, 0.90, 0.40)


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


func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in range(iters):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _arch(half_w: float, height: float, color: Color, tangle: float) -> Node3D:
	# A simple rectangular arch: two posts + a lintel. tangle = jitter on the lintel.
	var root := Node3D.new()
	var mat := _glow_mat(color, 0.7)
	var post := 0.10
	# posts
	root.add_child(_box(Vector3(-half_w, height * 0.5, 0), Vector3(post, height, post), mat))
	root.add_child(_box(Vector3(half_w, height * 0.5, 0), Vector3(post, height, post), mat))
	# lintel — broken into segments, each more jittered for higher classes
	var segs := 7
	for i in range(segs):
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var x0 := lerpf(-half_w, half_w, t0)
		var x1 := lerpf(-half_w, half_w, t1)
		var jy := _rng.randf_range(-tangle, tangle)
		var jz := _rng.randf_range(-tangle, tangle)
		var a := Vector3(x0, height + jy, jz)
		var b := Vector3(x1, height + _rng.randf_range(-tangle, tangle), _rng.randf_range(-tangle, tangle))
		root.add_child(_cylinder_between(a, b, post * 0.5, mat))
	return root


func _build() -> void:
	# --- room floor ---
	var floor_mat := _matte_mat(Color(0.11, 0.12, 0.14), 0.92)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 7), floor_mat))

	# --- four nested arches, outer = regular, inner = recursively enumerable ---
	# widest/cleanest outside, narrowest/most tangled inside.
	var classes := [
		{"w": 3.0, "h": 3.4, "z": -2.6, "c": Color(0.30, 0.55, 0.95), "t": 0.0, "name": "REGULAR"},
		{"w": 2.4, "h": 3.1, "z": -1.4, "c": Color(0.35, 0.75, 0.85), "t": 0.06, "name": "CONTEXT-FREE"},
		{"w": 1.8, "h": 2.8, "z": -0.2, "c": Color(0.55, 0.80, 0.55), "t": 0.14, "name": "CONTEXT-SENSITIVE"},
		{"w": 1.2, "h": 2.5, "z": 1.0, "c": Color(0.90, 0.70, 0.40), "t": 0.26, "name": "RECURSIVELY ENUMERABLE"},
	]
	for cls in classes:
		var arch := _arch(float(cls["w"]), float(cls["h"]), cls["c"], float(cls["t"]))
		arch.position = Vector3(0, 0, float(cls["z"]))
		add_child(arch)
		add_child(_billboard_label(String(cls["name"]), Vector3(0, float(cls["h"]) + 0.25, float(cls["z"])), 24, cls["c"]))

	# --- the L-system plant at the heart (a context-free grammar made visible) ---
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, 4), {
		"angle_deg": angle_deg, "step_len": 0.10, "step_shrink": 0.81,
		"base_width": 0.03, "width_shrink": 0.75, "seed": 3,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 7)
	plant.position = Vector3(0, 0.0, 2.0)
	plant.scale = Vector3.ONE * 1.6
	plant.name = "Plant"
	add_child(plant)

	# --- overhead label ---
	add_child(_billboard_label("CHOMSKY'S HIERARCHY", Vector3(0, 3.6, 0), 34, Color(0.88, 0.94, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var plant := get_node_or_null("Plant")
	if plant:
		plant.rotation.y += delta * 0.12
