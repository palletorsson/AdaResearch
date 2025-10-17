extends Node3D

var time = 0.0
var operation_timer = 0.0
var operation_interval = 3.0
var word_count = 0
var current_search_word = ""
var search_path = []

# Trie operations
enum TrieOperation {
	INSERT_WORD,
	SEARCH_WORD,
	DELETE_WORD,
	PREFIX_SEARCH,
	AUTOCOMPLETE
}

var current_operation = TrieOperation.INSERT_WORD

# Trie node structure
class TrieNode:
	var character: String
	var children: Dictionary = {}
	var is_end_of_word: bool = false
	var visual_object: CSGSphere3D
	var parent: TrieNode
	var level: int = 0
	var position_in_level: int = 0
	
	func _init(char: String = ""):
		character = char
		children = {}
		is_end_of_word = false
		parent = null

var root: TrieNode
var all_nodes = []
var trie_edges = []
var inserted_words = []

func _ready():
	setup_materials()
	initialize_trie()
	insert_initial_words()

func setup_materials():
	# Root node material
	var root_material = StandardMaterial3D.new()
	root_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	root_material.emission_enabled = true
	root_material.emission = Color(0.3, 0.3, 0.1, 1.0)
	$RootNode.material_override = root_material
	
	# Word counter material
	var counter_material = StandardMaterial3D.new()
	counter_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	counter_material.emission_enabled = true
	counter_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$WordCounter.material_override = counter_material
	
	# Prefix indicator material
	var prefix_material = StandardMaterial3D.new()
	prefix_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
	prefix_material.emission_enabled = true
	prefix_material.emission = Color(0.3, 0.15, 0.05, 1.0)
	$PrefixIndicator.material_override = prefix_material

func initialize_trie():
	root = TrieNode.new("")
	root.visual_object = $RootNode
	all_nodes.append(root)

func insert_initial_words():
	var initial_words = ["cat", "car", "card", "care", "careful", "cars", "carry"]
	for word in initial_words:
		insert_word(word)

func _process(delta):
	time += delta
	operation_timer += delta
	
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		perform_trie_operation()
	
	animate_trie()
	animate_indicators()

func perform_trie_operation():
	current_operation = (current_operation + 1) % TrieOperation.size()
	
	match current_operation:
		TrieOperation.INSERT_WORD:
			var words = ["dog", "dogs", "dodge", "door", "down", "download", "do"]
			var random_word = words[randi() % words.size()]
			if not random_word in inserted_words:
				insert_word(random_word)
		
		TrieOperation.SEARCH_WORD:
			if inserted_words.size() > 0:
				current_search_word = inserted_words[randi() % inserted_words.size()]
				search_word(current_search_word)
		
		TrieOperation.DELETE_WORD:
			if inserted_words.size() > 3:  # Keep minimum words
				var word_to_delete = inserted_words[randi() % inserted_words.size()]
				delete_word(word_to_delete)
		
		TrieOperation.PREFIX_SEARCH:
			var prefixes = ["ca", "car", "do", "d"]
			var prefix = prefixes[randi() % prefixes.size()]
			search_prefix(prefix)
		
		TrieOperation.AUTOCOMPLETE:
			demonstrate_autocomplete()

func insert_word(word: String):
	if word in inserted_words:
		return
	
	var current_node = root
	
	for i in range(word.length()):
		var char = word[i]
		
		if not char in current_node.children:
			# Create new node
			var new_node = TrieNode.new(char)
			new_node.parent = current_node
			new_node.level = current_node.level + 1
			current_node.children[char] = new_node
			
			# Create visual representation
			create_visual_node(new_node)
			all_nodes.append(new_node)
		
		current_node = current_node.children[char]
	
	current_node.is_end_of_word = true
	inserted_words.append(word)
	word_count += 1
	
	calculate_positions()
	update_edges()
	update_end_of_word_visuals()

func search_word(word: String) -> bool:
	search_path.clear()
	var current_node = root
	search_path.append(current_node)
	
	for char in word:
		if char in current_node.children:
			current_node = current_node.children[char]
			search_path.append(current_node)
		else:
			return false
	
	return current_node.is_end_of_word

func delete_word(word: String):
	if not word in inserted_words:
		return
	
	var current_node = root
	var nodes_in_path = [current_node]
	
	# Find the path to the word
	for char in word:
		if char in current_node.children:
			current_node = current_node.children[char]
			nodes_in_path.append(current_node)
		else:
			return  # Word not found
	
	if not current_node.is_end_of_word:
		return  # Not a complete word
	
	current_node.is_end_of_word = false
	inserted_words.erase(word)
	word_count -= 1
	
	# Delete nodes that are no longer needed
	delete_unnecessary_nodes(nodes_in_path, word)
	
	calculate_positions()
	update_edges()
	update_end_of_word_visuals()

func delete_unnecessary_nodes(path: Array, word: String):
	# Start from the end and work backwards
	for i in range(path.size() - 1, 0, -1):
		var node = path[i]
		
		# Keep node if it's end of another word or has children
		if node.is_end_of_word or node.children.size() > 0:
			break
		
		# Remove this node
		var parent = node.parent
		if parent:
			parent.children.erase(node.character)
		
		node.visual_object.queue_free()
		all_nodes.erase(node)

func search_prefix(prefix: String):
	search_path.clear()
	var current_node = root
	search_path.append(current_node)
	
	for char in prefix:
		if char in current_node.children:
			current_node = current_node.children[char]
			search_path.append(current_node)
		else:
			search_path.clear()
			return
	
	# Collect all words with this prefix
	collect_words_with_prefix(current_node, prefix)

func collect_words_with_prefix(node: TrieNode, current_prefix: String):
	# This is used for prefix search visualization
	if node.is_end_of_word:
		# Found a complete word with the prefix
		pass
	
	for char in node.children:
		collect_words_with_prefix(node.children[char], current_prefix + char)

func demonstrate_autocomplete():
	# Show autocomplete for "car"
	search_prefix("car")

func create_visual_node(node: TrieNode):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.2
	
	# Material based on character and level
	var node_material = StandardMaterial3D.new()
	var char_code = 0
	if node.character.length() > 0:
		char_code = node.character.unicode_at(0)
	
	var color_intensity = (char_code % 26) / 26.0
	node_material.albedo_color = Color(
		0.3 + color_intensity * 0.4,
		0.3 + (1.0 - color_intensity) * 0.5,
		0.8,
		1.0
	)
	node_material.emission_enabled = true
	node_material.emission = node_material.albedo_color * 0.3
	sphere.material_override = node_material
	
	$TrieNodes.add_child(sphere)
	node.visual_object = sphere

func calculate_positions():
	# Organize nodes by level
	var levels = {}
	for node in all_nodes:
		if not node.level in levels:
			levels[node.level] = []
		levels[node.level].append(node)
	
	# Position nodes level by level
	for level in levels:
		var nodes_in_level = levels[level]
		for i in range(nodes_in_level.size()):
			var node = nodes_in_level[i]
			node.position_in_level = i
			
			# Calculate x position
			var level_width = max(8.0, nodes_in_level.size() * 1.5)
			var x_offset = (i - (nodes_in_level.size() - 1) / 2.0) * level_width / nodes_in_level.size()
			
			# Calculate y position
			var y_position = 3 - level * 1.2
			
			node.visual_object.position = Vector3(x_offset, y_position, 0)

func update_edges():
	# Clear existing edges
	for edge in trie_edges:
		edge.queue_free()
	trie_edges.clear()
	
	# Create new edges
	for node in all_nodes:
		if node.parent and node != root:
			create_trie_edge(node.parent, node)

func create_trie_edge(parent: TrieNode, child: TrieNode):
	var edge = CSGCylinder3D.new()
	var parent_pos = parent.visual_object.position
	var child_pos = child.visual_object.position
	var distance = parent_pos.distance_to(child_pos)
	
	edge.height = distance
	edge.radius = 0.03
	
	
	# Position and orient edge
	var mid_point = (parent_pos + child_pos) * 0.5
	edge.position = mid_point
	
	# Orient edge
	var direction = (child_pos - parent_pos).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction)
		if axis.length() > 0.001:  # Check if axis is not zero
			axis = axis.normalized()
			var angle = acos(Vector3.UP.dot(direction))
			edge.transform.basis = Basis(axis, angle)
	
	# Edge material with character label color
	var edge_material = StandardMaterial3D.new()
	var char_code = child.character.unicode_at(0) if child.character.length() > 0 else 0
	var color_intensity = (char_code % 26) / 26.0
	edge_material.albedo_color = Color(
		0.5 + color_intensity * 0.3,
		0.5 + (1.0 - color_intensity) * 0.3,
		0.7,
		1.0
	)
	edge_material.emission_enabled = true
	edge_material.emission = edge_material.albedo_color * 0.2
	edge.material_override = edge_material
	
	$TrieEdges.add_child(edge)
	trie_edges.append(edge)

func update_end_of_word_visuals():
	# Update materials for end-of-word nodes
	for node in all_nodes:
		var material = node.visual_object.material_override as StandardMaterial3D
		if material:
			if node.is_end_of_word:
				# Brighten end-of-word nodes
				material.emission = material.albedo_color * 0.6
			else:
				material.emission = material.albedo_color * 0.3

func animate_trie():
	match current_operation:
		TrieOperation.INSERT_WORD:
			animate_insertion()
		
		TrieOperation.SEARCH_WORD:
			animate_word_search()
		
		TrieOperation.DELETE_WORD:
			animate_deletion()
		
		TrieOperation.PREFIX_SEARCH:
			animate_prefix_search()
		
		TrieOperation.AUTOCOMPLETE:
			animate_autocomplete()

func animate_insertion():
	# Pulse all end-of-word nodes
	for node in all_nodes:
		if node.is_end_of_word:
			var pulse = 1.0 + sin(time * 6.0 + node.level) * 0.3
			node.visual_object.scale = Vector3.ONE * pulse

func animate_word_search():
	# Highlight search path
	for i in range(search_path.size()):
		var node = search_path[i]
		var wave_phase = time * 4.0 - i * 0.3
		var intensity = max(0.0, sin(wave_phase)) * 0.5
		node.visual_object.scale = Vector3.ONE * (1.0 + intensity)

func animate_deletion():
	# Red pulsing for nodes being considered for deletion
	for node in all_nodes:
		if not node.is_end_of_word and node.children.size() == 0 and node != root:
			var pulse = 1.0 + sin(time * 8.0 + node.level) * 0.4
			node.visual_object.scale = Vector3.ONE * pulse

func animate_prefix_search():
	# Highlight nodes in search path with blue glow
	for node in search_path:
		var glow = 1.0 + sin(time * 5.0) * 0.4
		node.visual_object.scale = Vector3.ONE * glow

func animate_autocomplete():
	# Pulse nodes that match the autocomplete prefix
	animate_prefix_search()
	
func animate_indicators():
	# Word counter
	var counter_height = word_count * 0.2 + 0.5
	$WordCounter.size.y = counter_height
	$WordCounter.position.y = -3 + counter_height/2
	
	# Prefix indicator
	var prefix_height = search_path.size() * 0.15 + 0.3
	var prefixindicator = get_node_or_null("PrefixIndicator")
	if prefixindicator and prefixindicator is CSGCylinder3D:
		prefixindicator.height = prefix_height
		prefixindicator.position.y = -3 + prefix_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$WordCounter.scale.x = pulse
	$PrefixIndicator.scale.x = pulse
	
	# Root node special animation
	var root_pulse = 1.0 + sin(time * 2.0) * 0.2
	$RootNode.scale = Vector3.ONE * root_pulse
