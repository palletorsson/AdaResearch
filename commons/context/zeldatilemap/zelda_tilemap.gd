extends Node3D

# Tile map parameters
@export var map_width: int = 60
@export var map_height: int = 60
@export var tile_size: float = 1.0
@export var map_scale: float = 0.2  # Scale the map down to a reasonable size for VR

# Initial positioning
@export var initial_position: Vector3 = Vector3(5.0, -1.5, 15.0)  # Default: 1m down, 4m forward
@export var auto_position_on_ready: bool = true  # Whether to automatically position the map on _ready

# Tile colors for different terrain types
var tile_colors = {
	"empty": Color(0, 0, 0, 0),        # Transparent
	"sand": Color(0.95, 0.85, 0.5),    # Light yellow
	"grass": Color(0.3, 0.8, 0.3),     # Green
	"water": Color(0.3, 0.5, 0.95),    # Blue
	"rock": Color(0.5, 0.5, 0.5),      # Gray
	"mountain": Color(0.3, 0.3, 0.3),  # Dark gray
	"building": Color(0.6, 0.4, 0.2)   # Brown
}

# Heights for different terrain types
var tile_heights = {
	"empty": 0.0,
	"sand": 0.1,
	"grass": 0.2,
	"water": 0.05,
	"rock": 0.3,
	"mountain": 0.5,
	"building": 0.4
}

# Map data storage
var map_data = []

# Node references
var tiles_parent: Node3D
var instance_mesh: MeshInstance3D

func _ready():
	# Create a parent node to hold all tile instances
	tiles_parent = Node3D.new()
	tiles_parent.name = "Tiles"
	add_child(tiles_parent)
	
	# Scale the map to a reasonable size for VR
	tiles_parent.scale = Vector3(map_scale, map_scale, map_scale)
	
	# Create the map
	generate_map()
	
	# Center the map at its local origin
	tiles_parent.position = Vector3(
		-map_width * tile_size * map_scale / 2,
		0,
		-map_height * tile_size * map_scale / 2
	)
	
	# Position the entire map at the initial position if auto-positioning is enabled
	if auto_position_on_ready:
		set_position(initial_position)

func generate_map():
	randomize()
	
	# Initialize map with empty cells
	map_data = []
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			row.append("sand")  # Default to sand
		map_data.append(row)
	
	# Generate rooms and features
	generate_features()
	
	# Create the visual representation
	create_visual_map()

func generate_features():
	# Add various terrain features to make the map interesting
	
	# Add water bodies (lakes, rivers)
	add_water_bodies(5)
	
	# Add grass areas
	add_terrain_patches("grass", 12, 15)
	
	# Add rock formations
	add_terrain_patches("rock", 8, 5)
	
	# Add mountain ranges
	add_mountain_ranges(3)
	
	# Add buildings/structures
	add_buildings(20)

func add_water_bodies(count: int):
	for i in range(count):
		# Choose between lake and river
		if randf() > 0.5:
			# Create a lake (circular water body)
			var center_x = randi() % map_width
			var center_y = randi() % map_height
			var radius = randi() % 10 + 5
			
			for y in range(max(0, center_y - radius), min(map_height, center_y + radius)):
				for x in range(max(0, center_x - radius), min(map_width, center_x + radius)):
					var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
					if distance < radius * (0.8 + randf() * 0.4):
						map_data[y][x] = "water"
		else:
			# Create a river (meandering path)
			var start_x = randi() % map_width
			var current_x = start_x
			var current_y = 0
			
			while current_y < map_height:
				# Mark current position as water
				if current_y >= 0 and current_y < map_height and current_x >= 0 and current_x < map_width:
					map_data[current_y][current_x] = "water"
					
					# Add some width to the river
					for dx in range(-2, 3):
						var river_x = current_x + dx
						if river_x >= 0 and river_x < map_width:
							map_data[current_y][river_x] = "water"
				
				# Move downward with some meandering
				current_y += 1
				current_x += randi() % 5 - 2  # Random movement left or right
				
				# Keep within bounds
				current_x = clamp(current_x, 0, map_width - 1)

func add_terrain_patches(terrain_type: String, count: int, max_size: int):
	for i in range(count):
		var size = randi() % max_size + 5
		var center_x = randi() % map_width
		var center_y = randi() % map_height
		
		for y in range(max(0, center_y - size), min(map_height, center_y + size)):
			for x in range(max(0, center_x - size), min(map_width, center_x + size)):
				var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
				if distance < size * (0.6 + randf() * 0.4):
					map_data[y][x] = terrain_type

func add_mountain_ranges(count: int):
	for i in range(count):
		# Start point for the mountain range
		var start_x = randi() % map_width
		var start_y = randi() % map_height
		
		# Direction and length
		var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
		var length = randi() % 20 + 10
		
		for j in range(length):
			var pos_x = int(start_x + direction.x * j)
			var pos_y = int(start_y + direction.y * j)
			
			if pos_x >= 0 and pos_x < map_width and pos_y >= 0 and pos_y < map_height:
				# Create a small mountain cluster at this point
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var mountain_x = pos_x + dx
						var mountain_y = pos_y + dy
						
						if mountain_x >= 0 and mountain_x < map_width and mountain_y >= 0 and mountain_y < map_height:
							var distance = sqrt(pow(dx, 2) + pow(dy, 2))
							if distance < 3 and randf() > 0.3:
								map_data[mountain_y][mountain_x] = "mountain"

func add_buildings(count: int):
	for i in range(count):
		var width = randi() % 5 + 3
		var height = randi() % 5 + 3
		var pos_x = randi() % (map_width - width)
		var pos_y = randi() % (map_height - height)
		
		# Create the building
		for y in range(pos_y, pos_y + height):
			for x in range(pos_x, pos_x + width):
				if x >= 0 and x < map_width and y >= 0 and y < map_height:
					# Make walls on the perimeter, leave the interior
					if x == pos_x or x == pos_x + width - 1 or y == pos_y or y == pos_y + height - 1:
						map_data[y][x] = "building"

func create_visual_map():
	# Create the base mesh for a single tile
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(tile_size, tile_size)
	plane_mesh.subdivide_width = 0
	plane_mesh.subdivide_depth = 0
	
	# Create materials for each terrain type
	var materials = {}
	for terrain_type in tile_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = tile_colors[terrain_type]
		material.roughness = 0.8
		materials[terrain_type] = material
	
	# Create tile instances
	for y in range(map_height):
		for x in range(map_width):
			var terrain_type = map_data[y][x]
			
			# Skip empty tiles
			if terrain_type == "empty":
				continue
			
			# Create a mesh instance for this tile
			var tile = MeshInstance3D.new()
			tile.mesh = plane_mesh
			tile.material_override = materials[terrain_type]
			
			# Position the tile
			tile.position = Vector3(
				x * tile_size + tile_size/2, 
				tile_heights[terrain_type], 
				y * tile_size + tile_size/2
			)
			
			# Add collision if needed
			# var collision_shape = CollisionShape3D.new()
			# var box_shape = BoxShape3D.new()
			# box_shape.extents = Vector3(tile_size/2, tile_heights[terrain_type]/2, tile_size/2)
			# collision_shape.shape = box_shape
			# collision_shape.position.y = -tile_heights[terrain_type]/2
			# tile.add_child(collision_shape)
			
			# Add the tile to the scene
			tiles_parent.add_child(tile)
			
			# For efficiency in VR, you might want to combine meshes
			if x % 10 == 0 and y % 10 == 0:
				# This is a simple optimization to reduce draw calls
				tiles_parent.call_deferred("merge_meshes", Vector2i(x, y))

# Merge meshes in a region to reduce draw calls (better performance in VR)
func merge_meshes(region_start: Vector2i):
	var region_size = 10
	var region_end_x = min(region_start.x + region_size, map_width)
	var region_end_y = min(region_start.y + region_size, map_height)
	
	# This would need to be implemented with MultiMesh or CSG combining
	# Advanced implementation would go here
	pass

# Function to regenerate the map
func regenerate():
	# Clear existing tiles
	for child in tiles_parent.get_children():
		child.queue_free()
	
	# Generate a new map
	generate_map()
	
# Function to set the map position
func set_my_position(position: Vector3):
	self.global_transform.origin = position
	
# Function to reset the map to its initial position
func reset_position():
	set_my_position(initial_position)
	
# Function to offset the map from its current position
func offset_position(offset: Vector3):
	self.global_transform.origin += offset
