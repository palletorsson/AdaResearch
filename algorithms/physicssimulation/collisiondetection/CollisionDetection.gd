extends Node3D

class_name CollisionDetection

enum AlgorithmType { BROAD_PHASE, NARROW_PHASE, BOTH }

var current_algorithm = AlgorithmType.BOTH
var objects = []
var paused = false
var show_spatial_grid = true
var spatial_grid_size = 2.0
var spatial_grid = {}

func _ready():
	_initialize_objects()
	_create_spatial_grid()
	_connect_ui()

func _initialize_objects():
	# Get all collision objects
	objects = $CollisionObjects.get_children()
	
	# Initialize each object
	for obj in objects:
		obj.initialize()

func _create_spatial_grid():
	# Clear existing grid
	for child in $SpatialGrid.get_children():
		child.queue_free()
	
	# Create spatial grid lines
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var bounds = 8.0
	var grid_count = int(bounds / spatial_grid_size)
	
	for i in range(-grid_count, grid_count + 1):
		# X lines
		var x_line = CSGBox3D.new()
		x_line.material = grid_material
		x_line.size = Vector3(0.01, 0.01, bounds * 2)
		x_line.position = Vector3(i * spatial_grid_size, 0.1, 0)
		$SpatialGrid.add_child(x_line)
		
		# Z lines
		var z_line = CSGBox3D.new()
		z_line.material = grid_material
		z_line.size = Vector3(bounds * 2, 0.01, 0.01)
		z_line.position = Vector3(0, 0.1, i * spatial_grid_size)
		$SpatialGrid.add_child(z_line)

func _physics_process(delta):
	if paused:
		return
	
	# Update object physics
	for obj in objects:
		obj.update_physics(delta)
	
	# Perform collision detection
	match current_algorithm:
		AlgorithmType.BROAD_PHASE:
			_broad_phase_collision_detection()
		AlgorithmType.NARROW_PHASE:
			_narrow_phase_collision_detection()
		AlgorithmType.BOTH:
			_broad_phase_collision_detection()
			_narrow_phase_collision_detection()
	
	# Update spatial grid
	_update_spatial_grid()

func _broad_phase_collision_detection():
	# Clear previous collision info
	_clear_collision_visuals()
	
	# Spatial hashing for broad phase
	spatial_grid.clear()
	
	# Hash objects into spatial grid
	for obj in objects:
		var grid_x = int(obj.position.x / spatial_grid_size)
		var grid_z = int(obj.position.z / spatial_grid_size)
		var grid_key = str(grid_x) + "," + str(grid_z)
		
		if not spatial_grid.has(grid_key):
			spatial_grid[grid_key] = []
		spatial_grid[grid_key].append(obj)
	
	# Check for potential collisions within same grid cells
	for grid_key in spatial_grid:
		var cell_objects = spatial_grid[grid_key]
		
		if cell_objects.size() > 1:
			# Multiple objects in same cell - potential collision
			for i in range(cell_objects.size()):
				for j in range(i + 1, cell_objects.size()):
					var obj1 = cell_objects[i]
					var obj2 = cell_objects[j]
					
					# Highlight objects in same cell
					_highlight_potential_collision(obj1, obj2)

func _narrow_phase_collision_detection():
	# Check all pairs for actual collisions
	for i in range(objects.size()):
		for j in range(i + 1, objects.size()):
			var obj1 = objects[i]
			var obj2 = objects[j]
			
			if _check_collision(obj1, obj2):
				_resolve_collision(obj1, obj2)
				_visualize_collision(obj1, obj2)

func _check_collision(obj1, obj2):
	# Simple AABB collision detection
	var pos1 = obj1.position
	var pos2 = obj2.position
	var size1 = obj1.get_size()
	var size2 = obj2.get_size()
	
	# Check if bounding boxes overlap
	return (abs(pos1.x - pos2.x) < (size1.x + size2.x) / 2 and
			abs(pos1.y - pos2.y) < (size1.y + size2.y) / 2 and
			abs(pos1.z - pos2.z) < (size1.z + size2.z) / 2)

func _resolve_collision(obj1, obj2):
	# Simple collision response - separate objects
	var collision_vector = obj2.position - obj1.position
	var distance = collision_vector.length()
	
	if distance == 0:
		return
	
	var normal = collision_vector / distance
	var size1 = obj1.get_size()
	var size2 = obj2.get_size()
	var overlap = (size1.x + size2.x) / 2 - abs(collision_vector.x)
	
	# Separate objects
	var separation = normal * overlap * 0.5
	obj1.position -= separation
	obj2.position += separation
	
	# Bounce velocities
	var relative_velocity = obj1.velocity - obj2.velocity
	var velocity_along_normal = relative_velocity.dot(normal)
	
	if velocity_along_normal < 0:
		var restitution = 0.7
		var impulse = -(1 + restitution) * velocity_along_normal
		
		obj1.velocity += normal * impulse
		obj2.velocity -= normal * impulse

func _highlight_potential_collision(obj1, obj2):
	# Create visual indicator for potential collision
	var indicator = CSGSphere3D.new()
	indicator.radius = 0.1
	indicator.material = StandardMaterial3D.new()
	indicator.material.albedo_color = Color.YELLOW
	indicator.material.emission_enabled = true
	indicator.material.emission = Color.YELLOW * 0.5
	
	# Position between objects
	indicator.position = (obj1.position + obj2.position) / 2
	indicator.position.y += 1.0
	
	$CollisionInfo.add_child(indicator)

func _visualize_collision(obj1, obj2):
	# Create visual indicator for actual collision
	var indicator = CSGSphere3D.new()
	indicator.radius = 0.15
	indicator.material = StandardMaterial3D.new()
	indicator.material.albedo_color = Color.RED
	indicator.material.emission_enabled = true
	indicator.material.emission = Color.RED * 0.8
	
	# Position between objects
	indicator.position = (obj1.position + obj2.position) / 2
	indicator.position.y += 1.5
	
	$CollisionInfo.add_child(indicator)

func _clear_collision_visuals():
	for child in $CollisionInfo.get_children():
		child.queue_free()

func _update_spatial_grid():
	# Show/hide spatial grid
	$SpatialGrid.visible = show_spatial_grid

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/AlgorithmButton.pressed.connect(_on_algorithm_pressed)
	$UI/VBoxContainer/GridToggle.pressed.connect(_on_grid_toggle_pressed)

func _on_reset_pressed():
	# Reset all objects to initial positions
	for obj in objects:
		obj.reset_to_initial()
	
	_clear_collision_visuals()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_algorithm_pressed():
	current_algorithm = (current_algorithm + 1) % AlgorithmType.size()
	
	# Update UI text
	var algorithm_names = ["Broad Phase", "Narrow Phase", "Both"]
	$UI/VBoxContainer/AlgorithmButton.text = "Algorithm: " + algorithm_names[current_algorithm]

func _on_grid_toggle_pressed():
	show_spatial_grid = !show_spatial_grid
	$UI/VBoxContainer/GridToggle.text = "Grid: " + ("ON" if show_spatial_grid else "OFF")
