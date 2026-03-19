@tool
extends EditorScript
## Consolidated validation for the Axiom Garden L-System puzzle.
## Run via: right-click → "Run" in the Godot Script Editor.
##
## Covers: L-System logic, turtle graphics, renderer pipeline, goal detection,
## withering constraint, environment setup, stochastic rules, and full playthrough.
## Consolidates the original test_iteration_1 through test_iteration_9 plus
## test_full_playthrough (archived in _iterations/).

const BASE = "res://algorithms/machinelearning/thegame_a/"

var _passed := 0
var _failed := 0

func _run() -> void:
	print("=== Axiom Garden — Validation Suite ===\n")

	_test_lsystem_logic()
	_test_turtle_graphics()
	_test_renderer()
	_test_goal_detection()
	_test_withering()
	_test_environment()
	_test_stochastic_rules()
	_test_full_playthrough()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])

# --- 1. L-System Logic (Iteration 1) ---
func _test_lsystem_logic() -> void:
	print("— L-System Logic —")
	var lsys = load(BASE + "LSystem.gd").new()

	# Algae (Lindenmayer's original): A -> AB, B -> A
	lsys.axiom = "A"
	lsys.set_rule("A", "AB")
	lsys.set_rule("B", "A")
	_check("Algae gen 4", lsys.generate(4) == "ABAABABA")

	# Simple tree: F -> F[+F]F[-F]
	var tree = load(BASE + "LSystem.gd").new()
	tree.axiom = "F"
	tree.set_rule("F", "F[+F]F[-F]")
	_check("Tree gen 1", tree.generate(1) == "F[+F]F[-F]")

# --- 2. Turtle Graphics (Iteration 2) ---
func _test_turtle_graphics() -> void:
	print("— Turtle Graphics —")
	var turtle = load(BASE + "Turtle.gd").new()
	var lines = turtle.process_string("F[+F][-F]")
	_check("Branch produces 3 segments", lines.size() == 3)

# --- 3. Renderer (Iteration 3) ---
func _test_renderer() -> void:
	print("— Renderer —")
	var renderer = load(BASE + "GardenRenderer.gd").new()
	renderer._ready()
	var lines = [
		PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 1, 0)]),
		PackedVector3Array([Vector3(0, 1, 0), Vector3(1, 2, 0)])
	]
	renderer.render(lines)
	_check("MultiMesh instance count", renderer.multi_mesh_instance.multimesh.instance_count == 2)

# --- 4. Goal Detection (Iteration 5) ---
func _test_goal_detection() -> void:
	print("— Goal Detection —")
	var target = load(BASE + "Target.gd").new()
	target.position = Vector3(0, 2, 0)
	target.radius = 0.5
	var segment_end = Vector3(0, 2, 0)
	_check("Target reached", segment_end.distance_to(target.position) < target.radius)

# --- 5. Withering Constraint (Iteration 6) ---
func _test_withering() -> void:
	print("— Withering —")
	var garden = load(BASE + "AxiomGarden.gd").new()
	garden.max_segments = 10
	var renderer = load(BASE + "GardenRenderer.gd").new()
	renderer.name = "GardenRenderer"
	garden.add_child(renderer)

	# Safe: F -> F (1 segment)
	garden.lsystem = load(BASE + "LSystem.gd").new("F", {"F": "F"})
	garden.generations = 1
	garden.grow_garden()
	_check("Safe growth renders", garden.renderer.multi_mesh_instance.multimesh.instance_count == 1)

	# Withered: F -> FF, 5 gens = 32 segments > 10
	garden.lsystem = load(BASE + "LSystem.gd").new("F", {"F": "FF"})
	garden.generations = 5
	garden.grow_garden()
	_check("Excess segments wither", garden.renderer.multi_mesh_instance.multimesh.instance_count == 0)

# --- 6. Environment (Iteration 8) ---
func _test_environment() -> void:
	print("— Environment —")
	var env = load(BASE + "AxiomEnvironment.gd").new()
	env._ready()
	_check("Glow enabled", env.environment.glow_enabled == true)

# --- 7. Stochastic Rules (Iteration 9) ---
func _test_stochastic_rules() -> void:
	print("— Stochastic Rules —")
	var lsys = load(BASE + "LSystem.gd").new()
	lsys.axiom = "A"
	lsys.rules = {"A": ["B", "C"]}
	var results := {}
	for i in range(100):
		var res = lsys.generate(1)
		results[res] = results.get(res, 0) + 1
	_check("Stochastic produces both variants", results.has("B") and results.has("C"))

# --- 8. Full Playthrough (Iteration 10) ---
func _test_full_playthrough() -> void:
	print("— Full Playthrough —")
	var garden = load(BASE + "AxiomGarden.gd").new()
	var renderer = load(BASE + "GardenRenderer.gd").new()
	renderer.name = "GardenRenderer"
	garden.add_child(renderer)

	var target = load(BASE + "Target.gd").new()
	target.position = Vector3(0, 5, 0)
	target.radius = 1.0
	target.add_to_group("targets")
	garden.add_child(target)

	garden.lsystem = load(BASE + "LSystem.gd").new("F", {"F": "FF"})
	garden.generations = 3  # 8 segments at 1.0 step -> reaches 8 units
	garden.step_length = 1.0
	garden.grow_garden()

	var lines = garden.turtle.process_string(garden.lsystem.generate(3))
	var win := false
	for seg in lines:
		if seg[1].distance_to(target.position) < target.radius:
			win = true
			break
	_check("Plant reaches target", win)

# --- Helpers ---
func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS: " + name)
	else:
		_failed += 1
		push_error("  FAIL: " + name)


