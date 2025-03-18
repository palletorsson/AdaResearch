extends Node3D

# Configuration
@export_category("Installation Configuration")
@export var room_width: float = 12.0
@export var room_length: float = 18.0
@export var room_height: float = 5.0
@export var panels_count: int = 6
@export var generate_on_ready: bool = true

# Array of vibrant colors for panels
var panel_colors = [
	Color(1.0, 0.0, 0.0, 0.5),  # Red
	Color(0.0, 0.0, 1.0, 0.5),  # Blue
	Color(1.0, 1.0, 0.0, 0.5),  # Yellow
	Color(0.0, 1.0, 0.0, 0.5),  # Green
	Color(1.0, 0.0, 1.0, 0.5),  # Magenta
	Color(0.0, 1.0, 1.0, 0.5),  # Cyan
	Color(1.0, 0.5, 0.0, 0.5),  # Orange
	Color(0.5, 0.0, 1.0, 0.5)   # Purple
]

func _ready():
	if generate_on_ready:
		create_installation()

func create_installation():
	# Create the room (floor, ceiling, walls)
	create_room()
	
	# Create the transparent colored panels
	create_panels()
	
	# Add lighting
	setup_lighting()


func create_room():
	# Create floor
	var floor = create_floor()
	add_child(floor)
	
	# Create ceiling
	var ceiling = create_ceiling()
	add_child(ceiling)
	
	# Create walls
	var walls = create_walls()
	add_child(walls)

func create_floor():
	var floor_node = Node3D.new()
	floor_node.name = "Floor"
	
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "FloorMesh"
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(room_width, room_length)
	floor_mesh.mesh = plane_mesh
	
	# Create material for floor
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.9)
	material.roughness = 0.2
	floor_mesh.material_override = material
	
	floor_node.add_child(floor_mesh)
	return floor_node

func create_ceiling():
	var ceiling_node = Node3D.new()
	ceiling_node.name = "Ceiling"
	
	var ceiling_mesh = MeshInstance3D.new()
	ceiling_mesh.name = "CeilingMesh"
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(room_width, room_length)
	ceiling_mesh.mesh = plane_mesh
	
	# Position and rotate the ceiling
	ceiling_mesh.position = Vector3(0, room_height, 0)
	ceiling_mesh.rotation_degrees = Vector3(180, 0, 0)
	
	# Create material for ceiling
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.9)
	material.roughness = 0.2
	ceiling_mesh.material_override = material
	
	ceiling_node.add_child(ceiling_mesh)
	return ceiling_node

func create_walls():
	var walls_node = Node3D.new()
	walls_node.name = "Walls"
	
	# Create four walls
	for i in range(4):
		var wall = MeshInstance3D.new()
		wall.name = "Wall_" + str(i)
		
		var plane_mesh = PlaneMesh.new()
		
		if i % 2 == 0:
			# Front and back walls
			plane_mesh.size = Vector2(room_width, room_height)
			wall.position = Vector3(0, room_height / 2, (i - 1) * room_length / 2)
			if i == 0:
				wall.rotation_degrees = Vector3(90, 0, 0)
			else:
				wall.rotation_degrees = Vector3(-90, 0, 0)
		else:
			# Left and right walls
			plane_mesh.size = Vector2(room_length, room_height)
			wall.position = Vector3((i - 2) * room_width / 2, room_height / 2, 0)
			if i == 1:
				wall.rotation_degrees = Vector3(0, 0, 90)
				wall.rotation_degrees.y = -90
			else:
				wall.rotation_degrees = Vector3(0, 0, -90)
				wall.rotation_degrees.y = 90
		
		wall.mesh = plane_mesh
		
		# Create material for wall
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.95, 0.95, 0.95)
		material.roughness = 0.5
		wall.material_override = material
		
		walls_node.add_child(wall)
	
	return walls_node

func create_panels():
	var panels_node = Node3D.new()
	panels_node.name = "ColoredPanels"
	
	# Calculate spacing for panels
	var spacing = room_width / (panels_count + 1)
	
	# Create parallel vertical panels
	for i in range(panels_count):
		var color_index = i % panel_colors.size()
		
		# Create panel with alternating orientation
		if i % 2 == 0:
			# Length-oriented panel
			var panel = create_transparent_panel(
				Vector2(room_length * 0.8, room_height * 0.9),
				panel_colors[color_index]
			)
			panel.position = Vector3(
				(-room_width / 2) + spacing * (i + 1),
				room_height / 2,
				0
			)
			panel.rotation_degrees.y = 90
			panels_node.add_child(panel)
		else:
			# Width-oriented panel
			var panel = create_transparent_panel(
				Vector2(room_width * 0.7, room_height * 0.9),
				panel_colors[color_index]
			)
			panel.position = Vector3(
				0,
				room_height / 2,
				(-room_length / 2) + spacing * (i + 1)
			)
			panels_node.add_child(panel)
	
	# Create some intersecting panels
	for i in range(3):
		var color_index = (i + panels_count) % panel_colors.size()
		var panel = create_transparent_panel(
			Vector2(room_width * 0.6, room_height * 0.8),
			panel_colors[color_index]
		)
		
		# Position at different points
		var x_pos = sin(i * PI / 3) * room_width * 0.3
		var z_pos = cos(i * PI / 3) * room_length * 0.3
		
		panel.position = Vector3(x_pos, room_height / 2, z_pos)
		panel.rotation_degrees.y = 45 + i * 30
		
		panels_node.add_child(panel)
	
	add_child(panels_node)

func create_transparent_panel(size, color):
	var panel = MeshInstance3D.new()
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	panel.mesh = plane_mesh
	
	# Create transparent colored material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.0
	material.metallic = 0.1
	material.metallic_specular = 1.0
	
	# Enable transparency
	material.flags_transparent = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	
	panel.material_override = material
	
	return panel

func setup_lighting():
	# Create overall ambient light
	var ambient_light = WorldEnvironment.new()
	ambient_light.name = "WorldEnvironment"
	
	var env = Environment.new()
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 0.5
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.8, 0.8, 0.8)
	
	# Add bloom effect for the glowing colors
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	#env.glow_blend_mode = Environment.GLOW_BLEND_ADDITIVE
	
	ambient_light.environment = env
	add_child(ambient_light)
	
	# Add main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.name = "MainLight"
	dir_light.position = Vector3(0, room_height * 1.5, room_length)
	dir_light.light_color = Color(1.0, 1.0, 1.0)
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	dir_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	add_child(dir_light)
	
	# Add spotlights directed at panels for enhanced effect
	add_spotlights()

func add_spotlights():
	var spotlights_node = Node3D.new()
	spotlights_node.name = "Spotlights"
	
	for i in range(4):
		var spot = SpotLight3D.new()
		spot.name = "Spotlight_" + str(i)
		
		# Position spotlights at corners of the room pointing inward
		var x_pos = (i % 2 * 2 - 1) * room_width * 0.4
		var z_pos = (i / 2 * 2 - 1) * room_length * 0.4
		
		spot.position = Vector3(x_pos, room_height * 0.9, z_pos)
		spot.look_at(Vector3(0, room_height * 0.5, 0), Vector3.UP)
		
		# Light properties
		spot.light_color = Color(1.0, 1.0, 1.0)
		spot.light_energy = 2.0
		spot.spot_range = room_width
		spot.spot_angle = 30.0
		spot.shadow_enabled = true
		
		spotlights_node.add_child(spot)
	
	add_child(spotlights_node)



# Add some walking figures to simulate people in the installation
func add_people():
	var people_node = Node3D.new()
	people_node.name = "People"
	
	for i in range(5):
		var person = create_simple_person()
		
		# Random position within the installation
		var x_pos = randf_range(-room_width * 0.4, room_width * 0.4)
		var z_pos = randf_range(-room_length * 0.4, room_length * 0.4)
		
		person.position = Vector3(x_pos, 0, z_pos)
		person.rotation_degrees.y = randf_range(0, 360)
		
		people_node.add_child(person)
	
	add_child(people_node)

func create_simple_person():
	var person = Node3D.new()
	
	# Create simple body shape
	var body = MeshInstance3D.new()
	body.name = "Body"
	
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.25
	capsule.height = 1.8
	body.mesh = capsule
	
	body.position.y = 0.9
	
	# Create material for body
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.2)
	body.material_override = material
	
	person.add_child(body)
	
	# Add head
	var head = MeshInstance3D.new()
	head.name = "Head"
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	head.mesh = sphere
	
	head.position.y = 1.9
	
	# Create material for head
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.6, 0.4, 0.3)
	head.material_override = head_material
	
	person.add_child(head)
	
	return person

# Custom shader for enhanced color blending effects
func create_color_blend_shader():
	var shader_material = ShaderMaterial.new()
	
	var shader_code = """
	shader_type spatial;
	render_mode blend_add, depth_draw_always, cull_disabled, diffuse_lambert, specular_schlick_ggx;
	
	uniform vec4 albedo : source_color;
	uniform float roughness : hint_range(0.0, 1.0);
	uniform float metallic : hint_range(0.0, 1.0);
	uniform float specular : hint_range(0.0, 1.0);
	
	void fragment() {
		ALBEDO = albedo.rgb;
		ALPHA = albedo.a;
		ROUGHNESS = roughness;
		METALLIC = metallic;
		SPECULAR = specular;
		
		// Add refraction effect
		EMISSION = albedo.rgb * 0.2;
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	shader_material.shader = shader
	
	return shader_material
