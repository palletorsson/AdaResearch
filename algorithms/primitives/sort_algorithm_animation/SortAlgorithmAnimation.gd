extends Node3D

# Sort Algorithm Animation
# Demonstrates bubble sort, merge sort, and quick sort in 3D space

var time := 0.0
var animation_timer := 0.0
var current_algorithm := "bubble"

# Array data
var bubble_array := []
var merge_array := []
var quick_array := []

# Sorting state
var bubble_i := 0
var bubble_j := 0
var bubble_comparisons := 0
var bubble_swaps := 0

var merge_level := 0
var merge_step := 0

var quick_low := 0
var quick_high := 0
var quick_pivot := 0

# Visual elements
var bubble_elements := []
var merge_elements := []
var quick_elements := []

func _ready():
	initialize_arrays()
	create_visual_elements()

func _process(delta):
	time += delta
	animation_timer += delta
	
	animate_sorting_algorithms()
	visualize_comparisons()
	visualize_swaps()
	update_performance_metrics()

func initialize_arrays():
	# Initialize random arrays for each algorithm
	bubble_array = generate_random_array(8)
	merge_array = generate_random_array(8)
	quick_array = generate_random_array(8)

func generate_random_array(size: int) -> Array:
	var array = []
	for i in range(size):
		array.append(randi() % 20 + 1)
	return array

func create_visual_elements():
	create_bubble_sort_elements()
	create_merge_sort_elements()
	create_quick_sort_elements()

func create_bubble_sort_elements():
	var container = $BubbleSortArea
	
	for i in range(bubble_array.size()):
		var element = CSGBox3D.new()
		var height = float(bubble_array[i])
		element.size = Vector3(0.8, height * 0.3, 0.8)
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "BubbleElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
		bubble_elements.append(element)

func create_merge_sort_elements():
	var container = $MergeSortArea
	
	for i in range(merge_array.size()):
		var element = CSGCylinder3D.new()
		var height = float(merge_array[i])
		element.radius = 0.3
		
		element.height = height * 0.3
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "MergeElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.3)
		material.metallic = 0.4
		material.roughness = 0.3
		element.material_override = material
		
		container.add_child(element)
		merge_elements.append(element)

func create_quick_sort_elements():
	var container = $QuickSortArea
	
	for i in range(quick_array.size()):
		var element = CSGSphere3D.new()
		var height = float(quick_array[i])
		element.radius = 0.3
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "QuickElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.5, 1.0, 0.3)
		material.metallic = 0.2
		material.roughness = 0.5
		element.material_override = material
		
		container.add_child(element)
		quick_elements.append(element)

func animate_sorting_algorithms():
	if animation_timer > 1.0:
		animation_timer = 0.0
		
		match current_algorithm:
			"bubble":
				step_bubble_sort()
				current_algorithm = "merge"
			"merge":
				step_merge_sort()
				current_algorithm = "quick"
			"quick":
				step_quick_sort()
				current_algorithm = "bubble"

func step_bubble_sort():
	# Bubble sort step
	if bubble_j < bubble_array.size() - bubble_i - 1:
		bubble_comparisons += 1
		
		# Highlight comparison
		highlight_elements(bubble_elements, [bubble_j, bubble_j + 1], Color.YELLOW)
		
		# Compare and swap if needed
		if bubble_array[bubble_j] > bubble_array[bubble_j + 1]:
			swap_elements(bubble_array, bubble_j, bubble_j + 1)
			swap_visual_elements(bubble_elements, bubble_j, bubble_j + 1)
			bubble_swaps += 1
		
		bubble_j += 1
	else:
		bubble_j = 0
		bubble_i += 1
		
		if bubble_i >= bubble_array.size() - 1:
			# Reset for next iteration
			bubble_i = 0
			bubble_array = generate_random_array(8)
			recreate_bubble_elements()

func step_merge_sort():
	# Simplified merge sort visualization (showing merge phases)
	var size = bubble_array.size()
	var step_size = 1 << merge_level
	
	if step_size >= size:
		merge_level = 0
		merge_array = generate_random_array(8)
		recreate_merge_elements()
		return
	
	# Highlight current merge operation
	var left = merge_step * step_size * 2
	var mid = min(left + step_size - 1, size - 1)
	var right = min(left + step_size * 2 - 1, size - 1)
	
	if left < size:
		var indices = []
		for i in range(left, min(right + 1, size)):
			indices.append(i)
		highlight_elements(merge_elements, indices, Color.CYAN)
	
	merge_step += 1
	
	# Check if level is complete
	if merge_step * step_size * 2 >= size:
		merge_step = 0
		merge_level += 1

func step_quick_sort():
	# Simplified quick sort visualization (showing partitioning)
	if quick_high - quick_low <= 1:
		# Reset for new partition
		quick_low = 0
		quick_high = quick_array.size() - 1
		quick_pivot = quick_low + (quick_high - quick_low) / 2
		quick_array = generate_random_array(8)
		recreate_quick_elements()
		return
	
	# Highlight pivot
	highlight_elements(quick_elements, [quick_pivot], Color.RED)
	
	# Highlight partition range
	var indices = []
	for i in range(quick_low, quick_high + 1):
		if i != quick_pivot:
			indices.append(i)
	highlight_elements(quick_elements, indices, Color.MAGENTA)
	
	# Simulate partitioning (simplified)
	var pivot_value = quick_array[quick_pivot]
	var new_pivot_pos = quick_low
	
	for i in range(quick_low, quick_high):
		if quick_array[i] < pivot_value:
			if i != new_pivot_pos:
				swap_elements(quick_array, i, new_pivot_pos)
				swap_visual_elements(quick_elements, i, new_pivot_pos)
			new_pivot_pos += 1
	
	# Move pivot to correct position
	if quick_pivot != new_pivot_pos:
		swap_elements(quick_array, quick_pivot, new_pivot_pos)
		swap_visual_elements(quick_elements, quick_pivot, new_pivot_pos)
	
	quick_pivot = new_pivot_pos
	
	# Choose next partition
	if new_pivot_pos - quick_low > quick_high - new_pivot_pos:
		quick_high = new_pivot_pos - 1
	else:
		quick_low = new_pivot_pos + 1

func swap_elements(array: Array, i: int, j: int):
	var temp = array[i]
	array[i] = array[j]
	array[j] = temp

func swap_visual_elements(elements: Array, i: int, j: int):
	# Animate element swap
	var pos_i = elements[i].position
	var pos_j = elements[j].position
	
	elements[i].position = pos_j
	elements[j].position = pos_i
	
	# Also swap in array for tracking
	var temp = elements[i]
	elements[i] = elements[j]
	elements[j] = temp

func highlight_elements(elements: Array, indices: Array, color: Color):
	# Reset all elements to default color
	for element in elements:
		var material = element.material_override as StandardMaterial3D
		if elements == bubble_elements:
			material.albedo_color = Color(0.3, 0.7, 1.0)
		elif elements == merge_elements:
			material.albedo_color = Color(1.0, 0.5, 0.3)
		else:  # quick_elements
			material.albedo_color = Color(0.5, 1.0, 0.3)
		material.emission_enabled = false
	
	# Highlight specified elements
	for index in indices:
		if index < elements.size():
			var element = elements[index]
			var material = element.material_override as StandardMaterial3D
			material.albedo_color = color
			material.emission_enabled = true
			material.emission = color * 0.4

func recreate_bubble_elements():
	var container = $BubbleSortArea
	
	# Clear existing elements
	for element in bubble_elements:
		element.queue_free()
	bubble_elements.clear()
	
	# Create new elements
	for i in range(bubble_array.size()):
		var element = CSGBox3D.new()
		var height = float(bubble_array[i])
		element.size = Vector3(0.8, height * 0.3, 0.8)
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "BubbleElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
		bubble_elements.append(element)

func recreate_merge_elements():
	var container = $MergeSortArea
	
	# Clear existing elements
	for element in merge_elements:
		element.queue_free()
	merge_elements.clear()
	
	# Create new elements
	for i in range(merge_array.size()):
		var element = CSGCylinder3D.new()
		var height = float(merge_array[i])
		element.radius = 0.3
		
		element.height = height * 0.3
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "MergeElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.3)
		material.metallic = 0.4
		material.roughness = 0.3
		element.material_override = material
		
		container.add_child(element)
		merge_elements.append(element)

func recreate_quick_elements():
	var container = $QuickSortArea
	
	# Clear existing elements
	for element in quick_elements:
		element.queue_free()
	quick_elements.clear()
	
	# Create new elements
	for i in range(quick_array.size()):
		var element = CSGSphere3D.new()
		var height = float(quick_array[i])
		element.radius = 0.3
		element.position = Vector3(i * 1.0, height * 0.15, 0)
		element.name = "QuickElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.5, 1.0, 0.3)
		material.metallic = 0.2
		material.roughness = 0.5
		element.material_override = material
		
		container.add_child(element)
		quick_elements.append(element)

func visualize_comparisons():
	var container = $ComparisonVisualizer
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show comparison operations
	var comparison_height = min(bubble_comparisons * 0.1, 5.0)
	
	var comparison_bar = CSGBox3D.new()
	comparison_bar.size = Vector3(1.0, comparison_height, 1.0)
	comparison_bar.position = Vector3(0, comparison_height / 2.0, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 0.0) * 0.3
	comparison_bar.material_override = material
	
	container.add_child(comparison_bar)

func visualize_swaps():
	var container = $SwapVisualizer
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show swap operations
	var swap_height = min(bubble_swaps * 0.2, 5.0)
	
	var swap_bar = CSGBox3D.new()
	swap_bar.size = Vector3(1.0, swap_height, 1.0)
	swap_bar.position = Vector3(0, swap_height / 2.0, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 1.0) * 0.3
	swap_bar.material_override = material
	
	container.add_child(swap_bar)

func update_performance_metrics():
	var container = $PerformanceMetrics
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Big O complexity visualization for sorting algorithms
	var complexities = ["O(n²)", "O(n log n)", "O(n log n)"]
	var colors = [Color.RED, Color.YELLOW, Color.GREEN]
	var algorithm_names = ["Bubble", "Merge", "Quick"]
	
	for i in range(complexities.size()):
		var metric_box = CSGBox3D.new()
		metric_box.size = Vector3(0.8, 1.0, 0.8)
		metric_box.position = Vector3(i * 1.2, 0.5, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = colors[i]
		material.metallic = 0.3
		material.roughness = 0.4
		metric_box.material_override = material
		
		container.add_child(metric_box)

