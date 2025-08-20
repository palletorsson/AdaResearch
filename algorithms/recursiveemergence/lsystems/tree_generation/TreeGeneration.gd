extends Node3D

var time = 0.0
var generation = 0
var max_generations = 6
var current_string = "F"
var generation_timer = 0.0
var generation_interval = 2.0

# L-System rules
var rules = {
	"F": "F[+F]F[-F]F",  # Forward with branches
	"+": "+",             # Turn left
	"-": "-",             # Turn right
	"[": "[",             # Push state
	"]": "]"              # Pop state
}

# Drawing state
var turtle_stack = []
var branch_segments = []
var leaf_positions = []

func _ready():
	setup_materials()
	generate_initial_tree()

func setup_materials():
	# Root material
	var root_material = StandardMaterial3D.new()
	root_material.albedo_color = Color(0.6, 0.4, 0.2, 1.0)
	root_material.emission_enabled = true
	root_material.emission = Color(0.2, 0.1, 0.05, 1.0)
	$TreeRoot.material_override = root_material
	
	# Generation indicator material
	var gen_material = StandardMaterial3D.new()
	gen_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	gen_material.emission_enabled = true
	gen_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$GenerationIndicator.material_override = gen_material
	
	# Rule display material
	var rule_material = StandardMaterial3D.new()
	rule_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	rule_material.emission_enabled = true
	rule_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$RuleDisplay.material_override = rule_material

func generate_initial_tree():
	current_string = "F"
	generation = 0
	clear_tree()
	draw_tree()

func clear_tree():
	# Clear existing branches and leaves
	for child in $TreeBranches.get_children():
		child.queue_free()
	for child in $TreeLeaves.get_children():
		child.queue_free()
	
	branch_segments.clear()
	leaf_positions.clear()

func apply_lsystem_rules():
	var new_string = ""
	for char in current_string:
		if char in rules:
			new_string += rules[char]
		else:
			new_string += char
	current_string = new_string

func draw_tree():
	clear_tree()
	
	# Turtle graphics interpretation
	var position = Vector3(0, -3, 0)
	var direction = Vector3(0, 1, 0)
	var angle = 25.0 * PI / 180.0  # 25 degrees in radians
	var step_length = 0.8 / (generation + 1)  # Shorter branches each generation
	var thickness = 0.05 * max(1.0, 4.0 - generation)  # Thinner branches each generation
	
	turtle_stack.clear()
	
	for char in current_string:
		match char:
			"F":
				# Draw forward
				var new_position = position + direction * step_length
				create_branch_segment(position, new_position, thickness)
				position = new_position
				
				# Add leaf at end if this is a terminal branch
				if generation >= 3:
					create_leaf(position)
			
			"+":
				# Turn left (rotate around z-axis)
				direction = direction.rotated(Vector3(0, 0, 1), angle)
			
			"-":
				# Turn right (rotate around z-axis)
				direction = direction.rotated(Vector3(0, 0, 1), -angle)
			
			"[":
				# Push current state
				turtle_stack.push_back({"pos": position, "dir": direction})
			
			"]":
				# Pop previous state
				if turtle_stack.size() > 0:
					var state = turtle_stack.pop_back()
					position = state.pos
					direction = state.dir

func create_branch_segment(start_pos, end_pos, thickness):
	var branch = CSGCylinder3D.new()
	var length = start_pos.distance_to(end_pos)
	
	branch.height = length
	branch.radius = thickness * 1.2
	
	# Position and orient the cylinder
	var mid_point = (start_pos + end_pos) * 0.5
	branch.position = mid_point
	
	# Orient the cylinder to point from start to end
	var up_vector = (end_pos - start_pos).normalized()
	if up_vector != Vector3.UP:
		var right_vector = Vector3.UP.cross(up_vector).normalized()
		var forward_vector = up_vector.cross(right_vector).normalized()
		branch.transform.basis = Basis(right_vector, up_vector, forward_vector)
	
	# Material based on generation
	var branch_material = StandardMaterial3D.new()
	var brown_intensity = 1.0 - generation * 0.15
	branch_material.albedo_color = Color(0.6 * brown_intensity, 0.4 * brown_intensity, 0.2 * brown_intensity, 1.0)
	branch_material.emission_enabled = true
	branch_material.emission = Color(0.1 * brown_intensity, 0.05 * brown_intensity, 0.02 * brown_intensity, 1.0)
	branch.material_override = branch_material
	
	$TreeBranches.add_child(branch)
	branch_segments.append(branch)

func create_leaf(position):
	var leaf = CSGSphere3D.new()
	leaf.radius = 0.08 + randf() * 0.04
	leaf.position = position + Vector3(randf() * 0.2 - 0.1, 0, randf() * 0.2 - 0.1)
	
	# Leaf material
	var leaf_material = StandardMaterial3D.new()
	var green_variation = 0.8 + randf() * 0.4
	leaf_material.albedo_color = Color(0.2, 0.8 * green_variation, 0.3, 1.0)
	leaf_material.emission_enabled = true
	leaf_material.emission = Color(0.05, 0.2 * green_variation, 0.08, 1.0)
	leaf.material_override = leaf_material
	
	$TreeLeaves.add_child(leaf)
	leaf_positions.append(leaf)

func _process(delta):
	time += delta
	generation_timer += delta
	
	# Generate next generation
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		if generation < max_generations:
			generation += 1
			apply_lsystem_rules()
			draw_tree()
		else:
			# Reset to start
			generate_initial_tree()
	
	animate_growth()
	animate_indicators()

func animate_growth():
	# Animate branch growth
	var growth_progress = generation_timer / generation_interval
	for i in range(branch_segments.size()):
		var branch = branch_segments[i]
		if branch and is_instance_valid(branch):
			var scale_factor = min(1.0, growth_progress * 2.0 - i * 0.1)
			scale_factor = max(0.0, scale_factor)
			branch.scale.y = scale_factor
			
			# Glow effect during growth
			var material = branch.material_override as StandardMaterial3D
			if material:
				var glow_intensity = (1.0 - scale_factor) * 0.5
				material.emission = material.emission * (1.0 + glow_intensity)
	
	# Animate leaf appearance
	for i in range(leaf_positions.size()):
		var leaf = leaf_positions[i]
		if leaf and is_instance_valid(leaf):
			var appear_progress = max(0.0, growth_progress * 1.5 - i * 0.05)
			leaf.scale = Vector3.ONE * min(1.0, appear_progress)

func animate_indicators():
	# Generation indicator height
	var gen_height = (generation + 1) * 0.3
	var generationindicator = get_node_or_null("GenerationIndicator")
	if generationindicator and generationindicator is CSGCylinder3D:
		generationindicator.height = gen_height
		generationindicator.position.y = -2 + gen_height/2
	
	# Rule display pulsing
	var pulse = 1.0 + sin(time * 3.0) * 0.2
	$RuleDisplay.scale = Vector3.ONE * pulse
	
	# Gentle swaying of leaves
	for leaf in leaf_positions:
		if leaf and is_instance_valid(leaf):
			var sway = sin(time * 2.0 + leaf.position.x) * 0.1
			leaf.position.x += sway * 0.01
