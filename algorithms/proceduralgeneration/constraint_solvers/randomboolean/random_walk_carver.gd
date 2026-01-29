## res://algorithms/proceduralgeneration/randomboolean/random_walk_carver.gd
## Carves holes in a cube using CSGSphere3D along a random walk path
extends CSGCombiner3D

## Random walk parameters
@export var walk_steps : int = 50
@export var step_size : float = 0.8  # Increased from 0.5 for better spacing
@export var sphere_radius : float = 0.4

## Cube dimensions
@export var cube_size : Vector3 = Vector3(10, 10, 10)

## Random walk settings
@export var avoid_self_crossing : bool = true
@export var crossing_check_distance : float = 0.6  # Reduced from 1.0 to allow denser paths

## Visual settings
@export var show_path_line : bool = true
@export var path_line_color : Color = Color(1, 0.5, 0, 1)

## Generation settings
@export var random_seed : int = -1
@export var auto_generate : bool = true

## Internal
var path_points : PackedVector3Array = []
var occupied_positions : Array[Vector3] = []

func _ready():
	if auto_generate:
		# Defer one frame to ensure CSG system is ready
		call_deferred("generate_carved_cube")

func generate_carved_cube():
	# Clear existing CSG shapes (but keep Label3D and other scene nodes)
	for child in get_children():
		if child is CSGShape3D or child is MeshInstance3D:
			child.queue_free()
	
	path_points.clear()
	occupied_positions.clear()
	
	# Set random seed
	if random_seed >= 0:
		seed(random_seed)
	
	print("🔮 Starting random walk carving...")
	
	# Create base cube (as child of CSGCombiner3D)
	_create_base_cube()
	
	# Generate random walk path
	_generate_random_walk()
	
	# Carve spheres along path (as siblings of base cube, also children of CSGCombiner3D)
	_carve_spheres_along_path()
	
	# Optionally show path visualization
	if show_path_line:
		_create_path_visualization()
	
	print("✅ Carving complete! ", path_points.size(), " points in path")

## Create the base solid cube (as child of CSGCombiner3D - this node)
func _create_base_cube():
	var cube = CSGBox3D.new()
	cube.name = "BaseCube"
	cube.size = cube_size
	cube.material = _create_base_material()
	add_child(cube)  # Add as child of CSGCombiner3D
	print("📦 Created base cube: ", cube_size)

## Generate a random walk path that avoids crossing itself
func _generate_random_walk():
	# Start at center
	var current_pos = Vector3.ZERO
	path_points.append(current_pos)
	occupied_positions.append(current_pos)
	
	# Possible movement directions (6 directions in 3D)
	var directions = [
		Vector3.RIGHT,
		Vector3.LEFT,
		Vector3.UP,
		Vector3.DOWN,
		Vector3.FORWARD,
		Vector3.BACK
	]
	
	var stuck_count = 0
	var max_stuck_attempts = 10
	
	for step in range(walk_steps):
		var valid_move_found = false
		var attempts = 0
		
		while not valid_move_found and attempts < 20:
			# Pick random direction
			var direction = directions[randi() % directions.size()]
			var next_pos = current_pos + (direction * step_size)
			
			# Check if move is valid
			if _is_valid_move(next_pos):
				current_pos = next_pos
				path_points.append(current_pos)
				occupied_positions.append(current_pos)
				valid_move_found = true
				stuck_count = 0
			else:
				attempts += 1
		
		if not valid_move_found:
			stuck_count += 1
			if stuck_count >= max_stuck_attempts:
				print("⚠️ Walk got stuck after ", step, " steps")
				break
	
	print("🚶 Generated walk with ", path_points.size(), " points")

## Check if a move is valid (within bounds and not crossing)
func _is_valid_move(pos: Vector3) -> bool:
	# Check if within cube bounds (with small margin)
	var half_size = cube_size * 0.5 - Vector3.ONE * sphere_radius
	if abs(pos.x) > half_size.x or abs(pos.y) > half_size.y or abs(pos.z) > half_size.z:
		return false
	
	# Check for self-crossing if enabled
	if avoid_self_crossing:
		for occupied in occupied_positions:
			if pos.distance_to(occupied) < crossing_check_distance:
				return false
	
	return true

## Create carving spheres along the path (as siblings of base cube under CSGCombiner3D)
func _carve_spheres_along_path():
	var sphere_count = 0
	
	print("🔨 Carving ", path_points.size(), " spheres...")
	
	for i in range(path_points.size()):
		var pos = path_points[i]
		
		# Create subtractive sphere at this position
		var sphere = CSGSphere3D.new()
		sphere.name = "CarveSphere_%d" % i
		sphere.operation = CSGShape3D.OPERATION_SUBTRACTION  # CRITICAL: Subtract operation
		sphere.radius = sphere_radius
		sphere.transform.origin = pos
		sphere.radial_segments = 8  # Lower detail for performance
		sphere.rings = 6
		
		# Optional: vary sphere size slightly for organic look
		if randf() > 0.7:
			sphere.radius *= randf_range(0.8, 1.3)
		
		# Add as CHILD of CSGCombiner3D (sibling to base cube)
		add_child(sphere)  # Add to CSGCombiner3D, not the cube!
		sphere_count += 1
	
	print("✂️ Carved ", sphere_count, " spheres (CSGCombiner3D will combine them)")

## Create visual line showing the path
func _create_path_visualization():
	if path_points.size() < 2:
		return
	
	var line = MeshInstance3D.new()
	line.name = "PathVisualization"
	
	# Create line mesh
	var mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for point in path_points:
		surface_tool.add_color(path_line_color)
		surface_tool.add_vertex(point)
	
	mesh = surface_tool.commit()
	line.mesh = mesh
	
	# Create material for the line
	var mat = StandardMaterial3D.new()
	mat.albedo_color = path_line_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	line.material_override = mat
	
	add_child(line)
	print("📏 Created path visualization")

## Create material for base cube
func _create_base_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.8, 1.0)
	mat.metallic = 0.3
	mat.roughness = 0.7
	return mat

## Public function to regenerate with new seed
func regenerate(new_seed: int = -1):
	if new_seed >= 0:
		random_seed = new_seed
	else:
		random_seed = randi()
	
	generate_carved_cube()

## Get the carving path for external use
func get_carve_path() -> PackedVector3Array:
	return path_points
