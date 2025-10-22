## res://algorithms/proceduralgeneration/randomboolean/advanced_carver.gd
## Advanced CSG carving with multiple patterns and effects
extends CSGCombiner3D

enum CarvePattern {
	RANDOM_WALK,      # Standard random walk
	SPIRAL,           # Spiral through the cube
	BRANCHES,         # Tree-like branching
	PERLIN_PATH,      # Follow Perlin noise field
	GRID_TUNNELS,     # Grid of tunnels
}

## Pattern selection
@export var pattern : CarvePattern = CarvePattern.RANDOM_WALK

## Base parameters
@export_group("Base Shape")
@export var cube_size : Vector3 = Vector3(10, 10, 10)
@export var base_shape_type : String = "cube"  # cube, sphere, cylinder

## Carving parameters
@export_group("Carving")
@export var walk_steps : int = 60
@export var step_size : float = 0.8  # Increased from 0.5
@export var sphere_radius : float = 0.4
@export var radius_variation : float = 0.2
@export var avoid_self_crossing : bool = true
@export var crossing_check_distance : float = 0.6  # Reduced from 1.0 to allow denser paths

## Pattern-specific parameters
@export_group("Pattern Settings")
@export var spiral_turns : float = 3.0
@export var spiral_radius_decay : float = 0.5
@export var branch_probability : float = 0.15
@export var max_branches : int = 5
@export var perlin_scale : float = 0.3
@export var perlin_strength : float = 2.0

## Visual settings
@export_group("Visuals")
@export var show_path_line : bool = true
@export var path_line_color : Color = Color(1, 0.5, 0, 1)
@export var base_material_color : Color = Color(0.7, 0.7, 0.8, 1.0)

## Generation
@export_group("Generation")
@export var random_seed : int = -1
@export var auto_generate : bool = true

## Internal
var path_points : PackedVector3Array = []
var all_branches : Array[PackedVector3Array] = []
var occupied_positions : Array[Vector3] = []

func _ready():
	if auto_generate:
		# Defer one frame to ensure CSG system is ready
		call_deferred("generate")

func generate():
	# Clear existing CSG shapes (but keep Label3D and other scene nodes)
	for child in get_children():
		if child is CSGShape3D or child is MeshInstance3D:
			child.queue_free()
	
	path_points.clear()
	all_branches.clear()
	occupied_positions.clear()
	
	if random_seed >= 0:
		seed(random_seed)
	
	print("🎨 Generating carved shape with pattern: ", CarvePattern.keys()[pattern])
	
	# Create base shape (as child of CSGCombiner3D)
	_create_base_shape()
	
	# Generate path based on pattern
	match pattern:
		CarvePattern.RANDOM_WALK:
			_generate_random_walk()
		CarvePattern.SPIRAL:
			_generate_spiral()
		CarvePattern.BRANCHES:
			_generate_branching_path()
		CarvePattern.PERLIN_PATH:
			_generate_perlin_path()
		CarvePattern.GRID_TUNNELS:
			_generate_grid_tunnels()
	
	# Carve the path(s) as siblings of base shape under CSGCombiner3D
	_carve_all_paths()
	
	# Visualize
	if show_path_line:
		_create_path_visualization()
	
	print("✅ Carving complete!")

func _create_base_shape():
	var shape : CSGShape3D
	
	match base_shape_type:
		"sphere":
			var sphere = CSGSphere3D.new()
			sphere.radius = cube_size.x * 0.5
			shape = sphere
		"cylinder":
			var cylinder = CSGCylinder3D.new()
			cylinder.radius = cube_size.x * 0.5
			cylinder.height = cube_size.y
			shape = cylinder
		_:  # cube (default)
			var cube = CSGBox3D.new()
			cube.size = cube_size
			shape = cube
	
	shape.name = "BaseShape"
	shape.material = _create_material(base_material_color)
	add_child(shape)  # Add as child of CSGCombiner3D

func _generate_random_walk():
	var current_pos = Vector3.ZERO
	path_points.append(current_pos)
	occupied_positions.append(current_pos)
	
	var directions = [
		Vector3.RIGHT, Vector3.LEFT,
		Vector3.UP, Vector3.DOWN,
		Vector3.FORWARD, Vector3.BACK
	]
	
	for step in range(walk_steps):
		var valid = false
		var attempts = 0
		
		while not valid and attempts < 20:
			var dir = directions[randi() % directions.size()]
			var next_pos = current_pos + (dir * step_size)
			
			if _is_valid_position(next_pos):
				current_pos = next_pos
				path_points.append(current_pos)
				occupied_positions.append(current_pos)
				valid = true
			attempts += 1

func _generate_spiral():
	var vertical_segments = walk_steps
	var height_per_step = (cube_size.y * 0.8) / vertical_segments
	
	for i in range(vertical_segments):
		var t = float(i) / vertical_segments
		var angle = t * spiral_turns * TAU
		var radius_decay = 1.0 - (t * spiral_radius_decay)
		var radius = (cube_size.x * 0.4) * radius_decay
		
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = (t - 0.5) * cube_size.y * 0.8
		
		var pos = Vector3(x, y, z)
		path_points.append(pos)
		occupied_positions.append(pos)

func _generate_branching_path():
	# Main trunk
	var main_path = _create_branch(Vector3.ZERO, Vector3.UP, int(walk_steps * 0.6))
	path_points = main_path
	all_branches.append(main_path)
	
	# Create branches (only if main path has enough points)
	if main_path.size() > 10:
		var branches_created = 0
		for i in range(max_branches):
			if randf() < branch_probability and branches_created < max_branches:
				var safe_size = max(1, main_path.size() - 10)
				var branch_start_idx = randi() % safe_size
				var branch_start = main_path[branch_start_idx]
				
				# Random branch direction
				var branch_dir = Vector3(
					randf_range(-1, 1),
					randf_range(-0.5, 0.5),
					randf_range(-1, 1)
				).normalized()
				
				var branch_path = _create_branch(branch_start, branch_dir, int(walk_steps * 0.3))
				all_branches.append(branch_path)
				branches_created += 1
	else:
		print("⚠️ Main path too short for branches (", main_path.size(), " points)")

func _create_branch(start: Vector3, main_direction: Vector3, steps: int) -> PackedVector3Array:
	var branch = PackedVector3Array()
	var current = start
	branch.append(current)
	
	for i in range(steps):
		# Bias toward main direction but add randomness
		var random_offset = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		)
		var direction = (main_direction + random_offset).normalized()
		var next = current + direction * step_size
		
		if _is_valid_position(next):
			current = next
			branch.append(current)
			occupied_positions.append(current)
	
	return branch

func _generate_perlin_path():
	var current_pos = Vector3.ZERO
	path_points.append(current_pos)
	
	for step in range(walk_steps):
		# Sample Perlin noise to get direction
		var noise_x = sin(current_pos.x * perlin_scale + step * 0.1) * perlin_strength
		var noise_y = cos(current_pos.y * perlin_scale + step * 0.15) * perlin_strength
		var noise_z = sin(current_pos.z * perlin_scale + step * 0.12) * perlin_strength
		
		var direction = Vector3(noise_x, noise_y, noise_z).normalized()
		var next_pos = current_pos + direction * step_size
		
		if _is_valid_position(next_pos):
			current_pos = next_pos
			path_points.append(current_pos)
			occupied_positions.append(current_pos)

func _generate_grid_tunnels():
	var grid_size = 3
	var spacing = cube_size.x / (grid_size + 1)
	
	# Create horizontal tunnels
	for y in range(grid_size):
		for z in range(grid_size):
			var start_y = (y - grid_size/2.0 + 0.5) * spacing
			var start_z = (z - grid_size/2.0 + 0.5) * spacing
			
			var tunnel_path = PackedVector3Array()
			for x in range(-grid_size, grid_size + 1):
				var pos = Vector3(x * spacing * 0.5, start_y, start_z)
				tunnel_path.append(pos)
			
			all_branches.append(tunnel_path)

func _is_valid_position(pos: Vector3) -> bool:
	var half_size = cube_size * 0.45
	if abs(pos.x) > half_size.x or abs(pos.y) > half_size.y or abs(pos.z) > half_size.z:
		return false
	
	if avoid_self_crossing:
		for occupied in occupied_positions:
			if pos.distance_to(occupied) < crossing_check_distance:
				return false
	
	return true

func _carve_all_paths():
	var all_points = path_points.duplicate()
	for branch in all_branches:
		for point in branch:
			if point not in all_points:
				all_points.append(point)
	
	print("🔨 Carving ", all_points.size(), " spheres...")
	
	for i in range(all_points.size()):
		var pos = all_points[i]
		var sphere = CSGSphere3D.new()
		sphere.name = "Carve_%d" % i
		sphere.operation = CSGShape3D.OPERATION_SUBTRACTION  # CRITICAL: Subtract operation
		
		# Vary radius
		var radius = sphere_radius
		if radius_variation > 0:
			radius *= randf_range(1.0 - radius_variation, 1.0 + radius_variation)
		
		sphere.radius = radius
		sphere.transform.origin = pos
		sphere.radial_segments = 6
		sphere.rings = 4
		
		# Add as CHILD of CSGCombiner3D (sibling to base shape)
		add_child(sphere)  # Add to CSGCombiner3D, not the base shape!
	
	print("✂️ Carved ", all_points.size(), " spheres (CSGCombiner3D will combine them)")

func _create_path_visualization():
	# Main path
	if path_points.size() > 1:
		_create_line_mesh(path_points, path_line_color, "MainPath")
	
	# Branch paths
	for i in range(all_branches.size()):
		if all_branches[i].size() > 1:
			var branch_color = Color(randf(), randf(), randf(), 0.8)
			_create_line_mesh(all_branches[i], branch_color, "Branch_%d" % i)

func _create_line_mesh(points: PackedVector3Array, color: Color, name_str: String):
	var line = MeshInstance3D.new()
	line.name = name_str
	
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for point in points:
		st.set_color(color)  # Godot 4: use set_color instead of add_color
		st.add_vertex(point)
	
	mesh = st.commit()
	line.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	line.material_override = mat
	
	add_child(line)

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.7
	return mat

func regenerate(new_seed: int = -1):
	random_seed = new_seed if new_seed >= 0 else randi()
	generate()
