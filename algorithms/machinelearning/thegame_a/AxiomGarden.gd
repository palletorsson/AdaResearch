extends Node3D
class_name AxiomGarden

# The Axiom Garden - Iteration 4: The Gardener
# Main Game Controller

@export var generations: int = 4
@export var step_length: float = 0.5
@export var angle: float = 25.0
@export var max_segments: int = 2000

var lsystem: AxiomGardenLSystem
var turtle: Turtle
var renderer: GardenRenderer


# UI References
@onready var rule_input: LineEdit = $UI/Panel/RuleInput
@onready var grow_button: Button = $UI/Panel/GrowButton
@onready var next_button: Button = $UI/Panel/NextButton
@onready var prev_button: Button = $UI/Panel/PrevButton
@onready var label: Label = $UI/Panel/SolutionLabel

var solutions = [
	{ "name": "The Seed", "rule": "F=F[+F]F[-F]", "gens": 4, "angle": 25.0 },
	{ "name": "The Ladder", "rule": "F=FF", "gens": 3, "angle": 25.0 },
	{ "name": "The Bush", "rule": "F=FF-[-F+F+F]+[+F-F-F]", "gens": 3, "angle": 22.5 },
	{ "name": "The Vine", "rule": "F=F[+F]F[-F][F]", "gens": 4, "angle": 20.0 },
	{ "name": "The Dragon", "rule": "X=X+YF+,Y=-FX-Y", "gens": 10, "angle": 90.0, "axiom": "FX" }, # Dragon Curve
	{ "name": "The Fern", "rule": "X=F+[[X]-X]-F[-FX]+X,F=FF", "gens": 4, "angle": 25.0, "axiom": "X" }
]

var current_solution_index: int = 0

func _ready() -> void:
	# Initialize components
	lsystem = AxiomGardenLSystem.new("F", {"F": "F[+F]F[-F]"})
	turtle = Turtle.new()
	
	# Find or create renderer
	renderer = $GardenRenderer
	if not renderer:
		renderer = GardenRenderer.new()
		renderer.name = "GardenRenderer"
		add_child(renderer)
		
	# Setup UI connections
	if grow_button: grow_button.pressed.connect(_on_grow_pressed)
	if next_button: next_button.pressed.connect(_on_next_pressed)
	if prev_button: prev_button.pressed.connect(_on_prev_pressed)
		
	# Load first solution
	load_solution(0)

func load_solution(index: int) -> void:
	if index < 0: index = solutions.size() - 1
	if index >= solutions.size(): index = 0
	
	current_solution_index = index
	var sol = solutions[index]
	
	# Update UI
	if rule_input: rule_input.text = sol["rule"]
	if label: label.text = str(index + 1) + "/" + str(solutions.size()) + ": " + sol["name"]
	
	# Update System
	var axiom = sol.get("axiom", "F")
	lsystem = AxiomGardenLSystem.new(axiom, {})
	
	# Parse rule string "A=B,C=D"
	var rule_parts = sol["rule"].split(",")
	for part in rule_parts:
		var p = part.split("=")
		if p.size() == 2:
			lsystem.set_rule(p[0].strip_edges(), p[1].strip_edges())
			
	generations = sol["gens"]
	angle = sol["angle"]
	
	grow_garden()

func _on_next_pressed() -> void:
	load_solution(current_solution_index + 1)

func _on_prev_pressed() -> void:
	load_solution(current_solution_index - 1)


func grow_garden() -> void:
	# 1. Generate String
	var sequence = lsystem.generate(generations)
	print("Generated sequence length: " + str(sequence.length()))
	
	# 2. Turtle Interpretation
	turtle.step_length = step_length
	turtle.angle_degrees = angle
	var lines = turtle.process_string(sequence)
	
	# Constraint Check
	if lines.size() > max_segments:
		print("GARDEN WITHERED: Too complex! (" + str(lines.size()) + "/" + str(max_segments) + ")")
		# Render nothing or render "dead" state
		# For now, we'll just clear the renderer
		renderer.render([])
		return
	
	# 3. Render
	renderer.render(lines)
	
	# 4. Check Collisions
	if check_collisions(lines):
		print("GARDEN BLOCKED: Plant hit an obstacle!")
		# Visual feedback could be turning the plant red
		# For now, we just print
		return

	# 5. Check Goals
	check_goals(lines)

func check_collisions(lines: Array) -> bool:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return false
		
	for segment in lines:
		var start = segment[0]
		var end = segment[1]
		
		var query = PhysicsRayQueryParameters3D.create(start, end)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			if collider.is_in_group("obstacles"):
				return true
				
	return false


func check_goals(lines: Array) -> void:
	var targets = get_tree().get_nodes_in_group("targets")
	if targets.is_empty():
		return
		
	for target in targets:
		var t_pos = target.global_position
		var t_radius = target.radius
		var reached = false
		
		for segment in lines:
			# Check both endpoints
			if segment[0].distance_to(t_pos) < t_radius or segment[1].distance_to(t_pos) < t_radius:
				reached = true
				break
		
		if reached:
			print("Target reached: " + target.name)
			target.emit_signal("target_reached")


func _on_grow_pressed() -> void:
	if rule_input:
		var text = rule_input.text
		# Parse rule: "F=F[+F]"
		var parts = text.split("=")
		if parts.size() == 2:
			var predecessor = parts[0].strip_edges()
			var successor = parts[1].strip_edges()
			lsystem.set_rule(predecessor, successor)
			print("Rule updated: " + predecessor + " -> " + successor)
			grow_garden()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
