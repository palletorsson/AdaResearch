# RhizomeCaveDemoController.gd
# Demo controller for showcasing the rhizomatic cave system
# Provides interactive parameter adjustment and generation

extends Node3D

# UI references
@onready var generate_button = $UI/Panel/VBoxContainer/GenerateButton
@onready var size_slider = $UI/Panel/VBoxContainer/Parameters/SizeSlider
@onready var complexity_slider = $UI/Panel/VBoxContainer/Parameters/ComplexitySlider
@onready var chambers_slider = $UI/Panel/VBoxContainer/Parameters/ChambersSlider
@onready var stats_text = $UI/Panel/VBoxContainer/Stats/StatsText
@onready var progress_bar = $UI/Panel/VBoxContainer/ProgressBar
@onready var cave_generator_node = $CaveGenerator
@onready var camera = $Camera3D

# Cave generator
var cave_generator: RhizomeCaveGenerator

# Camera control
var camera_rotation = Vector2.ZERO
var camera_distance = 50.0
var camera_target = Vector3.ZERO
var is_mouse_captured = false

# VR Navigation
var teleport_ray: RayCast3D
var teleport_marker: MeshInstance3D
var vr_camera: XRCamera3D
var vr_controllers: Array[XRController3D] = []

func _ready():
	setup_ui()
	setup_cave_generator()
	setup_camera()
	setup_vr_navigation()  # Add VR setup
	
	# Generate initial cave asynchronously to prevent blocking on startup
	call_deferred("generate_cave_async")

func setup_ui():
	"""Setup UI connections and initial states"""
	generate_button.pressed.connect(_on_generate_pressed)
	
	# Update labels when sliders change
	size_slider.value_changed.connect(_on_size_changed)
	complexity_slider.value_changed.connect(_on_complexity_changed)
	chambers_slider.value_changed.connect(_on_chambers_changed)
	
	# Initialize slider labels
	_on_size_changed(size_slider.value)
	_on_complexity_changed(complexity_slider.value)
	_on_chambers_changed(chambers_slider.value)
	
	progress_bar.visible = false

func setup_cave_generator():
	"""Initialize the cave generator"""
	cave_generator = RhizomeCaveGenerator.new()
	cave_generator.name = "RhizomeCaveGenerator"
	cave_generator_node.add_child(cave_generator)
	
	# Connect signals
	cave_generator.generation_progress.connect(_on_generation_progress)
	cave_generator.generation_complete.connect(_on_generation_complete)
	
	print("RhizomeCaveDemo: Cave generator initialized")

func _input(event):
	"""Handle input for camera controls"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_mouse_captured = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				is_mouse_captured = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(10.0, camera_distance - 5.0)
			update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(200.0, camera_distance + 5.0)
			update_camera()
	
	elif event is InputEventMouseMotion and is_mouse_captured:
		camera_rotation.x += event.relative.y * 0.01
		camera_rotation.y += event.relative.x * 0.01
		camera_rotation.x = clamp(camera_rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
		update_camera()

func update_camera():
	"""Update camera position based on rotation and distance"""
	var transform_camera = Transform3D()
	transform_camera = transform_camera.rotated(Vector3.UP, camera_rotation.y)
	transform_camera = transform_camera.rotated(Vector3.RIGHT, camera_rotation.x)
	
	var camera_pos = camera_target + transform_camera.basis.z * camera_distance
	camera.position = camera_pos
	camera.look_at(camera_target, Vector3.UP)

func _on_generate_pressed():
	"""Handle generate button press"""
	generate_cave_async()

func generate_cave_async():
	"""Generate a new cave system asynchronously with current parameters"""
	if cave_generator == null:
		return
	
	print("RhizomeCaveDemo: Starting non-blocking cave generation...")
	
	# Disable generate button but keep other controls working
	generate_button.disabled = true
	generate_button.text = "Generating..."
	progress_bar.visible = true
	progress_bar.value = 0
	
	# Update UI to show we're generating
	stats_text.text = "[color=yellow]🔄 Generating cave system...[/color]\n[color=gray]Camera controls remain active during generation.[/color]"
	
	# Configure generation parameters
	var cave_size = size_slider.value
	var cave_params = {
		"size": Vector3(cave_size, cave_size * 0.4, cave_size),
		"chunk_size": Vector3i(12, 12, 12),  # Smaller for smoother generation
		"voxel_scale": 1.0,
		"seed": randi(),
		"initial_chambers": int(chambers_slider.value),
		"growth_iterations": int(complexity_slider.value * 20)  # Reduced for faster generation
	}
	
	# Configure rhizomatic parameters
	var rhizome_params = {
		"branch_probability": complexity_slider.value,
		"merge_distance": 6.0,
		"vertical_bias": 0.3,
		"chamber_probability": 0.25,
		"max_depth": 4  # Reduced depth for faster generation
	}
	
	cave_generator.setup_parameters(cave_params)
	cave_generator.configure_rhizome_parameters(rhizome_params)
	
	# Start async generation - this will not block the UI
	await cave_generator.generate_cave_async()
	
	# Update camera target to cave center
	camera_target = Vector3.ZERO
	update_camera()

# Keep the old function for backwards compatibility but make it call the async version
func generate_cave():
	"""Generate a new cave system with current parameters (legacy function)"""
	generate_cave_async()

func _on_generation_progress(percentage: float):
	"""Update progress bar during generation"""
	progress_bar.value = percentage
	
	# Update status text based on progress
	var status = ""
	if percentage <= 20:
		status = "🌱 Growing rhizomatic network..."
	elif percentage <= 40:
		status = "🏗️ Creating voxel grid..."
	elif percentage <= 60:
		status = "⛏️ Carving cave system..."
	elif percentage <= 80:
		status = "🌊 Adding organic variation..."
	elif percentage <= 95:
		status = "🎨 Generating meshes..."
	else:
		status = "⚡ Creating physics..."
	
	stats_text.text = "[color=yellow]🔄 Generating cave system...[/color]\n[color=gray]%s[/color]\n[color=white]Progress: %.0f%%[/color]" % [status, percentage]

func _on_generation_complete():
	"""Handle generation completion"""
	print("RhizomeCaveDemo: Generation complete!")
	
	# Re-enable UI
	generate_button.disabled = false
	generate_button.text = "Generate New Cave"
	progress_bar.visible = false
	
	# Update statistics
	update_cave_statistics()

func update_cave_statistics():
	"""Update the statistics display"""
	if cave_generator == null:
		return
	
	var info = cave_generator.get_cave_info()
	
	var stats_html = "[color=yellow]Cave Statistics:[/color]\n"
	stats_html += "• Mesh Chunks: %d\n" % info.mesh_instances
	stats_html += "• Collision Bodies: %d\n" % info.collision_bodies
	stats_html += "• Total Vertices: %s\n" % format_number(info.total_vertices)
	stats_html += "• Total Triangles: %s\n" % format_number(info.total_triangles)
	stats_html += "• Voxel Chunks: %d\n" % info.voxel_chunks
	stats_html += "• Growth Nodes: %d\n" % info.growth_nodes
	stats_html += "• Chambers: %d\n" % info.chambers
	
	# Add VR navigation info
	var nav_tile_count = 0
	var walkable_bodies = 0
	for child in get_children():
		if child.name.begins_with("NavTile_"):
			nav_tile_count += 1
		elif child.name.ends_with("_VR_Collision"):
			walkable_bodies += 1
	
	stats_html += "\n[color=cyan]VR Navigation:[/color]\n"
	stats_html += "• Walkable Tiles: %d (1x1m)\n" % nav_tile_count
	stats_html += "• VR Collision Bodies: %d\n" % walkable_bodies
	stats_html += "• VR Controllers: %d\n" % vr_controllers.size()
	
	# Calculate approximate memory usage
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

func _on_size_changed(value: float):
	"""Update size slider label"""
	var size_label = $UI/Panel/VBoxContainer/Parameters/SizeLabel
	size_label.text = "Cave Size: %.0f units" % value

func _on_complexity_changed(value: float):
	"""Update complexity slider label"""
	var complexity_label = $UI/Panel/VBoxContainer/Parameters/ComplexityLabel
	complexity_label.text = "Complexity: %.1f" % value

func _on_chambers_changed(value: float):
	"""Update chambers slider label"""
	var chambers_label = $UI/Panel/VBoxContainer/Parameters/ChambersLabel
	chambers_label.text = "Initial Chambers: %.0f" % value

func _on_tree_exiting():
	"""Cleanup when scene exits"""
	if is_mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func setup_camera():
	"""Setup camera for VR mode"""
	vr_camera = find_child("XRCamera3D") as XRCamera3D

func setup_vr_navigation():
	"""Setup VR teleportation system"""
	# Find VR components if they exist
	vr_camera = find_child("XRCamera3D") as XRCamera3D
	
	# Find VR controllers
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		for child in xr_origin.get_children():
			if child is XRController3D:
				vr_controllers.append(child as XRController3D)
				setup_controller_teleport(child as XRController3D)
	
	print("VR Navigation: Found %d controllers" % vr_controllers.size())

func setup_controller_teleport(controller: XRController3D):
	"""Setup teleportation for a VR controller"""
	# Create teleport ray
	var teleport_ray = RayCast3D.new()
	teleport_ray.name = "TeleportRay"
	teleport_ray.target_position = Vector3(0, 0, -10)  # 10 meters forward
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
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var radius = 0.8  # Slightly smaller than 1m tile
	var segments = 20
	
	# Center vertex
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	
	# Circle vertices
	for i in range(segments):
		var angle = i * TAU / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		vertices.append(Vector3(x, 0.01, z))  # Slightly above ground
		normals.append(Vector3.UP)
		uvs.append(Vector2(x / radius * 0.5 + 0.5, z / radius * 0.5 + 0.5))
	
	# Create triangles
	for i in range(segments):
		var next_i = (i + 1) % segments
		
		indices.append(0)  # Center
		indices.append(i + 1)  # Current
		indices.append(next_i + 1)  # Next
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _on_vr_button_pressed(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String):
	"""Handle VR controller button press"""
	if button == "trigger_click" or button == "by_button":  # Common teleport buttons
		start_teleport_preview(controller, teleport_ray, teleport_marker)

func _on_vr_button_released(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String):
	"""Handle VR controller button release"""
	if button == "trigger_click" or button == "by_button":
		execute_teleport(controller, teleport_ray, teleport_marker)

func start_teleport_preview(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D):
	"""Start showing teleport preview"""
	teleport_marker.visible = true
	# Update preview position in _process

func execute_teleport(controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D):
	"""Execute teleportation to target location"""
	teleport_marker.visible = false
	
	if teleport_ray.is_colliding():
		var collision_point = teleport_ray.get_collision_point()
		var collider = teleport_ray.get_collider()
		
		# Check if it's a valid teleport target
		if collider != null and collider.has_meta("vr_walkable"):
			perform_vr_teleport(collision_point)

func perform_vr_teleport(target_position: Vector3):
	"""Teleport VR player to target position"""
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		# Adjust for player height
		var teleport_position = target_position + Vector3(0, 0.1, 0)  # Slightly above surface
		xr_origin.global_position = teleport_position
		
		print("VR Teleport: Moved to ", teleport_position)
		
		# Optional: Add teleport effect
		create_teleport_effect(target_position)

func create_teleport_effect(position: Vector3):
	"""Create visual effect at teleport location"""
	# Create temporary particle effect or flash
	var effect = MeshInstance3D.new()
	effect.mesh = SphereMesh.new()
	effect.mesh.radius = 0.5
	effect.mesh.height = 1.0
	effect.position = position
	
	# Glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN
	material.emission_energy = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	effect.set_surface_override_material(0, material)
	
	get_tree().current_scene.add_child(effect)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(effect.queue_free)

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
		
		# FIXED: Convert Vector2 camera_rotation to Vector3 for Camera3D
		camera.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0.0)
	
	# WASD movement
	var input_vector = Vector3.ZERO
	var speed = 10.0 if Input.is_action_pressed("ui_accept") else 5.0  # Sprint with space
	
	if Input.is_action_pressed("ui_up"):  # W
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down"):  # S
		input_vector.z += 1
	if Input.is_action_pressed("ui_left"):  # A
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):  # D
		input_vector.x += 1
	
	# Vertical movement
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	# Apply movement relative to camera orientation
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
				
				# Update marker position and color based on validity
				teleport_marker.global_position = collision_point
				
				var material = teleport_marker.get_surface_override_material(0) as StandardMaterial3D
				if collider != null and collider.has_meta("vr_walkable"):
					# Valid teleport location - green
					material.albedo_color = Color.GREEN
					material.emission = Color.GREEN
				else:
					# Invalid location - red
					material.albedo_color = Color.RED
					material.emission = Color.RED

func check_walkable_surface_at_position(position: Vector3) -> bool:
	"""Check if a position has a walkable surface"""
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		position + Vector3.UP,
		position + Vector3.DOWN * 2.0
	)
	query.collision_mask = 4  # VR navigation layer
	
	var result = space_state.intersect_ray(query)
	if result.has("collider"):
		var collider = result.collider
		return collider.has_meta("vr_walkable")
	
	return false

func get_navigation_info() -> String:
	"""Get information about generated navigation tiles"""
	var nav_tile_count = 0
	var walkable_bodies = 0
	
	# Count navigation tiles and walkable bodies
	for child in get_children():
		if child.name.begins_with("NavTile_"):
			nav_tile_count += 1
		elif child.name.ends_with("_VR_Collision"):
			walkable_bodies += 1
	
	return "VR Navigation: %d tiles, %d walkable bodies" % [nav_tile_count, walkable_bodies] 
