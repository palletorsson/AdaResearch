extends Node3D

# Context-Free Grammars Visualization
# Language generation rules and parse trees

var time := 0.0
var derivation_step := 0
var current_string := "S"

# CFG Rules: S -> AB, A -> aA | a, B -> bB | b
var grammar_rules := {
	"S": [["A", "B"]],
	"A": [["a", "A"], ["a"]],
	"B": [["b", "B"], ["b"]]
}

var derivation_history := []
var parse_tree_nodes := []

func _ready():
	initialize_grammar()

func _process(delta):
	time += delta
	
	if int(time * 0.5) != derivation_step:
		derivation_step = int(time * 0.5)
		if derivation_step % 8 == 0:
			reset_derivation()
		else:
			apply_derivation_step()
	
	visualize_grammar_rules()
	show_parse_tree()
	demonstrate_derivation()
	display_language_generation()

func initialize_grammar():
	current_string = "S"
	derivation_history = [current_string]
	parse_tree_nodes.clear()

func reset_derivation():
	initialize_grammar()

func apply_derivation_step():
	var new_string = ""
	var changed = false
	
	for i in range(current_string.length()):
		var symbol = current_string[i]
		
		if symbol in grammar_rules and not changed:
			var rules = grammar_rules[symbol]
			var chosen_rule = rules[randi() % rules.size()]
			new_string += "".join(chosen_rule)
			changed = true
		else:
			new_string += symbol
	
	if changed:
		current_string = new_string
		derivation_history.append(current_string)

func visualize_grammar_rules():
	var container = $GrammarRules
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	var rule_index = 0
	for non_terminal in grammar_rules:
		var rules = grammar_rules[non_terminal]
		
		# Non-terminal symbol
		var nt_sphere = CSGSphere3D.new()
		nt_sphere.radius = 0.3
		nt_sphere.position = Vector3(-4, rule_index * 2, 0)
		
		var nt_material = StandardMaterial3D.new()
		nt_material.albedo_color = Color(0.2, 0.8, 1.0)
		nt_material.emission_enabled = true
		nt_material.emission = Color(0.2, 0.8, 1.0) * 0.4
		nt_sphere.material_override = nt_material
		
		container.add_child(nt_sphere)
		
		# Production rules
		for rule_idx in range(rules.size()):
			var rule = rules[rule_idx]
			
			for symbol_idx in range(rule.size()):
				var symbol = rule[symbol_idx]
				
				var symbol_cube = CSGBox3D.new()
				symbol_cube.size = Vector3(0.4, 0.4, 0.4)
				symbol_cube.position = Vector3(
					-2 + symbol_idx * 0.6 + rule_idx * 2,
					rule_index * 2,
					0
				)
				
				var symbol_material = StandardMaterial3D.new()
				if symbol in grammar_rules:
					symbol_material.albedo_color = Color(0.2, 0.8, 1.0)
				else:
					symbol_material.albedo_color = Color(1.0, 0.8, 0.2)
				
				symbol_cube.material_override = symbol_material
				container.add_child(symbol_cube)
		
		rule_index += 1

func show_parse_tree():
	var container = $ParseTree
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create simplified parse tree
	create_parse_tree_recursive(container, "S", Vector3.ZERO, 0, 3, 3.0)

func create_parse_tree_recursive(container: Node3D, symbol: String, position: Vector3, depth: int, max_depth: int, spacing: float):
	if depth >= max_depth:
		return
	
	# Create node
	var node = CSGSphere3D.new()
	node.radius = 0.2
	node.position = position
	
	var material = StandardMaterial3D.new()
	if symbol in grammar_rules:
		material.albedo_color = Color(0.2, 0.8, 1.0)
	else:
		material.albedo_color = Color(1.0, 0.8, 0.2)
	
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	node.material_override = material
	
	container.add_child(node)
	
	# Create children
	if symbol in grammar_rules:
		var rules = grammar_rules[symbol]
		var rule = rules[0]  # Use first rule for visualization
		
		var child_spacing = spacing / rule.size()
		for i in range(rule.size()):
			var child_symbol = rule[i]
			var child_pos = position + Vector3(
				(i - float(rule.size() - 1) * 0.5) * child_spacing,
				-1.5,
				0
			)
			
			# Create connection
			var connection = CSGCylinder3D.new()
			connection.top_radius = 0.02
			connection.bottom_radius = 0.02
			connection.height = position.distance_to(child_pos)
			
			connection.position = (position + child_pos) * 0.5
			connection.look_at(child_pos, Vector3.UP)
			connection.rotate_object_local(Vector3.RIGHT, PI / 2)
			
			var conn_material = StandardMaterial3D.new()
			conn_material.albedo_color = Color(0.6, 0.6, 0.6)
			connection.material_override = conn_material
			
			container.add_child(connection)
			
			# Recursive call
			create_parse_tree_recursive(container, child_symbol, child_pos, depth + 1, max_depth, child_spacing)

func demonstrate_derivation():
	var container = $DerivationProcess
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show derivation steps
	for step in range(min(6, derivation_history.size())):
		var step_string = derivation_history[step]
		
		for i in range(step_string.length()):
			var symbol = step_string[i]
			
			var symbol_cube = CSGBox3D.new()
			symbol_cube.size = Vector3(0.3, 0.3, 0.3)
			symbol_cube.position = Vector3(
				i * 0.4 - step_string.length() * 0.2,
				-step * 0.8,
				0
			)
			
			var material = StandardMaterial3D.new()
			if symbol in grammar_rules:
				material.albedo_color = Color(0.2, 0.8, 1.0)
				material.emission_enabled = true
				material.emission = Color(0.2, 0.8, 1.0) * 0.4
			else:
				material.albedo_color = Color(1.0, 0.8, 0.2)
			
			symbol_cube.material_override = material
			container.add_child(symbol_cube)

func display_language_generation():
	var container = $LanguageGeneration
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Generate multiple strings
	var strings = generate_language_samples(8)
	
	for string_idx in range(strings.size()):
		var generated_string = strings[string_idx]
		
		for symbol_idx in range(generated_string.length()):
			var symbol = generated_string[symbol_idx]
			
			var symbol_sphere = CSGSphere3D.new()
			symbol_sphere.radius = 0.15
			symbol_sphere.position = Vector3(
				symbol_idx * 0.4 - generated_string.length() * 0.2,
				0,
				string_idx * 0.6 - strings.size() * 0.3
			)
			
			var material = StandardMaterial3D.new()
			if symbol == "a":
				material.albedo_color = Color(1.0, 0.2, 0.2)
			else:
				material.albedo_color = Color(0.2, 1.0, 0.2)
			
			material.emission_enabled = true
			material.emission = material.albedo_color * 0.4
			symbol_sphere.material_override = material
			
			container.add_child(symbol_sphere)

func generate_language_samples(count: int) -> Array:
	var samples = []
	
	for i in range(count):
		var sample = generate_string_from_grammar("S", 5)
		samples.append(sample)
	
	return samples

func generate_string_from_grammar(start_symbol: String, max_steps: int) -> String:
	var current = start_symbol
	
	for step in range(max_steps):
		var new_string = ""
		var changed = false
		
		for i in range(current.length()):
			var symbol = current[i]
			
			if symbol in grammar_rules:
				var rules = grammar_rules[symbol]
				var chosen_rule = rules[randi() % rules.size()]
				new_string += "".join(chosen_rule)
				changed = true
			else:
				new_string += symbol
		
		current = new_string
		
		if not changed:
			break
	
	return current

