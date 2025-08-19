extends Node3D

# Four Sorting Algorithms Visualizer
# Creates a panel with four rows, each using a different sorting algorithm

@export_category("Panel Structure")
@export var num_algorithms: int = 4  # One row for each algorithm
@export var shelf_width: float = 6.0
@export var shelf_depth: float = 0.25
@export var shelf_height: float = 0.12
@export var shelf_spacing: float = 0.7  # Spacing between algorithm rows
@export var shelf_color: Color = Color(0.95, 0.95, 0.95)  # Off-white

@export_category("Bar Settings")
@export var bars_per_row: int = 20  # Number of bars per algorithm row
@export var min_bar_height: float = 0.25
@export var max_bar_height: float = 0.65
@export var bar_width: float = 0.08
@export var bar_depth: float = 0.08
@export var bar_gap: float = 0.02

@export_category("Sorting Settings")
@export var sort_delay: float = 0.3  # Delay between sorting steps
@export var auto_resort_delay: float = 4.0  # Time before resorting
@export var auto_animate: bool = true  # Automatically toggle between states

# Algorithm names and colors
const ALGORITHM_NAMES = [
	"Bubble Sort",
	"Selection Sort", 
	"Insertion Sort",
	"Quick Sort"
]

const ALGORITHM_COLORS = [
	Color(0.9, 0.6, 0.6),  # Bubble Sort - Reddish
	Color(0.6, 0.9, 0.6),  # Selection Sort - Greenish
	Color(0.6, 0.6, 0.9),  # Insertion Sort - Bluish
	Color(0.9, 0.8, 0.5)   # Quick Sort - Yellow
]

# Internal variables
var panel_container: Node3D
var random_generator = RandomNumberGenerator.new()
var bar_data = []  # Store all bar values
var bar_objects = []  # Store visual bar objects
var is_sorted = false
var sort_timer = 0.0
var is_sorting = false

# Algorithm tracking
var active_algorithm_index = -1
var quick_sort_calls = []  # For tracking recursive quick sort steps

func _ready():
	random_generator.randomize()
	
	# Create panel container
	panel_container = Node3D.new()
	panel_container.name = "SortingVisualizer"
	add_child(panel_container)
	
	# Create the panel structure
	create_panel_structure()
	
	# Initialize with random data
	randomize_bars()

func _process(delta):
	# Handle automatic sorting/randomizing
	if auto_animate and !is_sorting:
		sort_timer += delta
		if sort_timer >= auto_resort_delay:
			sort_timer = 0.0
			toggle_sort_state()

func toggle_sort_state():
	if is_sorted:
		randomize_bars()
		is_sorted = false
	else:
		start_sorting_algorithms()
		is_sorted = true

func create_panel_structure():
	# Create panel background
	var panel_base = CSGBox3D.new()
	panel_base.name = "PanelBase"
	
	panel_container.add_child(panel_base)
	
	# Create shelves - one for each sorting algorithm
	for algo_idx in range(num_algorithms):
		var shelf_y_pos = algo_idx * shelf_spacing
		
		# Create a shelf
		var shelf = CSGBox3D.new()
		shelf.name = "Shelf_" + str(algo_idx)
		shelf.size = Vector3(shelf_width, shelf_height, shelf_depth)
		shelf.position = Vector3(0, shelf_y_pos, 0)
		
		# Create material for shelf
		var shelf_material = StandardMaterial3D.new()
		shelf_material.albedo_color = shelf_color.lightened(0.1 * algo_idx)
		shelf_material.roughness = 0.9  # Not glossy
		shelf.material = shelf_material
		
		panel_container.add_child(shelf)
		
		# Add algorithm name label
		var label = Label3D.new()
		label.text = ALGORITHM_NAMES[algo_idx]
		label.font_size = 16
		label.position = Vector3(-shelf_width/2 - 0.4, shelf_y_pos, 0)
		label.modulate = ALGORITHM_COLORS[algo_idx]
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		panel_container.add_child(label)
		
		# Initialize containers for bar data and bar objects
		bar_data.append([])
		bar_objects.append([])

func randomize_bars():
	is_sorting = false
	
	# Generate a set of random heights
	var random_heights = []
	for i in range(bars_per_row):
		random_heights.append(randf_range(min_bar_height, max_bar_height))
	
	# Apply the same random arrangement to all algorithm rows
	for algo_idx in range(num_algorithms):
		# Clear existing bars
		for bar in bar_objects[algo_idx]:
			bar.queue_free()
		
		bar_data[algo_idx] = random_heights.duplicate()
		bar_objects[algo_idx] = []
		
		# Create new bars
		create_bars_for_algorithm(algo_idx)

func create_bars_for_algorithm(algo_idx):
	var shelf_node = panel_container.get_node("Shelf_" + str(algo_idx))
	if !shelf_node:
		return
		
	var shelf_y = shelf_node.position.y
	var total_width = bars_per_row * (bar_width + bar_gap) - bar_gap
	var start_x = -total_width / 2
	
	# Create bars
	for i in range(bar_data[algo_idx].size()):
		var height = bar_data[algo_idx][i]
		var x_pos = start_x + i * (bar_width + bar_gap)
		
		var bar = CSGBox3D.new()
		bar.name = "Bar_" + str(i)
		bar.size = Vector3(bar_width, height, bar_depth)
		
		# Position the bar (centered at bottom)
		bar.position = Vector3(
			x_pos + bar_width/2,
			shelf_y + shelf_height/2 + height/2,
			0
		)
		
		# Create material
		var bar_material = StandardMaterial3D.new()
		bar_material.albedo_color = ALGORITHM_COLORS[algo_idx].lightened(0.3)
		bar.material = bar_material
		
		panel_container.add_child(bar)
		bar_objects[algo_idx].append(bar)

func highlight_bars(algo_idx, indices, highlight_color = Color(1, 1, 1)):
	# Reset all bars to default color
	for i in range(bar_objects[algo_idx].size()):
		var bar = bar_objects[algo_idx][i]
		var default_material = StandardMaterial3D.new()
		default_material.albedo_color = ALGORITHM_COLORS[algo_idx].lightened(0.3)
		bar.material = default_material
	
	# Highlight the specified bars
	for idx in indices:
		if idx >= 0 and idx < bar_objects[algo_idx].size():
			var bar = bar_objects[algo_idx][idx]
			var highlight_material = StandardMaterial3D.new()
			highlight_material.albedo_color = highlight_color
			highlight_material.emission_enabled = true
			highlight_material.emission = highlight_color.darkened(0.3)
			bar.material = highlight_material

func swap_bars(algo_idx, idx1, idx2):
	# Swap data values
	var temp = bar_data[algo_idx][idx1]
	bar_data[algo_idx][idx1] = bar_data[algo_idx][idx2]
	bar_data[algo_idx][idx2] = temp
	
	# Update bar positions
	update_bar_positions(algo_idx)

func update_bar_positions(algo_idx):
	var shelf_node = panel_container.get_node("Shelf_" + str(algo_idx))
	if !shelf_node:
		return
		
	var shelf_y = shelf_node.position.y
	var total_width = bars_per_row * (bar_width + bar_gap) - bar_gap
	var start_x = -total_width / 2
	
	# Update positions of existing bars
	for i in range(bar_data[algo_idx].size()):
		var height = bar_data[algo_idx][i]
		var x_pos = start_x + i * (bar_width + bar_gap)
		var bar = bar_objects[algo_idx][i]
		
		# Update size and position
		bar.size = Vector3(bar_width, height, bar_depth)
		bar.position = Vector3(
			x_pos + bar_width/2,
			shelf_y + shelf_height/2 + height/2,
			0
		)

func start_sorting_algorithms():
	is_sorting = true
	
	# Start all four sorting algorithms
	for i in range(num_algorithms):
		match i:
			0: bubble_sort(i)
			1: selection_sort(i)
			2: insertion_sort(i)
			3: 
				quick_sort_calls = []  # Reset quick sort tracking
				quick_sort(i, 0, bar_data[i].size() - 1)

# BUBBLE SORT
func bubble_sort(algo_idx):
	var n = bar_data[algo_idx].size()
	
	for i in range(n):
		for j in range(0, n - i - 1):
			# Highlight current comparison
			highlight_bars(algo_idx, [j, j + 1], Color(1, 0.8, 0.8))
			await get_tree().create_timer(sort_delay).timeout
			
			if bar_data[algo_idx][j] > bar_data[algo_idx][j + 1]:
				swap_bars(algo_idx, j, j + 1)
				await get_tree().create_timer(sort_delay).timeout
	
	# Reset highlighting when done
	highlight_bars(algo_idx, [])
	if algo_idx == num_algorithms - 1:
		is_sorting = false

# SELECTION SORT
func selection_sort(algo_idx):
	var n = bar_data[algo_idx].size()
	
	for i in range(n):
		var min_idx = i
		
		# Highlight current position
		highlight_bars(algo_idx, [i], Color(0.8, 1, 0.8))
		await get_tree().create_timer(sort_delay).timeout
		
		for j in range(i + 1, n):
			# Highlight comparison
			highlight_bars(algo_idx, [min_idx, j], Color(0.8, 1, 0.8))
			await get_tree().create_timer(sort_delay).timeout
			
			if bar_data[algo_idx][j] < bar_data[algo_idx][min_idx]:
				min_idx = j
		
		if min_idx != i:
			swap_bars(algo_idx, i, min_idx)
			await get_tree().create_timer(sort_delay).timeout
	
	# Reset highlighting when done
	highlight_bars(algo_idx, [])

# INSERTION SORT
func insertion_sort(algo_idx):
	var n = bar_data[algo_idx].size()
	
	for i in range(1, n):
		var key = bar_data[algo_idx][i]
		var j = i - 1
		
		# Highlight current element being inserted
		highlight_bars(algo_idx, [i], Color(0.8, 0.8, 1))
		await get_tree().create_timer(sort_delay).timeout
		
		while j >= 0 and bar_data[algo_idx][j] > key:
			bar_data[algo_idx][j + 1] = bar_data[algo_idx][j]
			
			# Update visuals
			update_bar_positions(algo_idx)
			highlight_bars(algo_idx, [j, j+1], Color(0.8, 0.8, 1))
			await get_tree().create_timer(sort_delay).timeout
			
			j -= 1
		
		bar_data[algo_idx][j + 1] = key
		update_bar_positions(algo_idx)
		await get_tree().create_timer(sort_delay).timeout
	
	# Reset highlighting when done
	highlight_bars(algo_idx, [])

# QUICK SORT
func quick_sort(algo_idx, low, high):
	quick_sort_calls.append([low, high])
	
	if low < high:
		# Partition and get pivot index
		var pivot_idx = await partition(algo_idx, low, high)
		
		# Recursively sort elements before and after pivot
		await quick_sort(algo_idx, low, pivot_idx - 1)
		await quick_sort(algo_idx, pivot_idx + 1, high)
	
	# Check if this is the last quick sort call
	quick_sort_calls.pop_back()
	if quick_sort_calls.size() == 0:
		highlight_bars(algo_idx, [])

func partition(algo_idx, low, high):
	var pivot = bar_data[algo_idx][high]
	
	# Highlight pivot
	highlight_bars(algo_idx, [high], Color(1, 0.9, 0.5))
	await get_tree().create_timer(sort_delay).timeout
	
	var i = low - 1
	
	for j in range(low, high):
		# Highlight comparison
		highlight_bars(algo_idx, [j, high], Color(1, 0.9, 0.5))
		await get_tree().create_timer(sort_delay).timeout
		
		if bar_data[algo_idx][j] <= pivot:
			i += 1
			swap_bars(algo_idx, i, j)
			await get_tree().create_timer(sort_delay).timeout
	
	swap_bars(algo_idx, i + 1, high)
	await get_tree().create_timer(sort_delay).timeout
	
	return i + 1
