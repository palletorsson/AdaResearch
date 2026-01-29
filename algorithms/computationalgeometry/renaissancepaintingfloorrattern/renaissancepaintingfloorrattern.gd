extends Node3D

# Renaissance Painting Floor Pattern Recreation
# Creates the geometric diamond and square pattern seen in the painting

func _ready():
	create_renaissance_floor()

func create_renaissance_floor():
	"""Create the complex geometric floor pattern from the Renaissance painting"""
	
	# Floor parameters
	var floor_width = 24
	var floor_height = 16
	var base_tile_size = 1.0
	var tile_thickness = 0.08
	
	# Create floor container
	var floor_container = Node3D.new()
	floor_container.name = "RenaissanceFloor"
	add_child(floor_container)
	
	# Create materials for different pattern elements
	var dark_brown = create_dark_brown_material()
	var light_brown = create_light_brown_material()
	var cream_stone = create_cream_stone_material()
	var red_terracotta = create_red_terracotta_material()
	
	# Create the base checkerboard pattern
	create_base_checkerboard(floor_container, floor_width, floor_height, base_tile_size, tile_thickness, dark_brown, light_brown)
	
	# Add diamond pattern overlay
	create_diamond_pattern(floor_container, floor_width, floor_height, base_tile_size, tile_thickness, cream_stone, red_terracotta)
	
	# Add decorative border strips
	create_decorative_borders(floor_container, floor_width, floor_height, base_tile_size, tile_thickness)
	
	# Add perspective effect elements
	create_perspective_elements(floor_container, floor_width, floor_height, base_tile_size, tile_thickness)

func create_base_checkerboard(parent: Node3D, width: int, height: int, tile_size: float, thickness: float, dark_mat: Material, light_mat: Material):
	"""Create the base alternating checkerboard pattern"""
	
	var base_container = Node3D.new()
	base_container.name = "BaseCheckerboard"
	parent.add_child(base_container)
	
	for x in range(width):
		for z in range(height):
			var tile = create_floor_tile(tile_size, thickness)
			
			# Position the tile
			tile.position = Vector3(
				(x - width * 0.5) * tile_size + tile_size * 0.5,
				0,
				(z - height * 0.5) * tile_size + tile_size * 0.5
			)
			
			# Apply alternating pattern
			var is_dark = (x + z) % 2 == 0
			if is_dark:
				tile.material_override = dark_mat
				tile.name = "DarkTile_" + str(x) + "_" + str(z)
			else:
				tile.material_override = light_mat
				tile.name = "LightTile_" + str(x) + "_" + str(z)
			
			base_container.add_child(tile)

func create_diamond_pattern(parent: Node3D, width: int, height: int, tile_size: float, thickness: float, cream_mat: Material, red_mat: Material):
	"""Create diamond-shaped decorative elements"""
	
	var diamond_container = Node3D.new()
	diamond_container.name = "DiamondPattern"
	parent.add_child(diamond_container)
	
	# Create diamond tiles at regular intervals
	var diamond_spacing = 4
	
	for x in range(0, width, diamond_spacing):
		for z in range(0, height, diamond_spacing):
			if x >= 2 and x < width - 2 and z >= 2 and z < height - 2:
				var diamond_group = create_diamond_group(tile_size, thickness, cream_mat, red_mat)
				
				diamond_group.position = Vector3(
					(x - width * 0.5) * tile_size + tile_size * 0.5,
					thickness * 0.5,
					(z - height * 0.5) * tile_size + tile_size * 0.5
				)
				
				diamond_container.add_child(diamond_group)

func create_diamond_group(tile_size: float, thickness: float, cream_mat: Material, red_mat: Material) -> Node3D:
	"""Create a group of diamond-shaped tiles"""
	
	var diamond_group = Node3D.new()
	
	# Central diamond
	var center_diamond = create_diamond_tile(tile_size * 0.6, thickness * 1.2)
	center_diamond.material_override = cream_mat
	center_diamond.position.y = thickness * 0.1
	diamond_group.add_child(center_diamond)
	
	# Small corner accents
	var corner_positions = [
		Vector3(tile_size * 0.4, thickness * 0.15, tile_size * 0.4),
		Vector3(-tile_size * 0.4, thickness * 0.15, tile_size * 0.4),
		Vector3(tile_size * 0.4, thickness * 0.15, -tile_size * 0.4),
		Vector3(-tile_size * 0.4, thickness * 0.15, -tile_size * 0.4)
	]
	
	for pos in corner_positions:
		var corner_accent = create_diamond_tile(tile_size * 0.2, thickness * 0.8)
		corner_accent.material_override = red_mat
		corner_accent.position = pos
		diamond_group.add_child(corner_accent)
	
	return diamond_group

func create_diamond_tile(size: float, thickness: float) -> MeshInstance3D:
	"""Create a diamond-shaped tile using rotated cube"""
	
	var diamond_mesh = BoxMesh.new()
	diamond_mesh.size = Vector3(size, thickness, size)
	
	var diamond_instance = MeshInstance3D.new()
	diamond_instance.mesh = diamond_mesh
	diamond_instance.rotation.y = PI * 0.25  # 45 degree rotation for diamond shape
	
	return diamond_instance

func create_decorative_borders(parent: Node3D, width: int, height: int, tile_size: float, thickness: float):
	"""Create decorative border strips"""
	
	var border_container = Node3D.new()
	border_container.name = "DecorativeBorders"
	parent.add_child(border_container)
	
	var border_material = create_ornate_border_material()
	var border_width = tile_size * 0.3
	var border_height = thickness * 1.5
	
	# Create border strips with alternating pattern
	for i in range(4):
		var border_strip = create_border_strip(width, height, tile_size, border_width, border_height)
		border_strip.material_override = border_material
		
		match i:
			0: # Top border
				border_strip.position = Vector3(0, border_height * 0.5, height * tile_size * 0.5 + border_width * 0.5)
			1: # Bottom border  
				border_strip.position = Vector3(0, border_height * 0.5, -height * tile_size * 0.5 - border_width * 0.5)
			2: # Left border
				border_strip.position = Vector3(-width * tile_size * 0.5 - border_width * 0.5, border_height * 0.5, 0)
				border_strip.rotation.y = PI * 0.5
			3: # Right border
				border_strip.position = Vector3(width * tile_size * 0.5 + border_width * 0.5, border_height * 0.5, 0)
				border_strip.rotation.y = PI * 0.5
		
		border_container.add_child(border_strip)

func create_border_strip(width: int, height: int, tile_size: float, border_width: float, border_height: float) -> MeshInstance3D:
	"""Create a decorative border strip"""
	
	var length = max(width, height) * tile_size
	var strip_mesh = BoxMesh.new()
	strip_mesh.size = Vector3(length, border_height, border_width)
	
	var strip_instance = MeshInstance3D.new()
	strip_instance.mesh = strip_mesh
	
	return strip_instance

func create_perspective_elements(parent: Node3D, width: int, height: int, tile_size: float, thickness: float):
	"""Add elements that enhance the perspective effect"""
	
	var perspective_container = Node3D.new()
	perspective_container.name = "PerspectiveElements"
	parent.add_child(perspective_container)
	
	# Create subtle raised lines that follow the perspective
	var line_material = create_perspective_line_material()
	
	# Horizontal perspective lines
	for z in range(0, height, 2):
		var line = create_perspective_line(width * tile_size, 0.02, thickness * 0.5)
		line.material_override = line_material
		line.position = Vector3(0, thickness * 0.6, (z - height * 0.5) * tile_size)
		perspective_container.add_child(line)
	
	# Vertical perspective lines  
	for x in range(0, width, 2):
		var line = create_perspective_line(height * tile_size, 0.02, thickness * 0.5)
		line.material_override = line_material
		line.position = Vector3((x - width * 0.5) * tile_size, thickness * 0.6, 0)
		line.rotation.y = PI * 0.5
		perspective_container.add_child(line)

func create_perspective_line(length: float, width: float, height: float) -> MeshInstance3D:
	"""Create a thin line for perspective effect"""
	
	var line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(length, height, width)
	
	var line_instance = MeshInstance3D.new()
	line_instance.mesh = line_mesh
	
	return line_instance

func create_floor_tile(size: float, thickness: float) -> MeshInstance3D:
	"""Create a single floor tile with collision"""
	
	var tile_mesh = BoxMesh.new()
	tile_mesh.size = Vector3(size, thickness, size)
	
	var tile_instance = MeshInstance3D.new()
	tile_instance.mesh = tile_mesh
	tile_instance.position.y = thickness * 0.5
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size, thickness, size)
	collision_shape.shape = box_shape
	collision_shape.position.y = thickness * 0.5
	
	static_body.add_child(collision_shape)
	tile_instance.add_child(static_body)
	
	return tile_instance

# Material Creation Functions

func create_dark_brown_material() -> StandardMaterial3D:
	"""Create dark brown stone material"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.18, 0.12, 1.0)  # Rich dark brown
	material.roughness = 0.6
	material.metallic = 0.0
	# material.specular = 0.3  # Godot 3.x parameter not available in Godot 4
	
	# Add slight variation
	material.rim_enabled = true
	material.rim_strength = 0.2
	material.rim_color = Color(0.3, 0.22, 0.15, 1.0)
	
	return material

func create_light_brown_material() -> StandardMaterial3D:
	"""Create light brown stone material"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.35, 0.25, 1.0)  # Warm light brown
	material.roughness = 0.5
	material.metallic = 0.0
	# material.specular = 0.4  # Godot 3.x parameter not available in Godot 4
	
	material.rim_enabled = true
	material.rim_strength = 0.15
	material.rim_color = Color(0.5, 0.4, 0.3, 1.0)
	
	return material

func create_cream_stone_material() -> StandardMaterial3D:
	"""Create cream/beige stone material"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.78, 0.65, 1.0)  # Warm cream
	material.roughness = 0.4
	material.metallic = 0.0
	# material.specular = 0.5  # Godot 3.x parameter not available in Godot 4
	
	material.rim_enabled = true
	material.rim_strength = 0.25
	# rim_color parameter not available in Godot 4 - using emission instead for rim effect
	material.emission_enabled = true
	material.emission = Color(0.9, 0.85, 0.75, 1.0) * 0.1
	
	return material

func create_red_terracotta_material() -> StandardMaterial3D:
	"""Create red terracotta material"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.65, 0.3, 0.2, 1.0)  # Deep terracotta red
	material.roughness = 0.7
	material.metallic = 0.0
	# specular parameter removed - not available in Godot 4
	
	material.rim_enabled = true
	material.rim_strength = 0.3
	material.rim_color = Color(0.7, 0.35, 0.25, 1.0)
	
	return material

func create_ornate_border_material() -> StandardMaterial3D:
	"""Create material for decorative borders"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.6, 0.45, 1.0)  # Golden brown
	material.roughness = 0.3
	material.metallic = 0.1
	# material.specular = 0.7  # Godot 3.x parameter not available in Godot 4
	
	# Add golden highlights
	material.rim_enabled = true
	material.rim_strength = 0.4
	material.rim_color = Color(0.8, 0.7, 0.5, 1.0)
	
	# Slight metallic sheen
	material.clearcoat_enabled = true
	material.clearcoat = 0.2
	material.clearcoat_gloss = 0.8
	
	return material

func create_perspective_line_material() -> StandardMaterial3D:
	"""Create material for perspective guide lines"""
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.25, 0.2, 1.0)  # Dark accent lines
	material.roughness = 0.9
	material.metallic = 0.0
	# material.specular = 0.1  # Godot 3.x parameter not available in Godot 4
	
	return material

# Optional: Add Renaissance-style lighting
func setup_renaissance_lighting():
	"""Setup warm, painterly lighting"""
	
	# Main light (window light)
	var main_light = DirectionalLight3D.new()
	main_light.name = "WindowLight"
	main_light.light_energy = 0.9
	main_light.light_color = Color(1.0, 0.9, 0.7)  # Warm golden light
	main_light.position = Vector3(-5, 8, 5)
	main_light.rotation_degrees = Vector3(-35, 35, 0)
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Ambient fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "AmbientFill"
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.7, 0.8, 0.9)  # Cool ambient
	fill_light.rotation_degrees = Vector3(-120, -30, 0)
	add_child(fill_light)
	
	# Accent lighting for depth
	var accent_light = OmniLight3D.new()
	accent_light.light_energy = 0.6
	accent_light.light_color = Color(1.0, 0.85, 0.6)
	accent_light.omni_range = 20.0
	accent_light.position = Vector3(0, 6, 0)
	add_child(accent_light)
