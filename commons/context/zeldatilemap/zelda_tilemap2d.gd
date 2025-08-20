extends Node2D

# Tile map parameters
@export var map_width: int = 60
@export var map_height: int = 60
@export var tile_size: float = 16.0  # Pixel size of each tile
@export var map_scale: float = 1.0   # Scale the map if needed

# Initial positioning
@export var initial_position: Vector2 = Vector2(100, 100)
@export var auto_position_on_ready: bool = true

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

# Map data storage
var map_data = []

# Node references
var tiles_parent: Node2D

func _ready():
	# Create a parent node to hold all tile instances
	tiles_parent = Node2D.new()
	tiles_parent.name = "Tiles"
	add_child(tiles_parent)
	
	# Scale the map
	tiles_parent.scale = Vector2(map_scale, map_scale)
	
	# Create the map
	generate_map()
	
	# Center the map at its local origin
	tiles_parent.position = Vector2(
		-map_width * tile_size * map_scale / 2,
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
	# Create tile instances
	for y in range(map_height):
		for x in range(map_width):
			var terrain_type = map_data[y][x]
			
			# Skip empty tiles
			if terrain_type == "empty":
				continue
			
			# Create a ColorRect for this tile
			var tile = ColorRect.new()
			tile.color = tile_colors[terrain_type]
			tile.size = Vector2(tile_size, tile_size)
			
			# Position the tile
			tile.position = Vector2(
				x * tile_size, 
				y * tile_size
			)
			
			# Add the tile to the scene
			tiles_parent.add_child(tile)

# Function to regenerate the map
func regenerate():
	# Clear existing tiles
	for child in tiles_parent.get_children():
		child.queue_free()
	
	# Generate a new map
	generate_map()
	
# Function to set the map position
func set_my_position(position: Vector2):
	self.global_position = position
	
# Function to reset the map to its initial position
func reset_position():
	set_my_position(initial_position)
	
# Function to offset the map from its current position
func offset_position(offset: Vector2):
	self.global_position += offset
