@tool
extends Node3D

# Mondrian Grid Generator 3D
# Generates a 20x20 unit grid platform in the style of Mondrian.
# Colors (Red, Blue, Yellow) are represented as holes (empty space).
# Everything snaps to the nearest integer unit.

@export var generate_on_ready: bool = true
@export var grid_width: int = 20
@export var grid_depth: int = 20
@export var min_block_size: int = 2
@export var line_thickness: float = 0.2
@export var block_height: float = 1.0
@export var split_probability: float = 0.75
@export var colored_section_probability: float = 0.3 # Probability that a leaf is a "color" (hole)
@export var random_seed: int = 42 # Seed for deterministic generation

@export_group("Spawners")
@export var spawner_scene: PackedScene
@export var spawner_spacing: float = 7.0
@export var spawner_offset: float = 1.0 # Distance outside the grid

func _ready():
	if generate_on_ready:
		generate_grid()

func generate_grid():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Start recursive subdivision
	var initial_rect = Rect2i(0, 0, grid_width, grid_depth)
	
	# Set seed for determinism
	if random_seed != 0:
		seed(random_seed)
	else:
		randomize()
	
	var partitions = []
	_subdivide_rect(initial_rect, partitions)
	
	# Build the geometry
	_build_geometry(partitions)

	# Ensure spawner scene is loaded if referenced by path (though export does it)
	if spawner_scene == null:
		# Try to load default if not set
		if FileAccess.file_exists("res://algorithms/arrays/mondrian_grid/mondrian_spawner.tscn"):
			spawner_scene = load("res://algorithms/arrays/mondrian_grid/mondrian_spawner.tscn")

func _subdivide_rect(rect: Rect2i, partitions: Array):
	# Check if we should stop splitting
	# Stop if we are small enough, or randomly
	if rect.size.x <= min_block_size or rect.size.y <= min_block_size:
		partitions.append(rect)
		return
		
	# Randomly decide to stop splitting if we are larger than min size
	if randf() > split_probability:
		partitions.append(rect)
		return
		
	# Choose split direction (0: horizontal split (x-axis cut), 1: vertical split (y-axis cut))
	# Actually Rect2 names are x (width) and y (height/depth)
	# Determine split axis based on aspect ratio or random
	var split_axis = 0 # 0 for splitting along X (vertical line), 1 for splitting along Y (horizontal line)
	
	if rect.size.x > rect.size.y * 1.5:
		split_axis = 0 # Split width
	elif rect.size.y > rect.size.x * 1.5:
		split_axis = 1 # Split height
	else:
		split_axis = randi() % 2
		
	if split_axis == 0: # Split width (vertical line)
		var split_point = randi_range(rect.position.x + 1, rect.position.x + rect.size.x - 1)
		# Ensure integer split
		var r1 = Rect2i(rect.position.x, rect.position.y, split_point - rect.position.x, rect.size.y)
		var r2 = Rect2i(split_point, rect.position.y, rect.end.x - split_point, rect.size.y)
		
		# Validation to avoid zero size
		if r1.size.x > 0 and r2.size.x > 0:
			_subdivide_rect(r1, partitions)
			_subdivide_rect(r2, partitions)
		else:
			partitions.append(rect)
	else: # Split height (horizontal line)
		var split_point = randi_range(rect.position.y + 1, rect.position.y + rect.size.y - 1)
		
		var r1 = Rect2i(rect.position.x, rect.position.y, rect.size.x, split_point - rect.position.y)
		var r2 = Rect2i(rect.position.x, split_point, rect.size.x, rect.end.y - split_point)
		
		if r1.size.y > 0 and r2.size.y > 0:
			_subdivide_rect(r1, partitions)
			_subdivide_rect(r2, partitions)
		else:
			partitions.append(rect)

func _build_geometry(partitions: Array):
	# Create a container for the mesh
	var mesh_root = Node3D.new()
	mesh_root.name = "GridMesh"
	add_child(mesh_root)
	
	# We center the grid around 0,0 usually, or start at 0,0. 
	# Let's center it for convenience. 20x20 means -10 to +10.
	var offset = Vector3(-grid_width / 2.0, 0, -grid_depth / 2.0)
	
	for rect in partitions:
		# Decide type: Solid (White) or Hole (Color)
		var is_hole = randf() < colored_section_probability
		var rect_material: StandardMaterial3D
		
		if is_hole:
			# It's a hole! (Red/Blue/Yellow)
			# Generated visually but NO collision
			var color_roll = randf()
			if color_roll < 0.33:
				rect_material = _get_red_material()
			elif color_roll < 0.66:
				rect_material = _get_blue_material()
			else:
				rect_material = _get_yellow_material()
		else:
			# White section
			# Generated visually but NO collision (per user request: "only keep colliders on black")
			rect_material = _get_white_material()
			
		# Create the visual block
		var box = CSGBox3D.new()
		box.size = Vector3(rect.size.x - line_thickness, block_height, rect.size.y - line_thickness)
		# Position is center of rect + offset
		var cx = rect.position.x + rect.size.x / 2.0
		var cy = rect.position.y + rect.size.y / 2.0
		
		box.position = Vector3(cx, -block_height/2.0, cy) + offset
		box.material_override = rect_material
		
		# User Request: "make only the white fall-throw"
		# So Colors (is_hole) are SOLID. White is FALL-THROUGH.
		if is_hole:
			box.use_collision = true
		else:
			box.use_collision = false
			# Add ghost animation script to white blocks
			box.set_script(load("res://algorithms/arrays/mondrian_grid/mondrian_ghost_block.gd"))
		
		mesh_root.add_child(box)

	# Generate Grid Lines (Black)
	_generate_grid_lines(partitions, offset)

func _generate_grid_lines(partitions: Array, offset: Vector3):
	# We create beams for all 4 edges of every rect.
	
	var beams_root = Node3D.new()
	beams_root.name = "Beams"
	add_child(beams_root)
	
	var spawners_root = Node3D.new()
	spawners_root.name = "Spawners"
	add_child(spawners_root)
	
	var processed_edges = {} # Key: "x1,y1-x2,y2"
	
	# Store boundary edges for spawner placement
	# We want to place spawners on the OUTER edges of the overall grid
	# Overall grid is 0,0 to grid_width, grid_depth
	var boundary_edges = []
	
	for rect in partitions:
		# 4 edges
		var edges = [
			Vector4(rect.position.x, rect.position.y, rect.end.x, rect.position.y), # Top
			Vector4(rect.position.x, rect.end.y, rect.end.x, rect.end.y), # Bottom
			Vector4(rect.position.x, rect.position.y, rect.position.x, rect.end.y), # Left
			Vector4(rect.end.x, rect.position.y, rect.end.x, rect.end.y) # Right
		]
		
		for e in edges:
			var key = "%d,%d-%d,%d" % [e.x, e.y, e.z, e.w]
			
			if not processed_edges.has(key):
				processed_edges[key] = true
				_create_beam(e, offset, beams_root)
			
			# Check if this edge is on the boundary
			# Adjust for float precision if needed, but we use ints for grid coords
			var is_top_edge = (e.y == 0 and e.w == 0)
			var is_bottom_edge = (e.y == grid_depth and e.w == grid_depth)
			var is_left_edge = (e.x == 0 and e.z == 0)
			var is_right_edge = (e.x == grid_width and e.z == grid_width)
			
			if is_top_edge or is_bottom_edge or is_left_edge or is_right_edge:
				_try_place_spawners(e, offset, spawners_root)
			else:
				# Debug: why is this NOT a boundary?
				if e.y == 0 or e.w == 0:
					print("MondrianGenerator: Near-miss TOP edge? %s (y==0: %s, w==0: %s)" % [e, e.y==0, e.w==0])
				if e.x == 0 or e.z == 0:
					print("MondrianGenerator: Near-miss LEFT edge? %s (x==0: %s, z==0: %s)" % [e, e.x==0, e.z==0])


func _try_place_spawners(coords: Vector4, offset: Vector3, parent: Node):
	if not spawner_scene:
		# Auto-load default if missing
		print("MondrianGenerator: Spawner scene not set, loading default...")
		spawner_scene = load("res://algorithms/arrays/mondrian_grid/mondrian_spawner.tscn")
		if not spawner_scene:
			print("MondrianGenerator: ⚠️ Failed to load default spawner scene!")
			return

	var start = Vector2(coords.x, coords.y)
	var end = Vector2(coords.z, coords.w)
	var length = start.distance_to(end)
	var is_horizontal = (start.y == end.y)
	
	# Determine if we should place a spawner here
	# Simple logic: Place if the segment crosses a multiple of spawner_spacing
	# OR just place one if it's long enough?
	
	# Better logic: The user wants "something like 7 apart".
	# We can use a global counter or just check coordinates.
	
	# Let's iterate along the segment
	var t = 0.0
	while t <= length:
		var pos_on_line = start.move_toward(end, t)
		
		# Robust check using round to avoid float precision issues
		var check_val = 0
		if is_horizontal:
			check_val = round(pos_on_line.x)
		else:
			check_val = round(pos_on_line.y)
			
		var spacing_int = int(round(spawner_spacing))
		
		if int(check_val) % spacing_int == 0:
			print("MondrianGenerator: Placing spawner at %s (val=%d %% %d == 0)" % [pos_on_line, check_val, spacing_int])
			_spawn_spawner(pos_on_line, offset, parent, is_horizontal)
			
		t += 1.0 # Check every unit

func _spawn_spawner(pos_2d: Vector2, offset: Vector3, parent: Node, is_horizontal: bool):
	# Calculate 3D position
	var pos_3d = Vector3(pos_2d.x, block_height/2.0, pos_2d.y) + offset
	
	# Determine orientation (Face inward)
	# Center of grid (in local coords with offset applied) is 0,0,0
	# We want to look AT the center (0,0,0)
	
	var world_pos = pos_3d
	var look_target = Vector3(0, block_height/2.0, 0)
	
	# Instantiate
	var spawner = spawner_scene.instantiate()
	spawner.position = pos_3d
	
	parent.add_child(spawner)
	
	# Explicit rotation based on edge (User requested: 180, -90, 90, 0)
	# Top Edge (z=0) -> Face +Z (South) -> Rotation 180
	# Bottom Edge (z=max) -> Face -Z (North) -> Rotation 0
	# Left Edge (x=0) -> Face +X (East) -> Rotation -90
	# Right Edge (x=max) -> Face -X (West) -> Rotation 90
	
	var r_y = 0.0
	var threshold = 0.1 # float margin
	
	if abs(pos_2d.y) < threshold: # Top Edge (z=0)
		r_y = 180.0
	elif abs(pos_2d.y - grid_depth) < threshold: # Bottom Edge
		r_y = 0.0
	elif abs(pos_2d.x) < threshold: # Left Edge
		r_y = -90.0
	elif abs(pos_2d.x - grid_width) < threshold: # Right Edge
		r_y = 90.0
	else:
		# Fallback to look_at if somehow internal
		spawner.look_at(look_target, Vector3.UP)
		r_y = spawner.rotation_degrees.y
		
	spawner.rotation_degrees.y = r_y
	
	# Move back slightly to sit "on the side"
	spawner.translate_object_local(Vector3(0, 0, spawner_offset)) 

func _create_beam(coords: Vector4, offset: Vector3, parent: Node):
	var start = Vector2(coords.x, coords.y)
	var end = Vector2(coords.z, coords.w)
	var length = start.distance_to(end)
	var is_horizontal = (start.y == end.y)
	
	# Revert to simple beam matching mesh
	var beam = CSGBox3D.new()
	
	if is_horizontal:
		beam.size = Vector3(length + line_thickness, block_height, line_thickness)
	else:
		beam.size = Vector3(line_thickness, block_height, length + line_thickness)
		
	var mid = (start + end) / 2.0
	beam.position = Vector3(mid.x, -block_height/2.0, mid.y) + offset
	beam.material_override = _get_black_material()
	beam.use_collision = true 
	
	parent.add_child(beam)

# Materials
var _mat_white: StandardMaterial3D
var _mat_black: StandardMaterial3D
var _mat_red: StandardMaterial3D
var _mat_blue: StandardMaterial3D
var _mat_yellow: StandardMaterial3D

func _get_white_material() -> StandardMaterial3D:
	if _mat_white: return _mat_white
	_mat_white = StandardMaterial3D.new()
	_mat_white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_white.albedo_color = Color(0.95, 0.95, 0.95, 0.3) # Transparent white
	_mat_white.emission_enabled = true
	_mat_white.emission = _mat_white.albedo_color
	_mat_white.emission_energy_multiplier = 0.5
	return _mat_white

func _get_black_material() -> StandardMaterial3D:
	if _mat_black: return _mat_black
	_mat_black = StandardMaterial3D.new()
	_mat_black.albedo_color = Color(0.1, 0.1, 0.1)
	return _mat_black

func _get_red_material() -> StandardMaterial3D:
	if _mat_red: return _mat_red
	_mat_red = StandardMaterial3D.new()
	_mat_red.albedo_color = Color(0.9, 0.1, 0.1)
	_mat_red.emission_enabled = true
	_mat_red.emission = _mat_red.albedo_color
	_mat_red.emission_energy_multiplier = 1.0
	return _mat_red

func _get_blue_material() -> StandardMaterial3D:
	if _mat_blue: return _mat_blue
	_mat_blue = StandardMaterial3D.new()
	_mat_blue.albedo_color = Color(0.1, 0.1, 0.9)
	_mat_blue.emission_enabled = true
	_mat_blue.emission = _mat_blue.albedo_color
	_mat_blue.emission_energy_multiplier = 1.0
	return _mat_blue

func _get_yellow_material() -> StandardMaterial3D:
	if _mat_yellow: return _mat_yellow
	_mat_yellow = StandardMaterial3D.new()
	_mat_yellow.albedo_color = Color(0.9, 0.9, 0.1)
	_mat_yellow.emission_enabled = true
	_mat_yellow.emission = _mat_yellow.albedo_color
	_mat_yellow.emission_energy_multiplier = 1.0
	return _mat_yellow
