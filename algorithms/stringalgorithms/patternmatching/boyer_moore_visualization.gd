extends Node3D

# Boyer-Moore String Matching: Identity Recognition & Textual Resistance
# Demonstrates the politics of pattern matching - finding yourself in text
# Shows how algorithms can reveal or conceal identity through search and recognition

@export_category("Text & Identity")
@export var text_corpus: String = "In a world where queer stories matter, every word carries weight. Trans voices echo through digital spaces, searching for recognition and belonging. Non-binary identities resist categorization while seeking authentic representation."
@export var search_pattern: String = "queer"
@export var case_sensitive: bool = false
@export var highlight_partial_matches: bool = true

@export_category("Algorithm Configuration")
@export var animation_speed: float = 0.8  # Seconds per character comparison
@export var show_bad_character_table: bool = true
@export var auto_animate: bool = true

@export_category("Visualization")
@export var text_size: float = 0.8
@export var character_spacing: float = 1.0
@export var pattern_color: Color = Color(0.9, 0.3, 0.9)  # Magenta
@export var match_color: Color = Color(0.2, 0.9, 0.3)    # Green
@export var mismatch_color: Color = Color(0.9, 0.3, 0.3) # Red
@export var text_color: Color = Color(0.9, 0.9, 0.9)     # White

@export_category("Queer Presets")
@export var identity_preset: String = "Trans_Visibility"  # Trans_Visibility, Queer_Community, Non_Binary_Recognition

# Algorithm state
var text_array: Array[String] = []
var pattern_array: Array[String] = []
var current_text_position: int = 0
var current_pattern_position: int = 0
var matches_found: Array[int] = []
var is_searching: bool = false
var animation_timer: float = 0.0
var algorithm_step: String = "starting"

# Boyer-Moore tables
var bad_character_table: Dictionary = {}

# Visual elements
var text_meshes: Array[MeshInstance3D] = []
var pattern_meshes: Array[MeshInstance3D] = []
var ui_display: CanvasLayer
var camera_controller: Node3D

# Educational components
var statistics: Dictionary = {
	"comparisons": 0,
	"skips": 0,
	"efficiency_gain": 0.0
}

func _ready():
	setup_environment()
	setup_camera()
	load_identity_preset()
	preprocess_pattern()
	create_text_visualization()
	setup_ui()
	if auto_animate:
		start_boyer_moore_search()

func _process(delta):
	if is_searching and auto_animate:
		animation_timer += delta
		if animation_timer >= animation_speed:
			perform_search_step()
			animation_timer = 0.0

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if not is_searching:
					start_boyer_moore_search()
				else:
					perform_search_step()
			KEY_R:
				restart_search()
			KEY_1:
				load_identity_preset("Trans_Visibility")
			KEY_2:
				load_identity_preset("Queer_Community")
			KEY_3:
				load_identity_preset("Non_Binary_Recognition")

func setup_environment():
	# Dramatic lighting for text focus
	var light = DirectionalLight3D.new()
	light.light_energy = 1.5
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Dark environment to emphasize text
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.02, 0.05)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_energy = 0.3
	env.environment = environment
	add_child(env)

func setup_camera():
	camera_controller = Node3D.new()
	add_child(camera_controller)
	
	var camera = Camera3D.new()
	camera.position = Vector3(0, 8, 15)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera_controller.add_child(camera)

func load_identity_preset(preset: String = ""):
	if preset != "":
		identity_preset = preset
	
	match identity_preset:
		"Trans_Visibility":
			text_corpus = "Trans rights are human rights. Every transgender person deserves recognition, respect, and the freedom to live authentically. Trans women are women, trans men are men, and non-binary identities are valid."
			search_pattern = "trans"
			
		"Queer_Community":
			text_corpus = "Queer joy radiates through community spaces where LGBTQ+ folks gather, share stories, and build chosen family. Pride celebrations remind us that queer love wins and visibility matters."
			search_pattern = "queer"
			
		"Non_Binary_Recognition":
			text_corpus = "Non-binary people exist beyond the gender binary, using they/them pronouns and other identifiers that reflect their authentic selves. Recognition of non-binary identities challenges traditional gender categories."
			search_pattern = "non-binary"
	
	if not case_sensitive:
		text_corpus = text_corpus.to_lower()
		search_pattern = search_pattern.to_lower()
	
	restart_search()

func preprocess_pattern():
	"""Build Boyer-Moore preprocessing tables"""
	pattern_array = []
	for c in search_pattern:
		pattern_array.append(c)
	
	build_bad_character_table()

func build_bad_character_table():
	"""Build bad character shift table"""
	bad_character_table.clear()
	
	# Initialize table with pattern length for unknown characters
	for i in range(pattern_array.size()):
		var char = pattern_array[i]
		# Distance from current position to rightmost occurrence
		bad_character_table[char] = pattern_array.size() - i - 1

func create_text_visualization():
	"""Create 3D visualization of text and search pattern"""
	clear_previous_visualization()
	
	# Convert text to character array
	text_array = []
	for c in text_corpus:
		text_array.append(c)
	
	# Limit text length for visualization
	if text_array.size() > 100:
		text_array = text_array.slice(0, 100)
	
	# Create text character meshes
	create_text_meshes()
	create_pattern_overlay()
	
	# Position camera for optimal viewing
	adjust_camera_for_text()

func create_text_meshes():
	"""Create 3D text characters"""
	var chars_per_row = 20
	var row_spacing = 2.0
	
	for i in range(text_array.size()):
		var char = text_array[i]
		var x = (i % chars_per_row) * character_spacing - (chars_per_row * character_spacing) / 2
		var y = -(i / chars_per_row) * row_spacing
		
		var char_mesh = create_character_mesh(char, Vector3(x, y, 0), text_color)
		text_meshes.append(char_mesh)
		add_child(char_mesh)

func create_pattern_overlay():
	"""Create pattern visualization overlay"""
	for i in range(pattern_array.size()):
		var char = pattern_array[i]
		var char_mesh = create_character_mesh(char, Vector3(0, 2, 0.1), pattern_color)
		char_mesh.visible = false  # Will be positioned during search
		pattern_meshes.append(char_mesh)
		add_child(char_mesh)

func create_character_mesh(character: String, position: Vector3, color: Color) -> MeshInstance3D:
	"""Create a 3D character mesh"""
	var mesh_instance = MeshInstance3D.new()
	
	# Use a simple box with text label
	var box = BoxMesh.new()
	box.size = Vector3(text_size, text_size, 0.1)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	mesh_instance.material_override = material
	
	mesh_instance.position = position
	
	# Add text label
	var label = Label3D.new()
	label.text = character
	label.font_size = 32
	label.position = Vector3(0, 0, 0.1)
	mesh_instance.add_child(label)
	
	return mesh_instance

func start_boyer_moore_search():
	"""Initialize Boyer-Moore search algorithm"""
	current_text_position = 0
	current_pattern_position = pattern_array.size() - 1  # Start from end of pattern
	matches_found.clear()
	statistics.comparisons = 0
	statistics.skips = 0
	is_searching = true
	algorithm_step = "positioning"
	
	position_pattern_overlay()
	update_ui()
	
	print("Boyer-Moore search started for pattern: '", search_pattern, "'")

func perform_search_step():
	"""Perform one step of Boyer-Moore algorithm"""
	if not is_searching:
		return
	
	if current_text_position + pattern_array.size() > text_array.size():
		# Search complete
		is_searching = false
		algorithm_step = "complete"
		print("Search complete. Found ", matches_found.size(), " matches.")
		update_ui()
		return
	
	# Position pattern overlay
	position_pattern_overlay()
	
	# Compare characters from right to left (Boyer-Moore characteristic)
	var text_char = text_array[current_text_position + current_pattern_position]
	var pattern_char = pattern_array[current_pattern_position]
	
	statistics.comparisons += 1
	
	# Visual comparison indication
	highlight_comparison(current_text_position + current_pattern_position, 
						current_pattern_position, 
						text_char == pattern_char)
	
	if text_char == pattern_char:
		# Characters match
		if current_pattern_position == 0:
			# Full pattern match found!
			matches_found.append(current_text_position)
			highlight_match(current_text_position)
			algorithm_step = "match_found"
			
			# Move to next position
			current_text_position += 1
			current_pattern_position = pattern_array.size() - 1
		else:
			# Continue comparing from right to left
			current_pattern_position -= 1
			algorithm_step = "continuing_match"
	else:
		# Character mismatch - apply Boyer-Moore skip
		var skip_distance = calculate_boyer_moore_skip(text_char)
		statistics.skips += skip_distance
		
		current_text_position += skip_distance
		current_pattern_position = pattern_array.size() - 1
		algorithm_step = "skip_applied"
		
		# Show skip visualization
		show_skip_visualization(skip_distance)
	
	update_ui()

func calculate_boyer_moore_skip(mismatched_char: String) -> int:
	"""Calculate skip distance using bad character rule"""
	if bad_character_table.has(mismatched_char):
		return max(1, bad_character_table[mismatched_char])
	else:
		return pattern_array.size()  # Character not in pattern

func position_pattern_overlay():
	"""Position the pattern overlay at current search position"""
	var chars_per_row = 20
	var row_spacing = 2.0
	
	for i in range(pattern_meshes.size()):
		var text_index = current_text_position + i
		if text_index < text_array.size():
			var x = (text_index % chars_per_row) * character_spacing - (chars_per_row * character_spacing) / 2
			var y = -(text_index / chars_per_row) * row_spacing + 0.5
			
			pattern_meshes[i].position = Vector3(x, y, 0.1)
			pattern_meshes[i].visible = true
		else:
			pattern_meshes[i].visible = false

func highlight_comparison(text_pos: int, pattern_pos: int, is_match: bool):
	"""Highlight the current character comparison"""
	# Reset previous highlights
	reset_highlights()
	
	# Highlight text character
	if text_pos < text_meshes.size():
		var material = text_meshes[text_pos].material_override as StandardMaterial3D
		material.albedo_color = match_color if is_match else mismatch_color
		material.emission = material.albedo_color * 0.6
	
	# Highlight pattern character
	if pattern_pos < pattern_meshes.size():
		var material = pattern_meshes[pattern_pos].material_override as StandardMaterial3D
		material.albedo_color = match_color if is_match else mismatch_color
		material.emission = material.albedo_color * 0.6

func highlight_match(start_position: int):
	"""Highlight a complete pattern match"""
	for i in range(pattern_array.size()):
		var text_index = start_position + i
		if text_index < text_meshes.size():
			var material = text_meshes[text_index].material_override as StandardMaterial3D
			material.albedo_color = Color(0.2, 0.9, 0.2)  # Bright green
			material.emission = material.albedo_color * 0.8

func show_skip_visualization(skip_distance: int):
	"""Visualize the Boyer-Moore skip"""
	# Create temporary skip indicator
	var skip_indicator = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = 0.2
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	skip_indicator.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW * 0.5
	skip_indicator.material_override = material
	
	var chars_per_row = 20
	var start_x = (current_text_position % chars_per_row) * character_spacing
	var end_x = ((current_text_position + skip_distance) % chars_per_row) * character_spacing
	
	skip_indicator.position = Vector3((start_x + end_x) / 2, 1, 0.2)
	add_child(skip_indicator)
	
	# Remove after short time
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): skip_indicator.queue_free())

func reset_highlights():
	"""Reset all character highlights to default colors"""
	for mesh in text_meshes:
		var material = mesh.material_override as StandardMaterial3D
		material.albedo_color = text_color
		material.emission = text_color * 0.3
	
	for mesh in pattern_meshes:
		var material = mesh.material_override as StandardMaterial3D
		material.albedo_color = pattern_color
		material.emission = pattern_color * 0.4

func clear_previous_visualization():
	"""Clear previous visualization elements"""
	for mesh in text_meshes:
		mesh.queue_free()
	text_meshes.clear()
	
	for mesh in pattern_meshes:
		mesh.queue_free()
	pattern_meshes.clear()

func adjust_camera_for_text():
	"""Adjust camera position for optimal text viewing"""
	var text_width = min(20, text_array.size()) * character_spacing
	var text_height = (text_array.size() / 20 + 1) * 2.0
	
	camera_controller.position = Vector3(0, text_height / 2, max(text_width, text_height) * 1.2)

func restart_search():
	"""Restart the search with current parameters"""
	clear_previous_visualization()
	preprocess_pattern()
	create_text_visualization()
	is_searching = false
	matches_found.clear()
	statistics.comparisons = 0
	statistics.skips = 0
	update_ui()

func setup_ui():
	"""Create user interface for algorithm information"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 500)
	panel.position = Vector2(20, 20)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(370, 470)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Boyer-Moore: Identity Recognition"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Information labels
	for i in range(12):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label)
	
	update_ui()

func update_ui():
	"""Update user interface with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(12):
		var label = ui_display.get_node_or_null("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 12:
		labels[0].text = "Identity Focus: " + identity_preset.replace("_", " ")
		labels[1].text = "Search Pattern: '" + search_pattern + "'"
		labels[2].text = "Text Length: " + str(text_array.size()) + " characters"
		labels[3].text = ""
		labels[4].text = "Algorithm Status: " + algorithm_step.replace("_", " ").capitalize()
		labels[5].text = "Current Position: " + str(current_text_position)
		labels[6].text = "Comparisons Made: " + str(statistics.comparisons)
		labels[7].text = "Characters Skipped: " + str(statistics.skips)
		labels[8].text = "Matches Found: " + str(matches_found.size())
		labels[9].text = ""
		labels[10].text = "Controls: SPACE=Step, R=Restart, 1-3=Presets"
		labels[11].text = "Pattern overlay shows search progress" 
