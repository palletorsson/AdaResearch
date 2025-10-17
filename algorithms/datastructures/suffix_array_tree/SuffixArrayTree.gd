extends Node3D

# Suffix Array and Suffix Tree Visualization
# Demonstrates string processing data structures

var time := 0.0
var pattern_timer := 0.0
var text := "BANANA$"
var pattern := "ANA"
var suffix_array := []
var lcp_array := []  # Longest Common Prefix array

# Suffix tree structure (simplified)
class SuffixNode:
	var children := {}
	var suffix_link: SuffixNode
	var start: int
	var end: int
	var is_leaf := false

var suffix_tree_root: SuffixNode
var current_pattern_index := 0

func _ready():
	build_suffix_array()
	build_lcp_array()
	build_suffix_tree()

func _process(delta):
	time += delta
	pattern_timer += delta
	
	visualize_suffix_array()
	visualize_suffix_tree()
	demonstrate_pattern_matching()
	show_string_processing()

func build_suffix_array():
	var suffixes = []
	
	# Generate all suffixes with their starting indices
	for i in range(text.length()):
		suffixes.append([text.substr(i), i])
	
	# Sort suffixes lexicographically
	suffixes.sort_custom(func(a, b): return a[0] < b[0])
	
	# Extract the suffix array (starting indices)
	suffix_array.clear()
	for suffix in suffixes:
		suffix_array.append(suffix[1])

func build_lcp_array():
	lcp_array.clear()
	lcp_array.resize(suffix_array.size())
	lcp_array[0] = 0
	
	for i in range(1, suffix_array.size()):
		var suffix1 = text.substr(suffix_array[i - 1])
		var suffix2 = text.substr(suffix_array[i])
		var lcp_length = 0
		
		var min_length = min(suffix1.length(), suffix2.length())
		for j in range(min_length):
			if suffix1[j] == suffix2[j]:
				lcp_length += 1
			else:
				break
		
		lcp_array[i] = lcp_length

func build_suffix_tree():
	# Simplified suffix tree construction
	suffix_tree_root = SuffixNode.new()
	suffix_tree_root.start = -1
	suffix_tree_root.end = -1
	
	# Insert each suffix (simplified approach)
	for i in range(text.length()):
		insert_suffix(suffix_tree_root, i)

func insert_suffix(node: SuffixNode, suffix_start: int):
	var suffix = text.substr(suffix_start)
	
	if suffix.is_empty():
		return
	
	var first_char = suffix[0]
	
	if first_char not in node.children:
		# Create new leaf node
		var leaf = SuffixNode.new()
		leaf.start = suffix_start
		leaf.end = text.length() - 1
		leaf.is_leaf = true
		node.children[first_char] = leaf
	else:
		# Continue with existing edge
		var child = node.children[first_char]
		var edge_label = text.substr(child.start, child.end - child.start + 1)
		
		# Find common prefix length
		var common_length = 0
		var min_length = min(suffix.length(), edge_label.length())
		
		for i in range(min_length):
			if suffix[i] == edge_label[i]:
				common_length += 1
			else:
				break
		
		if common_length < edge_label.length():
			# Split the edge
			var internal_node = SuffixNode.new()
			internal_node.start = child.start
			internal_node.end = child.start + common_length - 1
			
			# Update child
			child.start = child.start + common_length
			
			# Insert the new internal node
			node.children[first_char] = internal_node
			internal_node.children[text[child.start]] = child
			
			# Insert remaining suffix
			if common_length < suffix.length():
				var new_leaf = SuffixNode.new()
				new_leaf.start = suffix_start + common_length
				new_leaf.end = text.length() - 1
				new_leaf.is_leaf = true
				internal_node.children[suffix[common_length]] = new_leaf
		elif common_length < suffix.length():
			# Continue with child
			insert_suffix(child, suffix_start + common_length)

func visualize_suffix_array():
	var container = $SuffixArray
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show suffix array indices
	for i in range(suffix_array.size()):
		var index_value = suffix_array[i]
		
		# Create element for suffix array index
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, 0.8, 0.8)
		element.position = Vector3(i * 1.0 - suffix_array.size() * 0.5, 0, 0)
		
		var material = StandardMaterial3D.new()
		var color_intensity = float(index_value) / text.length()
		material.albedo_color = Color(color_intensity, 0.7, 1.0 - color_intensity)
		material.emission_enabled = true
		material.emission = Color(color_intensity, 0.7, 1.0 - color_intensity) * 0.3
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
		
		# Show LCP value
		var lcp_height = lcp_array[i] * 0.3 + 0.1
		var lcp_element = CSGCylinder3D.new()
		lcp_element.radius = 0.15
		
		lcp_element.height = lcp_height
		lcp_element.position = Vector3(i * 1.0 - suffix_array.size() * 0.5, lcp_height * 0.5 + 1.5, 0)
		
		var lcp_material = StandardMaterial3D.new()
		lcp_material.albedo_color = Color(1.0, 0.5, 0.0)
		lcp_material.emission_enabled = true
		lcp_material.emission = Color(1.0, 0.5, 0.0) * 0.3
		lcp_element.material_override = lcp_material
		
		container.add_child(lcp_element)
		
		# Show corresponding suffix (first few characters)
		var suffix = text.substr(index_value)
		show_suffix_chars(container, suffix.substr(0, min(3, suffix.length())), Vector3(i * 1.0 - suffix_array.size() * 0.5, -1.5, 0))

func show_suffix_chars(container: Node3D, chars: String, position: Vector3):
	for i in range(chars.length()):
		var char_cube = CSGBox3D.new()
		char_cube.size = Vector3(0.2, 0.2, 0.2)
		char_cube.position = position + Vector3((i - chars.length() * 0.5) * 0.25, 0, 0)
		
		var material = StandardMaterial3D.new()
		# Color based on character
		var char_code = chars[i].to_ascii_buffer()[0]
		var color_value = float(char_code - 65) / 26.0  # Assuming uppercase letters
		material.albedo_color = Color(color_value, 1.0 - color_value, 0.5)
		material.emission_enabled = true
		material.emission = Color(color_value, 1.0 - color_value, 0.5) * 0.2
		char_cube.material_override = material
		
		container.add_child(char_cube)

func visualize_suffix_tree():
	var container = $SuffixTree
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize suffix tree structure
	visualize_tree_node(container, suffix_tree_root, Vector3(0, 0, 0), 0, 8.0)

func visualize_tree_node(container: Node3D, node: SuffixNode, position: Vector3, depth: int, spacing: float):
	if not node:
		return
	
	# Create node representation
	var node_sphere = CSGSphere3D.new()
	node_sphere.radius = 0.3
	node_sphere.position = position
	
	var material = StandardMaterial3D.new()
	if node.is_leaf:
		material.albedo_color = Color(0.2, 1.0, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.2, 1.0, 0.2) * 0.4
	else:
		var depth_ratio = min(float(depth) / 4.0, 1.0)
		material.albedo_color = Color(1.0 - depth_ratio, 0.5, depth_ratio)
		material.emission_enabled = true
		material.emission = Color(1.0 - depth_ratio, 0.5, depth_ratio) * 0.2
	
	material.metallic = 0.3
	material.roughness = 0.4
	node_sphere.material_override = material
	
	container.add_child(node_sphere)
	
	# Create children
	var child_index = 0
	var child_spacing = spacing / max(1, node.children.size())
	
	for char in node.children:
		var child = node.children[char]
		var child_position = position + Vector3(
			(child_index - float(node.children.size() - 1) * 0.5) * child_spacing,
			-2.0,
			0
		)
		
		# Create edge
		create_tree_edge(container, position, child_position, char)
		
		# Recursively create child
		visualize_tree_node(container, child, child_position, depth + 1, child_spacing)
		
		child_index += 1

func create_tree_edge(container: Node3D, from: Vector3, to: Vector3, edge_char: String):
	var distance = from.distance_to(to)
	var edge = CSGCylinder3D.new()
	edge.radius = 0.05
	
	edge.height = distance
	
	edge.position = (from + to) * 0.5
	edge.look_at(to, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	edge.material_override = material
	
	container.add_child(edge)
	
	# Add character label
	var char_label = CSGBox3D.new()
	char_label.size = Vector3(0.15, 0.15, 0.15)
	char_label.position = (from + to) * 0.5 + Vector3(0.3, 0, 0)
	
	var label_material = StandardMaterial3D.new()
	var char_code = edge_char.to_ascii_buffer()[0] if edge_char.length() > 0 else 65
	var color_value = float(char_code - 65) / 26.0
	label_material.albedo_color = Color(color_value, 1.0 - color_value, 0.5)
	label_material.emission_enabled = true
	label_material.emission = Color(color_value, 1.0 - color_value, 0.5) * 0.4
	char_label.material_override = label_material
	
	container.add_child(char_label)

func demonstrate_pattern_matching():
	var container = $PatternMatching
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update pattern search periodically
	if pattern_timer > 2.0:
		pattern_timer = 0.0
		current_pattern_index = (current_pattern_index + 1) % (text.length() - pattern.length() + 1)
	
	# Show text with pattern highlighting
	for i in range(text.length()):
		var char_cube = CSGBox3D.new()
		char_cube.size = Vector3(0.6, 0.6, 0.6)
		char_cube.position = Vector3(i * 0.8 - text.length() * 0.4, 0, 0)
		
		var material = StandardMaterial3D.new()
		
		# Check if this position starts a pattern match
		var is_pattern_start = false
		if i + pattern.length() <= text.length():
			var substring = text.substr(i, pattern.length())
			if substring == pattern:
				is_pattern_start = true
		
		# Check if this character is part of the currently highlighted pattern
		var in_current_pattern = (i >= current_pattern_index and i < current_pattern_index + pattern.length())
		
		if is_pattern_start and in_current_pattern:
			material.albedo_color = Color(1.0, 0.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.0, 0.0) * 0.6
		elif in_current_pattern:
			material.albedo_color = Color(1.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.0) * 0.4
		else:
			material.albedo_color = Color(0.5, 0.5, 0.5)
		
		material.metallic = 0.3
		material.roughness = 0.4
		char_cube.material_override = material
		
		container.add_child(char_cube)
	
	# Show pattern separately
	for i in range(pattern.length()):
		var pattern_cube = CSGSphere3D.new()
		pattern_cube.radius = 0.25
		pattern_cube.position = Vector3(i * 0.6 - pattern.length() * 0.3, 2, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.0, 1.0, 0.0)
		material.emission_enabled = true
		material.emission = Color(0.0, 1.0, 0.0) * 0.5
		pattern_cube.material_override = material
		
		container.add_child(pattern_cube)

func show_string_processing():
	var container = $StringProcessing
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show string processing operations
	var operations = ["Find", "Count", "Replace", "Extract"]
	
	for i in range(operations.size()):
		var op_box = CSGBox3D.new()
		op_box.size = Vector3(1.5, 0.8, 0.8)
		op_box.position = Vector3(i * 2.0 - operations.size() * 1.0, 0, 0)
		
		var material = StandardMaterial3D.new()
		var color_cycle = float(i) / operations.size()
		material.albedo_color = Color(
			sin(color_cycle * TAU) * 0.5 + 0.5,
			sin(color_cycle * TAU + TAU/3) * 0.5 + 0.5,
			sin(color_cycle * TAU + 2*TAU/3) * 0.5 + 0.5
		)
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.3
		material.metallic = 0.3
		material.roughness = 0.4
		op_box.material_override = material
		
		container.add_child(op_box)
		
		# Add operation indicator
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.2 + sin(time * 2 + i) * 0.1
		indicator.position = Vector3(i * 2.0 - operations.size() * 1.0, 1.5, 0)
		
		var indicator_material = StandardMaterial3D.new()
		indicator_material.albedo_color = Color(1.0, 1.0, 1.0)
		indicator_material.emission_enabled = true
		indicator_material.emission = Color(1.0, 1.0, 1.0) * 0.8
		indicator.material_override = indicator_material
		
		container.add_child(indicator)
