extends Node3D

# Ten Tulip Buckets Generator
# Creates 10 instances of the bucket of tulips scene

@export var bucket_spacing: float = 3.0
@export var grid_size: int = 5  # 5x2 grid for 10 buckets
@export var randomize_colors: bool = true
@export var randomize_positions: bool = true

var bucket_scenes = []
var bucket_instances = []

func _ready():
	randomize()
	
	# Set up visual environment
	setup_environment()
	
	# Create 10 tulip buckets
	create_ten_buckets()
	
	# Add camera controls
	setup_camera_controls()

func setup_environment():
	# Create enhanced lighting
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(5, 8, 5)
	main_light.look_at_from_position(main_light.position, Vector3(0, 0, 0), Vector3.UP)
	main_light.light_energy = 1.2
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Add rim lighting
	var rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.position = Vector3(-3, 2, -3)
	rim_light.look_at_from_position(rim_light.position, Vector3(0, 0, 0), Vector3.UP)
	rim_light.light_energy = 0.6
	rim_light.light_color = Color(0.8, 0.9, 1.0)
	add_child(rim_light)
	
	# Add fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(0, 3, 4)
	fill_light.look_at_from_position(fill_light.position, Vector3(0, 0, 0), Vector3.UP)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(1.0, 0.95, 0.9)
	add_child(fill_light)
	
	# Create environment
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = create_sky()
	environment.ambient_light_color = Color(0.2, 0.25, 0.3)
	environment.ambient_light_energy = 0.3
	
	var world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

func create_sky() -> Sky:
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.4, 0.6, 0.8)
	sky_material.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky_material.ground_horizon_color = Color(0.6, 0.7, 0.8)
	sky_material.ground_bottom_color = Color(0.4, 0.5, 0.6)
	sky.sky_material = sky_material
	return sky

func create_ten_buckets():
	# Load the bucket of tulips scene
	var bucket_scene = preload("res://algorithms/computationalbiology/bucketoftulips/bucket_of_tulips.tscn")
	
	# Calculate grid positions
	var start_pos = Vector3(-bucket_spacing * (grid_size - 1) / 2, 0, -bucket_spacing * 0.5)
	
	# Create 10 buckets in a 5x2 grid
	for i in range(10):
		var bucket_instance = bucket_scene.instantiate()
		bucket_instance.name = "TulipBucket_" + str(i)
		
		# Calculate position
		var row = i / 5
		var col = i % 5
		var position = start_pos + Vector3(col * bucket_spacing, 0, row * bucket_spacing)
		
		# Add random variation to position if enabled
		if randomize_positions:
			position.x += (randf() - 0.5) * 0.5
			position.z += (randf() - 0.5) * 0.5
			position.y += (randf() - 0.5) * 0.1
		
		bucket_instance.position = position
		
		# Randomize bucket properties
		randomize_bucket_properties(bucket_instance, i)
		
		# Add to scene
		add_child(bucket_instance)
		bucket_instances.append(bucket_instance)

func randomize_bucket_properties(bucket_instance, index):
	# Randomize scale slightly
	var scale_factor = 0.8 + randf() * 0.4  # 0.8 to 1.2
	bucket_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Randomize rotation
	var rotation_y = randf() * 360
	bucket_instance.rotation_degrees = Vector3(0, rotation_y, 0)
	
	# Randomize tulip count in each bucket
	var tulip_script = bucket_instance.get_script()
	if tulip_script:
		# Access the tulip_count property if it exists
		if bucket_instance.has_method("set") and bucket_instance.has_method("get"):
			var current_count = bucket_instance.get("tulip_count")
			if current_count != null:
				var new_count = 10 + randi() % 11  # 10 to 20 tulips
				bucket_instance.set("tulip_count", new_count)
	
	# Randomize colors if enabled
	if randomize_colors:
		randomize_bucket_colors(bucket_instance)

func randomize_bucket_colors(bucket_instance):
	# Find and randomize bucket material
	var bucket_mesh = bucket_instance.get_node_or_null("FlowerBucket")
	if bucket_mesh and bucket_mesh.material_override:
		var material = bucket_mesh.material_override.duplicate()
		# Randomize bucket color
		var bucket_colors = [
			Color(0.2, 0.2, 0.2),  # Dark gray
			Color(0.3, 0.2, 0.1),  # Brown
			Color(0.1, 0.3, 0.1),  # Dark green
			Color(0.2, 0.1, 0.3),  # Dark blue
			Color(0.3, 0.1, 0.1),  # Dark red
		]
		material.albedo_color = bucket_colors[randi() % bucket_colors.size()]
		bucket_mesh.material_override = material
	
	# Find and randomize handle material
	var handle = bucket_instance.get_node_or_null("FlowerBucket/BucketHandle")
	if handle and handle.material_override:
		var material = handle.material_override.duplicate()
		material.albedo_color = Color(0.1, 0.1, 0.1)  # Very dark for handle
		handle.material_override = material

func setup_camera_controls():
	# Create camera controller
	var camera_controller = Node3D.new()
	camera_controller.name = "CameraController"
	camera_controller.position = Vector3(0, 5, 8)
	add_child(camera_controller)
	
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 60.0
	camera.near = 0.1
	camera.far = 100.0
	camera_controller.add_child(camera)
	
	# Add UI
	setup_ui()

func setup_ui():
	# Create UI canvas
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UI"
	add_child(ui_canvas)
	
	# Create info panel
	var info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(300, 150)
	ui_canvas.add_child(info_panel)
	
	# Create info label
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector2(10, 10)
	info_label.size = Vector2(280, 130)
	info_label.text = "Ten Tulip Buckets\n\n10 beautiful tulip arrangements\nEach with unique colors and variations\nUse mouse to look around"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_panel.add_child(info_label)
	
	# Create control panel
	var control_panel = Panel.new()
	control_panel.name = "ControlPanel"
	control_panel.position = Vector2(10, 170)
	control_panel.size = Vector2(300, 100)
	ui_canvas.add_child(control_panel)
	
	# Add control buttons
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 80)
	control_panel.add_child(vbox)
	
	# Regenerate button
	var regen_button = Button.new()
	regen_button.text = "Regenerate Buckets"
	regen_button.pressed.connect(_on_regenerate_pressed)
	vbox.add_child(regen_button)
	
	# Toggle randomization button
	var random_button = Button.new()
	random_button.text = "Toggle Randomization"
	random_button.pressed.connect(_on_toggle_randomization_pressed)
	vbox.add_child(random_button)

func _on_regenerate_pressed():
	# Clear existing buckets
	for bucket in bucket_instances:
		if bucket and is_instance_valid(bucket):
			bucket.queue_free()
	bucket_instances.clear()
	
	# Create new buckets
	create_ten_buckets()

func _on_toggle_randomization_pressed():
	randomize_positions = !randomize_positions
	randomize_colors = !randomize_colors
	
	# Regenerate with new settings
	_on_regenerate_pressed()

func _input(event):
	# Handle keyboard input
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_on_regenerate_pressed()
			KEY_SPACE:
				_on_toggle_randomization_pressed()
