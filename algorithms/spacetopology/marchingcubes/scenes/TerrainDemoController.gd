# TerrainDemoController.gd
# Controls the walkable terrain demo
# Provides UI and camera controls for testing marching cubes terrain

extends Node3D

# UI elements
var generate_button: Button
var progress_bar: ProgressBar
var stats_text: RichTextLabel
var size_slider: HSlider
var height_slider: HSlider
var noise_slider: HSlider

# Camera system
var camera: Camera3D
var camera_rotation: Vector3 = Vector3.ZERO
var camera_target = Vector3.ZERO
var is_mouse_captured = false

# VR Navigation
var vr_camera: XRCamera3D
var vr_controllers: Array[XRController3D] = []

# Terrain generation
var terrain_generator: TerrainGenerator

# Parameters
var terrain_size: float = 50.0
var terrain_height: float = 5.0
var noise_frequency: float = 0.05

func _ready():
	setup_ui()
	setup_terrain_generator()
	setup_camera()
	setup_vr_navigation()
	
	# Generate initial terrain
	call_deferred("generate_terrain_async")

func setup_ui():
	"""Initialize UI elements"""
	# Get UI references
	generate_button = $UI/Panel/VBoxContainer/Controls/GenerateButton
	progress_bar = $UI/Panel/VBoxContainer/ProgressBar
	stats_text = $UI/Panel/VBoxContainer/StatsText
	size_slider = $UI/Panel/VBoxContainer/Parameters/SizeSlider
	height_slider = $UI/Panel/VBoxContainer/Parameters/HeightSlider
	noise_slider = $UI/Panel/VBoxContainer/Parameters/NoiseSlider
	
	# Setup initial state
	progress_bar.visible = false
	
	print("TerrainDemo: UI initialized")

func setup_terrain_generator():
	"""Initialize terrain generation system"""
	terrain_generator = TerrainGenerator.new()
	terrain_generator.generation_progress.connect(_on_generation_progress)
	terrain_generator.generation_complete.connect(_on_generation_complete)
	
	# Configure initial parameters
	update_terrain_parameters()
	
	print("TerrainDemo: Terrain generator initialized")

func setup_camera():
	"""Setup camera system"""
	camera = $Camera3D
	vr_camera = find_child("XRCamera3D") as XRCamera3D
	
	# Mouse capture for camera control
	if not vr_camera:
		print("TerrainDemo: Desktop camera controls enabled")

func setup_vr_navigation():
	"""Setup VR teleportation system"""
	# Find VR components if they exist
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		for child in xr_origin.get_children():
			if child is XRController3D:
				vr_controllers.append(child as XRController3D)
				setup_controller_teleport(child as XRController3D)
	
	print("TerrainDemo: Found %d VR controllers" % vr_controllers.size())

func setup_controller_teleport(controller: XRController3D):
	"""Setup teleportation for a VR controller"""
	# Create teleport ray
	var teleport_ray = RayCast3D.new()
	teleport_ray.name = "TeleportRay"
	teleport_ray.target_position = Vector3(0, 0, -10)
	teleport_ray.collision_mask = 4  # VR navigation layer
	teleport_ray.enabled = true
	controller.add_child(teleport_ray)
	
	# Create teleport preview marker
	var teleport_marker = MeshInstance3D.new()
	teleport_marker.name = "TeleportPreview"
	teleport_marker.mesh = create_teleport_preview_mesh()
	teleport_marker.visible = false
	
	# Glowing material for teleport preview
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.emission_enabled = true
	material.emission = Color.GREEN
	material.emission_energy = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	teleport_marker.set_surface_override_material(0, material)
	
	get_tree().current_scene.add_child(teleport_marker)
	
	# Connect controller signals
	controller.button_pressed.connect(_on_vr_button_pressed.bind(controller, teleport_ray, teleport_marker))
	controller.button_released.connect(_on_vr_button_released.bind(controller, teleport_ray, teleport_marker))

func create_teleport_preview_mesh() -> ArrayMesh:
	"""Create a circular mesh for teleport preview"""
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var radius = 0.8
	var segments = 16
	
	# Center vertex
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	
	# Circle vertices
	for i in range(segments):
		var angle = i * TAU / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, 0.01, z))
		normals.append(Vector3.UP)
	
	# Create triangles
	for i in range(segments):
		var next_i = (i + 1) % segments
		indices.append(0)
		indices.append(i + 1)
		indices.append(next_i + 1)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _input(event):
	"""Handle input events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				is_mouse_captured = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				is_mouse_captured = false
	
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				is_mouse_captured = false

func _process(delta):
	# Update camera if not in VR mode
	if not vr_camera:
		update_camera_movement(delta)
	
	# Update teleport previews
	update_teleport_previews()

func update_camera_movement(delta: float):
	"""Handle non-VR camera movement"""
	if not camera:
		return
	
	# Mouse look
	if is_mouse_captured:
		var mouse_delta = Input.get_last_mouse_velocity() * delta * 0.001
		camera_rotation.y -= mouse_delta.x
		camera_rotation.x -= mouse_delta.y
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		camera.rotation = camera_rotation
	
	# WASD movement
	var input_vector = Vector3.ZERO
	var speed = 15.0 if Input.is_action_pressed("ui_accept") else 8.0
	
	if Input.is_action_pressed("ui_up"):
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.z += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	
	# Vertical movement
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	# Apply movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var movement = camera.transform.basis * input_vector * speed * delta
		camera.position += movement

func update_teleport_previews():
	"""Update teleport preview positions"""
	for controller in vr_controllers:
		var teleport_ray = controller.find_child("TeleportRay") as RayCast3D
		var teleport_marker = get_tree().current_scene.find_child("TeleportPreview") as MeshInstance3D
		
		if teleport_ray != null and teleport_marker != null and teleport_marker.visible:
			if teleport_ray.is_colliding():
				var collision_point = teleport_ray.get_collision_point()
				var collider = teleport_ray.get_collider()
				
				teleport_marker.global_position = collision_point
				
				var material = teleport_marker.get_surface_override_material(0) as StandardMaterial3D
				if collider != null and collider.has_meta("vr_walkable"):
					material.albedo_color = Color.GREEN
					material.emission = Color.GREEN
				else:
					material.albedo_color = Color.RED
					material.emission = Color.RED

func update_terrain_parameters():
	"""Update terrain parameters from UI"""
	var params = {
		"size": Vector2(terrain_size, terrain_size),
		"height": terrain_height,
		"noise_frequency": noise_frequency,
		"threshold": 0.5
	}
	terrain_generator.configure_terrain(params)

func _on_generate_pressed():
	"""Handle generate button press"""
	generate_terrain_async()

func generate_terrain_async():
	"""Generate terrain asynchronously"""
	print("TerrainDemo: Starting terrain generation...")
	
	# Disable UI during generation
	generate_button.disabled = true
	generate_button.text = "Generating..."
	progress_bar.visible = true
	progress_bar.value = 0
	
	# Clear previous terrain
	clear_previous_terrain()
	
	# Update parameters and generate
	update_terrain_parameters()
	var terrain_meshes = await terrain_generator.generate_terrain_async()
	
	# Add terrain to scene
	terrain_generator.add_terrain_to_scene(self)

func clear_previous_terrain():
	"""Clear previously generated terrain"""
	# Remove old terrain
	for child in get_children():
		if child.name.begins_with("TerrainChunk_") or child.name.ends_with("_VR_Collision") or child.name.begins_with("NavTile_"):
			child.queue_free()

func _on_generation_progress(percentage: float):
	"""Update progress bar during generation"""
	progress_bar.value = percentage
	
	var status = ""
	if percentage <= 25:
		status = "🏗️ Creating voxel grid..."
	elif percentage <= 50:
		status = "🌄 Generating height field..."
	elif percentage <= 75:
		status = "🎨 Creating terrain meshes..."
	else:
		status = "⚡ Building collision..."
	
	stats_text.text = "[color=cyan]🔄 Generating terrain...[/color]\n[color=gray]%s[/color]\n[color=white]Progress: %.0f%%[/color]" % [status, percentage]

func _on_generation_complete():
	"""Handle generation completion"""
	print("TerrainDemo: Generation complete!")
	
	# Re-enable UI
	generate_button.disabled = false
	generate_button.text = "Generate Terrain"
	progress_bar.visible = false
	
	# Update statistics
	update_terrain_statistics()

func update_terrain_statistics():
	"""Update the statistics display"""
	if terrain_generator == null:
		return
	
	var info = terrain_generator.get_terrain_info()
	
	var stats_html = "[color=cyan]Terrain Statistics:[/color]\n"
	stats_html += "• Terrain Size: %.0fx%.0f units\n" % [info.terrain_size.x, info.terrain_size.y]
	stats_html += "• Height Variation: %.1f units\n" % info.height_variation
	stats_html += "• Terrain Chunks: %d\n" % info.terrain_chunks
	stats_html += "• Mesh Instances: %d\n" % info.mesh_instances
	stats_html += "• Collision Bodies: %d\n" % info.collision_bodies
	stats_html += "• Total Vertices: %s\n" % format_number(info.total_vertices)
	stats_html += "• Total Triangles: %s\n" % format_number(info.total_triangles)
	
	# Count VR navigation tiles
	var nav_tile_count = 0
	for child in get_children():
		if child.name.begins_with("NavTile_"):
			nav_tile_count += 1
	
	stats_html += "\n[color=green]VR Navigation:[/color]\n"
	stats_html += "• Walkable Tiles: %d (1x1m)\n" % nav_tile_count
	stats_html += "• VR Controllers: %d\n" % vr_controllers.size()
	
	# Memory estimate
	var memory_mb = (info.total_vertices * 12 + info.total_triangles * 6) / (1024 * 1024)
	stats_html += "\n• Memory Est: %.1f MB" % memory_mb
	
	stats_text.text = stats_html

func format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var formatted = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_num[i] + formatted
		count += 1
	
	return formatted

# Slider event handlers
func _on_size_changed(value: float):
	terrain_size = value
	var size_label = $UI/Panel/VBoxContainer/Parameters/SizeLabel
	size_label.text = "Terrain Size: %.0f units" % value

func _on_height_changed(value: float):
	terrain_height = value
	var height_label = $UI/Panel/VBoxContainer/Parameters/HeightLabel
	height_label.text = "Height Variation: %.1f" % value

func _on_noise_changed(value: float):
	noise_frequency = value
	var noise_label = $UI/Panel/VBoxContainer/Parameters/NoiseLabel
	noise_label.text = "Noise Frequency: %.3f" % value

# VR teleportation handlers
func _on_vr_button_pressed(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String):
	if button == "trigger_click" or button == "by_button":
		teleport_marker.visible = true

func _on_vr_button_released(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String):
	if button == "trigger_click" or button == "by_button":
		teleport_marker.visible = false
		
		if teleport_ray.is_colliding():
			var collision_point = teleport_ray.get_collision_point()
			var collider = teleport_ray.get_collider()
			
			if collider != null and collider.has_meta("vr_walkable"):
				perform_vr_teleport(collision_point)

func perform_vr_teleport(target_position: Vector3):
	"""Teleport VR player to target position"""
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		var teleport_position = target_position + Vector3(0, 0.1, 0)
		xr_origin.global_position = teleport_position
		print("VR Teleport: Moved to ", teleport_position)
