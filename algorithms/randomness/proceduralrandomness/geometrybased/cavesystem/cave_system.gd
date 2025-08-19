extends Node3D

# Improved Procedural Cave Generator with Textured Walls
# Ensures all caverns are connected into a single system

@export var cave_size: Vector3 = Vector3(20, 15, 20)  # Overall cave system dimensions
@export var num_primary_caverns: int = 5  # Number of main cave chambers
@export var tunnel_complexity: int = 10  # Number of interconnecting tunnels
@export var cave_seed: int = 42  # Seed for consistent generation

# Texture generation parameters
@export var texture_scale: float = 0.1  # Scale of noise texture
@export var color_variation: float = 0.2  # Amount of color variation

# Connectivity parameters
@export var ensure_full_connectivity: bool = true  # Make sure all caverns are connected
@export var extra_tunnels_ratio: float = 0.3  # Percentage of extra tunnels beyond minimum spanning tree

var rng: RandomNumberGenerator
var cave_root: Node3D
var noise: FastNoiseLite

func _ready():
	# Seed the random number generator
	rng = RandomNumberGenerator.new()
	rng.seed = cave_seed
	
	# Create noise for texture generation
	noise = FastNoiseLite.new()
	noise.seed = cave_seed
	noise.frequency = texture_scale
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	# Create a root node for our cave system
	cave_root = Node3D.new()
	cave_root.name = "CaveSystem"
	add_child(cave_root)
	
	# Generate the cave system
	generate_cave_system()

func generate_cave_system():
	# Create primary caverns
	var caverns = generate_primary_caverns()
	
	# Connect caverns with tunnels
	connect_caverns(caverns)
	
	# Add some environmental details
	add_cave_details()
	
	# Apply textures and materials
	apply_cave_textures()

func generate_primary_caverns() -> Array:
	var caverns = []
	
	for i in range(num_primary_caverns):
		# Create a CSG sphere as base for each cavern
		var cavern = CSGSphere3D.new()
		
		# Randomize cavern size and position
		var cavern_size = rng.randf_range(3.0, 8.0)
		cavern.radius = cavern_size
		
		# Position within the overall cave system
		cavern.position = Vector3(
			rng.randf_range(-cave_size.x/2, cave_size.x/2),
			rng.randf_range(-cave_size.y/2, cave_size.y/2),
			rng.randf_range(-cave_size.z/2, cave_size.z/2)
		)
		
		# Deform the sphere to make it more organic
		deform_cavern(cavern)
		
		# Add to scene and store reference
		cave_root.add_child(cavern)
		caverns.append(cavern)
	
	return caverns

func deform_cavern(cavern: CSGSphere3D):
	# Add multiple deformation spheres to create irregular shapes
	for i in range(rng.randi_range(2, 5)):
		var deformation_sphere = CSGSphere3D.new()
		
		# Randomize deformation sphere size and position
		var offset_scale = rng.randf_range(0.3, 0.7)
		deformation_sphere.radius = cavern.radius * offset_scale
		
		# Offset position relative to main cavern
		deformation_sphere.position = Vector3(
			rng.randf_range(-cavern.radius/2, cavern.radius/2),
			rng.randf_range(-cavern.radius/2, cavern.radius/2),
			rng.randf_range(-cavern.radius/2, cavern.radius/2)
		)
		
		# Use subtraction to create more organic shapes
		deformation_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
		
		# Add deformation sphere as a child to create boolean operation
		cavern.add_child(deformation_sphere)

func connect_caverns(caverns: Array):
	if ensure_full_connectivity:
		# Build a minimum spanning tree to ensure all caverns are connected
		var edges = []
		var connected_caverns = [0]  # Start with first cavern as connected
		var disconnected_caverns = []
		
		# Add all other caverns to disconnected list
		for i in range(1, caverns.size()):
			disconnected_caverns.append(i)
		
		# Create minimum spanning tree
		while disconnected_caverns.size() > 0:
			var min_distance = INF
			var closest_connected = 0
			var closest_disconnected = 0
			
			# Find closest pair of connected and disconnected caverns
			for connected_idx in connected_caverns:
				for disconnected_idx in disconnected_caverns:
					var distance = caverns[connected_idx].position.distance_to(caverns[disconnected_idx].position)
					if distance < min_distance:
						min_distance = distance
						closest_connected = connected_idx
						closest_disconnected = disconnected_idx
			
			# Create tunnel between closest pair
			create_tunnel(caverns[closest_connected], caverns[closest_disconnected])
			
			# Move cavern from disconnected to connected
			connected_caverns.append(closest_disconnected)
			disconnected_caverns.erase(closest_disconnected)
		
		# Add some additional tunnels for complexity
		var additional_tunnels = int(caverns.size() * extra_tunnels_ratio)
		
		# Store already created tunnels
		var created_tunnels = {}
		for i in range(caverns.size()):
			for j in range(i + 1, caverns.size()):
				if connected_caverns.has(i) and connected_caverns.has(j):
					var tunnel_key = str(min(i, j)) + "_" + str(max(i, j))
					created_tunnels[tunnel_key] = true
		
		# Add random additional tunnels
		for _i in range(additional_tunnels):
			# Try to find a new tunnel to create
			var attempts = 0
			while attempts < 10:  # Limit attempts to prevent infinite loop
				var a = rng.randi() % caverns.size()
				var b = rng.randi() % caverns.size()
				
				if a != b:
					var tunnel_key = str(min(a, b)) + "_" + str(max(a, b))
					
					# Only create tunnel if it doesn't already exist
					if not created_tunnels.has(tunnel_key):
						create_tunnel(caverns[a], caverns[b])
						created_tunnels[tunnel_key] = true
						break
				
				attempts += 1
	else:
		# Original probabilistic tunnel creation
		for i in range(caverns.size()):
			for j in range(i + 1, caverns.size()):
				# Probabilistically create tunnels
				if rng.randf() < 0.6:  # 60% chance of tunnel
					create_tunnel(caverns[i], caverns[j])

func create_tunnel(start_cavern: CSGSphere3D, end_cavern: CSGSphere3D):
	# Create a tunnel between two caverns
	var tunnel = CSGCylinder3D.new()
	
	# Calculate tunnel parameters
	var start_pos = start_cavern.position
	var end_pos = end_cavern.position
	
	# Tunnel direction and length
	var tunnel_direction = (end_pos - start_pos)
	var tunnel_length = tunnel_direction.length()
	tunnel_direction = tunnel_direction.normalized()
	
	# Set tunnel parameters
	tunnel.height = tunnel_length
	tunnel.radius = rng.randf_range(0.5, 2.0)
	
	# Position tunnel midpoint
	tunnel.position = (start_pos + end_pos) / 2
	
	# Correct rotation to align with tunnel direction
	# Use look_at with a careful up vector selection
	var up_vector = Vector3.UP
	if abs(tunnel_direction.dot(up_vector)) > 0.99:
		up_vector = Vector3.FORWARD
	
	# Create a temporary basis to look at the end position
	var look_basis = Basis()
	look_basis = look_basis.looking_at(end_pos - start_pos, up_vector)
	
	# Apply rotation to align the cylinder
	tunnel.global_transform.basis = look_basis.rotated(Vector3.RIGHT, PI/2)
	
	# Add some randomness to tunnel path
	add_tunnel_variations(tunnel)
	
	# Add to scene
	cave_root.add_child(tunnel)
	
	# Optional: store connection data
	if not tunnel.has_meta("connected_caverns"):
		tunnel.set_meta("connected_caverns", [start_cavern, end_cavern])

func add_tunnel_variations(tunnel: CSGCylinder3D):
	# Add some organic variation to the tunnel
	for i in range(rng.randi_range(2, 5)):
		var variation_sphere = CSGSphere3D.new()
		
		# Randomize variation sphere
		variation_sphere.radius = tunnel.radius * rng.randf_range(0.5, 1.5)
		
		# Position variation along tunnel
		variation_sphere.position = Vector3(
			rng.randf_range(-tunnel.radius/2, tunnel.radius/2),
			rng.randf_range(-tunnel.height/4, tunnel.height/4),
			rng.randf_range(-tunnel.radius/2, tunnel.radius/2)
		)
		
		# Use subtraction to create more organic tunnel shape
		variation_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
		
		# Add variation to tunnel
		tunnel.add_child(variation_sphere)

func add_cave_details():
	# Add some additional details to make the cave more interesting
	
	# Create some rock formations
	for i in range(rng.randi_range(10, 30)):
		var rock = CSGBox3D.new()
		
		# Randomize rock size and position
		rock.size = Vector3(
			rng.randf_range(0.5, 2.0),
			rng.randf_range(0.5, 2.0),
			rng.randf_range(0.5, 2.0)
		)
		
		rock.position = Vector3(
			rng.randf_range(-cave_size.x/2, cave_size.x/2),
			rng.randf_range(-cave_size.y/2, cave_size.y/2),
			rng.randf_range(-cave_size.z/2, cave_size.z/2)
		)
		
		# Add some rotation
		rock.rotation = Vector3(
			rng.randf_range(0, 2*PI),
			rng.randf_range(0, 2*PI),
			rng.randf_range(0, 2*PI)
		)
		
		cave_root.add_child(rock)
	
	# Add some stalactites and stalagmites
	add_stalactites_stalagmites()

func add_stalactites_stalagmites():
	# Number of formations to create
	var num_formations = rng.randi_range(15, 30)
	
	for i in range(num_formations):
		# Decide whether to create a stalactite (ceiling) or stalagmite (floor)
		var is_stalactite = rng.randf() < 0.5
		
		# Create the formation
		var formation = CSGCylinder3D.new()
		
		# Set size parameters
		var height = rng.randf_range(1.0, 3.0)
		var top_radius = is_stalactite if rng.randf_range(0.2, 0.5) else 0.05
		var bottom_radius = is_stalactite if 0.05 else rng.randf_range(0.2, 0.5)
		
		formation.height = height
		formation.radius = top_radius
		#formation.bottom_radius = bottom_radius
		formation.cone = true
		
		# Position the formation
		formation.position = Vector3(
			rng.randf_range(-cave_size.x/2, cave_size.x/2),
			is_stalactite if cave_size.y/2 - height/2 else -cave_size.y/2 + height/2,
			rng.randf_range(-cave_size.z/2, cave_size.z/2)
		)
		
		# Add slight random rotation for natural look
		formation.rotation = Vector3(
			0,
			rng.randf_range(0, 2*PI),
			is_stalactite if 0 else PI  # Flip stalagmites
		)
		
		cave_root.add_child(formation)

func generate_cave_texture() -> ImageTexture:
	# Create a procedural texture with noise
	var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	
	# Generate noise-based texture
	for y in range(256):
		for x in range(256):
			# Generate noise value
			var noise_val = (noise.get_noise_2d(x, y) + 1) / 2.0  # Normalize to 0-1
			
			# Create color variation based on noise
			var base_color = Color(0.4, 0.35, 0.3)  # Base rock color
			var variation_color = Color(
				base_color.r + rng.randf_range(-color_variation, color_variation),
				base_color.g + rng.randf_range(-color_variation, color_variation),
				base_color.b + rng.randf_range(-color_variation, color_variation),
				1.0
			)
			
			# Interpolate between base and variation colors
			var final_color = base_color.lerp(variation_color, noise_val)
			
			# Set pixel color
			image.set_pixel(x, y, final_color)
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	return texture

func apply_cave_textures():
	# Generate a unique texture
	var cave_texture = generate_cave_texture()
	
	# Create a material with the texture and bump mapping
	var cave_material = StandardMaterial3D.new()
	cave_material.albedo_texture = cave_texture
	
	# Add some roughness and metallic properties
	cave_material.roughness = 0.8
	cave_material.metallic = 0.1
	
	# Add normal (bump) map based on noise
	var normal_map = generate_normal_map(cave_texture)
	cave_material.normal_enabled = true
	cave_material.normal_texture = normal_map
	cave_material.normal_scale = 0.5
	
	# Apply material recursively to all CSG shapes
	apply_material_recursive(cave_root, cave_material)

func generate_normal_map(base_texture: ImageTexture) -> ImageTexture:
	# Get image from texture
	var base_image = base_texture.get_image()
	var normal_image = Image.create(base_image.get_width(), base_image.get_height(), false, Image.FORMAT_RGBA8)
	
	# Generate normal map based on height variations
	for y in range(1, base_image.get_height() - 1):
		for x in range(1, base_image.get_width() - 1):
			# Sample neighboring pixels
			var height_left = base_image.get_pixel(x-1, y).r
			var height_right = base_image.get_pixel(x+1, y).r
			var height_up = base_image.get_pixel(x, y-1).r
			var height_down = base_image.get_pixel(x, y+1).r
			
			# Calculate normal vector
			var normal_vector = Vector3(
				height_left - height_right,
				height_up - height_down,
				1.0  # Adjust this for more or less pronounced bumps
			).normalized()
			
			# Convert normal to color
			var normal_color = Color(
				(normal_vector.x + 1) / 2.0,
				(normal_vector.y + 1) / 2.0,
				(normal_vector.z + 1) / 2.0,
				1.0
			)
			
			normal_image.set_pixel(x, y, normal_color)
	
	# Create texture from image
	var normal_texture = ImageTexture.create_from_image(normal_image)
	return normal_texture

func apply_material_recursive(node: Node, material: Material):
	if node is CSGShape3D:
		node.material_override = material
	
	for child in node.get_children():
		apply_material_recursive(child, material)

# Check if the cave system is fully connected
func is_cave_system_connected() -> bool:
	var caverns = []
	var tunnels = []
	
	# Find all caverns and tunnels
	for child in cave_root.get_children():
		if child is CSGSphere3D:
			caverns.append(child)
		elif child is CSGCylinder3D:
			tunnels.append(child)
	
	# If there are no caverns, consider it connected
	if caverns.size() <= 1:
		return true
	
	# Build adjacency list
	var adjacency_list = {}
	for i in range(caverns.size()):
		adjacency_list[i] = []
	
	# For each tunnel, find the caverns it connects
	for tunnel in tunnels:
		if tunnel.has_meta("connected_caverns"):
			var connected = tunnel.get_meta("connected_caverns")
			var idx1 = caverns.find(connected[0])
			var idx2 = caverns.find(connected[1])
			
			if idx1 >= 0 and idx2 >= 0:
				adjacency_list[idx1].append(idx2)
				adjacency_list[idx2].append(idx1)
		else:
			# Fallback: find caverns by proximity
			for i in range(caverns.size()):
				for j in range(i + 1, caverns.size()):
					# Check if tunnel is between these caverns
					var tunnel_midpoint = tunnel.position
					var cavern_midpoint = (caverns[i].position + caverns[j].position) / 2
					
					if tunnel_midpoint.distance_to(cavern_midpoint) < 1.0:
						adjacency_list[i].append(j)
						adjacency_list[j].append(i)
	
	# Perform BFS to check connectivity
	var visited = []
	visited.resize(caverns.size())
	for i in range(caverns.size()):
		visited[i] = false
	
	var queue = [0]  # Start BFS from first cavern
	visited[0] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		for neighbor in adjacency_list[current]:
			if not visited[neighbor]:
				visited[neighbor] = true
				queue.append(neighbor)
	
	# Check if all caverns were visited
	for v in visited:
		if not v:
			return false
	
	return true

# Optional method to regenerate the entire cave system
func regenerate_cave():
	# Clear existing children
	for child in cave_root.get_children():
		child.queue_free()
	
	# Regenerate cave system
	generate_cave_system()
	
	# Verify connectivity
	if ensure_full_connectivity and not is_cave_system_connected():
		print("Warning: Cave system is not fully connected! Regenerating...")
		regenerate_cave()  # Try again if not connected
