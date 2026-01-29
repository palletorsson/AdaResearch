extends Node3D

# Sorting Algorithms Visualization
# Shows various sorting algorithms with animated comparisons and swaps

@export_category("Array Configuration")
@export var array_size: int = 30
@export var max_value: int = 20
@export var shuffle_on_start: bool = true

@export_category("Algorithm Settings")
@export var sorting_algorithm: String = "bubble_sort"  # bubble_sort, selection_sort, insertion_sort, merge_sort
@export var animation_speed: float = 0.2
@export var show_comparisons: bool = true
@export var show_swaps: bool = true

@export_category("Visualization")
@export var bar_width: float = 0.8
@export var bar_spacing: float = 1.0
@export var highlight_active: bool = true

# Algorithm state
var array: Array = []
var sorting_active: bool = false
var algorithm_timer: float = 0.0
var current_step: int = 0
var comparison_count: int = 0
var swap_count: int = 0

# Visual elements
var bar_meshes: Array = []
var ui_labels: Array = []
var highlighted_indices: Array = []

# Sorting state for different algorithms
var algorithm_state: Dictionary = {}

# Colors
var default_color = Color(0.6, 0.6, 0.8)
var comparing_color = Color(0.9, 0.7, 0.2)
var swapping_color = Color(0.9, 0.2, 0.2)
var sorted_color = Color(0.2, 0.8, 0.2)

func _ready():
	setup_environment()
	initialize_array()
	create_visuals()
	setup_ui()
	
	if shuffle_on_start:
		shuffle_array()
	
	start_sorting()

func _process(delta):
	if sorting_active:
		algorithm_timer += delta
		if algorithm_timer >= animation_speed:
			perform_sorting_step()
			algorithm_timer = 0.0
	
	update_ui()

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(array_size * bar_spacing / 2.0, 15, 20)
	camera.look_at_from_position(camera.position, Vector3(array_size * bar_spacing / 2.0, 5, 0), Vector3.UP)
	add_child(camera)

func initialize_array():
	array.clear()
	for i in range(array_size):
		array.append(i + 1)

func shuffle_array():
	for i in range(array.size()):
		var j = randi() % array.size()
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	
	update_visual_array()

func create_visuals():
	bar_meshes.clear()
	
	for i in range(array.size()):
		var bar = create_bar(i, array[i])
		bar_meshes.append(bar)
		add_child(bar)

func create_bar(index: int, value: int) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bar_width, value, bar_width)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = default_color
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(
		index * bar_spacing,
		value / 2.0,
		0
	)
	
	return mesh_instance

func start_sorting():
	sorting_active = true
	current_step = 0
	comparison_count = 0
	swap_count = 0
	
	# Initialize algorithm-specific state
	match sorting_algorithm:
		"bubble_sort":
			algorithm_state = {"i": 0, "j": 0, "n": array.size()}
		"selection_sort":
			algorithm_state = {"i": 0, "min_idx": 0, "j": 0}
		"insertion_sort":
			algorithm_state = {"i": 1, "key": 0, "j": 0}
		"merge_sort":
			algorithm_state = {"size": 1}
	
	print("Starting ", sorting_algorithm, " with array size ", array.size())

func perform_sorting_step():
	match sorting_algorithm:
		"bubble_sort":
			bubble_sort_step()
		"selection_sort":
			selection_sort_step()
		"insertion_sort":
			insertion_sort_step()
		_:
			bubble_sort_step()

func bubble_sort_step():
	var i = algorithm_state.i
	var j = algorithm_state.j
	var n = algorithm_state.n
	
	if i >= n - 1:
		sorting_active = false
		highlight_sorted()
		return
	
	if j >= n - i - 1:
		algorithm_state.i += 1
		algorithm_state.j = 0
		return
	
	# Compare adjacent elements
	highlight_bars([j, j + 1], comparing_color)
	comparison_count += 1
	
	if array[j] > array[j + 1]:
		# Swap elements
		var temp = array[j]
		array[j] = array[j + 1]
		array[j + 1] = temp
		swap_count += 1
		
		highlight_bars([j, j + 1], swapping_color)
		update_visual_array()
	
	algorithm_state.j += 1

func selection_sort_step():
	var i = algorithm_state.i
	var min_idx = algorithm_state.min_idx
	var j = algorithm_state.j
	
	if i >= array.size():
		sorting_active = false
		highlight_sorted()
		return
	
	if j == i:
		# Start new iteration
		algorithm_state.min_idx = i
		algorithm_state.j = i + 1
		return
	
	if j >= array.size():
		# Swap minimum with current position
		if min_idx != i:
			var temp = array[i]
			array[i] = array[min_idx]
			array[min_idx] = temp
			swap_count += 1
			update_visual_array()
		
		algorithm_state.i += 1
		algorithm_state.j = algorithm_state.i
		return
	
	# Find minimum
	highlight_bars([j, min_idx], comparing_color)
	comparison_count += 1
	
	if array[j] < array[min_idx]:
		algorithm_state.min_idx = j
	
	algorithm_state.j += 1

func insertion_sort_step():
	var i = algorithm_state.i
	var j = algorithm_state.j
	
	if i >= array.size():
		sorting_active = false
		highlight_sorted()
		return
	
	if j == 0:
		# Start new insertion
		algorithm_state.key = array[i]
		algorithm_state.j = i - 1
	
	if j >= 0 and array[j] > algorithm_state.key:
		highlight_bars([j, j + 1], comparing_color)
		comparison_count += 1
		
		array[j + 1] = array[j]
		algorithm_state.j -= 1
		swap_count += 1
		update_visual_array()
	else:
		# Insert key at correct position
		array[j + 1] = algorithm_state.key
		algorithm_state.i += 1
		algorithm_state.j = 0
		update_visual_array()

func highlight_bars(indices: Array, color: Color):
	# Reset all bars to default color
	for i in range(bar_meshes.size()):
		var material = bar_meshes[i].material_override
		material.albedo_color = default_color
	
	# Highlight specified bars
	for index in indices:
		if index >= 0 and index < bar_meshes.size():
			var material = bar_meshes[index].material_override
			material.albedo_color = color

func highlight_sorted():
	for i in range(bar_meshes.size()):
		var material = bar_meshes[i].material_override
		material.albedo_color = sorted_color
		material.emission_enabled = true
		material.emission = sorted_color * 0.3

func update_visual_array():
	for i in range(array.size()):
		var bar = bar_meshes[i]
		var box = BoxMesh.new()
		box.size = Vector3(bar_width, array[i], bar_width)
		bar.mesh = box
		bar.position.y = array[i] / 2.0

func setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var algorithm_label = Label.new()
	algorithm_label.position = Vector2(20, 20)
	algorithm_label.text = "Algorithm: " + sorting_algorithm
	canvas.add_child(algorithm_label)
	ui_labels.append(algorithm_label)
	
	var comparisons_label = Label.new()
	comparisons_label.position = Vector2(20, 50)
	comparisons_label.text = "Comparisons: 0"
	canvas.add_child(comparisons_label)
	ui_labels.append(comparisons_label)
	
	var swaps_label = Label.new()
	swaps_label.position = Vector2(20, 80)
	swaps_label.text = "Swaps: 0"
	canvas.add_child(swaps_label)
	ui_labels.append(swaps_label)
	
	var status_label = Label.new()
	status_label.position = Vector2(20, 110)
	status_label.text = "Status: Sorting..."
	canvas.add_child(status_label)
	ui_labels.append(status_label)

func update_ui():
	if ui_labels.size() >= 2:
		ui_labels[1].text = "Comparisons: " + str(comparison_count)
	
	if ui_labels.size() >= 3:
		ui_labels[2].text = "Swaps: " + str(swap_count)
	
	if ui_labels.size() >= 4:
		if sorting_active:
			ui_labels[3].text = "Status: Sorting..."
		else:
			ui_labels[3].text = "Status: Complete!" 
